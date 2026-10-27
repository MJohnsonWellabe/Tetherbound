# b47: Stormtrail lightning bolts + value separation vs main (CPU, three judges)

Candidate: 2ee02bfa (coordinator ruling (b), 26 Oct).
- The storm_veins glow, which lit the darkest fur seams, is removed.
- Two forked, tapering bolts per flank replace it. They are drawn on the body in model space (`generate_aspect_variant_textures.py` `build_bolts`, scored by 3D distance so they cross UV seams unbroken), with a pale core in the albedo and lit in the emissive.
- The coat values spread as in b45.

Stage: `capture_f36_poses.gd --whole-body --context`; tiles are standing, hit-050, faint-050, faint-100. Sheet `_sheet_b47.jpg`: main | candidate.

Anchors: f36_0_gap:C5, f36_0_npc:C5, p2_094_r4. Fit: slope 1.37, r 0.96, RMSE 0.32. Not a confirming batch (top anchor reference 6.93, under the confirm floor); ranking within the set holds.

| side | mapped (j1, j2, j3) | mean | glow reads as seams on fur | body value merges with stage |
|---|---|---|---|---|
| main | 6.12, 6.12, 5.84 | 6.03 | PRESENT x3 | PRESENT, PARTIAL, PRESENT |
| bolts + value | 6.67, 5.98, 6.39 | **6.35** | **PARTIAL x3** | PRESENT, PRESENT, PARTIAL |

Call: +0.32, under the 0.5 rule on score. The candidate stays, because it takes Stormtrail off an owner-rule violation: all three judges move "glowing seams on fur" from PRESENT to PARTIAL, and they describe the new marks as "thin white-blue arcs, more lightning-like". What keeps it PARTIAL: the bolts "still sit on the fur as lines, not arcing off the body" (3/3). The value spread did not register (b45, b47). The next swing is arcs that leave the body: the runtime Stormtrail VFX (`aspect_vfx.gd`, now flickering discs) drawn as jagged arcs jumping just off the spine and legs.

Anchor notes, for the anchor owners: the Mt serpent's A side floats in its faint, and the Ad wall B side reads as a billboard. These are the known anchor pairs and behave as expected.
