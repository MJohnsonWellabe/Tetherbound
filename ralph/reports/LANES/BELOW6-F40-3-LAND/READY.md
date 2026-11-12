STATUS: land
BRANCH: tb/below6-f40-3-land (cut from origin/main 3b7d04b5, after #918; READY is in the same commit)

# F40#3 Cloudreach landmark read: dome crowns and two approach stands, ON (LANE-BELOW6, 12 Nov 2026)

The crowns are LANE-MESHY's build (`landmark_crowns_1111`), carried over and judged here.

## Verdict
`ralph/reports/GPU-PASS/1108/G-below6-f40-3-landmarks.md` on `tb/item-scout-1108` cb3ff531d (GPU High, three code-blind judges):
- Row: base 6.00, arm 6.33 (+0.33; judges a and c prefer the arm, b prefers base by 0.1). Re-baselined from the board's 5.65; the row is above 6 on the new stands.
- 3/3: the beacon's dome is "a clear step toward the Sky Aviary board"; the armillary ring adds identity.
- The gain is under 0.5; this lands on the coordinator's ship call and stand ruling ("neither old stand showed its subject"). High only.

## What lands
- `data/config/cloudreach_visual.json landmark_crowns_1111`: ON with `_why_on`; `scripts/world/cloudreach_landmark_crowns.gd` and its two hooks (`cloudreach_old_wind_observatory_presentation.gd`, `cloudreach_windscar_beacon_site.gd`). Presentation only, no collider.
- `data/config/capture_stands.json approach_overrides.candidates_1112`: ON with `_why_on`. Observatory looks from the south (search from (430, 4500), heading 180); beacon from 32 m (search from (-240, 2698), heading 47). These are F40#3's fixed approach stands from now on.
- `tools/phase2_capture_locations.gd`: `approach_override_for` also reads the candidate block when it is on (4 lines).
- Tests: `tests/test_cloudreach_landmark_crowns.gd` (new on main; adds a ships-ON test), `tests/test_capture_approach_overrides.gd` (the candidates-OFF test becomes ships-ON with both stands pinned, and still checks that an OFF block moves nothing).

## Tests
Run in the lane checkout (main 3b7d04b5 merged) with these files copied over: `--only=capture_approach_overrides,cloudreach_landmark_crowns,cloudreach_old_wind_observatory_presentation,cloudreach_windscar_beacon_site,cloudreach_friendly_palette,cloudreach_production_integration,cloudreach_counterweight_seal,realm_shell_transition_guard,capture_stand`: 10 test files, 41 tests, 614 assertions, 0 failed. That set includes every older test that names the observatory or the beacon. No full suite. No texture or other new asset.

## Still named by the judges (3/3)
- The Skyroad Arch frame shows "an empty field between two blocky stacked-slab cliff faces". Screened on CPU (`BELOW6-F40-3/_sheet_cpu_arch_screen.jpg` on `tb/below6`): today's stand already shows the two piers and the lower curve; three stands further back have no ground to seat on. The arch's crown is above the frame, so this needs art, not a stand.
- The observatory path is a stretched, blurry strip; its plateau reads as a hard-rimmed cylinder; the tower top is cut off.
- Uniform grass carpet and regular slab pillars.
