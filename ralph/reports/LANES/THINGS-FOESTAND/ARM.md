# THINGS-FOESTAND: the opposing trainer stands behind their own creature (F38#3, and every trainer fight)

**Row.** F38#3 fight camera: High 7.17, Medium 7.35 (`G-closeout-meadows-ui.md`, d3be8b49). 3/3: "the Tether grunt is half hidden behind Terrapup's legs in frames 1 and 2". Same cause group as T-FIGHTSTAGE (F39#7, F39#19, F39#20, F39#22, F41#3: actors overlap).

**Cause.** A challenged trainer never moves: they stay at the post they were spoken to at. The player stands next to them to talk, so when the fight forms the opposing trainer ends up beside or under the player's own creature, next to the player's trainer.

**Change** (flag `combat.json arena.opponent_trainer_stand_1112`, OFF). At placement the opposing trainer is stood 3 m behind their own creature along the fight's heading and 1.6 m to the side nearer the lens, re-grounded, facing the fight; they return to the post when the round ends. Skipped if the spot is off the arena, has no ground or steps more than 1.5 m. Client presentation only: nothing saved or replicated; post, dialogue and rewards untouched.

**CPU** (`_sheet_stand_off_vs_on_cpu.jpg`; left main, right arm; Meadows south bridge grunt, two moments): the grunt is out from under Terrapup and stands behind Mudsnout, visible over its back. The player's trainer keeps their place. No script errors.

**Risks to check.** Multi-creature trainer fights (the trainer returns to the post between rounds, then steps out again); posts on decks or bridges (the height guard should skip them); the aftermath shot expects the trainer near the post (they are restored before it).

**Not in this arm.** The wooden post props at bottom right and the dotted dust loops.

**Tests.** `tests/test_opponent_trainer_stand_1112.gd` (2).

**Ask.** F38#3 job.json frames, base vs arm, High; plus one Tidewake and one Stormwood trainer fight as no-loss checks.
