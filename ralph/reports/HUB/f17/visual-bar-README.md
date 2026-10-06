# F17#6 village and Hall full visual bar — Compatibility matrix R1 to R3

Capture: `tests/capture_f17_visual_matrix.gd`. It uses the real farmhouse-door → Main Street → Hall walk on parsed
joypad input; camera turns are by look stick; native 1920×1080, Compatibility. Stations: farm door (approach), mid-street
frontages with the starter called out, Hall approach and its reverse, nave forward/arch walls/reverse, and Shrine Room
plus its reverse. Each station is shot at day, golden and night; five stations are also shot in day and night rain.
43 frames per round.

| Round | Code | Frames | Code-blind verdict |
|---|---|---|---|
| r1 | 09efb3b4 (base) | `visual-bar-r1/frames`, `sheets` | Bar A NO, Bar B NO; destination NO day, NO night (`visual-bar-r1/codeblind-review.md`) |
| r2 | 53e3e0f5 | `visual-bar-r2/sheets` only (intermediate) | not judged; the far gable was still open |
| r3 | scene at ae495e7d (gables) + later test-only commits; frames committed fe31d6db | `visual-bar-r3/frames`, `sheets` | Bar A NO, Bar B NO; destination YES (weak) day and night; the nave is not yet an enclosed lit interior (`visual-bar-r3/codeblind-review.md`) |

| r4 | 356afa08 (door/vestibule pools); **GPU Low** by the Codex render service, f17-1 (tb/lookdev `ralph/reports/LOOKDEV/handoffs/f17/f17-1/low/`, 43 frames at 1920x1061) | `visual-bar-r4/sheets`, `frames.json` | Bar A NO, Bar B NO, Low readable YES. Destination WEAK by day, close to YES at night. Door lit on the stone front, but the doorway is still a flat emissive card. Interior enclosed but not warmly lit (`visual-bar-r4/codeblind-review.md`). The Medium pass failed to boot in the existing tool (fixed below) |

F17 fixes between r1 and r3 (scene-level, installed MegaKit families only):
- Stone crossing tower over the Hall entrance (~17.5 m). The Hall is now the tallest roofline seen from the farm door.
- The Hall's far gable, clerestory ends, aisle and Shrine annex gables are closed. The sky slot and light leaks into the
  nave are gone.
- The Hall shell casts double-sided shadows. There are six nave wall lanterns, and every Hall lantern has a visible flame.
- Matrix stations corrected: the approach is shot ~26 m out, arch walls are split by side, and the starter is on screen.

**F17#6 stays OPEN (FAIL against the full bar).** Two acceptance limits also apply. ACCEPTANCE §4 judges the bars on
High and Medium, which come from the Codex F26 Forward+ lane. These are Low/Compatibility frames only, and the
≥30 s motion sample is not captured under llvmpipe.

Remaining gaps, split by owner (from the r3 review):
- **Global look (F26/WorldLook, not F17 paths):** no haze, fog or depth bands; night is not dark enough; night rain is
  brighter than night clear; day rain does not wet or darken anything.
- **F17 scene work still available:** the night nave and Shrine Room are flooded by ambient light (they need interior
  lighting and occlusion); the ceiling shows roof-tile undersides; the upper windows face the Hall's own roof; there are
  two text lines per arch, labels draw through walls, and the quest beam shows indoors; the road reads as a wide plaza;
  the houses sit on open field with thin dressing.
- **New art (Codex / Meshy, `meshy-handoff/README.md`):** a stone civic Hall kit or hero pieces, hero portal arches with a
  biome emblem and a sealed state, and Shrine pedestals with relic displays.
- **Other defects:** the prompt "Hang your Sealed relic" uses the state word as the item name; a world sign shows behind the
  quest panel; villagers stand in a bind pose; the companion crowds the Shrine stations.

## R5–R6: lane A scene pass and handover (2026-10-06)

Software Compatibility matrix (43 frames per round, xvfb + llvmpipe), judged code-blind. Reviews: `visual-bar-r5/codeblind-review.md` (current main + tb/f17 at c7407294) and `visual-bar-r6/codeblind-review.md` (tb/f17 at d85247ef). Frame indexes: `visual-bar-r5/frames.json`, `visual-bar-r6/frames.json`. Frames are not committed.

| Round | Code | Verdict |
|---|---|---|
| r5 | c7407294 | Bar A exterior YES (day/golden), interior NO; Bar B YES weakly on exteriors only. Destination WEAK by day, WEAK leaning YES at night; front door PARTIAL; interior at night NO |
| r6 | d85247ef | Bar A NO (exterior close); Bar B YES exterior, NO interior. Destination WEAK by day, NO at night; front door WEAK; interior at night NO |

r6 did not compare against main, and it judged d85247ef, before 6fc08802. Its night-destination NO came from the wall darkening below, since reverted (measured), but no judge has seen 6fc08802. **The branch is not landable as an improvement and stays as reference** (coordinator, 2026-10-06).

Scene changes on tb/f17 (installed families only):
- **07f19fab, night nave.** Moonlight leaked through the Hall roof onto the floor: the global night shadow opacity is 0.68, and Compatibility ignores a directional light's cull mask (measured: floor luma 71 with the moon, 30 without). At night the Hall floor modules take their own material copy with albedo × `night_floor_albedo` 0.45. The copy is tagged so static batching keeps it apart. The lanterns go from 1.15 to 1.8. Night floor luma goes 71 → 27; golden hour is unchanged.
- **d30e9383, street and labels.**
  - A night-only `door_lantern.gd` post lantern stands at each of the 8 road-house doorsteps (`village.json door_lanterns`). Ground beside a post at night goes from luma 63 to 131.
  - Pedestal labels sit above their stands at 1.72 m.
  - Labels fade with distance: pedestals past 8 m, arch signs past 14 m.
- **d85247ef, forecourt.** A paved forecourt of two doorstep pavings at the Hall door, with a lantern each side (`lanterns_at`).
- **6fc08802.**
  - r6 caught a regression: night wall darkening (0.6) also darkened the front facade, because the walls are one shell. `night_wall_albedo` is back to 1. Facade night luma: 49 → 60 from the farm door, 46 → 67 at the approach, back to r5 levels.
  - Flames are now amber (#ff9b3d) at lower emission, not white panes.
- **Checks.** Village/Hall unit tests 0 failed. The Hall circuit smoke passes (farmhouse door → Main Street → nave, every arch and pedestal).

Capture option: `tests/capture_f17_visual_matrix.gd -- --capture-dir=<abs> --only=<prefix>[,<prefix>]` shoots only frames whose `station_time_weather` name starts with a prefix, for example `--only=nave-arches-left_night_clear,hall-approach_night`. About 5 minutes per small set here, against about 1.5 hours for all 43.

Open scene items handed to Codex M1 (from r6):
- the Hall facade windows go black at night;
- the doorway is a flat cream card;
- the nave end wall is a black void at night;
- the shrine windows show daylit hillside at 23:00, and the nave clerestories show bright sky;
- the exterior roof edge is visible from inside (no soffit);
- the creature clips a lectern;
- the cobbles are oversized;
- the street lacks trees and props.

Not in lane A's paths:
- road texture and edges: terrain file, another lane;
- haze, rain and the moon at golden hour: F26 global look;
- HUD and clock overlap, and label occlusion behind HUD panels: UX.

New art (Hall silhouette, portals, pedestals, furniture, idle animation) is Codex M1 under RD-26 (`meshy-handoff/README.md`).
