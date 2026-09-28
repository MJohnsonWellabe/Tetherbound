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
- **Not a game defect: the walk does not reproduce at normal speed** (`probe_bay_exit.txt`).
  - **Probe:** a headless scratch probe (not committed) built on `smoke_stormwood_pocket_walks.gd`, starting from the earned `1_prefix` checkpoint, with the chain's four flags set only for the diagnosis. The completed shelter builds for real: the care point, the solid creature-bed pad (a 3.3 × 0.29 × 3.0 m box), the workshop props and the crates.
  - **Result:** the player stands at the same bed stance, (-720.7, 47.42, 2310.2), on the pad. Rays to the arch at 0.3, 1.0 and 1.6 m are clear, and the ordinary stick-navigator walk reaches the arch (`ok=true`, within 1.14 m).
  - **Harness difference:** the continuous smoke walks at `Engine.time_scale` 8 and 480 Hz right after the bed-rest panel.
  - **Status:** harness-reason, second strike, so it is disclosed and not chased further. Bryn's closing acknowledgement stays unwitnessed in this run.
  - The rested companion is ruled out as well: its cosmetic body has `collision_layer = 0` (`creature_bed.gd` line 537).
- **Left open** under the two-strike rule. The next step is a rendered look at the bay after a rest.
