# CREATURES-RALPH r4: Tuskroot remake ON, which takes Ashtusk live (CPU, three blind judges)

Same harness as r1. The A arm is the installed models (`remake_owner1101_tuskroot` OFF, as on main). The B arm is the remake with this lane's fixes:
- Ashtusk remake recipe and rigid tusks (r1);
- Tuskroot GLB weights relaxed, worst clip stretch 0.92 m → 0.22 m.

Anchors were craft, f36_0_npc:C8 and f36_0_gap:C7 (seed 110204). Fit: slope 1.60, intercept −3.52, r 0.85, RMSE 0.45. There were no warnings.

| Creature | Mapped installed → remake | Target | Verdict |
|---|---|---|---|
| **Ashtusk** | 5.36 → **7.27** | ≥ 6.60 (old 7.40 GPU − 0.8) | **KEEP**, CPU-provisional; all three recorded defects FIXED ×3 |
| **Tuskroot** | 6.85 → **7.06** | ≥ installed | **KEEP**, CPU-provisional |

On the installed Ashtusk this CPU stage still shows the "gravel-noise / mottled collage" defect. The remake loses it.

## What the judges still see

- **Ashtusk remake:** it is a dark body on the flat stage, the eyes do not read, and the ember lines show mostly in the faint frames.
- **Tuskroot remake:** it is dark on dark with no visible element trait.

## Change

`remake_owner1101_tuskroot` is ON and removed from `HELD` in `tests/test_creature_model_flags.gd`. Its held reason was that Ashtusk's aspect textures were painted for the old model. They are now painted for the remake UVs.

The gameplay smokes (`smoke_arena_contain`, `test_creature_rest_pose`, `test_dual_type`) are **not run here**: they need a full world import that does not fit this container's disk. CI decides.
