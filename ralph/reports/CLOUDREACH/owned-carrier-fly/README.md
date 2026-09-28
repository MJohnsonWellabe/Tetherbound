# Owned-carrier Fly (Cloudreach debt, closed)

Before this change every proof flight used Maela's loaner: the earned five hold no Fly species, and the Galewisp starter had no carry capability. That broke CREATURES §7's promise that the starter gains Fly at the unlock.

## The rule (WORLD §4.2; CREATURES §7, §204; SYSTEMS Fly; MULTIPLAYER)

- **The five's own carrier.** The healthy active member flies when its species can carry and its promise has opened.
  - `data/config/fly_traversal.json` `capabilities`. Galecrest carries; Galewisp carries once `fly_traversal_unlocked` is set (`requires_flag`).
  - `scripts/player/fly_controller.gd` `carrier_qualifies()` / `owned_carrier()`.
- **Maela's loaner** serves only two cases:
  - her flight trial;
  - after the unlock, a five that holds no healthy carrier, until `cloudreach_chapter_complete`.
- **Carrier in the five but not out.** A five with a healthy carrier that is not out gets no loaner. The refusal names it: "Send out Galecrest to fly." (`carrier_refusal()`).
- **Carrier unwell.** A five whose only carrier is fainted or resting keeps the loaner's safety net inside Cloudreach until the chapter ends, as before this change. A carrier that faints on a flight-only shelf therefore cannot strand the trainer. Past the chapter the refusal says "Galecrest needs to recover before it can carry you."
- **One creature, drawn once.** An owned launch puts the carrier's ground follower away through the production recall, so co-op viewers lose its body too, and touchdown sends it back out. `party_cycle` and `creature_recall` are refused mid-air ("Land before changing or recalling your companion."), because a swap would drop the trainer. A loaner flight keeps carrying to touchdown if the unlock commits mid-flight, for example a co-op peer's trial.
- **Party, save and network.** No party write, no sixth creature, and no save or network format change.
  - Remotes already build the carrier art from `net_fly_species`.
  - The host still decides where the flyer may land.
  - A reload resumes in recovery at the safe anchor, as before.

## Evidence

| Check | Result |
|---|---|
| `earned-run/`: `tests/smoke_cloudreach_fly_training_witness.gd -- --from-save=res://tests/fixtures/earned_saves/c1_arrival --leg=flight --live-combat --accelerated --owned-carrier=galecrest` at 86271273 | F06#2 WITNESS PASS; CONTINUOUS LEG PASS, 9,630 m. The trial flew on the loaner (`loaner: true`, carrier in the five but not out). The first launch after the unlock was refused with "Send out Galecrest to fly." and Fly did not deploy. After 4 real `party_cycle` presses the Galecrest was out, and one real `creature_recall` press brought its follower out beside the trainer. The owned Galecrest then flew the other 4 launches (`loaner: false`, `owned_carrier: true`, party 5). Its follower was out before every launch and put away during every flight (`owned_flights`). A real `party_cycle` press mid-air was refused; the carrier and the flight carried on (`owned_mid_air_cycle`). The disk save/reload kept every member field and every flag. Two earlier passing runs of the same leg (before the re-check fixes) are not kept. |
| `tests/test_fly_traversal.gd` + `test_cloudreach_fly_loaner_end.gd` | 18 tests, 152 assertions, 0 failed. Adds: the Galewisp starter gains Fly at the unlock without a sixth slot; an owned carrier that is not out gets no loaner and the refusal names it; a healthy carrier on the bench is named before a fainted one; an unwell carrier keeps the loaner in Cloudreach and is told to recover past it; a carrier-less five keeps the loaner until the chapter ends; Galewisp carrier art builds with grip bones and flapping wings. |
| `tests/smoke_fly_traversal.gd` | FLY CORE: 30 assertions, 0 failures |
| Owned Galecrest on the production scene: `tests/smoke_cloudreach_closed_gate_seal.gd`, `smoke_cloudreach_physical_runtime.gd`, `smoke_environment_velocity.gd` | CLOSED GATE SEAL OK checks=195 failures=0; ENVIRONMENT VELOCITY PASS; CLOUDREACH PHYSICAL 36 assertions, 0 failures. The physical smoke's reload check also failed on main, for an unrelated reason: a flat flag store behind both halves of `Game.progression` was loaded twice. That is fixed in `autoload/merged_progression.gd` at dacc047d. |
| Unit suite at dacc047d (4 shards) | 5,224 tests, 0 failed |
| `net-fly/`: `tools/net/run_net_smoke.sh fly` | ALL CHECKS PASSED (2 peers) at 86271273. An earlier attempt ran beside the accelerated witness: the peers' world boot took about 3m09s and missed the 180 s hello budget. Every run on a quiet machine has passed. |

`events.json` is the full event log of the counted run; `run.txt` holds its verdict lines.

## Disclosures (relaxed-proof ruling 1)

- **Party write.** After the earned save loads through the title Load list, `--owned-carrier=galecrest` replaces one member of the five with a freshly spawned level-21 Galecrest. The member it replaces is not out and is not a starter; here it is one of the two Mudsnouts, also level 21. The party stays five, and nothing else is written. Galecrest is catchable wild in Meadows band 1, so this five is a legal one. The earned c1_arrival five is a Ripplet-starter five, so it cannot hold a Galewisp; the Galewisp path is covered by the unit tests above.
- **Switching.** Every switch uses the real exploration `party_cycle` press. The live-combat pilot's own mid-fight switching had left the Galecrest out, so before the trial the witness sends another member out. This shows the loaner serving the trial.
- **Clock and fights.** The clock is accelerated and fights use the live-combat pilot, as in the earlier F06#2 earned runs (`../b/f06-2-fly-training/earned/`).
