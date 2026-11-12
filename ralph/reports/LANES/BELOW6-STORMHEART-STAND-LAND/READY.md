STATUS: land
BRANCH: tb/below6-stormheart-stand-land (cut from origin/main 6eae79177; READY is in the same commit)

# F41#1 Stormheart: new approach stand, ON (LANE-BELOW6, 12 Nov 2026)

## Verdict
`ralph/reports/GPU-PASS/1108/G-below6-stormheart-approach.md` on `tb/item-scout-1108` d3f616f1c (GPU High, three code-blind judges):

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F41#1 row (4 frames) | 5.10 | 6.81 | +1.71 | 3/3 |
| Approach frames alone | 2.80 | 6.42 | | |

The gain is from the stand, not from new art: the old approach stand sat beside the trunk and faced bark from 5 m. LANE-SCOUT asks for this to be F41#1's fixed approach camera set: both sides of every later comparison use it. High only; Medium has not been judged.

## What lands
- `data/config/capture_stands.json approach_overrides`: ON, with `_why_on`. The two Stormheart approach views search for their stand from (-100, 5300), heading 0.
- `tools/phase2_capture_locations.gd`: `approach_override_for` and its two call sites (catalogue rows and landmark rows). With the block off or a destination unnamed, stands are exactly as before.
- `tests/test_capture_approach_overrides.gd`: pins the two destinations, the verdict citation, that no other destination moves, and that malformed entries are rejected.
- `docs/TECHNICAL.md` §8.1: one bullet naming the new F41#1 approach stand.

## Not in this landing
- `split_bark_finish.aged_heartwood_1112` (the judged arm had it on, but no frame faces the split, so it was not judged). Its code and flag are on `tb/below6`, OFF. It needs one split-facing frame as its own small arm.
- `ramp_body_1112`: flag-off, on `tb/below6`, not judged.

## Tests
Run in the lane checkout with main's `capture_stands.json` plus this block and the landing test copied over: `--only=capture_approach_overrides,capture_stand,phase2_capture,capture_view`: 4 test files, 17 tests, 61 assertions, 0 failed. No older test pins the old Stormheart approach stand (searched `tests/` for the two identities and for `approach_overrides`). No full suite.

## Still named by the judges (3/3)
The crown is out of frame; the interior banners read as flat UI decals; a black pool with an orange crack line sits in the interior foreground (one judge: "close to warning red"); smooth mauve trunks with no bark detail; a branching crown mesh is asked for as new art.
