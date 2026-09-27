# Cloudreach-B witness evidence

Lane: Cloudreach-B. Branch: `tb/cloudreach-b`. READY posts are on #356. Under the owner ruling of 2026-09-27 06:55, shortcuts are allowed if each is disclosed in the READY.

## Start state

Every counted run below starts from the earned save `tests/fixtures/earned_saves/c1_arrival/`, loaded through the title Load list with `--from-save=res://tests/fixtures/earned_saves/c1_arrival`.

- **How it was built.** The seed-4 earned chain ran from the committed `seed4_hall` checkpoint and was joined at checkpoints: `warden@village_pre_kell` → `kell_rift2@storm_road_join` → `storm2`.
- **Disclosures.** Stick detours and harness fixes B13–B16 are recorded in `PROVENANCE.json`, `receipts/c1_arrival.json` and `tools/earned_saves/BLOCKERS.md`.
- **Flight checkpoint.** `tests/fixtures/earned_saves/checkpoints/c1_flight_trained/` is an ordinary save taken right after Maela's trial unlocked Fly. It was made for X05 F06#5.

## Shortcuts common to all runs

- `--accelerated` runs at time_scale 8 and 480 Hz, so each physics step is still 1/60 s. Fights and taps run at 1x.
- Fights are driven by the `--live-combat` controller pilot. It writes camera yaw directly, as an idealised right stick.
- The title Load buttons are pressed by emitting their signal. The reload check calls `game.save_game`/`load_game` directly.
- Fly climb and descent use the production held Jump and `fly_descend` inputs, which are lawful under the owner ruling.
- The earned five have no flier, so every flight is carried by Maela's loaner.

## Evidence

| Criterion | Folder | Run | Result |
|---|---|---|---|
| F06#1 foot through all six regions | `f06-1-foot-regions/earned/` | 581fdfa7, full chapter | PASS, 15.96 km. The owned-carrier Fly path is a skipped sub-part (loaner only). |
| F06#2 Fly training, landing, invalid landing | `f06-2-fly-training/earned/` | 0883848d, `--leg=flight` | PASS. Refused trial escape, sealed Upper refusal, exhausted-fall recovery, 4 verified landings, equal reload. Threshold test: `tests/test_cloudreach_b_landing_threshold.gd`. |
| F06#3 loaner never bypasses a gate or loses a creature | `f06-3-loaner/earned-full-v2/` | 36f915d6, full chapter | PASS. 5 loaner launches, 0 violations, refused trial escape. The pre-Voss overfly got 312 m past Voss's road point airborne but never landed past it. |
| F08#0 Veyra's team and relay exam | `f08-0-veyra-exam/earned/` | 581fdfa7, full chapter | PASS, strict re-score CLOSES. |
| F08#0 re-check additions (dry run) | `f08-0-veyra-exam/earned-dryrun-recheck-assertions/` | 601eab3f | Failed-exam return, phase order, lee pocket and wind pushes all held. One assertion was misread and has been fixed since (see `run.txt`). |

## Other folders

- **Failed and superseded earned runs:** `earned-fail-*`, `earned-full`, `f06-3-loaner/earned/` (flight leg only), and `f06-3-loaner/earned-full-fail-overfly-recovery/`.
- **Legacy fixture-start verdicts:** `legacy-fixture-fail/`.
- **DRY RUNs from declared fixtures:** `aerie-start/` and `resume-dry-run/`.
- **New earned runs** write to a git-ignored `latest-run/` folder. A passing run is copied into a named `earned*/` folder with its `run.txt`.
- **Earlier investigations:**
  - `closed-gate-seal/` and `fly-traversal-unit/` (complementary suites);
  - `route-stall-root-causes/` (B1–B3 and the SkyPillar stall, fixed by the Cloudreach lane);
  - `blocker-lower-west/`;
  - `c1-arrival-verify/` (the continuous harness's `hotbar_1` knife assumption, reported on #356).

## Open follow-ups

- **Loaner end.** After chapter completion and a reload, the loaner must no longer fly. The witness for this waits on Cloudreach's loaner-end config key (#356, 06:22 item 2).
- **Voss Fly gate.** The Voss approach is held by altitude and the exhausted-fall recovery, not by a restriction (#356, question B). The trajectory is in `f06-3-loaner/earned-full-v2/events.json`, under `witness_pre_voss_overfly.trajectory_1s`.
