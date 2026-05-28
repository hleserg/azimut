#!/usr/bin/env python3
"""Cross-platform wrapper for export_mermaid.sh / .ps1 (HLE-528).

Runs scripts/export_mermaid.sh on Linux/macOS/WSL, or .ps1 on Windows.
Designed to be called from a pre-commit hook.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from shutil import which

REPO_ROOT = Path(__file__).resolve().parents[1]


def _resolve_runner() -> list[str] | None:
    sh_path = REPO_ROOT / "scripts" / "export_mermaid.sh"
    if sh_path.exists() and which("bash"):
        return ["bash", str(sh_path)]

    if os.name == "nt":
        ps_path = REPO_ROOT / "scripts" / "export_mermaid.ps1"
        if ps_path.exists():
            for shell in ("pwsh", "powershell"):
                if which(shell):
                    return [shell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(ps_path)]
    return None


def main() -> int:
    cmd = _resolve_runner()
    if cmd is None:
        print(
            "export-mermaid: skip — scripts/export_mermaid.{sh,ps1} not found",
            file=sys.stderr,
        )
        return 0
    return subprocess.run(cmd, cwd=REPO_ROOT).returncode


if __name__ == "__main__":
    sys.exit(main())
