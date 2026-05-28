#!/usr/bin/env python3
"""Agent-readable system state: один текстовый/JSON срез по workspace.dsl + ADR (HLE-543).

Pipeline:
  1. Экспорт workspace.dsl → JSON через structurizr/structurizr (Docker).
  2. Парсинг frontmatter всех docs/architecture/adr/**/NNNN-*.md.
  3. Для каждого softwareSystem / container / component:
     - name, description, technology, tags
     - resolved adr-link / open-issues (title + status)
     - incoming / outgoing relationships (name + tech)
  4. Запись:
     - docs/architecture/_state.md   — human-readable
     - docs/architecture/_state.json — machine-readable

Запуск:
    python3 scripts/dump_arch_state.py

Возвращает 0 если всё ок. Не падает, если Docker недоступен — пропускает с warning.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
ADR_ROOT = REPO_ROOT / "docs" / "architecture" / "adr"
JSON_EXPORT = REPO_ROOT / "docs" / "diagrams" / "workspace.json"
OUT_MD = REPO_ROOT / "docs" / "architecture" / "_state.md"
OUT_JSON = REPO_ROOT / "docs" / "architecture" / "_state.json"
DOCKER_IMAGE = "structurizr/structurizr"


# ── 1. Export workspace.dsl → JSON ─────────────────────────────────────────────
def export_workspace_json() -> None:
    uid, gid = os.getuid(), os.getgid()
    JSON_EXPORT.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [
            "docker", "run", "--rm",
            "--user", f"{uid}:{gid}",
            "-v", f"{REPO_ROOT}:/workspace",
            DOCKER_IMAGE, "export",
            "-w", "/workspace/workspace.dsl",
            "-f", "json",
            "-o", f"/workspace/{JSON_EXPORT.relative_to(REPO_ROOT).parent}",
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: structurizr export failed:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)


# ── 2. ADR frontmatter parsing ─────────────────────────────────────────────────
_FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
_FIELD_RE = re.compile(r'^([\w-]+):\s*"?(.*?)"?\s*$', re.MULTILINE)


def parse_adr_frontmatter(md_path: Path) -> dict[str, str]:
    text = md_path.read_text(encoding="utf-8")
    m = _FRONTMATTER_RE.match(text)
    if not m:
        return {}
    fields = dict(_FIELD_RE.findall(m.group(1)))
    # Title: первая `# ...` строка тела
    title_match = re.search(r"^#\s+(.+)$", text[m.end():], re.MULTILINE)
    if title_match:
        fields["_title"] = title_match.group(1).strip()
    return fields


def load_all_adrs() -> dict[str, dict[str, str]]:
    """Map: 'docs/architecture/adr/<sub>/<file>.md' → {status, _title, ...}.

    Берёт только файлы вида `NNNN-*.md` (4-значный префикс) — отбрасывает
    `template.md`, `AGENTS.md` и прочие служебные.
    """
    result: dict[str, dict[str, str]] = {}
    for md_path in sorted(ADR_ROOT.glob("*/[0-9][0-9][0-9][0-9]-*.md")):
        rel = md_path.relative_to(REPO_ROOT).as_posix()
        result[rel] = parse_adr_frontmatter(md_path)
    return result


# ── 3. Element extraction + relationship lookup ────────────────────────────────
def build_element_index(model: dict) -> dict[str, dict]:
    """Map: element_id → element_dict (with extra _kind/_parent fields)."""
    idx: dict[str, dict] = {}

    def _add(elem: dict, kind: str, parent: str | None = None) -> None:
        elem = dict(elem)
        elem["_kind"] = kind
        elem["_parent"] = parent
        idx[elem["id"]] = elem

    for person in model.get("people", []):
        _add(person, "person")
    for system in model.get("softwareSystems", []):
        _add(system, "softwareSystem")
        for container in system.get("containers", []):
            _add(container, "container", parent=system["id"])
            for comp in container.get("components", []):
                _add(comp, "component", parent=container["id"])
    return idx


def collect_relationships(idx: dict[str, dict]) -> dict[str, dict[str, list[dict]]]:
    """Map: element_id → {'outgoing': [...], 'incoming': [...]}.

    Каждая связь — {destinationId, sourceId, description, technology, _peer_name}.
    """
    rels: dict[str, dict[str, list[dict]]] = {
        eid: {"outgoing": [], "incoming": []} for eid in idx
    }
    for eid, elem in idx.items():
        for r in elem.get("relationships", []):
            dst = r.get("destinationId")
            src = r.get("sourceId", eid)
            peer = idx.get(dst, {}).get("name", f"<unknown:{dst}>")
            rels[src]["outgoing"].append({
                "to": peer,
                "description": r.get("description", ""),
                "technology": r.get("technology", ""),
            })
            if dst in rels:
                rels[dst]["incoming"].append({
                    "from": idx.get(src, {}).get("name", f"<unknown:{src}>"),
                    "description": r.get("description", ""),
                    "technology": r.get("technology", ""),
                })
    return rels


# ── 4. ADR-link resolution ─────────────────────────────────────────────────────
def resolve_adr(path: str | None, adr_db: dict[str, dict[str, str]]) -> dict | None:
    if not path:
        return None
    meta = adr_db.get(path)
    if not meta:
        return {"path": path, "status": "<unknown>", "title": "<not found>"}
    return {
        "path": path,
        "status": meta.get("status", "<no-status>"),
        "title": meta.get("_title", path.rsplit("/", 1)[-1]),
    }


# ── 5. Build state dict ────────────────────────────────────────────────────────
def build_state(model: dict, adr_db: dict[str, dict[str, str]]) -> dict:
    idx = build_element_index(model)
    rels = collect_relationships(idx)

    def _element_payload(elem: dict) -> dict:
        eid = elem["id"]
        props = elem.get("properties", {})
        return {
            "name": elem.get("name", ""),
            "kind": elem["_kind"],
            "technology": elem.get("technology", ""),
            "description": elem.get("description", ""),
            "tags": [t for t in elem.get("tags", "").split(",") if t and t not in (
                "Element", "Person", "Software System", "Container", "Component",
            )],
            "adr_link": resolve_adr(props.get("adr-link"), adr_db),
            "open_issues": resolve_adr(props.get("open-issues"), adr_db),
            "outgoing": rels[eid]["outgoing"],
            "incoming": rels[eid]["incoming"],
        }

    systems = []
    for s_id, s in sorted(idx.items(), key=lambda kv: int(kv[0])):
        if s["_kind"] != "softwareSystem":
            continue
        s_payload = _element_payload(s)
        s_payload["containers"] = []
        for c_id, c in sorted(idx.items(), key=lambda kv: int(kv[0])):
            if c["_kind"] != "container" or c["_parent"] != s_id:
                continue
            c_payload = _element_payload(c)
            c_payload["components"] = []
            for k in (
                idx[i] for i in sorted(idx, key=int)
                if idx[i]["_kind"] == "component" and idx[i]["_parent"] == c_id
            ):
                c_payload["components"].append(_element_payload(k))
            s_payload["containers"].append(c_payload)
        systems.append(s_payload)

    people = [
        {
            "name": p.get("name", ""),
            "description": p.get("description", ""),
            "outgoing": rels[p["id"]]["outgoing"],
        }
        for p in (idx[i] for i in idx if idx[i]["_kind"] == "person")
    ]

    return {
        "generated_at": date.today().isoformat(),
        "workspace_name": model.get("name", "Азимут"),
        "people": people,
        "softwareSystems": systems,
        "stats": {
            "people": len(people),
            "softwareSystems": sum(1 for e in idx.values() if e["_kind"] == "softwareSystem"),
            "containers": sum(1 for e in idx.values() if e["_kind"] == "container"),
            "components": sum(1 for e in idx.values() if e["_kind"] == "component"),
            "adr_total": len(adr_db),
            "adr_proposed": sum(1 for a in adr_db.values() if a.get("status") == "proposed"),
            "adr_accepted": sum(1 for a in adr_db.values() if a.get("status") == "accepted"),
            "adr_superseded": sum(1 for a in adr_db.values() if a.get("status") == "superseded"),
        },
    }


# ── 6. Markdown rendering ──────────────────────────────────────────────────────
def _adr_md(adr: dict | None) -> str:
    if not adr:
        return "—"
    return f"[`{adr['path'].rsplit('/', 1)[-1]}`]({REPO_ROOT_REL}/{adr['path']}) — {adr['title']} *({adr['status']})*"


REPO_ROOT_REL = ".."  # links from docs/architecture/_state.md go up one level


def slug(name: str) -> str:
    """Детерминированный slug для anchor: lowercase, non-word chars → -.

    Кириллица сохраняется (Python re.UNICODE — `\\w` включает её).
    Используется в _state.md как `<a id="<kind>-<slug>">` и в
    workspace.dsl как `url ".../_state.md#<kind>-<slug>"` (HLE-547).
    """
    s = name.lower()
    s = re.sub(r"[^\w-]+", "-", s, flags=re.UNICODE)
    s = re.sub(r"-+", "-", s)
    return s.strip("-")


def anchor(kind: str, name: str) -> str:
    """Anchor id: `<kind-prefix>-<slug>`. `kind` = 'softwaresystem'/'container'/'component'."""
    return f"{kind}-{slug(name)}"


def _rel_md(direction: str, rels: list[dict]) -> str:
    if not rels:
        return "  - (нет)\n"
    out = ""
    for r in rels:
        peer = r.get("to") if direction == "outgoing" else r.get("from")
        arrow = "→" if direction == "outgoing" else "←"
        tech = f" [{r['technology']}]" if r.get("technology") else ""
        desc = f" — {r['description']}" if r.get("description") else ""
        out += f"  - {arrow} **{peer}**{tech}{desc}\n"
    return out


def render_markdown(state: dict) -> str:
    out: list[str] = []
    out.append("# Архитектурный state (auto-generated)\n")
    out.append(f"> Сгенерировано {state['generated_at']} скриптом `scripts/dump_arch_state.py` (HLE-543). **Не редактировать вручную** — перегенерируется из `workspace.dsl` + frontmatter ADR.\n")
    s = state["stats"]
    out.append(f"> Stats: {s['softwareSystems']} systems, {s['containers']} containers, {s['components']} components · {s['adr_total']} ADRs ({s['adr_accepted']} accepted, {s['adr_proposed']} proposed, {s['adr_superseded']} superseded) · {s['people']} people.\n\n")

    if state["people"]:
        out.append("## Пользователи\n\n")
        for p in state["people"]:
            out.append(f"### {p['name']}\n\n")
            out.append(f"{p['description']}\n\n")
            if p["outgoing"]:
                out.append("**Использует:**\n")
                out.append(_rel_md("outgoing", p["outgoing"]))
                out.append("\n")

    for sys_ in state["softwareSystems"]:
        out.append(f'<a id="{anchor("softwaresystem", sys_["name"])}"></a>\n')
        out.append(f"## SoftwareSystem: {sys_['name']}\n\n")
        out.append(f"{sys_['description']}\n\n")
        if sys_["tags"]:
            out.append(f"**Tags**: `{', '.join(sys_['tags'])}`\n\n")
        out.append(f"- **ADR**: {_adr_md(sys_['adr_link'])}\n")
        out.append(f"- **Open issues**: {_adr_md(sys_['open_issues'])}\n\n")
        if sys_["outgoing"]:
            out.append("**Связи (исходящие):**\n")
            out.append(_rel_md("outgoing", sys_["outgoing"]))
            out.append("\n")

        for c in sys_["containers"]:
            out.append(f'<a id="{anchor("container", c["name"])}"></a>\n')
            out.append(f"### Container: {c['name']}\n\n")
            out.append(f"- **Технология**: `{c['technology']}`\n")
            out.append(f"- **Описание**: {c['description']}\n")
            if c["tags"]:
                out.append(f"- **Tags**: `{', '.join(c['tags'])}`\n")
            out.append(f"- **ADR**: {_adr_md(c['adr_link'])}\n")
            out.append(f"- **Open issues**: {_adr_md(c['open_issues'])}\n")
            out.append("- **Исходящие**:\n")
            out.append(_rel_md("outgoing", c["outgoing"]))
            out.append("- **Входящие**:\n")
            out.append(_rel_md("incoming", c["incoming"]))
            out.append("\n")

            for k in c["components"]:
                proposed = " ⚠️ **proposed**" if "Proposed" in k["tags"] else ""
                out.append(f'<a id="{anchor("component", k["name"])}"></a>\n')
                out.append(f"#### Component: {k['name']}{proposed}\n\n")
                out.append(f"- **Технология**: `{k['technology']}`\n")
                out.append(f"- **Описание**: {k['description']}\n")
                if k["tags"]:
                    out.append(f"- **Tags**: `{', '.join(k['tags'])}`\n")
                out.append(f"- **ADR**: {_adr_md(k['adr_link'])}\n")
                out.append(f"- **Open issues**: {_adr_md(k['open_issues'])}\n")
                out.append("- **Исходящие**:\n")
                out.append(_rel_md("outgoing", k["outgoing"]))
                out.append("- **Входящие**:\n")
                out.append(_rel_md("incoming", k["incoming"]))
                out.append("\n")

    return "".join(out)


# ── 7. Main ────────────────────────────────────────────────────────────────────
def main() -> int:
    if not (REPO_ROOT / "workspace.dsl").exists():
        print("dump_arch_state: workspace.dsl not found — abort", file=sys.stderr)
        return 1

    try:
        subprocess.run(["docker", "info"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("dump_arch_state: Docker not available — skip", file=sys.stderr)
        return 0

    print("==> dump_arch_state: exporting workspace.dsl → JSON...")
    export_workspace_json()

    with open(JSON_EXPORT, encoding="utf-8") as f:
        data = json.load(f)

    print("==> dump_arch_state: parsing ADR frontmatter...")
    adr_db = load_all_adrs()
    print(f"    {len(adr_db)} ADR loaded.")

    print("==> dump_arch_state: building state...")
    state = build_state(data.get("model", {}), adr_db)

    OUT_JSON.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    OUT_MD.write_text(render_markdown(state), encoding="utf-8")

    s = state["stats"]
    print(f"    OK: {OUT_MD.relative_to(REPO_ROOT)} + {OUT_JSON.relative_to(REPO_ROOT)}")
    print(f"    Stats: {s['softwareSystems']} systems / {s['containers']} containers / {s['components']} components / {s['adr_total']} ADR")
    return 0


if __name__ == "__main__":
    sys.exit(main())
