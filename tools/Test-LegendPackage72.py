"""Validate a distributable, including every manifest hash, before a clean launch."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import json
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument("package", type=Path)
parser.add_argument("--extract", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
required = {
    "src/legend_career.gd", "src/legend_match.gd", "src/legend_save.gd",
    "src/legend_menu.gd", "src/legend_hud.gd", "src/legend_locale.gd",
    "assets/ui/en72_legend.tsv", "docs/RELEASE_NOTES_72.md",
    "tools/godot/Godot_v4.5.1-stable_win64.exe",
    "tools/Test-LegendIntegration72.gd", "version.json", "Spike Forever.exe",
}
with zipfile.ZipFile(args.package) as bundle:
    names = bundle.namelist()
    assert len(names) == len(set(names)), "Duplicate archive entries"
    assert required.issubset(names), "Required career/runtime files missing"
    for name in names:
        part = PurePosixPath(name)
        assert not part.is_absolute() and ".." not in part.parts and ":" not in name
        assert not any(item in part.parts for item in (".git", ".runtime", ".tmp"))
        assert not part.name.startswith("legend-") or part.suffix != ".json", "Personal career leaked"
        assert "roster-overrides" not in name, "Personal database overrides leaked"
    manifest = json.loads(bundle.read("release-manifest.json"))
    version = json.loads(bundle.read("version.json"))["version"]
    assert manifest["version"] == version and version.startswith("0.72.")
    assert set(names) == set(manifest["files"]) | {"release-manifest.json"}
    for name, expected in manifest["files"].items():
        digest = hashlib.sha256()
        with bundle.open(name) as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        assert digest.hexdigest() == expected, f"Invalid archive hash: {name}"
        assert hashlib.sha256((root / name).read_bytes()).hexdigest() == expected, f"Stale file: {name}"
    if args.extract:
        target = args.extract.resolve()
        assert target.is_relative_to(root) and target != root
        assert not target.exists(), "Clean launch directory must be new"
        target.mkdir(parents=True)
        bundle.extractall(target)
report = {
    "version": version, "files": len(manifest["files"]),
    "bytes": args.package.stat().st_size,
    "sha256": hashlib.sha256(args.package.read_bytes()).hexdigest(),
    "all_manifest_hashes": True, "matches_workspace": True, "no_personal_saves": True,
}
print("LEGEND72 PACKAGE PASS " + json.dumps(report))
