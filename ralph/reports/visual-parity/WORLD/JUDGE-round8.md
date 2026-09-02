# Visual Judge — WORLD round8 (sky / light / atmosphere)

Blind comparison of round7 (PREVIOUS) vs round8 (NEW) stands, judged against
`docs/reference/tetherbound-meadows-keyart.png` (DAWN panel) and
`site/img/page-board.jpg`. Measurements below are pixel statistics I computed
directly from the PNGs (960×540), not estimates.

## Question 1 — Sun disc containment (01-spawn-outward-golden, 03-rise-overlook-golden)

Method: brightness = R+G+B per pixel; found the connected bright blob around
the frame-max pixel at a tight threshold (max−30, i.e. the hard core) and
again at a looser threshold (≥500/765, i.e. core+immediate glow) to see
whether the halo stays contained or bleeds into the cloud layer. Height
reported as % of the 540px frame height.

**01-spawn-outward-golden**
- Tight core (max−30): PREVIOUS 13px = 2.41% · NEW 13px = 2.41% (unchanged — the
  hard disc itself was already small).
- Loose halo (≥500 brightness, where glow meets bright cloud): PREVIOUS bbox
  y[0,66] x[531,944] → **67px = 12.41%**, and the halo bleeds sideways across
  **413px (43% of frame width)**, fusing with the cloud bank. NEW: bbox
  y[0,12] x[681,700] → **13px = 2.41%**, identical to the tight-core box — at
  round8 the glow no longer merges with the clouds at all, at any threshold
  tested (500/550/max−30 all return the same 13px box).
- Verdict for 01: disc is contained (≤3% target met, and stays met across
  every threshold instead of only the strictest one), soft glow is present
  but no longer eating the sky. Golden mood check: sky (RGB 155,145,132) and
  mid-ground (RGB 37,29,1) tone in NEW are within a few RGB points of
  PREVIOUS's own sky/ground (150,142,131 / 41,32,1) — the warmth was not lost
  chasing the fix, only the halo shrank.

**03-rise-overlook-golden**
- Tight core: PREVIOUS 1px (barely resolvable) · NEW 5px = 0.93%.
- Loose halo (≥500): PREVIOUS bbox y[13,38] x[533,743] → 26px = **4.81%**,
  210px wide (22% of frame). NEW: bbox y[0,6] x[574,604] → 7px = **1.30%**,
  30px wide — again identical to its own tight-core box.
- Verdict for 03: contained, well under the 3% target, soft glow present,
  golden mood preserved (sky 160/148/133 vs PREVIOUS 159/147/132; ground
  69/47/14 vs PREVIOUS 73/50/15).

**Q1 — PROVEN.** In PREVIOUS the sun's glow was not a contained disc at all —
at a realistic "where does the light visibly stop" threshold it filled
7–12% of frame height and up to ~43% of frame width, fusing with the cloud
bank. In NEW the same threshold sweep returns the same small box the hard
core does (≤2.4% at both stands, at every threshold tried), meaning the halo
now has a real edge instead of blooming outward. Golden hour mood (sky/ground
hue and value away from the disc itself) is statistically unchanged, so the
fix did not cost warmth. As a side effect (not asked, but relevant to the
regression sweep below), the same bloom containment shows up at
06-moon-stand-night: PREVIOUS moon halo 9.8% vs NEW 2.4%, same pattern.

## Question 2 — Dawn ground tint (01-spawn-outward-dawn, 03-rise-overlook-dawn)

Sampled a sky patch and one or two ground patches per frame (mean RGB, R−G as
the orange-cast indicator — the DAWN reference panel's own foreground grass
measures R−G ≈ 23 with sky R−G ≈ 76, i.e. the *sky* should carry most of the
saturation and the ground should stay comparatively close to neutral/green).

**01-spawn-outward-dawn**
- sky_upper: PREVIOUS (104,74,81) R−G=30.5 · NEW (109,79,84) R−G=30.7 — sky
  essentially unchanged, still pink-gold as intended.
- ground_far_hill (the only lit ground patch in this stand): PREVIOUS
  (72,41,20) R−G=31.5 · NEW (71,46,21) R−G=25.7 — orange cast down ~18%, G
  channel up from 41 to 46. Close to the reference ground's own R−G≈23.
- ground_mid (near-camera grass, in shadow): PREVIOUS (7.4,6.9,0.4) R−G=0.5 ·
  NEW (5.8,7.4,0.4) R−G=**−1.6** (G now exceeds R). This patch is too dark in
  both builds to read hue meaningfully either way — it's crushed near-black,
  not orange-washed, but also not showing "its own local colour" the way the
  reference's lit grass does. Not a regression, just unresolved by this pass.

**03-rise-overlook-dawn** — this is the stand the question calls out, and
it's the one that still fails it.
- sky_upper: PREVIOUS (110,76,80) R−G=34.5 · NEW (112,78,82) R−G=33.9 — sky
  unchanged, correctly saturated.
- ground_near (foreground rock/moss slope): PREVIOUS (33,17,3) R−G=15.5 · NEW
  (31,24,7) R−G=**7.3** — orange cast cut by more than half, G channel up
  37%. Real, visible improvement here.
- ground_mid (the fog-plain that fills most of the frame to the horizon):
  PREVIOUS (142,73,44) R−G=69.1 · NEW (142,83,54) R−G=**58.8** — only a ~15%
  reduction, and it **still reads as an orange plain by eye** (see the two
  full-res frames — they are close to indistinguishable at a glance). Worse,
  this patch's R−G (58.8) now *exceeds* the sky's own R−G (33.9), i.e. the
  ground is more saturated-orange than the sky sitting above it — backwards
  from the reference relationship, where the sky (R−G≈76) is far more
  saturated than the ground (R−G≈23) it sits over.

**Q2 — PARTIAL.** The fix measurably works where it was applied — both
foreground/near-camera ground patches (01's lit hillside, 03's foreground
slope) dropped their orange cast 18–53% and gained real green back, in line
with the reference's own ground R−G. But the dominant terrain in
03-rise-overlook-dawn — the plain that fills the majority of that frame —
only improved ~15% and remains visibly orange-washed, still more saturated
than the sky itself. Anyone looking at 03-rise-overlook-dawn today would
still describe it the same way the question does: "the whole terrain is
washed orange." The near-camera patch in 01 is too dark in both builds to
judge hue at all.

## Regression sweep (all 9 stands)

Pixel-diffed every PREVIOUS/NEW pair; day and night included.

- **01/03 day**: mean diff ~9–11 (small global grading shift only); visually
  green grass and blue sky read correctly in NEW, no orange bleed, no new
  artifacts. The single largest per-pixel diff (507) is at a small tree
  silhouette (y≈170–176, x<20/120/338 in 01-day) — consistent with
  foliage-sway animation phase between two separate captures, not a lighting
  defect; affects 105 px total out of 518,400.
- **01/03 night**: mean diff ~2–2.8, smallest of the set — night lighting is
  effectively untouched. No new banding, no seams.
- **06-moon-stand-night**: moon halo tightened the same way the sun's did
  (9.8%→2.4% at the loose threshold) with no loss of the "full moon" read —
  still a clean, soft-edged disc, not a hard cutout.
- No z-fighting, texture stretching, popping, or chunk seams observed in any
  of the 9 NEW frames.
- The blotchy/noisy dark-cloud texture in the three night skies (01-night,
  03-night, 06-moon-night) is present identically in PREVIOUS — pre-existing,
  not introduced this round.

**Regressions: none observed.**

## Score — sky/light/atmosphere vs. reference art

**6.5/10.** The bloom-containment work is a clean, complete win — the sun and
moon are now genuinely disc-shaped light sources with a real edge, matching
how the DAWN panel's sun sits as a defined orb rather than a blown-out patch,
and it cost nothing in golden-hour mood. But the second, arguably more
visible ask — grass reading as itself, cool and green, under a warm sky
rather than dyed by it — is only half done: it's fixed exactly where the
near-camera ground was sampled and unfixed on the large mid-distance plain
that actually dominates 03-rise-overlook-dawn's composition, which is the
frame most likely to be judged against the DAWN panel's rolling green
hillside.

## Verdict

**NEXT ROUND.** Ranked remaining defects:

1. **03-rise-overlook-dawn mid/far terrain still orange-washed and now more
   saturated than its own sky** (ground R−G 58.8 vs sky R−G 33.9 — backwards
   from the reference's sky-dominates-saturation relationship). This is the
   dominant surface in the frame and the one the question named directly.
   Fixable in-scene: extend whatever desaturated the near-camera ground
   material/lighting term to the mid-distance terrain shader/fog tint too —
   the fix clearly exists and works nearby, it just isn't reaching this
   range.
2. **01-spawn-outward-dawn near-camera grass is crushed too dark to show any
   colour**, orange or green — can't confirm the "keeps its own local
   colour" half of the ask because there's no visible colour there at all.
   Fixable in-scene: raise dawn ambient/exposure enough for foreground grass
   to read as grass rather than silhouette.
3. Minor: the tight-threshold sun/moon core numbers (2.4%, 0.9%) are already
   well under the 3% target with margin to spare — if anything there's room
   to soften the glow radius slightly for a more "soft" (vs. hard-edged)
   look without risking re-bleeding into the clouds, since the loose-vs-tight
   threshold boxes are now identical (i.e. the glow falloff is currently very
   steep). Not a defect, just headroom noted for polish.
