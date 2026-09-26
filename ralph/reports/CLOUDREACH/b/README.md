# Cloudreach-B witness evidence

Lane: Cloudreach-B. PR: #294. Branch: `tb/cloudreach-b-f06-1-foot-regions`.
All runs used local Godot 4.7-stable, headless, `--accelerated` (physics stays at 1/60 per step). Each run had its own `XDG_DATA_HOME`.

## F06#2 — Fly training, landing and invalid landing: PASS (flight leg, declared fixture)

- Command: `godot --headless --path . --script tests/smoke_cloudreach_fly_training_witness.gd -- --accelerated --start=aerie --leg=flight`
- Evidence: `f06-2-fly-training/aerie-start/witness.json` and `events.json`.
- The witness asserts, by ordinary input:
  - **Trial edge refused.** Mid-trial, before Fly is earned, steering out of the marked volume is refused ("Stay inside the marked flight trial."). The flyer stays inside and keeps flying, and the trial then completes (3 rings in order, then a verified landing that unlocks Fly).
  - **Sealed Upper Cloudreach refused.** After Fly unlocks and before the shrine windlass, the witness climbs the aerie lift to y 770, glides at the sealed `cloudreach_upper` wall and tries to descend there. The wall refuses it ("This wind route is still sealed: cloudreach_upper.") 0.75 m from the box, with 0 frames inside. It then lands back on the aerie deck.
  - **Landings.** There are 4 landings (trial, return from the refused attempt, High Roost shrine, final return to the aerie), all on a verified collision floor.
  - **No gate breach.** No trial frame falls outside the marked volume, and no frame is inside sealed Upper Cloudreach before its unlock.
  - **Reload.** A disk save/reload at the leg end keeps every persisted field of all five members, the exact flag set and the Fly unlock.
- **Not covered here: anchor recovery.** A refused landing zeroes the inward velocity, so ordinary input never reaches `recover_to_anchor`. Fly anchor recovery is covered by `tests/smoke_cloudreach_closed_gate_seal.gd` legs (i) and (j), plus `tests/test_fly_traversal.gd`. Leg (i) recovers to the verified launch anchor; leg (j) is carried out of sealed volumes when the anchor is cleared. The exhausted-fall branch in `scripts/player/fly_controller.gd` (`state == "exhausted"`) has no test anywhere.

## F06#3 — the loaner path does not bypass gates or lose creatures: PASS (flight leg, declared fixture)

- Command: `godot --headless --path . --script tests/smoke_cloudreach_loaner_witness.gd -- --accelerated --start=aerie --leg=flight`
- Evidence: `f06-3-loaner/aerie-start/witness.json` and `events.json`.
- The fixture party has five non-Fly creatures, so Maela's Galecrest loaner carries every flight. The witness asserts:
  - **No loaner before the trial.** A double-jump before the trial deploys no Fly and offers no loaner.
  - **Every launch is the loaner.** There were 4 launches, all with the loaner and a party of 5, and 0 owned-carrier frames.
  - **The loaner hits the same sealed wall.** It is refused at `cloudreach_upper` 0.75 m from the box, with 0 frames inside.
  - **0 violations over 13,068 loaner frames:**
    - the loaner is never a party member;
    - the five creature uids never change;
    - it is never inside a sealed box before that box's flag is set;
    - it never leaves the trial box before Fly unlocks.
  - **Reload.** The disk save/reload keeps the five uids and every persisted field, with no loaner species in the party.
- **Disclosed failed run.** One earlier run on this code failed after its witness checks had passed. It stalled in the unchanged base route, walking on the shrine dais toward `shrine_vane_east`. This happened at the normal clock (`physics_hz` 60, `time_scale` 1.0): stick velocity was set, but `last_motion` was zero, the only contact was the flat dais floor (normal pointing up), and the interaction arbiter's winner was `EncounterDirector`. The root cause is **not determined**. The same step passed in every other run of this witness. The confirming rerun passed. See `shrine-stall-run-witness.json` and `shrine-stall-run-fail.txt`.

## Complementary: closed gate seal

- `closed-gate-seal/run.txt` ran on a working tree whose product and test code match 269cc025c05ce15216386995b99bce6bae33627e. The witness helpers changed afterwards, but `smoke_cloudreach_closed_gate_seal.gd` does not use them. It is from `godot --headless --path . --script tests/smoke_cloudreach_closed_gate_seal.gd` on the same code: `CLOUDREACH CLOSED GATE SEAL OK checks=195 failures=0`.
- It includes leg (b), where the loaner flight is sealed and no sixth slot appears, and legs (i) and (j), the Fly anchor recovery cases.
- It also includes leg (a), the owned-carrier flight, which the aerie witnesses do not cover: the fixture party has no Fly creature, so every witness flight is carried by the loaner.
- `fly-traversal-unit/run.txt` is `godot --headless --path . --script tests/run_tests.gd -- --only=test_fly_traversal.gd` on 7e45bd2d: 10 tests, 83 assertions, 0 failed. It covers the trapped-flyer carry-out, the airborne save/load anchor and the invalid airborne anchor.

## Declared fixture: `--start=aerie` and `--leg=flight` (see `tests/helpers/cloudreach_witness_route.gd`)

- **Start.** Act I flags are seeded as the Cloudreach scene enters the tree, and the trainer is placed once beside the aerie repair. The first 21 route steps (arrival, lower anchors, Senn, causeway, Maela's battle) are skipped. The party stays at the fixture's level 25, and 3 Gale Fiber are granted (logged as a fixture grant). Every step from the aerie camp rest onward is the unchanged base route, driven by ordinary input.
- **End.** The run stops after the chapter's last flight, the return glide onto the aerie deck. The grounded counterweight, Voss and Veyra remainder is not run.
- **Not claimed.** This is not the earned-route start; that is F06#0.

## Blocked criteria

- **F06#1**, the full foot route, needs the whole chapter.
- **F08#0**, Veyra plus relays under live combat, needs the grounded remainder.

Three product stalls in the unchanged base route block both. They are owned by the main Cloudreach lane (#294 comments). Full-route evidence from the earlier runs is in `blocker-lower-west/`.

| Blocker | Location | Colliding object |
|---|---|---|
| B1 | (-128.4, 205.5, 704.5), arrival to the lower-west anchor | `LowerOverlookLoopCliffShoulders/.../VegetatedGeologicalShelf2`, an overhanging shelf |
| B2 | (223.6, 556.5, 3331.9), aerie to the counterweight | `ravine_wind_0`, a vertical collision wall |
| B3 | (500.5, 986.4, 4890.0), the Voss summit approach | `roost_perches_0`, an overhanging collision |
