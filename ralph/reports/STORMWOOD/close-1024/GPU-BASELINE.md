# Stormwood F41 matrix: GPU baseline commands (for the GPU queue)

Owner, 24 Oct: GPU decides done; worst-first tiers (to 6, then 7, then 7.5). This is the Stormwood baseline the coordinator asked for: all matrix stands, Medium and High, plus the real fights. Run on main as it stands (no candidate flags), from the repo root, one Godot process at a time.

Camera set: the F10/F41 Stormwood matrix stands of `tools/capture_stormwood_f10_matrix.gd` (forest, giant, glass, rod_line, stormheart = `tools/visual_judge/camera_sets/F41-look.json`) plus three fixed custom stands used unchanged since close-1020 (reverse, heart_near, hollows). Phases Calm and Break, plus the Long Storm aftermath (Calm). 24 frames per preset. `--fixed-fps 20` so a Break still catches a lit bolt (`_await_sky_bolt`; without it a slow frame skips the 0.25 s bolt).

```
SHA=$(git rev-parse HEAD)
CUSTOM="reverse@-300,4420@-350,4,4330@-2;heart_near@-100,5330@-100,80,5470@18;hollows@-500,1550@-460,3,1640@0"
for P in Medium High; do
  godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --fixed-fps 20 \
    --script res://tools/capture_stormwood_f10_matrix.gd -- \
    --preset=$P --source-commit=$SHA --out=<dir>/sw-matrix-$P --label=sw-gpu-$P \
    --phases=calm,break "--custom=$CUSTOM"
done
```

Real fights (F41#3 "a real fight" and F10#2), same as GPU-PASS/F10-2 with the two named fights this lane judged on CPU:

```
godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1280x720 --fixed-fps 20 \
  --script res://tools/capture_named_fights_f10_6.gd -- --out=<dir>/sw-fights-<preset> \
  --ids=glass_field_alpha,capacitor_alpha --seconds=14 --interval=2.0 --camera-view=north --fixture-seed=1042206
```

Judge sheets (as this lane's CPU rounds): per phase, the eight stands as a 4x2 grid (forest, giant, glass, rod_line / stormheart, reverse, heart_near, hollows); per fight, six moments i00, i03, i06, tell1-c-late, tell1-e-impact, tell2-d-strike as a 3x2 grid. Briefs and recorded defects: `ralph/reports/STORMWOOD/close-1024/r15/spec.json` (tb/stormwood). Anchors fixed: `--include craft --include f10_2_r3_capacitor --include f36_0_npc:C5 --include f36_0_gap:C2 --pairs 4`.

CPU reference (Compatibility/Low, llvmpipe, mapped, main as control in r15): Calm 5.33, Break 4.81, aftermath 5.30; fights glass_field 6.10, capacitor 6.17. Best CPU candidate (r14, OFF): 5.75 / 4.98 / 5.90.

Flag-off candidates ready to judge on GPU after the baseline (tb/stormwood-land dd722a9c9 and tb/stormwood):
- P2-037 Stormheart finale: `stormheart_presentation.json meshy_hero._model_v3_candidate` (copy to `model`, height 300, shape [0.8, 1, 0.8]).
- P2-043 Glass Field spike bases: `stormwood_glass_field.json shard_finish._crystal_model_candidate` (copy to `crystal_model`, `crystal_height_scale` 0.55).
- P2-039 forest ground / interior fill (r13/r14 config): `ralph/reports/STORMWOOD/close-1024/r14-candidate.patch` (tb/stormwood).
