# F13#5 function rounds: currents, inhabited docks, Veilfall distance read

Phase 1 closes this row on function and readability (owner, 2026-09-28; STATE §1
ruling 4). Bars A/B moves to the Phase 2 catalog.

Capture: `tools/capture_tidewake_f13_5.gd`, local xvfb + opengl3 (Mesa llvmpipe),
1280x720, the production Water scene, CameraRig and HUD, day, clock frozen.
Declared fixtures: teleport stands and the mid-chapter upstream story flags in the
tool header. Each judge was a fresh code-blind subagent that saw only its frame
folder and the questions (function only, "do not mark down simple or flat art").

## Round 1 (`r1/`, main 5396c23a: before this lane's changes)
| Question | Verdict |
|---|---|
| Q1 Veilfall far read | WEAK: tiny from First Shore; the Salt Crown landing stand faced its own slope |
| Q2 docks | 1 INHABITED / 6 WEAK / 0 EMPTY: six of seven docks had no people |
| Q3 currents | 0 YES / 3 WEAK: foam moves, direction unreadable |

## Changes
- `water_dock_residents.gd`: two installed-cast dock hands at every mandatory dock
  (presentation only, no prompt/collider/state; every peer builds the same people).
- Current shader: ribbon ends fade over 6 m, not 12% of the route; a direction cue
  (chevrons in r2, replaced by flow-lane comets in r3).
- Veilfall stands: mid-journey from the Tidal Cradle departure dock and the Sluice
  Isle departure dock (the Salt Crown landing looks into its own island).

## Round 2 (`r2/`, 811c3244 + residents)
| Question | Verdict |
|---|---|
| Q1 Veilfall | **YES**: "clearly the same grey cone with the same white falls, and it gains detail as you get closer"; weak only at the farthest First Shore view |
| Q2 docks | **7 INHABITED / 0 WEAK / 0 EMPTY** (2-3 people each; caveats: identical layouts, small figures) |
| Q3 currents (chevrons) | 0 YES / 3 WEAK: marks animate but read as crosses and do not share one direction |

## Round 3, currents only (`r3_currents/`, 8d7e3ddf, comets)
frame_01+02 First Shore→Reedhaven, 03+04 Brine Steps→Shellwatch, 05+06 Salt
Crown→Sluice Isle; each pair 0.5 s apart.
- All three: "It is obvious that the water is moving; there are many aligned
  streaks"; the dashes "shift a few pixels down each lane, toward the camera and the
  shore". Direction read in all three pairs: **toward the player/dock**, which is the
  authored adverse flow back toward the departure dock.
- Rated WEAK (3/3) only because a pointed tail in a still frame suggested the
  opposite direction; the judge's suggested remedy (narrow tail upstream, bright head
  downstream) is the shipped comet shape.
- Reading: currents now read as currents at the normal camera, with the correct
  direction from motion; the still-frame arrow ambiguity is recorded, not closed.

## Veilfall interior (F14#1 overlap; `interior_r3/`, `interior_r4/`)
- r3 (props placed): 1 READS / 4 WEAK / 1 NO (Pump Hall: "no pumps anywhere").
- r4 (Pump Hall machinery on): **1 READS / 5 WEAK / 0 NO**. The route is readable in
  every frame; the weak ratings are room identity (no visible inflow, pumps not
  recognisable as pumps, flat water planes, no captive visible in the crystal):
  asset and look work for the Phase 2 catalog.
