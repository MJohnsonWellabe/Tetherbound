# Visual Judge — Travel Corridor Composition, Round 1

Blind review of 8 player-height stations along the walked route, before vs.
after a mid-ground pass. Compared against `tetherbound-meadows-keyart.png`
and the two Palworld references. No code, config, or diff was read — this is
frames only.

## Cross-cutting observation before the per-station notes

Every one of the 16 frames — before and after, all 8 stations — shares one
defect that outweighs anything the mid-ground pass changed: the tree canopies
render as pale, semi-translucent, faceted "crumpled paper" shapes (hardest to
miss at station 03, where two trunks fill the right third of frame and the
canopy above them reads as glass shards, not leaves). This is not a stylistic
choice reachable from the key art's saturated, rounded oak canopies — it reads
as a shader/material bug. Any scene-composition fix (more trees, better
placement) is being executed in this material, so it is worth naming once,
up front, rather than repeating at every station: adding more of this canopy
does not, by itself, make the corridor look more "designed," because the
added mass reads the same slightly-broken way as the mass already there.

## Per-station findings

### 01 — village-edge-day
**Before:** already has real structure — a rock-topped hill with a small tree
cluster sits on the horizon directly ahead, and a tree line continues right of
it past the fence. Not an empty-corridor frame.
**After:** a small tree cluster was added behind the boulder at left-of-frame,
partly visible past the hero foreground tree's trunk. It is a real addition
(confirmed by crop diff) but a minor one — mostly occluded by the existing
foreground tree, so its practical effect on the sightline is close to zero.
**Still reads empty/procedural:** nothing new here; this was already the
strongest station in the before set.
**Path:** clear both before and after; fence rails run alongside the path,
not across it.

### 02 — first-bend-day — **regression**
**Before:** a tree grove sat on the *left* horizon (roughly the left third of
frame), balancing the grove already on the right and giving the sightline
structure on both sides of the path.
**After:** that left grove is gone. In its place is one small, thin sapling
far off on the horizon and otherwise open grass straight to sky. The right
grove is untouched. The frame now reads as textbook "player → empty grass →
sky" on its entire left half — the exact failure this pass was supposed to
remove, and it is worse here than in the before frame.
**Path:** clear, no crowding — but that's because there's nothing there.

### 03 — loop-apex-day
**Before/after: unchanged.** Pixel diff confirms no structural edit; two
close foreground trunks flank the path on the right and a continuous
tree/rock line runs the horizon left-to-right. Already has compression
(near trunks) and a horizon line — no empty-sky problem here, before or
after.
**Note:** the near trunks are close enough to the camera that their bark
texture stretches visibly (station-specific artefact, not a composition
issue).

### 04 — eastward-swing-day — **the one real, working fix**
**Before:** a dense grove of trunks stood directly in the walked path,
canopy overhead blocking the sky and horizon completely — the path visually
terminates *into* the trees a few metres ahead. This is the "blocks the path"
failure mode the brief calls out, not the empty one.
**After:** the grove was pulled off the route and re-clustered to flank the
right side; the path itself opens down the center to a hill crest with a
rock landmark on the skyline, plus a fainter shape farther back suggesting
more terrain beyond it. A thin line of small trees now traces the left
horizon, and two small blue creature silhouettes sit in the left midground —
a nice touch of the "lived-in" quality the rubric asks about. This is a
genuine compression → reveal → landmark sequence where before there was only
compression with nothing to reveal.
**Still reads thin:** the left flank is now sparse — small saplings and nothing
else between them, so the left half of the frame is closer to empty than the
right. Better than before, not yet a matched pair of flanks.
**Path:** clear now, an improvement over before (where the grove obstructed
it).

### 05 — south-bridge-day
**Before/after: essentially unchanged**, aside from a small creature added at
lower right and cloud/foliage-shader jitter. Already the best-composed
station in the set: trunks frame both sides of the path, a stone stair
landmark sits mid-distance directly on the route, and a hill with a
background tree line closes the horizon. No empty-corridor problem before or
after.
**Path:** the flanking trunks sit close to the route but not on it.

### 06 — stone-root-entry-day
**Before/after: unchanged.** A dark, dense grove flanks the path on the left
(with a signpost at path edge) and a tree line closes the horizon behind a
second walking figure ahead on the path. No sky-to-grass gap; nothing to
fix, nothing broken.

### 07 — band2-mid-day — **regression, the worst one**
**Before:** a large tree canopy occupied the left third of the frame at
midground distance, giving the hillside real mass and a horizon that wasn't
just grass-to-sky.
**After:** that tree is gone. What's left on the left horizon is a single
distant sapling and two smaller ones, all thin enough to read as noise, not
structure. The frame is now dominated by open sky (over half the frame) and
open grass with grazing sheep as the only incident — the single emptiest
frame in the after set, and it was not the emptiest frame in the before set.
This is a direct instance of the "player → empty grass → sky" failure the
pass exists to fix, freshly created rather than removed.
**Path:** clear, again because there is nothing around it to be blocked by.

### 08 — band2-far-day
**Before/after: essentially unchanged.** Already the strongest landmark
frame in the set — a rocky mountain ridge dominates the left third of frame
at real scale, two signposts (naming destinations) frame the path like a
gate, and a tree grove closes the right side with a further grove visible
past it on the horizon. This is the one station that already matches the
"landmark" beat the brief wants (compare to the Palworld plateau-landmark
reference) — nothing needed fixing and nothing was broken.

## What still reads empty or procedural, overall

- Station 02 and 07 are now emptier than before — see above.
- Station 04's left flank is thin (real trees only close to the player,
  nothing but two-three saplings further out).
- Where trees do cluster (01, 03, 05, 06, 08), the clustering itself reads as
  intentional — irregular counts, mixed distances, not a repeating grid — so
  the "authored vs. procedural" question is being answered correctly by the
  scatter logic. The regressions are placement removals, not a return to
  procedural evenness.

## Anything now blocking or crowding the path

Nothing added by this pass crowds the route. The one blocking element that
existed (04's grove standing in the walked path) was removed, which is a
correct fix. The station-08 signposts flank rather than block. No new
obstruction anywhere in the after set.

## Three biggest gaps, ranked

1. **Two of eight stations got emptier, not fuller — 07 worst, 02 close
   behind.** Both had genuine left-side mid-ground mass in the before frames
   (a full canopy at 07, a grove at 02) that is simply absent after. Whatever
   pass added the station-04 fix and station-01 filler is, at these two
   stations, subtracting instead of adding. This is the opposite of the
   stated goal and needs to be caught before round 2 — the fix is not "add
   more trees to 02 and 07," it's "find out why trees that existed there
   before don't exist there now."
2. **The canopy material reads as broken, everywhere, in both passes.** Pale,
   glassy, faceted "shattered glass" foliage on every tree in all 16 frames
   is a bigger gap to the key art's rich, rounded, saturated canopies than
   any placement choice this pass can fix. It undercuts every other
   improvement: station 04's newly-opened path still resolves into the same
   washed-out canopy wall at the right edge of frame.
3. **Even the successful fix (04) is asymmetric.** The right flank got a full
   grove; the left flank got three small saplings with visible gaps of open
   sky between them. A rhythm needs both sides of a "compression" beat to
   read as intentional, or the eye reads the thin side as unfinished rather
   than as a deliberate gap before a reveal.

## Bar questions

**A. Do these frames read as belonging to the world in
`tetherbound-meadows-keyart.png`?** **No.** The rolling-hills-and-oak-grove
composition language is present and correctly aimed at in the well-composed
stations (05, 06, 08 especially resemble the key art's oak-grove-path panel
in silhouette and landmark logic). But the palette carries none of the key
art's saturation or value depth — foliage is pale mint/white rather than rich
green, shadows are flat rather than deep and warm-cool contrasted, and the
broken-glass canopy material is a constant, frame-by-frame reminder this
isn't finished art standing in front of a finished world.

**B. Shown these frames beside the Palworld references, would someone say
these are trying to be the same kind of game?** **No, not yet.** The
underlying intent matches — open grass corridors, landmark hills, occasional
wildlife glimpsed at a distance, a path that curves rather than runs straight
— and station 08's ridge-plus-signpost framing is a legitimate cousin of the
Palworld plateau-landmark shot. But Palworld's ground reads dense and
saturated at every distance band, and its foliage holds convincing form at
combat range; these frames have comparably decent ground-flower density up
close but the canopy material breaks the illusion the moment a tree fills any
real portion of frame, which happens constantly since trees are the primary
mid-ground device being used to solve the emptiness problem.

## Fixable by scene vs. needs new art

**Fixable by scene (placement/scatter, no new assets):**
- Restore mid-ground structure at stations 02 and 07 — whatever removed the
  pre-existing left-side groves at these two stations should be reverted or
  investigated; this is the single most actionable finding in this round.
- Thicken station 04's left flank to match the right — a couple more trees or
  a rock cluster, not new geometry types.
- Nothing needs to be added to 01, 03, 05, 06, 08 — leave them alone.

**Needs new art / a shader-level fix, not a scene-composition fix:**
- The tree canopy material itself. This is the dominant visual defect across
  every frame in both passes and sits above any placement decision — no
  amount of additional scatter improves a corridor whose trees read as
  broken glass rather than foliage.
