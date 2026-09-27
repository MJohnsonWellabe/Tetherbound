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
- **Suspected game cause, not yet confirmed:** the freshly rested companion lying on the bed at the player's side, inside the 6 × 8 m bay, blocks the path from the bed stance to the arch. The bed is 5.6 m from the arch, and the player stands 0.27 m up, on the bed's edge. That would trap a real player.
- **Left open** under the two-strike rule. The next step is a rendered look at the bay after a rest.
