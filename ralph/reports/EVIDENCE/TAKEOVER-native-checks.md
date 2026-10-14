# Takeover native checks

## Systems P0 — partial proof, remains open

Source: `ce1812e712a1e2e35168601a0c711221737841bd`. Native tracked tree was clean; four runner/test source SHA-256 bindings matched. Godot 4.7 runtime SHA-256: `b2ca888d5115a6cedee564764a2ee494a625f2ec2edbabd010fe33c9a88a6bf8`.

At 5:40–5:41 PM CT on 13 Oct, the bounded serial run selected exactly `test_water_capture_codec.gd,test_meadows_earned_warrens_segment.gd`: **23 tests, 1,503 assertions, zero failures**. This includes signature-move opponent identity and cap-aware exact XP regression cases.

The separate `tests/smoke_warrens.gd -- --guardian-reward` process stopped during production world loading, before combat. Confirmed stop reason: available physical memory below 2 GiB. Observed minimum: 1,958,506,496 bytes. This is a resource-blocked runtime proof, not a passing guardian fight or a diagnosed gameplay failure. No unchanged retry was launched. Engine termination was verified and the single-writer lease returned idle.

Raw receipt and hashed stdout/stderr are retained locally at `D:/tetherbound/.artifacts/codex-takeover-systems/native-output-ce1812e712/run-systems-ce1812-warrens-smoke-r2-d-output/`. Total output: 7,039,506 bytes. The launch packet is at the sibling `native-ce1812e712/root-supervisor-d-output-r1/`. Evidence is not implied uploaded by this source report.

The focused step had a 180-second cap; guardian had 600 seconds. Fresh output went to D with a 1 GiB cap, C admission/stop 10.5/10 GiB, D admission/stop 21/20 GiB, and 2 GiB physical/commit guards. Tests were not weakened, skipped or deleted. Candidates and acceptance counts remain unchanged.

## Systems projection probe — startup approach parked

The opt-in `f4be08ff1b9b789cbfb04f00a38167ae39a309fe` guardian probe retained production collision/placement and all original combat/reward/reload assertions while omitting scatter rendering uploads. Independent source review passed that limited mechanics scope. The run again stopped below 2 GiB available physical memory during world loading, before combat or the projection census. Minimum: 2,021,507,072 bytes; output: 7,031,486 bytes. Receipt: `D:/tetherbound/.artifacts/codex-takeover-systems/native-output-f4be08ff1b/run-systems-f4be08-warrens-no-scatter-visuals-d-output/receipt.json`. This startup approach is parked after two resource stops. No live guardian PASS or criterion closure follows.

## Hall isolated OFF baseline — Medium and High diagnostic PASS

Source: `4ae7c09b0599d98ad5549ee7a77338a8e7777158`. The exact staged source was clean and all five packet bindings matched. Both Hall candidate flags remain OFF. One fixed `nave-forward_day_clear` camera was captured on the GTX 1060 3GB with Forward+, in separately isolated preference/save homes. The first diagnostic at 8da633 produced an image but exposed trainer falling/jump pose during setup; this source fixes the freeze after ready and holds the production idle animation at 0.2 seconds. Trainer scale, coordinates, and fixed camera are unchanged.

Corrected Medium: 25.822 seconds, minimum physical free 3,225,698,304 bytes. Corrected High: 25.938 seconds, minimum physical free 3,108,315,136 bytes. Both exited 0, saved 1280x720, emitted the expected preset/renderer/trainer/capture markers, and had empty stderr. Root inspected both images and confirmed the stationary idle pose. The receipts and raw logs/PNGs are retained in [hall-baseline-4ae7c09b05](takeover-native/hall-baseline-4ae7c09b05/).

This mounts the installed Hall prefab and authored lighting/trainer without the Meadows world builder, with disclosed ground Y = 0. It proves isolated GPU capture feasibility and setup correction only. It does not prove full-world residency, traversal, the complete camera matrix, or an 8.5 visual score. The three-judge isolated interior comparison is recorded below; the complete camera matrix and full-world visual judging remain open. Acceptance counts are unchanged.

## Hall isolated interior comparison — three-judge diagnostic, F17#6 remains open

Visual source pin: `0ed5f35e92112fbff9b399d1c6f56f5eabde96db`; blind-judgment report commit: `7686dd45f673b726978be878aeea0e2cba77c7dd`. Three independent code-blind judges scored the same 26 matched interior pairs (13 cameras × Medium/High) from sheet SHA-256 `99d1e20269ecf96aa188ccdda081dadcfc9a20e28531d7510d6e01be93213e35`. After verdicts, the mapping was disclosed: A = furnishing; B = baseline. I independently recomputed each arm/bar mean and spread from all three raw verdict JSONs; the recomputed values match the aggregate JSON.

| Arm | Bar A judge means | Bar A mean / spread | Bar B judge means | Bar B mean / spread |
|---|---|---|---|---|
| Baseline | 3.000, 3.231, 2.915 | 3.049 / 0.315 | 2.462, 2.588, 2.323 | 2.458 / 0.265 |
| Furnishing | 3.554, 4.054, 3.577 | 3.728 / 0.500 | 2.800, 3.192, 2.723 | 2.905 / 0.469 |

Furnishing changed the mean by +0.679 on Bar A and +0.447 on Bar B. This is an isolated-interior diagnostic only: assumed ground Y=0, no exterior approach, traversal, terrain integration, follower/collision, or full-world proof. Neither arm reached 8.5; all judges answered no for both reference-fit questions. No candidate flag was activated and F17#6 remains open. This is not full acceptance or a criterion closure.

Capture provenance was checked against the pinned source, manifest, receipts, private image-hash provenance and the actual contact-sheet hash. The original wrapper receipt remains `FAILED` because of its postprocessing error; the predecessor recovery record independently validates its natural engine exit and three recovered PNGs. The continuation receipt is `EXITED_ZERO_AWAITING_REVIEW` and its hash-check records 15 steps and 49 validated images. Together the 52 PNG hashes match the private provenance; raw PNGs remain retained on D: and were not copied into this coordinator evidence folder. Small receipts, manifests, verdicts, aggregate and recovery checks are copied under [hall-interior-hall-i-0ed5f35e92](takeover-native/hall-interior-hall-i-0ed5f35e92/).
## Systems simulation harvest follow-up — focused fixture rejected, no runtime PASS

Source pin: Systems commit `56958a16488b90f4a70bda641eedfc4866e20b4d`. The bounded first step ran six tests with 41 assertions and zero framework assertion failures, then exited 0. The wrapper correctly recorded the step and job as `FAILED` because Godot emitted engine `ERROR` diagnostics. Receipt/log hashes were independently checked against the raw files before copying; unchanged copies are retained in [systems-fixture-56958](takeover-native/systems-fixture-56958/).

The stderr contains two distinct diagnostic classes. `test_portal_arrival_travel_reset.gd::test_an_accepted_guest_arrival_confirms_the_travel_reset_at_its_body` produces two Godot `get_global_transform` errors from `_confirm_travel_reset` when reading `actor.global_position` at `foundation_portal_arrival.gd:280-281`; the source fixture declares `RUNS_IN_INITIALIZED_TREE`, but the actor is not inside the tree at the read. Its assertions passed, but these are not an intentional diagnostic and need fixture/API follow-up before an accepted clean run. The research-conflict test deliberately creates a disclosed owner XP conflict and drives the watchdog; its training-stall warning and `push_error` diagnostics are expected side effects of that path, despite passing assertions. The current wrapper treats any such `ERROR` output as a rejected step, so this evidence remains FAILED either way.

Receipt records only the `home-key-and-research` step, with exit code 0 and failure reason “emitted script/engine errors.” The remaining two planned steps have no execution evidence and remain UNRUN. No full runtime proof or visual/gameplay acceptance is claimed. Raw receipt SHA-256: `75dc6ee8fb4f87e0ec572d3fa3bac668f5096e6643ad96ce8efaa3b5afec63f7`; stdout SHA-256: `9c1cca9a547eccb4b5459d332d08fdf4371df947917eacbee32f42211275e1b0`; stderr SHA-256: `46f626792bad57bb0ac30f475f6acd79f767d149a17926535e24142fcc219059`.
## Systems volunteer native failure — 13 Oct 2026, 8:57 PM CT

Pinned source `5dbb4946f57c82c1e408c3b711d8c662286b1396` passed exact staged-file preflight. Volunteer group exited 0 and printed 14 tests/244 assertions/0 failures, but is FAILED: `water_capture_transaction.gd:30` cannot infer the type of `accepting_guardian`, cascading into compile and missing-settle errors. Supervisor rejected the misleading framework totals; independent review verified both raw log hashes. Participant/feast, harvest and scatter/regional groups were not started. Systems owns the explicit-type repair; no unchanged retry or criterion closure. Raw proof: [systems-volunteer-5dbb](takeover-native/systems-volunteer-5dbb/).

## Systems corrected focused checks — 13 Oct 2026, 9:08 PM CT

Exact source `8ea96a13524a8a2785e183c142501cf4e953c1f8`: volunteer14/350, participant-feast3/175, harvest15/105 and scatter-regional10/259 all verified, total42tests889assertions0failures. Raw hashes and diagnostics reviewed. Participant group exited0 with empty stderr; original r1 wrapper remains FAILED because it expected3 selected files instead of2. Independent review recovers only completed17tests; r2 ran remaining25 and exited cleanly. Prior HomeKey/research6tests42assertions reused with exact predecessor hashes. Focused mechanics checks only: live guardian, ENet, full-world residency and route acceptance remain open. Homecoming guard is outside this batch. Proof: [systems-focused-8ea](takeover-native/systems-focused-8ea/).

## Warrens guardian witness — 13 Oct 2026, 9:14 PM CT

Source8ea96a1352, bounded mechanics fixture omitting decorative scatter render upload, completed in about357s with exit1. Both required nonempty placement/collision censuses were emitted, including reload; combat/reward/save path reached its final report. Sole FAIL is exact XP: all retained5 remain at6730 before/after, enemyL14 bonus140. This does not close P0; Systems is diagnosing cap/fixture versus reward semantics. No script errors; one physics-interpolation deprecation warning. Physical minimum3,409,195,008B and commit headroom minimum2,307,702,784B remained above2GiB; no resource stop. Original logs/receipt hashes independently verified and preserved in [raw-evidence.json](takeover-native/systems-guardian-8ea/raw-evidence.json); fields preserve raw text plus BOM metadata. Full-world visuals/performance and earned route proof are outside this fixture.
