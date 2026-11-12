# G-f38-27: settings and bindings readability arm (menu only, CPU)

**Source:** `tb/item-f38-27-glyphs` 7db168661, `ralph/reports/LANES/ITEM-F38-27/_sheet_readability.jpg`. Frames are CPU Compatibility 1920x1080; menus are a HUD/menu exception to GPU judging.
- **A (base):** the branch with the arm off. The round-1 keycap glyphs are already in.
- **B (arm):** `menu.json` `controls_scan.readability_1110` on:
  - opaque row bands;
  - bordered bright binding cells;
  - lighter headers and notes;
  - a group gap with an amber rule.

**Blinding:** each side's two frames (`settings_controls` over `quick_bindings`) were cropped from the sheet without the A and B labels and stacked. `anchor_tiles.py` then gave them a random code and a random side order.

Batch `G-f3827`:
- Three code-blind judges and the standard prompt.
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.3172, intercept −1.0555, r 0.873, anchor RMSE 0.563.
- Warning: both sides meet the bar only above the top anchor (7.35). This batch's anchors reach 7.35, so it is the confirming batch.

| Row | Base | Arm | Gain | Judges preferring arm | Ship |
|---|---|---|---|---|---|
| F38#27 | **7.81** (raw 6.5, 6.9, 6.8; mapped 7.51, 8.03, 7.90) | 7.68 (raw 6.8, 6.5, 6.6; mapped 7.90, 7.51, 7.64) | **−0.13** | 1/3 (judge a) | **no** |

**The arm fails the ship rule: −0.13, with 1 of 3 judges preferring it.**

Judges b and c prefer the base, for two reasons:
- **Rows hidden under the scroll fade.** The arm's taller bordered cells push the third controls row ("Step left") and quick slot 5 under the fade. Only two usable rows show in the controls frame; the base shows three full rows and all five slots. ARM.md had already flagged this.
- **A busier grid.** The cell boxes make it busier; the base's single focused box "scans more cleanly".

Judge a prefers the arm's "boxed tiles" because they give "the eye an anchor".

## Note: the base itself maps above 7.5
In this confirming batch, the F38#27 **base** (the branch with the round-1 keycap glyphs, arm off) maps **7.81**, with every judge at 7.51 or above. The recorded defect is PARTIAL on both sides (3/3).

What all three judges still name:
- **Duplicated key labels:** the quick-item keyboard column shows a key chip and then the same digit ("[1] 1").
- **The long reset-instruction line** (judge c).

If menus close on CPU under the HUD/menu exception, F38#27 may already be at the bar on the base. Two caveats: this is the coordinator's call, and the base here is branch `tb/item-f38-27-glyphs` with the glyph fix, which is not yet on main.

**Suggested next step, small and config or code:**
- Keep the base layout.
- Drop the duplicated digit after the key chips.
- If boxed cells are wanted, use a shorter cell so three rows still clear the scroll fade.
