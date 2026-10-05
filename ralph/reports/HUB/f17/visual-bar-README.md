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
