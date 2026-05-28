#!/usr/bin/env python3
"""Проверяет MADR-структуру ADR-файлов.

Поля frontmatter (см. docs/architecture/adr/template.md): status, date,
decision-makers, linear-task, basis, implemented-in, related-to,
supersedes, superseded-by. Первые пять — обязательны.

Заголовки тела — те, что просит arc42/MADR-шаблон. Жёстко проверяем
наличие `## Context and Problem Statement` и `## Decision Outcome` —
без них ADR теряет смысл.

Запуск:
    python scripts/validate-madr.py [path ...]

Без аргументов — проходит по всем `docs/architecture/adr/<sub>/NNNN-*.md`.
Возвращает 0 если все ADR валидны, 1 при ошибках. Дизайн pre-commit-friendly:
аргументы — это список изменённых файлов (см. .pre-commit-config.yaml).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
ADR_ROOT = REPO_ROOT / "docs" / "architecture" / "adr"

REQUIRED_FRONTMATTER = ("status", "date", "decision-makers", "linear-task", "basis")
REQUIRED_HEADINGS = (
    "## Context and Problem Statement",
    "## Decision Outcome",
)

# Соответствует фильтру `files:` в .pre-commit-config.yaml. Намеренно широко:
# существующие ADR (0001-р1-…, 0008-п1-…) используют кириллицу в slug —
# `new-adr.sh` сам не запрещает не-ASCII в `<kebab-title>`, мы лишь требуем
# `NNNN-` префикс и расширение .md.
ADR_FILENAME_RE = re.compile(r"^\d{4}-.+\.md$")
FRONTMATTER_LINE_RE = re.compile(r"^([a-z-]+):\s*(.*)$")


def parse_frontmatter(text: str) -> dict[str, str] | None:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    fields: dict[str, str] = {}
    for line in lines[1:]:
        if line.strip() == "---":
            return fields
        m = FRONTMATTER_LINE_RE.match(line.strip())
        if m:
            fields[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return None  # закрывающая --- не найдена


def validate_file(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        rel = path.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        rel = str(path)

    if not ADR_FILENAME_RE.match(path.name):
        errors.append(f"{rel}: имя файла не соответствует NNNN-<title>.md")

    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        return [f"{rel}: не удалось прочитать файл ({exc})"]

    fm = parse_frontmatter(text)
    if fm is None:
        errors.append(f"{rel}: отсутствует или не закрыт YAML-frontmatter")
        return errors  # без frontmatter дальнейшие проверки бессмысленны

    for field in REQUIRED_FRONTMATTER:
        value = fm.get(field, "").strip()
        if not value:
            errors.append(f"{rel}: пустое или отсутствует поле `{field}:` в frontmatter")
            continue
        if field == "status":
            allowed_prefixes = ("proposed", "accepted", "rejected", "deprecated", "superseded")
            if not value.startswith(allowed_prefixes):
                errors.append(
                    f"{rel}: status='{value}' — допустимы proposed/accepted/rejected/"
                    f"deprecated/superseded by NNNN"
                )
        if field == "date" and not re.match(r"^\d{4}-\d{2}-\d{2}$", value):
            errors.append(f"{rel}: date='{value}' — ожидается YYYY-MM-DD")
        if field == "linear-task" and not re.match(r"^HLE-\d+", value):
            errors.append(f"{rel}: linear-task='{value}' — ожидается HLE-NNN")

    # H1 заголовок
    h1_match = re.search(r"^# (.+)$", text, re.MULTILINE)
    if not h1_match:
        errors.append(f"{rel}: отсутствует H1-заголовок")
    elif "{Короткий заголовок" in h1_match.group(1):
        errors.append(f"{rel}: H1 не заполнен (остался placeholder из шаблона)")

    for heading in REQUIRED_HEADINGS:
        if heading not in text:
            errors.append(f"{rel}: отсутствует обязательный раздел `{heading}`")

    return errors


def collect_targets(argv: list[str]) -> list[Path]:
    if argv:
        return [Path(arg) for arg in argv]
    if not ADR_ROOT.exists():
        return []
    return sorted(ADR_ROOT.glob("*/[0-9][0-9][0-9][0-9]-*.md"))


def main(argv: list[str]) -> int:
    targets = collect_targets(argv)
    if not targets:
        print("validate-madr: нет ADR-файлов для проверки")
        return 0

    all_errors: list[str] = []
    checked = 0
    for path in targets:
        # template.md — не ADR, не валидируется
        if path.name == "template.md":
            continue
        # Файлы вне adr/<sub>/NNNN-*.md пропускаем (pre-commit может прислать прочее)
        if not ADR_FILENAME_RE.match(path.name):
            continue
        checked += 1
        all_errors.extend(validate_file(path))

    if all_errors:
        print(f"validate-madr: проверено {checked} ADR, найдено {len(all_errors)} ошибок:")
        for err in all_errors:
            print(f"  - {err}")
        return 1

    print(f"validate-madr: проверено {checked} ADR — OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
