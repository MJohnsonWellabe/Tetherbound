# Visual Judge — WORLD round7 vs round6

Method: viewed `_sheet_r6_vs_r7.png`, all 9 full-resolution round6/round7 frame pairs, both
reference boards (`docs/reference/tetherbound-meadows-keyart.png`,
`site/img/page-board.jpg`), and pixel-sampled the sky/horizon regions in the golden and
night frames to check size/darkness claims a still image can mislead the eye on.

## Targeted questions

**1. Low sun at golden/dawn — contained disc, ≤3% frame height?**
**PARTIAL.** At `01-spawn-outward-golden`, round6's sun was a blown-out oval: near-white
core bbox ~146px wide × 73px tall (13.5% of the 540px frame height), 8,148 near-white
pixels. round7's sun is a genuine disc with a soft gradient glow blending into the warm
sky rather than a hard-edged blob — but the near-white core still measures ~62×40px
(7.4% of frame height), roughly 2–3× the ≤3% target, and the total soft-glow halo around
it is larger still. At `03-rise-overlook-golden` the improvement is much further along:
round6 had a 10.4%-height blown core (4,965 near-white px); round7 has essentially none
(1 pixel above the near-white threshold) — the sun there reads as ambient warm haze in
the high clouds rather than a disc at all. So: real, large improvement at both stands,
target met at one of the two, not the other.

**2. Dawn reads as saturated pink-gold vs. reference?**
**PROVEN.** Sampled the sky band (y=10–60) at `01-spawn-outward-dawn`: round6 averages
RGB(117,110,121), HSV saturation 0.09, hue ≈275° (a near-grey lavender-tan — matches the
"desaturated tan/dust under grey sky" description). round7 averages RGB(108,77,83),
saturation 0.29 (>3× round6), hue ≈348° (magenta-pink). Visually, round7's sky at both
`01-spawn-outward-dawn` and `03-rise-overlook-dawn` is a smooth pink-to-rust-orange
gradient with no banding, close in character to the pink/orange/purple sunset-sky panel
in `tetherbound-meadows-keyart.png`. round6 is clearly the desaturated grey-tan version;
round7 is clearly closer to the reference.

**3. Night horizon seam gone?**
**PROVEN.** Pixel-sampled the horizon row across the full frame width at both
`03-rise-overlook-night` and `06-moon-stand-night`. round6: every sampled column drops to
near-pure-black (RGB sums of 3–12, e.g. (0,0,9)) in a band right at the horizon — a hard
seam. round7: the same columns never go below dim navy blue (RGB sums of ~140–215, e.g.
(38,61,100)) — there is a visible dark band where sky meets ground (expected, terrain
silhouette) but no true black cutoff anywhere along the horizon in either frame.

**4. Night depth — far ground darker/bluer than near ground at 03-rise-overlook-night?**
**NOT PROVEN as stated (partial credit on "bluer" only).** Sampled a vertical strip from
the far plain (y≈160, near the horizon) down to the near foreground (y≈530) at several x
columns. Far ground is indeed the bluer of the two (B/R ratio ~1.9–2.0 far vs. ~1.5–1.6
near) — but it is also brighter, not darker, than the near foreground (far ≈ RGB(75-90,
105-120,150-165); near ≈ RGB(30-50,45-60,20-75), noticeably dimmer and warmer). So the
frame does have far/near separation, but via the far plain washing out lighter/bluer into
haze while the foreground sits in shadow — the opposite direction from "far ground sits
darker." Also worth flagging: this specific relationship is numerically unchanged between
round6 and round7 (matched sample columns differ by <2 RGB units) — whatever produces it
was already present before this round, it is not something round7 changed.

## Regression sweep

**None observed.** Pixel-diffed the unaffected-looking stands to confirm the eye wasn't
missing something small: `01-spawn-outward-day` mean diff 2.1/255, `01-spawn-outward-night`
mean diff 1.0/255, `03-rise-overlook-day` mean diff 1.7/255 — all consistent with cloud/
noise jitter, not a rendering change. Visual inspection of all four day frames, both
night frames, and the moon stand found no new banding, haloing, clipped highlights, color
casts, lost terrain/vegetation detail, or cloud-shape degradation versus round6. The
golden-hour ground/vegetation tone at both stands is unchanged from round6 — only the sky/
sun rendering differs.

## Rubric verdict

Top defects remaining, ranked:

1. **Golden-hour sun core at `01-spawn-outward-golden` is still ~2-3× the target size**
   (7.4% vs. ≤3% frame height) — much improved from round6's 13.5%, but still reads as a
   soft light blob rather than a small solar disc when compared at native resolution.
2. **Night "far ground darker than near" cue is not implemented** (and unchanged from
   round6) — the far plain currently reads lighter/bluer while the near foreground reads
   darker, the reverse of the intended cue, at `03-rise-overlook-night`.
3. **Sun rendering is inconsistent between the two golden stands** — `01-spawn-outward-
   golden` still shows a visible disc while `03-rise-overlook-golden` shows essentially no
   disc at all (near-white pixel count of 1), so the "low sun" motif doesn't read the same
   way twice in the same round.

**MERGE / NEXT ROUND: MERGE.** The two largest previously-flagged defects (desaturated
dawn, hard-black night horizon seam) are both proven fixed with quantified evidence and no
regressions were found anywhere in the sweep; the residual sun-disc oversizing at one
stand is a real but much-diminished cosmetic gap, not a blocker. Ranked follow-ups for the
next round: (1) tighten the `01-spawn-outward-golden` sun core further toward ≤3%, (2)
make sun rendering consistent between the two golden-hour stands, (3) reconsider the
far/near night ground darkening cue if that atmospheric read is still wanted.
