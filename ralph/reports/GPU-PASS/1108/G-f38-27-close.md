# G-f38-27-close: F38#27 close-out confirm at High

Frames: `tb/gpu-frames-1108` 136e9af1, **High**, keyboard prompts on both sides (no pad attached), matching the row's earlier frames.
- **Live:** main 52a633598.
- **Arm:** live plus `input_glyph.gd`, `game_menu.gd`, `tab_settings.gd`, `menu.json` and `keyboard_tab.png` at ed4eb76d4 (`keyboard_chip_only` on, `readability_1110` off).
- **Blank-frame receipts:** 0 of 12 on both sides.

## Pre-judge render check
2% of pixels differ by more than 30 levels. A visual check confirms all three changes rendered in the arm frames:
- **Quick-item keyboard column:** the key chip only. The duplicated "1"–"5" digits are gone.
- **Footer:** keycap icons for Previous and Next tab, in place of "[Q]" and "[Tab]" text.
- **Reset line:** shortened to "for 1.5 s: reset all controls".

**Blinding:** each side's two screens were stacked full width at 1280 px so the text stays legible. `anchor_tiles.py` then gave them a random code and side order.

## Judged

Batch `G-f27c`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a **confirming batch**.
- Fit: linear, slope 1.4218, intercept −2.112, r 0.896, anchor RMSE 0.512.
- Warning: the arm meets the bar only above the top anchor (7.35). This batch's anchors reach 7.35, so it is the confirming batch.

| Row | Preset | Live | Arm | Gain | Judges preferring arm |
|---|---|---|---|---|---|
| F38#27 | High | 6.89 (raw 6.4, 6.6, 6.0; mapped 6.99, 7.27, 6.42) | **7.84** (raw 7.0, 7.2, 6.8; mapped 7.84, 8.12, 7.56) | **+0.95** | **3/3** |

**F38#27 reaches the bar at High: 7.84 mapped, with every judge at 7.56 or above, in a confirming batch.** The ship rule is also met (+0.95, 3/3).

The recorded defect ("dense gray-on-navy control instructions and literal key labels make settings and quick binding text hard to scan"):
- **Live:** PRESENT (3/3).
- **Arm:** PARTIAL (3/3).

All three judges name the arm's three changes as the reason.

**To close:** under the owner's High-first rule, F38#27 now needs a **Medium** capture of the same two screens, judged at 7.5 or above. This assumes the GPU close rule applies to this row. Earlier the coordinator treated menus as a CPU exception; the CPU base on the glyph branch mapped 7.81 in G-f38-27-readability. Whether this High result is enough on its own is the coordinator's call.

## Remaining asks, if more is wanted (3/3)
- Brighter body text: the grey helper and instruction lines on navy are low contrast.
- Larger key-cap glyphs and D-pad icons.
- Stronger cell separation.
- Fill or drop the empty Reset column.
- A teal accent on the primary action prompts.

- 10 Nov 03:29 UTC: no Medium frames are on `tb/gpu-frames-1108` (head 136e9af1); the `G-f38-27-close` manifest is High only. I will judge Medium when it lands.
