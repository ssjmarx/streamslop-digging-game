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

**Addendum 16 — the outfit coverage cull.** (1) **The system**: worn outfit
pieces now declare per-piece coverage (`OUTFIT_COVERAGE` in player_controller.gd:
piece node name -> region groups the piece REPLACES); the union of visible
pieces' regions becomes a covered bone set, and `body_cull.gd` drops body
triangles whose skin weights lie under it (strictness 1.0 = fully covered only,
so boundary triangles survive and no holes open at seams). The tri-state: cover
= non-empty list; overlay = empty list (hood, pauldrons, bracer, belts); not
worn = visibility, already existing. Culled meshes cache per mesh + bones +
strictness; the source ArrayMesh is never mutated; avatar and ghost land on the
same cached culled mesh — the shadow stays dressed identically. (2) **The
probe** (`probe_body_cull.gd`, reporting through the production classifier):
body = 1 surface, 7376 verts / 12812 tris, 4 influences/vertex, weight sums
exactly 1.0, zero blend shapes; per-piece weights settled the table — Arms
includes fingers (gloves), Feet is knee-high (calf 84%), Body rides clavicle +
neck_01 (collar), Hood weights Head 59% but stays an overlay (modeled with an
open face). Full Ranger set culls 9672/12812 triangles (75.5%). (3) **The
region contract** (design fact for 0.0.7/0.0.8, GDD §6b amended): groups derive
from bone-name prefixes — neck split from head (hoods must never eat faces),
calf from thigh (knee-high boots), pelvis lumps into torso; modded rigs
validated by the bone list get groups for free, and mods without coverage data
overlay harmlessly. Face furniture (Eyes/Eyebrows) and hair are exempt
(BODY_MESH_NODES). (4) **Order fix**: `_load_avatar` now caches `_skeleton`
before `_attach_outfit` — caught on read: the rebuild fires inside
`_attach_outfit` and reads the bone map. One real parse bug en route:
`add_surface_from_arrays` takes lods as a Dictionary, not an Array.
`outfit_coverage_strictness` ships as a live export dial (1.0 default). Gates:
probe exit 0, smoke 0 script errors, audit ✓, lint ✓ (50 files).

**Addendum 17 — unhooded default.** Ruling: the default outfit ships without
the hood — `OUTFIT_UNWORN_PIECES` skips the piece at wear time (8 meshes worn
instead of 9, both bodies). The hood's overlay coverage entry stays authored in
`OUTFIT_COVERAGE`, correct for when pieces return; 0.0.7's per-piece dials
supersede this const.

**Addendum 18 — auto mantle.** Ruling: running into a 1-voxel lip steps you
onto it instead of dead-stopping — quake step-slide via
`PhysicsServer3D.body_test_motion` (signature + params verified against pinned
4.7.2 by `probe_physics_api.gd`). The dials, as ruled: base step 0.58 m
(Quake's `pm_stepsize`, 18u x 0.0321 m/u), chain window 0.3 s after a step
raises the search to 1.05 m (just over a voxel — chain-stepping staircases;
net gain per step exactly one voxel), gate is horizontal speed STRICTLY greater
than the `walk_speed` constant (walk and crouch still block on purpose), ground
AND air triggers (vertical walls never qualify — taller than any step height —
so dig-jump keeps the walls; GDD §3 sentence amended to match), horizontal
speed retained structurally (input-driven velocity) — "the cost is for bunny
hopping later when that's implemented with the full quake mechanics" (ruling,
verbatim note). Body teleports, lens lerps (`mantle_cam_smoothing`, anti-pop —
distinct from the deleted camera slides). Two sweeps per attempt, only when
wall-hit at speed: raised sweep must be fully unblocked, down sweep must find
floor in range, zero-lift grazes rejected (a wall-parallel slide must not eat
fall speed). Feel-test box added to ROADMAP §4 base list. Gates: smoke clean
(0 script errors, boot line prints), audit ✓, lint ✓. Uncommitted pending
corey's by-hand pass: 1-voxel lip steps, 2-voxel wall stops, walk-speed blocks,
staircase chains, hole walls still need the shovel, no FP camera pop.

**Addendum 19 — mantle never fired; the post-slide velocity trap.** (1) The
traps, in order: (a) `_try_mantle` gated on `velocity` AFTER `move_and_slide()`
— Godot rewrites velocity to the slide result, so a head-on hit zeroes
horizontal speed before the gate reads it (0 m/s fails the walk gate). Lesson:
gate on PRE-slide intent. (b) Addendum 18's "ground AND air" reading with base
0.58 m could never fire anyway: blocky terrain surfaces sit at integer heights,
so every lip is exactly 1.0 m and a 0.58 m raised sweep is still blocked from
the ground; the chain window could not bootstrap without a first success.
(2) Ruling (supersedes 18's trigger law): the mantle check runs on EVERY
qualifying wall bump — enabled, wall contact, horizontal speed strictly above
`walk_speed` — with NO jump-state machinery. The jump-lead is emergent: a
grounded capsule searches from +0.58 and cannot clear a 1.0 m lip; a mid-jump
capsule already carries the elevation, so the same search clears it. Chain
window unchanged (0.3 s at 1.05 m after any success — grounded staircase
chaining). `mantle_debug` export prints accepted mantles while tuning. (3)
ROADMAP §4 box reworded (grounded stops / jump-led mantles / staircases chain /
2-voxel walls stop / shovel owns walls). Gates: smoke clean, audit ✓, lint ✓.

**Addendum 20 — the boot spawn flash; the body now exists only after the
replay.** corey saw the spawn position for a frame during the dig sequence:
three stacked races — (a) the avatar was built in `_ready` and stood at the
origin (in the hole, dead center of the spectator shot) until main's hide,
which fired only after the spawn-area meshed await; (b) the FP camera claimed
`current = true` from the tscn, so the boot rendered from inside her head
until the spectator made itself current, same awaited frames away; (c) the
reveal had no animation-settled guarantee (T-pose at the reveal on slow loads).
Ruling: the player body does not exist until after the hole is dug — `_ready`
no longer loads the avatar and no longer claims a camera; main calls
`spawn_avatar()` after spawn placement (builds HIDDEN, waits out the Idle fade,
then reveals — a T-pose cannot render); the spectator is created before the
first await so the boot camera is the spectator, frame one; the empty-hole and
rescue paths get the lens via an explicit `set_camera_mode(false)`. Boot order:
spectator frame one → "loading your hole." → replay → place → build hidden →
animate → reveal → descent → FPV, controls live. Rescue path unchanged
(existing body hides, teleports, re-reveals). ROADMAP §4 box added.

**Addendum 21 — movement shovels (future build; ruled into GDD §3, marked Q3).**
When shovel tiers exist, "movement shovels" are a special class of tier shovel
that dig fixed preprogrammed shapes instead of spheres — founding member: the
staircase shovel; more shapes may follow. Same verb, same 0.45s cadence; each
shape is a batch of idempotent strikes through DigAuthority, so netcode gets
them for free. Not part of the launch tier ladder (tiers change radius only —
the launch law stands); the class is future content.

**Addendum 22 — the rescue crash; the typed-array ternary trap.** Void-diving
off the rim crashed the loader: `_boot_spawn_sequence` assigned its diglog
entries through a ternary (`read_entries() if with_replay else []`) into an
`Array[Dictionary]` — a GDScript ternary strips the empty literal's typed
conversion, so on the rescue path the expression arrived as untyped `Array`,
failed the runtime assignment, and killed the coroutine right after the
teleport (physics stayed off: frozen player). Lesson: typed-array defaults are
assigned first, populated by branches after — never through a ternary. Fix:
`var entries: Array[Dictionary] = []` + `if with_replay: entries =
read_entries()`. No other instances of the pattern in the codebase (searched).

**Addendum 23 — the 0.0.3 gate: MEMORY passes.** corey ratified the two open
rulings and walked the checklist. Compaction: none, forever — the Addendum 14
benchmark stands as recorded (50k spheres, 7.85 s, 2.4 MB), the jsonl format is
law (GDD Appendix B), and the Kiosk's wipe makes the question moot. "Save size is
surfaced somewhere": dropped — the HUD readout was already rejected in pt1,
nothing surfaces the number, and the §5 exit test is amended at the boundary
accordingly. The §4 feel checklist passed in full, by hand, at 60 Hz — including
the two new boxes (mantle, boot). Tagged `v0.0.3` at 06db5f7, annotated in the
v0.0.1/v0.0.2 style. Export/zip/patch-note ritual pending on corey's machine.

**Addendum 24 — quake speed.** project.godot had no [physics] section: the game
had been running at Godot's 60 Hz default while the intent was 125. Set
`physics/common/physics_ticks_per_second=125` and retuned dig.gd's
`startup_frames` 9 → 19 — the windup was ruled at 60 Hz (9/60 = 150 ms), and
19/125 ≈ 152 ms preserves it. Everything time-based (0.45 s swing, mantle
windows, chain grace) is untouched by construction. Lesson: the tickrate intent
lived in nobody's config; the stopwatch's new sub-frame law (Addendum 25) is
what surfaced it.

**Addendum 25 — the stopwatch: deferred, and its law rewritten.** All purchases
are deferred past this patch, stopwatch included — the model stays in
~/Downloads, unstaged. Verification closed by corey reading the pages directly
(Pixabay blocks scrapers): febrianes86's stopwatch is Free for use under the
Pixabay Content License — no attribution required, modify/adapt fine, no
standalone resale — and the model is a 21,299-vertex GLB with no textures and no
animations, so it needs a hand-made material when it stages. New timing law,
ruled into GDD §6e and superseding "runs from your first swing": a run is
physics frame → physics frame — it starts the frame the player gains control and
ends the frame depth ≤ −100.0 m, with sub-frame display in physics frames at
125 Hz. Standard speedrun semantics.

**Addendum 26 — the kiosk interaction bundle.** Rulings for 0.0.4, made
together. (1) The LMB taxonomy, ratified framing for the One Rule: one button,
three target-dependent machines — voxel clicks are the digging machinery
(shipped), interaction clicks are the kiosk's (this patch), melee clicks are a
future machine; the verb set stays {dig}. (2) Interact is cursor-driven and
keyless: the crosshair's in-range state (inside DIG_RANGE) is the liveness
gate — no separate radius concept, E is dead, and the `interact` input action is
removed at pt2; a live interactable under the cursor eats the click — it
dispatches and the swing never starts, no whiff, no clang. (3) Shop view:
controls lock, the camera lerps to a static authored shot, and the cursor
becomes virtual — the mouse stays captured, deltas drive a clamped screen point,
and the diegetic billboard stays the only cursor in the world; hover highlights
inventory via the sight's edge-glow idiom; a SELL DIRT text billboard stands
over the shopkeeper's head in shop view; Esc exits. (4) The world lip: the dirt
disc is untouched; the 10 m apron (50→60 m) is a smooth generated ring mesh —
higher resolution than the voxels, undiggable by construction because it is not
voxel terrain. (5) All purchases deferred: price popups are display-only, [/]
stays the tier switcher, SELL DIRT is the only working button. (6) GameState
becomes the owner of user://hole/state.json at pt3 (dirt, money, tier, PB), the
stop sign's pose migrating under a reserved key with a compat read.

**Addendum 27 — double digs; the cadence anchors to the strike.** corey saw rare
double digs after the 125 Hz conversion. Mechanism: `_swing()` armed `_cooldown`
at click time and counted chain grace from the last click, but the strike landed
only after the windup — so with corey's tuned windup (~488 ms), follow-up clicks
in the window between windup-resolve and grace-expiry canceled into an instant
second strike ~12 ms after the first. The bug predates the conversion (a ~50 ms
window existed at 60 Hz); the new tickrate widened it. Fix: the cadence and the
grace both anchor to the strike — `_resolve_swing()` now re-arms `_cooldown` and
stamps `_last_strike_msec`; `_swing()` no longer arms anything. Strikes are
always ≥ 0.45 s apart (double digs structurally impossible), spam-clicking still
cancels the windup but can never skip cadence, and hold-to-chain still lands
strikes at the frozen 0.45 s. Also: Addendum 24's "~150 ms preserved"
reconstruction was wrong — corey had hand-tuned the windup in the scene to 30
frames at 60 Hz (~500 ms); the honest 125 Hz value is 61 frames (~488 ms), now
the code default (the scene override made 19 dead code). And the rescue path no
longer forces first person: `_boot_spawn_sequence` takes `preserve_camera`, so
being rescued in third person returns you in third person.

**Addendum 28 — the double-dig fix, take two: revert, then a dead-simple strike
gap.** The Addendum 27 strike-anchored cadence was wrong twice over. It silently
ate timed inputs inside a 0.45 s dead zone — a windup-paid strike lands ~0.49 s
after its click, so dig-jump rhythm clicks landed inside the zone and vanished —
and corey ruled the design point outright: a shovel jump does NOT get the
windup cancel; the cancel exists for the spam rhythm only, and paying the
windup is the skill. Machinery reverted to the simple click-anchored form
(cooldown at click, grace from the last click, windup cancel untouched). Double
digs are now prevented by one guard in `_resolve_swing()`: a resolution
arriving less than `min_strike_gap_frames` (56, ~0.45 s at 125 Hz) after the
last landed strike is held in the existing pending countdown until the gap is
paid. Strikes land ≥ ~0.45 s apart, no input is ever lost, windup-paid timed
clicks clear the gap naturally, and shovel jumping is untouched. Lesson: when a
guard breaks the thing it protects, the fix is not a smarter guard — it is the
dumbest guard that cannot break it.

## Entry #4 — 2026-10-18 — the garment-fitting rollback; the wardrobe pushed up (0.0.4 amended)

**The rollback.** Automated garment fitting was ruled a failure and left history: the
repo reset to `f094a5e` (0.0.4 pt0), the fitting commit (`b6baa49`) force-rewritten out
of both remotes (gitea and github), the uncommitted fitter WIP discarded —
unrecoverable, and mourned by nobody. Provenance restored from memory and reflog: the
runtime coverage cull (Addendum 16) worked on the female body + Ranger set but was a
disaster on the male body + Peasant clothes, and that disaster triggered the automation
attempt — an offline Blender-side fitter, an independent checker that kept catching the
fitter lying about itself (blind BVH normals, a phantom mannequin inside the "body"
union), the Fitment Ruling (clothes are overrides on the body; seam work is human),
and finally fitted artifacts worn as pure overlays. The numbers got good. The strategy
stayed wrong: the geometry decisions kept migrating from eyes that can see to scripts
that cannot. Rolled back to the last-known-good wearing system (the coverage cull;
`body_cull.gd` resurrected) — corey confirmed the dressed character renders perfectly,
which is the whole verdict in one sentence.

**The ruling: the wardrobe moves up.** Ladder amended at the pt0 boundary:
0.0.4 THE WARDROBE, 0.0.5 THE KIOSK, 0.0.6 CREDITS, 0.0.7 THE MACHINE; FOLDER, SEAM,
PHONE CALL, RELEASE unchanged (ROADMAP §3/§5 amended same day; the kiosk's exit tests
moved intact). The pedestal select and the sign mirror remain wardrobe scope for later
pts; the guest CONTRIBUTED HUD moved to THE SEAM, where it always belonged.

**The doctrine: the automation boundary.** The fitter failed because it automated
geometry; the boundary is now scope law, written into ROADMAP §5's wardrobe entry:
- Geometry is human, in Blender. Attaching pieces (plain Armature Deform — the
  shipped weights are correct; Automatic Weights would ruin them), the head/body
  split, seam and silhouette repair, cross-gender ports, the per-piece hide
  decisions, and the Pose-Mode eye test before every export.
- Offline tooling checks, never fixes. `tools/wardrobe_check.py` validates the
  exports — a gate, not an oracle. (The fitter's checker earned its keep; the
  fitter did not. Only the checker idea survives.)
- Runtime is state, never geometry. Visibility from an authored slot table, body
  swap, menu, persistence. No reparenting, no re-weighting, no triangle culling
  in the dev path. `body_cull.gd` stays in the tree, dormant and documented — it
  is the mod-coverage mechanism for THE FOLDER, where "mods without coverage
  data overlay harmlessly" still rules.

**The mechanism** (GDD §6b amended same day): one GLB per body, every piece inside,
all skinned to the single `Armature` (UAL binds by the name); pieces wear as
overlays; hiding is authored show/hides per slot (head/torso/arms/legs/feet/
accessory/hair); sources live in `blender/` at the repo root. First export target:
the female body + Ranger set, parity with today's dressed character.

**Addendum 29 — the naming grammar; blender/ goes local.** The first authoring
pass produced its own law, adopted same day: node-name arity IS the type marker.
Two-token names (`Ranger_Feet`, `Hair_Long`) are slot pieces — mutually exclusive
with their slot word (Body, Arms, Legs, Feet, Hair); three-or-more-token names
(`Ranger_Head_Hood`, `Ranger_Body_Belt_1`) are accessories — independent toggles
that stack with anything, and the game never arbitrates their overlap (clipping
accessories are the player's to switch off). Numbered suffixes are
accessory-only (`Ranger_Feet_2` would be an accessory, not a boot variant).
`wardrobe_check.py` now enforces the grammar at the gate, plus two fixes to the
checker itself: the rig's head bone is `Head`, capital H (the HEAD_BONE const
was right all along), and name uniqueness is same-parent only — the `Head`
bone and the `Head` mesh legally share a name across namespaces. Also:
`blender/` leaves git — the .blend sources and exports live on this PC only; a
private game-assets repo (sources + license files that cannot ship publicly)
is slated for the CREDITS milestone, and the authoring contract doc will move
there when it exists. The law itself lives in GDD §6b. First export
`wardrobe_female.glb`: 20 skinned pieces, 65 joints, one armature — gate green
after the checker fixes above.

## Entry #5 — 2026-10-18 — the wardrobe runs: the pipeline proven in-engine

**The asset.** `wardrobe_female.glb` graduated from blender/ (local-only) into
godot/assets/characters/wardrobe/ — 93 MB with embedded textures, which Godot's
importer extracts as 17 sibling PNGs (all cataloged; attr_lint went 50 → 68
green). Twenty skinned pieces, 65 joints, one armature, names conforming to
the naming grammar at the wardrobe_check gate.

**The runtime.** `player/wardrobe.gd`: the grammar IS the data — pieces are
discovered from the instantiated avatar, two-token names become exclusive
slots, three-plus become free accessories, fixed meshes always show; every
mutation is a visibility pass over avatar AND ghost (the shadow stays dressed,
Addendum 16's ruling, kept). `ui/wardrobe_menu.gd`: the O debug menu — slot
cyclers (bare is always an option), accessory checkboxes, a hair-color row.
While open the mouse is free, dig.gd stands down on `GameState.wardrobe_open`,
and walking stays live — dressing while pacing is the whole test.

**The tint port.** The old styling machinery's ATTACH half died (hairs ride
the GLB now); its TINT half was ruled state, not geometry, and survives: a
12-swatch palette (Sims-arc order, multiplier-friendly values, Brown default =
parity) applies to `Hair_*`, with `Eyebrows` — brows and lashes are one mesh —
riding at 0.75 of the hair color, the exact ratio the old constants encoded.
Materials duplicate off the GLB's own surfaces once, then recolor in place;
nothing external is loaded. Future ruling recorded: clothes go grayscale in
Blender and modulate in-engine like hair — out of scope until the loop is
proven.

**The save graduation.** corey ruled the wardrobe must persist, and on review
that meant graduating the save itself: user://hole/state.json existed only as
the stop sign's private pose file — GameState now owns it end to end
(state + wardrobe + sign keys), with dirt/best_depth arriving over DirtBus
(Addendum 26's shape, arriving early by ruling: "the game already saves; a
half-save is incoherent"). Compat reads degrade, never crash; the legacy
sign-only file reads as the sign on first boot. Verified live: a fresh headless
boot wrote the full graduated shape, default kit persisted.

**The excision.** player_controller lost the whole coverage-cull and
attach-outfit layer — OUTFIT_COVERAGE, BODY_MESH_NODES, the hair piece table,
the pose dials, the strictness dial — plus `_attach_outfit`,
`_attach_hair_piece`, `_style_builtins` and friends (~250 lines). The FP head
tuck got simpler: the Head-bone scale now tucks head, hairs, and hood in one
move. body_cull.gd and its probe stay DORMANT (the 0.0.8 mod-coverage
mechanism; the consts say so). The dev probes probe_body_cull /
probe_avatar_dump still reference the old scenes — manual tools, untouched,
revisit at THE FOLDER.

Gates: rescan ✓ (new uids), audit ✓ (25 files / 172 functions), attr_lint ✓
(68), headless smoke ✓ — boot, replay, spawn, shovel on `hand_r`, UAL1+2
bound, zero script errors (the --quit-after ObjectDB-leak warning is a
hard-exit artifact, not a runtime fault). Eyes-only parity pass is corey's,
in-engine.

**Addendum 30 — the covering rule, finally implemented; the dressing lens.**
The eyes-only pass found the fight the manual process was supposed to end:
nothing hid body skin — every sleeve fought its arm. Diagnosis: the covering
rule was in the tutorial and the pack Readme all along ("only the head is
required; the full body will result in clipping") and the pt3 runtime dropped
it. Ruling: the base body parts are single-word meshes — head, body, arms,
legs, feet — split at the outfit seams in Blender (once per body), and
occupying a garment slot hides that region's skin; head stays visible under
open-faced hoods until a closed helmet claims it. The slot words and the body
regions are the same words now — the mesh name IS the slot. body_cull's
triangle math is replaced by visibility on authored meshes: the
manual-process solution, as intended. Also: the O menu swings a dressing lens
— in front of the body, player framed screen-right, position-tracking,
yaw-ignoring, distance/height/offset as live dials.

**Addendum 34 — the weights pass: the manual element, automated.** corey's
diagnosis confirmed: the outfit packs are weighted for the Regular bodies,
and tight shrinkwrapped fits to the heroic body expose the divergence only
in motion — static fits, moving fights. Fix: transfer the heroic skin's own
vertex groups onto the tight-fitted garments (Data Transfer, nearest-face)
— the exact Case B of the original tutorial, automated under the
automate-the-choiceless clause: geometry stays exactly where the fit put
it; only the weights are re-derived from the coincident reference. Scoping
law: pieces that ride the skin get the transfer; intentionally offset
pieces (hood, pauldrons, belts) keep their pack weights, which are authored
for their floating positions. The macro is replace-semantics — safe to
re-run, unlike stacked normal passes. `blender/transfer_weights.py` +
README section; body-agnostic already, wave 2 expected to need the same
pass on the male side.

**Addendum 33 — automate the choiceless.** The doctrine gains its clarifying
clause. The normal pass (NormRef + Data Transfer, the split-mesh fix) was
mechanical from birth: rejoin the coincident boundary verts, smooth,
transfer, delete — zero decisions, same output every time, eye-verifiable in
one glance. That is compilation, not authoring, and it is now
`blender/fix_normals.py`: select the five regions, run, look. The boundary
holds: anything with a knob that changes what you see (fit, caps,
silhouette, thresholds) stays human; the checker-vs-fixer law is untouched
(this script runs in Blender at authoring time, beside the human, not in
any gate). The fitter remains the cautionary tale; this is the healthy
example.

**Addendum 31 — CI retired; the world freezes for the mirror.** The workflow
file left the repo: gitea never ran it, github ran it faithfully and
redundantly — the gates it mirrored (attr_lint et al) run locally at every
change, which is the only place they can be acted on. The credits gate lives;
the cloud mirror does not. GDD §2/§7/§13 and .clinerules amended. Also
shipped: the O menu now holds the world's inputs (movement, jump, P, wheel,
tier cycling — gravity and slides continue, the body stays put), and the
dressing lens is a real scene node under Mesh, in front of the body in
body-space, framed screen-right, eye-tunable in the Remote tab — the camera
comes to the body, the body never turns, and the behind-bug is structurally
impossible. And the seam-fix tier 1: garment pieces render double-sided
(cull_disabled on their duplicated materials) — openings show cloth interior
instead of the world; tier 2 caps await corey's list.

**Addendum 32 — caps go on the garment, sized by fit.** Tier 2 landed with a
correction from the first pass: the caps initially went on the bare body's
region seams, where every garment rim is wider than the skin — the caps
poked out exactly wrong. Ruling: caps are garment interiors, placed on a
seam only when that seam is LOOSER than the bare body beneath it — for
Peasant/Ranger that meant torso and legs; sleeves ride at the shoulder split
exactly and take none; Quaternius' boots ship pre-capped (why the feet seam
never showed in any combination). Recorded as the manual element of every
future import: split the regions the pieces replace, cap seams looser than
the body, and for pieces shorter than the region they replace, clone and
extend the base body into them — a few Quaternius pieces ship with the base
body included and are clean swaps out of the box. The contract lives in
blender/README.md (local; blender/ is untracked by ruling).

## Entry #6 — 2026-10-19 — v0.0.4 tagged; 0.0.5 pt1–pt3: the kiosk exists

The wardrobe milestone closed. corey walked the feel checklist, the tag went
down at 067a58e (`v0.0.4`, annotated v0.0.1/v0.0.2 style), and the export/zip/
patch-note ritual is pending on corey's machine as usual. Rulings at the gate:
the pedestal select and the sign mirror are deferred to an unassigned later pt;
the Long Shovel is dropped (never made, never shipped); movement shovels came
into scope with the staircase shovel as founding member (Q3 marker retired);
the HUD moves to a top-right readout stack. Boundary docs amended in the tag
commit (GDD §3/§6c/§11, ROADMAP §5, instructions §7, asset_plan benchmarks).

- **pt3.6 rode the tag**: the generalized lens — `enter_lens`/`exit_lens` run a
  transient camera that glides (0.35 s, supersede-safe) between any two views;
  O uses it, and corey liked it enough to rule P onto it the same day.
  `wardrobe_open` generalized to `GameState.view_lens` + `inputs_held()`; the
  dead `interact` (E) action removed from project.godot.
- **pt1 assets**: ten Quaternius packs staged from ~/Downloads (the two 2025
  [Standard] MegaKits are QAL v1.0, NOT CC0 — the legacy ten are CC0; recorded
  in `assets_unimplemented/quaternius/ATTRIBUTION.md`). Promoted with catalog
  claims: Kenney ui-audio (click1/rollover1/switch2), Kenney voiceover Male
  (ready, mission_completed — the shopkeeper's voice until better lines exist),
  `Stall_Empty` (the kiosk prop, 1,650 verts) and the stopwatch (21,299 verts —
  over the small-item budget, decimate to ≤ 500 pending corey's Blender pass).
  The size-benchmark table is law now: small item ≤ 500, large item ≤ 1,500,
  small prop ≤ 3,000, large prop ≤ 6,000, actor ≤ 15,000; the player wardrobe
  bundle is the sanctioned exemption.
- **pt2 the kiosk**: `scenes/world/kiosk.tscn` is a hand-editable scene,
  pre-placed in main.tscn on the apron at (0, 0, 54) — corey hand-adjusts from
  there. The apron is the world lip (Addendum 26.4): a generated ring mesh
  50→60 m, trimesh collision, undiggable because it is not terrain. Outside,
  the whole stall is one clickable and hover glows it; a click lerps to the
  pre-placed ShopCamera. Inside, the mouse stays captured and drives a virtual
  screen point; the sight casts through it, so the crosshair IS the cursor and
  items glow individually (duplicated-material emission, the tint-port idiom).
  The shopkeeper is a capsule placeholder until corey's frankenmodel lands
  (superhero-male head, male peasant body); his SELL DIRT billboard already
  hangs. Purchases went live the same day: tier buys are next-tier-only, the
  stopwatch is $600 with the whole tooltip, owned tags read OWNED, and the
  debug `[`/`]` cycler is dead (its actions removed from project.godot). The
  HUD is the top-right stack: DIRT, $, DEPTH, FPS.
- **pt3 the reset**: SELL DIRT reads the carried count, plays the pour, then
  tells the truth. The pour walks 16-aligned data-block slabs bottom-up, each
  re-emitted straight from the generator — the fill and the cull are the same
  write, so "pristine revert" is by construction, not parity math; the rate is
  an export with the never-tune-slower law on it. A click skips to the complete
  end state. The waiter lift raises any body inside the disc with the fill
  line (the shopkeeper never checks occupancy). At the settle: `depth_floor`
  resets to START_DEPTH and the whole stack re-emits (byte-identical to a fresh
  boot), the diglog is deleted (§6c: the theater is mandatory, the deletion is
  the truth), `dirt_sold` fires and GameState collapses dirt into money at 1:1,
  the stopwatch ownership persists in state.json, and the stop sign re-
  materializes via its new `stop_sign` group (re-frozen if the pour buried it).
  Relaunch after a sell loads instantly — empty diglog, no replay.
- **The slab-alignment lesson**: the pour's first draft walked block rows at
  `-depth_floor + n`, but data blocks are 16-aligned; `depth_floor` itself only
  aligns after the first grow (START_DEPTH is 20). Misaligned rows would have
  written slab data into the wrong blocks — caught in self-review, fixed by
  computing the aligned bottom (`-ceili(depth_floor/16)*16`) and stepping by
  16. `write_floor_blocks` never hit this because `ensure_depth` rounds every
  grown floor to 16 first.
- **One mesh, one glow manager**: the first kiosk draft had the stall as a
  sibling of its collider and a material_override fighting the hover-glow
  duplicates on the stopwatch. Fix: meshes live under the clickable that glows
  them (stall under StallBody, placeholder under SellZone), and the watch keeps
  its author materials — the hand-made material pass is corey's editor work.
- **Known artifact**: headless smoke prints 3× `Parameter "material" is null`
  from the dummy renderer since the kiosk landed; windowed run pending to
  confirm it is headless-only.
- **Pending for the milestone**: the shopkeeper GLB, the four Blender shovels,
  the staircase shovel + its solver (later pt), the stopwatch decimate, the
  snow shovel, the fear anim, the "You have no hole." empty state, and the
  local volume/depth tracking surface.

**Addendum 35 — the kiosk playtest round (2026-10-19, corey in-engine).**
Seven rulings from the first hands-on, one diagnosis worth enshrining:

- **The apron was invisible and unsolid — one wound ring.** Godot's front
  faces are clockwise-when-viewed-from-the-front; my ring's triangles crossed
  to +Y, so their fronts pointed down: backface culling hid the ring from
  above AND the trimesh (backface_collision defaults false) was non-solid from
  above — walking past the disc edge fell into the void and the rescue
  teleport read as "stuck." Fix is one index order; culling stays ON as the
  canary for this bug class. The ring also sinks 0.1 m (`apron_drop` export)
  under the voxel tops it z-fought.
- **The shop exit freed the mouse — double-handled Esc, not Wayland.** The
  kiosk's `_unhandled_input` closed the shop (`view_lens = ""`) and the same
  Esc event then propagated to the player's handler, which no longer saw held
  inputs and ran its own `ui_cancel` branch (`mouse_mode = VISIBLE`). Fix:
  `set_input_as_handled()` after closing; plus the O-menu now stands down over
  a foreign lens (shop/pour) instead of clobbering the flag.
- **Two-stage click (law, GDD §3 shape):** click → interact detection first
  (dispatches, eats the click, NO cooldown/clip — this also killed the
  windup-latency bug where shop clicks waited out the 61-frame startup) → no
  target? the swing starts → end of swing: the dig check. An interactable hit
  at strike time is a drifted cursor: a whiff, never an interaction.
- **Dig-jump renamed SHOVEL JUMP**, and it procs on ANY solid: dirt walls
  (load-bearing climbing — wall hits confirmed in), dirt floors, and now the
  non-diggable apron via the new `_strike_static` (clang, no dirt, jump if
  armed). `dig_jump_velocity` → `shovel_jump_velocity`; `notify_dig_jump` →
  `notify_shovel_jump`. GDD §3 amended.
- **Shop view hides the body** (`set_body_visible(false)` on open, back on
  close and at the pour's end — the waiter lift needs him visible). **Labels
  live on the hover**: every clickable's Label3D children start hidden and
  ride `set_hover` — price tags and SELL DIRT exist for the cursor, not the
  wall. **Spawn flipped 180°** — first tried as a yaw π on the Player scene
  node and it inverted the controls: movement keys off the RIG's local basis
  (`rig.transform.basis * input`), so rotating the body rotated the camera but
  not the walk direction. Final form: `spawn_yaw_deg` export (180) applied to
  `rig.rotation.y` at boot — spawn facing is a rig concern, never a body-node
  transform. **BGM plays tracks in full** — the 90 s cap export is gone;
  the fade anchors at `length - 10 s` (fade_seconds export unchanged).

**Addendum 36 — the apron bake, the shop layer swap, the teleport rescue
(2026-10-19, second playtest round).**

- **The apron is level geometry now.** The runtime-generated ring left a
  void slit between the bedrock's outer face and the apron (south side, on
  fresh setups — my mined-trench theory was wrong; the exact seam cause is
  still unproven, which is the point). `bake_apron.gd` (scripts/tools/) bakes
  the ring once into `apron_mesh.tres` + `apron_shape.tres` and main.tscn
  carries honest MeshInstance3D + StaticBody3D + CollisionShape3D nodes —
  editor-visible, hand-nudgeable. Inner radius is 48, tucked under the
  undiggable rim across the entire circumference; the 0.1 m drop is the node's
  transform, so the drop is an editor dial. Runtime `apron.gd` deleted.
- **Shop-mode collision swap.** In the world the StallBody eats the cursor
  and the products were unreachable through it; per ruling, the stall's
  collider drops to layer 0 in shop mode (rays sail past it) while the
  products and the SellZone come up — hover and clicks follow the rays
  automatically. `_set_shop_collision` toggles on open/close/end-of-pour.
- **The rescue is a teleport, nothing more.** The old `_rescue_player` re-ran
  the entire boot loader — body rebuild, awaits, camera reset — which is how a
  rescue could interleave with itself (the doubled rescues in the log) and
  present a holeless world from the no-replay path. New shape: velocity to
  zero, teleport to `_find_grounded_spawn` (ring-outward, each column's
  top-most solid at ANY depth with a solid 3x3 landing row — the floor
  guarantees a hit, so the mid-air origin failsafe loop is dead), one print.
  `_physics_process` stands down entirely while `_sequence_active`, plus a
  catch-all rescue below y = −2000. If a fresh-voxel world ever appears again,
  the rescue is provably incapable of it and the terrain streaming itself gets
  instrumented next.
- **Diglog hygiene:** a strike that erases zero cells (a pure bedrock hit —
  falling click-pogo) plays its clang and jumps, but no longer appends a
  no-op sphere. Bedrock-pogo no longer bloats the log.

**Addendum 37 — the apron's hole is the voxel rim's exact silhouette
(2026-10-19, third playtest round).** The radial-trace bake still showed
unpredictable gaps: the rim is a digital staircase, and its jogs outrun the
128 traced segments — chords between traced vertices cross *outside* the
voxel boundary wherever the rim is locally concave. corey's fix wins: the
apron's hole is now the rim's EXACT shape. `bake_apron.gd` extracts the
painted-cell union's boundary as a lattice loop (solid-on-left walk, ~404
points at integer coordinates), shrinks it 0.05 m under the voxels, offsets
it +5 m radially for the outer loop, and triangulates with the proven
winding. No analytic circle exists anywhere in the pipeline — the apron
cannot gap because its inner edge IS the rim. Tool self-checks: closed loop,
point count, and the printed radius band (48.75..51.40 — the digital
wobble, matching corey's 1 m/2 m seam measurements).

