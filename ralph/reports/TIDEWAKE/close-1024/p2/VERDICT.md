# Tidewake close-1024 round p2: P2-008 shore landforms in the judged view (24 Oct 2026, CT)

- **Item:** the coordinator's 12:12 work order, step 2.
  - The old Deep Watch clusters sat 18-34 m inland of the P2-008-shore stand, and that stand faces the sea. Every cluster was therefore behind the camera, and the control and candidate frames came out identical.
  - The clusters now sit 4-14 m out, between the stand and the waterline: span ±14°, 3 clusters (`water_dune_cover.json`, `deep_watch` site).
- **Views:** `deep-watch-shore-day` and `deep-watch-shore-night`, CPU llvmpipe, Low, 1920x1080, stacked.
- **Control:** `tb/tidewake` 8ce49fdaf, shipping.
- **Candidate:** the same commit with `--tidewake-shore-candidate`, which enables the parent `shore_ecology_candidate`.
- **Yardstick:**
  - Standard prompt verbatim, three fresh code-blind judges.
  - `anchor_tiles.py` with seed 5151 and 4 pairs.
  - `calibrate.py`: linear fit with slope 0.991, r 0.86 and anchor RMSE 0.62. The top anchor is 7.53, so this is a confirming batch.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Main (shipping) | 5.3 / 5.4 / 5.2 | **5.72** |
| Shore landform candidate | 5.6 / 5.7 / 5.5 | **6.02** |

The candidate gains **+0.30**, and every judge rated it higher. P2-008 is **not met**: 6.02 is below the 6.7 CPU-provisional bar.

The candidate **stays OFF**. Only the Deep Watch site was judged, and the parent flag would also turn on six other islands' clusters that no judge has seen. Shipping the Deep Watch site alone needs a per-site switch. That is a small follow-up if the coordinator wants it.

## Recorded defects

| Defect | Main | Candidate |
|---|---|---|
| Empty sand-plane foreground | PRESENT x3 | PARTIAL x2, PRESENT x1 |
| Even pebble and grass scatter | PRESENT x3 | PRESENT x3 |
| Flat sand-to-water edge, no landform | PRESENT x3 | PARTIAL x1, PRESENT x2 |

## What the judges still ask for

- **Rocks and shoreline:**
  - The rock group reads, but it "sits up on the sand away from the water".
  - The left and centre shoreline stays flat.
  - What the judges want is outcrops or a headland at the waterline with surf foam. That is landform and new-art scale, not small installed rocks.
- **Scatter:** the pebble field is still even. This is the `stone_field` shader again; the same note is in p1.
- **Water markings:** the current-flow lane markings in the shallows read as "road markings / a decal grid". This is the F13#5 currents defect, still present on shipping.
- **Night:** the sand goes to one flat grey-blue.

## Files

- `batch.json`
- `mapped.json`
- `key.json`
- `_sheet_p2.jpg` (left: main, right: candidate)
