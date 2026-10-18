# docs/ROADMAP.md — Internal Development Roadmap

**Project:** streamslop digging game · **Author:** corey · **Reviewer:** corey (deferred)
**Status:** living document. Amend only at milestone boundaries.
**Dates:** none. Estimates are in weekends. If anyone asks when something ships: Q3.

## §1 How this document works

- Milestones are gates, not dates. Each retires a specific risk, phrased as a question.
  We do not start the next milestone until the current one passes its exit test.
- Every milestone ends in a tagged, exported, playable build — someone who is not corey
  must be able to unzip it and run the exit test in under 15 minutes. The game is
  shippable-to-a-friend at every tag. (The one piece of real discipline in the project.
  It exists so that when motivation dips, "the last playable" is never far behind us.)
- Build ritual (end of every milestone): `git tag v0.0.X` → export Windows build → zip →
  shared folder → run the feel checklist (§4) → write the internal patch note, even
  though nobody reads it. The patch-note habit is practiced deliberately. There will be
  a lot of them later.
- Devlog: every milestone gets an honest entry in `docs/dev_log.md`. Written
  truthfully, in plain language, forever. Reason: future design material. Reason given:
  documentation.

## §2 Versioning policy

- 0.0.x — internal testable milestones. Never leave the shared folder.
- 0.3.0 — initial Steam release ($5). The build the store page points at, and the
  first version where the joke is legible: a digging game with something entirely
  unrelated you can go do instead — "a game where you can dig the ground but also
  it's a giant co-op quake 3 level" (human ruling 2026-10-17).
- 0.1.0–0.2.x — the slope between the phone call and the joke; not yet carved. The
  ladder between them is drafted at the 0.1.0 gate, by the human, out loud.
- Version bumps only at gates. No mid-milestone version numbers. The version number is
  a promise about testability, not a timestamp.

## §3 The ladder

| Version | Codename       | The question it retires                                    |
|---------|----------------|------------------------------------------------------------|
| 0.0.1   | DIRT           | Can we stand on dirt?                                      |
| 0.0.2   | THE VERB       | Is digging fun for ten minutes? (incl. dig-jump)           |
| 0.0.3   | MEMORY         | Does the hole survive a restart? (+ compaction benchmark)  |
| 0.0.4   | THE WARDROBE   | Can you pick a guy? (bodies + pieces, Blender-authored)    |
| 0.0.5   | THE KIOSK      | Is there a loop? (shopkeeper, refill, prestige, stopwatch) |
| 0.0.6   | CREDITS        | Is every asset accounted for?                              |
| 0.0.7   | THE MACHINE    | Can a machine dig?                                         |
| 0.0.8   | THE FOLDER     | Can a stranger's guy appear without code?                  |
| 0.0.9   | THE SEAM       | Can two people dig one hole? (backhoe replication too)     |
| 0.0.10  | THE PHONE CALL | Can a stranger join without talking to us?                 |
| 0.3.0   | THE RELEASE    | Is the joke legible? (dig + a giant co-op quake 3 level)   |

(Amended at the 0.0.4 pt0 boundary, ruling 2026-10-18: THE WARDROBE moved up to
0.0.4; THE KIOSK stepped to 0.0.5, CREDITS to 0.0.6, THE MACHINE to 0.0.7. The
kiosk's exit tests moved intact — dev_log Entry #4.)

0.1.0–0.2.9 are not carved into milestones yet; the ladder between the phone call and
the release is drafted at the 0.1.0 gate (ruling 2026-10-17: the launch moved here
from 0.1.0).

Dependency chain (nothing starts before its parents pass; redrawn at the amendment —
the wardrobe leads, the machine branch follows the kiosk, the folder hangs off the
wardrobe):

    DIRT ──► THE VERB ──► MEMORY ──► THE WARDROBE ──► THE KIOSK ─────────────────────► THE RELEASE
                                       │                │                              ▲
                                       │                └──► CREDITS ──► THE MACHINE ──► THE SEAM ──► THE PHONE CALL
                                       │                                                     ▲
                                       └──► THE FOLDER ─────────────────────────────────────┘

## §4 The feel checklist (run at every gate, 2 minutes, by hand)

There are no automated gameplay tests. There is this, forever:

- ☐ One verb. Press every button; none of them dig differently.
- ☐ Swing interval 0.45s ±0.05s, stopwatch, 20 swings. (The single most important
  number in the project.)
- ☐ Upgrades widen. Nothing anywhere makes digging faster.
- ☐ The clang is present, unchanged, audible.
- ☐ Nothing happens in the hole. Stand in it for one full minute. Confirm: nothing.
- ☐ Depth meter reads negative and large.
- ☐ Into a 1-voxel lip: a grounded run stops dead, a jump-led run mantles onto
  it and keeps its speed; after a mantle, staircases chain; a 2-voxel wall
  stops everyone; the shovel is still the only way up a wall.
- ☐ Boot shows no spawn flash and no T-pose: the body first exists already
  animating, after the replay.

Additions (0.0.4+):

- ☐ The stopwatch zeroes on sell. No sound.
- ☐ Volume is live, depth is memory, time is a run.
- ☐ The pour outruns every shovel; selling deletes the diglog — verify the file is
  gone and that the theater played first.
- ☐ The backhoe reveals as a fossil, freezes embedded, revives when freed; tipped is
  still forever. Nothing happens in the hole — including when the hole contains a
  backhoe (unrendered data is nothing).
- ☐ Nine handles exist; daily resets at 00:00 UTC; nobody explains this.
- ☐ The curve admits it's approximate.

A failed checkbox blocks the tag. No exceptions, including for corey.

## §5 The milestones

### v0.0.1 — DIRT
**Question:** Can we stand on dirt?
**Scope:** flat voxel plain, sun + procedural sky, the avatar (one stock guy),
CharacterBody3D movement — walk, sprint, crouch, jump, first/third toggle. No digging
yet: THE VERB is next. This milestone also settles the addon pins: godot_voxel and
GodotSteam builds matching Godot 4.7.x, verified in a blank project before anything
else (ROADMAP §6, risk #1).
**Exit tests:** ☐ spawn on a flat voxel plain, run the Ladder in under 15 min from a
cold unzip ☐ walk / sprint / crouch / jump all work ☐ camera toggle P works (the
toggle moved V→P by ruling 2026-10-15; this text was amended at the 0.0.2 boundary) ☐ the
plain streams with no visible hitch ☐ the feel checklist's "depth" box passes vacuously
(meter exists, reads 0.0).

### v0.0.2 — THE VERB
**Question:** Is digging fun for ten minutes?
**Scope:** `dig.gd` ships (GDD Appendix B shape): 0.45s swing, sphere erase, +dirt,
the clang, the whiff, depth reporting over DirtBus. The diglog begins. Dig-jump ships
here. The sign (THE HOLE) may stand.
**Exit tests:** ☐ digging is fun for ten straight minutes — the only subjective gate;
corey decides ☐ swing interval holds 0.45s ±0.05s under load ☐ tiers widen only (tier
table live, price check) ☐ jump-spam out of a 5m hole unaided ☐ flight bounded by dirt
(can't ascend the hole's open air column — only along walls) ☐ ground-digging beneath
your feet does not pogo you (airborne-sample gate works) ☐ the clang.

### v0.0.3 — MEMORY
**Question:** Does the hole survive a restart?
**Scope:** `diglog.jsonl` append + replay-on-load ("loading your hole."), plus the
compaction benchmark that the Kiosk's wipe will later make moot — run it anyway; the
number is a nice thing to know and the habit of measuring is the point.
**Exit tests:** ☐ dig N spheres, restart, the hole is voxel-identical ☐ replay time
under 10s for a weekend's worth of dirt ☐ ~~save size is surfaced somewhere
(braggable)~~ — dropped at the 0.0.3 gate (ruling 2026-10-17: the HUD readout was
already rejected in pt1; nothing surfaces the number — dev_log Addendum 23).

### v0.0.4 — THE WARDROBE
**Question:** Can you pick a guy?
**Scope:** the wardrobe, pushed up (amendment 2026-10-18): bodies and pieces
authored in Blender — one GLB per body, every piece skinned to the one armature,
worn as overlays, hidden by an authored slot table; the debug wardrobe menu
(body swap, per-slot cycling, RANDOMIZE), persistence, ghost parity. The
automation boundary is scope law: geometry is human in Blender, tools only check
(`tools/wardrobe_check.py`), runtime is state only (dev_log Entry #4).
Select-screen presentation (pedestal, LOCK IN, the mirror at the sign) closes
the milestone at a later pt.
**Exit tests:** ☐ the debug menu swaps male/female live ☐ every slot cycles
independently; mixed kits bend together in FPV and TPV ☐ the choice persists
across restart ☐ the ghost stays dressed identically ☐ dig-jump and swing are
clean in mixed kit ☐ the Ranger set on the female body reads identical to the
pre-patch character ☐ attr_lint green on the new GLBs ☐ the placeholder renders
for missing models, credited.

### v0.0.5 — THE KIOSK
**Question:** Is there a loop?
**Scope:** the shopkeeper NPC (the launch NPC), sell-all, the pour animation
(deepest-first, the waiter lift), diglog wipe + pristine revert, Long Shovel on the
wall, snow shovel, ergonomic plateau, the stopwatch with its silent reset. Volume and
depth tracked locally — submission is 0.0.10's problem.
**Exit tests:** ☐ sell → `diglog.jsonl` gone from `user://` ☐ terrain spot-checks
byte-match a fresh generator ☐ PB depth survives in `state.json` — verify the
sanctuary is real ☐ pour lifts a standing player from −20m to the rim (the waiter) ☐
pour rate outruns ergonomic-shovel dig rate — verify once, never tune ☐ stopwatch zeroes
on sell, silently ☐ volume empty state reads "You have no hole." ☐ relaunch after
sell loads instantly ☐ sell → hole restores voxel-exact at 5 spot-checks ☐ snow shovel
purchasable, equippable, useless — uselessness verified, because a scam you don't
verify is just a bug ☐ ergonomic stats byte-identical to Regular (regression forever)
☐ shopkeeper's fear anim plays at the rim; he never descends.

### v0.0.6 — CREDITS
**Question:** Is every asset accounted for?
**Scope:** the attribution law live end to end — lower thirds, the completion menu,
catalog filled out to launch scope (~40 entries), first-boot popup.
**Exit tests:** ☐ every shipped asset file is claimed in catalog.json (attr_lint
green) ☐ lower thirds fire on first sight for font, sky, dirt, shovel, sign ☐
completion menu N/M matches reality ☐ the placeholder is credited.

### v0.0.7 — THE MACHINE
**Question:** Can a machine dig?
**Scope:** 9km flat terrain + the backhoe: VehicleBody3D (Jolt), six levers,
stabilizers, tip-freeze with persistence, fuel, scoops → `DigAuthority.strike()`, the
burial interaction. Secretly where the chunk loader is born — a 9km each-way
pilgrimage is the streaming stress test; every sophisticated streaming system the game
will ever grow begins as "make the walk not hitch."
**Exit tests:** ☐ walk 9km, flat framegraph, no stutter ☐ the drive home takes ≥ 60
real minutes at crouch speed ☐ stabilized scooping works and counts dirt ☐ scoop
without stabilizers → tips → stays tipped across save/reload at the exact transform ☐
backhoe digs the hole from the rim within arm's reach ☐ fuel empty mid-drive → engine
dies, walking home is possible ☐ the fence at 4.5km is credited ☐ backhoe below
surface at sell → interred at exact transform, persisted across reload ☐ re-dig to
stored AABB → spawns frozen mid-wall (a fossil you buried yourself) ☐ clear its AABB →
unfreezes, settles, drivable, fuel intact ☐ tipped+buried → excavation yields a lawn
ornament, still tipped, forever ☐ sell mid-excavation → re-burial; the fossil loop is
repeatable ☐ rider at entomb → ejected and lifted, never deleted.

### v0.0.8 — THE FOLDER
**Question:** Can a stranger's guy appear without code?
**Scope:** `user://avatars/` local modding — `model.gltf` + `portrait.png` +
`avatar.json`; bone-list rig validation; magenta placeholder fallback. The entire
modding API, shipped before the game has content.
**Exit tests:** ☐ a stranger's folder appears in-game with no code changes ☐ a bad
rig → placeholder, never a crash ☐ portraits show in select (and later on the curve)
☐ data-only mods enforced — no PCK loading, ever.

### v0.0.9 — THE SEAM
**Question:** Can two people dig one hole?
**Scope:** `DigAuthority` netcode — host authority, guest prediction, `by_peer` on
every signal; player replication (sync position/anim/avatar_id/hash/name, never the
mesh); backhoe replication; the guest CONTRIBUTED HUD (moved here from the old
wardrobe milestone at the 0.0.4 amendment); the competitive shopkeeper.
**Exit tests:** ☐ two people dig one hole, voxel-identical on both ends ☐ guest
swings inside the 0.45s window are rejected host-side ☐ host sells with a guest at
depth → guest lifted to the rim, watches the pour to the end, CONTRIBUTED survives
locally (unspendable, forever) ☐ pour spheres broadcast to guests via the idempotent
path ☐ backhoe despawn/reveal is host-authoritative and replicates.

### v0.0.10 — THE PHONE CALL
**Question:** Can a stranger join without talking to us?
**Scope:** Steam lobbies + invites; the HOLES screen — nine leaderboard handles,
submission on session end and on sell, the two-dot curve, the unverified badge,
Diggers You Know, the empty state. Sandbox the leaderboard API alongside the lobby
API first — score upload types (int64, keep-best vs replace) pin to the 4.7-matching
GodotSteam build before net_session touches them.
**Exit tests:** ☐ a stranger joins a public lobby without talking to us ☐ nine
handles exist on a real app build ☐ daily resets at 00:00 UTC, unexplained ☐ the
curve admits it's approximate ☐ guests feed the host's boards.

### v0.3.0 — THE RELEASE (the launch moved here from 0.1.0, ruling 2026-10-17)
**Question:** Is the joke legible — a digging game with something entirely unrelated
you can go do instead?
**Scope:** everything this section carried as v0.1.0 THE LAUNCH: store page live
("We are focusing on digging." — screenshot it; honest for exactly one build),
Workshop sharing ships at launch, curve polish, the empty state, store bullet "Three
leaderboards. Nine leaderboards." — plus the unrelated thing that makes the joke
legible: the giant co-op quake 3 level (the initial $5 ask). Milestones 0.1.0–0.2.9
are not carved yet; the ladder from the phone call to the release is drafted at the
0.1.0 gate.
**Exit test:** ☐ the feel checklist, in full, passes on the store build. The game is
complete. This statement becomes false at Update 1 and is never true again.

## §6 Risk register

- **godot_voxel 4.7-compatible GDExtension availability is unverified** — the first
  risk of DIRT. If no matching build exists, the pinned engine moves; the rule
  doesn't.
- GodotSteam API drift (lobby, UGC, leaderboards) — sandbox first, pin the version,
  trust only its docs.
- The curve-from-sample is a disclosure, not a bug — never "fix" it.
- Burial AABB checks are O(1) per erase via the near-last-erase gate.
- Volume-replace submissions double-upload on sell + session-end (idempotent;
  harmless; ship it).
- Diglog deletion on the Windows build is untested — "rm semantics on the untested
  platform: probably fine."
- The pour rate is a safety invariant wearing an animation — documented in GDD §6c so
  nobody "polishes" it slower.



