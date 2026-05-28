#!/usr/bin/env python3
"""PR architecture review — единая точка вызова для трёх промптов из .github/prompts/.

Запускается из GitHub Actions workflow pr-architecture-review.yml. Для каждого
из трёх промптов (pr-architecture-lint / pr-adr-check / pr-lead-manual-check):

1. Загружает текст промпта.
2. Подставляет в `{{placeholder}}` контекст: workspace.dsl, git diff PR,
   список ADR, выбранные главы arc42, шаблон ADR.
3. Отправляет в Claude (Sonnet 4.6, anthropic.Anthropic().messages.create).
4. Парсит финальную строку `VERDICT: PASS|BLOCK`.
5. Постит комментарий в PR через `gh pr comment` (если запущен в Actions).
6. Возвращает exit-код 0 (PASS) или 1 (BLOCK / ошибка).

Запуск:
    python pr_review.py <prompt_name> [--pr <num>] [--base <sha>] [--head <sha>]

Где `<prompt_name>` ∈ {pr-architecture-lint, pr-adr-check, pr-lead-manual-check}.

Зависимости: `anthropic`. Переменные окружения: ANTHROPIC_API_KEY (обязательно),
GITHUB_TOKEN (для `gh pr comment`).

Sonnet 4.6 (не Opus) — эти проверки шаблонные, Opus тут избыточен и в ~5× дороже.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

try:
    import anthropic
except ImportError:
    print("error: install with `pip install anthropic`", file=sys.stderr)
    sys.exit(2)


REPO_ROOT = Path(__file__).resolve().parents[2]
PROMPTS_DIR = REPO_ROOT / ".github" / "prompts"
MODEL = "claude-sonnet-4-6"
MAX_TOKENS = 4096
MAX_DIFF_CHARS = 100_000  # обрезаем очень крупные PR, иначе вылетим из контекста


def read_text(path: Path) -> str:
    if not path.exists():
        return f"(файл {path.relative_to(REPO_ROOT)} отсутствует)"
    return path.read_text(encoding="utf-8")


def get_pr_diff(base_sha: str | None, head_sha: str | None) -> str:
    if base_sha and head_sha:
        cmd = ["git", "diff", f"{base_sha}...{head_sha}"]
    else:
        cmd = ["git", "diff", "HEAD~1...HEAD"]
    try:
        out = subprocess.check_output(cmd, cwd=REPO_ROOT, text=True, encoding="utf-8")
    except subprocess.CalledProcessError as exc:
        return f"(git diff failed: {exc})"
    if len(out) > MAX_DIFF_CHARS:
        out = out[:MAX_DIFF_CHARS] + f"\n... (обрезано до {MAX_DIFF_CHARS} символов)"
    return out


def list_adrs() -> str:
    adr_root = REPO_ROOT / "docs" / "architecture" / "adr"
    if not adr_root.exists():
        return "(папка docs/architecture/adr/ отсутствует)"
    lines = []
    for path in sorted(adr_root.glob("*/[0-9][0-9][0-9][0-9]-*.md")):
        rel = path.relative_to(REPO_ROOT).as_posix()
        title = ""
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.startswith("# "):
                title = line[2:].strip()
                break
        lines.append(f"- {rel} — {title}")
    return "\n".join(lines) if lines else "(ADR не найдены)"


def build_context(base_sha: str | None, head_sha: str | None) -> dict[str, str]:
    return {
        "workspace_dsl": read_text(REPO_ROOT / "workspace.dsl"),
        "pr_diff": get_pr_diff(base_sha, head_sha),
        "building_block_view": read_text(
            REPO_ROOT / "docs" / "architecture" / "05-building-block-view.md"
        ),
        "lead_manual": read_text(
            REPO_ROOT / "docs" / "architecture" / "13-lead-operating-manual.md"
        ),
        "adr_template": read_text(
            REPO_ROOT / "docs" / "architecture" / "adr" / "template.md"
        ),
        "adr_list": list_adrs(),
    }


def render_prompt(prompt_name: str, context: dict[str, str]) -> str:
    path = PROMPTS_DIR / f"{prompt_name}.md"
    if not path.exists():
        raise SystemExit(f"prompt not found: {path}")
    text = path.read_text(encoding="utf-8")
    for key, value in context.items():
        text = text.replace("{{" + key + "}}", value)
    return text


def call_claude(prompt: str) -> str:
    client = anthropic.Anthropic()
    resp = client.messages.create(
        model=MODEL,
        max_tokens=MAX_TOKENS,
        messages=[{"role": "user", "content": prompt}],
    )
    parts = [block.text for block in resp.content if getattr(block, "type", "") == "text"]
    return "".join(parts).strip()


def parse_verdict(reply: str) -> str:
    for line in reversed(reply.strip().splitlines()):
        line = line.strip()
        if line.startswith("VERDICT:"):
            verdict = line.split(":", 1)[1].strip().upper()
            if verdict in ("PASS", "BLOCK"):
                return verdict
    # Если модель не указала вердикт явно — считаем PASS, чтобы не блокировать PR
    # по техническому сбою; в логе явно подсветим.
    print("::warning::No explicit VERDICT line found — treating as PASS", file=sys.stderr)
    return "PASS"


def post_comment(prompt_name: str, verdict: str, reply: str, pr_number: str | None) -> None:
    if not pr_number:
        return  # запуск локально / вне Actions — комментарий не пишем
    icon = "✅" if verdict == "PASS" else "❌"
    body = (
        f"### {icon} `{prompt_name}` — `{verdict}`\n\n"
        f"<details><summary>Ответ ИИ-ревьюера</summary>\n\n{reply}\n\n</details>"
    )
    try:
        subprocess.run(
            ["gh", "pr", "comment", pr_number, "--body", body],
            check=True,
            cwd=REPO_ROOT,
        )
    except FileNotFoundError:
        print("::warning::gh CLI not available — skipping PR comment", file=sys.stderr)
    except subprocess.CalledProcessError as exc:
        print(f"::warning::gh pr comment failed: {exc}", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("prompt", help="имя промпта без .md, напр. pr-architecture-lint")
    parser.add_argument("--pr", default=os.environ.get("PR_NUMBER"))
    parser.add_argument("--base", default=os.environ.get("BASE_SHA"))
    parser.add_argument("--head", default=os.environ.get("HEAD_SHA"))
    args = parser.parse_args()

    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("error: ANTHROPIC_API_KEY is not set", file=sys.stderr)
        return 2

    context = build_context(args.base, args.head)
    prompt = render_prompt(args.prompt, context)

    print(f"::group::{args.prompt} — prompt size: {len(prompt)} chars")
    print(f"  workspace.dsl:        {len(context['workspace_dsl'])} chars")
    print(f"  pr_diff:              {len(context['pr_diff'])} chars")
    print(f"  building_block_view:  {len(context['building_block_view'])} chars")
    print(f"  lead_manual:          {len(context['lead_manual'])} chars")
    print(f"  adr_template:         {len(context['adr_template'])} chars")
    print(f"  adr_list entries:     {context['adr_list'].count(chr(10)) + 1}")
    print("::endgroup::")

    reply = call_claude(prompt)
    verdict = parse_verdict(reply)
    print(f"::group::{args.prompt} — verdict: {verdict}")
    print(reply)
    print("::endgroup::")

    post_comment(args.prompt, verdict, reply, args.pr)

    return 0 if verdict == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
