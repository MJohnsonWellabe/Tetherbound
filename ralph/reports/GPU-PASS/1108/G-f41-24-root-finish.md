# G-f41-24-root-finish: canopy root fix at the Fallen Giant grove stand (F41#24, Stormwood cleanliness)

Frames: `tb/gpu-frames-1108`, High.
- **Fix section:** G-f41-24-root-finish (bed48a090), `giant_calm`, live vs arm.
- **Control section:** G-f41-24-root-finish-giant (2e5aadb6e), `the_fallen_giant__day__close`.

**GPU lane's flag (read before judging):** the root fix removes the long mauve wedge at the trainer's feet. A separate flat pale lilac quad stays, and it is in live too.

## Pre-judge render check
- **Fix frame:** the arm changes 11.5% of pixels, so it is in frame.
- **Control frame:** 0.20% of pixels change and luma is flat, so it is unchanged as expected. The control was not sent to the judges.

## Judged
Batch `G-root`:
- Three code-blind judges and the standard prompt.
- A cleanliness brief. F41#24 is not in the item job table, so its criterion text was used as the recorded defect: "Flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the frame".
- Pinned anchors are craft, f10_2_r3_capacitor and f04_6_r22, so this is a confirming batch.
- Fit: linear, slope 1.1685, intercept −0.3116, r 0.806, anchor RMSE 0.683. No warnings.

| Frame | Live | Arm | Gain | Judges preferring arm | Defect (live → arm) |
|---|---|---|---|---|---|
| giant_calm | 5.06 (raw 4.5, 4.7, 4.6) | **5.88** (raw 5.3, 5.4, 5.2) | **+0.82** | **3/3** | PRESENT 3/3 → PARTIAL 3/3 |

## What the judges saw
- **The fix lands.** All three name the live side's defect on their own: "a large flat grey slab cuts diagonally across the ground right of the trainer", "a flat, untextured grey slab sticks out of the ground … clearly cuts through the terrain". They agree it is gone on the arm.
- **The lilac quad is still there**, as the GPU lane said. All three flag "a flat white rectangular quad (with a dark notch) on the ground at the lower right", plus white flecks, as placeholder or a rendering bug. This is what keeps the arm at PARTIAL.
- **Further cleanliness defects on both sides:**
  - **Screen-door dither:** all three see a cross-hatch or dither pattern on the near pink-mauve trunks, which "reads like an untextured preview material".
  - **Trainer bloom:** the trainer's arms and shoulders bloom white in all three reports ("looks like a bug").
  - Flat cut-out foliage and a flat near-black ground. One judge also calls out a stray orange line across the pool in the arch frame.

## Verdict
- **SHIP the root fix.** +0.82 with 3/3 judges preferring it.
- **F41#24 stays open.** The arm is at 5.88 and the defect is PARTIAL.
- **The next F41#24 cleanup** is four items, each named by all three judges:
  1. Remove the pale lilac or white ground quad and the white flecks.
  2. Fix the dithered trunk material, which may be distance-fade dither showing on near trunks.
  3. Fix the white bloom on the trainer's arms.
  4. Give the ground real moss and litter.
