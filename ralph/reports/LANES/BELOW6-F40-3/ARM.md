STATUS: ready for GPU (High first)
ROW: F40#3 Cloudreach landmark read (GPU High 5.65)
BRANCH: tb/below6 (code and config; no new asset, no import; the arm must run this branch's capture tool)
OVERLAY: ralph/reports/LANES/BELOW6-F40-3/overlay.json (`cloudreach_visual.json landmark_crowns_1111` on; `capture_stands.json approach_overrides.candidates_1112` on)
FRAMES: CAPTURE.json (the row's three approach frames, base and arm)

# ARM: Cloudreach landmarks seen from where they read, with their crowns (LANE-BELOW6, 12 Nov 2026)

## Why the crowns alone were not sent
`BELOW6-CROWNS/NOT-SENT.md`: with the old stands the observatory's dome is above the frame and the beacon's is a twentieth of it. Judges: the landmarks "read as plain disconnected pieces", "no aviary-family landmark: no dome, gold trim". The frames did not show the landmarks.

## The arm (all OFF by default)
1. **Two approach stands** (`capture_stands.json approach_overrides.candidates_1112`, the mechanism that landed for the Stormheart):
   - Old Wind Observatory: looks from the south (stand search from the tower at (430, 4500), heading 180). Old stand: 8 m from the tower on the island rim, framing a bare rim wall with the tower cut at the knees and the trainer in front of the wall.
   - Windscar Beacon: 32 m from the gate (search from (-240, 2698), heading 47). Old stand: 16 m behind the landmark position, the gate about 60 m further on.
2. **The crowns** (`landmark_crowns_1111`, LANE-MESHY's, tested, never judged): the aviary's gold-ribbed dome on the beacon gate and the observatory tower.
The Broken Skyroad Arch frame is unchanged.

## CPU check (`_sheet_cpu_base_vs_arm.jpg`: old stands above, new stands with crowns below; observatory left, beacon right. `_sheet_cpu_screen.jpg`: the other candidates screened)
- **Beacon:** the gate with its blue and gold dome, banners and the beacon tower behind fill the centre of the frame between two rock stacks. This is the clear gain.
- **Observatory:** the tower stands at the end of its dirt path with the armillary ring beside it and open sky around; no rim wall. **The tower top and its dome are still cut off** (true of all five candidates: the gameplay camera cannot take in a 20 m tower from this island). So the dome is judged on the beacon only.
- No CPU judge batch was run.

## Stand rule
A stand may move when the old one does not show its subject. That is plainly true of the observatory (a rim wall). For the beacon it is a judgement: the old frame does contain the gate, small and far. If the coordinator or LANE-SCOUT rule the beacon stand out, the arm still stands as observatory stand + crowns, and the beacon's crown can be judged on its old stand.

## Expected
More than 0.5 on the row: two of its three frames change from "empty lawn with a distant or cropped landmark" to a landmark in the middle of the frame, one of them with the aviary-family dome the judges asked for.

## Checks
`--only=capture_approach_overrides,cloudreach_landmark_crowns`: 5 tests, 25 assertions, 0 failed. The candidate block is OFF and pinned OFF by the test; the landed Stormheart overrides are untouched.
