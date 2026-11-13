# LAND-MT-TWORANGES (F38#24): PARKED on CPU, not sent

Ask: a layered, sculpted mountain backdrop (taller ridge plus a second range).
Code: flag-off `back_layer` in `scripts/world/meadows_ridge_vl.gd` (second copy of the ridge, own scale, height, yaw, sink and fog keep). It stays flag-off.

Rounds (CPU, stronghold_approach routes; sheet `_sheet_tworanges_cpu.jpg`, columns base | back 1.6 | back 1.4):
1. Front ridge scaled 0.82 xz and 1.25 high, plus the back layer: a pale looming wall with streak facets.
2. Back layer only, height 1.6, fog keep 0.9: less overpowering, but tall pale ranges still fill both sides and crowd the stronghold.
3. Back layer only, height 1.4: the same read, a little lower.

By eye, none of the three is better than the base. The back copy is the same ridge mesh stretched, so its facets stretch into vertical streaks and the layer reads as a flat pale wall, not a sculpted far range. Two rounds have now missed. A real second range needs a different far mesh (its own silhouette and erosion detail), and that is new-mesh or Meshy work, outside this round (no Meshy credits).
