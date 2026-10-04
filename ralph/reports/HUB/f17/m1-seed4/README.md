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

The hammer stage has not been reached on this branch yet, so the reproof's hammer failure is unconfirmed either way.
A direct probe (hammer on quick slot 4, one d-pad tap in the live world) equips correctly. The reproof failure therefore
depends on the state at the camp stage.

Local runs on this 4-core container are not valid for this harness while a software-GL capture is running: two local
attempts hit "cooperative callback deadline" and "native query count/lifetime/cooperative deadline cap" refusals.

Key log lines per run: `r*-key-lines.txt`.
