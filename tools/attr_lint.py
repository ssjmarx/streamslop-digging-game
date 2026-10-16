#!/usr/bin/env python3
"""attr_lint.py -- the attribution linter for streamslop digging game.

Law (GDD §7): every shipped asset is credited. This linter walks
godot/assets/ and asserts that every asset file appears in
godot/assets/catalog.json. A catalog entry claims files via "path"
(a string) or "paths" (a list of strings), relative to godot/assets/.
catalog.json itself is exempt, and entries may be fileless (e.g. the
procedural sky -- an engine built-in that still deserves its credit).

Matching is one-directional on purpose: a catalog entry whose path does
not exist yet is fine (packs are downloaded later), but a file on disk
without a claim fails the lint.

Exit codes: 0 = every file credited · 1 = uncredited files found ·
2 = catalog missing or unreadable. Run from the repo root; paths are
resolved relative to this script's location, so any cwd works.
"""

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = REPO_ROOT / "godot" / "assets"
CATALOG_PATH = ASSETS_DIR / "catalog.json"


def claimed_paths(catalog: list) -> set:
	"""Flatten every catalog entry's path/paths field into one set."""
	claimed = set()
	for entry in catalog:
		path = entry.get("path")
		if isinstance(path, str):
			claimed.add(Path(path).as_posix())
		paths = entry.get("paths")
		if isinstance(paths, list):
			claimed.update(Path(p).as_posix() for p in paths if isinstance(p, str))
	return claimed


def asset_files() -> list:
	"""Every regular file under assets/ except the catalog and engine
	metadata (*.import files are generated bookkeeping, not assets)."""
	return sorted(
		p for p in ASSETS_DIR.rglob("*")
		if p.is_file()
		and p.name != CATALOG_PATH.name
		and not p.name.endswith(".import")
	)


def main() -> int:
	"""The audit: exit 0 = all credited, 1 = uncredited files, 2 = no catalog."""
	try:
		catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
	except (OSError, json.JSONDecodeError) as exc:
		print(f"attr_lint: cannot read {CATALOG_PATH.relative_to(REPO_ROOT)}: {exc}")
		return 2
	if not isinstance(catalog, list):
		print("attr_lint: catalog.json must be a JSON list of entries")
		return 2

	claimed = claimed_paths(catalog)
	files = asset_files()
	if not files:
		print(
			"attr_lint: no asset files under godot/assets/ -- nothing to check "
			f"(catalog carries {len(catalog)} entries). Vacuous pass."
		)
		return 0

	unclaimed = [
		f.relative_to(ASSETS_DIR).as_posix()
		for f in files
		if f.relative_to(ASSETS_DIR).as_posix() not in claimed
	]
	if unclaimed:
		print(
			f"attr_lint: {len(unclaimed)} uncredited file(s) -- every asset "
			"must be claimed in godot/assets/catalog.json:"
		)
		for rel in unclaimed:
			print(f"  - {rel}")
		return 1

	print(f"attr_lint: {len(files)} asset file(s), all credited. Good.")
	return 0


if __name__ == "__main__":
	sys.exit(main())
