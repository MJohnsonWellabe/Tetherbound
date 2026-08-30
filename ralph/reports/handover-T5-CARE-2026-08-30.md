# T5-CARE — building, survival and care, played

**Branch:** `ralph/T5-CARE` off `origin/ralph/LAND-0830I`
**Scope:** `ralph/MEADOWS_EXIT_CRITERION.md` section H (H1–H6) and section I.
**Date:** 2026-08-30

## Why this lane existed

Section H was entirely unevidenced. Over a long night of parallel work, lanes
covered visuals, terrain, story, content, combat, performance, reliability and
audio; nobody verified building, survival or creature care by playing them. It
is also the part of the game the player touches most often between fights.

## Method

Godot 4.7-stable — the version `ci.yml` pins — installed into the session and
the project imported clean (exit 0). Every run below boots the real
`scenes/world/meadows_playground.tscn` and drives it with parsed physical
`InputEventJoypadButton`/`InputEventJoypadMotion` events through the live
InputMap, in the style of `tests/helpers/gate_a_build_segment.gd`. Where a
number is quoted it was measured in that running world, not read from config.

Harnesses added by this lane, all runnable and all committed:

| tool | what it plays |
|---|---|
| `tools/_play_t5_care.gd` | satiety, eating from both screens, team feeding, bed rest, the sixth catch |
| `tools/_play_t5_gather_craft.gd` | gather node → item → use, recipe discoverability, death satchels |
| `tools/_play_t5_strand.gd` | walling the player in and trying to get out |
| `tools/_play_t5_walk_build_route.gd` | the opening's build route, watching the floor |
| `tools/_probe_t5_ground.gd`, `_probe_t5_holes.gd`, `_probe_t5_holes2.gd` | terrain height vs. real collision |
| `tools/_probe_t5_spawn.gd`, `_probe_t5_launch.gd` | the spawn defect below, isolated and traced |
| `tools/_play_t5_respawn.gd` | where death and the fall-rescue actually put you |
| `tools/capture_t5_build_ghost.gd` | real frames of the real armed ghost over real grass |

---

## The headline: the player is thrown 7,000,000 metres out of the world

**Found, traced, fixed, and verified fixed on this branch.**

Booting the real Meadows with `opening:beat:free_play` set — the ordinary
post-opening state — reproducibly threw the player out of the world. Traced
frame by frame with `tools/_probe_t5_launch.gd`:

```
frame  14  pos (      0.0,    2.90,      0.0)  vel (0, 0, 0)               on_floor=false
frame  17  pos ( -23721.0, 3079.46,   7468.8)  vel (-1444690, 368, 454877) on_floor=true
...
final      (-6813751.5, 2683.75, 2145383.5)
```

**1.44 million metres per second, arriving in a single frame, with the body
reporting `on_floor`.** That is Godot's platform-velocity inheritance: the body
was resting on a collider at the instant world construction moved it, and 24 km
of collider motion in one 60 Hz frame is exactly 1,444,690 m/s. Three frames
later the player is past the world perimeter, which prints

```
[world_perimeter_corridor] player fell below the world at 14, -133, -19 -- returning to spawn
```

and the session never recovers.

**This is why section H had no evidence.** `tests/smoke_gate_a_build_segment_meadows.gd`
— the canonical proof that a controller can build in the real Meadows — sets
exactly that flag in its fixture. It could not complete a run on this branch, so
the one automated thing that would have exercised building never ran, and
nobody noticed because it fails as a walk timeout ("stopped 28.35m short")
rather than as a crash.

**Fix shipped:** `player_controller.gd::_clamp_runaway_velocity()`, called every
physics frame before `move_and_slide()`, with the ceiling in
`movement.json::locomotion.max_speed` (120 m/s). Clamped rather than chased to
its source: the race is between world construction and the physics step, more
than one thing in the Meadows is built under a standing body, and nothing the
player legitimately does comes near the ceiling (sprint is 8.6 m/s;
`vitals.json` calls a 34 m/s landing lethal). Direction is preserved rather than
zeroed, so a real fall keeps falling.

Verified: the same free-play boot that ended at `(-6789673, 2686, 2137802)` now
ends at `(-13.8, 1.16, -5.4)`, standing on the ground in the village.

### Two things this is NOT

Being precise, because two plausible-looking claims did not survive testing:

- **Not a hole in the world.** A first sweep found 87 columns near the village
  where a downward raycast hit nothing. Dropping a real capsule down every one
  of them landed on terrain (`tools/_probe_t5_holes2.gd`). Terrain3D simply does
  not answer a long ray from y=400; the world is solid. Had I stopped at the
  raycast I would have filed a fabricated defect.
- **Not the respawn point.** `_spawn_position` is `(0, 2.9, 0)` — the world
  origin — and `player_death.gd` and the perimeter rescue both teleport there,
  which looked alarming given `village.json` puts the `workshop` at `(2, 2)`.
  Played it (`tools/_play_t5_respawn.gd`): zero bodies overlap a player capsule
  at that point, and a player put there comes to rest at y=0.90 and stays.
  **PASS.** The launch needs the world-construction race specifically.

---

## Verdicts, one per question the lane was asked

### Building — H1, H2

*Verdict pending the re-run of the build segment; see "Status" at the end.*

What is settled from the played runs and the shipping code:

- Placement refuses for exactly three reasons, each with plain-English text
  shown in red in a persistent hint strip alongside the full control list
  (`build_placer.gd::evaluate_placement`, `_hint_text`): "Something is already
  here", "Too steep to build here", "Can't afford this — check the build menu
  for what's short". That is good: the refusal never leaves the player guessing.
- **There is no refusal for "this would seal the player in."** Stranding is not
  prevented at placement time; it is caught downstream by
  `player_controller.gd::_recover_if_entombed`. Played result in the stranding
  section below.
- The reported Gate F defect blaming `creature_bed_built_3` on stick-driven
  placement needs no fix here: `home_progress.gd::maybe_set_creature_beds()` IS
  called from both placement paths (`build_placer.gd:655` in `_place`, `:700` in
  `restore_from_game`). The objective data has additionally been rewritten
  (FIRST-HOUR-FUN-REBUILD) to require ONE bed, so the 3/3 rung no longer ships
  at all. Bookkeeping, not a defect.

### Care and satiety — H4. **PASS on the model, FAIL on one screen.**

Measured in the running game (`tools/_play_t5_care.gd`):

```
hungry at 82 min of play, critical at 107 min, empty at 126 min
at ZERO satiety: stamina regen x0.35, move speed x0.92, health 100, is_dead=false
```

CLAUDE.md's rule is met exactly. A player who ignores food entirely for a whole
3–4 hour chapter is slowed 8% and regenerates stamina at a third rate. They are
inconvenienced, never punished, and **nothing touches health**. There is no
starvation death path in the code and none was added.

**But the player cannot eat from the screen they would look in.** Played, with
a real pad press of the Use verb on Berries in the real Satchel tab:

```
H4 satchel: the Use verb opened the CREATURE target picker; the player's own
satiety was untouched (40). picker rows: [1. T0 HP 120/120, 2. empty, 3. empty,
4. empty, 5. empty]
H4 hotbar: PASS — the same berry from the quick bar DID feed the player
(satiety 40 -> 58, berries 10 -> 9)
```

`tab_backpack.gd::_read_use()` tests `creature_food` **before** the player's own
`satiety` branch. `berries` is the only item in `data/items/items.json` carrying
a `satiety` value and it also carries `creature_food`, so the backpack always
routes to the creature picker and the player-eating branch below it is dead code
from that screen. The picker offers party creatures only — there is no player
row. `playground_hud.gd`'s own comment still asserts "the backpack could always
eat berries", which the D68 creature-feeding change silently falsified.

Player-facing effect: the FOOD bar goes down, the player opens their satchel,
selects the only food in the game, presses Use, and is asked *"Who eats it?"*
with a list that does not include them. The `berry_verve` player buff
(stamina regen ×1.15) is unreachable by that route too. It works from the
hotbar — if they know to put berries there.

**Proposed patch (not applied — see Scope note):** in `_read_use()`, when the
focused item has BOTH `satiety` and `creature_food`, the picker should carry the
player as its first row. That is a change to a shared target picker used by
potions, tonics, elixirs and TMs, and getting the eligibility and ineligibility
text right for a non-creature row touches `_eligible`, `_ineligible_reason`,
`_apply_to_creature` and the row builder. It is bigger than "clear and local",
so it is written up rather than jammed in beside a physics fix.

### Care as a chore — H6. **Concern, not a failure.**

Measured with five creatures owned:

```
a creature fed to full is hungry again 64 min later
five-creature team = 5 target-picker trips (Use press + pick, one creature per
press) every 64 min
there is no feed-all verb
```

64 minutes is a generous cadence and the drain is genuinely light. The cost is
the interaction shape, not the frequency: feeding the team is five separate
open-menu → focus item → Use → choose row sequences, because the picker takes
one creature per press. Over a 3–4 hour chapter that is roughly 15–20 such
sequences. It never threatens the creature journey (H6's actual test) but it is
the least interesting minute in the game, repeated.

### Injury, beds and rest — H3. **PASS.**

- Completing a rest sets `rested` and moves happiness to 0.61 — above the 0.6
  `happy_at` gate, so a night's rest is what makes a creature tournament-eligible.
- `rested` expires after 45 minutes of awake time, so "well rested" describes
  today rather than a box ticked once.
- `resting_drain_scale: 0.0` means a bed also feeds — a night's rest is not a
  night's hunger.
- Six creature beds already stand in the loaded world before the player builds
  one (the stronghold's authored recovery point plus the authored camps), and
  `creature_bed.gd::build_real(player_built)` correctly refuses to credit the
  chapter's objective for world-owned beds.

### The five-creature limit as an experience — G4. **PASS, and it is good.**

Played: filled the party to five, made a sixth creature, handed it to the same
`Game.pending_catch` slot `encounter_director.gd::_resolve_catch` uses when the
belt is full.

```
G4: party.add() refused the sixth, as the cap requires
G4: the shell opened the Creatures tab by itself, release stage 'choose'
```

The sixth catch forces the release ceremony; play cannot resume with six owned.
Nothing here resembles storage, a reserve box or a hidden slot, and none was
added. The ceremony itself is well written — the farewell screen restates the
creature's level, bond nodes and its actual history with the player at the exact
press that gives it up, and says plainly that a released creature does not come
back. This is the part of section H in the best shape.

### Gathering, crafting and inventory

*Verdict pending; see "Status".*

---

## Scope note

Two findings are written up rather than patched, per the brief's instruction to
propose rather than widen:

1. The backpack/player-eating routing (above) — a shared-picker change.
2. No feed-all verb — a design question about care's interaction shape, not a
   defect.

The one fix applied is the velocity clamp, because it is local, it is a
reliability failure of the kind section I9 forbids outright, and without it the
lane could not gather the evidence it exists to gather.

## Status

Runs still in flight at the time of writing are marked *pending* above and are
filled in by the final commit on this branch.
