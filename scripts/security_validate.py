#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    required = [
        ".github/workflows/security.yml",
        "docs/security/threat-model.md",
        ".gitignore",
    ]

    missing = [p for p in required if not (REPO_ROOT / p).exists()]
    if missing:
        print("Security validation failed. Missing:\n" + "\n".join(f"- {m}" for m in missing))
        return 1

    gitignore = (REPO_ROOT / ".gitignore").read_text(encoding="utf-8")
    must_contain = [".env", "*.pem", "artifacts/"]
    missing_rules = [r for r in must_contain if r not in gitignore]
    if missing_rules:
        print("Security validation failed. .gitignore missing rules:\n" + "\n".join(f"- {r}" for r in missing_rules))
        return 1

    print("Security validation OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

