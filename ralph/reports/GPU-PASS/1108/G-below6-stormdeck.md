# G-below6-stormdeck: warm deck wood, cloth banners and retuned aged heartwood (F41#15, F41#1; GPU High)

## Verdict: passes the ship rule, ride-along only
- **F41#15 row (3 frames):** +0.48, all three judges prefer the arm.
- **F41#1 split frame:** +0.40, all three judges prefer the arm.
- No set loses.

Both gains are under 0.5, so this rides inside a larger change rather than landing alone.

This replaces `G-below6-stormdress.md`. The rose-pink split wood flagged there is fixed: no judge now sees pink or red on the arm.

## Frames

**Source:** `tb/gpu-frames-1108`, High, both sides captured on `tb/below6` b49b20b41 with no import.
- That tree is main through #918, so the Marrow glow fix is on both sides.
- Dialogue blend is 1.000 on all frames. 0 blank, 0 script errors.

**Sides:**
- **base:** overlay off.
- **arm:** `BELOW6-STORMDECK/overlay.json`, which applies three changes: `deck_wood_warm_1112`, `banner_cloth_1112` and a retuned `aged_heartwood_1112`. The log confirms all three.

**Sections:**
- `G-below6-stormdeck-marrow` (32816e840): the full F41#15 row, stacked: captain_marrow, captain_marrow_dynamo_core, officer_nysa_deepwood_rod.
- `G-below6-stormdeck-split` (b10e9ab98): the split-facing spot frame.

**GPU lane's hue pre-check** (saturation-weighted, base → arm). Every arm reading falls between 15° and 50°, so none is pink or magenta.

| Surface | Base | Arm |
|---|---|---|
| Deck | 322° / 324° (lavender-pink) | 27° / 23° (warm wood) |
| Left trunk | 10° (saturated orange) | 21° (olive-brown) |
| Split face | 21°, sat 0.91 | 38°, sat 0.51 |

**Render check (mean difference, share of pixels changed):**
- Marrow row: 7.3, 22.8%.
- Split frame: 4.4, 10.0%.

## Batch `G-sk`

Three code-blind judges with the standard prompt. Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.

**Fit:** linear, slope 1.1961, intercept −0.4065, r 0.915, RMSE 0.557. No warnings.

## Results

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| F41#15 dialogue row (3 frames) | 3.9, 4.4, 4.3 → 4.62 | 4.2, 4.9, 4.7 → **5.10** | +0.48 | 3/3 |
| F41#1 split-facing frame | 3.8, 3.9, 4.6 → 4.50 | 4.1, 4.2, 5.0 → **4.90** | +0.40 | 3/3 |

**What changed:**
- **Marrow frames, arm (3/3):** "the deck is a natural tan wood and the trunk is olive-tan, which is more believable". On base the deck was "pink-lilac" and the trunk "saturated orange".
- **Split frame (3/3):** base's "hot, saturated orange [panel] ... nearly reaches the reserved red" becomes "muted tan/gold ... less jarring", but it "still looks flat and striped / like a flat texture card".

**Recorded defects:**
- **F41#15 obstruction:** PRESENT 1/3, PARTIAL 2/3 on both sides. Nysa's frame is the same on both: "a huge saturated royal-blue bird creature ... fills almost the whole frame, Nysa a sliver behind it".
- **F41#1 "ring with a hole":** PARTIAL 3/3 on both sides.

## What still holds these rows down (3/3)
1. **F41#15, Nysa.** The storm birds fill her frame, and the player's blown-out head covers the left edge. This is the change that moves the row; the dressing cannot.
2. **F41#15, Marrow.** His hair still blooms white, and the dialogue box covers him from the chest down. The sky is "flat purple backdrop bands", and the background "reads as a test box".
3. **F41#1 split frame.** It is "a close-up of two flat tiled bark walls with no crown, core, sky or storm atmosphere". The bark texture is stretched and the left panel is still a flat striped card. Judges ask for a Stormheart hero asset (new art) or a reframed stand.

## Recommendation
1. **Land stormdeck in place of stormdress.** Its colours are now clean.
2. **Ride it along with Nysa's creature clearance,** the only change that can lift F41#15 past 6.
3. **Treat the split-frame stand as a capture problem.** That stand shows only bark, so its scores will stay low until the stand moves or the tree gets its crown.
