# Visual Judge — Travel Corridor Composition, Round 2

Blind review of 8 player-height stations along the walked route (village →
South Bridge → Band 2), comparing `00-before` (pre-pass) → `round1` (first
mid-ground pass) → `round2` (fix pass targeting round 1's regressions at
stations 02 and 07, plus horizon mass at 04 and 08). Compared against
`tetherbound-meadows-keyart.png` and the Palworld references. No code,
config, or diff was read — frames and pixel-diff masks only, the latter used
purely to locate where geometry changed between rounds, not to interpret it.

## Cross-cutting observation, unchanged from round 1

The canopy material is still broken in every frame of every round. Pale,
semi-translucent, faceted "crumpled paper/glass shard" shapes stand in for
foliage on every tree, at every station, in all three rounds. This is not a
composition problem and no placement fix touches it — it is flagged once
here because it undercuts every placement judgement below the same way it
did in round 1: a station can go from empty to "full of structure" and the
structure added is still made of visibly broken material.

## New finding this round: an unintended change at station 06

Round 2's commit describes touching only stations 02, 07 (regression fixes)
and 04, 08 (added horizon mass). Station 06 was not a stated target — but it
has the single largest frame-to-frame change of the whole set, round1→round2
(measured ~58% of pixels changed, more than either "fixed" station moved).
This matches the round-2 report's own account of the round-1 bug: appending
anchors reshuffles the shared `corridor_fill` RNG stream *corridor-wide*, so
untouched stations can be redecorated as a side effect of fixing others. At
06 that side effect reads as a **regression**: in before/round1, the right
side of frame held a moderate, readable tree line at mid-distance with open
sky above it and the trail signpost legible past the near foreground trunks.
In round2, that same right side is now a close, dense wall of trunks crowding
right up to the path, burying the mid-distance tree line behind near-camera
bark and cutting the horizon read down to slivers of canopy between trunks.
The signpost that was previously in frame is no longer visible. Station 06
was the strongest "flanked, unblocked, readable" frame in round 1's report;
round 2 has made it busier and shallower without anyone asking it to change.

## Per-station findings

### 01 — village-edge-day
**Before:** real structure already — rock-topped hill with a small tree
cluster on the horizon dead ahead, tree line continuing right past the fence.
**Round 1:** a small tree cluster added behind the left boulder, mostly
occluded by the foreground tree — minor, near-zero sightline effect.
**Round 2:** visually identical to round 1 at this station; no further
change, none needed.
**Verdict:** unchanged r1→r2, no worse than before. **Top remaining defect:**
none composition-related; canopy material as usual.

### 02 — first-bend-day — **round 1 regression, round 2 partially restores it**
**Before:** a real tree grove sat on the left horizon (roughly the left
third of frame), balancing the grove on the right — both sides of the
sightline had mass.
**Round 1:** that left grove vanished, leaving one thin sapling and open
grass-to-sky across the entire left half — the textbook failure this pass
was meant to remove.
**Round 2:** a diff mask against round 1 confirms new geometry: a compact
copse of ~4 small trees plus two rounded bushes now sits at roughly the
20–30% mark from the left edge, with two more small saplings further right
of it, at mid-distance (further back than the before grove was).
**Better or worse than before:** improved over round 1, but **not fully
restored to before**. The before grove was denser, wider, and closer; the
round-2 copse is smaller, more compact, and sits further from camera, so the
left horizon reads as "something is there" rather than the balanced,
tree-lined-both-sides frame the before shot had. The right grove is
untouched and still dominant, so the frame remains left-light relative to
right.
**Top remaining defect:** left/right mass asymmetry — right grove still
outweighs the new left copse by a wide margin.

### 03 — loop-apex-day
**Before/round1/round2: unchanged.** Two close foreground trunks flank the
path on the right, a continuous tree/rock line runs the horizon; no
empty-sky problem in any round.
**Verdict:** stable, no regression, no improvement needed. **Top remaining
defect:** the near-camera trunk bark stretches visibly at this close range —
a texture artefact, not a placement issue.

### 04 — eastward-swing-day — **the clearest genuine improvement this round**
**Before:** a dense grove stood directly in the walked path, blocking the
route and the horizon.
**Round 1:** grove pulled off-route to the right; path opens to a hill crest
and rock landmark, but the left flank was thin — small saplings only, gaps
of open sky between them (round 1's own noted weak point).
**Round 2:** a diff mask against round 1 confirms new solid tree shapes
(two mid-size trees plus two small saplings) added on the horizon left of the
path's vanishing point, filling the gap round 1 left open. The right flank's
grove is untouched.
**Verdict:** **improved, and now the strongest "compression → reveal →
landmark" beat in the set.** Both flanks now carry real mass, the center
stays open down to the crest, and the two blue creature silhouettes in the
left midground still read as a lived-in touch.
**Top remaining defect:** canopy material breaks the reveal the moment the
right-side grove fills any real portion of frame.

### 05 — south-bridge-day
**Before/round1/round2: essentially unchanged**, aside from cloud/foliage
shader jitter and a small creature at lower right. Already the best-composed
station in the set across all three rounds: trunks frame both sides of the
path, a stone stair landmark sits mid-distance directly on the route, hill
and tree line close the horizon.
**Verdict:** stable, still the strongest station. **Top remaining defect:**
none compositional.

### 06 — stone-root-entry-day — **new regression, not requested by this pass**
See "New finding this round" above.
**Before:** dark, dense grove flanks the path on the left with a signpost at
path edge; tree line closes the horizon behind a second walking figure ahead
on the path; readable mid-distance right side.
**Round 1:** unchanged from before.
**Round 2:** right side now crowds close to the path with a wall of near
trunks, burying the mid-distance tree line and the signpost.
**Verdict:** **worse than both before and round 1** — the only station in the
set where round 2 is a net regression against its own predecessor.
**Top remaining defect:** loss of horizon read on the right, an unintended
side effect of the RNG-stream fix applied elsewhere.

### 07 — band2-mid-day — **round 1's worst regression, round 2 restores and reshapes it**
**Before:** one large tree canopy occupied the left third of frame at close
mid-distance, giving the hillside real mass.
**Round 1:** that tree gone entirely; only a thin distant sapling remained,
sky occupying over half the frame — the emptiest frame in the whole before/r1
comparison.
**Round 2:** a diff mask against round 1 confirms substantial new geometry:
a hero tree with full canopy now stands right-of-center at mid-distance, a
large dark boulder anchors the right edge, a thin line of small trees
threads the horizon between them, and a small sapling appears at the far
left edge. Grazing sheep remain as the "lived-in" detail.
**Better or worse than before:** **net improvement over both round 1 and
before.** It doesn't reproduce before's exact composition (mass shifted from
near-left to center-right, and a boulder now serves as a genuine landmark
where before had none), but the frame is no longer sky-dominant — it now has
a clear mid-ground anchor and a horizon line the eye can follow across the
whole frame width, which before's single left tree didn't fully provide
either.
**Top remaining defect:** left edge is still thin (one small sapling only) —
the frame reads as anchored right rather than balanced.

### 08 — band2-far-day
**Before/round1/round2: essentially unchanged** — a diff mask against round 1
shows only cloud and grass-shader noise, no structural edit. Already the
strongest landmark frame in the set: rocky ridge dominates the left third at
real scale, two signposts frame the path like a gate, tree grove closes the
right side with a further grove visible past it.
**Verdict:** stable, still the best "landmark" beat in the corridor —
correctly left alone in both passes. **Top remaining defect:** none
compositional; this is the frame closest to the Palworld plateau-landmark
reference in silhouette logic.

## Did round 2 restore and improve the two round-1 regressions?

**Station 07 (the worse of the two): yes, restored and arguably improved.**
It gained a hero tree, a rock landmark, and a horizon line — more structure,
and a more legible "landmark" beat, than the single tree the before frame
had. This is the one unambiguous fix in the round.

**Station 02: improved but not fully restored.** Round 2 put real mass back
on the left horizon (confirmed by diff mask — a copse plus two bushes), but
it is smaller and more distant than the grove that existed before the whole
pass started, and the frame is still right-heavy. Call this "no longer a
regression" rather than "matches before."

**Did anything get worse than 00-before?** Yes — **station 06**, which
neither round 1 nor round 2 intended to touch. It was one of the two or three
strongest frames in the set before this pass began and is now busier and
shallower than it was, a side effect of the shared RNG stream the round-2
report itself names as the root cause of the 02/07 regressions. Fixing 02 and
07 correctly, this round quietly broke a third station that nobody asked to
be broken.

## Three weakest stations, ranked

1. **06 — stone-root-entry-day.** The only station actively worse than its
   own before frame, in this round. A previously well-flanked, readable
   frame with a visible signpost now has a wall of trunks crowding the path's
   right edge and no horizon depth on that side.
2. **02 — first-bend-day.** Still the most asymmetric frame in the set —
   right grove dominant, left copse present but visibly smaller and thinner
   than what stood there before this whole pass started.
3. **07 — band2-mid-day.** The most improved station this round, which is
   exactly why it still ranks here: it went from the emptiest frame in round
   1 to a genuinely composed one, but the left edge is still a single
   sapling and the canopy material is at its most exposed here, filling a
   large, close portion of frame.

## Three biggest gaps vs. the references, ranked

1. **The canopy material itself, every station, every round.** Nothing in
   this rubric's placement criteria — copse density, flanking, landmark
   siting — closes the gap to the key art's saturated, rounded oak canopies
   or to Palworld's convincingly-formed foliage at combat range while every
   tree in the build reads as pale, faceted, semi-transparent shattered
   glass. Station 04, this round's best placement fix, resolves directly into
   this material at the right edge of frame the moment the eye reaches it.
2. **Uneven confidence in mid-ground fixes — restorations read as thinner
   than the thing they're restoring.** Station 02's new left copse and
   station 07's new hero tree are real, but both are smaller, sparser, or
   more distant than the mass they replace or compare against. The pattern
   across two rounds is that fixes under-correct relative to the regression
   they're answering, which matters because the process (shared RNG stream)
   that removes mass at unintended stations is the same process supplying
   the fix — so a "fix" and a "regression" are two faces of the same
   mechanism, not independent operations.
3. **The fix mechanism itself is not scoped to the station it targets.**
   Station 06's new regression is the clearest evidence: a change aimed at
   02, 07, 04 and 08 measurably altered 06, which nobody flagged as needing
   work and which was previously one of the strongest frames in the set. Two
   rounds in, the tool used to compose a corridor is still capable of
   silently decomposing a station nobody touched.

## Does the route read as an authored, leading path through the keyart's world?

**Partially, and unevenly.** Five of eight stations (01, 03, 04, 05, 08) read
as intentional, landmark-anchored beats — 08 in particular is a legitimate
cousin of the Palworld plateau-landmark shot, and 04 now delivers a real
compression-to-reveal sequence with the crest landmark visible at the far
end. But a route is judged by its weakest links as much as its best: station
06 (this round's new failure) breaks the "leading somewhere" read right where
the path enters Stone & Root — the mid-ground swallowed by close trunks reads
as clutter, not a gate. Station 02 still telegraphs asymmetry rather than
design (one side considered, one side not). And every station, strong or
weak, resolves into the same broken canopy material the instant a tree fills
real frame area, which keeps the whole corridor from reading as "finished
world" even where the underlying siting logic is sound. The corridor is
closer to authored than to scatter-tool noise — the clustering, scale
variety, and clearing logic identified in round 1 still hold — but "closer"
is not "there," and this round traded one pair of empty stations for one
newly-cluttered one rather than banking a clean net gain.

## Bar questions

**A. Do these frames read as belonging to the world in
`tetherbound-meadows-keyart.png`?** **No, still.** The composition language —
rolling hills, oak-grove clusters, path-as-gate signposts, ridge landmarks —
is aimed correctly and is closer to landing than round 1 at stations 04 and
07. But the key art's saturation, warm-cool shadow contrast, and rounded,
volumetric canopy silhouettes have no counterpart here: foliage is uniformly
pale mint-white regardless of station, shadows are flat, and the faceted
canopy material is a constant reminder this is unfinished art in front of a
finished-looking terrain base.

**B. Shown these frames beside the Palworld references, would someone say
these are trying to be the same kind of game?** **No, not yet, but closer at
the strong stations than in round 1.** Station 08's ridge-and-signpost gate
and station 04's new compression/reveal are legitimate cousins of the
Palworld open-field-path and plateau-landmark shots in silhouette and beat
structure. But Palworld's ground and foliage hold convincing density and
form at every distance band including close up; here the ground-flower
density is genuinely good up close (unchanged strength from round 1) while
the canopy breaks the illusion the instant a tree fills real frame area —
which is constantly, since trees remain the primary device solving the
emptiness problem station by station.

## Fixable by scene vs. needs new art

**Fixable by scene (placement/scatter, no new assets):**
- Investigate and fix station 06's new right-side crowding — this is the
  single most actionable finding in this round, the same class of bug
  (shared RNG stream reshuffling an untouched station) that caused round 1's
  02/07 regressions, now recurring at a third station.
- Thicken station 02's left copse further — it is real now, but still
  visibly smaller than the before grove and than the right grove it should
  balance.
- Thicken station 07's left edge to match its new right-side mass (hero tree
  + boulder) — currently one sapling against a real landmark cluster.
- Nothing needs to be added to 01, 03, 05, 08 — leave them alone, they are
  stable and correctly composed.

**Needs new art / a shader-level fix, not a scene-composition fix:**
- The tree canopy material. Two rounds of placement work have not moved this
  gap at all — it is orthogonal to where trees are put and sits above every
  other finding in this report. No amount of correctly-sited scatter closes
  the distance to the key art or to Palworld while the canopy itself reads
  as a rendering defect rather than foliage.
