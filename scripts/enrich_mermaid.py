#!/usr/bin/env python3
"""Post-processor: добавляет кликабельные ADR-ссылки в Mermaid-диаграммы (HLE-534).

Читает docs/diagrams/workspace.json, извлекает id → adr-link для всех
containers/components и вставляет строки:
  click <id> href "../../<adr-link>" "_blank"
в каждый docs/diagrams/structurizr-*.mmd перед закрывающим "end".

Идемпотентен: не дублирует уже существующие click-строки.
Требует: docs/diagrams/workspace.json (генерируется export_mermaid.sh).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DIAGRAMS_DIR = REPO_ROOT / "docs" / "diagrams"
WORKSPACE_JSON = DIAGRAMS_DIR / "workspace.json"


def _collect_adr_links(model: dict) -> dict[str, str]:
    """Return {element_id: adr_link_path} for all elements with adr-link property."""
    links: dict[str, str] = {}

    def _visit(element: dict) -> None:
        adr = element.get("properties", {}).get("adr-link", "")
        if adr:
            links[element["id"]] = adr

    for system in model.get("softwareSystems", []):
        _visit(system)
        for container in system.get("containers", []):
            _visit(container)
            for component in container.get("components", []):
                _visit(component)

    return links


def _enrich_file(mmd_path: Path, adr_links: dict[str, str]) -> int:
    """Inject click lines into mmd_path. Returns number of lines added."""
    text = mmd_path.read_text(encoding="utf-8")

    # Build set of ids already having a click line (idempotency)
    existing_ids = set(re.findall(r"^\s*click\s+(\S+)\s+href", text, re.MULTILINE))

    # Find which ids from adr_links appear in this file as Mermaid nodes: "<id>["
    node_pattern = re.compile(r"^\s*(\d+)\[", re.MULTILINE)
    file_node_ids = set(node_pattern.findall(text))

    lines_to_add: list[str] = []
    for elem_id, adr_path in sorted(adr_links.items(), key=lambda x: int(x[0])):
        if elem_id in existing_ids:
            continue
        if elem_id not in file_node_ids:
            continue
        # Relative path from docs/diagrams/ to the ADR file
        rel = "../../" + adr_path
        lines_to_add.append(f'  click {elem_id} href "{rel}" "_blank"')

    if not lines_to_add:
        return 0

    # Insert before the last "end" line
    insert_block = "\n".join(lines_to_add) + "\n"
    # Find the closing "  end" of the subgraph
    new_text = re.sub(r"(\n  end\s*\n?)$", "\n" + insert_block + r"\1", text, count=1)
    if new_text == text:
        # Fallback: append before EOF
        new_text = text.rstrip("\n") + "\n" + insert_block

    mmd_path.write_text(new_text, encoding="utf-8")
    return len(lines_to_add)


def main() -> int:
    if not WORKSPACE_JSON.exists():
        print(
            f"enrich-mermaid: {WORKSPACE_JSON.relative_to(REPO_ROOT)} not found — "
            "run export_mermaid.sh first",
            file=sys.stderr,
        )
        return 1

    with open(WORKSPACE_JSON, encoding="utf-8") as f:
        data = json.load(f)

    adr_links = _collect_adr_links(data.get("model", {}))
    if not adr_links:
        print("enrich-mermaid: no adr-link properties found in workspace.json — skip")
        return 0

    mmd_files = sorted(DIAGRAMS_DIR.glob("structurizr-*.mmd"))
    if not mmd_files:
        print("enrich-mermaid: no structurizr-*.mmd files found — skip")
        return 0

    total = 0
    for mmd_path in mmd_files:
        added = _enrich_file(mmd_path, adr_links)
        if added:
            print(f"    enriched {mmd_path.name}: +{added} click link(s)")
        else:
            print(f"    {mmd_path.name}: already up to date")
        total += added

    print(f"enrich-mermaid: done ({total} link(s) added across {len(mmd_files)} file(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
