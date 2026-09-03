# Finding — Stronghold Approach / Meadows Hall verification, 2026-08-29

Track 3 (content/fun) pass, `ralph/T3-STRONGHOLD`. Scope: §15 Stronghold
Approach and §16 Meadows Hall, per the owner-direction midgame rebuild doc.
Branch pushed with no PR, per this lane's own instructions.

## What this pass found: already built, and it plays

Band 5 and the stronghold finale are far more complete than a cold read of
the two governing prompts (`docs/ralph-prompts/66-BAND5-*.md`,
`docs/ralph-prompts/69-STRONGHOLD-*.md`) suggests — those prompts read as
open asks, but the work against them has already landed on `main` across
many prior lanes (R8.2/R8.3/R8.4, SG38/SG40/SG44, GATE-E, BAND5-CONTENT,
BAND5-DENSITY, T1-ARCH). Per CLAUDE.md's "evidence-backed already fixed is
valid," this pass verified rather than re-authored:

- **§15 (approach):** band5 fields an outer watch, a mid-approach officer
  checkpoint, wild ecology (22 clusters/75 creatures across 4 species plus
  an alpha galecrest and a solitary "mudsnout" special encounter --
  `data/config/bands/band5_stronghold_approach/spawns.json` orders
  5000-5022), a lit pylon spine as a readable bearing toward the Hall, drained
  ground, and a final waystop/camp clearing with harvest nodes nearby
  (`props.json` order 5001, `the_waystop`). The finding report referenced by
  this lane's brief (`finding-post-tournament-cadence-2026-08-29.md`) already
  confirmed band 5 passes both cadence measures with 5 authored POIs and no
  gap over 130m -- **not** a region to add content to on density grounds, and
  this pass did not.
- **§16 (the Hall):** `scripts/world/stronghold.gd` builds the canonical
  five-space route (Outer Works -> Courtyard -> Tether Chamber Approach ->
  Warden Arena -> Legendary Chamber) with a real recovery bed before the
  Warden and a gated shutter behind the elite. `scripts/world/
  stronghold_climax.gd` places the Warden (a genuine 5-creature team, three
  types, ace 4 levels above the rest -- `warden_aldis` in `data/config/bands/
  band5_stronghold_approach/trainers.json`), the reveal readout, and runs
  §28's finale order (freed -> voluntary join offer -> five-creature ceremony
  if the belt is full -> machinery fails -> `MeadowHealing` responds).

## Verification performed (Godot 4.7-stable, fetched fresh this session)

- `tests/smoke_stronghold.gd` — passed clean: five spaces in order, every
  floor stands, the shutter gates correctly, the recovery bed heals, the
  machine stands at scale.
- `tests/smoke_gate_e_finale.gd` — passed clean: a full five walks in from
  the Hall entrance, fights the three-trainer gauntlet with a real rest
  between the second and third, the reveal is read before the Warden speaks,
  the Warden falls, the lever frees the legendary, a full belt opens the
  R4.10 release ceremony, the released creature and the legendary are both
  correctly resolved, the region visibly heals, and a post-victory villager
  line closes the objective chain.
- `tests/run_tests.gd -- --only=progression_state,dialogue_runner,item_gate,
  party` — 135 tests, 995 assertions, 0 failed (no regression from the fix
  below).

## The one real bug found and fixed

Neither existing test reloads a save mid-finale or after it — both play one
continuous session. `scripts/world/stronghold_climax.gd::build()` runs again
on every world load (a fresh node reading whatever flags a save already set),
and `_place_legendary()` built the caged Bound Legendary and reset `_stage`
to `""` unconditionally, with no check against `legendary_settled` or
`legendary_freed` — unlike `key_pickup.gd`, `meadow_healing.gd`, and
`rift_collapse.gd`, which all already keep the same "check the one-time flag
before spawning, not after" rule for their own one-time world state.

Two concrete, reachable failures followed:

1. **The ordinary case.** Any save taken after finishing the finale (which is
   every save from then on) would, on reload, stand a fresh caged Bound
   Legendary back up in the Legendary Chamber — visually contradicting both
   possible endings (it is on the party belt right now, or it walked free and
   the player kept their five), and violating prompt 69's own acceptance
   criterion, "no duplicate legendary/repeat ceremony after reload."
2. **A narrower soft-lock.** `legendary_freed` is set the instant the lever
   is pulled, but the join offer and the release ceremony that follow run
   through the dialogue panel first, which — unlike the ceremony's own menu —
   does not pause the tree. `autoload/game_state.gd`'s 180s fallback autosave
   (and an ordinary manual save, since nothing blocks opening the pause menu
   during a conversation) can therefore land in the few seconds between
   `legendary_freed` and `legendary_settled`. Reloading such a save hit
   `_sync_gate()`'s own `not legendary_is_freed()` guard on the machine
   prompt — permanently refused, with `_stage` reset to `""` and no way left
   to reach the join offer or the decision again. That save's chapter ending
   would never resolve.

Fixed in `_place_legendary()`: if `legendary_settled` is already set, skip
spawning the legendary entirely and set `_stage` to `done`. If only
`legendary_freed` is set (the narrow window above), build it already freed
(no cage) and resume at the `freed` stage, so `_advance()` picks the sequence
back up at the join offer rather than replaying lines the player already
heard.

## New test coverage

`tests/smoke_stronghold_reload.gd` — boots the world twice with the two flag
combinations above pre-set on `Game.progression` (the same order a real load
takes: flags first, then the scene that reads them), and asserts the settled
ending spawns nothing and the freed-not-settled window comes back freed and
resumes. This is the piece of `CLAUDE.md`'s "party-five rules at the
legendary choice" coverage that the existing single-session finale test
structurally cannot reach, since it never serializes and reloads.

Both scenarios pass. Full log: this branch's own CI run.

## What this pass did not do

No content was added to band 5 or the stronghold — the cadence measurement
already on `main` says not to, and this pass's own read of the existing
gauntlet/roster-temptation/camp content agrees it already satisfies §15/§16's
asks. No visual work — that is Track 1's lane, and `stronghold_occupation.gd`/
`.json` were left untouched. Bands 1/3/4, `playground_world.gd`'s `TM_AT`
table, and `tools/gate_f/` were not touched, per this lane's ownership
boundaries.
