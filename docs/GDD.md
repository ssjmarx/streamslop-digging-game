# streamslop digging game — Game Design Document

**Engine:** Godot 4.7.x (local install: 4.7.2 via Godots) · **Team:** corey ·
**Status:** This document is accurate. Parts of it are aspirational. Those parts are
marked Q3.
**Provenance:** consolidated 2026-10-15 from the founding design conversation (now
deleted — this doc and `docs/dev_log.md` are the record). Post-launch content lives in
Appendix A and is non-binding. The build plan lives in `docs/ROADMAP.md`.

## §1 High Concept

First/third-person hole-digging incremental. One verb: dig. One place: the hole. One
item: the shovel. Dirt is currency. Depth is score. The game remains in Early Access for
a very long time, during which the digging mechanic is never expanded. The world around
it accretes unrelated systems forever.

North-star metric: minutes dug per viewer-hour. A streamer digs for 40 minutes while
talking about something else. That is the target experience. The hole is the overlay;
the stream is the content.

## §2 The One Rule (spiritual)

`dig.gd` may be touched: refactors, engine upgrades, bug fixes, netcode seams. What may
never change is the player-facing experience:

- One verb. The verb set is `{dig}` and it stays that size.
- Swing rate 0.45s. Never tuned, never upgraded, never buffed by anything.
- Depth is infinite. Width is purchasable. Never the reverse.
- Nothing ever happens in the hole.
- The clang.

Enforcement: corey's conscience. The credits gate (`tools/attr_lint.py`) runs
locally at every change — there is no CI (removed 0.0.4 pt3.2, redundant). The
credits matter more than the mechanic; this was always true of the genre.

The corollary: every future system integrates with digging by *reading* DirtBus, never
by changing it. If a future feature needs digging to change: it doesn't.

## §3 The Verb

LMB → erase voxel sphere → +dirt → walk to kiosk → sell → buy a wider shovel → repeat.

- Dig rate (swings/sec) is never tuned, never upgraded, never patched. Tiers change
  sphere radius only. Depth is infinite. Width is purchasable.
- Sell price: 1 dirt = $1. This number will be regretted in a later update.
- Shovel-jump (renamed from dig-jump, ruling 2026-10-19): swinging while airborne
  and striking ANY solid grants upward velocity — dirt walls (load-bearing
  climbing), dirt floors, the non-diggable apron alike; the strike is the verb,
  diggable or not. The only player-driven air control in the game is a shovel;
  terrain may step a fast-moving player a single voxel (auto mantle) — never a
  wall. Flight is bounded by dirt —
  you can climb the hole's walls, never ascend its open air column.
- Movement shovels: a special class of shovel that dig fixed preprogrammed
  shapes instead of spheres — the staircase shovel is the founding member,
  authored in Blender with the rest of the shovel set (ruling 2026-10-19: the
  class is in scope; the Q3 marker is retired). Each swing digs a 2-voxel-wide,
  1-voxel-per-step staircase in the player's facing direction, gauged from
  where the feet are planted; up/down look is disregarded. Same verb, same
  0.45s cadence; each shape is a batch of idempotent strikes through
  DigAuthority (§13), so netcode gets them for free. Still not part of the
  launch tier ladder — tiers change radius only.

| Tier | Name               | Radius | Swing | Cost   | Notes                     |
|------|--------------------|--------|-------|--------|---------------------------|
| 0    | Plastic Toy Shovel | 1.3    | 0.45s | —      | beach-grade               |
| 1    | Garden Trowel      | 1.7    | 0.45s | 250    | insulting upgrade         |
| 2    | Pro Shovel 3000    | 2.3    | 0.45s | 2,000  | "Pro"                     |
| 3    | Ergonomic Shovel   | 2.3    | 0.45s | 25,000 | same stats. ergonomic. |

## §4 The Hole (invariants)

- One (1) hole. Hardcoded at world origin. The world grows around it, never over it.
- Infinite dirt downward, generator-streamed. There is no bedrock. The surrender is
  your hardware (§9).
- Width is purchasable. Depth is never gated, capped, or sold.
- Nothing ever happens in the hole: NPCs will not enter (invisible wall; sole dev
  comment ever: "NPCs are afraid of it"), enemies gather at the rim and stare, no
  events trigger, weather does not render below y=0 (it is permanently pleasant at
  −400m), and audio distance culling silences every overlapping soundtrack. The hole
  is the only quiet place in the game. People dig for the peace. The community-voted
  Steam tag becomes "Cozy."
- There is never a waypoint at the hole. Nearest: "Hole Overlook — 900m."
- The disc wears an undiggable black rim wall — one voxel at its edge, top to
  bottom. It clangs (the stop-sign clang) and takes shovel jumps, but never yields:
  the world keeps its skin.
- Off the rim there is no floor and nothing generates; fall ~20m and the void
  rescue picks you up. The floor grows only under the disc.
- The hole is excluded from the streaming system — fully resident in memory at any
  depth. It owns its own chunk column. Two streaming philosophies coexist and are
  never reconciled.
- Co-op players hold funerals in the hole. A sanctuary that is also the tutorial zone.

## §5 Movement

- Run is the default — full Q3 speed (10.3 m/s, g_speed 320u under our mapping).
  Walk is held (V, 1.288 m/s — stealth and roleplay). Crouch (hold, 0.966) / jump.
  Animation cadence follows velocity dynamically (2026-10-17).
- First/third-person camera toggle (P). The body stays visible in both modes: in
  first person the camera rides just forward of the face and the body stays
  view-aligned (human ruling 2026-10-15 — supersedes the v0.1 hide-the-body choice);
  in third person the body faces its movement direction on a hand-rolled SpringArm
  (replaced by an addon in a later patch, as is tradition). While running,
  crouching, or AIRBORNE in first person the CAMERA slides a little further
  forward than its hand-tuned base offset (the airborne bump is additive with
  the run slide), strictly so it never rides into the torso — the body
  itself never moves (ruling: slide the camera, not her).
- Dig-jump (§3). No other air control. No death: you cannot die and you cannot leave —
  there is nothing to leave to.
- Crouch is a non-goal to document (§14). Do not ask.

## §6 Launch features

The launch build is a hole, a wardrobe, a phone call — and a giant co-op Quake 3
level: the unrelated thing you can go do instead, which is what makes the digging
the joke. Initial Steam release: 0.3.0 (human ruling 2026-10-17), the first version
where the joke is legible. The $5 pitch verbatim: "a game where you can dig the
ground but also it's a giant co-op quake 3 level."

### §6a Co-op

- Online 2–4 players. One hole. The host's hole. Steam lobbies and invites via
  GodotSteam.
- The net seam is `DigAuthority.strike()`: dig.gd never knows whether it is online.
  Host-authoritative; guests predict; spheres are idempotent, so prediction never
  needs rollback.
- The anti-cheat is a server-side swing-rate check (0.45s minus jitter charity) — the
  only anti-cheat in the game that works, forever.
- Guest HUD: guests don't see DIRT, they see `CONTRIBUTED: N` (tallied from their own
  dirt_dug events). The employment joke is structural, not cosmetic.
- Guest labor feeds the host's diglog and leaderboards: the save format was already
  the network protocol; it just didn't know it yet.

### §6b Avatars (the wardrobe)

- The game opens on character select: six avatars, one Quaternius pack, one rig.
  Left/right arrows, rotating pedestal, name entry, RANDOMIZE, LOCK IN.
- Roster: Adventurer, Knight, Robot, Bandit, Zombie Businessman, and Shovelhead — the
  one original asset in the entire game ("corey", all rights reserved).
- Wardrobe pieces are authored in Blender as overlays on their body: every piece
  rides the shared skeleton with its original weights, and wearing is mesh
  visibility — the body ships as single-word region meshes (head, body, arms,
  legs, feet) plus face furniture, and occupying a garment slot hides that
  region's skin (a hood shows the face; a future closed helmet will hide Head).
  One piece per slot; accessories stack freely and are never arbitrated. No
  runtime geometry: no reparenting, no re-weighting, no triangle culling in
  the dev path. Mods without any wardrobe data overlay harmlessly — never
  naked by default. Seam, silhouette, and cross-gender work is human, in
  Blender.
- The naming grammar carries the exclusivity law: a two-token piece name
  (`Ranger_Feet`, `Peasant_Body`) is a slot piece — mutually exclusive with its
  slot word (`Body`, `Arms`, `Legs`, `Feet`, and the `Hair_<name>` prefix for
  hair); a three-or-more-token name (`Ranger_Head_Hood`, `Ranger_Body_Belt_1`)
  is an accessory — an independent toggle that stacks with anything. The game
  arbitrates slot conflicts by construction and never arbitrates accessory
  overlap: clipping accessories are the player's to switch off.
  `tools/wardrobe_check.py` enforces the grammar at the gate.
- Change your avatar later at the sign ("the mirror is at the sign" — sole dev
  comment on the matter).
- Local modding from day one: a folder in `user://avatars/` with `model.gltf`,
  `portrait.png`, `avatar.json`. That is the entire modding API. Rigs are validated
  against the required bone list; failures render the magenta placeholder (which is
  itself credited, §7). Data-only mods — never load PCKs. The community lives under
  the same rule as the dev.
- Character select is a credits gallery — browsing fires each avatar's lower third.
  The game's first room is its own attribution menu. In a lobby: four pedestals.
- Steam Workshop sharing ships at launch (0.3.0; ROADMAP).

### §6c The Kiosk (the shopkeeper)

- The shopkeeper is a garbage collector. Selling frees dirt: he puts it back where he
  found it. Selling **deletes** `diglog.jsonl` and reverts the terrain to the pristine
  generator — the hole un-happens. Personal best survives in `state.json` (§10).
- The pour is theater with a law inside: the layers fill bottom-up (deepest
  first) while voxel rows below the rising fill line are culled back to the
  pristine generator, and the pour rate outruns every shovel, forever — a safety
  invariant wearing an animation; never tune it, never polish it slower. The
  shopkeeper plays his spell-casting animation, hands glowing, while the hole
  fills; the view rides an overhead camera (the boot spectator's, lerped); a
  click skips the theater to the complete end state. The shopkeeper lifts any
  player standing in the fill column to the surface (he is also the only
  elevator).
- He never checks whether the hole is occupied (§6f). He walks to the rim and
  fills; his tool is never modeled, never shown up close, never for sale (the
  Long Shovel was dropped at the 0.0.4 gate, ruling 2026-10-19 —
  never made, never shipped).
- Shop inventory at launch: five items, one scam (Snow Shovel — purchasable,
  equippable, useless), one meta item (§6e). The Ergonomic Shovel has byte-identical
  stats to the Regular, forever.
- The shop is diegetic — no UI panel. From the world, the kiosk is one
  interactable: hover glows the whole shop, a click walks the camera to a
  pre-placed shop shot. Inside, individual items glow under the same sight
  machinery: the shovels, the stopwatch, and the shopkeeper himself as the SELL
  DIRT button, a billboard over his head proclaiming it. Esc exits. Future
  items join the shop as props, never as menus.
- He never descends. He does not check the hole. He is afraid of it too, but greed
  overcomes fear.

### §6d The Tide

Re-digging refilled dirt counts as fresh: dig → sell → refill → re-dig → sell. Dirt is
renewable; money is trivially infinite; this is not an exploit to patch — it is the
launch endgame. The true progression stat is maximum depth per cycle before the
surrender modal fires. The game is a tide with escalating amplitude, terminating in
thermals. The player is the moon. The shopkeeper is the tide. Nobody involved chose
this.

### §6e The Stopwatch

- Kiosk item, $600. Tooltip: "Stopwatch." That is the whole tooltip. No explanation,
  ever.
- Once purchased it runs from the physics frame the player gains control, forever. No
  stop button. It resets to 00:00.0 on exactly two events: purchase, and every sell.
  The reset makes no sound.
- A run: the physics frame control is gained → the physics frame depth ≤ −100.0m →
  time submitted. Sub-frame display is in physics frames (125 Hz — quake speed).
  Selling mid-run zeroes the watch; the reload hands control back and the next gain
  of control starts a new run. It doesn't punish; it forgets.
- The optimal route falls out immediately: grind → sell freely → upgrade → buy the
  watch → clean run. The community will formalize this in a week; we never confirm it.

### §6f The Machine (the backhoe)

- Parked ~9,000m out on flat procedural terrain (procedural the way a hallway is
  architecture). Walk out: 30 minutes. Drive back at exactly crouch speed (2.5 m/s —
  a coincidence we never explain): one full hour. Fuel exists; running dry means
  walking home, which is the content.
- Controls are My-Summer-Car: sit, then click and drag six individual levers —
  throttle, slew, boom, stick, bucket, stabilizers. No tutorial; the tutorial is the
  tip. Scoop without stabilizers and it tips; tipped is forever (the second frozen
  rule — no untip, ever; it becomes a lawn ornament). It drives at the old sacred
  crouch speed (2.5 m/s — the player's stealth crouch is now 0.966, ruling
  2026-10-17): one full hour.
- Each scoop is just a big `DigAuthority.strike()` — dirt to the counter, never
  inventory. It can dig the hole from the rim, within arm's reach, or dig its own
  ramp down and never leave. The backhoe is not an event; it is furniture.
- Burial: the shopkeeper never checks occupancy. Sell while the backhoe is in the
  hole and it is interred at its exact transform — a fossil you buried yourself. Dig
  it out by hand to revive it. Every sell re-buries it. Tipped *and* buried stays
  tipped after excavation. Co-op backhoe tourism is a thing people do. A backhoe in
  the hole is furniture that owes you money.

### §6g The HOLES screen (the phone call)

- Screen name: HOLES. Tabs DEPTH / VOLUME / TIME × DAILY / WEEKLY / MONTHLY —
  implemented as nine separate Steam leaderboard handles, because that is the honest
  way to do windows. Store bullet: "Three leaderboards. Nine leaderboards."
- Main view: the population distribution curve with your dot on it; two dots always
  (latest hollow, PB solid). "You are deeper than 61% of everyone. Approximately." —
  the curve is extrapolated from a sample; the tooltip admits it; this is a
  disclosure, not a bug, and is never fixed.
- Every entry wears a small "✓ unverified" badge. Score verification is planned, not
  shipped — forever. The swing-rate check polices cadence; the scores run on honor.
- Histogram bars are textured with the dirt texture re-imported for the leaderboard —
  catalog entry `tex_dirt_01_2`, credited separately. The void, rendered in dirt,
  credited twice.
- Diggers You Know: friends' avatars as portrait chips positioned on the curve.
  Strangers are dots; friends are guys. The leaderboard is the Workshop's storefront.
- Empty state (day one, daily): one bar. You. Text: "You are the distribution."
- Submission: host submits on session end and on sell (volume collapses at the moment
  of sale; the board deserves to watch). Depth and time keep-best; volume replace.
  Reset windows: 00:00 UTC, unexplained, forever.

## §7 Credits & Attribution

Completion percentage *is* asset attribution; 100% is achieved by literally seeing
everything in the game.

- Every asset a player can see is introduced by a TV-style lower third — name — author —
  license — on a queue, ~2.5s cadence.
- `godot/assets/catalog.json` is the law file: every asset file under `godot/assets/`
  must carry a claim in it. `tools/attr_lint.py` enforces exactly this and
  nothing else, locally at every change.
- The font is credited on boot, by the HUD rendered in it. The engine's
  ProceduralSkyMaterial is credited when the player looks up. The dirt texture credits
  itself on first dig. The magenta placeholder is credited as "unknown/unknown" — the
  uncredit-able one.
- Completion menu: seen/unseen, N/M. In v0.1 the menu is honest. It will not remain
  honest. (If an entry is unreachable, it is not a bug. Do not fix it.)
- First-boot popup: "You are seeing assets. This is normal."

## §8 Audio

One clang (dig), one whiff (miss), one footstep set, one wind loop.

- The clang is the only audio asset shared between digging and everything else,
  forever.
- The footstep set will be used for every surface in every future update. We are not
  making new footsteps.
- Below the rim: the music muffles by the dirt still overhead — a low pass paid in
  occlusion, not depth — and the clang rides clear. Dig the sky back and the music
  returns (ruling 2026-10-17, amending the old silence-and-the-clang).

## §9 Memory & The Surrender

- Memory usage is unbounded by design. Every dug sphere persists (§10).
- On low-memory conditions the game does not crash. It asks. Modal — title: "Your
  computer would like to stop." Body: "It has been digging for N hours. It is tired."
  Buttons: [Keep Digging] [Keep Digging]. Both work. Both are tracked separately. In
  three years the split will be 51/49 and nobody will know what to do with that
  information.
- Trigger (v2): <10 FPS sustained or <10% RAM remaining; non-blocking — the dirt does
  not stop for your feelings — and re-asks every 60s while conditions hold.
- Confirming increments the hidden stat `surrender_declined`, surfaced nowhere.

## §10 Save Format

- `user://hole/state.json` — money, dirt, tier, best depth, hidden stats. Stats
  survive the tide.
- `user://hole/diglog.jsonl` — append-only log of every sphere ever dug:
  `{"p":[x,y,z],"r":1.5}`. Load = replay the log through the voxel tool before spawn.
  The save file is the hole, expressed as its entire history. The loading screen says
  "loading your hole."
- Selling wipes the diglog and the hole reverts to pristine (§6c). The pour animation
  plays first — the theater is mandatory, the deletion is the truth.
- Deleting `diglog.jsonl` by hand resets the hole but keeps stats. We know what this
  enables. We allow it.

## §11 UI

- HUD, top-right readout stack (amended 2026-10-19: the bottom-center depth
  meter is retired): DIRT (or CONTRIBUTED for guests), $, DEPTH, FPS — ASSETS
  N/M joins the stack at CREDITS (0.0.6).
- The depth readout is monospace, one decimal, negative. It is the score. There
  is no other score.
- Personal best depth flashes on record. Local only until 0.0.10.
- Tutorial: two popups, total, forever: "You are seeing assets. This is normal." and
  "LMB — DIG." Future updates may add tutorials; none will conclude.

## §12 Store Page (launch bullets)

- DIG A HOLE — alone, or with up to 4 friends
- 6 avatars (more via local mods now, Steam Workshop at launch)
- One hole. Yours, or someone else's
- Infinite depth (bounded only by your computer's consent)
- Online co-op, Steam invites, leaderboards
- We are focusing on digging.

Last bullet: honest for exactly one build. Screenshot it.

## §13 Engineering

- Godot 4.7.x; `godot_voxel` (Zylann, GDExtension) pinned to the matching tagged
  release; GodotSteam pinned to the 4.7-matching build. API drift is the standing
  risk: verify generator property names, `do_sphere` semantics, raycast result
  fields, and every Steam call signature against the pinned versions — trust only
  their docs. Later updates add one addon per patch, as is tradition.
- Every tunable is an `@export` under a named export group — the inspector (and the
  editor's Remote tab, for live tweaks) is the tuning surface (ruling 2026-10-17).
  Law-locked numbers stay consts and are never exported: the 0.45s swing, DIG_RANGE,
  the tier table, MODEL_YAW, the rim (y=0).
- Project root: `godot/` (`res://` is godot/'s root). `dig.gd` lives at the project
  root, where everyone can see it. Repo-level docs and tooling live at the repo
  root. Two roots, on purpose.
- Autoloads: DirtBus, GameState, Attribution — in that order. DirtBus is the only
  bus. Signals may be appended. Signals are never removed. There will never be a
  second bus.
- `DigAuthority` is the single choke point every erase passes through (shovel, guest,
  backhoe scoop, future cannon). Every dirt-erasing path in the game — current and
  future — checks in for free. Patch 12's naval cannon that happens to hit the hole
  will excavate the backhoe. We will not have thought about it. It will be correct
  anyway.
- There is no CI (removed 0.0.4 pt3.2 — it ran the credits check on github,
  redundantly with the local gates). The credits gate (`attr_lint`) runs
  locally. There are no tests. There will never be tests. The feel checklist
  (ROADMAP §4) is the regression suite.
- Version stays 0.x until the developer gets bored. 1.0 criteria: boredom. Not
  measurable. Not our problem.

## §14 Non-Goals

Bedrock (there is no bottom) · a second hole · NPCs in the hole (they are afraid of
it) · documenting crouch · rebalancing dig rate, ever · a second bus · untipping the
backhoe · score verification · tests.

## §15 Roadmap

Milestones, exit tests, the build ritual, and the feel checklist live in
`docs/ROADMAP.md`. Amend it only at milestone boundaries.

## Appendix A — The Long Slop (post-launch bit; non-binding canon)

The digging mechanic never gets expanded, ever. Every patch ships a completely
disconnected, irrelevant gameplay focus, and each patch is genuinely decent at the
thing it ships — the slop isn't broken, it's off-target.

- P1 Quake movement + enemies (circle-strafe the hole) · P2 Daggerfall dungeons (a
  door in the hole wall; all loot is shovels, all worse than store-bought; a ladder —
  the only digging-adjacent feature ever shipped) · P3 motorcycle simulation (the
  service log notes the fuel tank has a hole in it; from a shovel) · P4 factory
  (conveyors can't be built below y=0; hand-carry ore; "Shovel Mk2 — same stats,
  red") · P5 blackjack (table at the bottom; the pit boss is the robot you built in
  P4) · P6 fishing & farming ("hole dirt does not grow things") · P7 co-op (one
  shared hole; shoveling dirt back in on teammates is the only new dig verb ever
  added post-launch)
- P8 dating sim (one NPC says "nice hole"; she is canonized) · P9 stock market +
  ShovelCoin · P10 naval combat (the hole floods permanently; fishing quietly becomes
  mandatory) · P11 city builder (tourists quote real Steam reviews) · P12 rhythm
  minigame "Shovel Hero" · P13 Hole Royale (100 players, one hole, zone shrinks into
  the hole) · P14 VR (three people finish setup) · P15 "Digging 2.0 Preview" (a
  second hole — rolled back after 11 hours due to community feedback) · P16 lore (the
  hole predates civilization; the final log says "we dug too deep"; nothing follows
  it)
- Stealth mechanics ship and are never mentioned in the patch notes.
- Stratigraphy: the column is the patch history — −30m dungeons, −60m casino, −200m
  factory and a single conveyor belt running, delivering nothing, −400m flooded naval
  wreck, −800m the Backrooms, then pure dirt forever with occasional lone assets: a
  chair, a Kenney tree at −1,204m, a Quaternius spider, dead, posed. Every patch the
  dev secretly buries one new asset deeper than anyone has ever dug. At a depth no
  consumer hardware reaches: a small sign. "thanks for digging."
- Meta: the store title mutates into SEO soup; the roadmap JPEG says "Digging — Q3"
  forever (eventually removed from the image, kept in the alt text); patch notes fix
  a typo and list known issues: digging; 300 achievements, none for digging; saves
  break every patch (the migration wizard converts your dirt into unredeemable Dirt
  Bonds); every patch adds another simultaneous music system.
- 1.0.0 releases when the developer gets bored. There is no ending — a credits
  screen with the Steam usernames of every Early Access buyer.

## Appendix B — Reference shapes for the frozen verb and the only bus

Preserved from the founding conversation (now deleted) because these two files are the
most-reviewed code in the project and their shape is design law. The 0.0.2/0.0.9
implementations land on these shapes; exact GDScript API details are verified against
the pinned godot_voxel/GodotSteam versions at build time (§13).

### dig.gd — v0.2 shape (the netcode seam, ~40 lines)

The FEEL is frozen (§2). The file may be touched. The verb may not grow.

- `DIG_RANGE := 5.0`, `SWING_COOLDOWN := 0.45` (constant; forever; §3 — range 10→5 by
  ruling 2026-10-17).
- Exports: `terrain: VoxelTerrain`, `viewmodel: AnimationPlayer` (cosmetic only),
  `clang: AudioStreamPlayer3D`.
- Swing: raycast from the camera; miss → play "whiff"; hit → play "dig", `clang.play()`,
  then `DigAuthority.strike(hit_voxel, GameState.dig_radius)`. dig.gd doesn't know if
  it's online. It never will.
- Erase: `VoxelTool.do_sphere(center, radius)` on CHANNEL_TYPE, erase-to-air. The
  removed-count is "approximately honest; load-bearing slop" — count/erase sphere math
  differ slightly and that is fine.
- Width only: radius comes from the tier (`GameState.dig_radius`). Depth comes free.

### DigAuthority — the single choke point (0.0.9)

- `strike(center, radius)`: offline or server → `_authoritative`; guest → predict
  (`_apply`), then request the host decide. Spheres are idempotent, so prediction never
  needs rollback. This is the only reason sloppy netcode works: the frozen mechanic is
  accidentally the most replication-friendly verb in games.
- Server-side anti-cheat: reject a peer's swing inside 0.45s minus jitter charity
  (~400ms). The game's entire anti-cheat, below.
- `_broadcast` is `call_local` and idempotent — duplicate applies are no-ops.
- Every erase path (shovel, guest, backhoe scoop, future cannon) goes through
  `_apply()` — which is also where the backhoe reveal check lives (§6f).

### DirtBus — signal list (v0.2; every signal carries `by_peer`, 1 = you)

    signal dirt_dug(amount: int, voxel_pos: Vector3i, depth: float, by_peer: int)
    signal dirt_sold(amount: int, price: int, by_peer: int)
    signal depth_changed(depth: float, by_peer: int)   # negative, like a scoreboard
    signal player_noise(level: float, by_peer: int)    # no subscribers in v0.1. intentional.
    signal asset_seen(id: String)
    signal surrendered(strength: int)                  # your computer. GDD §9.

Signals may be appended. Signals are never removed. There will never be a second bus.

### hole_persistence — the save format in one line

Every `dirt_dug` appends `{"p":[x,y,z],"r":radius}` to `user://hole/diglog.jsonl`; load
replays the file through the voxel tool before the player spawns ("loading your
hole."). The diglog is already the network protocol: host-side listeners log guest
labor for free. Selling deletes the file (§6c) — the format is never mutated, only
lived and, at the end, deleted.




