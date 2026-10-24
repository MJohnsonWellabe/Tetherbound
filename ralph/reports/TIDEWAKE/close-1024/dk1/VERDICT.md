# Tidewake close-1024 round dk1: F13#5 docks with the Meshy 1024 buildings (24 Oct 2026, CT)

- **Item:** the F13#5 inhabited-docks frame. Four mandatory departure docks, each seen from 20 m inland (`capture_tidewake_f13_5.gd --only=docks`). CPU llvmpipe, Low, 1920x1080, four frames per side stacked.
- **Control:** main 5f1f388cc, the shipping dock village (Meshy fisher hut plus two installed Medieval cottages per hamlet).
- **Candidate:** `--tidewake-look-candidate` at 28c4e8282. The Meshy 1024 boathouse and smokehouse replace the cottages, mixed per dock; a work cluster by each pier; pavers off. Note the candidate side also carries the parked currents candidate, since both sit under the same flag.
- **Yardstick:** standard prompt verbatim, three fresh code-blind judges; `anchor_tiles.py --seed 4242 --pairs 4 --include craft --include f36_0_npc:C1`; `calibrate.py` fitted a line (slope 1.071, r 0.915), anchor RMSE 0.50, top anchor 7.53, `confirming_batch: true`.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Control (main) | 5.7 / 5.5 / 5.2 | **6.07** |
| Meshy 1024 candidate | 5.4 / 5.3 / 5.4 | 5.97 |

**No gain (-0.10).** The building swap stays OFF.

**This also re-measures the shipping docks on the current yardstick: 6.07, below the 6.7 CPU-provisional bar.** The close-1022 figure of 6.77 was measured before the standard prompt was corrected and with weaker anchors; the dock half of F13#5 should not be counted as met.

## Recorded defects (all three judges)

| Defect | Control | Candidate |
|---|---|---|
| Pier on empty sand, not an inhabited harbour | PARTIAL x1, PRESENT x2 | PARTIAL x1, PRESENT x2 |
| Buildings repeat dock to dock, or mixed family | PRESENT x3 | PRESENT x3 |
| Currents as painted road markings | PRESENT x3 | PARTIAL x3 |

## Why the new buildings did not move it

The judges split on the buildings themselves: the Meshy thatch huts are "a loosely coherent coastal family", but at 20 m they read "small and half-dressed" and "pale, washed-out", while the control's half-timber cottages "add density and a sense of people living there" even though they read as "an inland village family dropped onto the sand". The swap traded density for coherence and came out level.

**What none of them could miss is the layout.** "The same stilt house with a teal door, the same blue banner and the same stall cluster repeat at every dock." Changing which models sit in the spots does not change the spots: all three hamlets share one layout template's positions, the same banner and the same stall, so the four landings still read as one copied set. That, plus an empty sand foreground with nobody working it, is the dock ask in every verdict.

## Next step for this item (scene work, no new art needed)

1. **Per-dock layouts, not per-dock models.** Three layouts that differ in where things stand (which side the buildings flank, where the stall and banner go), not only in which GLB is placed.
2. **Fill the walk-in.** The 20 m approach is bare sand in every frame; the sloop, nets, racks and fish crates belong between the camera and the pier, with residents working there rather than bunched at the waterline.
3. **Keep the Meshy buildings and scale them up** (the judges read them as small at 20 m), and drop the inland cottages rather than mixing families.
