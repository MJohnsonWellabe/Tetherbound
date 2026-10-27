# b61: Ripplet matte countershaded coat r2 vs main (CPU, three judges)

Candidate 12b62925d is r1 (b60) plus countershading.
- Each coat texel's bind-pose normal scales its value: the back x0.70, shifted 6 degrees deeper blue, and the belly x1.15.
- The normals come from `tools/creature_anatomy_maps.py`.

Tiles: standing, hit 050, faint 050, faint 100. Anchors: f36_0_gap:C5, f36_0_npc:C4, f04_6_r22. **Weak fit:** the least-squares slope was 0.48, so the map is a mean offset only (r 0.58, RMSE 0.51).

| | main | r2 | gain |
|---|---|---|---|
| Ripplet (mapped, offset) | 6.03 | 6.43 | +0.40 |

- The defect went from PRESENT x2 / PARTIAL to PARTIAL x3. All 3/3 judges prefer r2.
- Judges say the darker coat now loses the face at small size in the faint frames, and that the coat still has no rim light or water accent.

Call: **GPU READY under the close-out exception**. On GPU's 7.26, +0.40 would cross 7.5.
- This is the second round under 0.5, so the coat-grade approach parks after this GPU pass.
- A natural bioluminescent fin and frill accent is the untried idea.

Checks: `run_tests --only=colourway,shiny,ripplet,creature_body,f36_pose,aspect,starter,texture_for,smoke_creature`: 81 tests, 0 failed.
