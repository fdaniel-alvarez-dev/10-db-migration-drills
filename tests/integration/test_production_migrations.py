from __future__ import annotations

import subprocess
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def _run(cmd: list[str], *, timeout_s: int = 120) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(REPO_ROOT),
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout_s,
    )


class TestProductionMigrations(unittest.TestCase):
    def test_migrations_apply_and_status(self) -> None:
        try:
            _run(["docker", "compose", "up", "-d", "--build"], timeout_s=600)

            deadline = time.time() + 90
            while True:
                try:
                    _run(
                        ["docker", "compose", "exec", "-T", "postgres-primary", "psql", "-U", "app", "-d", "appdb", "-c", "select 1;"],
                        timeout_s=30,
                    )
                    break
                except Exception:
                    if time.time() > deadline:
                        raise
                    time.sleep(2)

            _run(["make", "migrate"], timeout_s=180)
            out = _run(["make", "migrate-status"], timeout_s=120).stdout
            self.assertIn("schema_migrations", out)
        finally:
            subprocess.run(["docker", "compose", "down", "-v"], cwd=str(REPO_ROOT), check=False)

