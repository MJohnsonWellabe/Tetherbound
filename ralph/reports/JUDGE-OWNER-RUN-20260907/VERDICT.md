# Blind visual verdict — owner kickoff run 20260907T023802Z

**Frames:** GPU-rendered on the owner's ROG Ally (AMD Radeon, Compatibility),
from `ralph/reports/OWNER-KICKOFF-20260907T023802Z/frames/`. Judged: `survey`,
`composition`, `places`, `locations`, seven `route_day` sheets sampled across the
corridor (001/004/008/012/016/020/024), three `route_night` (002/007/012).
**Critic:** blind sub-agent under `.claude/skills/visual-judge/`. It was told
nothing about the run, the project's history, what had changed, or what was
hoped for. It did not see the frame-rate data and was not told the budget (D06).
**First GPU-rendered frames the judge has ever been given** — previous rounds
were software-rendered survey captures.

## Bar questions

**A. Do these belong to the world of `tetherbound-meadows-keyart.png`?**
**Partially yes** — and the split is by location type, which is the useful part.
*Carried it:* the half-timbered village (`locations` rows 1/4/5) is a direct
match for the keyart's STARTING SETTLEMENT panel; the Team Tether courtyard
matches the STRONGHOLD panel's colour discipline; `survey` tile 5 at dusk
genuinely belongs to the sunset panel. *Sank it:* the wilderness between those
places does not belong to that board at all — one hue of grass, no aerial
perspective, a horizon that is a flat green wash, a sky that never changes
across 24 stages, and a night that is the day render multiplied down.

**B. Beside `palworld-0*.jpg`, is this trying to be the same kind of game?**
**No.** Across 84 route tiles creatures appear in maybe eight, always small,
always low-contrast, never the subject. Nothing in these sheets says the game is
about creatures.

## The three biggest gaps, ranked

1. **The chroma budget is inverted.** Palworld holds a muted sage-and-tan ground
   so creatures and the player carry all saturation and pop at any size. Here the
   *ground* is the most saturated thing in frame — acid yellow-green grass,
   orange-brown path — and creatures the least. The tan deer in `route_day_020`
   r4c1 disappear entirely at thumbnail. A colour-allocation decision, not a
   modelling one, and the single highest-value fix.
2. **23 of 24 route stages have no landmark.** `route_day_008` and `_012` contain,
   across 24 tiles, nothing a player could navigate by, name, or return to. The
   exception is `route_day_024` — Team Tether pylons with the cyan cable, and the
   fort on the ridge — which is the only genuine landmark language in the set and
   proves the build can do it.
3. **The creature art is three incompatible languages.** The rock-shelled tortoise
   (`locations`, boulder-field tile) is stylised, chunky and matches the world.
   The blue raptor (`route_day_024` r2c3) is a recoloured photoreal eagle. The
   spotted quadrupeds (`route_day_020` r4c1) are generic photo-fur. A badger-headed
   rock shell in the tortoise's own tile splits the difference inside one
   silhouette. The trainer and the villager beside him (`locations` r3c1) are in
   two different character styles.

## Named defects worth logging separately

- **Broken camera stands** (harness, not art): camera inside the trainer's legs
  with hands detached (`locations` ~r13c1); inside an untextured grey box
  (`route_day_001` r3c2); two solid dark-green tiles with the camera inside a
  canopy; a robed NPC clipping the near plane in `survey` tiles 1 **and** 5, both
  framed survey stands.
- **Hard shadow-distance band** — a razor-edged diagonal of darkened ground with
  no caster, `survey` tiles 1 and 5. Reads as a cascade/shadow-distance cutoff.
- **Oxblood leak onto friendly elements** — the wayfinding arrow in
  `route_day_016` r2c1 uses the faction danger colour in open friendly meadow,
  and is flat-shaded/untextured; same colour on a friendly camp banner in
  `locations`. The fort tiles use it correctly; these two dilute it.
- **Team Tether grunt is grey-on-grey** — the antagonist soldier is the least
  readable character in any frame.
- **Tree scale ladder is broken** — `composition` r1c1 has a ~1.8 m diameter trunk
  (implying a 25-35 m tree) in the same frame as mid-band trees ~4 m tall, with
  nothing between. Recurs in `composition` r2c1-2 and `route_day_012` r1c1.
- **Hard scatter radius** — grass/flower detail stops dead in a ~4 m bubble around
  the camera, most visible in `locations` ~r13c1 and `route_day_012` r2c1.
- **No aerial perspective** — `survey` tile 3 is a flat texture-free green wash
  meeting the sky at a hard line.
- **Night is a multiply** — `route_night_002` r1c2 is a near-black rectangle;
  clouds stay brighter than the ground, inverting real night contrast. No rim
  light, no bounce, no second light colour. `route_night_012` is much better and
  only because the pylons emit their own cyan light.
- Water is a flat plane with a hard bank line (`places` r1c3); path material
  carries no detail despite being the largest area in most frames; canopy cards
  intersect with visible seams; sky texture never varies.

**Scale passes where it was checkable:** fence rail at the trainer's chest,
boulder ~1.5x his height, village houses ~9 m to ridge. Props and architecture
agree about a metre. Trees do not.

## Fixable in the scene vs needs art that is not in the build

**Scene (density, palette, lighting, composition, scatter):** desaturate/de-yellow
the ground and give the chroma to creatures and the player; recover the dark end
of the day value range; add aerial perspective; fix the shadow-distance band; push
and fade the scatter radius; author the scatter (cluster, cut clearings, vary prop
scale) instead of distributing it evenly; relight night; fix the tree scale ladder;
take oxblood off friendly props and texture them; fix the broken camera stands;
water depth gradient and shoreline blend; path material detail; sky variation.

**Needs art:** a coherent creature set (the raptor and deer cannot be brought into
line with the tortoise by lighting or placement — different art philosophies);
character style unification between trainer and villagers; a readable Team Tether
grunt silhouette; landmark geometry for the 23 stages that have none (the keyart
names a windmill, a watchtower, a peak and a standing rune stone — none exist in
these frames); a distant silhouette layer for the skyline; tree assets with a real
size range.

## Note for whoever acts on this

The judge's "push the scatter radius out" and "author denser, clustered scatter"
pull **against** `docs/PERF_ALLY_FIRST_MEASUREMENT_2026-09-07.md`, which finds six
of nine stands under 8 fps on this same machine and suspects grass fill rate. The
two highest-value visual fixes here — desaturating the ground and giving chroma to
creatures, and adding landmarks — are both free of that tension. The scatter and
density items are not. Settle the grass A/B before spending anything on those.
