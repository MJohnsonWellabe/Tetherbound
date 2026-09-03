# T5-CARE — building, survival and care, played

**Branch:** `ralph/T5-CARE` off `origin/ralph/LAND-0830I`
**Scope:** `ralph/MEADOWS_EXIT_CRITERION.md` section H (H1–H6) and section I.
**Date:** 2026-08-30

## Why this lane existed

Section H was entirely unevidenced. Lanes covered visuals, terrain, story,
content, combat, performance, reliability and audio; nobody verified building,
survival or creature care by playing them. It is also the part of the game the
player touches most often between fights.

## Method

Godot 4.7-stable — the version `ci.yml` pins — installed into the session, the
project imported clean (exit 0). Every run boots the real
`scenes/world/meadows_playground.tscn` and drives it with parsed physical
`InputEventJoypadButton` / `InputEventJoypadMotion` events through the live
InputMap. Where a number is quoted it was measured in that running world.
Renders are real frames of the real armed placer over the real grass field,
with `tools/capture_check.gd` run at every shutter.

Harnesses added, all committed and runnable:

| tool | plays |
|---|---|
| `tools/_play_t5_care.gd` | satiety, eating from both screens, team feeding, bed rest, the sixth catch |
| `tools/_play_t5_freeplay.gd` | gathering, the hammer+interact Build press, place/dismantle, deaths |
| `tools/_play_t5_deaths.gd` | two deaths and an aimed dismantle, instrumented |
| `tools/_probe_t5_launch.gd`, `_probe_t5_spawn.gd` | the launch defect, isolated and traced frame by frame |
| `tools/_probe_t5_ground.gd`, `_probe_t5_holes.gd`, `_probe_t5_holes2.gd` | terrain height vs. real collision |
| `tools/_play_t5_respawn.gd` | where death and the fall-rescue actually put you |
| `tools/_play_t5_strand.gd` | walling the player in and trying to get out |
| `tools/capture_t5_build_ghost.gd` | `shots/t5-care/*.png` — the ghost against grass |

---

## The one fix that had to ship: the player is thrown 7,000,000 m out of the world

Booting the real Meadows with `opening:beat:free_play` set — the ordinary
post-opening state — reproducibly threw the player out of the world. Traced
frame by frame:

```
frame  14  pos (      0.0,    2.90,      0.0)  vel (0, 0, 0)               on_floor=false
frame  17  pos ( -23721.0, 3079.46,   7468.8)  vel (-1444690, 368, 454877) on_floor=true
...
final      (-6813751.5, 2683.75, 2145383.5)
```

**1,444,690 m/s, arriving in one frame, with the body reporting `on_floor`.**
Godot platform-velocity inheritance: the body was resting on a collider at the
instant world construction moved it, and 24 km of collider motion in one 60 Hz
frame is exactly that number. Three frames later the player is past the world
perimeter, which prints `player fell below the world at 14, -133, -19 --
returning to spawn`, and the session never recovers.

**This is why section H had no evidence.**
`tests/smoke_gate_a_build_segment_meadows.gd` — the canonical proof that a
controller can build in the real Meadows — sets exactly that flag in its
fixture. It could not complete a run, and it failed as a *walk timeout*
("stopped 28.35m short"), which reads as a navigation problem, not a physics
one. The one automated thing that would have exercised building has never run.

**Fixed:** `player_controller.gd::_clamp_runaway_velocity()`, every physics
frame before `move_and_slide()`, ceiling in `movement.json::locomotion.max_speed`
(120 m/s). Clamped rather than chased to source: the race is between world
construction and the physics step, more than one thing in the Meadows is built
under a standing body, and nothing legitimate comes near the ceiling (sprint
8.6 m/s; a 34 m/s landing is lethal). Direction preserved, so a real fall keeps
falling.

Verified three ways: the free-play boot now ends at `(-13.8, 1.16, -5.4)` on the
ground in the village; the canonical build segment logged the guard firing
(`velocity 1514610 m/s exceeded the 120 m/s ceiling ... clamped`) and then
walked its route for the first time; 54 player/food/death unit tests pass.

A second, smaller fix followed from it: with the walk working, the build segment
reached the press that opens Build and stopped, because the wrapper staged a
progressed opening and paid materials but **no hammer** — and under
CONTROLLER-MAP the hammer *is* the pad route into build mode. One line in
`smoke_gate_a_build_segment_meadows.gd::_fixture_state`.

---

## Verdict per loop

### Building — H1. **Placement works. Getting into build mode was broken; now fixed.**

What passes, played with a pad:

- Quick-bar press puts the hammer in hand.
- Both `camp` and `creature_bed` ghosts arm, report `refusal reason: (none —
  placeable)`, and place: **2 records, 18 wood spent.**
- **`home_built=true` and `creature_bed_built=true` both registered through
  stick/pad-driven placement.** That closes the repeat defect the brief named.
  (`home_progress.gd::maybe_set_creature_beds()` is called from both placement
  paths — `build_placer.gd:655` and `:700`. The objective data was additionally
  rewritten to require ONE bed, so the 3/3 rung no longer ships.)
- Refusals are good: three reasons, each plain English in a persistent hint
  strip beside the full control list — "Something is already here", "Too steep
  to build here", "Can't afford this — check the build menu for what's short".

**The failure, and it was the worst thing in section H — now fixed and re-verified:**

```
standing on the clearing, arbiter winner <none>
  -> PASS: hammer in hand, one interact press opened Build.

standing 1.5m from a deadwood node, arbiter winner Interactable
  { "label": "Gather deadwood", "distance": 1.54, "actionable": true }
  -> FAIL: hammer in hand, the interact press did NOT open Build.
```

Under CONTROLLER-MAP, hammer + interact is the **only** pad route into build
mode, and the interact press was forfeited to any actionable interaction-arbiter
winner. This world scatters **57,967 harvestable nodes**, and the nearest one to
the centre of the opening's own authored build clearing is **5.7 m away** — the
clearing is only clear at its centre. So: step toward a bush and the build
button silently stopped being the build button. Nothing told the player why, and
the recovery ("walk somewhere with no gatherable within 2.4 m") is not
discoverable. This is `gate_a_build_segment.gd`'s own documented worry, and it
reproduced on the first patch the chapter asks you to build on.

And the press did not gather either: `harvest_logic.gd::gather()` refuses
outright when the visibly equipped tool is not the resource's `gathered_with`,
so with the hammer out the player got "Needs an Axe." and no catalogue. **Both
verbs lost.**

**Fixed** in `playground_hud.gd::_hammer_opens_the_catalogue()`, which now asks
a narrower question: *would that offer refuse me?* A tool-gated resource whose
tool is not in hand gives the press back to Build. A resource with no
`gathered_with` (berries) keeps it — the player pressing interact beside a berry
bush wants the berries. A conversation still wins, so a hammer in hand still
talks to Grandpa.

Fixed there rather than by giving build mode its own binding (the owner's
fourteen-button map has no room and the directive bans a chord) or inside
`interaction_arbiter.gd`, whose job is which offer is nearest and drawable, not
equipment rules — teaching it about equipped tools would put gathering rules
inside the thing that arbitrates prompts for conversations, doors, beds and orbs
alike. Explicitly **not** fixed by clearing scatter around build sites, which
treats the symptom and thins the world.

**Verified in play:** the same harness, at the same spot, with the arbiter still
reporting `Gather deadwood` as its winner —
`H1 VERDICT: PASS — hammer in hand, one interact press opened Build.`

**Ghost readability against grass — poor.** Real frames, `capture_check` clean
on grass/terrain/ground/subject (`shots/t5-care/ghost-camp.png`,
`ghost-creature-bed.png`): the ghost is a **teal wireframe in the same hue
family as the grass field**, drawn transparent so blades read straight through
it, with no ground decal marking the footprint. Worse, it sits 3 m ahead of the
player, which from the default over-the-shoulder camera puts it **directly
behind the player's own body** — in the creature-bed frame the ghost is almost
entirely occluded by the trainer. The player is aiming at something they can
barely see, positioned where they can least see it.

**Dismantle — unresolved, with a repro.** Placed a `creature_bed` at
(30.0, 0.2, -42.0), stood 3 m south facing it, held the dismantle button for a
second: `build_placer._dismantle_target` was `<none>` and the record stayed.
Tried from two stances across two runs. I am not confident enough to call this a
defect rather than my aim being wrong — the placer picks its target from what
the player's own -Z ray finds within `DISMANTLE_RANGE` (8 m), and a bed is a low
flat pad the ray may pass over. **Refund therefore also unverified in play.**
Worth ten minutes from someone who can watch the highlight.

### Building as a factory game — H2. **PASS.**

Nothing resembling a production chain: a small catalogue, and the chapter's
whole ask is a Camp (tent + fire + bedroll) plus one Creature Bed.

### Gathering and crafting — I4. **PASS, with one doc/code drift.**

(Corrected twice on the way here. My first verdict said gathering silently did
nothing — I had checked only the inventory count. My second stood 2.6 m from a
node whose prompt radius is 2.4 m. Both were the harness, not the game.)

Gathering is tool-gated and **says so**: with no axe equipped, the prompt is
offered and actionable, the press is refused, and `harvest_node.gd` pushes
"Needs an Axe." to the HUD. (An earlier verdict of mine said gathering silently
did nothing — that was wrong; I had checked only the inventory count, not the
message.) 57,967 nodes means supply is never the problem; the nearest to the
build patch is 5.7 m, so the walk is short and the return (4 wood) is fine.

7 recipes exist and **a fresh save knows all 7** — nothing needs outside
documentation, but nothing is a discovery either. That is a design observation,
not a defect.

**Drift:** `data/items/items.json`'s own comment says "no tool gives a reduced
bare-handed amount (BAREHANDED_FRACTION, tunable)". `harvest_logic.gather()`
returns `amount: 0` on any mismatch, empty hands included, and always passes
`has_tool = true` to `harvest_yield()` — so the documented bare-handed fraction
is unreachable. Either the comment or the gate is stale. Not fixed blind: which
one is wrong is a design call.

### Care and satiety — H4. **PASS on the model. FAIL on the screen the player looks in.**

Measured in the running game:

```
hungry at 82 min of play, critical at 107 min, empty at 126 min
at ZERO satiety: stamina regen x0.35, move speed x0.92, health 100, is_dead=false
```

CLAUDE.md's rule is met exactly. A player who ignores food for a whole chapter
is slowed 8% and regenerates stamina at a third rate — inconvenienced, never
punished, **health untouched**. No starvation path exists and none was added.

But, played with a real pad press of Use on Berries in the real Satchel tab:

```
satchel: the Use verb opened the CREATURE target picker; the player's own
satiety was untouched (40). picker rows: [1. T0 HP 120/120, 2. empty, ...]
hotbar: the same berry from the quick bar DID feed the player (40 -> 58)
```

`tab_backpack.gd::_read_use()` tests `creature_food` **before** the player's own
`satiety` branch. `berries` is the **only** item in the game carrying a
`satiety` value and it also carries `creature_food`, so the backpack always
routes to the creature picker and the player-eating branch below is dead code
from that screen. The picker lists creatures only. `playground_hud.gd`'s comment
still claims "the backpack could always eat berries" — the D68 creature-feeding
change falsified it silently.

So: the FOOD bar drops, the player opens their satchel, selects the only food in
the game, presses Use, and is asked *"Who eats it?"* by a list that does not
include them. It works from the hotbar, if they know to put berries there. The
`berry_verve` player buff is unreachable by the satchel route too.

`tests/test_food.gd::test_every_food_item_restores_satiety` passes throughout,
because it calls `vitals.eat()` directly and never touches the routing.

**Fixed.** The picker now carries the trainer's own row, so "Who eats it?"
includes the person asking. A row rather than a reorder: D68 is right that
berries are the team's food and "the team is the reason the tournament asks you
to gather them", so swapping the two branches would just break the other half.
The screen was already asking the right question; it was missing an answer.

Two things fell out of doing it:

- **An empty belt refused food outright.** `_open_target_picker()` began with an
  unconditional "Nobody on the belt yet." — so before the first catch, which is
  most of the opening, the hungry player could not eat at all. Food now passes
  that guard; potions, revives, tonics, elixirs and TMs genuinely need a
  creature and keep it. Found by the new test, not by reading.
- **`_targeting_food` / `_targeting_tonic` / `_targeting_elixir` were never
  cleared when a picker closed** — only on a full tab rebuild. `_eligible()`
  tests them in order with food second, so feeding a creature and then using a
  potion evaluated the potion's picker under the food rule. Latent before this
  task; no longer latent once a stale `_targeting_food` also draws a trainer
  row. Cleared in `_end_targeting()` where the other four already were.

**And the test that hid it.** `test_food.gd` passed throughout, because it calls
`vitals.eat()` directly; its own comment claimed it drove the path "exactly the
way `tab_backpack.gd`'s `_read_use()` does it", which had stopped being true.
Added `tests/smoke_backpack_player_eats.gd`: real joypad presses through the
live InputMap, the real menu shell, the real tab, and no `eat()` call anywhere.
**Verified to fail cleanly against the unfixed code** ("tab_backpack.gd has no
trainer row in its target picker…", exit 1) and pass against the fix. Wired into
`ci.yml`'s smoke matrix — it needs no world build, so it costs seconds.
`test_food.gd`'s comment now says what it does and does not cover.

### Injury, beds and rest — H3. **PASS.**

- Completing a rest sets `rested` and lifts happiness to 0.61, just over the
  0.6 `happy_at` gate — so a night's rest is what makes a creature
  tournament-eligible.
- `rested` expires after 45 min awake, so it describes today.
- `resting_drain_scale: 0.0` — a bed also feeds; a night's rest is not a
  night's hunger.
- Six creature beds already stand in the world before the player builds one
  (stronghold recovery point plus authored camps), and
  `creature_bed.gd::build_real(player_built)` correctly refuses to credit the
  chapter's objective for world-owned beds.

**Camps — played, and they work.** Ran `tests/smoke_authored_camps.gd` against
the real world: five authored camps carry a rest block and every one of them
stood up with **rest + craft + a creature bed** — `trail_camp` (346, 935),
`ranger_camp` (-256, 2260), `riverwatch_rest` (215, 3697),
`highfield_stockcamp` (277, 5652), `the_waystop` (-21, 7457). Each offers
"Rest until morning" where the player stands, and pressing it passed the night:
**day 1 → 2, and the bedded creature woke at full HP.** H5's "recovery and
crafting" is real at every one.

Worth noting for pacing rather than as a defect: all five sit in bands 2–5, the
nearest about a kilometre from the village. Band 1 has no authored camp — the
opening's answer to rest is the camp you build yourself, which is what the
build ladder teaches.

### The five-creature limit — G4. **PASS, and it is the best-shaped thing in my scope.**

Filled the party to five, handed a sixth to the same `Game.pending_catch` slot
`encounter_director.gd::_resolve_catch` uses when the belt is full:

```
party.add() refused the sixth, as the cap requires
the shell opened the Creatures tab by itself, release stage 'choose'
```

Play cannot resume with six owned. Nothing resembling storage, a reserve box or
a hidden slot exists, and none was added. The ceremony is well written: the
farewell restates the creature's level, bond nodes and its **actual history with
the player** at the exact press that gives it up, and says plainly that a
released creature does not come back.

### Care as a chore — H6. **Concern, not a failure.**

```
a creature fed to full is hungry again 64 min later
five owned = 5 target-picker trips (Use press + pick, one per press) every 64 min
there is no feed-all verb
```

64 minutes is generous and the drain is genuinely light — this never competes
with the creature journey, which is H6's actual test. The cost is the
interaction shape: feeding the team is five separate open → focus → Use →
choose sequences, roughly 15–20 of them across a chapter. It is the least
interesting minute in the game, repeated.

### Inventory and death satchels. **Partly evidenced.**

Slot/stack, 24 slots, no carry weight — as the hard rule requires.

One played death drops one satchel, correctly: the inventory drained, and the
record carried the death position
(`{"position": [-14.07, 1.20, -8.05], "state": []}`).

**Not verified: that MULTIPLE satchels persist.** I could not stage a second
death in the free-play world — dropping the player 120 m produced
`landed on frame 11 at -0 m/s, health 100`, i.e. the teleport never became a
fall, twice. That is a harness limitation I ran out of runway to diagnose, not
evidence against the rule. `tests/test_satchel.gd` covers multi-satchel
persistence and the save round trip at unit level, but that is not a played
path. **Stated as a gap rather than a pass.**

---

## Two claims of mine that testing killed

Recorded because the evidence rule cuts both ways:

- **Not a hole in the world.** A sweep found 87 columns near the village where a
  downward raycast hit nothing. Dropping a real capsule down every one landed on
  terrain — Terrain3D simply does not answer a long ray from y=400. Had I
  stopped at the raycast I would have filed a fabricated defect.
- **Not a bad respawn point.** `_spawn_position` is the world origin and
  `village.json` puts the workshop at (2,2), which looked alarming. Played it:
  zero bodies overlap a player capsule there, and a player put there rests at
  y=0.90 and stays. The launch needs the world-construction race specifically.

A third, smaller one: the "[Shift] Snap step" in the ghost frames is not a
controller-first defect — `build_snap_cycle` has joypad button 11; my capture
just never pinned the device to gamepad.

Also noted, wire-it-or-delete-it class: `inventory.gd::HOTBAR_SLOTS := 6`
disagrees with the real quick bar (5, per `game_state.gd`, `playground_hud.gd`
and five bound actions). Its own comment admits "nothing reads it yet".

## What shipped on this branch

1. `player_controller.gd::_clamp_runaway_velocity()` + `movement.json`
   `locomotion.max_speed` — the 7,000,000 m launch.
2. `playground_hud.gd::_hammer_opens_the_catalogue()` — build mode no longer
   forfeits its only pad route to an offer that would refuse the press.
3. `tab_backpack.gd` — the trainer's row in the eater picker, the empty-belt
   food guard, and the uncleared targeting state.
4. `tests/smoke_backpack_player_eats.gd` + its `ci.yml` matrix entry — the
   reachability test `test_food.gd` was never going to be.
5. The hammer in `smoke_gate_a_build_segment_meadows.gd`'s fixture.
6. The T5 harnesses, including a fix to their own navigator callback signature
   (`stick_navigator.gd`'s fourth argument is the stick driver and takes two
   floats; a no-arg callback meant the navigator pushed nothing and two runs
   reported walks that never happened).
7. `shots/t5-care/*.png` — four real ghost frames, `capture_check` clean.

## What is still owed on section H

- **Ghost contrast and its position behind the player** (H1) — a teal wireframe
  in the grass's own hue family, drawn 3 m ahead where the over-the-shoulder
  camera puts the player's body in front of it. Frames are in `shots/t5-care/`.
- **Dismantle and refund, played** (H1) — repro in this file; ten minutes for
  someone who can watch the highlight.
- **A second death, played**, for the multiple-satchel rule.
