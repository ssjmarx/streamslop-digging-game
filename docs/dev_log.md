# docs/dev_log.md — Development Log

Session rulings, changelogs, supersessions. Evidence, not law — the law is `docs/GDD.md`
and the plan is `docs/ROADMAP.md`. Newest entries at the bottom.

## Entry #1 — 2026-10-15 — 0.0.1 DIRT: first running build

The world exists. Flat dirt plain at y=0 (scene-configured `VoxelGeneratorFlat` +
`VoxelMesherBlocky` with a colored `VoxelBlockyModelCube` — no textures yet, CREDITS
gets those), sun + procedural sky, one Quaternius guy (Superhero Female, per ruling —
"female normal" turned out to be paid-only) with the full Universal Animation Library
bound at runtime, walk/sprint/crouch/jump, V camera toggle, DEPTH meter reading 0.0.

- **Addons pinned: Voxel Tools 1.7 GDExtension** (tag `v1.7x`) on stock Godot 4.7.2.
  The module (custom-engine) build was also tested and is held in reserve; the
  extension works and keeps the Godots/editor tooling intact. ROADMAP §6 risk #1
  retired — a matching build exists.
- **The invisible-world incident.** First runs spawned the player into an infinite
  fall with no voxels. Bisected with the streaming probe (`probe_terrain.gd`): the
  engine, machine, and both extension flavors were innocent — **a stale `.godot`
  cache built across an extension/scene change silently disabled block scheduling**.
  A clean cache fixed it; the fix that endures is scene-configured terrain (no
  runtime generator/mesher assignment racing the scheduler) + the wipe-cache-on-
  addon-change rule (instructions.md §7). Approximately two hours of debugging, zero
  error messages, one lesson enshrined.
- **Three real bugs fixed on first boot:** (1) the FP camera started inside the
  avatar's head — initial camera state was never applied, only the toggle; (2) the
  glTF importer strips `_Loop` suffixes and loop flags from animation clips — clip
  names probed, loops re-applied by name (LOOPERS list); (3) the spawn gate now pins
  the player until the ground's collision exists, so async streaming can never
  dump anyone into the void (5s failsafe).
- **Rulings made in passing:** the default avatar is Superhero Female (9 asset files,
  catalog-claimed); the animation library ships as `anims/quaternius/UAL1_Standard.glb`;
  `*.import` files are engine metadata, exempt from attr_lint; exports are deferred
  until 0.0.1 passes the feel checklist — in-editor testing only until then.
- **Ruling addendum, same day (first feel pass):** first person keeps the body
  visible — camera just forward of the face, body view-aligned (supersedes GDD §5's
  hide-the-body v0.1 choice; GDD amended). Third-person body faces movement — the
  UAL library has no lateral clips, so forward-run-on-strafe read as sliding.
  Camera flip moved V -> P; crouch rebound Ctrl -> C. Ground became a two-tone
  checkerboard (`VoxelGeneratorScript`, 8m squares — motion aid and strata prep).
  "White world" lesson: `VoxelBlockyModelCube.color` bakes as VERTEX colors and
  renders only through a material with `vertex_color_use_as_albedo = true` — now
  the terrain's `material_override` (instructions.md §7). Later same-day rulings:
  crouch is hold, not toggle; hair ships — Hair Long, rigged-to-Head-bone,
  attached via `BoneAttachment3D` on the universal rig's Head bone. Facing
  lesson: models face -Z at yaw 0, so movement-facing is
  `atan2(-dir.x, -dir.z)` — the unnegated atan2 points her exactly backwards
  (verified by eye, laughed at, enshrined). FP camera slide ruling: while
  running or crouching, the FP camera lerps further forward than its base
  offset (dials: FP_RUN_SLIDE / FP_CROUCH_SLIDE / FP_SLIDE_SPEED; base
  captured from the scene at _ready, never overwritten) — the BODY never
  moves. FP eye lesson: ONE writer per node — the slide function owns the
  whole fp_eye position (height lerped, never snapped). Airborne addendum:
  FP_JUMP_BUMP adds a slight forward bump while off the floor. Depth ruling:
  the disc starts 20m thick and its floor grows ahead of the player —
  `generator.ensure_depth(depth + margin)` + `emit_changed` re-generates
  affected blocks; no bedrock, GDD law intact. Rescue: falling past -30m
  teleports to spawn and re-runs the loader. Wheel zoom: TP cranes the boom
  1.5–8m, FP zooms FOV 50–90 (also the eyebrow-color inspector). Comment-law
  ruling: witchgame's comment auditor (tools/build_project_map.py) now runs
  here too — the "no linter ever" clause is superseded; every docstring
  condensed to one dense line per func, PROJECT_MAP.md born (11 files,
  41 funcs). CI still enforces only the credits. World-limit ruling: the
  world is a WORLD_RADIUS=50 disc centered on spawn — the generator refuses
  dirt beyond the rim (void beyond, walked off at will); streaming distance
  went back to 256 (the earlier 50 was world scope, not render distance).
  FP camera offset hand-tuned by the human in player.tscn.
  node-level `material_override` with a per-piece surfaces-debug print).
  Eyebrow verdict from the dump (probe_avatar_dump.gd): the character ships
  her OWN 'Eyebrows' mesh (MI_Hair_2 / T_Hair_2 grayscale, untinted -> reads
  light gray = the 'white brows'), and the standalone piece was doubling it.
  Piece removed; the built-in mesh gets a brown-tinted override at load
  (_style_builtins) -- textured brows, skinned to her animated skeleton by
  construction.
  Eyebrow verdict from the print (both pieces painted, still white): their UVs
  sample a blank region of the T_Hair_2 atlas — brows/lashes went FLAT brown
  (BROW_COLOR); the hair keeps the textured look. World-limit ruling:
  the world is a WORLD_RADIUS=50 disc centered on spawn — the generator refuses
  dirt beyond the rim (void beyond, walked off at will); streaming distance went
  back to 256 (the earlier 50 was world scope, not render distance). FP camera
  offset hand-tuned by the human in player.tscn. Hair addendum, same
  hour: head-bone attach added the head height twice (full-body bind space), so the
  pieces attach at the avatar root behind an `HAIR_OFFSET` dial, and the import's
  dropped textures are rebound by a shared hair material — T_Hair_2 grayscale
  detail + normal, brown-tinted. FP camera nudged to -0.55. Spawn gate saga
  concluded: v1 (position pin) always timed out, v2 (clamped gravity fall) embedded
  her halfway into the floor once collision landed mid-fall — both replaced by a
  proper loading sequence: main.gd holds the player with physics OFF until
  `VoxelTerrain.is_area_meshed` over the spawn column is true (the documented
  mesh-collider gate), then hands physics over; 15s loud failsafe.
- **Feel checklist status:** still pending — the human runs it next, in a window.
  Known dials if anything feels wrong: `MODEL_YAW` (moonwalk = flip),
  `BODY_TURN_SPEED` and the speeds in `player_controller.gd` `# -- Config ------`,
  `CHECKER_SIZE` / cube colors for the grid, view distances.


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
