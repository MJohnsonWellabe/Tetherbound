# Visual Parity Judgment — Round 8 (Meadows PLACES)

Blind review. No code, diffs, or prior round prose was read. Compared only: the rubric,
`docs/reference/tetherbound-meadows-keyart.png`, `docs/reference/palworld-0*.jpg`
(palworld-02 = warren reference), `site/img/page-board.jpg`, and the round7/round8 frames
themselves, at native exposure.

Round7 supplied only 12 of the 31 round8 frames as a baseline (warrens x3, stronghold x6,
castle hall x3). Everything under `relay-camp`, `relay-road/apparatus`, `ridge-camp`, and
`waystop` is new to round8 with no round7 counterpart — those are reported as current-state
only, and the camp frames are judged separately as BEFORES per the brief.

For every "identical-looking" pair I ran a pixel diff to confirm what actually moved
before writing a verdict, rather than trusting a screen-size read. The diffs are noted
below where they change the finding.

## Per-location: r7 → r8

**04-warrens-approach-day / -standing-day / -den-day** — Pixel-diffed against r7: the only
changes are cloud noise, wind-blown grass jitter, and a one-frame shift in the badger
creature's idle pose. Nothing about the built structure moved a single pixel. **No visible
change.** The pale, un-textured light-grey boulder sitting dead-center above the mouth in
`04-warrens-approach-day` is byte-identical between rounds — still there, still reading as a
chalk-white slab dropped into a pile of brown-black boulders. The flat white rectangular
panel on the right wall in `04-warrens-standing-day` (the cave-mouth reverse shot) is also
pixel-identical — still an unlit or unmatched-material card, not rock. Top remaining defect:
these two pale surfaces are the loudest thing in both frames; the mound around them reads
fine as earth, but the eye goes straight to the two flat pale shapes instead of the entrance.

**05/06/08/09 relay + camp locations** — no round7 baseline; see current-state notes below
and the BEFORE ranking.

**10-stronghold-approach-day** — Diffed: cloud/grass noise only, no structural change. Reads
as a recognizable dark castle on a green rise; better than most because the crenellations,
door glow and a hint of window light survive at this range. Remaining top defect: the whole
building is one flat near-black value with almost no midtone — it's a strong silhouette but
zero building.

**10-stronghold-approach-night, courtyard-night, gate-night** — Diffed against r7: noise-level
only, no change. Remaining top defect: unchanged from round7, see night findings below.

**10-stronghold-courtyard-day** — Diffed: noise only. Cobbles, moss and a real cast shadow
from the player read cleanly here — this is the best-lit frame in the set. Top defect: the
right-hand banner pillar geometry reads slightly thin/flat next to the well-modeled wood
scaffold on the left.

**10-stronghold-gate-day** — Highest mean pixel diff of any repeated frame (µ≈21) but the
diff map shows it's entirely grass-blade shimmer and cloud drift, not the castle. Structure
unchanged. Top defect: at the actual gate — the closest vantage point in the whole set — the
walls are still a flat near-black mass; only the vine overlay and the pink door read as
distinct material. No stone coursing, no weathering, no block seams anywhere on the facade.

**11-castle-landmark-hall-100m/200m/400m-day** — Diffed against r7: noise only (grass, cloud,
haze band), the building silhouette is byte-for-byte the same shape at all three distances in
both rounds. **This is a pre-existing, unaddressed condition, not a regression.** At 100 m the
entire hall — towers, walls, roofline — is a single flat black cutout against the sky, with
literally zero internal value or hue variation: no window glow, no stone tone, no vine green.
It reads exactly like an occlusion/backlight silhouette, not a lit building. At 200 m and
400 m it's the same flat black shape, just smaller — which happens to still read as "a castle"
at a glance, but only because it was never anything but a silhouette to begin with.

## Targeted questions

**(A) Relay from the road — is the ground pad and colonnade no longer pale?**
Yes, in the current round8 state (`06-relay-road-day.png`, `06-relay-approach-day.png`,
`06-relay-standing-day.png`, `06-relay-apparatus-day.png`). The dirt path reads as a
believable grey-brown trodden track with visible tonal variation, not a chalk slab, and the
gate/colonnade structure is a dark warm brown-black stone/timber mass consistent with the
rest of the Meadows built palette — no pale card anywhere in these four frames. This is the
one clear win in the set. Minor note: the colonnade posts in `06-relay-apparatus-day` are
lit almost as dark as the hall walls (same flat-black-mass issue at close range), so the win
is "no longer pale," not "now fully modeled" — see the hall finding above, same underlying
cause likely applies here too.

**(B) Warrens — is the pale boulder above the mouth and the right-side pale panel gone? Does
the mound read as earth with a dark mouth?**
No on both counts, and this is the single most direct miss against the brief's own framing
(the brief assumes these are fixed; the pixel diff proves they are not). The light-grey
boulder above the entrance in `04-warrens-approach-day.png` is unchanged from round7 —
pixel-identical. The flat white panel on the right wall in `04-warrens-standing-day.png` is
also unchanged — pixel-identical. Against `palworld-02-open-field-path.jpg` (the named warren
reference), the Palworld cave mouth is a coherent dark rock mass with a readable dark opening
and no stray pale geometry; the Tetherbound warren still has two conspicuously pale, flat
shapes breaking that read. Separately: yes, the mound itself (the boulder pile forming the
hill) does read as earth/rock and the entrance is a legible dark opening — that part is fine
and was fine in round7 too. The defect is specifically the two pale surfaces, not the earth
language.

**(C) Hall at 100 m/gate — does material and weathering read up close now? Does the silhouette
still hold at 200/400 m?**
No to the first question. At both the 100 m vantage and standing at the gate itself (the
closest frame in the set), the hall's walls carry no readable stone material and no
weathering — no block coursing, no cracks, no moss/algae variation, no color range at all
beyond the flat vine-green overlay and the pink door insert. It is functionally a silhouette
at every distance tested, including point-blank. Yes to the second question, but trivially:
the silhouette holds at 200 m and 400 m because it was never more than a silhouette to begin
with, so there's nothing for distance to degrade. This is unchanged from round7 — not a new
problem, but also not fixed.

**(D) Courtyard at night — native exposure, and does the floor around the trainer read?**
The three `night-repeats/run1-3.png` renders are pixel-consistent with each other (same
framing, same lighting state, no flicker or nondeterminism between runs — that part is
solid). But at native exposure the floor directly around and under the trainer is crushed to
near-pure black — no cobble texture, no moss tint, nothing distinguishable from shadow. Floor
only becomes legible in small pools directly under the two lit banners and the lantern on the
right. Compare to `10-stronghold-courtyard-day.png`, where the same floor reads cleanly with
visible stone and moss — this is a night-exposure problem specific to the courtyard interior,
not a modeling problem. `10-stronghold-approach-night.png` and `10-stronghold-gate-night.png`
share the same issue outside the gate: trees, grass and the player's own legs go to flat
black past a few meters from the nearest light source.

**(E) Sentries — is a guard figure identifiable on a tower?**
No. Zoomed crops of both towers in `gate-sentry-2x-crop.png` at native exposure show, on the
right tower, a small red/maroon blob with a thin dark stub next to it (plausibly a banner and
a weapon silhouette, but no legible head/torso/limb shape), and on the left tower, a blue-grey
conical shape with a yellow accent stripe that reads as an architectural finial or spire cap,
not a person. Neither crop produces a silhouette a player could identify as "a guard standing
watch" without already knowing to look for one. Whatever is up there is present but not
legible as a figure.

## Camp BEFOREs — ranked weakest to strongest, with the fix each needs

All three camps in `camps-before/` currently amount to: one thin campfire flame, one or two
generic crates/barrels, and 1-2 NPCs standing in a large empty patch of dirt or grass. None
of them yet reach the "authored little settlement" read of `page-board.jpg`'s FIND YOUR FIVE
strip or the keyart's starting-settlement panel (well, fence, banner, clustered buildings),
and none reach the density of supplies/tents/workstations in
`palworld-05-base-building.jpg`.

**1. Relay camp (weakest)** — `05-relay-camp-fire-day.png` / `-standing-day.png`. A large,
mostly-empty dirt clearing with a flagpole, a single crate, a thin fire off to one side, and
two NPCs standing apart from each other and from the fire — nobody is oriented toward
anything. There is no seating at all near the fire. The only "reason this camp exists" signal
is the flag; strip the flag and this reads as bare dirt. **Fix:** cluster 2-3 more props
(a second crate, a barrel, a bedroll) and the two NPCs around the fire itself, facing it, and
add one seat/log at the fire so the flame has a purpose besides existing.

**2. Ridge camp (middle)** — `08-ridge-camp-fire-day.png` / `-standing-day.png`. Better prop
variety than relay (a lean-to/tent shape, a workbench with a barrel and shield-like disc, a
small stool), but the pieces are scattered rather than clustered: the stool sits several
meters from the fire, the workbench is off to the side, and nothing forms a ring or working
area around the flame. Reads as "props were placed near each other" rather than "someone
lives here." **Fix:** pull the stool and workbench into the fire's radius so there is one
coherent seating/working cluster instead of three unrelated islands.

**3. Waystop (least weak)** — `09-waystop-bench-day.png` / `-standing-day.png`. This is the
only one of the three with real environmental storytelling: it sits directly on the road with
the stronghold silhouette visible in the background, has a tent, a fire, a plank/log bench,
and a dead accent tree, plus taller cattail/reed dressing that differentiates it from the
surrounding grass. It still under-delivers on supplies (no crates, no visible reason a
traveler stopped here beyond the tent) and the fire is the same thin, undersized flame column
as the other two camps. **Fix:** add one or two supply props (a pack, a cooking pot, firewood
stack) near the existing bench so the "reason to stop" reads as more than a tent silhouette.

All three share one fix that would raise the floor everywhere at once: the campfire itself is
a narrow vertical flame with no visible logs, stones, or fire-pit geometry in any of the
fifteen frames — it reads as a particle effect standing in grass, not a fire someone built.

## Ranked: the three biggest remaining gaps against the references

1. **The castle hall has no material at any distance, including point-blank.** Against the
   keyart's Team Tether stronghold panel — weathered stone, visible vines, banners with clear
   fabric shading, a lit doorway with real depth — the in-game hall (`11-castle-landmark-hall-
   100m-day.png`, `10-stronghold-gate-day.png`) is a flat black cutout with a green overlay and
   a pink doorway insert pasted on. This is a silhouette standing in for a building, not a
   building with a strong silhouette. Not fixable by scene tuning alone if the underlying issue
   is the mesh/material being effectively unlit at these light angles — this needs an actual
   lighting or material investigation, not just an exposure slider, since the courtyard interior
   goes bright and readable a few meters through the same door.

2. **Two pale, flat, un-integrated surfaces still sit on the warrens' entrance,** unchanged
   since round7 (`04-warrens-approach-day.png`, `04-warrens-standing-day.png`). Against
   `palworld-02-open-field-path.jpg`, the named reference for this exact location, Palworld's
   cave mouth commits fully to one dark rock language with no stray bright geometry. This is
   fixable by scene work — retexture or recolor the two flagged surfaces to match the
   surrounding boulder material — but it has now gone at least two rounds unaddressed despite
   being called out.

3. **None of the three camps yet look "authored" against `palworld-05-base-building.jpg`.**
   Palworld's base has dense, functionally clustered props — workbenches, storage, decoration —
   all oriented around what a base is for. The Meadows camps have the right prop *types* (fire,
   tent, crate, bench) but not the *clustering*: seating sits away from fire, supplies are
   single instances instead of small piles, and the campfire itself has no pit geometry in any
   frame. This is entirely fixable by scene composition — no new art is needed, only rearranging
   and adding 2-3 existing prop instances per camp.

Runner-up, not in the top three only because it's a smaller-scope fix: night interiors
(courtyard, gate, approach) crush the ground plane to black around the player in every one of
the six night frames checked, including all three deterministic `night-repeats` runs — fixable
by raising ambient/fill light near the player's own position rather than only at fixed prop
lights.

## Bar questions

**A. Do these frames read as belonging to the world in `tetherbound-meadows-keyart.png`?**
**No.** The open-field frames (warrens approach, relay road, ridge/waystop approaches) come
reasonably close — green rolling grass, oak-type trees, a natural palette matching the
keyart's five ground-tier greens. But the keyart's two most load-bearing panels — the
stronghold (weathered stone, visible arch, red banners with real fabric read, warm lit
windows) and the starting settlement (clustered, purposeful build-up) — are the two places
these frames diverge hardest: the hall is a black cutout instead of weathered stone, and the
camps are three scattered props instead of a settlement. The palette matches; the built-up,
authored density the keyart sells does not, yet, in the frames that most need to sell it.

**B. Shown these frames beside `palworld-0*.jpg`, would someone say these are trying to be the
same kind of game?**
**No, not yet, though closer than the ground layer alone would suggest.** The terrain density,
creature presence (the ridge-camp approach frame's badger/hawk cluster is a genuine bright
spot — multiple distinct creatures with plausible scale relative to the trainer, echoing
`palworld-04-plateau-landmark.jpg`), and grass/flower coverage are in the right family. What
breaks the comparison is structure and camp density: nothing in the Palworld shots is ever a
flat black cutout the way the hall is at every range tested, and Palworld's base-building
reference has real prop density where the Meadows camps currently have three or four scattered
items in open grass. The gap here is fixable — it's composition and lighting, not missing art
— but as shot, a side-by-side would read as "same palette, earlier stage of the same game,"
not yet "the same kind of game" on the two frames (hall, camps) doing the most work to prove it.
