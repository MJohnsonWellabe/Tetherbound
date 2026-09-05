# Blind judge — round 1 (frames `shots/vfx/0*` at 8963cd4b+77778f4b's predecessor, sheet `_sheet_round1.png`)

Code-blind sub-agent (opus), given only the sheet, the eight frames, `docs/reference/` and the
visual-judge skill. Verbatim conclusions; the lane's response follows.

## Ranked gaps
1. **The effects are invisible at the size the eye reads them.** At thumbnail scale `01`, `02`
   and `03` show no discernible effect; `palworld-01` at the same scale still reads as a hit
   (hot orange across a quarter of the frame against dark green). "The gap is area and value
   contrast, not detail or fidelity."
2. **No hot colour anywhere.** Every effect is white or pale khaki on a cream creature on bright
   grass — effect, subject and ground in one value band.
3. **The world does not react at the moment.** The creature holds its idle pose through the
   knockout; the caught Mudsnout is still standing at full size in `04`.

## Per-question
- **01 (hit):** "reads as one creature standing in grass with a smudge on its cheek." Impact
  ≈65 px, ~13 % of the creature, white on a cream muzzle; depth-corrected ≈0.6 m. The target
  Bramblebun appears uninvolved ~15 m back (it was in fact adjacent, hidden behind Terrapup's
  head — a framing defect of the capture, see response).
- **02 (knockout):** nothing reads as a knockout; the only added element is a "dull oxblood
  torus" across the creature's chest (this is `telegraph_glow.gd`, the existing enemy wind-up
  ring, not this lane's — see response). The HUD carries the knockout.
- **03 (level-up):** a thin white-grey torus ~290 px hugging the shoulders, reads as
  "stunned / dizzy", not a reward; no ascending particles, no beam, no gold, no emissive lift.
- **04 (catch):** generic flash; a flat khaki disc, a white ball, hard-edged white spikes;
  "no sparkle points, no twinkles"; the orb reads as an egg (existing catching flash + orb
  prop; the new gold sparkle did not register).
- **Artefacts:** rings intersect the body (`02`, `03`); square sprite corners in the jaw puff;
  a stray white streak above the head in `01`; a quad seam and hard spike tips in `04`; the
  catch orb ~0.7–1.0 m across.
- **Bars:** A — **no** (palette on-board; light flat, no dark anchor). B — **no** ("the frame
  contains no combatant relationship at all").

## Lane response (what round 2 changes)
- Tint saturated ×1.7 and motes born white-hot cooling to the element; dark contrast halo
  behind every mote/streak; spark 22 motes, size 0.28 m, core 0.65 m warm; damage scale
  1.2–2.0×; hit flash flat_mix 0.7.
- Level-up: rings gold, radius 2.3× body radius (clear of a long body), thicker, rise 1.5×
  height; beam rebuilt as a real column; motes bigger with halos; rim tint 0.38 flat, gold.
- Catch sparkle gold, 26 motes, bigger, shot 16 ticks in after the existing white flash fades.
- Capture camera steps 3 m sideways so the struck body is in frame beside the ally; a
  `00-squared-up` baseline frame for the pixel-energy delta.
- Not this lane's, passed to the coordinator: the oxblood telegraph ring (`combat.json`
  `telegraph.colour`) on a friendly; the flat catch disc/spikes are `catching.json`'s
  `vfx.caught` impact_flash sized for the resolve close-up; the orb prop; hit/KO reaction
  animation; the catch absorb.
