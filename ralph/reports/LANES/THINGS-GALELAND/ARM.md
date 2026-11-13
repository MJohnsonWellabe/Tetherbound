# THINGS-GALELAND: Galewisp stands beside the trainer when it lands, whole and clearly taller (close-out)

LANE-THINGS, 12 Nov 2026. Branch `tb/things`. Config only. CPU proof: `_sheet_galewisp_landing_cpu.jpg` (main above, arm below: launch, glide, landed).

## Cause (G-faint2-medium-galecarrier.md, 3/3)
"In the landing frame the creature is half hidden behind the trainer and a foreground bush, and looks barely taller than him."

## The arm (overlay `overlay_galewisp_landing.json` on `data/config/fly_traversal.json`)
- `landing_presentation`: `side_m` 1.2 to 2.3 and `forward_m` 2.4 to 1.2, so the carrier lands beside the trainer instead of behind them. **These two keys are shared by every carrier**, so Galecrest's landing moves too; its landed frame is in CAPTURE.json as a no-loss check.
- `capabilities.galewisp.presentation_height_m`: 3.0 to 3.4. The carrier's height is measured over its raised wings, so at 3.0 its body stood about level with the trainer's head. Presentation only: collision, the grip and the feet offset are unchanged. Creatures must stand taller than the trainer; this grows the creature and shrinks nothing.

## CPU result
- Landed: the bird stands to the trainer's right, whole, about one and a half times his height. On main it is partly behind him.
- Launch and glide: larger, still fully in frame at launch (3.7 was tried first and cut the head off at the top; not used).
- The trainer still hangs from the feet; the larger bird makes the hang a little clearer but the grip itself is not changed.

## Not in the arm
- "The talon grip doesn't read as a grip" (2/3): the remake has foot bones but no toe bones, so the hands meet the ankles. It needs a grip pose on the feet (art), not config.
- The flat fog backdrop (3/3) is LANE-PLACES.

## Estimate
+0.3 to +0.5 on the Galewisp flight row (6.83), all from the landed frame, which every judge named. Risk: the shared landing offsets move Galecrest's landing; if that loses, keep only the Galewisp height.

## Landing note
`tests/test_vis_meadows_1104_on.gd` pins Galewisp's presentation height at 3.0; a landing must update that pin.

## Attempt 2 (12 Nov, after the GPU pre-check failed attempt 1)
- **GPU pre-check, attempt 1:** launch and glide passed and Galecrest's landing passed, but Galewisp's landed frame cut the ear tufts off at the top edge. Cause, per the GPU lane: `forward_m` 2.4 to 1.2 brought the bird nearer the camera on top of the height change. My CPU frame did not show the crop.
- **Change:** `forward_m` is left at main's 2.4. The overlay now only moves the carrier sideways (`side_m` 1.2 to 2.3) and keeps Galewisp at 3.4 m. The side move alone puts it beside the trainer.
- **Not re-captured on CPU:** the CPU landed frame did not reproduce the crop, so it cannot confirm the fix. The GPU pre-check on the landed frame is the test. If the tufts still crop, drop the height to 3.2 before parking; that would be the second failed attempt.
