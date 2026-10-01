#!/usr/bin/env python3
"""CI helper: unpacks the REAL Rojo release ZIP committed in the repo and puts rojo on PATH.

    python tools/ci_unpack_rojo.py rojo-7.7.0-windows-x86_64.zip .rojo_bin
"""
import os
import stat
import sys
import zipfile
from pathlib import Path

archive, dest = Path(sys.argv[1]), Path(sys.argv[2]).resolve()
dest.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(archive) as z:
    z.extractall(dest)
exe = next((p for p in dest.rglob("*") if p.name.lower() in ("rojo.exe", "rojo")), None)
if exe is None:
    print("FAIL: no rojo binary inside", archive)
    sys.exit(1)
exe.chmod(exe.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
print("Rojo binary:", exe, "(%d bytes)" % exe.stat().st_size)
gh_path = os.environ.get("GITHUB_PATH")
if gh_path:
    with open(gh_path, "a", encoding="utf-8") as f:
        f.write(str(exe.parent) + "\n")
