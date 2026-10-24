# Tidewake close-1024 batch mx1: F39#3 matrix and F39#5 defect pass (24 Oct 2026, CT)

The first F39#3/#5 batch with weather and a real fight in it. Both were impossible before this close: the fixed-view capture refused any weather but clear, and the full-matrix tool needs a GPU preset plus a job manifest that exists nowhere.

## What was captured, all at the shipping look (the time-of-day grade ON)

- **Look and weather:** `F39-look.json`, nine fixed views. Six existing views (First Shore 12:00/18:00/23:00, the swim-lesson dune 12:00/05:00, Veilfall close) plus three rain views added this close (shore-rain, lesson-rain, veilfall-rain) at the existing stands.
  - Capture: `capture_tidewake_f13_5.gd --camera-set=...`, with the two capture fixes from this close: it honours each view's declared weather preset, and it keeps the weather's sky delta instead of wiping it.
  - The rain views now read as overcast: a grey sky, flat light, haze and no hard shadows.
- **Real fight:** `phase2_capture_tidewake_fights.gd --trainer=water_trainer_venn --seed=2042`, the installed input-piloted Venn fight (Cannonback against Ripplet). It produced 40 frames over 33 s with the fight active.
  - The tool flagged the run as a failure because its 40-frame cap ended before an observed victory, the same as the 1020 recap. The frames are a real fight, and that is what F39#3 asks for.
  - Receipt: `ralph/reports/VISUAL/phase2/tidewake/f39-3-fight-1024/frames.json`. The frames stay local.
- **Renderer:** CPU llvmpipe, Low/Compatibility, 1920x1080.

## Yardstick

- Standard prompt verbatim, three fresh code-blind judges. `anchor_tiles.py --seed 3939 --pairs 4 --include craft --include f36_0_npc:C1`.
- `calibrate.py` fitted a line (slope 0.901, r 0.845), anchor RMSE 0.65, top anchor 7.53, `confirming_batch: true`.
- The fight set shows the same capture on both sides. The standard prompt allows identical sides, and the judges said themselves that the two were identical. The fight's score is the mean of both sides.

## Mapped Bar A

| Matrix part | Raw (j1/j2/j3) | Mapped |
|---|---|---|
| Weather, clear (3 views incl. the Veilfall close-up) | 5.0 / 5.2 / 5.5 | 5.73 |
| Weather, rain (same 3 stands) | 4.5 / 4.6 / 5.2 | 5.31 |
| **Real fight** | 4.4 / 4.3 / 4.9 | **5.10** |

The six clear look views were scored on their own in lt2: **7.07** with the grade ON.

**F39#3 is not met.** The look views pass the CPU-provisional bar, but the matrix's weather and fight rows do not: rain 5.31, fight 5.10.

## F39#5: defect pass, all three judges

| Defect class | Look views | Rain views | Real fight | Owner of the fix |
|---|---|---|---|---|
| Flat magenta rings or slabs | none (FIXED/PARTIAL; the only flat marks are the parked current lanes) | none | **PRESENT x3** | **Fights lane / COMBAT spec (P2-063)** |
| Placeholder or untextured materials | **PRESENT x3: Veilfall cliff** | **PRESENT x3: Veilfall cliff** | PARTIAL/PRESENT: the same Veilfall rock seen from above | **This lane:** material candidate judged in vf1; hero mesh via Meshy 7-8 |
| Floating bodies | FIXED x2, PARTIAL x1 | FIXED | FIXED x2, PARTIAL x1 | nothing to fix |
| Clipping / camera in geometry | **PRESENT/PARTIAL: Veilfall-near stands against the rock** | same | **PRESENT x3: a black slab at the frame edge** | **This lane** (see below) |

**F39#5 is not met.**

### What the two "this lane" defects actually are, checked frame by frame

- **The black slab in the fight is the Veilfall rock.** The fight is at (365, 3805), on the Veilfall approach. At 2x crop the slab is a hard-edged, near-black navy polygon lying on the sand: the base of the Veilfall cliff, seen from the high fight camera.
  - It is the same placeholder material the judges flag up close, not a camera clip.
  - Fixing the rock fixes both rows.
- **The "camera crowding the rock" at veilfall-near** is the camera set's own stand at the foot of the cliff. That is a framing choice in `F39-look.json`, not a game defect. Move the stand back a few metres if a later round needs it.

### What blocks F39#5 that this lane must not change

- **The magenta telegraphs.** The colour is a documented, tested combat decision: `combat.json` `telegraph.colour` is the "must-move" colour, hue 308, kept 25 degrees clear of Team Tether's oxblood by `tests/test_telegraph_glow.gd`.
- The Fights lane owns the fix through P2-063's OFF `tell_style` candidate and the per-attack overrides Stormwood's named fights already use. A Tidewake-only override for Venn's attacks would follow that pattern.
- That is a combat-readability decision, so it is the Fights lane's to make.

### Also seen, and recorded for other lanes

- **UI lane:** the "Gather Reef Stone" world prompt overprints the fight's "C Switch / Esc Flee" line, and the fight HUD covers about 35-40% of the frame.
- **Camera lane:** the player's creature is out of frame in two of the four fight moments. There is no visible hit effect on the hit frame.
