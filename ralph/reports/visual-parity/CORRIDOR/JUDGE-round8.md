# Corridor Round 8 — Visual Judge

Blind review of three re-rendered corridor stations (round 7 → round 8), scored against
`docs/reference/tetherbound-meadows-keyart.png` and `docs/reference/palworld-0*.jpg`.
Sheet reviewed: `ralph/reports/visual-parity/CORRIDOR/round8/_sheet_prev_vs_r8.png`, plus
full-resolution frames and pixel crops of each station.

## Station 07 — band2-mid-day

**PASS.**

- PREVIOUS: nearest trees sit well back from the player, mid-ground only. The area
  immediately around and beside the path is open — foreground is empty dirt/grass.
- NEW: a real close foreground clump now exists, right of the path, roughly 6–10 m from
  the player — a tall canopy tree plus two smaller trees clustered together, trunks
  visible at the base with grounded shadow, canopy filling the upper-right quadrant of
  the frame. This gives a genuine foreground/path/background composition that PREVIOUS
  lacked: near tree mass → open path with the player → the same distant tree line and
  rock/creature silhouettes on the horizon that PREVIOUS already had.
- Scale check: trunk width and canopy height read as plausible against the player (a
  large oak-class tree, several times the player's 1.8 m) — no violation.
- This is the single clearest win of the round and the shot that most now resembles the
  Palworld framing (`palworld-02-open-field-path.jpg`: near tree mass at frame edge,
  open path down the middle, mid-ground incident/landmark beyond).

## Station 13 — band4-entry-bend-day

**PARTIAL.**

- The tree cluster left-of-center is denser and reads better than PREVIOUS (more
  trunks, tighter grouping, less gap between individual trees).
- The right side of the frame is **not** filled to the edge. Pixel-scanned the canopy
  band (y≈300): the rightmost tree/foliage pixel in NEW sits at x≈946 of 1280. That
  leaves **≈334 px (≈26% of frame width)** of bare sky-over-grass at the extreme right,
  broken only by a faint, indistinct tree line on the far hill silhouette — nothing that
  reads as "filled" at normal viewing size. A rock/boulder cluster with a green plant
  sits at the edge of the tree group (x≈780–950) but does not extend the mass rightward.
- Net effect: the frame still reads as "trees on the left, empty sky/grass on the
  right" rather than trees bracketing both sides of the bend, which is what the station
  name ("entry bend") implies it should be doing.

## Station 14 — ridge-camp-approach-day

**PARTIAL.**

This is a re-sited stand, not a direct crop change, so it is judged as a new
composition rather than against round 7's very different (signpost + captain) framing.

Elements actually visible, located by approximate frame position (1280×720):

- **Crate/supply pile** — yes, clearly visible, center-right (~x 600–650, y 350–400):
  a stacked brown crate/box cluster.
- **Fire (glow)** — yes, an orange glow sits immediately right of the crates (~x
  655–680, y 360–390), read as a campfire at this distance.
- **Tent** — yes, a tan/brown A-frame tent sits further right (~x 700–780, y 350–390).
- **A humanoid figure** — yes, standing on/behind the crates (~x 615–635, y 340–370),
  dark/purple-toned clothing consistent with a Team Tether grunt silhouette. At this
  render distance the figure is heavily aliased (roughly 15×25 px before upscaling) —
  identifiable as a person, not confidently identifiable as *specifically* a Team Tether
  grunt from silhouette alone. Treat as "a figure at the camp," not confirmed grunt,
  without a closer-range frame.
- **Log seats** — not found. No log/seat silhouettes near the fire in the crop.
- **Signpost** — not found anywhere in frame (checked both left tree-line area and the
  full frame; nothing post-and-plank shaped).
- **Second NPC / captain** — not found. The only other frame occupant is a distant wild
  creature (blue/teal, winged) near the tree line at the right edge of frame (~x
  1020–1080, y 340–380) — a wildlife silhouette, not a captain NPC.

Composition: player is bottom-center as expected, the camp cluster sits just
right-of-center in the middle distance and reads as a single coherent group (crates →
fire → tent, left to right) rather than scattered props — that part works. But the camp
is small in frame (roughly 80×50 px of camp footprint against a 1280×720 frame) and sits
on a fairly flat, feature-poor grass slope with no supporting landmark (no ridge rock,
no silhouette break) to anchor it — it reads as a small huddle of brown/tan shapes on an
otherwise empty green hillside rather than a "camp you're approaching." Nothing is
clipped or obviously broken, but the camp under-fills the frame compared to what
"ridge-camp-approach" promises, and round 7's version — while a different, wrong
composition (signpost + captain, no camp) — at least had a stronger near-field tree mass
on the right that this new siting has traded away.

## Regression sweep (all three stations)

- **No sky/cloud regressions** — cloud shapes and blue gradient are consistent with
  round 7 and with each other across all three frames.
- **No new geometry artifacts observed** — tree trunks meet the ground with shadow in
  all three stations; no floating props, no visible seams or z-fighting in the crops
  examined.
- **Persisting (not new) ground-shading defect**: in all three stations the grass
  texture shows blotchy, hard-edged dark patches (baked AO or terrain-blend seams)
  that read as dirty/mottled rather than as soft ambient shadow. This is present in
  both PREVIOUS and NEW at all three stations — unchanged by round 8, not a regression,
  but still an open defect worth naming since it recurs in every frame reviewed.
- **Tree style is unchanged and still flat-faceted**: canopies are built from
  clearly-quantized flat leaf-cluster facets (visible faceting, especially in the
  station 07 foreground clump where the new trees are close enough to see it plainly).
  This was already true in round 7's trees; round 8 just brought more of the same
  geometry closer to camera, which makes the faceting more visible than before, not
  less — worth flagging as a side effect of station 07's win rather than a new defect.
- Station 13's right-side gap and station 14's missing signpost/second-NPC/log-seats
  are treated above as PARTIAL findings, not regressions, since no prior round had them
  either.

## Overall

Round 8 fixes the one thing it clearly targeted (07's foreground clump) convincingly,
makes partial, insufficient progress on 13 (right side still ~26% empty), and re-sites
14 into a smaller, less-anchored composition that gains a real camp readout but drops
several of the callout's requested elements (no signpost, no second NPC/captain, no log
seats, and the figure present cannot be confidently confirmed as a grunt from this
distance). Overall corridor evidence for this round: **improved but not passing** — one
solid win, two stations still short of the ask.

**A. Do these frames read as belonging to `tetherbound-meadows-keyart.png`'s world?**
**Partial / lean yes on palette, no on polish.** The green/gold meadow palette, blue sky,
and tree-cluster landmark language match the keyart's Meadows swatches and composition
intent (foreground tree mass, open path, distant landmark). What keeps it from a clean
yes is texture/shading quality: the keyart's canopies are soft, volumetric, and
continuously toned; these frames' canopies are visibly flat-faceted low-poly shapes, and
the ground has the blotchy AO patches noted above. Station 07 is the closest match in
the set to the keyart's "path through a tree stand" panel; 13 and 14 are thinner and
flatter than any keyart panel.

**B. Beside `palworld-0*.jpg`, would someone say these are trying to be the same kind of
game?** **Partial — closer than before, still no on density.** Station 07's new
foreground clump is the first frame in this set that reads like
`palworld-02-open-field-path.jpg`'s "near trees bracket the path" framing. But ground
foliage density remains thinner than every Palworld reference (Palworld's grass/flower
scatter is continuous; these frames have visible bare-dirt gaps between clumps), tree
canopies read flatter/more faceted than Palworld's rounded, painterly foliage, and
station 13/14 both still have large empty sky or empty-hillside stretches Palworld
reference frames don't carry. Fixable by scene work (more scatter density, close
foliage on 13's right side, a stronger landmark or near-tree mass anchoring 14's camp);
the canopy-faceting gap is a tree-asset/shader quality question, not a placement one.

## Ranked remaining defects

1. **Station 13's right side is still ~26% empty (≈334 px of 1280) sky/grass** — the
   callout's core ask ("filled toward the right edge") is not met; needs tree/foliage
   placement extending further right, not just a denser left cluster.
2. **Station 14's camp is under-scaled and under-anchored in frame** — no signpost, no
   second NPC/captain, no log seats, and the one figure present is too small/aliased at
   this camera distance to read confidently as a grunt. Needs either a closer stand, a
   bigger/taller camp silhouette, or the missing set-dressing (signpost, log seats,
   second NPC) actually placed.
3. **Flat-faceted tree canopy style, now more visible at close range (station 07)** —
   not new, but round 8's own win exposes it more: closer trees make the quantized
   leaf-cluster faceting more noticeable against Palworld's rounded, continuously-shaded
   canopies. A scene-only fix (placement) won't close this gap; it needs asset/shader
   work on the tree canopy itself.

## Recommendation

**NEXT ROUND** — station 07 is done; fix 13's right-side coverage and either re-anchor
or re-dress 14's camp (signpost, second NPC, log seats, or a bigger/closer siting)
before merging the corridor route.
