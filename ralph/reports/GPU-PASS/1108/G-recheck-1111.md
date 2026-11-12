# G-recheck-1111: one-sided re-score of F40#3, F38#32 and F41#13 on main e1c941cbd (GPU High)

Frames: `tb/gpu-frames-1108` 9ce07c9bb, `G-recheck-1111`, main e1c941cbd (after #897), High, seed 2042, no overlay. These are the three re-captures `ROW-AUDIT-1111.md` recommended.
- **F40#3** (P2-024 architectural landmark read): windscar_beacon, broken_skyroad_arch and old_wind_observatory, day approach. These include the #871 closer stands.
- **F38#32** (P2-035 camp and workshop prop legibility): camp_tent, camp_bed, bonfire_fire.
- **F41#13** (P2-044 electric creature finish): fulgocobra idle, stormraven idle.

Batch `G-rc`:
- one-sided 2×2 sheets, each row on its own catalogue brief and recorded defect;
- three code-blind judges, standard prompt;
- anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor, so this is a confirming batch.

Fit: linear, slope 1.5399, intercept −2.7664, r 0.936, anchor RMSE 0.487. No warnings.

## Result

| Row | Mapped (judges a, b, c) | Raw | Above 6? | Recorded defect |
|---|---|---|---|---|
| **F38#32** camp prop legibility | **6.37** (5.86, 6.17, 7.09) | 5.6, 5.8, 6.4 | **yes** | PARTIAL, PARTIAL, PRESENT |
| **F40#3** Cloudreach landmark read | **5.65** (5.40, 5.70, 5.86) | 5.3, 5.5, 5.6 | no | PRESENT 3/3 |
| **F41#13** electric creature finish | **5.14** (4.70, 5.24, 5.47) | 4.85, 5.2, 5.35 | no | PARTIAL or PRESENT |

- **F41#13 is settled at about 5.1, below 6.**
  - This agrees with the one-sided re-score (5.00), not the paired charged_1105 batch (6.14).
  - **Fulgocobra:** a dark navy coil whose charge reads only as a faint sheen.
  - **Stormraven:** a pale-blue glowing blob that flattens its feather form. At mid-distance both are small behind the trainer.
  - **Scale:** one judge read the Stormraven as about the trainer's height, against the "creatures taller than the trainer" rule. Worth a scale check.
  - **Judges' fix:** emissive vein and edge masks (cobra scale lines, raven feather edges) instead of a whole-body glow, plus a rim light.
- **F40#3 stays below 6 (5.65) with the #871 stands.**
  - The structures read as plain, disconnected pieces: stacked slab walls on an empty lawn, a bark-brown tower on a mesa disc with a smooth procedural cliff skirt, and a small blue-roofed tower far off.
  - There is no aviary-family landmark: no dome, gold trim, bridges or waterfalls.
  - **The closer stands did not lift the row; it needs landmark art (new_art 3/3).**
- **F38#32 is above 6 (6.37) on current main**, so the 8 Nov 5.66 was low against today's scale.
  - **Spread is wide (5.86 to 7.09).** One judge marked the defect PRESENT: the foreground "CAMP" sign and a boulder cover part of frame 1, and small props overlap NPCs and grass.
  - **Red flag (2/3):** the "CAMP" signboard and a flag in frame 1 read **dark red, near oxblood**, on a friendly camp. One judge called it a leak, one a minor flag. Worth recolouring to a plain wood tone.

## Effect on ROW-AUDIT-1111
- **F38#32 leaves the below-6 list (6.37).**
- F40#3 and F41#13 stay below 6.
- **Below-6 count: 26 → 21** (or 20 with F41#3 at its best).
