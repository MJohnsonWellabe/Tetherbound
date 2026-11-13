# LAND-MT-DUSKRIDGE: Meadows mountains at golden hour

**Rows.** F38#0 Meadows frame matrix 6.60 (its dusk frames); the dusk vistas of F38#24 (6.59 on main after #952) and F38#20's stand; no-loss on every Meadows day frame.

**Defect (G-things-redleaf, 3/3, both sides).** Stronghold vista_dusk: "flat tan haze swallows the mountains"; "the dusk grade is ... flat tan at the stronghold".

**Cause, and how I know.**
- The ridge backdrop takes 60% of the scene fog. At golden hour the fog colour is tan (`#c5b5ac` scaled by the sky), so a ridge 1.5 to 1.9 km away is drawn mostly in flat tan. By day the same share of blue fog reads as aerial distance, which is why day frames are fine.
- This is separate from the stale-fog bug fixed in #952: there the wrong hour's fog was used; here the right hour's fog is simply the wrong colour for distant mountains.
- Check: with only the ridge's haze colour and share changed (nothing else in the scene), the tan sheet becomes a blue-grey range with snow and rock form in the same frame (sheet).

**Change.** Overlay only, two values in `meadows_ridge_vl.json` `shader`: `warm_haze_mix` 0 to 0.85, `warm_keep_scale` 1 to 0.6. The ridge shader measures how warm the live fog is; when it is warm, the ridge's haze moves to a cool dusk blue at the same brightness and thins. Blue day fog and night fog measure as not warm, so day and night are untouched by construction.

**CPU before / after.** `_sheet_duskridge_off_vs_on_cpu.jpg`: stronghold approach vista_dusk, left base, right arm. 0 script errors on both sides.

**By-eye line for the GPU lane.** Stronghold approach vista_dusk: the mountains left of the castle are blue-grey with white snow caps; on base they are a flat tan sheet. Any day frame: identical to base.

**Risks and no-loss frames.**
- A cool range against a warm sky could read as two grades in one frame; if judges say so, lower `warm_haze_mix` toward 0.5.
- Dawn fog (`#bcb5bd`) measures slightly warm, so dawn shifts a little too. Not looked at on CPU.
- No-loss: stronghold and Warrens day frames (walk_01 to walk_03, route_day), and night.
