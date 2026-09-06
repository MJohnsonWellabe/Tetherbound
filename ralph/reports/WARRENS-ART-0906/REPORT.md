# WARRENS-ART-0906 — Burrow Warrens art gaps W1, W3, W5 and the §5.2 leftovers

Branch `claude/art-warrens-round-0906`, from `claude/second-biome-art-plan-470zru`
(which carries the main merge, Cloudreach cliff option A and the crown-relief work).

Gap table: `docs/HANDOFF_2026-09-06.md` §4.3. Six prior exterior judge rounds and
their trajectory: `ralph/reports/WARRENS-EXT-0906/REPORT.md`.

## The owner's standing correction, and what it changed

> "There is art in the repo for most of these things already, like mushrooms and
> team tether stuff. Find it and use it. Recolor it if you need to. Don't use Meshy."
> — owner, 2026-09-06

This overrides the handoff's own W1 row, which proposed downloading the AssetQuest
Free Mushroom Asset Kit (54.8 MB). **Nothing was downloaded in this lane and no
Meshy generation was spent.** The repository already held six mushroom
silhouettes; the two the gap actually needed were sitting un-installed in
`assets_raw/vendor/quaternius_stylized-nature-megakit/`, one `cp` away, sharing a
texture that was already installed. Every other asset this lane places —
`DeadTree_1/2/3`, `TwistedTree_1/2/4`, `stump_round`, Kenney `tree-log` — was
already installed and needed no ledger row of its own.

(Placeholder: verdicts and measured evidence are appended below as rounds land.)

## Round 1 — measured on the lane's own frames, before any judge was spawned

`docs/HANDOFF_2026-09-06.md` §6 trap 9 says to measure exposure yourself before
spawning a judge, because the judge reads it off the PNG and a wasted round costs
15 minutes. Measuring found three defects loud enough that a judge round on these
frames would have been spent on them, so they were fixed first. Rec.709 medians,
`shots/warrens_63/`, 1280x800, day, software GL:

| frame | median Y | p05 | p95 | floor-band Y | floor-band RGB |
|---|---|---|---|---|---|
| 00-approach-60m | 122.7 | 22.0 | 186.9 | 126.4 | 126,129,106 |
| 01-knoll-from-outside | 125.6 | 47.5 | 184.9 | 107.6 | 105,110,89 |
| 02-knoll-from-outside | 116.7 | 54.6 | 189.2 | 106.4 | 97,111,91 |
| 03-mouth | 54.8 | 7.3 | 171.5 | 48.3 | 59,47,30 |
| 04-hall-dressing | **24.6** | 7.7 | 109.1 | 92.4 | 108,90,66 |
| 05-hall-from-the-doorway | 123.2 | 10.8 | 188.9 | **159.1** | 185,156,114 |
| 06-den-and-guardian | 54.0 | 9.0 | 103.3 | 66.9 | 76,66,51 |
| 07-den-dressing | 43.1 | 9.1 | 84.8 | 74.0 | 86,72,55 |

**1. The new earth collar was the brightest object at the entrance** (03-mouth,
01-knoll): a cream ring around a black hole, reading as bone or plaster, not as
compacted earth — and about 3.3 m of collar around a 5.9 m arch, a hood rather
than a rim, with a sawtooth silhouette from ~11 lobes and ~54 grain cycles around
the arch.

Root cause is not the collar: it is that the bank's `earth_tint` (#f0ece4 at
`earth_brightness` 1.5) is tuned to lift the *sunlit dug face* against a pale
meadow, and a hole's rim is not a sunlit face. The Compatibility renderer has no
SSAO and no light volumes, so nothing darkens the inside of a concave form. Fixed
by giving `earth_bank.gdshader` a baked contact-occlusion term on **COLOR.a** and
having the collar write a ramp into it — dark at the rim, reaching exactly 1.0 at
the outer edge so the collar and the mound still match where they touch. This is
a no-op for everything that existed before it: `_build_bank()` and
`_build_bank_cap()` write vertex colour through `_bank_add_vertex()`, whose
`Color(frac, moist, spoil)` leaves alpha at Godot's default 1.0. The alternative
— moving `earth_tint` — would have repainted the whole mound, which a previous
lane judged over six rounds.

Size halved, lobe and grain frequencies dropped to a few broad lobes.

**2. Three of the new root masses came back as dark maroon blobs** (03-mouth,
01-knoll). `TwistedTree_*` ships `Leaves_TwistedTree`, the pack's crimson autumn
texture. This is the same asset and the same texture as the "red tree" the
previous lane spent three judge rounds chasing
(`ralph/reports/WARRENS-EXT-0906/REPORT.md`), and `_tint_rock()` multiplying a
root brown over crimson only makes it darker crimson. A root mass has no leaves
at all, so the fix is not a retexture: every entry is now `DeadTree_*`, which
carries `Bark_DeadTree` and nothing else.

**3. Two value inversions.**

- The earth-clad hall bay came back at a frame median of **24.6** (04) — earth so
  dark it reads as a hole, not a wall. `exterior_cladding_colour` (#4a3a2a) is
  tuned for full daylight *plus* the mouth dome's shadow; underground, against
  stone that is `rock` lerped 45 % toward a near-white tint, it is the wrong end
  of the same problem. New `site.interior_cladding_colour`, ~1.5x, applied to the
  interior skins only — `_clad_exterior_face()` is deliberately left alone.
  Absent, the key is a no-op and every skin is byte-identical to before.
- The mouth->hall beacon mushrooms were **brighter than the floor they stand on**
  (05: floor-band median 185,156,114; the caps read above 200 in all channels) —
  a stand of pale mint parasols filling the frame. Two causes: `scale_mul` was
  picked per species by eye, and `Mushroom_Oyster` is a multi-cap mesh, so four
  instances put twelve caps in a 3 m passage. Every multiplier is now derived
  from the model's own native height (0.46 / 0.92 / 1.78 m) so all three land
  near 0.46 m at a cluster scale of 1.0; emission roughly halved and the albedo
  tints dropped about a quarter. Glowing fungus has to sit *under* the lit floor
  in value or it stops being a light source and becomes the subject.

**Also fixed this round, the §5.2 leftover.** The "thin pale sliver at the tube's
right foot" is measurable, not a guess: the apron ramp tapers to a **2.30 m**
half-width at the throat's outer end while the throat shell there is flared
(`throat_flare` 0.18) to **2.95 m**. The ramp is 0.65 m narrower than the hole it
ends in, at both feet, and what shows in the gap is raw pale terrain inside a dark
tube. The taper's own stated reading ("the trample spreads wide at the threshold
and narrows further off") is not what the numbers do either — the wide end is the
doorway, 8 m *inside* the throat. Fixed by construction rather than by re-tuning a
width: the ramp is never allowed to be narrower than the throat standing on it,
for any `throat_flare` and any taper a later pass picks.

**The other §5.2 leftover, the pale terrain strip at the threshold, is left
alone deliberately.** `tools/_probe_warrens_threshold_render.gd` already
established what it is: the terrain's own baked dirt-path road arriving at the
mouth. A road that arrives at the den mouth is the world working, not a defect,
and `meadow_grass_Color.png` and the Meadows terrain bake are out of this lane.

## Owner directive, 2026-09-06, on this lane's first render

> "the interior looks a little cramped for that creature. should be taller.
> exterior look better but can still be improved."

**Interior height.** The den guardian is a Burrowback at 3.57 m (measured last
lane) and the den ceiling was 4.8 m: 1.2 m of air over its head, of which
`interior_structure.rib_drop_m` takes 0.34 back, so the boss stood
shoulder-to-beam in its own chamber (frame `06-den-and-guardian`). Per CLAUDE.md's
own scale rule — *resolve relative-scale defects by growing the smaller side,
never by shrinking* — the room grew, not the creature:

| chamber / passage | was | now | why |
|---|---|---|---|
| den | 4.8 | **7.0** | the guardian is now 51 % of its own room's height, 3.4 m over it |
| hall | 4.2 | 5.6 | the room the player walks into, and where the earth bay is |
| warren, vault | 3.4 | 4.0 | kept in proportion with the two big rooms |
| hall→den passage | 3.4 | 4.4 | round 6 measured the guardian's shoulder at 85–90 % of this door |
| mouth, mouth→hall | 3.6 / 3.0 | unchanged | tied to `bank.arch_height_m` and the throat — moving them moves the front door six judge rounds settled |

Two knock-ons were re-authored with it rather than left to rot. `roots.pieces.tip_y`
per chamber: a root crown authored to hang just under a 4.2 m ceiling is a floating
bush under a 5.6 m one, and its trunk has to stay buried in the ceiling slab (every
piece re-checked: shortest trunk top is 6.5 m against a 4.0 m ceiling, tallest 9.0 m
against 7.0 m). And the `lights` y/range/energy for the four rooms that grew — in
particular the den's warm key moved from y 3.1 to 4.6, i.e. from *below* a 3.57 m
creature's head to above it.

The mound over each room needed no authoring at all: `_bank_chamber_bumps()` derives
its cone from the chamber's own height plus `clearance_m` + `safety_m`, so the
enclosure promise holds by construction. Re-measured after the change:

```
[warrens] chamber clearance past the required 1.5m: mouth +11.8m, hall +2.8m,
          warren +3.5m, den +2.9m, vault +4.7m (worst 2.8m)
[fixture] chamber enclosure: 5 chambers checked, highest cover hit 0.3m above the mouth
[fixture] skyline from the approach: 3 local maxima with >=1.0m prominence:
          x=-21.0 h=16.2m, x=+0.5 h=18.1m, x=+19.0 h=15.2m
WARRENS FIXTURE OK
```

(the two flank maxima gained 0.6 m each: the heaps over the warren and the vault
rose with the rooms under them, which is the mound telling the truth about what it
covers.)

**Exterior.** The round-1 fixes named above — the collar's value, size and
silhouette, the maroon `TwistedTree` root masses, and the apron/throat sliver —
were all still unrendered when the directive arrived. They go into the next sheet,
and the blind judge names what is left rather than this file guessing at it.

## Round 2 — measured on the round-1 re-render

Rec.709 medians, same capture, before/after round 1:

| frame | median Y (r0 → r1) | floor-band Y | what moved |
|---|---|---|---|
| 03-mouth | 54.8 → 51.8 | 48.3 → 46.2 | collar occlusion landed |
| 04-hall-dressing | **24.6 → 52.8** | 92.4 → 101.6 | `interior_cladding_colour`: earth reads as a wall, not a hole |
| 05-hall-from-the-doorway | **123.2 → 73.7** | 159.1 → 159.3 | mushrooms stopped being the subject; the floor did not move |
| 07-den-dressing | 43.1 → 46.6 | 74.0 → 87.7 | ditto, den passage |

The maroon root masses are gone and the collar is no longer cream. Two things
the re-render still shows, both fixed this round:

**1. The collar traded a sawtooth for a pipe.** Round 1 cut `brow_noise_m` to
0.16 and `brow_lobe_freq` to 0.06 and the collar came back *smooth* — a rounded
band of near-uniform thickness, which is precisely the W5 gap ("reads as tubes"),
just olive instead of chocolate. Grain and lobes are put back between the two
extremes (~27 cycles and ~6 broad lobes, against round 0's 54 and 11). The
structural change is in code, not config: `width_scale` now drives the crest's
**proud** offset as well as its radial one, so a lobe pushes out *and* forward and
the crest **line** wanders in z. A crest line that runs true along the arch is what
reads as a pipe from 16 m, whatever the thickness is doing.

**2. The pale sliver survived the round-1 fix — the measurement corrected the
guess.** Cropped and sampled at the throat's right foot in `03-mouth.png`: a flat
near-white wedge at RGB **[162,157,134]**, and it is the **bank's own surface**
where `_bank_notch_open_factor()` stops holding the mound open, caught at a
grazing angle. Round 1 measured the apron ramp against the throat *shell*
(2.95 m) when the bare, un-mounded ground actually runs to the *notch's* edge
(`arch_width_m * 0.5 + arch_margin_m` = 3.60 m, plus its own 0.6 m taper ≈ 4.2 m),
so the ramp still stopped 0.4 m short at each foot. It is measured against the
notch now (`_mouth_notch_half_width()`), which is the thing that actually decides
where the mound stops.

The tonal half is the same root cause as the collar: `earth_tint` #f0ece4 at
`earth_brightness` 1.5 is tuned for the broad sunlit dug face, and *any* small
piece of bank caught at a grazing angle reads white at that value. Rather than
repaint a mound a previous lane judged over six rounds, this uses the mechanism
that already exists for it — the damp band around every opening. `moist_radius_m`
3.0 → 4.5 and `moist_darken` 0.35 → 0.55, which is also the SECOND-PASS brief's
own words ("a darker moist band within 2 m of every hole and the mouth").

## The guardian is not floating — measured, not assumed

`06-den-and-guardian` reads as though the boss hovers. It does not, and the new
`tools/_probe_warrens_guardian_stance.gd` says so on a real boot of the real scene:

```
PROBE floor plane y = 4.148
PROBE guardian origin y = 4.149  (origin - floor = 0.001)
PROBE is CharacterBody3D, on_floor=true velocity=(0.0, 0.0, 0.0)
PROBE collider Collision shape=CapsuleShape3D origin_y=5.934 (1.786 above floor)
```

The body is on the floor, at rest, its origin a millimetre above the floor plane.
What reads as a hover is the **mesh's own feet sitting above its origin**, magnified
by the 3.57 m scale — a creature-mesh matter, which `docs/HANDOFF_2026-09-06.md`
§4.3 W4 puts under "creature art locked / owner call" and this lane's brief
explicitly fences off ("do not touch creature meshes or `creature_visual.gd`").
**Left alone deliberately, and recorded here with the numbers so whoever owns it
does not have to re-derive them.** Note the probe's visual-AABB line is not
evidence of anything: it merges the *rest-pose* bounds of skinned meshes, which is
why it reports a nonsensical 16 m span.

## Blind verdict — `JUDGE-round1.md`, against the three gaps this lane owns

The judge saw the sheet and the eight frames, the two references and the skill,
and nothing else — no source, no config, no history, no statement of what changed.
Its full text is in `JUDGE-round1.md`. Scored against the handoff §4.3 rows in the
judges' own words:

| gap | round 6 (before) | round 1 of this lane (after) |
|---|---|---|
| **W1** "Mushrooms are plain domes, no gills or cap profile" | named | **not named.** `05`'s cluster is now called "the single best-shaped thing in the interior". A NEW complaint replaces it: the mushrooms read 1.5–2 m, "larger than its guardian, which inverts the hierarchy". |
| **W3** "Interior rooms read as a stone box" | named | **still named, and ranked #3**: "reads as a rectangular basement, not a dug den". Worse, it names the seam this lane's own partial cladding created — "`04` uses a brown dirt-and-gravel wall while `05`/`06`/`07` add a grey speckled granite for the same structural role — two unrelated rock materials in adjacent rooms with no transition, so the burrow has no material identity". |
| **W5** "Burrow-arch reads as tubes, not compacted earth and roots" | named | **not named.** `03-mouth` is now "a genuinely good arch silhouette — the mossy lintel over a dark opening with grass fringing the top is a real piece of landmark language and it is the best-composed frame here." |
| §5.2 tube-foot sliver | recorded as remaining | **not named** at any size. Below the threshold that matters, on frames rendered before the round-3 overlap fix. |

So: **W5 closed, W1 closed on its own terms, W3 not closed — and half-doing it
made one of its symptoms worse.** A bay of earth beside unclad stone is two
materials where there was one. That is a real cost of the partial approach and it
is this lane's to carry.

### New defects the verdict names that are inside this lane's files

- `03`: "the root/branch dressing hanging over the arch is a flat black scribble
  with no thickness or overlap; it reads as a decal, not geometry" — the new
  `brow_root_meshes`, silhouetted against bright sky.
- `03`: "a **red-and-white striped pole with a white ball on top** ... reads as a
  barber pole, a survey stake or a debug marker, and it is the single most
  saturated red in the whole survey". That is the Team Tether lamp post, which
  round 6 asked for and which now reads as left-in placeholder.
- `03`: "the bottom 40% of the frame is a single smooth chocolate-brown mass with
  no texture, no scatter and no detail" — the threshold fan.
- `03`, `01`: "the moss on the boulders is a bright green band painted only on the
  upper faces with a hard straight edge where it stops — reads as a decal stripe".
- `05`: the beacon cluster sits ~1 m from the capture's own eye, which is why it
  measures 1.5–2 m against a doorway 10 m behind it.

### What the verdict names that is NOT this lane's, recorded so it is not lost

- **The guardian** (its ranked #1): style seam at the neck, two texel densities,
  dog scale, no staging. W4 / owner call, and creature meshes plus
  `creature_visual.gd` are fenced off from this lane. **One caution for whoever
  takes it:** the judge measured against "a doorway a 1.80 m trainer walks through
  is ~2 m". After this lane's owner-directed height pass those passages are
  3.2–4.4 m, so the absolute figures ("under 1 m at the shoulder") rest on a wrong
  premise. The *finding underneath* still stands and is the useful part: a blind
  viewer had no scale cue in that room and read the boss as dog-sized.
- **The meadow ground** (its ranked #2): grey not green, bare substrate between
  isolated blades, evenly-spaced one-scale scatter, no atmospheric perspective.
  This is W2 — Meadows-wide terrain palette and grass field, explicitly not this
  lane, and it shares a root cause with Cloudreach's C1.
- **"The exterior has no sun"**: no cast shadows on terrain in `00`/`01`/`02`,
  while `01`'s crate and `03`'s near ground both have crisp ones. That pattern is a
  directional-shadow range limit, not a missing light — `art.json` and the renderer,
  Meadows-wide.
- **Asset-set gaps** the judge says the scene cannot fix: the tree set (two
  silhouettes, flat leaf cards, off-palette trunks), the ground-cover set, the rock
  set (facet slabs with a painted moss band), and an organic tunnel kit for the
  interior.

## Round 3 — acting on the verdict

W3 done as the verdict asked ("pick ONE wall rock material for the burrow")
rather than as the handoff asked ("the hall's first bay and the passage walls").
`site.earth_clad_walls` clads all four walls and the ceiling underside of every
chamber; the hall's partial bay retires to an empty list. Evidence in the smoke
output:

```
[warrens] 38 interior earth skins across 5 walls-clad chamber(s) and the passages
warrens smoke test passed
SMOKE_EXIT=0        ERROR lines: 0
```

The four `03-mouth` defects the verdict named in this lane's files are fixed:
the lamp (hood, amber bulb at emission 3.2 instead of a white-clipping 7.0,
oxblood moved from an eye-height ring to a foot collar), the arch roots (three
thin crowns became two at half again the scale, overlapping, over a lighter
tint), the boulder moss (`moss_normal_min` 0.5 → 0.22 — that threshold *was* the
hard edge the judge saw), and the threshold debris (40 → 85).

**A regression this round introduced, recorded rather than hidden:**
`07-den-dressing` fell from a frame median of 46.6 to **32.0** when the den's
walls went from pale stone to earth. The material identity is right and the value
is now wrong; the den's own lights were tuned against a wall albedo that no longer
exists. `site.interior_cladding_colour` and the den pools are the levers and this
is the next thing to measure, not something to leave for a reader to discover.

**A second-order defect found while checking the lamp.** The post rendered
near-white whatever its albedo said, because the lamp's `OmniLight3D` was
parented at the post's own axis — the post was lit at zero distance. That is half
of why the verdict read "a red-and-white striped pole": not the colour, the
lighting. `lamp_throw_m` stands the light 0.45 m out toward the road while the
bulb and hood stay on the post, since a light source does not have to be the
thing you see.
