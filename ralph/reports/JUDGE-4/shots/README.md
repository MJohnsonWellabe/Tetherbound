# JUDGE-4 derived frames

**None of these are new captures.** There is no Godot binary in the JUDGE-4
container, so nothing could be re-shot. Every file here is derived from frames
already committed on `origin/ralph/T1-VARIANTS`, and is included only so the
defects in `ralph/reports/JUDGE-4-2026-08-30.md` can be checked without
rebuilding the crops.

Rows in the stacked sheets are always in this order:
**Nightburrow / Stormtrail / Riftfrill / Ashtusk**, each variant on the right
of its base species, with the 1.80m trainer as ruler in the wide frames.

| File | Source | Why |
|---|---|---|
| `chk-nightburrow-eye-day-vs-night.png` | `nightburrow-vs-burrowback-{day,night}-close.png`, eye crop, day left / night right | **Q2-D3, the highest-priority defect.** The eye is a yellow-gold crescent on the lower lid, and it is *dimmer at night than by day* — diffuse albedo, not emission. The sheet specifies a violet glowing eye. This crop is the whole argument. |
| `derived-variants-day-wide-sheet.png` | the four `*-day-wide.png` frames stacked | Q2-D2, Q2-D5, Q2-D11. Whole-queue day read at once — this is where Stormtrail and its base fail to separate. |
| `derived-variants-night-wide-sheet.png` | the four `*-night-wide.png` frames stacked | Row 4 is where Ashtusk's ember tusks resolve, answering JUDGE-3 directly. Rows 2 and 3 are where Stormtrail and Riftfrill do not. |
| `derived-variants-night-close-sheet.png` | the four `*-night-close.png` frames stacked, half scale | Confirms the emissive *quality* is good — soft cores with falloff, no pixel staircase, no mirroring, clean pupils. JUDGE-3's four technical defects are fixed and this sheet is where you can see it. |

Seeing the queue at once is what makes "one creature recoloured" visible or
not, and it is the artefact the visual-judge skill asks for. The committed
evidence did not include one.

**No Hall crops here.** Queue 1 was deferred, not judged — the lane was still
building. See the report's Q1 section.
