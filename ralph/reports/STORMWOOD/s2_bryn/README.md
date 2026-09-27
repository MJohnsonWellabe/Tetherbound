# S2: Glass for Bryn from the earned prefix (`--through-bryn`)

```
godot --headless --path . --script tests/smoke_stormwood_continuous.gd -- --through-bryn
```

**The chain completes in both runs.** Both runs go through the same steps:
- the earned prefix;
- Bryn's brief, heard in a conversation;
- Stormglass and Conductor Vine gathered;
- a walk back along the west loop;
- **DELIVERED 3 Stormglass and 2 Conductor Vine through the host transaction**;
- **INSPECTED the repaired supplies; the chain is complete**;
- **RESTED a party member in the shelter's creature bed through its live panel**.

**Both runs then fail at the same next step,** so the run's EXIT is 1. After the rest, the stick walk "out through the workshop arch" makes **zero progress**: 5.1 m (run 1) and 7.4 m (run 2) remain. The player stands at y 47.42 on a 47.15 m floor at the bed, about (-720, 2310), inside the `rodline_workshop` (6 × 8 m, `Wall_Arch` bay). Bryn's closing acknowledgement is therefore not reached in this witness.
- **Run 2** added a harness wait until the bed panel is closed and input has returned to the world. It made no difference, so the stall is not the panel.
- **Stall mechanism:** the failure is raised from inside `stick_navigator.step` (its no-progress give-up; backtrace in `run2.txt`). Locomotion was enabled; the body was physically blocked.
- **Cause not yet found.** The first suspect was the rested companion. It is ruled out: the cosmetic rest body that `creature_bed.gd` spawns has `collision_layer = 0` (line 537), and the bed has no static body. What blocks the stick path from the bed stance, about (-720.9, 2310.3), to the bay arch is still unknown; the player stands 0.27 m above the terrain there. Next step: a rendered look inside the bay after a rest.
- **Left open** under the two-strike rule. The next step is a rendered look at the bay after a rest.
