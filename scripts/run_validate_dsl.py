#!/usr/bin/env python3
"""Кросс-платформенная обёртка над validate-dsl.{sh,ps1} (HLE-510, Фаза 8a).

Скрипт validate-dsl ещё НЕ создан (он входит в HLE-510). Эта обёртка:
- если найден scripts/validate-dsl.sh (или .ps1 на Windows) — запускает его;
- иначе печатает предупреждение и возвращает 0, не ломая pre-commit.

Когда HLE-510 будет слит — обёртка автоматически начнёт делать настоящую
проверку, никаких изменений в .pre-commit-config.yaml не потребуется.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]


def _resolve_runner() -> list[str] | None:
    from shutil import which

    sh_path = REPO_ROOT / "scripts" / "validate-dsl.sh"
    if sh_path.exists() and which("bash"):
        return ["bash", str(sh_path)]

    if os.name == "nt":
        ps_path = REPO_ROOT / "scripts" / "validate-dsl.ps1"
        if ps_path.exists():
            for shell in ("pwsh", "powershell"):
                if which(shell):
                    return [shell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(ps_path)]
    return None


def main() -> int:
    cmd = _resolve_runner()
    if cmd is None:
        print(
            "validate-dsl: skip — scripts/validate-dsl.{sh,ps1} ещё не создан "
            "(см. HLE-510, Фаза 8a)",
            file=sys.stderr,
        )
        return 0

    return subprocess.run(cmd, cwd=REPO_ROOT).returncode


if __name__ == "__main__":
    sys.exit(main())
