# b45: Stormtrail value separation vs main (CPU, three judges)

Candidate: fac6e385 (CLOSE-OUT per-species texture work). Stormtrail's coat value range widened so the body separates from the slate stage, with a brighter spine bolt and glows. Base is main's Stormtrail on the same stage (`capture_f36_poses.gd --whole-body --context`: standing, hit react, faint mid, faint end). Sheet `_sheet_b45.jpg`: base | candidate.

Anchors: craft before/after, f36_0_gap:C1, f36_0_npc:C3. Fit: slope 1.51, r 0.90, RMSE 0.43, confirming.

| side | mapped (j1, j2, j3) | mapped mean | body value merges with the stage |
|---|---|---|---|
| main Stormtrail | 6.02, 6.32, 6.62 | **6.32** | PARTIAL on both sides |
| value candidate | 6.17, 6.02, 6.47 | 6.22 | PARTIAL on both sides |

Call: tie (-0.10). Reverted (e5495230). The wider value range did not lift the body off the stage at CPU stage scale.

Two findings for the coordinator:
- All three judges read the blue vein glow, on both sides, as stamped "glowing seams on fur". That is the exact pattern the owner ruled out (25 Oct: glow only where natural to the element, never as glowing seams on fur or hide). The next Stormtrail step is a question: remove the vein glow, or reshape it as arcs off the body like Tanglevolt's, rather than another value pass.
- The `storm_line_glow` layer in `aspect_variants.json` selects no texels for Stormtrail on main (no-op). Changing its colour and clump coverage did not make it select anything; not chased further.
