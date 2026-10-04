# F17#4 M1 opening chain, seed 4 — re-proof series (tb/f17)

Command (render.yml headless, as in tb/reproof-earned F17-4.md):
`tests/smoke_four_biome_continuous.gd -- --legacy-order-diagnostic --through-tournament --world-seed=4`

Reproof baseline (826d273c3): reached the `camp` stage, then FAILED "hammer hotbar input did not equip the earned tool".

| Run | Commit | Result | Root cause → fix |
|---|---|---|---|
| r2 (37222128574) | 2efea672 (main merged) | FAIL at village, earned team: "selected wild needs a physical village crossing but no current open gate route" | The F17 east street and the practice meadow are both inside the fence but separated by the outside notch at RoadGate. Added `interior_path` detour + unit test (d7a08c6c). |
| r3 (37224169807) | d7a08c6c | FAIL: "actual village gate closed during the selected wild's approach" | The gate-free detour has an empty gate id, which was treated as a closed gate. Fixed (e95d6dff). |
| r4 (37225901166) | e95d6dff | FAIL: "Native opening refused: actual production walk lost grounded floor" at (28.03, 1.06, −11.11), the same spot as reproof F02#3 | The production-steered walk stepped onto the village_twins_yard woodpile box (exactly STEP_HEIGHT, 0.35 m) and left the floor stepping off it. |
| r5 (37228980147) | 5d093a77 | same refusal, same spot | The low-prop steering rule had an upper bound of step + ε, which excluded the 0.35 m box edge. |
| r6 (37231047443) | 059b3569 | **past the woodpile**; FAIL at 916 s in earned-team training: "Ordinary wild training did not win" (4th loss; `MAX_TRAINING_LOSSES` = 3) | Combat outcome or pilot behaviour, not village/Hall geometry. The reproof baseline finished team prep with exactly 3 losses (the cap) on 826d273c3. main's F21 combat-impact changes have landed since. Not changed here: raising the cap would weaken the test. |

| **r7 (37232841924)** | **d6f855d4** | **PASS**: exit 0 after 1245 s; `reached: tournament_won`, `requested_prefix_passed: true`, `failures: []` | Starter chosen and named; practice catch and earned team (`team_ready`, 5 creatures, 0 catch retries); materials; **camp passed** (paid tent/fire/bedroll and creature beds; the hammer equipped through the hotbar); **rest passed** (bed assignments); tournament quarter (Mira), semi (Tam) and final (Oskar) all won through real opponent defeats. |

**F17#4: PASS on r7 (seed 4, d6f855d4).** Variance disclosure: r6 on near-identical code (059b3569, which lacks only the
tread exclusion and the visit-Door guard) failed on a fourth training loss. The earned-runs session attributes that to
attrition: the team runs out of potions and enters training fights at 1–25 % HP. It is adding a rest-when-low step to the
shared earned-team segment. Re-run F17#4 once that merges, to show the pass is not a lucky draw. As in the reproof, the
harness flag `counts_as_proof:false` marks the `--legacy-order-diagnostic` prefix, not a full campaign. The hammer
failure reported by the reproof did not reproduce: the camp stage equipped the hammer through its hotbar slot.

Logs: `r7-run.log.gz` (OPENING_PRODUCTION diagnostics stripped), `r7-key-lines.txt`.
A direct probe (hammer on quick slot 4, one d-pad tap in the live world) equips correctly. The reproof failure therefore
depends on the state at the camp stage.

Local runs on this 4-core container are not valid for this harness while a software-GL capture is running: two local
attempts hit "cooperative callback deadline" and "native query count/lifetime/cooperative deadline cap" refusals.

Key log lines per run: `r*-key-lines.txt`.
