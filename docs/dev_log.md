# docs/dev_log.md — Development Log

Session rulings, changelogs, supersessions. Evidence, not law — the law is `docs/GDD.md`
and the plan is `docs/ROADMAP.md`. Newest entries at the bottom.

## Entry #0 — 2026-10-15 — repo setup

The repository was initialized and the founding design conversation (a single saved chat,
`convo.md`, 1,792 lines) was consolidated into the memory bank and then deleted, by design.
These docs are now the only record. Rulings made or confirmed during setup:

- **Name.** The project is "streamslop digging game", all lowercase, everywhere — docs,
  window title, store copy. The remote repos are `streamslop-digging-game` (gitea +
  github, mirrored: one push to `origin` lands on both).
- **Two roots, on purpose.** The Godot project lives in `godot/` (`res://` is its root);
  docs, tooling, CI, and agent config live at the repo root, witchgame-style. Amended
  from the founding conversation, which put `dig.gd` at the repo root: it now lives at
  the Godot project root (`godot/dig.gd`) so `res://` can see it. Same street,
  different door.
- **The freeze is spiritual.** `dig.gd` may be touched (refactors, engine upgrades,
  netcode seams); the feel may not (GDD §2). CI enforces only attribution, plus one
  cultural echo job. The founding conversation's CI freeze job is superseded.
- **There are no tests. There will never be tests.** The feel checklist (ROADMAP §4) is
  the entire regression suite.
- **Engine pinned.** Godot 4.7.2 via the Godots version manager (supersedes the
  conversation's early "4.4.x"). `godot_voxel` and GodotSteam must be pinned to
  4.7-matching builds; availability of a 4.7-compatible godot_voxel build is the first
  open risk (ROADMAP §6).
- **Catalog contract.** `godot/assets/catalog.json` claims files via `path`/`paths`
  (paths relative to `godot/assets/`); the starter entries' paths are provisional until
  the CC0 packs are imported (0.0.5 CREDITS). Entries may be fileless (engine built-ins
  deserve credit too).
- **Tooling.** `.vscode` tasks/launch target `godot/`; `tools/attr_lint.py` is the only
  gate; `.clinerules` boot order = instructions → ROADMAP → GDD → dev_log. GDScript
  comment house discipline is kept by hand; there is no linter and there will never be
  one.
- **Honest gaps.** Exit tests for v0.0.1 DIRT, v0.0.3 MEMORY, v0.0.5 CREDITS, v0.0.7 THE
  WARDROBE, and v0.0.8 THE FOLDER were drafted fresh at setup (the founding
  conversation's verbatim versions, where they existed at all, did not survive
  consolidation). Amend freely at those milestones.
- Riff canon that survives as design: the surrender modal, the tide, the stopwatch's
  silent reset, the deepest-first pour, the burial fossil, "thanks for digging"
  (GDD Appendix A). Jokes that became architecture: DirtBus `by_peer`, DigAuthority as
  the single choke point, the save file as the network protocol.
