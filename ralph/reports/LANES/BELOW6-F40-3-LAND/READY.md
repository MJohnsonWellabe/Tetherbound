STATUS: land
BRANCH: tb/coord-f40-3-land (coordinator, cut from origin/main 3b7d04b5e; LANE-BELOW6's arm BELOW6-F40-3 on tb/below6 0623dcbfe)

# F40#3: Cloudreach landmarks seen from where they read, with their aviary-family crowns, ON

## Verdict
`ralph/reports/GPU-PASS/1108/G-below6-f40-3-landmarks.md` on `tb/item-scout-1108` cb3ff531d (GPU High, three code-blind judges, confirming batch): F40#3 6.00 -> 6.33 (+0.33, 2/3 prefer the arm). The beacon's "blue-and-gold glass dome over stone columns, with banners" reads as "a clear step toward the Sky Aviary board's language" (3/3). Re-baselined on the new stands.

## What lands
- `data/config/cloudreach_visual.json landmark_crowns_1111` ON with `_why_on` (LANE-MESHY's crowns: the aviary's gold meridian-rib dome on a slate-blue shell on the Old Wind Observatory tower and the Windscar Beacon gate; no collider).
- `scripts/world/cloudreach_landmark_crowns.gd` (new) and its hooks in `cloudreach_old_wind_observatory_presentation.gd` and `cloudreach_windscar_beacon_site.gd`.
- `data/config/capture_stands.json approach_overrides.candidates_1112` ON with `_why_on` (coordinator stand ruling: neither old stand showed its subject), read by `tools/phase2_capture_locations.gd approach_override_for`.
- Tests: `test_cloudreach_landmark_crowns.gd` (new, plus an ON pin), `test_capture_approach_overrides.gd` (candidates ON, the beacon stand moves, an OFF block still moves nothing).
- Not included: anything Stormheart (heartwood core v2, ramp body, aged split wood, banners), Fulgocobra.

## Still named on this row (3/3)
The Skyroad Arch frame shows the piers but not the arch (LANE-BELOW6 screened the stands: no ground further back; this is art); the observatory path is a stretched strip and its plateau a hard-rimmed cylinder.
