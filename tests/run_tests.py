#!/usr/bin/env python3
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import textwrap
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def _print_missing_config_and_exit(missing: list[str]) -> None:
    msg = "\n".join(f"- {item}" for item in missing)
    print(
        textwrap.dedent(
            f"""
            Production-mode tests are enabled, but required configuration is missing.

            Fix the following and re-run:
            {msg}

            Re-run:
              PRODUCTION_TESTS_CONFIRM=1 TEST_MODE=production python3 tests/run_tests.py
            """
        ).strip()
    )
    raise SystemExit(2)


def _run(cmd: list[str], *, cwd: Path = REPO_ROOT) -> None:
    subprocess.run(cmd, cwd=str(cwd), check=True)


def main() -> int:
    mode = os.environ.get("TEST_MODE", "").strip().lower()
    if mode not in {"demo", "production"}:
        print(
            "Missing or invalid TEST_MODE. Set TEST_MODE=demo or TEST_MODE=production.\n"
            "Examples:\n"
            "  TEST_MODE=demo python3 tests/run_tests.py\n"
            "  PRODUCTION_TESTS_CONFIRM=1 TEST_MODE=production python3 tests/run_tests.py"
        )
        return 2

    if mode == "demo":
        _run([sys.executable, "-m", "unittest", "discover", "-s", "tests/unit", "-p", "test_*.py"])
        return 0

    missing: list[str] = []
    if os.environ.get("PRODUCTION_TESTS_CONFIRM") != "1":
        missing.append("PRODUCTION_TESTS_CONFIRM=1 (explicit acknowledgement)")
    if shutil.which("docker") is None:
        missing.append("docker (Docker CLI + daemon installed and running)")

    if missing:
        _print_missing_config_and_exit(missing)

    try:
        subprocess.run(
            ["docker", "compose", "version"],
            cwd=str(REPO_ROOT),
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        _print_missing_config_and_exit(
            [
                "Docker Compose v2 available as `docker compose` (install/upgrade Docker Desktop or docker-compose-plugin)"
            ]
        )

    try:
        subprocess.run(
            ["docker", "info"],
            cwd=str(REPO_ROOT),
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        _print_missing_config_and_exit(
            [
                "Docker daemon reachable (start Docker Desktop / start dockerd; ensure your user can access the Docker socket)",
            ]
        )

    _run([sys.executable, "-m", "unittest", "discover", "-s", "tests/integration", "-p", "test_*.py"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

