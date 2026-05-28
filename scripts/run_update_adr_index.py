#!/usr/bin/env python3
"""Кросс-платформенная обёртка над update-adr-index.{sh,ps1}.

Pre-commit на Windows/Linux/macOS вызывает эту обёртку; она выбирает
правильный bash- или PowerShell-скрипт. После пересборки индекса
автоматически добавляет 09-architectural-decisions.md в git stage,
иначе pre-commit ругнётся, что хук изменил файлы.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
INDEX_FILE = REPO_ROOT / "docs" / "architecture" / "09-architectural-decisions.md"


def _resolve_runner() -> list[str] | None:
    """Подбирает интерпретатор. Предпочитаем bash (.sh) — он есть и в git-bash
    на Windows, и в Linux/macOS, и не страдает от ANSI/UTF-8 коллизий
    PowerShell 5.1 на кириллице. PS1-fallback только если bash не нашёлся.
    """
    from shutil import which

    sh_path = REPO_ROOT / "scripts" / "update-adr-index.sh"
    if sh_path.exists() and which("bash"):
        return ["bash", str(sh_path)]

    if os.name == "nt":
        ps_path = REPO_ROOT / "scripts" / "update-adr-index.ps1"
        if ps_path.exists():
            for shell in ("pwsh", "powershell"):
                if which(shell):
                    return [shell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(ps_path)]
    return None


def main() -> int:
    cmd = _resolve_runner()
    if cmd is None:
        print("update-adr-index: skip — ни bash, ни powershell не найдены", file=sys.stderr)
        return 0

    result = subprocess.run(cmd, cwd=REPO_ROOT)
    if result.returncode != 0:
        return result.returncode

    if INDEX_FILE.exists():
        subprocess.run(["git", "add", str(INDEX_FILE)], cwd=REPO_ROOT, check=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
