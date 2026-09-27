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
- **Suspected game cause, not yet confirmed:** the rested companion's body, or the bed itself, blocks the only path from the bed to the bay arch inside the small workshop. That would trap a real player.
- **Left open** under the two-strike rule. The next step is a rendered look at the bay after a rest.
