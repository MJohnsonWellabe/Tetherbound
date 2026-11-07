STATUS: land (lane list done)
BRANCH: tb/item-f38-17 (this note); each row's own branch and READY are listed below
HEAD: (this commit)

# LANE-KIT: list complete (7 Nov 2026)

Every row in the brief is finished. Each READY sits at ralph/reports/LANES/ITEM-<ROW>/READY.md on its own branch.
Scores are CPU mapped; a row closes only on the GPU.

| Row | Branch | Status | Score (CPU mapped) | Flag |
|---|---|---|---|---|
| Capture fixes a-e | tb/item-capture-fixes | land | - | - |
| F38#31 alpha presence | tb/item-f38-31 | land | 6.69 -> 6.84 | alpha_presence_1105 ON |
| F38#33 catch result | tb/item-f38-33 | land | +1.45 | hud catch_card.step_back_on_break ON |
| F38#26, F38#19 | tb/item-f38-26, tb/item-f38-19 | parked | flat | OFF |
| F38#38 craft | tb/item-f38-38 | parked | at the bar on CPU | quiet_missing_r5 OFF |
| F36#70 Sparkit legs | tb/item-f36-70 | land | +0.20, +0.12 | lanekit_sparkit_legs_1107 ON |
| Fulgocobra/Mirejaw eyes | tb/item-eyes | land | 6.09 -> 6.78 | lanekit_face_read_* ON |
| Hit-react grounding | tb/item-hitreact | parked | flat | lanekit_hitreact_grounded_1107 OFF (HELD) |
| F41#8 outfit variants | tb/item-f41-8 | land | 5.47 -> 5.83 | lanekit_f41_8_{bryn,maud} ON |
| F38#17 Solene/Hald | tb/item-f38-17 | land | 5.81 -> 7.32 | lanekit_f38_17_{solene,hald} ON |

## Merge note
- tb/item-f41-8 and tb/item-f38-17 each add two character_appearance_variants records, and each moves
  tests/test_character_appearance_variants.gd to `staged.size() + 8`. Once both land, that line is `staged.size() + 10`.

## Best next candidates
- F38#17 straight to the GPU High pass (CPU 7.32; the close-out exception applies).
- F41#8: per-role silhouette accessories from installed families (new_art in the judges' terms).
