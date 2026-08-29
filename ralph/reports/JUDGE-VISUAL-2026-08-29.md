# VISUAL JUDGE — 2026-08-29

Blind verdict pass over the visual work that landed on `ralph/LAND-0829A`
(judged at `1656a71`). Frames were rendered and judged **before** reading any
lane report, handover, or fix-describing commit message; the reconciliation
section at the end was written after. Frames live beside this file in
`ralph/reports/judge-visual-2026-08-29/`.

Renderer caveat (per `tools/survey.sh` and D06): Compatibility renderer under
llvmpipe software GL — trustworthy for composition, silhouette, colour, scale
and texture read; not for fine lighting/post quality. Since RB4/D01 the game
ships Compatibility, so these are the shipped pipeline's frames.

Capture note: the castle approach frame here uses a **corrected** stand.
`tools/capture_t1arch_all.gd`'s `C-01-approach-gate` offset
`Vector3(2.0, 1.8, 24.0)` sits *inside* the plinth footprint (local z runs
−10..+34, gate/ramp exit toward −z, ramp foot ≈ z −21 — see
`scripts/world/landmark.gd`). My variant `tools/_judge_capture_arch_0829.gd`
stands at local z −40, south of the ramp foot, and also hands Terrain3D the
capture camera so each site renders streamed ground rather than parked-rig LOD.

Commands used:

```
godot --headless --path . --import
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_judge_capture_arch_0829.gd          # frames 1–4
# (world subjects follow the same invocation with the named tool)
```

---

## 1. Castle — exterior, approach, near the walls

Frames: `C-01-approach-gate-FIXED.png`, `C-02-silhouette-far.png`,
`C-03-corner-close.png`, `C-04-wall-close-ground.png`.

**Verdict: BAD.** The owner called the castle BAD before this round; from
these frames that verdict stands. It has a complete, symmetric silhouette —
towers, keep, crenellations, flags, a real ramp with lit torch posts and camp
props at the foot — but it reads as a white toy fort on a concrete display
base, not as the "grounded, military, believable" castle on the owner's own
board.

What specifically reads wrong:

- **Maquette walls.** The curtain walls are large identical near-white
  modules with visible vertical seams and bevelled edges (loudest in
  `C-03`/`C-04`). No stone coursing at any distance, no arrow slits or
  windows along entire wall runs, no weathering gradient from base to
  parapet. The only surface variation is metre-scale blotchy stain noise
  that reads as smudged plaster, not masonry.
- **The plinth.** A featureless mid-grey box with one trim line — poured
  concrete. Its base is a dead-straight line meeting undulating grass with
  no transition (no footing, rubble, or grade change), and in `C-02` and
  under the near corner in `C-03` the plinth visibly **floats** — open
  shadow gap between its underside and the ground.
- **Scale disagreement on the wall walk.** The mid-wall turrets are
  miniature — roughly a third the girth of the corner towers with their own
  full crenellation sets, so they read as sandcastle decorations
  (`C-03`). The witch-hat roofs are small and cartoonish against the wall
  mass.
- **Placeholder masses in the hero vista.** Directly beside the castle,
  giant untextured boxes intrude into every exterior frame: a light-grey
  blank slab on the right of `C-01`/`C-04`, and the stronghold's near-black
  mega-box with a flat untextured tan top on the left of `C-02`. The hero
  landmark shares every composition with what looks like unfinished
  blockout.
- **Value structure.** Walls are one bright value top to bottom; the frame
  splits into white shape / green smear / blue sky with nothing tying the
  building to the ground plane.

Guess at cause (flagged as guess): the kit modules share a single
unweathered albedo with baked AO blotches at the wrong scale; the plinth is
a box ground-snapped at one probe point so sloping terrain opens a gap on
the far side; the neighbouring boxes are the stronghold shell's unmaterialed
upper masses.

## 2. Stronghold — exterior and approach

Frames: `S-ext-01-approach-ramp-foot.png`, `S-ext-02-flank-wide.png`.

**Verdict: BAD.** Owner said BAD; still BAD, and from the flank it is the
worst-reading structure in the world right now.

- **From the flank it is a featureless near-black box.** Under a full day
  sky the wall texture crushes to void — no roofline articulation beyond one
  step, no openings, no banners, no machinery, no propaganda, nothing that
  says "occupied military works" (`S-ext-02`). It reads as an unlit
  warehouse dropped on the meadow.
- **The approach is one texture swatch.** The entire lower half of
  `S-ext-01` is a single cobble material — puffy, clay-like cobbles with
  strong bevel highlights — and the wall ahead is a flat slab of the *same
  kind* of cobble texture at 2–3× the scale, so wall stones read 1–2 m
  wide. The two scales collide at the junction. The gate is a plain
  rectangular hole with no gatehouse, frame, reveal or depth.
- **What genuinely works:** the Team Tether pylon line (`S-ext-02` left) —
  distinct silhouette, cyan crystal accent, correctly grounded, reads as
  danger-faction tech at meadow scale. The keyart's stronghold language
  (stone facade, banners, scaffolds, apparatus) is exactly what the pylons
  have and the building lacks.

Guess at cause (guess): the exterior is probe-built structural volume with
a single dark tiling material and no exterior dressing/articulation pass;
albedo dark enough that llvmpipe's flat sky term leaves no legible shading.

## 3. Burrow Warrens — the mound / exterior

Frames: `W-ext-01-knoll-from-outside.png`, `W-ext-02-knoll-from-outside.png`,
`W-ext-03-mouth-door.png`.

**Verdict: BAD.** Owner said BAD; still BAD. The re-sited knoll *composition*
is defensible — a rock outcrop with a built mouth could read as intended —
but the materials sink it.

- **Three unrelated rock languages in one frame** (`W-ext-03`): noisy
  speckled-granite mega-boulders; smooth mint-green faceted low-poly rocks
  that read as a different game's asset pack; and a plain grey concrete
  walk slab. Nothing shares hue, roughness or detail frequency.
- **Boulders read as chamfered cubes.** The upper courses of the knoll are
  visibly box-shaped with bevelled corners (`W-ext-02` top row), stacked at
  similar sizes; and every face carries the same high-frequency granite
  noise with no macro variation, so the mass reads as static rather than
  stone. On distant faces the noise aliases into literal checkerboard pixel
  patches (top-left and right cube face of `W-ext-02`).
- **The mouth facade** is a flat wall with a rectangular hole; the facade
  texture streaks/stretches vertically near the top (`W-ext-03`), and the
  concrete slab path sits on the grass with no edge blend.
- **Vegetation confetti fights the rock.** Hyper-saturated lime aloe-blade
  grass clumps, plastic-bright ferns and an oversized purple flower prop
  (petals ~40 cm against the 1.8 m-trainer ruler) clash with the muted
  ground smear under them.

Guess at cause (guess): knoll assembled from generic boulder meshes at
different scales sharing one granite material (so UV density varies per
boulder); mossy rocks and ferns come from a stylised low-poly pack and were
never re-tinted toward the knoll's palette.

## 4. Burrow Warrens — interior

Frames: `W-int-01-den-wide.png`, `W-int-02-hall.png`.

**Verdict: GOOD — the owner's positive verdict holds; protect it.** The
interior reads as one coherent authored place: stained dirt floor, dark
timber beams, pilaster rhythm on the walls, warm doorway light against cool
dark, resident creatures inhabiting the space, dressing (crate, grain sack,
barrel) at believable scale. This is the only architecture subject where
material, value structure and story agree.

Watch items (not failures):

- The guardian's dark shell merges into the shadowed back wall
  (`W-int-01`) — its silhouette is nearly lost at the exact moment the room
  wants you to see it. A rim of warmer bounce or a lighter back wall behind
  the den would protect the read.
- In `W-int-02` a resident creature bisects the camera frustum
  (bottom-right camo blob) and another crowds the right edge; residents
  wander close enough to swallow the camera in doorways.
- Walls and ceiling share the same granite-noise material, so surfaces
  separate by geometry only; it holds at this light level but is the same
  noise-texture economy that fails outside.

## 5. Open Meadows ground and grass, near to far

Frames: `shots/ground/ground-0{1..5}-*-day.png` (bands 1–5, pinned day,
clear; band 2 also carries the weather sweep), rendered via
`xvfb-run … --script tools/_capture_ground_and_sky.gd`. Far tier verdict
continues under subject 8 (far panels/survey pending at time of writing).

**Verdict: ACCEPTABLE — a real and visible step toward the bar, with
specific defects that keep it from GOOD.** The near field finally reads
like the keyart's world: tall blade grass with parallax, flowering bushes
with restrained purple/white accents, believable dirt paths with pebble
scatter, the trainer sitting correctly in it (the trainer model itself is
genuinely strong — expressive, well-proportioned, reads as the game's own
art). Band 2's grove (`ground-02-…-day`) has real mood: shaded path, purple
bells, dappled dark. This is the closest any Tetherbound frame gets to
`palworld-02`.

What keeps it from GOOD:

- **One grass species everywhere.** Every band uses the same vertical
  blade sprite at the same density; bands differ only by tree props and
  flower confetti. Palworld's fields read as mixed groundcover (tufts,
  broadleaf, bare patches); here the blades read as a uniform carpet of
  wheat sprouts, and several blades render near-black in full daylight
  (visible in `water-02-river-grazing.png`) — unlit/shadow-sampled blades
  mixed into lit clumps.
- **The mid-distance smear tier.** Past ~30 m the ground collapses into a
  soft green-yellow blur with no detail texture, and the boundary between
  blade-grass tier and smear tier is a visible band that tracks the camera
  (right edge of `ground-01`, lower third of `ground-01-golden`).
- **Dashed seam lines on the ground.** Faint dotted/dashed lines cross the
  terrain in multiple frames (`ground-01-day` bottom-right,
  `ground-01-golden` right, `W-ext-01` bottom-left). They read as region
  or scatter-cell seams and are visible enough for a player to steer by.
  Guess (flagged): Terrain3D region borders or a scatter-cell debug edge
  surviving into the shipped material.
- **Floating path pebbles.** The light-grey low-poly pebbles along paths
  hover a few cm above the dirt in most path frames (`ground-01`,
  `ground-04`), reading as scattered rather than embedded.
- **The black NPC.** In band 2's frames a villager/NPC on the path renders
  as a 100 % black silhouette in full day (`ground-02-…-day`, `-fog`).
  Whatever material path lights the trainer correctly is not being applied
  to this NPC.
- **"Day" sky disagrees with day ground** in bands 3–5 — see subject 7.

## 6. Water and shorelines

Frames: `shots/ground/water-01/02/03-*.png` (pinned day — primary
evidence); `shots/gate_a/water/water-0{1..4}.png` (dedicated tool,
**compromised** — see below).

**Verdict: pond GOOD, river ACCEPTABLE, stream BAD → subject overall
ACCEPTABLE.**

- **The pond is the best water in the game** (`water-01-pond-eye`):
  turquoise shallows graduating to depth, submerged pebbles readable
  through the surface, sparkle at the right scale, sand-to-grass bank
  transition, reeds at the waterline. It would not embarrass a Palworld
  comparison. One artefact: a hard-edged dark rectangular shadow lies on
  the water right of the trainer — a quad's shadow with no visible owner.
- **The river reads engineered, not natural** (`water-02-river-eye`): both
  banks are uniform ~45° cuts faced in one large hex/pebble texture, like
  riprap on a canal levee, with a hard turf line where the meadow resumes.
  The water itself (deep navy, moving surface) is fine; the channel is the
  problem. Shore stones float at the waterline.
- **The stream is invisible from its own bank** (`water-03-stream-eye`):
  the capture stands at the stream's authored bank point and the frame
  shows only meadow grass — no channel cut, no water surface, no bank
  vegetation. If a player was led to this stream they would not find it.
- **Tool defect to fix, separate from the scene:** the dedicated
  `tools/capture_water.gd` frames all came back in a dusk/night wash
  (`water-01-bank-closeup` is near-black; `water-04-approach` sits under a
  flat blue veil). That tool does not pin/freeze the clock the way
  `_capture_ground_and_sky.gd` does, so its frames are unusable for colour
  judgement. Composition read through the veil of `water-04` is actually
  promising (framed path, big tree, house across the pond).
## 7. Sky and sun across the day cycle

Frames: `shots/day_night/hour-*.png` (the driven passive clock —
`tools/_capture_day_night_transition.gd`, 12 hours at one fixed ranger-camp
viewpoint), plus the snap-preset `-golden`/`-night` frames from
`_capture_ground_and_sky.gd`.

**Verdict: BAD**, on two grounds the still frames show unambiguously.

- **Deep night rendered crimson in this capture — attributed after
  reconciliation to a KNOWN CAPTURE BUG, and the tool needs the ported
  fix.** `hour-22.00`, `hour-23.90`, `hour-00.10`, `hour-02.00` came back
  as blood-red frames: red sky, red-orange ground brighter than the 20:30
  dusk. Written blind, this looked like the driven clock blending to a
  danger colour. Post-verdict reconciliation found the true cause:
  `tools/_capture_day_night_transition.gd:91` parks the Player at
  y = −500 — 500 m underground — and `ralph/DONE.md` (SURVEY_BAND2 item)
  documents precisely this anti-pattern: a submerged player makes
  `water.gd` ramp a red drowning vignette over the whole frame, a fix
  already ported into `survey_band2.gd`/`capture_band3_region.gd` but
  **not** into this tool. The red frames are exactly the last four
  captured, matching a ramp over capture wall-time rather than an hour
  window. Consequence: **the real 22:00–02:00 look is unverified by this
  pass** — the four red frames are evidence about the tool, not the sky.
  The snap `apply_time("night")` (`ground-02-…-night.png`) is blue,
  navigable and good, and is probably closer to the truth. Port the
  above-ground parking fix into `_capture_day_night_transition.gd` and
  re-run its last four hours before believing anything about deep night.
- **Golden hour never happens on the driven clock.** The sweep brackets the
  18:00 keyframe (`hour-17.50/17.90/18.10`) and every one of those frames
  is a flat grey-blue overcast wash — no warm cast, no long warm shadows,
  no sun presence. The snap preset `apply_time("golden")`
  (`ground-01-…-golden.png`) produces a genuinely lovely warm frame, so the
  look exists in the keyframe set; the continuous blend never displays it.
  A player free-running the clock gets grey → blue → **red**, and never
  the keyart's sunset panel.
- Secondary defects: the golden snap's **sun is a flat white ellipse** — a
  blown sticker-disc with no halo gradient (`ground-01-…-golden`); in
  bands 3–5 the "day" sky carries dark navy ink-blot clouds over fully
  sunlit terrain, so sky and ground disagree about the weather
  (`ground-03/04-…-day`, `water-03-stream-eye`); and at 19:00–20:50 tree
  canopies stay near-daylight green over an already-dark ground, reading
  self-lit.
- **What works:** the 19:00–20:50 dusk slide itself is smooth, blue and
  navigable — the OP23 "night has a floor" goal visibly holds in that
  window; the midnight-wrap crossing (23.9 → 0.1) is continuous (both
  red, but continuous); the fixed frames show no snapping between
  adjacent hours short of the red window's entry.
## 8. Terrain macro composition / landmarks / regional silhouettes

Evidence: the wide/horizon reads across the frames above —
`C-02-silhouette-far`, `ground-05-band5-approach-day`,
`ground-01-band1-opening-day`, `ground-03-band3-crossing-day`,
`water-02-river-eye`, `S-ext-02-flank-wide`. Capture note: the dedicated
far-panel tool (`_capture_far_panels.gd`) stalled after 70+ minutes with no
frame written and was killed (its two viewpoints re-shoot the 2026-08-23
assessment's panels); `tools/survey.sh` was still rendering when this
verdict was written. The macro verdict therefore rests on the named frames,
which include band-1, band-3 and band-5 horizons.

**Verdict: ACCEPTABLE as a skeleton, dragged down by what stands on it.**

What works:

- **The band-5 approach axis is real composition** (`ground-05`): a forked
  path, the Team Tether pylon line marching toward the stronghold with
  cyan tether cables strung between, crystal clusters flanking — a player
  reads "that way is the endgame" from one frame. Best macro moment in
  the set.
- **The castle silhouette works as a landmark** (`C-02`): towers, keep and
  crenellation read clearly against the sky at distance. The silhouette
  language fails only when you get close enough to see the surfaces.
- **Band 3's tall half-timbered house** (`ground-03`) is a genuine
  mid-scale landmark; band 1's rolling hills with ridgeline tree stands
  (`ground-01`) compose like the keyart's opening panel.

What reads wrong:

- **Untextured placeholder masses stand on the horizon.** The band-5 skyline
  — the one the whole approach march aims at — carries plain grey
  untextured boxes (`ground-05`, top of frame), and the stronghold reads
  as a black slab from every angle (`S-ext-02`, `C-02` left). The macro
  skeleton points the player at the two worst surfaces in the game.
- **No aerial perspective.** Distant hills and treelines render at the
  same saturation and value as the near field (`C-02`, `ground-01`) —
  no haze gradient, so depth flattens and the horizon reads like a
  backdrop a few hundred metres away. (The fog weather preset, which
  might have supplied this, renders no visible fog at all —
  `ground-02-…-fog` is indistinguishable from clear. Guess, flagged:
  it relies on volumetrics the shipped Compatibility renderer doesn't
  have.)
- **Regional differentiation is prop-deep.** Bands 1, 3, 4 and 5 share the
  same grass carpet, same tree family, same palette; they differ by what
  is parked on them (house, crystals, pylons). Only band 2's grove has
  its own light and colour identity. "Increasingly demanding regions"
  is not yet something the terrain itself says.
- **The river reads as a canal at macro scale** (`water-02-river-eye`):
  uniform 45° cut, one bank texture, hard turf line along the top edge.

---

## The three things that most separate these frames from the references

1. **The built structures.** The keyart's stronghold panel and the owner's
   castle concept are weathered, layered, multi-elevation stone with
   banners, scaffolds and machinery; `palworld-04`'s tower landmark is one
   coherent silhouette. Tetherbound's castle is a bright-white maquette on
   a floating concrete pedestal (`C-03-corner-close`) and its stronghold is
   a featureless black box (`S-ext-02-flank-wide`). This is the single
   widest gap, and the endgame march aims the player straight at it.
2. **The live clock's colour script.** The keyart's identity is its light —
   golden sunset panel, blue mysterious night. On the driven clock golden
   hour never renders (`hour-17.90` straddles the 18:00 keyframe and is a
   flat grey-blue wash), while the golden look demonstrably exists via the
   snap preset. (The blood-red deep-night frames initially blamed here were
   reattributed after reconciliation to the capture tool's own documented
   submerged-player vignette bug — see subject 7 — so deep night is
   unverified rather than condemned.)
3. **Material cohesion.** The references read as one fabric; these frames
   keep breaking style within a single view — three unrelated rock
   languages at the Warrens mouth (`W-ext-03`), untextured horizon boxes
   (`ground-05`), riprap canal banks (`water-02-river-eye`), plastic-bright
   fern/aloe confetti against muted ground. Any one frame contains the
   evidence that three different games contributed assets.

## The two bar questions

**A. Do these frames read as belonging to the keyart's world?** **No** —
but for the first time it is a near miss in places. The band-1/band-2
meadows, the pond, and the trainer standing in blade grass
(`ground-01-band1-opening-day`, `water-01-pond-eye`) are recognisably
reaching for the keyart's palette and composition and getting close. What
breaks belonging is everything built (castle, stronghold, Warrens mound)
and the night/golden failures — the keyart's two signature moods.

**B. Beside the Palworld shots, would someone say these are trying to be
the same kind of game?** **Yes for the open-field frames — no overall.**
`ground-01` and `water-01-pond-eye` beside `palworld-02` read as the same
genre of world: third-person scale, blade grass, path, water, stylised
character. The moment a structure enters frame (`C-01`, `S-ext-01`) the
answer flips to no — Palworld's buildings are believable mass; these are
blockout. Since the chapter's climax is architecture, the overall answer
is no.

**What is fixable by changing the scene** (density, palette, lighting,
composition, scatter, materials on existing meshes): the missing golden
blend (WorldLook keyframe path — and port the above-ground player parking
fix into `_capture_day_night_transition.gd` so deep night can actually be
judged); the sky/ground weather
disagreement; the dashed ground seams; floating pebbles and the floating
castle plinth; the black-rendering NPC; the invisible stream (carve the
channel, dress the banks); river bank texture scale; second grass
species/tufts; re-tinting the Warrens' mint rocks and ferns toward the
granite palette; putting real materials on the stronghold shell and the
horizon boxes; sun disc halo.

**What needs art that is not in the build:** a weathered stone material
set and gate/hoarding-scale detail modules for the castle kit, and an
exterior facade language for the stronghold (banners, scaffolds, apparatus
— the keyart panel's vocabulary). Both are material/kit work on existing
meshes, consistent with the no-new-creature-mesh and reuse rules; neither
needs a new hero mesh, but neither is achievable by re-scattering what is
already placed.

---

## Lane-report reconciliation — WRITTEN LAST, after all verdicts

Read after every verdict above was written: `T1-ARCH_buildings_2026-08-29.md`,
`T1-CASTLE_castle_2026-08-29.md`, `t1-light-session-2026-08-29.md`,
`ralph/DONE.md` (recent entries), and the landing branch's commit log.
Where a report and my eyes disagree, both claims are stated.

**Where the reports and the frames agree:**

- **T1-ARCH's stronghold honesty is accurate.** It claims S-ext-01 "now
  shows real warm-lit masonry, a large improvement over pure black" and
  that S-ext-02's flank "is still mostly dark." Both match my frames
  exactly. The lane also flagged `stronghold.json`'s `yaw_deg: 90` as
  probably wrong for the current approach and a plausible contributor —
  consistent with my "no articulation faces the player" read. No
  disagreement; the verdict stays BAD because a readable-but-blank wall is
  still a blank wall.
- **T1-CASTLE predicted its own insufficiency.** Its report says the
  metallic fix brightened the walls (~15–25 % measured) and warns that "if
  the owner's next pass still reads the castle as too pale, the fix is
  likely a value-ladder retune… not a reach for metallic again." That
  next pass is this report: the castle now reads *whiter* than the tan
  its albedo values intend (measured post-fix patch (212,203,185) —
  essentially off-white), and my blind verdict called the walls
  "near-white maquette." The predicted retune is now evidenced work.
  Its C-01 capture-bug diagnosis also matches what I found and corrected
  independently.
- **T1-LIGHT's unaddressed list is confirmed by the frames.** Its blind
  critic flagged, and left open: no aerial perspective at distance
  (confirmed — subject 8), and night foliage staying saturated/day-lit
  (confirmed at 19:00–20:50, canopies read self-lit). Its sun-disc fix
  targeted the hour-21 blend, and my 19:00–20:50 frames indeed show no
  blown disc — but the blown white ellipse is still present in the
  **golden snap preset** (`ground-01-…-golden`), a state its fix did not
  target.

**Where the reports claim more than the frames show:**

- **T1-ARCH: "the mound now shows real granite facet/fracture detail…
  matching the interior's own bar."** The first half is true — the moss-
  hedge multiply bug is genuinely gone; it is granite now. The second half
  is not: the mound still fails (chamfered-cube silhouettes, one
  noise-frequency everywhere, texture aliasing to checkerboard at
  distance, and mint-green low-poly rocks plus saturated fern/aloe
  confetti from a different style family sitting right at the mouth). The
  material swap fixed the named defect and left the mound BAD for reasons
  the fix was never aimed at. The interior's bar is not met.
- **The castle round overall**: two lanes of accurate diagnosis and real
  fixes (metallic, weathering octaves) have not moved the owner-level
  verdict. The weathering variance is measurable (their std-dev 21.9→28.1)
  and visible in my frames — as metre-scale smudges that read "stained
  plaster," not masonry. Landed ≠ enough; the wall needs a value-ladder
  retune plus coursing/openings-scale detail, not more octaves of blotch.
- **DONE.md's black-NPC fix did not reach everything.** An additive
  emission floor fix for dark rank tints is recorded as verified ("Hess
  now reads with visible brown leather…"), yet a villager/NPC on the band-2
  path renders 100 % black in full day in my frames
  (`ground-02-…-day/-fog`), and the Team Tether grunt in `ground-04` is
  a near-black mass. Either a different material path misses the floor,
  or it regressed on the landing branch.

**Where reconciliation overturned my own blind verdict (recorded, not
erased):** the four blood-red deep-night frames. Blind, I attributed them
to the driven clock; DONE.md's SURVEY_BAND2 entry documents the identical
symptom as `water.gd`'s drowning vignette over a player parked underground,
`_capture_day_night_transition.gd:91` parks the player at y = −500, and the
red tracks capture order, not hour. Subject 7's text was corrected before
finalising; the missing-golden-hour finding is in the clean early-capture
window and stands. The lesson cuts both ways: my blind eyes caught what six
rounds of prose missed elsewhere, and the repo's own prose caught my
misattribution here. The tool still needs the parking fix ported before
anyone judges deep night.

**Findings no lane report mentions (new this pass):** dashed seam lines
crossing the terrain in multiple daylight frames; floating path pebbles;
the castle plinth's visible under-gap; the fog weather preset rendering no
visible fog; the invisible stream at its own authored bank; the giant
untextured horizon boxes on the band-5 skyline; `capture_water.gd`'s
frames arriving in a dusk/night wash (it lacks the clock-pin fix its
sibling tools carry); and `_capture_far_panels.gd` stalling >70 min
without writing a frame (killed; possibly related to the Terrain3D
streaming defect T1-LIGHT root-caused for the survey's black frame —
guess, flagged).
