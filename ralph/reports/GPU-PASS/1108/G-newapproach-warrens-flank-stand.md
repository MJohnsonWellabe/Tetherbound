# G-newapproach-warrens-flank-stand: flank grass + open-ground walk_03 stand (F38#24, F38#30; GPU High)

Frames: `tb/gpu-frames-1108` 6e47b5a2f, High.
- base = 3f2fffb61 + `warrens4_base`: the shipping state of batches 48 and 50 (foundation with the new mouth keep-out, stand guard, ridge).
- arm = base + `overlay_flank_and_stand`: grass grain and ground cover on the foundation flank, and an explicit open-ground walk_03 stand.
- Frames: walk_02, walk_03, Warrens route_day, and the stronghold approach as a control.

Render check (pixels changed by more than 30): walk_02 2.6%, walk_03 56.3%, route_day 8.2%, stronghold 9.0% (creatures and grass sway).

Batch `G-fs`:
- three code-blind judges, standard prompt, each row's own brief;
- anchors craft (7.35), f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.

Fit: linear, slope 1.1967, intercept −0.4675, r 0.856, anchor RMSE 0.596.
Warnings (verbatim):
- `meets the bar only above the top anchor (7.35): G F38#24 stronghold route_day control … extrapolated, but this batch's anchors reach 7.35 or more, so it is the confirming batch`
- `some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)`. The walk scores sit below the lowest anchor.

## Verdict: does NOT pass as built. Warrens route_day loses again (−0.20, 0/3). This is the second loss for the flank texture, so park the flank line.
**The walk_03 stand is the big win and should ship on its own:** +2.47 on F38#24 and +1.28 on F38#30, 3/3 on both.

| Frame | Row | Base | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|---|
| **walk_03** | F38#24 mountains | 4.16 | **6.63** | **+2.47** | **3/3** |
| **walk_03** | F38#30 hillside | 4.24 | **5.52** | **+1.28** | **3/3** |
| walk_02 | F38#24 | 3.88 | 3.88 | 0.00 | tie (unchanged) |
| walk_02 | F38#30 | 5.24 | 5.24 | 0.00 | tie (unchanged) |
| **Warrens route_day** | — | 6.23 | 6.03 | **−0.20** | **0/3** |
| stronghold route_day (control) | F38#24 | 7.51 | 7.51 | 0.00 | tie (**no change**, as required) |

**Row means:**

| Row | Base | Arm | Gain |
|---|---|---|---|
| F38#24 (walk_02, walk_03, stronghold) | 5.18 | **6.01** | **+0.82** |
| F38#30 (walk_02, walk_03) | 4.74 | **5.38** | **+0.64** |

**Stronghold frame:** 7.51 mapped on High, judges 7.43, 7.43, 7.67, in a confirming batch. This single F38#24 frame now sits at the bar. It is a control here (unchanged on both sides), so it is the ridge's earlier result reconfirmed. The row as a whole is far below 7.5 because of the walk frames.

## Why route_day loses (second time for the flank)
- All three judges say the arm adds "a dark, muddy shadow blotch across the right-hand hill that reads as a texture error, not as form".
- The new grain and ground cover on the flank darken it into a dirty patch.
- Earlier batches:
  - batch 48 foundation, against a base with black shards: +0.46;
  - ridge batch, smooth stretched flank: −0.22;
  - now, grained flank: −0.20.
- Two consecutive losses on the flank texture is the owner's two-failure rule, so **park the flank texture line** until there is a new idea. For example: match the neighbouring hill's own grass material and value exactly, rather than adding a new grain.

## What the walk_03 stand does
- The open-meadow stand frames a continuous, soft blue range behind the route, with no slash facets (F38#24 defect FIXED or PARTIAL).
- A bear creature reads well on the right.
- **Remaining:**
  - the hillside on the left is a long, straight-bottomed, smeared green wall with a brown cut strip at the burrow end (F38#30 PARTIAL, 3/3);
  - floating leaf cards in the sky.

## Still dragging both rows
- **walk_02 (unchanged):** a close blurry hillside with the brown band and dark cut. Its "mountains" are pale-blue shards poking over the crest (F38#24 PRESENT). It needs its own open-ground stand, as walk_03 just got.
- **Flags, unchanged:**
  - the crimson trees beside the Burrow (red on friendly ground, 3/3);
  - the opaque white smoke cone;
  - floating leaf and debris cards above the mound;
  - the smeared mound texture.
