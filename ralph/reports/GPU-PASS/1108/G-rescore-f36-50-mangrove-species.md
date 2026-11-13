# G-rescore-f36-50-mangrove-species: F36#50 Mangrove Monitor on main (GPU High, one-sided)

## Score: F36#50 = 6.70 mapped (board 6.98, −0.28)

| | Value |
|---|---|
| Raw a / b / c | 6.0, 6.25, 6.2 |
| Mapped per judge | 6.52, 6.82, 6.76 |
| Dark body, low contrast | PRESENT for a and c; PARTIAL for b |
| Faint lies flat with the trainer inside the tail | PARTIAL 3/3 |

- **Panel strictness:** this batch ran about 0.6 strict (control 7.63 against 8.16/8.30), so some of the −0.28 is the panel.
- **Trainer and tail:** the clear-ruler stage (#923) did what was hoped. The tail no longer passes through the trainer (3/3), but it still ends right at the trainer's feet, hence PARTIAL.

## Frames and batch
- Section: `tb/gpu-frames-1113` 69aaecbfb, species `mangrove_monitor`, High, pose stage with the clear ruler.
- Set: 2×2 of hit-000, hit-050, faint-050 and faint-100, crop (560, 200, 1560, 840). One-sided.
- Batch: `yardstick_g_batch5_1113/`. Fit r 0.925, RMSE 0.38. Confirming.

## What the judges see
- **Body (3/3):** "a believable scaled monitor with cyan spine glow and eyes", taller than the trainer. The body is "near-black" or "a single dark mid-tone" against the grey stage, and at 30% the silhouette "reads mostly through the cyan spots and the shadow".
- **Tail (judge a):** in the standing frame the curled tail tip reaches about trainer height right beside them, a near-overlap.
- **Faint end (judge a):** reads as "a long low slab".

## Next asks (LANE-BEINGS)
1. **Body value:** lift the albedo, especially the dorsal and flank, and add rim light. This is the 3/3 ask and the one that moves this row. Material.
2. **Tail:** shorten or uncurl the tail tip in the standing and faint poses so it stays clear of the trainer's feet. Pose data, or shift the stage ruler 0.3 m.
3. **Cyan spine spots:** keep them; they carry identity. Brighten them slightly.
