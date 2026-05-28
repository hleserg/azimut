#!/usr/bin/env python3
"""Auto-фикс «красивостей» на C4-элементах в workspace.dsl (HLE-547).

Для каждого element (softwareSystem / container / component), у которого
определён `properties { "adr-link" "..." }`:

1. **`url`**: указывает на секцию элемента в `docs/architecture/_state.md`
   (генерируется HLE-543 dump_arch_state.py с явными `<a id="..."></a>`
   anchors). Это даёт кликабельный переход:
       компонент в C4 → `_state.md#component-<slug>` → видны ADR,
       open-issues, описание, связи — все clickable.
   Если `url` отсутствует или не соответствует — обновляется.

2. **`tags "Proposed"`** (конвенция A из HLE-541): тег ставится **только**
   когда `adr-link` (основной ADR) в статусе `proposed`. Скрипт читает
   frontmatter ADR-файла, добавляет/удаляет тег как нужно.

Скрипт **идемпотентный** — повторный запуск без изменений в источниках
не меняет файл.

Запуск:
    python3 scripts/sync_arch_metadata.py [--check]

Без `--check` — auto-fix workspace.dsl in-place.
С `--check` — exit 1 если нужны изменения (для pre-commit).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DSL_PATH = REPO_ROOT / "workspace.dsl"
ADR_ROOT = REPO_ROOT / "docs" / "architecture" / "adr"
STATE_URL_BASE = "https://github.com/hleserg/azimut/blob/master/docs/architecture/_state.md"

# ── ADR status lookup ─────────────────────────────────────────────────────────
_FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
_FIELD_RE = re.compile(r"^([\w-]+):\s*\"?(.*?)\"?\s*$", re.MULTILINE)


def adr_status(adr_path_rel: str) -> str | None:
    """Прочитать frontmatter и вернуть status, либо None если файл не найден."""
    p = REPO_ROOT / adr_path_rel
    if not p.exists():
        return None
    text = p.read_text(encoding="utf-8")
    m = _FM_RE.match(text)
    if not m:
        return None
    fields = dict(_FIELD_RE.findall(m.group(1)))
    return fields.get("status")


# ── Slug (должен совпадать с dump_arch_state.py) ──────────────────────────────
def slug(name: str) -> str:
    s = name.lower()
    s = re.sub(r"[^\w-]+", "-", s, flags=re.UNICODE)
    s = re.sub(r"-+", "-", s)
    return s.strip("-")


def url_for(kind: str, name: str) -> str:
    return f"{STATE_URL_BASE}#{kind}-{slug(name)}"


# ── DSL parsing/editing ───────────────────────────────────────────────────────
# Найти element: строка вида `[indent]<varname> = (softwareSystem|container|component) "<Name>" "<Desc>" "<Tech>"? {`
ELEMENT_RE = re.compile(
    r"^(?P<indent>\s+)(?P<var>\w+)\s*=\s*(?P<kind>softwareSystem|container|component)\s+\"(?P<name>[^\"]+)\".*\{$"
)


def find_element_block(lines: list[str], start_idx: int) -> int:
    """Вернуть индекс закрывающей `}` для блока, начинающегося на start_idx."""
    depth = 1
    i = start_idx + 1
    while i < len(lines) and depth > 0:
        s = lines[i].strip()
        if s.endswith("{"):
            depth += 1
        elif s == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return i - 1


def adr_link_in_block(lines: list[str], start: int, end: int) -> str | None:
    for i in range(start, end):
        m = re.search(r'"adr-link"\s+"([^"]+)"', lines[i])
        if m:
            return m.group(1)
    return None


def has_url_in_block(lines: list[str], start: int, end: int, indent: str) -> int:
    """Вернуть индекс строки с `url ...` если есть, иначе -1.

    Только на element-уровне (тот же indent, что и block-open + 4 пробела — обычно
    индентация атрибутов внутри блока).
    """
    inner_indent = indent + "    "
    for i in range(start + 1, end):
        if re.match(rf"^{inner_indent}url\s+", lines[i]):
            return i
    return -1


def set_url(lines: list[str], start: int, end: int, indent: str, url: str) -> bool:
    """Insert or update `url ...` строку внутри element. True if changed."""
    new_line = f'{indent}    url "{url}"'
    idx = has_url_in_block(lines, start, end, indent)
    if idx >= 0:
        if lines[idx].rstrip() == new_line:
            return False
        lines[idx] = new_line
        return True
    # Insert: после открывающей `{` строки start, перед всем остальным
    lines.insert(start + 1, new_line)
    return True


# ── Tags handling ─────────────────────────────────────────────────────────────
TAGS_LINE_RE = re.compile(r'^(\s+)tags\s+(.+)$')


def parse_tags(line: str) -> list[str]:
    m = TAGS_LINE_RE.match(line)
    if not m:
        return []
    return re.findall(r'"([^"]+)"', m.group(2))


def write_tags(indent: str, tags: list[str]) -> str:
    quoted = " ".join(f'"{t}"' for t in tags)
    return f'{indent}    tags {quoted}'


def sync_proposed_tag(
    lines: list[str], start: int, end: int, indent: str, want_proposed: bool
) -> bool:
    """Auto-fix tags "Proposed" по конвенции. True if changed.

    - want_proposed=True: тег должен присутствовать (добавить если нет).
    - want_proposed=False: тег должен отсутствовать (удалить если есть).
    """
    inner_indent = indent + "    "
    tag_line_idx = -1
    existing_tags: list[str] = []
    for i in range(start + 1, end):
        if TAGS_LINE_RE.match(lines[i]):
            # check indent matches inner
            if lines[i].startswith(inner_indent + "tags"):
                tag_line_idx = i
                existing_tags = parse_tags(lines[i])
                break

    has_proposed = "Proposed" in existing_tags

    if want_proposed and has_proposed:
        return False
    if not want_proposed and not has_proposed:
        return False

    if want_proposed:
        # Добавить
        if tag_line_idx >= 0:
            existing_tags.append("Proposed")
            lines[tag_line_idx] = write_tags(indent, existing_tags)
        else:
            # Вставить новую tags-строку после открывающей `{`
            lines.insert(start + 1, write_tags(indent, ["Proposed"]))
    else:
        # Удалить
        new_tags = [t for t in existing_tags if t != "Proposed"]
        if new_tags:
            lines[tag_line_idx] = write_tags(indent, new_tags)
        else:
            del lines[tag_line_idx]
    return True


# ── Main ──────────────────────────────────────────────────────────────────────
def main() -> int:
    check_only = "--check" in sys.argv

    text = DSL_PATH.read_text(encoding="utf-8")
    lines = text.splitlines()
    changed = False
    fixes: list[str] = []

    i = 0
    while i < len(lines):
        m = ELEMENT_RE.match(lines[i])
        if not m:
            i += 1
            continue

        indent = m.group("indent")
        kind = m.group("kind")
        name = m.group("name")
        end = find_element_block(lines, i)
        adr_link = adr_link_in_block(lines, i, end)

        if adr_link:
            # 1. URL
            want_url = url_for(
                {"softwareSystem": "softwaresystem",
                 "container": "container",
                 "component": "component"}[kind],
                name,
            )
            if set_url(lines, i, end, indent, want_url):
                changed = True
                fixes.append(f"  url updated: {kind} {name!r}")
                # Сместить end: добавилась/изменилась строка → пересчитать
                end = find_element_block(lines, i)

            # 2. Proposed tag
            status = adr_status(adr_link)
            want_proposed = status == "proposed"
            if sync_proposed_tag(lines, i, end, indent, want_proposed):
                changed = True
                action = "+Proposed" if want_proposed else "-Proposed"
                fixes.append(f"  tags {action}: {kind} {name!r}")

        # NOTE: i += 1 (НЕ end+1) — иначе пропустим вложенные container/component
        # внутри softwareSystem. find_element_block при следующем match'е
        # корректно найдёт `end` для inner-элемента.
        i += 1

    if changed:
        if check_only:
            print("sync-arch-metadata: changes needed:")
            for f in fixes:
                print(f)
            print(f"\nRun without --check to auto-fix.")
            return 1
        new_text = "\n".join(lines)
        if not new_text.endswith("\n"):
            new_text += "\n"
        DSL_PATH.write_text(new_text, encoding="utf-8")
        print(f"sync-arch-metadata: applied {len(fixes)} fix(es):")
        for f in fixes:
            print(f)
    else:
        print("sync-arch-metadata: workspace.dsl already in sync, no changes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
