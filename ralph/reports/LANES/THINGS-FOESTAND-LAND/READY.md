STATUS: land

# THINGS-FOESTAND landing (the opposing trainer stands behind their own creature)

Branch `tb/things-foestand-land`, cut from main f5263ebc.

Verdict: `ralph/reports/GPU-PASS/1108/G-things-foestand.md` on tb/item-scout-1108 8598c54d (GPU High, confirming batch).

| Set | Before | After | Judges |
|---|---|---|---|
| F38#3 Meadows fight camera | 7.48 | 7.61 | 2/3; at the bar on High, needs a Medium arm capture |
| Warden Aldis fight | 6.80 | 7.18 | 3/3 (no longer under the HUD) |
| F39#7 Tidewake | | +0.09 | |
| F41#3 Stormwood | | level | |
| F39#19 | | -0.04 on identical frames | noise |

Change: `combat.json arena.opponent_trainer_stand_1112` ON; `scripts/combat/combat_manager.gd` stands a challenged trainer 3 m behind their own creature (1.6 m to the side nearer the lens), re-grounded and facing the fight, for the round, and returns them to their post when it ends. Skipped when the spot is off the arena, has no ground, or steps more than 1.5 m. Client presentation only; nothing saved or replicated.

Tests: `tests/test_opponent_trainer_stand_1112.gd` (2, flag pinned ON). Ran with the tests that touch the trainer aside, the admission trainer and fight placement (aftermath focus, flee buffer, realm-owned begin, send-out hold, director join snapshot, route strip boxes, Tidewake trainer aside): 27 tests, 0 failed. **Not run:** the combat smoke scenes (too long for a CPU turn). Because this moves an NPC node during fights, I recommend `full-ci` on the PR.

Known limits: in a multi-creature fight the trainer returns to the post between rounds and steps out again; a Tidewake trainer (Venn) is fully hidden by her Cannonback at some camera angles (GPU pre-check); the Meadows grunt is still half hidden by Mudsnout's head (3/3).
