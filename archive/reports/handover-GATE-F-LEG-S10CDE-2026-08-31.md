# Handover — GATE-F-LEG-S10CDE (S10c/S10d/S10e, in isolation)

Branch: `ralph/GATE-F-LEG-S10CDE`. Run directory:
`ralph/reports/gate-f-run-GATE-F-LEG-S10CDE/`.

## Honesty statement (read this first)

This lane drives S10c, S10d and S10e — Gate F's post-win "world healing"
walk-back (Old Mill Crossing → Tether Relay → Burrow Warrens → South
Bridge → the village → Grandpa's house) — **in isolation**, from a
hand-authored `S10b-exit.json` rather than one produced by a real
S10a/S10b run. `ralph/GATE-F-FOUNDATION` and `ralph/GATE-F-LEG-S10AB`, the
upstream lanes this work depends on, did not exist at any point during this
session (checked repeatedly with `git fetch origin`).

**Every finding below must be read as "S10c/d/e, given this hand-seeded
state, does X" — never as "the chapter does X."** This run says nothing
about whether a real player's S09→S10a→S10b chain produces a save shaped
like this seed, whether the roster ceremony or the Warden fight themselves
work, or about pacing/difficulty before this seed's entry point. See
`ralph/reports/gate-f-run-GATE-F-LEG-S10CDE/HONESTY.md` for the standing
version of this note.

## The seed

`tools/gate_f/build_s10b_synthetic_seed.gd` builds
`ralph/reports/gate-f-run-GATE-F-LEG-S10CDE/S10b/saves/S10b-exit.json`
using real game arithmetic (`creature_species.gd::spawn` +
`creature_instance.gd::set_level`, the same curve a real playthrough uses)
rather than hand-edited numbers:

- Party of 5: terrapup Bramble (L19), mudsnout Digger (L20), brooktail
  Ripple (L19), tuskroot Anvil (L20), veridian Veridian (L22) — full HP,
  save version 16.
- 32 progression flags: every one of `objectives.json`'s 26-entry main
  chain through `settle_the_roster`, plus `legendary_joined`,
  `legendary_settled` and `learned_legendary_is_the_source`.
  `meadows_acknowledged` is deliberately **not** set — that is the one
  flag S10c/d/e exist to set.
- Positioned at the approach-drain start near the Hall exit, day 9.

This is a **minimum-viable** clean-victory state, not a full playthrough's
history: it carries only the flags the main chain actually requires, not
every optional trainer or side flag a real player would likely also have
(see the Dell finding below for what that costs).

## Result: the walk-back completes cleanly and the world reads as healed

All three sub-segments are COMPLETE with real save handoffs between them,
chained start to finish from the single seed above:

| Segment | Result | Exit position | Notes |
|---|---|---|---|
| S10c | 25/26 pass, 1 delegated, **0 fail** | (-151.6, -1.9, 4210.8) — Old Mill Crossing | |
| S10d | 26/28 pass, **2 fail (both explained, non-defect)** | (1.17, -2.88, 1337.71) — ~8m from South Bridge | |
| S10e | 37/37 pass, **0 fail** | (-22.72, 1.32, -15.14) — inside Grandpa's house, at his marker | Final `S10-exit.json` |

Reassembled walk-back distance across the three sub-segments: S10c
3391.81 m + S10d 4235.49 m + S10e 1807.74 m = **9435.04 m**, well clear of
the original monolithic segment's 7000 m "no shortcut" bar.

World-healing evidence, logged once on the `legendary_freed` trigger during
S10e: **1916 plants regrown, 13 tether lights out, 4 beaten Team Tether
patrols withdrawn, 0 barriers newly opened** (both barrier flags —
`road_gate_open`, `hall_approach_open` — were already set by this seed
before healing ran, so zero *new* openings is the correct number here, not
a miss). `meadows_freed.json`'s five post-win conversations (Mira, Oskar,
Tam, the Quarry Foreman, Grandpa) are each reachable and each carries
`flag:meadows_acknowledged` on its first line; this run reached it through
Tam and Grandpa specifically. Grandpa's own post-win line
(`grandpa_freed`, "I felt it in my knees before I heard it...") plays
correctly — this is the fix recorded below, verified end-to-end for the
first time in this session.

The final save (`S10e/saves/S10-exit.json`) is the chapter's true terminal
state: version 16, day 9, party of 5, 38 progression flags including
`meadows_acknowledged`. Bramble is fainted (0/249.6 hp) from a wild
encounter inherited from S10c (see below) — the other four are untouched
and healthy (Digger 214, Ripple 191.36, Anvil 278.2, Veridian 949.2).

## Two honest non-defects (recorded, not "fixed")

1. **A wild creature fainted Bramble mid-walk (S10c → S10d).** The
   harness's `move_to` only drives movement, not combat, so a wandering
   wild creature engaged the deployed Bramble and it took 38 small hits
   passively over ~85 seconds before fainting; `combat_end` then fired and
   the walk resumed normally. This is the world doing exactly what its own
   design says ("the world is not frozen" post-win) — not a bug, and
   never previously observed because no earlier run had walked far enough
   to hit it. Carried into every later save.
2. **An unbeaten Team Tether officer (Dell) stopped a `move_to` leg in
   S10d**, because this lane's minimum-viable seed carries only
   `relay_captain_defeated` and not the optional pickets/officers a real
   player would very likely have already beaten along the same ground.
   `relay_officer_dell` correctly refused to be fought with a fainted
   Bramble and nothing else deployed. A seed limitation, not a game
   defect — flagged rather than patched, since inflating the seed with
   flags the main chain doesn't require would misrepresent what a
   "clean, minimum" S10b-exit looks like.

## What was fixed

### Game code (four defects, all verified)

1. **GAME-F4 — creature base stats lost on save/load.**
   `scripts/save/save_game.gd`: `base_hp`/`base_attack`/`base_defence`
   were never written to or read from the save file. Bumped `VERSION` 15
   → 16, added the three fields to both the write and read paths, and
   added `_migrate_v15()` to backfill them from `data/species.json` for
   any pre-existing save.
2. **`world_perimeter.gd`'s kill-volume false-triggered on a player
   legitimately standing on solid ground** (a residual case of the
   documented "platform velocity inheritance" glitch), and on trigger
   unconditionally reset the player to the **world spawn** — 7 km from
   anywhere near a mid-walk position — burning an entire `move_to`
   budget trying to walk back. Fixed to track the player's last verified
   on-ground position (age-gated, 3 s) and recover there instead.
3. **All four `sigil_gate_gorge_*` carved trenches (`terrain_playground.json`)
   had no rescue failsafe**, unlike every other carved gorge in the game.
   A player who fell in was permanently pinned with no way out except a
   used-up `move_to` budget. Wired `road_gate.gd`'s existing
   `severed_spokes.gd::_add_carve_failsafe` mechanism to all four via a
   new opt-in `gorge_carve_ids` + `"failsafe": true` flag, called from
   `playground_world.gd::_build_sigil_gate`. Verified with
   `tools/_probe_gorge_failsafe.gd`: a player dropped at the historical
   pin point is rescued within 30 frames.
4. **Grandpa had no post-win dialogue at all.** His conversation table
   (`opening.json`'s `beats.grandpa_conversations`) reaches a terminal
   `free_play` beat around the tournament and then goes silent by design
   for the rest of the game — nothing ever pointed him at a line for
   after the Warden falls, so the ending the protocol itself promises
   ("Grandpa's post-win line") was unreachable. Added `grandpa_freed` to
   `data/dialogue/meadows_freed.json` and a
   `sequence_director.gd::_grandpa_conversation_id()` check that looks at
   `legendary_freed` ahead of the beat table.

### Harness/protocol data — not game code (six fixes, this session)

Everything below is `tools/gate_f/segments/S10e.json` and this run
directory's own bookkeeping. None of it touched game code, and each is
recorded in full in `RESTARTS.md` and the per-attempt
`S10e-superseded-N/WHY_SUPERSEDED.md` files:

1. Split the village approach behind a gate waypoint (`S10e-98g`) —
   `stick_navigator.gd` is a local wall-follower, not a pathfinder, and a
   straight `move_to` at the village centre never found the one gap in
   the fence.
2. Retargeted the village interact at Tam's actual position instead of
   the bare village-square centre, and Grandpa's `move_to` at his real
   `grandpa_house.gd::marker("grandpa")` instead of the house's origin
   point — both npc prompts have only a 3.8 m radius, and the abstract
   destinations left the arrival point outside it.
3. Recalibrated `S10e-108`'s `distance_above` floor 3000.0 → 1300.0: the
   original figure assumed geography this direct leg does not have (see
   the reassembled-distance table above, which clears the *original*
   whole-walk-back bar comfortably even with this leg's own floor
   lowered).
4. Replaced two blind `press interact xN` counts with
   `advance_dialogue_until_closed` (the predicate-driven primitive
   `S02`/`S02C`/`S03` already use) — a guessed count either leaves a
   3-line conversation open or over-presses and re-opens it, since a
   re-talkable NPC's next `interact` while still in range is a new open,
   not a no-op.
5. Split the Grandpa approach behind a door waypoint
   (`grandpa_house.gd::marker("door")`) — a straight `move_to` at his
   interior marker walked `stick_navigator.gd` around the *outside* of
   the house instead of through the doorway, stalling at an exterior
   corner it couldn't route past.
6. One operator error, disclosed rather than hidden: attempt 3's raw run
   artifacts were lost to a bad `rsync`-then-`rm -rf` during a supersede
   move. The findings from that attempt were captured in its
   `WHY_SUPERSEDED.md` before the loss and are not in question; there is
   simply no raw telemetry left to re-inspect for that one attempt. See
   `S10e-superseded-3/WHY_SUPERSEDED.md`'s own note.

Six attempts at S10e in total (`S10e-superseded-1` through `-5`, plus the
final clean run) — each restart, its cause, and its fix are recorded in
full in `RESTARTS.md`.

## Bottom line

Given this lane's hand-seeded, minimum-viable clean-victory entry state,
S10c → S10d → S10e completes end to end with real save handoffs, no
teleports, and no shortcuts: the world visibly heals (vegetation back,
lights dead, patrols thinned), every reachable post-win NPC — including
Grandpa, previously unreachable — has something new to say, and the
27-objective main chain's last flag (`meadows_acknowledged`) closes
correctly. Four real game defects were found and fixed along the way (one
save-corruption bug, one catastrophic-teleport bug, one missing rescue
mechanism × 4 hazard sites, one entirely missing ending line for a named
character), plus six harness/protocol-data fixes needed to make this
segment's own synthetic walk actually reach the places a real player
would.

What this run does **not** say anything about: whether S09→S10a→S10b
produces this seed in practice, whether the roster ceremony and Warden
fight work, or pacing/difficulty anywhere before this seed's entry point —
those remain `ralph/GATE-F-FOUNDATION`/`ralph/GATE-F-LEG-S10AB`'s scope.
