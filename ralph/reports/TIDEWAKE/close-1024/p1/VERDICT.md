# Tidewake close-1024 round p1: Meshy 1024 props in the F39-look views (24 Oct 2026, CT)

- **Item:** the coordinator's 12:12 work order, step 1. Place the six meshy-1024 props where the F39-look judges asked for life and foreground, and judge against main.
- **Views:** six fixed `F39-look.json` views (first shore at midday, golden hour and night; swim-lesson dune at midday and dawn; Veilfall falls close-up). CPU llvmpipe, Low, 1920x1080, stacked.
- **Control:** main as merged into `tb/tidewake` 8ce49fdaf, shipping look.
- **Candidate:** the same commit with `--tidewake-look-sections=landmark_props_candidate,dock_village_candidate,dock_dressing_candidate`.
  - Driftwood (0.7-0.95 m tall) and a 1.2 m deck-work cluster on First Shore.
  - Driftwood and a 6.5 m hauled-up sloop on the lesson dune.
  - Driftwood at Deep Watch.
  - None of the six views shows a dock, so the dock sections did not change any judged frame.
- **Yardstick:**
  - Standard prompt verbatim, three fresh code-blind judges.
  - `anchor_tiles.py` with 4 pairs (`--include craft --include f36_0_npc:C1`).
  - `calibrate.py`: linear fit with slope 1.434, r 0.935 and anchor RMSE 0.48. The top anchor is 7.53, so this is a confirming batch.

## Mapped Bar A

| Side | Raw (j1/j2/j3) | Mapped mean |
|---|---|---|
| Main (shipping) | 5.3 / 5.3 / 5.1 | **5.02** |
| Props candidate | 5.6 / 5.8 / 5.5 | **5.59** |

The candidate gains **+0.57**, and every judge rated it higher. Under the coordinator's rule ("turn a prop ON only if its scene beats main"), `landmark_props_candidate` ships **ON**, with the score in its `_why`. It is presentation only with no colliders, so nothing changes for routes or encounters. The dock sections stay OFF: dk1 judged them level with the shipping docks.

**No F39 row closes.** 5.59 is below the 6.7 CPU-provisional bar.

## Recorded defects

| Defect | Main | Candidate |
|---|---|---|
| Empty sand-plane foreground | PRESENT x3 | **PARTIAL x3** |
| Even pebble and grass scatter | PRESENT x3 | PRESENT x3 |
| Razor-straight sea/sky seam, no haze | PRESENT x3 | PRESENT x3 |

## What still holds the frames down (all three judges)

- **Pebbles:** the pebble field is peppered evenly across the whole beach instead of grouped at the tide line and around rocks. This is the `stone_field` shader scatter, which has no clearing threshold.
- **Horizon:** there is no haze band where the sea meets the sky.
- **Night:** the 23:00 sky reads near-black. The lt2 regrade measured night near_luma inside the Meadows night band, but the judges still call it crushed.
- **Veilfall close-up:** black faceted rock and a blown white cone read as placeholder. This needs the Meshy 7-8 hero falls (`meshy-requests.md`), not a scene change; see F39#4.
- **Dune frames:** they are still mostly bare texture apart from the sloop.

## Out-of-scope notes from the same batch

These sets were anchors, not Tidewake work:

- The anchor wall and craft panel scored as expected.
- The Fc boar's B side (lava glow) was flagged as leaning toward the reserved red.

## Files

- `batch.json`
- `mapped.json`
- `key.json`
- `_sheet_p1.jpg` (left: main, right: props)
