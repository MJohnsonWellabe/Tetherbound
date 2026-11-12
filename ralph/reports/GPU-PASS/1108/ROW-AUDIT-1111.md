# Row audit 11 Nov: current GPU score for the 26 board rows below 6

Request: the coordinator, 11 Nov 01:53 UTC. For each row, this gives the best GPU mapped score from any LANE-SCOUT verdict on `tb/item-scout-1108` since 8 Nov whose change is now on main (batches through #898, checked against main's log), or "8 Nov stands".

Rules used:
- **Landed:** the verdict's arm (or the main state it measured) is on main per the merge log (#869–#898).
- **Own frames:** the verdict judged the row's catalogue frames (all, or the subset named).
- **All scores are GPU High mapped** unless marked. No row below was re-judged on Medium.
- **Scale scatter.** The same unchanged main state has scored up to ±0.4 apart in different batches (see F41#15, F41#8). Where several on-main measurements exist, the table gives the best and the latest, and a **board value** recommendation. That value is the latest on-main measurement of the row's own frames, which is the honest current state.

## Rows with a newer score

| Row | 8 Nov board | Best on-main score since (verdict, landed via) | Latest on-main score | Frames judged | Recommended board value | Still below 6? |
|---|---|---|---|---|---|---|
| **F41#21** Hollows victory reward | 5.78 | **7.13** (`C.md`, victory_on arm; `hud.json victory_focus` on main since batch 25 / aa23cda5b) | 7.13 (same) | own: hollows 99-after, 100-aftermath | **7.13** | **no** |
| **F38#1** creature faint/rest | ≈5.76 | **6.58** (`G-npc-floor.md` F38#1 recheck on the ghost-glow state; ghost-glow landed batch 27) | 6.58 | own: faint and rest frames | **6.58** | **no** |
| **F40#19** Cloudreach rain | ≈6.2/5.x | **6.66** (`G-f40-19-mist.md` sky-only arm, +0.44 3/3; landed batch 39 "slate overcast", #885) | 6.66 | own: F40#19 rain frames | **6.66** | **no** |
| **F41#15** Marrow/Nysa dialogue | 5.71 | **6.67** (`G-npc-floor.md`, live side on main ba6778f45 with ghost-glow; ghost-glow landed batch 27) | 6.33 (`G-exposure.md` live), 6.11 (`G-ghost-glow.md` arm) | own: Marrow, Marrow dynamo, Nysa | **6.33** (median of 4 on-main measures, 5.88–6.67) | **no** (3 of 4 measures ≥6.1) |
| **F41#13** electric creature finish | 5.59 | **6.14** (`G-parked.md` charged_1105, +0.61 3/3; landed batch 27) | **5.00** (`G-rescore-f39-21-f41-13.md`, one-sided on main 306239e9f) | own: fulgocobra and stormraven idles | **5.00** (latest; the two batches disagree by 1.1) | **yes** |
| **F41#3** named wild fight spacing | 5.78 | **6.86** (`G-voltarach-value.md`, bloom clamp; landed batch 33) | **5.89** (`G-hollows-giant-trees.md`, giant-tree fade; landed batch 51: Hollows 5.89, Capacitor 5.89) | own fight (Capacitor), plus Hollows in batch 51 | **5.89** (latest; fights diverge per run, spacing defect still PRESENT 3/3) | **yes** |
| **F38#30** Burrow Warrens hillside | 4.00 | **5.38** row (`G-newapproach-warrens-flank-stand.md`: walk_03 5.52, walk_02 5.24; stand landed batch 52, foundation batch 48, ridge batch 50) | 5.38 | own: walk_02, walk_03 (both) | **5.38** (the arm's walk_03 included the unlanded flank, which is not in that frame's view) | **yes** |
| **F41#8** Stormwood named silhouettes | 5.31 | 6.11 (`G-f41-8.md` live side, main d9d79ff93; the arm did not ship) | 4.84 (`G-npc-floor-go.md` live, main ba6778f45) | own | **8 Nov stands (5.31)**: no change landed; later live re-measures scatter 4.84–6.11 | **yes** |
| **F41#1** Stormheart named destination | 5.78 | — (`G-storm-light-b-core-v2.md` −0.13, `G-scout-arms.md` 0.00: neither shipped) | live re-measures 5.75, 4.87 | own | **8 Nov stands (5.78)** | **yes** |
| **F38#32** camp spacing | 5.66 | — (`G-scout-arms.md` arm −0.35, did not ship) | live re-measure 6.24 (main 4af7d07a9) | own | **8 Nov stands (5.66)**: no change landed; one later live re-measure 6.24 | **yes** (by the 8 Nov score) |

## Rows where 8 Nov stands (no newer LANE-SCOUT verdict applies)

| Row | 8 Nov score (LANE-SCOUT section) | Note |
|---|---|---|
| F40#6 | 5.10 (`F-cloudreach.md`) | Cloudreach matrix baseline (F40#0, 6.58) covers the biome, not this row's frames |
| F40#11 | 5.50 (`F-cloudreach.md`) | as above |
| F40#9 | 5.72 (`F-cloudreach.md`) | as above |
| F40#8 | 5.85 (`F-cloudreach.md`) | as above |
| F40#3 | 5.86 (`F-cloudreach.md`) | **closer capture stands landed in batch 25** (#871); no GPU re-judge since, so **re-capture to credit it** |
| F40#1 | 5.90 (`F-cloudreach.md`) | |
| F40#5 | 5.94 (`F-cloudreach.md`) | the Veyra pilot lost that run (see `F-cloudreach.md`) |
| F39#8 | 5.66 (`B.md`) | |
| F38#5 | 5.86 (`B.md`) | |
| F41#9 | 5.86 (`B.md`) | |
| F38#26 | 5.91 (`B.md`) | |
| F38#8 | (`F-meadows.md`) | Meadows full-row baseline (F38#0, 6.60) covers the biome, not this row's frames |
| F38#31 | (`F-meadows.md`) | as above |
| F39#30 | — | no LANE-SCOUT verdict on this row; board value stands |
| F39#31 | — | no LANE-SCOUT verdict on this row; board value stands |
| F36#29 | — | no LANE-SCOUT verdict on this row; board value stands |

## Summary
- **Leave the below-6 list: 4 rows.** F41#21 (7.13), F40#19 (6.66), F38#1 (6.58) and F41#15 (6.33 recommended, 6.67 best).
- **Moved, still below 6:** F38#30 (4.00 → 5.38) and F41#3 (latest 5.89, though one landed verdict scored 6.86).
- **Disputed:** F41#13. A paired verdict at 6.14 is on main, but a later one-sided re-score on main gave 5.00. I count it below 6 until a confirming re-score.
- **Below-6 count: 26 → 22** (or 21 if F41#3 is taken at its best rather than its latest).
- **Cheapest re-captures that could move more rows:**
  - F40#3: its new stand landed but was never re-judged.
  - F38#32: a later live re-measure gave 6.24 with no change, which suggests scale scatter. A confirming one-sided re-score would settle it.
  - F41#13: settle the 6.14 against 5.00 disagreement.
- **Medium:** no row here has a Medium verdict. F38#28, cited by the coordinator, is not on this list; its confirm batch gave High 7.54 / Medium 6.99 (`G-confirm-75*.md`).

## Update 11 Nov: `G-recheck-1111` (one-sided, main e1c941cbd, GPU High, confirming batch)

| Row | Re-score | Above 6? | Replaces |
|---|---|---|---|
| F38#32 | **6.37** | **yes** | 8 Nov 5.66 |
| F40#3 | 5.65 | no | 8 Nov 5.86 (the #871 stands do not lift it) |
| F41#13 | 5.14 | no | settles the 6.14 vs 5.00 disagreement at about 5.1 |

**Below-6 count after the recheck: 21** (20 if F41#3 is taken at its best). See `G-recheck-1111.md`.
