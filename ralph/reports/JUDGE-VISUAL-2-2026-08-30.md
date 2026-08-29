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

---
