#!/usr/bin/env python3
"""Architecture validation: code vs workspace.dsl (HLE-528).

Pipeline:
  1. Export workspace.dsl → JSON via structurizr/structurizr Docker image.
  2. Check every container/component in 'Азимут' system has non-empty
     'technology' and 'description'.
  3. Check docker-compose.yml services appear somewhere in DSL text.
  4. Check top-level src/ subdirectories appear somewhere in DSL text.

Exit 0 = all checks pass; 1 = issues found.
Requires: Docker.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DOCKER_IMAGE = "structurizr/structurizr"
JSON_OUTPUT = REPO_ROOT / "docs" / "diagrams" / "workspace.json"

# Services/dirs that are intentionally absent from DSL by exact name but
# documented under a different name.  Format: {code_name: "reason / DSL ref"}.
# Expand this list when adding new whitelisted mappings.
KNOWN_MAPPINGS: dict[str, str] = {}


def _docker_export_json() -> None:
    uid, gid = os.getuid(), os.getgid()
    JSON_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [
            "docker", "run", "--rm",
            "--user", f"{uid}:{gid}",
            "-v", f"{REPO_ROOT}:/workspace",
            DOCKER_IMAGE, "export",
            "-w", "/workspace/workspace.dsl",
            "-f", "json",
            "-o", f"/workspace/{JSON_OUTPUT.relative_to(REPO_ROOT).parent}",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: structurizr export failed:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)


def _get_azimuth_containers(model: dict) -> list[dict]:
    for system in model.get("softwareSystems", []):
        if "зимут" in system.get("name", ""):
            return system.get("containers", [])
    return []


def _dsl_text(model: dict) -> str:
    """Return all names, descriptions, and IDs in the model as lowercase text."""
    parts: list[str] = []

    def _collect(obj: dict | list) -> None:
        if isinstance(obj, dict):
            for k, v in obj.items():
                if k in ("name", "description", "id", "technology") and isinstance(v, str):
                    parts.append(v)
                else:
                    _collect(v)
        elif isinstance(obj, list):
            for item in obj:
                _collect(item)

    _collect(model)
    return " ".join(parts).lower()


def check_metadata(containers: list[dict]) -> list[str]:
    issues: list[str] = []
    for c in containers:
        name = c.get("name", "?")
        if not c.get("technology", "").strip():
            issues.append(f"Container {name!r}: missing 'technology'")
        if not c.get("description", "").strip():
            issues.append(f"Container {name!r}: missing 'description'")
        for comp in c.get("components", []):
            cname = comp.get("name", "?")
            if not comp.get("technology", "").strip():
                issues.append(f"Component {name!r}/{cname!r}: missing 'technology'")
            if not comp.get("description", "").strip():
                issues.append(f"Component {name!r}/{cname!r}: missing 'description'")
    return issues


def _parse_compose_services() -> list[str]:
    compose_path = REPO_ROOT / "docker-compose.yml"
    if not compose_path.exists():
        return []
    # Minimal YAML service-key parser: lines under `services:` that are
    # indented exactly 2 spaces followed by a word and a colon.
    import re
    text = compose_path.read_text(encoding="utf-8")
    in_services = False
    services: list[str] = []
    for line in text.splitlines():
        if re.match(r"^services\s*:", line):
            in_services = True
            continue
        if in_services:
            m = re.match(r"^  ([\w][\w-]*):", line)
            if m:
                services.append(m.group(1))
            elif line and not line.startswith(" "):
                break
    return services


def check_docker_compose(dsl_text: str) -> list[str]:
    services = _parse_compose_services()
    issues: list[str] = []
    for svc in services:
        if svc in KNOWN_MAPPINGS:
            continue
        if svc.lower() not in dsl_text:
            issues.append(
                f"docker-compose service {svc!r} is not referenced anywhere in workspace.dsl"
            )
    return issues


def check_src_dirs(dsl_text: str) -> list[str]:
    src_path = REPO_ROOT / "src"
    if not src_path.is_dir():
        return []
    issues: list[str] = []
    for item in sorted(src_path.iterdir()):
        if item.name.startswith(("_", ".")):
            continue
        if item.is_dir():
            if item.name in KNOWN_MAPPINGS:
                continue
            if item.name.lower() not in dsl_text:
                issues.append(
                    f"src/{item.name}/ directory is not referenced anywhere in workspace.dsl"
                )
    return issues


def main() -> int:
    if not (REPO_ROOT / "workspace.dsl").exists():
        print("validate-arch: workspace.dsl not found — skip", file=sys.stderr)
        return 0

    try:
        subprocess.run(["docker", "info"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("validate-arch: Docker not available — skip", file=sys.stderr)
        return 0

    print("==> validate-arch: exporting workspace.dsl → JSON...")
    _docker_export_json()

    with open(JSON_OUTPUT, encoding="utf-8") as f:
        data = json.load(f)

    model = data.get("model", {})
    containers = _get_azimuth_containers(model)
    full_text = _dsl_text(model)

    all_issues: list[str] = []

    # ── Check 1: metadata completeness ────────────────────────────────────────
    print("==> Checking metadata completeness (technology + description)...")
    meta_issues = check_metadata(containers)
    if meta_issues:
        for issue in meta_issues:
            print(f"    FAIL: {issue}")
        all_issues.extend(meta_issues)
    else:
        total = sum(1 + len(c.get("components", [])) for c in containers)
        print(f"    OK: all {total} container(s)/component(s) have technology + description.")

    # ── Check 2: docker-compose services vs DSL ────────────────────────────────
    print("==> Checking docker-compose.yml services vs DSL...")
    compose_issues = check_docker_compose(full_text)
    if compose_issues:
        for issue in compose_issues:
            print(f"    FAIL: {issue}")
        all_issues.extend(compose_issues)
    else:
        print("    OK: all docker-compose services are referenced in workspace.dsl.")

    # ── Check 3: src/ directories vs DSL ──────────────────────────────────────
    print("==> Checking src/ directories vs DSL...")
    src_issues = check_src_dirs(full_text)
    if src_issues:
        for issue in src_issues:
            print(f"    FAIL: {issue}")
        all_issues.extend(src_issues)
    else:
        print("    OK: all src/ directories are referenced in workspace.dsl.")

    print()
    if all_issues:
        print(f"validate-arch: {len(all_issues)} issue(s) found. Fix workspace.dsl or add to KNOWN_MAPPINGS.")
        return 1

    print("validate-arch: all checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
