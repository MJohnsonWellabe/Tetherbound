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
