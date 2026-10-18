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


## Entry #2 — 2026-10-17 — 0.0.1 closed; the corey rulings; 0.0.2 THE VERB built

**0.0.1 DIRT closed.** The feel checklist ran in a window and was "tweaked into
passing" (the owner's words); the tag stands, the question is retired, the dev-log
line that said "still pending" was drift and is hereby corrected.

**Rulings (2026-10-17, by corey — the human owner; "dave" is retired everywhere):**

- **dave → corey.** All nine instances across `.clinerules`, `instructions.md`, GDD,
  ROADMAP — including the Shovelhead avatar credit, which was always the owner's joke
  and renames with him.
- **0.3.0 is the initial Steam release** ($5). Verbatim: "0.3.0 is the first version
  where the joke is legible — a digging game with something entirely unrelated that
  you can go do instead — so the initial $5 ask is for 'a game where you can dig the
  ground but also it's a giant co-op quake 3 level.'" ROADMAP §2/§3/§5 amended; the
  0.1.0–0.2.x ladder is explicitly uncarved until the 0.1.0 gate. GDD §6 preamble and
  the Workshop-at-launch line amended to match. THE LAUNCH becomes THE RELEASE.
- **Ergonomic replaces Golden** in the GDD §3 tier table: tier 3 is now the Ergonomic
  Shovel — radius 2.3, same as Pro (the plateau made literal), $25,000, "same stats.
  ergonomic." GameState.SHOVELS updated, now with `short` display names
  (toy/trowel/regular/ergonomic). The 0.0.4 pour-rate exit test reads ergonomic.
- **Asset plan.** Kenney for sounds (catalog swapped from the Sonniss placeholders;
  the whiff is provisional — no true swing whoosh exists in any Kenney pack, replace
  when one is sourced). Karl Casey "Extreme Essentials Vol. 2" staged for future
  Quake-ish combat music. Pixabay exploration tracks staged; exactly one implements
  this patch: "Exploration" by Melodigne. New `assets_unimplemented/` at the repo
  root, gitignored: one subfolder per source, each carrying its license and
  attribution (kenney ×3, quaternius ×3, karl-casey + the AlkaKrab PDF, pixabay with
  the Content License summary preserved in full).
- **The stop sign** (Quaternius Street Pack) is buried FACE-UP 10m under spawn, dead
  center of the disc — you dig down onto its face. It is a live RigidBody3D: frozen
  fossil until the dirt above it is dug away (the §6f pattern, prototyped early),
  then knockable forever via dig.gd's swing ray (impulse + clang, no dirt — it is
  not dirt). **No physics plugin**: Godot 4.7's embedded physics (Jolt) is the
  engine. Detection is the swing's own query extended to rigid bodies; a shovel-head
  hurtbox (tunneling, desync from the dig ray, netcode-hostile) and a fighting-game
  frame window (unneeded coupling at 0.45s cadence) were considered and rejected.
- **Debug tier cycler** on `[` / `]` with a SHOVEL readout in the HUD, so "tiers
  widen only" is testable before the kiosk exists.

**0.0.2 THE VERB — what shipped (uncommitted; awaiting the human's review and the
ten-minute fun verdict):**

- `godot/dig.gd` (the Appendix B shape): DIG_RANGE 10, SWING_COOLDOWN 0.45 (frozen,
  forever), one camera ray at the active instant, sphere erase on CHANNEL_TYPE via
  `do_sphere` (v1.7 signature verified by introspect: two args, no mesh-destroy
  flag), approx-honest count (0.9 × sphere volume), +dirt, best_depth, `dirt_dug` +
  `depth_changed` on DirtBus, clang + dig thud on hit, whiff on miss, dig-jump
  (granted only when airborne at swing time — ground digs never pogo; flight bounded
  by dirt). Props take the impulse instead of the sphere; frozen props refuse.
- The swing anim is UAL `Sword_Attack` (clip name verified by probe) with a
  locomotion lock until the clip ends; the shovel is the Survival Pack OBJ on
  `hand_r` via BoneAttachment3D, AABB-normalized to 1.1m (raw diagonal 3.96m —
  Quaternius export scale), pose by dials.
- The diglog begins: `scripts/hole/diglog_writer.gd` appends `{"p":[x,y,z],"r":radius}`
  to `user://hole/diglog.jsonl` per dirt_dug (file verified on disk). Replay-on-load
  is 0.0.3's problem.
- Music: Melodigne's "Exploration" loops on the surface and fades out below the rim —
  GDD §8 ("below the rim: silence and the clang") implemented with the fade baked in
  so 0.0.2 cannot violate the law retroactively.
- **HUD bug found and fixed during boot recon:** nothing ever added the player to the
  "player" group, so DEPTH had been pinned at 0.0m since day one — the 0.0.1 exit box
  passed vacuously and the bug hid behind it. `add_to_group("player")` in `_ready`.
- Gates: class rescan ✓ · headless probe (main) ✓ — loader 0.4s, streaming true,
  hair + shovel attached · `build_project_map.py` ✓ (16 files, 63 functions) ·
  `attr_lint.py` ✓ (20 files credited). The single "resource in use at exit" line is
  probe-quit noise (the BGM stream playing at forced quit), not a game leak.

**Known dials for the feel pass:** `DIG_JUMP_VELOCITY` (5.5), `KNOCK_POWER` (7.0),
`SHOVEL_OFFSET` / `SHOVEL_ROT_DEG` (pose is a guess until eyes land on it), the stop
sign's reveal probe height (FACE_PROBE_UP, 1.6m), `SURFACE_DB` (−14). Also pending a
human ear: clang/dig/whiff pick approval, and a real whoosh for the whiff.


## Entry #3 — 2026-10-17 — tweak round one: Q3 physics, the floor-grow bug, exports as law

**Rulings (by corey, from the first 0.0.2 playtest):**

- **The FPV body stays visible — "invisible FPV bodies are a personal bugbear."**
  The hide-the-body option is off the table, not just deferred. The dig-jank fix is
  the clip, not the camera. Animation layering (the upper-body/lower-body split) is
  PINNED until he has tried browsing the available clips via exports.
- **The swing becomes browsable:** `swing_clip` (default `Punch_Jab` — the power-swing
  windup of `Sword_Attack` was the jank) and `swing_playback_speed` are exports; the
  locomotion lock is capped at the 0.45s cooldown so cadence never waits on animation.
- **Export vars are law** (GDD §13 + instructions.md §7): every tunable ships as an
  `@export` under a named `@export_group` — the inspector is the tuning surface, the
  editor's Remote tab tweaks live. Law-locked numbers stay consts and are never
  exported: the 0.45s swing, DIG_RANGE, the tier table, MODEL_YAW, the rim (y=0).
- **Dig-jump only off real jumps:** a `jumped` flag arms on the space-jump and on
  every granted dig-jump (a dig-jump is a jump — the 5m-hole chain law), disarms on
  landing. Falls never arm it.
- **Shovel pose dialing PINNED** until the jab is seen; the pose consts became exports
  (`Held Shovel` group) so the dialing session is inspector work when it happens.
- **Q3 physics imported, avatar-mapped (Option A):** the numbers were pulled verbatim
  from the GPL source (ioquake3 master): `JUMP_VELOCITY 270` (bg_local.h),
  `DEFAULT_GRAVITY 800` (bg_public.h), player 56u tall (MINS_Z −24 / HEIGHT 32),
  duckScale 0.25, friction 6, accelerate 10, airAccelerate 1, STEPSIZE 18. Mapping:
  1.8m capsule = 56u player = 0.0321 m/u → gravity **25.7 m/s²**, jump **8.67 m/s**,
  jump height 1.46m (clears a voxel; air time 0.68s). The sign-off test: Q3 crouch
  = 80u/s = 2.57 m/s under this mapping — the GDD's sacred 2.5 m/s crouch was Quake
  all along. STEPSIZE noted (0.58m), no stair-stepper built. Props still fall at the
  project default 9.8 — the sign's knocked arc reads floaty next to a 25.7 player;
  `gravity_scale` on the sign is the zero-code dial if it reads wrong.
- **The sign now goes flying:** `knock_power` 7 → 50 (export), mass 12 → 5. The old
  numbers were Δv ≈ 0.58 m/s — a whisper.

**The floor-grow bug (found by the same playtest):** Corey dug under the disc,
dropped, and **no new dirt ever generated** — the GDD §4 infinite-down machinery had
never been exercised (0.0.1 had no shovel) and was simply broken.
`probe_depth_floor.gd` isolated it: `emit_changed()` does NOT regenerate
already-generated blocks in godot_voxel v1.7 — the floor grew in data but the
terrain never re-asked. Reassigning the generator DOES regenerate but **wipes player
edits** (also probe-proven — the carved hole refilled). The fix is surgical:
`ensure_depth` now grows in 16m block steps and returns whether it grew; when it
does, `main.gd write_floor_blocks()` generates the newly-dirtied slice directly and
writes it with `try_set_block_data` — data blocks are owned by the terrain, so holes
survive. Probe verdict: dirt to −112, carved hole intact, PASS.
**The −30m absolute rescue is also dead:** rescues now fire below the generator
floor (`rescue_below_floor`, 15m) — deep digging no longer teleports, deliberate
void dives still do. (Corey's two playtest "teleports" were deliberate void dives;
the absolute-rescue bug this surfaced would have made −31m unlivable.)

**Gates:** depth probe PASS · main smoke clean (no script errors; hair + shovel
attached; loader 0.3s) · `build_project_map.py` ✓ (17 files, 67 functions) ·
`attr_lint.py` ✓. Also in this round: the dig swing defaults to `Punch_Jab` with
exported playback speed; the whole feel surface is exported into groups (Quake
Physics / Movement / Camera Feel / Held Shovel / Dig Swing / Dig Feel / Stop Sign /
BGM / Depth Floor).

**Addendum, same day — the instrument (crosshair + dig preview):** the first
playtest surfaced "sometimes it digs 2 tiles then stops, sound keeps going" and
FP-vs-TP digging behaving differently. Root cause of the divergence is now fixed at
the source: **one aim ray, head origin + active-camera direction**, owned by the new
`scripts/player/aim.gd` (the sight) — dig.gd's swing asks it at swing time, so verb
and instruments can never disagree. The instruments, per ruling: Kenney Crosshair
Pack #15 (in range) / #16 (out of range), Light variants, drawn as a **billboarded
2D sign at the exact world hit point** (parks at ray end with #16 on a clean miss);
plus a **faint blue seam-glow** — one inflated wireframe box per DIRT voxel the
current shovel would take (data truth via the TYPE channel, air cells skipped,
128-instance MultiMesh budget) — visible only when in range. The glow previews DATA
while the clang previews COLLISION: during a "stopped digging" episode, a glow-vs-
clang disagreement is the diagnostic for the suspected collision/voxel-data mismatch
on the surgical floor blocks. Packed staged (`assets_unimplemented/kenney/
crosshairs/`), #15/#16 implemented + cataloged (`ui_crosshair`), dials exported
("Aim" group). Gates: smoke clean (0 script errors), audit ✓ (18 files, 77
functions), lint ✓ (22 files). The "stops digging" mystery stays OPEN until Corey
reads the instrument during an episode — prime suspect remains the floor-write
collision, with punch-through/sphere-sweep held in reserve.

**Addendum 2 — the glow-vs-dig misalignment, root-caused:** glow and crosshair
aligned, but the dig erased fewer tiles than predicted, inconsistently (1–4 of a
predicted 4 at toy radius). Probe (/tmp, throwaway) verdict: **`do_sphere` samples
voxel lattice points — cell min-corners — not cell volumes**; the glow previews
cell centers. Corner-sampling matched the erase 8/8; center-sampling 4/7. Because
the corner set depends on where the hit lands inside a cell, the count swung 1–4.
Fix: the strike shifts the sphere center +0.5 — equivalent to center-sampling —
so the hole centers on the aim and the glow's prediction is exact, every swing,
every tier. The diglog replay convention (0.0.3) must apply the same shift;
commented in diglog_writer.gd and instructions.md §7.

**Addendum 3 — the +0.5 was the wrong sign, and do_sphere left the strike:** the
shift shipped backwards (needed −0.5, shipped +0.5, caught by playtest: toy shovel
dug nothing ever; bigger tiers scraped offset crumbs). Corey's ruling superseded
the whole approach rather than fixing the sign: **the strike no longer uses
`do_sphere` at all.** `aim.targeted_voxels(center, radius)` is now the targeting
function — every DIRT cell whose center is inside the strike sphere — and the
glow draws that array while the strike erases it (`set_voxel` per cell, signature
verified against the pinned extension). Prediction equals outcome by construction.
Dirt counts are now exact, so `slop_ratio` (the volume-estimate dial) is deleted;
the diglog replay rule (0.0.3) re-derives cells through targeted_voxels' rule;
do_sphere survives only as a future bulk-eraser primitive, with its lattice
semantics documented in §7. Gates: smoke clean (0 script errors), audit ✓
(18 files, 77 functions), lint ✓.

**Addendum 4 — the glow was stale, not wrong:** the targeting array was only
recomputed when the aim crossed a cell boundary, so up to a meter of aim drift
never reached the display while the strike always used the live center — a
systematic highlight-vs-hole mismatch that survived even the shared array. The
preview now recomputes every physics frame (`targeted_voxels` is ~125 reads,
microseconds); the force-refresh handshake is deleted. Ruling: an instrument is
live or it is lying.

**Addendum 5 — three rulings, one honest miss:** (1) **DIG_RANGE 10 → 5** (Appendix
B amended). (2) **Off the rim, nothing generates and the rescue fires fast:** the
floor-grow call now requires the player to be inside the disc — it had chased
falling players downward forever outside it, which also meant the floor-relative
rescue never fired for rim-jumpers; a second condition rescues at −20m outside the
disc (`void_rescue_depth`). (3) **The rim wall:** one voxel ring at the disc's edge
is TYPE 3 bedrock — black/grey, undiggable (targeted_voxels only returns dirt
types), clangs the stop-sign clang with no dig thud, and still grants shovel jumps
(the dig-jump grant moved out of the erase path). SIDES ONLY by amendment — no
bottom shell; the infinite-down law is untouched. Honest miss recorded: the
Held Shovel exports were boot-time-only (read once at attach), so Remote-tab
dialing did nothing — they now have setters calling `_apply_shovel_pose()`, as do
aim's `crosshair_size` and `glow_color`. Ruling: exports the human tunes by eye
must apply live, or they are not exports, they are README text. Gates: smoke
clean, depth probe PASS, audit ✓ (18 files, 77 functions), lint ✓.

**Addendum 6 — two gears, muffled ears:** (1) Movement is run/walk: **run is the
DEFAULT at full Q3 speed — 10.3 m/s** (g_speed 320u, avatar-mapped; not 7.0), the
sprint key/action/branch are deleted, **walk is held on V at 5.0** with the Walk
clip, and the run cycle is Jog_Fwd with live `run_anim_speed` / `walk_anim_speed`
dials (Corey tunes cycle rates by eye). (2) The music's rim-fade is replaced by an
**occlusion low-pass**: a runtime BGM bus whose cutoff follows the count of dirt
cells in the column overhead (capped, exponential mapping, smoothed) — dig out the
sky and the music returns at any depth. GDD §5/§8 amended; §8's
silence-and-the-clang superseded by ruling.

**Addendum 7 — dynamic cadence, the final ladder, the checker restored:** (1)
Movement speeds are the tested ladder: **run 10.3 / walk 1.288 (stealth and
roleplay browse, held on V) / crouch 0.966**. §6f amendment: the backhoe keeps the
old sacred 2.5 — the player's stealth crouch is now slower — and the one-full-hour
drive stands. (2) Animation cadence is now dynamic, per the vojtechstruhar.com
speed-scale technique: **scale = ref_scale x speed / ref_speed, per clip, fed the
live horizontal velocity.** Calibration exports ("Anim Calibration" group,
eye-tuned): Jog_Fwd (10.3, 6.0), Walk (5.15, 1.0), Crouch_Fwd (2.575, 0.75). The
static run_anim_speed/walk_anim_speed dials are deleted — when acceleration
arrives, cadence follows reality for free. (3) CHECKER_SIZE returned to 8 (the 1m
slide-test grid served its purpose; Corey reverted). Gates: smoke clean, audit ✓,
lint ✓.

**Addendum 8 — the shovel gets its windup (and its joke):** (1) `swing_clip` is now
an `@export_enum` dropdown carrying the full probed UAL inventory (43 clips;
`probe_ual_anims.gd` is the drift-check; `has_animation()` fails safe on a stale
entry). (2) The default swing clip is **Sword_Attack** again — the power swing's
windup is now load-bearing. (3) **Fighting-game startup**: `startup_frames`
(export, Dig Feel, default 9 physics frames) delays only the FIRST strike of a
chain — the clip plays during the windup, and holding the button or spam clicking
cancels follow-ups straight into their hits; the 0.45s cadence stays
button-to-button (the startup window blocks new initiations until it resolves).
(4) **The easter egg, final form**: every swing rolls 1-in-256 (`JAB_ONE_IN`) to
land a secret Punch_Jab instead of the chosen clip; the swing lock reads the
chosen clip's length. Gates: smoke clean (0 script errors), audit ✓ (18 files, 80
functions), lint ✓.

lint ✓.

**Addendum 9 — Minecraft-style music, and two feel notes for the bank:** the BGM
rim-fade is replaced by a scheduler: silence (random 60–180s) → random track (no
immediate repeats) → 10s fade-in → ~90s of play → 10s fade-out → silence. The fade
anchors to the track's natural end if shorter. Both Pixabay tracks are now
implemented (catalog `music_exploration_01`/`_02`; the occlusion low-pass rides
along through fades and silence alike — the filter is the world's, the scheduler is
the radio's). Feel notes from the playtest, recorded as rulings/intent: **30
startup frames sync Sword_Attack's windup perfectly** ("really slick, the initial
windup following my beating the crap out of the ground"), and chained shovel jumps
don't sync perfectly with the animation — players will learn the timing to stay
airborne, and aerial speed stays high to promote the tech. Gates: smoke clean, audit
✓ (18 files, 84 functions), lint ✓ (23 files).

**Addendum 10 — the world speaks: the ambience engine.** The full layered kit
(34 Pixabay tracks, all staged in `assets_unimplemented/pixabay/ambience/` with
attribution) arrived; 14 shipped in 0.0.2: surface beds (Wind Rustling Grass,
Birds Chirping Calm, Leaves Rustling), grotto beds (Low Hum, Cavewind), and
one-shot pools — meadow (Dove, Distant Owl, Cuckoo) and grotto (Water Drip, Cave
Echo, Rock Plop, Bat Chirp, Bird Wings, Mouse). `ambience.gd` runs the beds
always-on and crossfades by DEPTH (ruling: not the sky ray — ambience is where you
are, music is what's above you), while a random-timer one-shot scheduler plays
from the pool your depth earns. Deferred as designed: positional water beds (no
water exists), rain/thunder (first weather; GDD §4's below-y=0 rule), day/night
bird pools (no time-of-day), all Alts — staged, attributed, waiting for their
world features. GDD §8 amended: two ambiences replace the single wind-loop
promise. Gates: smoke clean (0 script errors), audit ✓ (19 files, 89 functions),
lint ✓ (37 files).

**Addendum 11 — the FP lens gets a collision hull, the head learns to duck:** the
two nits were one root cause — the FP lens rode a fixed 0.25m forward offset with
no collision, so it lived inside voxels at dig faces (aim parallax at point-blank,
screen full of dirt) and the swinging head/hair swept the lens. Fix: (1) **the FP
lens rides a collision SpringArm3D** — walls retract the lens back toward the eye;
(2) **the FP head tuck** — in first person the Head bone scales to a speck
(`set_bone_pose_scale`; no scale tracks in the clips to fight) and the hair
pieces + Eyebrows hide. Both are exported live dials (`fp_arm_length`,
`fp_head_tuck`, `fp_head_tuck_scale` in the "FP Camera" group). Multiplayer
ruling: the tuck is a local-view artifact — gated on this client's camera mode,
per-instance only; replication never carries mesh state.

**Addendum 12 — the spring flip pointed the lens backward, and the shadow ghost
shipped:** SpringArm children inherit the arm's basis, so PI-flipping the FP arm
to push the lens forward ALSO flipped its view 180° (camera behind the head, pitch
mirrored). The SpringArm reverted; the FP collision is now a hand-rolled clamp —
one physics ray from the eye along its forward, the lens pulled back to the hit
minus margin — sign-safe by construction (`_update_fp_arm`; what the SpringArm
gave up — shape casting — is recoverable via cast_motion if edge clipping ever
shows). The **shadow ghost shipped**: a second avatar on render layer 2 (both
camera culls exclude it; the sun casts it), mirrored per physics frame from the
real skeleton with the Head tuck scale stripped and the same MODEL_YAW — the FP
lens never sees it, your shadow keeps a full animated head with long hair, and
the real avatar's meshes drop `cast_shadow` while tucked. Blender head
extraction deferred-but-canonical (bpy weight-threshold script) for when a
standalone head asset is wanted.

**Addendum 13 — one shadow source, tight-space eyes, and the slide purge:** (1)
**The ghost is the shadow's single source of truth**: the real avatar's meshes
carry `cast_shadow = OFF` permanently at load (not coupled to the tuck); the
ghost's meshes use `SHADOW_CASTING_SETTING_SHADOWS_ONLY` (renders no color for
any camera, casts always); the layer-2/cull-mask machinery is deleted — the
shadow pass culls by camera cull_mask, so layers would silence the ghost. Ruling:
the ghost trick is body-only; the shovel, stop sign, and all future props use
default shadows. (2) **FP camera collision casts from the BODY CENTER**, not the
eye — the eye sits 0.25m forward and can be past a wall face in tight tunnels,
where origin-inside-collider rays return no hit. The cast goes from body center
along the view direction for the total forward extent; the camera clamps so the
lens never crosses the hit. (3) **Down-pitch clamps at -85°** (export
`pitch_down_limit_deg`); the upward limit stays at 1.4 rad. (4) **The slides are
deleted entirely** (`fp_run_slide`, `fp_crouch_slide`, `fp_jump_bump`,
`fp_slide_speed`, `_update_fp_camera_slide`, `_fp_base_offset`) — the FP lens
lives at its hand-tuned scene position; crouch still drops the lens height (a
snap in `_set_crouch`). Feel notes: 30 startup frames synced, movement tech
emerging. Gates: smoke clean (0 script errors), audit ✓ (19 files, 92
functions), lint ✓ (37 files).

**Addendum 14 — 0.0.3 MEMORY pt1 + the asset wave.** (1) **The gate closed:**
feel checklist passed by hand; v0.0.2 tagged and pushed; both exports built and
zipped (v0.0.1 ritual); internal patch note written. (2) **MEMORY:** the diglog
schema now stores the float strike center ("c") — replaying from floored ints
mis-derived boundary cells; `aim.cells_in_sphere()` is the one static rule
consumed by sight, strike, and replayer; main boots replay-first (50k-sphere
benchmark: 7.85s, 2.4 MB jsonl — packed estimate ~0.8 MB, dev_log only), then
spawns at the nearest top-level solid column in the surface band (ruling: depth
0, never inside your own hole; the 50k synthetic shaft exposed the deep-column
bug, fixed by band-limiting the search); the stop sign persists in
user://hole/state.json (saved on reveal + exit) and materializes AFTER replay,
freezing only if its AABB intersects solid (ruling). probe_replay.gd: PASS —
40 spheres, 187/187 cells, voxel-identical. Legacy 0.0.2 diglogs wipe on boot
(dev reset). HUD save-size readout rejected. (3) **Music:** 9 tracks staged
with licenses; 4 CC0s implemented (omfgdude, HoliznaCC0 x2, Yoiyami — WAV
converted to OGG); the 3 CC BY tracks + the Satie stage unimplemented per the
no-unattributed-commits ruling; the Satie verified PDM 1.0 but is a 30 s
fragment — vibe-rejected. Playlist: 2 -> 6. (4) **UAL2 registered** as a second
library (43 clips under ual2/) for future actions; swing enum stays UAL1 names.
(5) **Female Ranger worn** on avatar AND ghost (9 skinned meshes reparented
onto the Quaternius standard rig, host shadow policy inherited) — the shadow
wears clothes. `outfit_enabled` export; full wardrobe is 0.0.7's. Gates:
import clean, smoke clean (0 script errors), audit ✓, lint ✓. pt2 pending:
compaction decision, 0.0.5 credit lines for the staged CC BY set.

**Addendum 15 — the opening credits: the dig sequence.** (1) **Worn Outfit
dials**: offset / rot_deg / scale as live setters over `_outfit_meshes` (avatar
+ ghost share them — the shadow stays dressed); bind-pose drift is now an
inspector dial. (2) **Spawn-edge fix**: the ring search required only the
candidate column, so a dug neighbor meant feet over the pit ("spawned into a
hole") — `_spawn_on_column` now demands a solid 3x3 surface neighborhood. (3)
**The sequence** (boot with a non-empty hole; empty hole and rescues stay
fast): spectator camera above the hole centroid -> "loading your hole." label
-> depth bands replay top-down (sort order is union-safe: per cell, whichever
sphere hits first erases; order changes who, never what), floor growing per
band just ahead of the front -> TP reveal at the surface spawn -> smoothstep
lerp to the FP eye -> FPV cut, controls live. Paced toward
`dig_sequence_seconds` (6s); any key/click skips with the end state completed
synchronously. Superseded `_replay_hole` deleted. Gates: smoke (0 errors,
sequence 0.30s for the 40-sphere dev hole), audit ✓, lint ✓.
