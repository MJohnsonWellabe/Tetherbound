# T3-RELAY session report — 2026-08-29

Track 3 (Content/Fun) lane, scoped to §7 (the Tether Relay, band 3/River &
Relay) of `docs/owner-direction/TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md`.
Branch `ralph/T3-RELAY`, pushed, no PR opened per instructions. Bound to
roughly 90 minutes; most of the wall clock went to fetching and importing a
Godot binary (none was present in this container) and to headless
verification runs, not authoring.

## What was already there

Before touching anything, I read `§7` in full and then inspected the actual
built state rather than trusting backlog prose. The Relay's mission
structure is already built and tested, from a sequence of prior sessions
(`SE23`/`SE25`/`SE27`, `OW5D`/`OW5E`/`OW6`, `GATE-D3`, `VIS-CAST`):

- **The escalation chain** is real and paced, not back-to-back: two grunts
  on the approach road (Hess, Orrin), an officer on the site itself (Dell),
  then Captain Vance at the console end — each a step deeper and a step
  stronger (`data/config/bands/band3_the_river_lock/trainers.json`).
- **A camp/recovery opportunity before commitment** exists on the flattest
  ground in the band, just past the spine's bend into the relay road and
  short of both pickets (`props.json`'s `relay_approach_checkpoint`
  cluster) — evidence of a staging point rather than a second rest
  mechanic, consistent with the game's one `camp.gd` system.
- **The captive/rescue** (Sela) is gated on `relay_captain_defeated`, hands
  over `mill_bridge_gear` on the same dialogue line that sets
  `captive_rescued`, and relocates to the village once freed
  (`data/config/relay_site.json`, `data/dialogue/relay.json`).
- **The console shutdown** is gated on the captain's own defeat flag,
  is one-way, and has an immediate, visible payoff: every lit pylon and
  conduit on the site swaps to its dead material the instant the console is
  used, and a world message ("The relay goes quiet. Every conduit on the
  site dies with it.") fires on the same call (`scripts/world/
  tether_relay.gd::disable_relay()`).
- **The crossing** reopens through `mill_crossing.gd`'s existing
  gated-crossing/item-gate mechanism once the Gear is delivered.
- **The chapter-wide land-heals-and-network-dies payoff** (dead ground
  fades, every Team Tether light in the region dies, barriers open, beaten
  patrols withdraw) is `meadow_healing.gd`, keyed on `legendary_freed` —
  correctly a Warden-victory event for the whole Meadows, not something
  this item should duplicate locally.

None of this needed rebuilding, and I did not touch any of it. Rewriting a
working system to manufacture a diff would have violated the standing
"evidence-backed already-fixed is valid" rule.

## What was actually missing

`ralph/reports/finding-post-tournament-cadence-2026-08-29.md` (a prior
measurement-only pass) flagged Band 3 as borderline: second-sparsest
authored-content density chapter-wide, with a 641m gap at the band2/3 seam
and a 679m interior gap. I re-derived the exact gap boundaries from that
report's own raw log (`ralph/reports/gate-f-corridor-probe-2026-08-29.txt`)
by filtering the cadence trace to non-wild ("authored": trainer/gather/TM/
key) points only:

- **641m gap, 4795m→5436m along the chapter**: the region's own entrance —
  from the last authored beat in Band 2 to the first one a player meets
  inside Band 3 (`harvest.json` order 3003, "the last gathering before the
  ground starts climbing into the relay approach"). The three harvest
  nodes already authored earlier in the band's own file (orders 3000-3002)
  turned out to sit more than the probe's 30m notice radius off the
  literal spine polyline, so they weren't closing this gap.
- **679m gap, 6057m→6736m along the chapter**: immediately AFTER Captain
  Vance's own fight, running through the Old Mill Crossing itself. This is
  the single worst place in the region for the world to go quiet — it is
  the stretch a player walks right after the mission's own victory
  moment.

## What I authored

Three harvest nodes, `data/config/bands/band3_the_river_lock/harvest.json`
orders 3012-3014, reusing the band's existing four-material vocabulary
(wood/fiber/stone/berries) and existing prop models — no new item, no new
mechanic:

- **3012** `(-60, 3240)`, fiber: splits the 641m entrance gap into two
  ~320m halves, seated directly on the spine's first leg.
- **3013** `(110, 3960)`, stone: on the relay's own spoil ground, the
  first half of the post-Vance gap.
- **3014** `(-60, 4110)`, berries: on the near-bank approach to the Old
  Mill Crossing — the second half of the same gap, on ground that was
  Team Tether's a few minutes earlier and is the player's own again now
  that the captain is down.

Positions were checked against `tools/_probe_gate_f_corridor.gd`'s own
30m/spine-segment geometry (a small scratch calculation, not committed)
before placing them, rather than guessed and re-run repeatedly.

## Why nothing else was authored

Every other §7 bullet — Team Tether visual presence, patrols, desirable
wild creatures, meaningful resources, an optional trainer/encounter,
visible environmental damage, captive/story clues, camp before commitment,
the paced Grunt→Officer→Captain chain, and the full victory payoff — was
already built and already reads correctly on inspection of the live
config/scripts. Adding more on top of a passing mission would have been
scope creep against this lane's own brief ("small content is valid
content", not "every point of interest needs more"), and I do not own
visuals, terrain, or the wild-density table (already at the owner's own
Valheim/Palworld-comparable target per `GATE-D3`).

Band 4's own 1064m band3/4-seam gap and 852m band4/5-seam gap remain the
two largest gaps chapter-wide and are explicitly out of scope — that
ownership sits elsewhere per this session's brief, and the finding report
already names band 4 as the higher-priority region.

## Verification

- **`tools/_probe_gate_f_corridor.gd`**, before/after: the entrance gap
  went from one 641m interval to two (323m, 318m); the post-Vance gap went
  from one 679m interval to three (239m, 214m, 226m). All six now sit
  inside the owner's 60-90s (~240-360m) cadence band. 0 of 888 wild bodies
  grounded (unrelated regression check the probe carries for free).
- **Unit suite**, scoped to the touched systems and their neighbours
  (`test_band_content`, `test_harvest_permanence`, `test_dialogue_runner`,
  `test_item_icons`): 97 tests, 221,667 assertions, 0 failed.
  `test_band_content.gd::test_merged_arrays_are_identical_to_the_pre_split_files`
  passed correctly — it only pins the first N entries against the baseline
  fixture and allows net-new entries appended after it, which is exactly
  what this change does.
- **`tests/smoke_relay.gd`**, full end-to-end: captain fought down (2314
  action frames, 3 of 3 creatures felled), `relay_captain_defeated` set,
  captive greeted correctly before and after, `captive_rescued` set,
  `mill_bridge_gear` granted, Sela's body removed from the site and
  re-placed in the village with her post-rescue greeting. `relay: OK`.

## Environment note

No Godot binary existed in this container. Fetched 4.7-stable (matching
`GODOT_VERSION` in `.github/workflows/ci.yml`) the same way CI does, then
`godot --headless --path . --import`. Per this repo's own documented trap,
`--headless --rendering-driver opengl3` hangs forever; every verification
run here used plain `--headless`. Also worth recording for the next
session: this environment's background-task "completed" notifications
fired several times while the underlying `godot` process was still
mid-boot (confirmed by `ps aux` and by output files that stopped mid-line)
— do not trust that signal alone for a Godot headless run; poll the
process or its output for the actual terminal line/metric instead.
