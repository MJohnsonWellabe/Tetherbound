# LAND-MT-SHOREZONES round 2: far-dune turf only

**GPU eye check of round 1 (GPU lane, G-land-mt-shorezones on tb/gpu-frames-1113, warned in its manifest).**
- The far dunes get the intended mottled sage patches.
- But hard, triangular olive facets lie on the **near** sand in front of the trainer in terraces, horizon_stones and sluice_bridge route_day. These did not show on CPU.

**Likely cause.** The turf mask is gated by a tight threshold on the terrain normal (`zone_gentle`, `abs(normal.y)` 0.55 to 0.85). Where the GPU's terrain normals are faceted, a threshold that tight steps per triangle.

**Round 2 change (overlay only; the new uniforms default to round 1's maths).**
- `zone_slope_free` 1: the normal gate is dropped; patches depend on height and noise only.
- `zone_edge` 0.3: a softer patch border (was 0.12).
- `zone_near_fade_m` 45: turf fades out toward the camera, so the near sand stays sand. Round 1's judged-positive part was the far dunes.

**By-eye line for the GPU lane.** Near sand in front of the trainer: no olive facets; far dunes: the sage mottling is still there. If facets remain near the camera, hold.

**Not looked at on CPU.** The CPU never showed the facets, so a CPU look cannot confirm the fix.

---

Round 1 notes follow.

# LAND-MT-SHOREZONES: Tidewake dunes with backdune turf patches

**Rows.** F39#1 shore landforms 6.14; F39#15 Veilfall approach shallows 6.14 (shares two frames); F39#27 6.16 ("bare flat dunes now"); F39#2 6.79 and F39#30 6.70 as no-loss (same islands in frame).

**Defect (G-rescore-stale-ext-tidewake, 3/3).** The shore is "bare smooth sand with no layered ecology"; F39#1's recorded defect asks for "layered shore ecology and clear grass-to-sand transitions".

**Cause, and how I know.**
- Every island is one pale sand from the waterline to the crest. The only zone in the sand shader is the damp band at 0 to 1.4 m.
- False-colour probe (damp band painted magenta, First Shore route_day): the band is a one-pixel line at the waterline. Two earlier probes were invalid (the edit did not match the file); this one was checked headless before the capture.
- Height probe (`water_heightfield.height_at` along four lines from the First Shore stand): the islands rise to 18 to 29 m and the capture stands sit at about 18 m. So from where players and judges look, nothing between 1.4 m and the crest changes: that is the missing zonation.

**Change (flag-off uniforms in `coastal_rock_material.gd`; the overlay sets them through `tidewake_look.json` `dunes`).**
- `zone_*`: sage and straw turf in noise-led patches that close up with height (8 m to 22 m) on gentle ground, with metre-scale sand flecks and the sand's own ripple value kept. Never a full cover.
- `wrack_*`, `wet_wobble_m`: a broken dark strand line and a wider damp band low on the beach. Built, but **not visible from these stands on CPU**; no claim rests on them.
- Colour only: no height, control map, collision or vegetation placement change. No red. No Meshy.

**CPU before / after.** `_sheet_shorezones_off_vs_on_cpu.jpg` (left base, right arm; rows east_beach walk_03, horizon_stones route_day, terraces route_day, terraces walk_01, sluice bridge route_day, east_beach route_day). 0 script errors on both sides.

**By-eye line for the GPU lane.**
- horizon_stones route_day and terraces route_day / walk_01: the far islands' dunes carry mottled green patches from mid-slope to the crest, where base is plain cream.
- If the far dunes are still plain cream, the overlay did not apply: hold.

**Honest read and risks.**
- This is a moderate change, not an outright fix: it adds one vegetation zone. Driftwood, rock clusters and grass groves (also asked for) are not in it.
- Near the camera the patches are soft green stains on sand (horizon_stones route_day, lower right; terraces route_day, mid). If judges read them as blotches, lower `zone_strength` or raise `zone_start_m`.
- Two earlier CPU tries blanketed the islands in a flat lawn; the patch rule and the 8 m start are the fix for that.
- The owner's dune direction is pale Great Lakes sand with sparse sage grass. The turf stays sage and straw and patchy to respect it.
