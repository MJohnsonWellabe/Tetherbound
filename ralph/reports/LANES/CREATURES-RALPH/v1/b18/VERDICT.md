# Visual lane v1/b18: creature rim (F38#1/#2/#26) and Nightburrow partial plates (F36#56) (4 Nov 2026, ~04:15 UTC)

**Arms:**
- **Creature rim:** `creature_rim.json` ON vs OFF, Meadows world frames, `phase2_capture_creatures.gd --biome=meadows`. Base `rim_base` and candidate `rim_cand` were captured on the same head.
- **Nightburrow partial plates:** `creature_coat_flags.json` `creatures_ralph_nightburrow_partial_plates` OFF vs ON. Stage frames from `capture_f36_poses.gd --species=nightburrow --whole-body --context`, base and candidate in one run.

CPU, Compatibility.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs, three fresh code-blind judges. `calibrate.py`: linear, slope 1.51, r 0.96, anchor RMSE 0.40, no warnings.

| Row | Item | CPU base (mapped) | Arm ON (mapped) | Decision |
|---|---|---|---|---|
| F36#56 | Nightburrow (stage) | 6.37 | **6.67 (+0.30)** | **ON** |
| F38#26 | creature ground contact | 6.06 | 6.11 (+0.05) | rim OFF (within noise) |
| F38#2 | hurt and movement poses | 5.96 | 5.96 | rim OFF (flat) |
| F38#1 | collapse and rest | 5.46 | 5.46 | rim OFF (flat) |

**Judges:**
- **Nightburrow, 2 of 3:** side B has "more muted, earthy plates that sit more naturally on the fur, closer to the Stormursa bar". The third judge scored it 6.0 vs 5.8 the other way ("duller brown, less elemental read"). The hurt frames still sit close to idle on both sides.
- **Rim, 3 of 3:** the two sides look identical at this camera. The creatures are about 15 m out in the shaded tree band. The rim (energy 0.55) does not register at that size.

**Next for F38#1 and F38#2:** the judges ask for creatures "framed closer, out of tree-trunk shade, trimmed grass around their feet", plus distinct hurt and faint silhouettes. A stronger rim (energy around 1.0) is the last cheap try. After that it needs pose new art.
