# VISUAL JUDGE 2 — 2026-08-30

Second blind verdict pass. Frames were rendered and every verdict below was
written **before** reading any lane report, handover
(`ralph/reports/handover-*-2026-08-30.md`), `HALL_DESIGN_2026-08-30.md`, or
branch commit message; the reconciliation section at the end was written
after. Frames live beside this file in
`ralph/reports/judge-visual-2-2026-08-30/`.

## Exactly what tree was rendered

No integration branch existed at judging time. Per the coordinator's
fallback instruction I rendered a **local throwaway integration**:
`origin/main` (`a97f3e84`) with all ten lane branches merged in, every merge
clean, no conflicts, nothing pushed from it:

`ralph/T1-SKY` (698e2046), `ralph/T1-CAST` (4cf5c66f), `ralph/T1-UI`
(529fc81e), `ralph/T1-GROUND` (0aa3db2b), `ralph/T1-WARRENS-EXT` (4816bab8),
`ralph/T1-HALL-DESIGN` (3f0b313d), `ralph/T3-TYPECHART` (94e7e0b2),
`ralph/T3-PICKUPS` (c1059109), `ralph/T2-STRANDING` (974e2ba8),
`ralph/T2-GATEF` (bfce0ed7). Local merge head: `0791b1f6`.

Renderer caveat (per `tools/survey.sh` and D06): Compatibility renderer
under llvmpipe software GL — trustworthy for composition, silhouette,
colour, scale and texture read; not for fine lighting/post quality and never
for frame times. Since RB4/D01 the game ships Compatibility, so colour
verdicts here are verdicts on the shipped pipeline's own output.

Colour method this round, per the coordinator's weighted focus: every
material verdict carries **sampled pixel numbers** — mean RGB and std-dev of
a named patch (`patch.py`-style rectangular sample, coordinates given), not
an eyeballed impression. ACES tonemap caveat kept in mind: on near-clipped
bright surfaces, lowering albedo can raise apparent saturation (R stays
clamped while G/B fall), so causal guesses stay guesses and are flagged.

Commands used:

```
godot --headless --path . --import
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/<capture tool>.gd
```

---

## 1. Castle / Meadows Hall — exterior

Frames: `C-01-approach-gate-FIXED.png`, `C-02-silhouette-far.png`,
`C-03-corner-close.png`, `C-04-wall-close-ground.png` (the first judge's own
corrected stands, `tools/_judge_capture_arch_0829.gd`, so directly
comparable to its frames).

**Verdict: BAD. The wall colour has not moved.** The owner's read —
"geometry is probably fine but the coloring is not good" — is exactly what
these frames show, for the third round.

The numbers, sampled where the sun hits the curtain wall:

- `C-01` wall left run, patch [340,300]–[480,400]: **mean (211,202,185),
  std 10.2**. The first judge's post-"fix" measurement was (212,203,185).
  Within one RGB point per channel. A full further round of castle work has
  changed the lit wall colour by *nothing a pixel can see*.
- `C-01` wall centre [560,300]–[760,380]: (208,195,178), std 22.5 — the
  higher std is the metre-scale AO smudge, still reading as stained
  plaster, not coursing.
- `C-03` lit wall run [560,400]–[1000,550]: (195,186,168), std 27.0.
- For calibration: the owner's board paints the castle in warm grey-brown
  stone. The plinth in this same frame — `C-01` [300,440]–[700,470],
  **(141,129,113)** — is very close to the colour the *walls* are supposed
  to be. The plinth is wearing the castle's intended paint; the castle is
  wearing whitewash at luma ~200.

The value ladder question, answered with the samples: a ladder technically
exists (`C-03`: roof ~96 / wall ~187 / plinth ~124 lit; shaded `C-04`:
wall ~94 / plinth ~37), so the tiers separate — but the ladder is
upside-down in emphasis. The single largest mass in every frame is also
the brightest surface in the world (brighter than the sky's zenith in
`C-01`), which is what keeps the toy-fort read alive at every distance.
At 400 m (`C-02`) the castle still separates from ground and sky — as a
white shape.

What else the frames show, unchanged from the first judge's list:

- Identical near-white wall modules with visible vertical seams and
  bolt-on trim plates (`C-03`, `C-04`); no coursing, no arrow slits, no
  openings along entire runs.
- Mid-wall turrets still a fraction of the corner towers' girth with their
  own full crenellation sets — sandcastle decorations (`C-03`).
- **The placeholder masses still stand in every hero composition.** `C-04`
  right edge: flat blue-grey face, (74,87,91) std **2.5** — untextured.
  `C-02` left: the stronghold's rear/west face reads (32,34,28) std
  **2.2** — a featureless near-black plane — under a flat pale top
  (113,125,131). One face of the `C-01` right-hand mass now carries a
  masonry texture ((92,82,62) — a reasonable warm stone, incidentally),
  which makes the untextured faces beside it louder, not quieter.

What moved (credit where the pixels show it): the plinth no longer
visibly floats — in all four frames its base meets the grass without the
open shadow gap the first judge photographed; and the plinth/skirt now has
a real moulding profile and a colour that belongs to the owner's board.

Causal guess, flagged as a guess: whatever albedo/metallic retunes landed,
the lit-face output is still driven to ~(210,200,185) — consistent with a
bright albedo plus ACES near-clip behaviour, where arithmetic reasoning
about albedo multipliers keeps failing; the first judge's warning that
this needs a **value-ladder retune judged on final pixels** (darken until
the *rendered lit face* samples warm grey-brown, then re-check saturation,
because ACES will shift it) still stands as evidenced, unperformed work.

## 2. Stronghold — exterior and approach

Frames: `S-ext-01-approach-ramp-foot.png`, `S-ext-02-flank-wide.png`.

**Verdict: ACCEPTABLE — this is the round's genuine move.** The flank that
rendered as "a featureless near-black box… an unlit warehouse" now reads
as occupied military works: crenellated parapet correctly seated on a
timber wale, tall cyan tether-energy window slits, dark timber
cross-bracing, red pennants, a distinct darker base course, and the pylon
line marching behind (`S-ext-02`). The gate is no longer a plain hole: it
has a recessed reveal, timber lintel, flanking torches (`S-ext-01`). This
is the board-15 material language — dark stone, dark timber, teal energy —
actually appearing on the building.

Samples: upper flank wall [560,150]–[900,350] **(41,33,25), std 24.9** —
very dark, but with real texture variance now, not the std 2–3 of a blank
plane; base course [560,330]–[900,390] (26,24,17) std 3.9; approach gate
wall `S-01` [400,60]–[900,250] **(25,22,16)** — still crushing toward
black at the exact point the player walks in.

What keeps it from GOOD:

- **The approach is still the worst angle**, and it is the one the player
  is routed up. The entire lower two-thirds of `S-ext-01` is the same
  puffy bevel-highlight cobble as before, and the wall ahead is a darker
  cobble of the same kind at a colliding scale; luma 23 on the gate wall
  means the new articulation only barely survives its own values.
- One masonry texture over the whole facade — no per-storey or per-bay
  variation, so at flank distance the wall is one dark field with
  features cut into it.
- Board 15's brass/gold accent tier is absent; the facade jumps from dark
  stone straight to cyan glow.
- Artefact, flagged: through the open gate (`S-ext-01`, zoomed), a bright
  sky-coloured band leaks across the top of the doorway interior — the
  building reads hollow/daylit through its own front door. Guess: a gap
  between the gate frame and the interior shell, or a missing interior
  ceiling face.
- The long connecting curtain to the west is still an untextured dark
  band (`S-ext-02` left, and it is the near-black plane in the castle's
  `C-02`).

Protect: the pylon line remains the strongest Team Tether statement in
the game and now has a building that agrees with it. Do not "fix" the
stronghold by brightening it to castle values — the dark-stone identity
is right per board 15; it needs *legibility* (a mid-value stone tier,
brass trim, larger texture breakup), not whitening.

## 3. Burrow Warrens — exterior mound

Frames: `W-ext-01/02-knoll-from-outside.png`, `W-ext-03-mouth-door.png`.

**Verdict: ACCEPTABLE — moved from BAD, on the axis that was named.** The
first judge's sharpest finding here was "three unrelated rock languages in
one frame." That defect is actually gone: the mint-green faceted low-poly
rocks are nowhere in these three frames, and the mouth facade now samples
**(138,134,115)** against neighbouring boulders at **(147,143,123)** —
same warm-grey family, hue-agreeing, believable together. The walk slab
is textured and tinted ((105,95,74)) instead of raw concrete, and a
worn-earth blend now surrounds the approach.

What still reads wrong:

- **The boulders are still chamfered cubes.** `W-ext-02` centre carries a
  literal bevelled cube embedded in the face; the top courses of both
  knoll views are box silhouettes with flat tops. Material cohesion
  arrived; the geometry still says "stacked crates," and no material can
  fully talk over that.
- One granite noise frequency everywhere — the mass has no macro
  variation, so big and small boulders read as the same rock zoomed.
- **The vegetation confetti survived.** A plastic-bright lime fern sits
  dead centre foreground of `W-ext-02` ((approx (140,220,60) tones) against
  smeared mid-green grass; flat purple flower sprites lie at the frame
  edges like stickers; the left-edge lollipop tree's boxy leaf clusters
  clash with the granite realism behind it.
- Through the mouth door (`W-ext-03`), the interior reads as flat grey
  panels and a white lintel band — an office lobby, not a burrow throat;
  the warm interior the door actually leads to does not show from
  outside. Guess: unlit/placeholder door-liner geometry.

## 4. Burrow Warrens — interior

Frames: `W-int-01-den-wide.png`, `W-int-02-hall.png`.

**Verdict: GOOD — not regressed; still the architectural bar. Protect
it.** Stained dirt floor, timber beams, pilaster rhythm, dressing at
believable scale (crate, grain sack, barrel), residents inhabiting the
space — all intact on the integrated tree. The first judge's watch item
about the guardian's silhouette has *improved in this capture*: the
badger's white face blaze reads clearly against the room (`W-int-01`),
and the den composition centres it.

Watch items (not failures):

- `W-int-02` right edge: a resident badger reads half-embedded in the
  floor mound/wall corner — paws over the mound, body inside it. If that
  is a bedded-den pose it needs a visible den rim to say so; as rendered
  it reads as clipping.
- Residents still wander into the camera's lap in doorways (`W-int-02`
  mid-frame blocks the corridor sightline).
- Walls and ceiling still share one granite noise; geometry alone
  separates them. It holds at this light level — it is the same texture
  economy that fails outside, and it will fail here too if the interior
  ever gets brighter.

## 5. Ground, grass and paths — bands 1–5

Frames: `ground-01..05-*-day/golden/night.png` (pinned clock,
`_capture_ground_and_sky.gd`), band 2 additionally cloudy/fog/rain.

**Verdict: ACCEPTABLE, and closer to GOOD than any other outdoor
subject.** Band 1's opening (`ground-01-…-day`) and band 3's crossing
(`ground-03-…-day`) are the two best frames in the game: authored
meandering path, pebble scatter, flowering accents at restrained density,
the half-timbered house as a real landmark, the trainer sitting correctly
in blade grass. Band 3's frame beside `palworld-02` reads as the same
genre without apology. The golden snap (`ground-01-…-golden`) is warm and
composed, and **the sun disc defect is fixed in it** — the sun now has a
real halo gradient (patch [950,40]–[1150,200] std 57 across the falloff,
where a sticker disc would sample near-flat). The night snap is blue and
navigable (overall luma 36, std 28 — dark with a floor, per OP23).

What still keeps the carpet from GOOD, sampled:

- **The dashed seam lines are still there and they glow at night.**
  Confirmed at zoom in `ground-01-…-day` (two dotted rows marching
  diagonally across the right half) and, worse, clearly visible in the
  night frame where the dots read *lighter than the ground around them*.
  A player can literally steer by them. Unmoved from the first judge's
  report.
- **The mid-distance smear tier is unmoved.** Past ~30 m every band
  collapses to a soft watercolour blur, and the blade/smear boundary
  still tracks the camera (loud on the right of `ground-01-…-day`, and
  the night frame adds a visible diagonal striping artefact inside the
  smear tier).
- **Blade grass is still one species.** The bushes and flower props vary,
  but the carpet is the same vertical blade sprite in every band;
  `water-02-river-grazing` shows the blades as flat angular polygon
  strips with **a minority of near-black blades mixed into fully lit
  clumps** — fewer than the first judge's frames showed, still present.
- **Saturation discipline fails on the open field.** Near-grass samples:
  `C-04` [100,600]–[1100,750] **(119,128,42)**, `S-ext-02`
  (119,130,42), `W-ext-01` (127,137,48), band 5 (154,151,81). A blue
  channel at a third of the green channel is a lime-lawn tint well past
  the keyart's controlled greens (keyart fields carry visibly more blue
  in every green). This is the single biggest reason open-field frames
  read "video-gamey bright" beside the references, and it is everywhere,
  which also makes it the cheapest single win available.
- Path pebbles have improved from floating to *seated on* the crust —
  contact is there at zoom (`ground-01` [330,470]–[560,650]) but almost
  every pebble still sits proud on the surface; none are half-buried, so
  the path top-crust reads sprinkled rather than worn.

## 6. Water and shorelines

Frames: `water-01-pond-eye/grazing`, `water-02-river-eye/grazing`,
`water-03-stream-eye/grazing` (same pinned-clock tool, so colour is
judgeable this round — the first judge's complaint that the dedicated
water tool captured in a dusk wash does not apply here).

**Verdict: pond GOOD, river ACCEPTABLE-at-best, stream BAD → overall
ACCEPTABLE, unchanged in structure from the first judge's split.**

- **Pond** (`water-01-pond-eye`): still the best water and the best
  single environment frame in the game — turquoise shallows over
  readable pebbles ((82,152,145) open water, believable), sand-to-grass
  bank, far tree line composed. **The ownerless rectangular shadow on
  the water is still there**, right of the trainer — same artefact the
  first judge photographed, one round later.
- **River** (`water-02-river-eye`): the channel still reads engineered —
  both banks are uniform ~45° cuts in one speckled camo-noise cliff
  texture with a hard turf line on top, and a pale uniform gravel strip
  at the waterline. The water surface itself is fine. Nothing about the
  bank language moved.
- **Stream** (`water-03-stream-eye`): **still invisible from its own
  authored bank point.** The frame is a meadow; there is no channel cut,
  no bank vegetation, no visible water beyond a couple of far blue
  pixels at the right edge. A player sent to this stream still cannot
  find it. Unmoved.

## 7a. Sky and the day cycle — driven clock, first real deep night

Frames: `hour-{14.00,17.50,17.90,18.10,19.00,20.00,20.50,22.00,23.90,00.10,02.00,08.00}.png`
(`tools/_capture_day_night_transition.gd`, which now parks the player
above ground at distance — the y=−500 drowning-vignette bug is fixed in
the tool, so **this is the first pass that has actually seen 22:00–02:00**).

**Verdict: ACCEPTABLE — two of the first judge's three failures moved;
deep night is real now and mostly holds, with one new named defect.**

- **Golden hour happens on the driven clock now.** 17:54 and 18:06
  render warm low sun with long tree shadows (ground samples
  (84,81,34) and (93,93,44) — R≥G with the warm cast, where the first
  judge measured a flat grey-blue wash at the same hours). The 17:30
  frame samples darker (luma 53) but the pixels show why: tree-shadow
  coverage across the sample area, not a wash — checked before calling
  it a defect. The keyart's sunset panel is still richer than this
  (no orange sky gradient, no sun presence in frame), but the
  "golden hour never happens" finding is **closed**.
- **Deep night is blue, not red.** 22:00: sky (31,63,82), ground
  (30,60,63) — moonlit blue with real directional moon shadows and dark
  cloud bands. It is the best night frame the game has produced and it
  is genuinely dark-but-readable. **No trace of the red vignette.**
- **New defect: night runs backwards after midnight.** Ground luma:
  20:00 → 44, 20:30 → 43, 23:54 → 53, 00:06 → 56, **02:00 → 78** — the
  world gets steadily *brighter* from mid-evening to 2 AM, and the
  02:00 frame is a flat pale-mint wash: ground brighter than the sky,
  no shadow direction, moonlight from nowhere. 02:00's ground (48,90,95)
  is brighter than the 17:54 golden ground. The night's darkest,
  moodiest hour is 20:00–22:00 and it *loses* mood from there. The
  torch/campfire justification (§13) holds at 22:00 and is gone by
  02:00.
- Artefact, with the llvmpipe caveat attached: the moonlit/shadow
  boundaries at 22:00 quantise into large rectangular stair-steps
  (loud, bottom-left of frame; also faintly at 17:54). Software GL
  makes fine shadow judgement unsafe, so this needs one look on real
  hardware before anyone chases it — but the block size is far above
  "fine lighting quality."
- The bands 3–5 "dark navy ink-blots over sunlit terrain" sky
  disagreement has softened: most day skies now carry tan/cream cloud
  streaks that agree with the light; a few dark smudge clouds persist
  (`ground-04-…-day` top-left corner).

## 7. Weather presets (band 2 sweep)

**Moved.** `fog` is no longer a no-op: it renders as occluded sun plus a
mild milky distance haze (mean abs diff vs day 55.4/255 across the frame,
where the first judge measured indistinguishability). `cloudy` and `rain`
also produce real changes (34.5, 32.6). The fog is light-handed — more
"overcast flattening" than the aerial-perspective fix the horizon needs —
but the preset pipeline demonstrably reaches the shipped renderer now.

## 8. The black-rendering humanoids

Evidence: real-world — the path figure in `ground-02-…-day/-fog`
(zoomed), the roadside figure in `ground-04-…-day`; stage rig —
`village_npcs.png` (`capture_village_npcs.gd`, five village NPCs through
the world's own character-model path).

**Verdict: the material hole is fixed; the grunt presentation is still
borderline-dark. Partially moved.**

- Both dark figures in my world frames are **Team Tether grunts**, and
  neither is a paint-black cutout any more: at zoom the band-2 figure
  shows oxblood jacket, straps, mask and cap detail, and the band-4
  grunt at close range in full sun reads leather browns, an insignia cap
  and a red medallion. The oxblood is correctly reserved danger colour.
- The five villagers on the stage rig all render fully lit — white
  shirts, green/brown kit, readable faces. No black-rendering path
  survives in the villager materials. (In-world villager evidence at
  close range did not occur in this frame set; the villages only appear
  at distance in `02-valley-floor`.)
- Still watch: the band-4 grunt's *mean* body sample in full daylight is
  (17,12,6) — luma 13. The detail read comes from highlights, so at 20+
  metres a grunt still collapses to a black speck (`ground-02` shows
  exactly this at path distance, worsened there by a tree-shadow band).
  The uniform is supposed to be dark; luma 13 mean is darker than any
  intentional oxblood. llvmpipe's weak fill light is part of this — but
  it is the shipped renderer, so it is the shipped read.

## 9. Creature presentation

Frames: `creature_presentation/_portraits.png`, `_field_thumbs.png`
(17 species, world light, trainer-height bar in frame), plus
`habitat/pond-shoreline.png`, `habitat/practice-meadow-cluster.png`; and
the Warrens interior residents from subject 4.

**Verdict: GOOD — the strongest asset class in the game, and now the
owner's colour board made real.** Portrait for portrait, the roster
matches the board's stated identities: bramblebun's forest greens,
mudsnout's rich browns, burrowback's stone-plate badger, duskhush's
midnight-and-glow owl, mosshell's teal-and-moss shell, veridian's
verdant-glow stag. Faces are expressive, materials read as fur/feather/
shell rather than flat tint, and relative scale against the 1.8 m bar is
role-appropriate (tuskroot/mudsnout large, terrapup small). At 30 %
thumb size every species still separates from the keyed meadow ground —
including the camouflage-risk species (bramblebun, veridian) which
separate on value. The pond shoreline shot shows a brooktail reading
near shore against turquoise water — close-toned but carried by its
white face.

Watch items:

- The field-thumb rig's ground is a flat keyed green, deliberately
  matched to measured grass tone — it answers colourway separation, not
  occlusion by blade geometry. The in-world frames I have (Warrens
  residents, pond brooktail, band-2 distance) all support the GOOD read,
  but tall-grass occlusion of small species remains unphotographed this
  pass.
- `habitat/practice-meadow-cluster.png` shows the practice meadow's
  bramblebuns on a **flat plastic-green ground with no blade carpet**,
  under a giant hard-edged black shadow blob, beside a floating white
  prompt-card quad — that one frame still looks like the pre-pass test
  environment. (Caveat, flagged: I cannot rule out the habitat rig
  suppressing scatter itself; the same flat look does not appear in the
  band frames.)

## 10. UI / HUD

Frames: `ui/01-title … 09-stamina-arc` (1920×1080,
`_capture_ui_survey.gd`).

**Verdict: ACCEPTABLE — legible and consistent, not yet styled.** The
exploration HUD reads at a glance: team strip with portraits/levels/KO,
HP and FOOD bars, minimap, objective card, hotbar, controller footer,
all on one dark-teal panel language with sane margins and safe areas.
Nothing misleads, nothing collides, glyphs are controller-first. What
keeps it from GOOD:

- Every element is the same untextured dark rounded rectangle; the
  panels carry none of the world's material language (timber/stone/
  Tether teal), so the HUD reads default-theme rather than
  art-directed.
- **The starter picker shows all three starters from behind** — the
  player's first impression of their three companions is three rumps
  (`02-starter-picker.png`). The orbs, title and selection ring are
  fine; the creatures need to face the camera.
- Party strip nits (`08-party-strip.png`): "Brookta" truncates with no
  ellipsis; the REST row's layout shifts its level column out of line
  with the other rows.
- The FOOD bar's label sits on top of its fill percentage in the
  exploration HUD, muddying an otherwise clean block.

## 11. Terrain macro composition and landmarks

Evidence: the wide reads across `ground-05-band5-approach-day/golden`,
`C-02-silhouette-far`, `ground-01/03-…-day`, `S-ext-02-flank-wide`,
`water-02-river-eye`.

**Verdict: ACCEPTABLE — the skeleton still works, and it still points the
player at the worst surfaces in the game.**

What works, unchanged: the band-5 approach axis is real composition —
forked path, pylon line with strung cyan cable, crystal clusters, long
golden-hour shadows (`ground-05-…-golden` is the best macro mood frame
this pass produced); band 3's half-timbered house is a real mid-scale
landmark; band 1's rolling ridgelines compose like the keyart's opening
panel; the castle silhouette still reads at distance.

What reads wrong:

- **The untextured horizon masses are still there.** Band 5's skyline
  carries flat grey slabs at (114,132,128)/(132,146,143) std ~21–28 —
  blank — and a floating pale tan rectangle sits on the skyline in the
  golden variant. The stronghold's west/rear faces are the same
  near-black blank planes they were ((32,34,28) std 2.2 in `C-02`).
  The endgame march still aims at blockout.
- **Aerial perspective is still absent.** `C-02`'s distant fields sample
  (154,160,112) — full near-field saturation and brightness at
  kilometre read; no haze gradient ties distance to the sky, so the
  horizon still reads as a backdrop. The new fog preset proves the
  pipeline could supply this; nothing applies it to clear-day distance.
- **Regional identity is still prop-deep.** Bands 1, 3, 4, 5 share one
  grass carpet, one tree family, one palette; band 2's grove remains the
  only region with its own light. The spec's "increasingly demanding
  regions" is still not something the terrain itself says.

---

## 12. Colour and material — the weighted synthesis

This round's coordinator focus, written from the samples above rather
than repeated impressions.

**The world's value structure is broken at both ends, with a screaming
middle.** In one representative daylight set: castle lit wall **luma
~200** (211,202,185), stronghold gate wall **luma 23** (25,22,16), and
the grass between them **(119,128,42)** — a blue channel at a third of
green. The two hero buildings sit at opposite clipping ends of the value
range while the ground that fills 60 % of every frame runs lime-yellow at
near-full saturation. The keyart never does any of these three things:
its stone is mid-value warm grey, its darkest masses keep legible hue,
and its greens carry blue. Individually each surface has an excuse;
together in one camera pan they are why frames read "AI-built prototype"
even where composition is genuinely good.

**The grass tint is the cheapest, biggest single win.** Every open-field
sample this pass has B ≈ G/3 (42–57 against 128–160). Palworld's fields
and the keyart's both sit closer to B ≈ G/2. This is one material/tint
decision applied everywhere, and it would move every outdoor frame at
once. (ACES caveat, flagged as before: verify on final pixels, not on
the albedo arithmetic.)

**Rock languages: better inside one frame, still plural across the
world.** The Warrens mouth now agrees with its own boulders — the
round's cleanest cohesion fix. But the world still speaks at least four
rock dialects: warm granite at the Warrens ((147,143,123)), near-black
faceted low-poly lumps with painted moss tops on the open meadow
(`01-spawn-outward`, `02-valley-floor`), puffy bevel cobble at the
stronghold, and smooth pale facet-rock on the rise
(`03-rise-overlook`). No two of these would be cast in the same game by
a viewer who saw them side by side.

**Saturation discipline splits by asset class.** Creatures: excellent —
board-true, controlled, nothing fluorescent. Team Tether: correct —
oxblood + cyan reserved and consistent. Flora: still the weak class —
plastic-lime ferns/aloe and sticker-flat purple flowers survive at the
Warrens mouth, and the blade carpet's tint pushes everything toward
lawn-fluorescence in full sun.

**Aerial perspective exists only from altitude.** `03-rise-overlook`
shows real distance desaturation from an elevated camera; at eye level
(`C-02`, distant field (154,160,112)) the horizon still renders at
near-field saturation. The fog preset proves distance haze is available
to the shipped renderer; the clear-day sky just doesn't use it.

---

## Did the previously-named defects actually move?

Named against `JUDGE-VISUAL-2026-08-29.md`, one line each:

1. Castle wall off-white/no coursing — **NO.** (211,202,185) vs last
   round's (212,203,185); identical to the pixel.
2. Castle plinth floating — **YES.** Seated in all four frames, real
   moulding, board-true colour.
3. Miniature mid-wall turrets — **NO.**
4. Untextured placeholder masses in hero vistas — **NO.** One face of
   one mass gained a texture; `C-04`'s (74,87,91)-std-2.5 slab and the
   near-black plane in `C-02` remain, and band 5's skyline still
   carries blank boxes.
5. Stronghold featureless black box — **YES, moved to ACCEPTABLE.**
   Crenellation, energy windows, flags, base course, framed gate.
6. Stronghold cobble scale collision at the approach — **NO.**
7. Warrens three unrelated rock languages — **YES.** One granite family
   at the mouth now; facade (138,134,115) vs boulders (147,143,123).
8. Warrens chamfered-cube boulder silhouettes — **NO.**
9. Warrens plastic fern/aloe/flower confetti — **NO.**
10. Warrens interior GOOD — **HELD.** Guardian silhouette watch item
    improved (white blaze reads).
11. One grass species everywhere — **NO** (bushes/flowers vary; the
    blade carpet doesn't), and near-black blades still mix into lit
    clumps at grazing angles.
12. Mid-distance smear tier tracking the camera — **NO**, plus a new
    striping artefact inside the smear at night.
13. Dashed seam lines on the terrain — **NO**, and they glow at night.
14. Floating path pebbles — **PARTIAL.** Seated on the crust now; none
    embedded in it.
15. Black-rendering NPC/grunt — **YES on material** (oxblood, straps,
    faces read; villagers clean on the stage rig); **watch on
    presentation** (grunt mean body luma 13 in sun still reads as a
    black speck at distance).
16. Golden hour never on the driven clock — **YES, closed.** 17:54 and
    18:06 render warm with long shadows.
17. Deep night unverified (red vignette) — **RESOLVED in the tool,
    judged for the first time**: 22:00 is GOOD; new defect — night
    brightens monotonically from 20:30 to a pale-mint 02:00 (ground
    luma 43 → 78).
18. Sun a flat white ellipse in the golden snap — **YES, fixed** (real
    halo falloff, std 57 across the disc patch).
19. Sky/ground weather disagreement (navy ink-blots over sun) —
    **MOSTLY.** Softened to tan/cream streaks; traces remain in band 4.
20. Fog preset rendering nothing — **YES, fixed** (mean abs diff 55 vs
    day).
21. Night foliage self-lit canopies at dusk — **NO.** 20:00 canopies
    still render near-daylight green over a dusk ground.
22. No aerial perspective at eye level — **NO.**
23. River riprap/canal banks — **NO.**
24. Stream invisible from its own bank — **NO.**
25. Pond's ownerless rectangular shadow — **NO.**

Scorecard flavour: the sky/light lane and the Warrens-cohesion and
stronghold-articulation work genuinely landed. The castle colour — the
owner's own named complaint, and the subject of two prior rounds — did
not move at all, and the world-scale ground defects (seams, smear,
stream, river banks, horizon boxes) are all still standing.

## §25's target question

> *Would someone seeing 30 seconds of normal gameplay, with no
> explanation, think this is a deliberately art-directed finished
> stylised game rather than an AI-built prototype?*

**If the 30 seconds stay in bands 1–3 in daylight or at 22:00 — closer
than ever, genuinely plausible.** The trainer, the creature roster, the
path language, the pond, the grove and the new night are all pulling the
same direction now, and the HUD doesn't break the spell.

**Over any 30 seconds that includes a building, the horizon, or
02:00 — no.** The castle answers the question by itself: a white
maquette at luma 200 next to a blank grey slab reads as placeholder in
one glance, and the approach march aims the camera at exactly that. The
dashed seams and the smear tier are the tells everywhere else.

So: **no overall**, by a narrower margin than the first pass, and for
the first time the "no" is concentrated in a shortlist you could
actually burn down: castle wall values, horizon boxes, seams, smear
tier, grass tint, 02:00.

## The two bar questions

**A. Do these frames belong to the keyart's world?** **No — but bands
1–3, the pond, the 22:00 night and the whole creature roster
individually do.** What breaks belonging is unchanged in kind from the
first pass: the built architecture (castle above all) and now the
post-midnight wash. The list of belonging frames got meaningfully
longer this round; the list of breaking causes barely shrank.

**B. Beside the Palworld references, would someone say this is trying
to be the same kind of game?** **Yes for the open world and the
creatures — no overall, and the flip still happens the moment a
structure enters frame.** `ground-03-…-day` and `_portraits.png` beside
`palworld-02`/`-01` read as the same genre at a comparable ambition;
`C-01` beside `palworld-04`'s tower still reads as blockout beside a
believable mass. Since the chapter's climax is architecture, the
overall answer stays no.

## Fixable by changing the scene vs. needs art not in the build

**Scene-fixable (materials, tints, lighting, composition on existing
meshes):** the castle wall value-ladder retune (the plinth already
demonstrates the correct target colour — sample it and drive the wall
there on final pixels); the grass B-channel tint; the dashed seams; the
smear-tier boundary and its night striping; the post-midnight
brightening curve; dusk canopy self-lighting; aerial-perspective haze
on clear days (the fog preset proves the machinery exists); re-tinting
or replacing the meadow's low-poly moss-top boulders and the rise's
pale facet rock toward one family; the Warrens fern/aloe/flower
confetti; the stream channel cut and banks; the river bank texture
scale; the pond's ownerless shadow; the stronghold approach cobble
scales and a mid-value stone tier + brass trim on its facade; the
starter picker's creature facing; the gate daylight leak; textures on
the remaining blank faces of the placeholder masses (or their removal
from hero sightlines).

**Needs art that is not in the build:** a weathered stone material set
with coursing-scale detail and openings/gate modules for the castle kit
(unchanged from the first judge's list — nothing landed against it);
proper boulder meshes (the chamfered-cube silhouettes cannot be
material-fixed); and a second grass species/tuft asset for the carpet.
Everything else that failed this round failed on placement, tint or
lighting, not on missing assets.

---

## Lane-report reconciliation — WRITTEN LAST, after all verdicts

Read after every verdict above was committed and pushed: all nine
`handover-*-2026-08-30.md` files, `HALL_DESIGN_2026-08-30.md`'s handover,
and the ten branches' commit logs. Both sides of every disagreement are
recorded; nothing above was rewritten.

### Where the reports and my frames agree

- **T1-GROUND's grunt fix is real and its honesty is exact.** Its
  before/after (band 2's picket, "Dorn") matches my zoom precisely —
  collar, straps, mask now read — and its own caveat ("Dorn is still a
  fairly dark figure… if the owner wants him brighter, the next lever is
  a rim/ambient floor, not another palette push") is my measured luma-13
  finding, said in advance. One identification correction falls out for
  free: the figure the first judge logged as a **villager** rendering
  black on the band-2 path was almost certainly this same Team Tether
  grunt — no villager material path was ever broken (my stage rig shows
  all five villagers clean).
- **T1-SKY's account matches the sweep I rendered.** Golden hour on the
  driven clock: fixed by config (weather leak + sun disc + cloud tint),
  and my 17:54/18:06 frames confirm it. Deep night: blue, real, first
  time judged — its parking fix is why. Its analysis that the ranger-camp
  stand "was never a sky beauty shot" also matches what I saw: warm and
  correct, not the keyart sunset, and that is now a composition question,
  not a lighting bug. Its fog measurement (the visible change is
  `shadow_opacity` removal, not distance haze) **refines my subject-7
  verdict**: I recorded fog as "moved"; it did move, but T1-SKY is right
  that nothing in it yet reads as *air* — both statements stand.
- **T1-WARRENS-EXT's four fixes are all visible in my blind frames**:
  one granite family at the mouth (my sample pair (138,134,115) vs
  (147,143,123)), no mint rock, no crimson bush, no checkerboard
  aliasing, and a real lintel/jamb on the mouth door. My remaining
  complaints (chamfered-cube silhouettes, one noise frequency, the
  bright fern/flower confetti) are exactly the items its handover did
  not claim to fix.
- **T1-GROUND's unfixed items match my unmoved verdicts** — stream
  (root-caused as a siting problem plus zero bank dressing; not fixed),
  river bank angle (measured 59–77° along all 19 points; deliberately
  not touched), dashed seams (reproduced, two hypotheses, not
  isolated). My "did not move" lines on those are its own honesty
  confirmed, not a contradiction.
- **T1-HALL-DESIGN explains the castle.** The owner has directed a
  merge: the castle IS the Meadows Hall IS the stronghold — one
  location, redesigned (design doc complete, implementation not
  started; the detached castle at (150,7595) is slated to retire). **No
  lane worked the castle walls this round**, so my "identical to the
  pixel" measurement is expected, not a third failed fix — but it
  should stop being read as a queue of failed retints and start being
  read as the strongest argument for building the merged Hall soon: the
  white maquette is still what the player sees today, and its material
  scheme in the design (one textured `T_UnevenBrick` stone with
  value-checked retints) is aimed at precisely the defect my samples
  re-measured.

### Where a report claims more than the frames show

- **T1-WARRENS-EXT (implicitly): vegetation confetti at the mouth.**
  The skirt-placer fix dropped `Plant_1` and retinted the skirt flora,
  and the specific crimson bush is gone — but plastic-lime ferns and
  flat purple flower sprites still sit in the foreground of my
  `W-ext-01/02` frames, evidently from a different scatter layer. The
  confetti finding is narrowed, not closed.
- **T1-GROUND's pebble fix was "done-but-under-verified" by its own
  admission** — my frames partially close that: pebbles now sit seated
  on the path crust (improvement verified in-world), but none are
  half-buried, so the "sprinkled, not worn" read remains.
- **T1-GROUND's groundmat/clover restore is still unverified.** I
  cannot confirm a visible clover mid-layer in any band frame I
  rendered; whether 145k restored placements actually read on screen
  needs its own deliberate before/after look.
- **T1-SKY's "weather disagreement not reproduced" is nearly right.**
  Band 3's day sky is clean in my frames too; band 4's day frame still
  carries dark smudge clouds in the top-left over sunlit ground.
  Softened materially; not fully gone.

### Where the repo's evidence overturned or nuanced my blind read

- **The starter picker's back-facing creatures**: T1-UI records round
  3's attribution — the preview turntables spin ~69°/frame against
  software-render frame timing, so a still capture catches arbitrary
  facings; a live player sees rotating creatures. My observation stands
  as a fact about stills but drops as a HUD defect. Counterpoint kept:
  two independent captures have now caught **all three** back-turned at
  once, so if the spin phase is deterministic at boot, the first
  rendered impression may genuinely be three rumps — one deliberate
  start-angle would erase the question.
- **The Warrens mouth "office lobby" doorway**: the lintel band and
  jamb I photographed are the new, intended door frame working — my
  residual complaint is only that the liner panels behind it read flat
  grey, not that the doorway lacks depth.
- **My castle framing needed the design context above** — "did not
  move" is true of the pixels and misleading as an indictment of this
  round's lanes; recorded both ways.

### Findings no lane report mentions (new this pass)

- **Night runs backwards after midnight** — ground luma climbs 43 → 78
  from 20:30 to 02:00, ending in a flat pale-mint shadowless wash
  (subject 7a). T1-SKY's own hour-02.00 was used only for the canopy
  check; nobody names the brightening.
- The dashed terrain seams **glow lighter than the ground at night**,
  and the night smear tier carries a diagonal striping artefact.
- Daylight leaks across the top of the stronghold's open gate interior
  (`S-ext-01` zoom).
- The pond's ownerless rectangular shadow survived the round.
- The open meadow's dark low-poly moss-top boulders
  (`01-spawn-outward`, `02-valley-floor`) are a fourth rock language no
  lane owns.
- The practice meadow still shows flat plastic-green ground, a giant
  hard-edged shadow polygon, and a floating white prompt quad
  (`habitat/practice-meadow-cluster.png`) — with the capture-rig caveat
  flagged in subject 9.
- Moonlit shadow boundaries at 22:00 quantise into large stair-steps
  (llvmpipe caveat attached; block size well above "fine lighting").
- `tools/survey.gd`'s `05-spawn-low-sun` stand rendered a flat frame
  ("nothing rendered", the tool's own FAIL line) — one more capture
  stand needing the streaming/settle fix its siblings got.
