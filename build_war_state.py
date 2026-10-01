#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""WAR STATE build runner (v0.2.0).

    python build_war_state.py                 # validate + tests + build (rojo if installed, else offline builder)
    python build_war_state.py --no-rojo       # validate + tests + offline builder only
    python build_war_state.py --serve         # ... then `rojo serve` for live sync into Studio
    python build_war_state.py --write-registry  # regenerate CountryRegistry.json from tools/countries.py
    python build_war_state.py --zip           # also create dist/WarState_READY_BUILD.zip

Since v0.2.0 the files in src/ are the source of truth (the 0.1.0 single-file generator embedded
old sources and would overwrite the new systems). Standard library only, Python 3.8+.
"""
import argparse, json, shutil, subprocess, sys, unittest, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GENERATOR_VERSION = "0.2.0"
sys.path.insert(0, str(ROOT / "tools"))


def write_registry():
    import countries
    path = ROOT / "src/ReplicatedStorage/Shared/Config/CountryRegistry.json"
    path.write_text(json.dumps(countries.country_registry(), ensure_ascii=False, indent=1), encoding="utf-8")
    print("[registry] wrote %d countries" % len(countries.COUNTRIES))


def run_tests():
    suite = unittest.defaultTestLoader.discover(str(ROOT / "tests"), top_level_dir=str(ROOT))
    result = unittest.TextTestRunner(verbosity=1).run(suite)
    return result.wasSuccessful()


def build(use_rojo=True):
    out = ROOT / "build" / "WarState.rbxlx"
    if use_rojo and shutil.which("rojo"):
        r = subprocess.run(["rojo", "build", str(ROOT / "default.project.json"), "-o", str(out)])
        print("[rojo] build", "PASS" if r.returncode == 0 else "FAIL")
        return r.returncode == 0
    import rojo_build
    info = rojo_build.build_place(ROOT / "default.project.json", out)
    print("[offline-builder] %s (%d instances) PASS" % (out, info["instances"]))
    return True


def make_zip():
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    target = dist / "WarState_READY_BUILD.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as z:
        for p in sorted(ROOT.rglob("*")):
            rel = p.relative_to(ROOT)
            if p.is_file() and rel.parts[0] not in ("dist",) and "__pycache__" not in rel.parts:
                z.write(p, Path("WarState") / rel)
    print("[zip]", target)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-rojo", action="store_true")
    ap.add_argument("--serve", action="store_true")
    ap.add_argument("--write-registry", action="store_true")
    ap.add_argument("--zip", action="store_true")
    a = ap.parse_args()
    if a.write_registry:
        write_registry()
    ok = run_tests() and build(not a.no_rojo)
    if a.zip:
        make_zip()
    if ok and a.serve and shutil.which("rojo"):
        subprocess.run(["rojo", "serve", str(ROOT / "default.project.json")])
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
