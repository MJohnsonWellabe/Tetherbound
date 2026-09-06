# WARRENS-ART-0906 — Burrow Warrens art gaps W1, W3, W5 and the §5.2 leftovers

Branch `claude/art-warrens-round-0906`, from `claude/second-biome-art-plan-470zru`
(which carries the main merge, Cloudreach cliff option A and the crown-relief work).
**No pull request opened**, per the brief. Written to be picked up cold.

Gap table: `docs/HANDOFF_2026-09-06.md` §4.3. The six prior exterior judge rounds and
their trajectory: `ralph/reports/WARRENS-EXT-0906/REPORT.md`.

---

## 1. Scoreboard

| gap | round 6 (before) | blind round 1 | blind round 2 | status |
|---|---|---|---|---|
| **W1** mushrooms are plain domes, no gills or cap profile | named | not named | not named, **praised**: "the only object in any interior frame with a designed silhouette … It reads at thumbnail size. Nothing else indoors does." | **CLOSED** |
| **W3** interior rooms read as a stone box | named | still named, **and the partial cladding's own seam named** | material half gone; what remains is "hard 90° extruded prisms … nothing says *dug*" | **MATERIAL HALF CLOSED, GEOMETRY HALF OPEN** — see §4 |
| **W5** burrow arch reads as tubes, not compacted earth and roots | named | not named | not named, **opens the verdict**: "`03-mouth` is the best frame in the survey and it is genuinely good" | **CLOSED** |
| §5.2 tube-foot pale sliver | recorded as remaining | not named | not named | **CLOSED**, measured: 219 → **0** bright pixels |
| §5.2 pale terrain strip at the threshold | recorded | not named | not named | **left alone deliberately** — it is the terrain's own baked road (§6) |
| **W2** meadow ground pale and sparse | (not this lane) | judge's ranked #2 | judge's ranked #1, with numbers | **NOT THIS LANE**, evidence in §6 |
| **W4** guardian proportions / style | (not this lane) | judge's ranked #1 | judge's #2; **withdraws** its own round-1 scale finding | **NOT THIS LANE**, evidence in §6 |

Verdicts in full: `JUDGE-round1.md`, `JUDGE-round2.md`. Both agents were given the
skill and the two references and nothing else — no source, no config, no history, no
statement of what changed. Round 2 was additionally told **not** to assume a doorway is
2 m, because round 1's absolute scale figures rested on that and this lane's
owner-directed height pass had already invalidated it.

---

## 2. What was closed, and how

### W1 — mushrooms (`fungus.species`)

Two causes. Only one species was placed, and `Mushroom_Common` **is** a plain
0.56 × 0.46 m dome with no stem read and no gill line; and every instance took the same
tint, so even two species would have read as one.

The owner's standing correction of 2026-09-06 overrode the handoff's W1 row, which
proposed a 54.8 MB AssetQuest download:

> "There is art in the repo for most of these things already, like mushrooms and team
> tether stuff. Find it and use it. Recolor it if you need to. Don't use Meshy."

`Mushroom_Oyster` (stacked gilled shelves) and `Mushroom_RedCap` (a cap-and-stem
toadstool) were already vendored in `assets_raw/vendor/quaternius_stylized-nature-megakit/`
and share `Mushrooms.png`, which was **already installed**. The install is two `.gltf`
and two `.bin` and **no new texture**. `fungus.species` gives each species its own
albedo tint, glow colour, emission and `scale_mul`; the tints are pale cave variants
(sage / bone / cool blue-grey), which is also what keeps the harvestable
`mushroom_pickup` readable — it is now the only warm saturated mushroom underground.
`scale_mul` is derived from each model's native height so all three land near 0.46 m.

**Nothing was downloaded in this lane and no Meshy generation was spent.**

### W5 — the burrow arch

The brow was a `_tube_mesh()` sweep (a constant-radius circular section — literally a
pipe) wearing `_bank_earth_material()`, while the bank two metres behind it wears
`earth_bank.gdshader`. Both are gone. It is now a **surface**: a collar swept around
the arch rim whose cross-section is a quadratic Bézier from the rim, out and proud to a
crest, then back and further out to die into the mound, displaced by seeded noise that
fades to zero at **both** ends of the section so the inner rim stays exactly on the arch
and the outer edge lands flush on the bank. It wears `_bank_material()` with the bank's
own vertex-colour contract, so the earth photo, its normal map and the spoil darkening
are continuous across the seam.

The ten bark-root cylinders (`bank.roots`, two five-tube "masses") are replaced by real
installed meshes — `DeadTree_*` crowns aimed crown-first out of the dug face, with
`stump_round` and Kenney `tree-log` half-buried at their feet (`bank.root_masses`), plus
two more hung off the arch itself (`bank.brow_root_meshes`). The two thin "snagged over
the top" sticks JUDGE-round2.md liked are kept verbatim — a thin snagged stick is one of
the few things a tapered tube actually is.

### The §5.2 tube-foot sliver — three diagnoses, and what settled it

Worth reading if you inherit this, because two of my three diagnoses were wrong and the
**measurement** is what corrected them:

| round | fix attempted | result |
|---|---|---|
| 1 | apron ramp widened to the throat **shell** (2.30 → 2.95 m half-width) | 219 bright px, bbox x 668–803 |
| 2 | apron widened to the **notch** (4.2 m) **and** the bank's moist band deepened | 219 px, **same bbox**, RGB [173,173,148] |
| 3 | `threshold_fan_overlap_m` — a metre of fan/ramp overlap instead of a hand's width | **0 px** |

An artefact byte-identical across two builds that changed different things is not caused
by either of them. It was a **z-gap**: the ramp's outermost box ends at `z_front − 0.075`,
the fan's row 0 sat at `z_front + 0.2` and row 1 at `z_front − 0.24`, so the two surfaces
met inside a single 0.44 m band, 3 cm apart in height, on ground falling away — at the
16 m stand that band is a few pixels tall and the eye looks straight through it to
sunlit terrain.

Rounds 1 and 2 were **kept, not reverted**: the apron genuinely did stop 0.4 m short of
the notch at each foot, and the bank's earth genuinely does read white at a grazing angle
at `earth_tint` #f0ece4 × 1.5. Real defects found on the way; neither was this one.

### Owner-directed interior height pass (2026-09-06)

> "the interior looks a little cramped for that creature. should be taller."

The guardian is 3.57 m under what was a 4.8 m ceiling, of which `rib_drop_m` takes 0.34
back. Per CLAUDE.md's scale rule the **room** grew, never the creature:

| | was | now |
|---|---|---|
| den | 4.8 | **7.0** (guardian 51 % of its own room, 3.4 m above it) |
| hall | 4.2 | 5.6 |
| warren, vault | 3.4 | 4.0 |
| hall→den passage | 3.4 | 4.4 (the boss's own door was shorter than the boss) |
| mouth, mouth→hall | 3.6 / 3.0 | **unchanged** — tied to `bank.arch_height_m` and the throat |

Two knock-ons re-authored with it: `roots.pieces.tip_y` per chamber (a crown hung under a
4.2 m ceiling is a floating bush under a 5.6 m one; every trunk re-checked as still
buried in its slab, shortest top 6.5 m against a 4.0 m ceiling) and the `lights` y/range/
energy for the four rooms that grew — the den's warm key moved from y 3.1 to 4.6, i.e.
from *below* a 3.57 m creature's head to above it. The mound needed no authoring:
`_bank_chamber_bumps()` derives its cone from the chamber height, so clearance held at
`den +2.9m`, unchanged.

Blind round 2 independently confirms the result and **withdraws** round 1's scale
finding: "the guardian measures about 4.5–5× the chest's height at the shoulder … It is
not the frog-sized-boss failure. Good."

### Other defects the verdicts named inside this lane's files, all fixed

- "a red-and-white striped pole with a white ball on top … reads as a barber pole, a
  survey stake or a debug marker" → emission 7.0 was clipping the bulb to white (round 6's
  fix for "an unlit black pole with a white sphere" had overshot into a different white
  sphere); the oxblood **stays** (this is the one Team Tether object at the threshold) but
  moved from an eye-height ring to a foot collar. Then round 2 called the result "a
  municipal streetlight", so `Lantern_Wall` — **already vendored, all three textures
  already installed** — hangs on the post instead. Ledger row added before the file.
- "the root/branch dressing … is a flat black scribble … reads as a decal, not geometry"
  → three thin crowns became two at half again the scale, overlapping, over a lighter
  tint. Round 2 quotes the result as a thing that works.
- "the moss on the boulders is a bright green band … a decal stripe" → `moss_normal_min`
  0.5 **was** the hard edge (it switched moss on across a few degrees of surface normal);
  0.22 makes it a gradient.
- "two grass tufts hang in open air against the blue sky" → self-inflicted: the brow turf
  was seated to the **old swept-tube** brow and I moved the collar twice without moving
  the turf. It now derives its seat from the same `lip_out`/`lip_proud` the ring is built
  from, so it cannot drift out of step again.
- "the bottom 40 % of the frame is a single smooth chocolate-brown mass" → threshold
  rubble 40 → 85.

---

## 3. Measured evidence (Rec.709, `shots/warrens_63/`, 1280×800, day, software GL)

Measured before every judge round, per `docs/HANDOFF_2026-09-06.md` §6 trap 9.

| frame | round 0 median Y | after | floor-band Y | what moved |
|---|---|---|---|---|
| 04-hall-dressing | **24.6** | **52.8** | 92.4 → 101.5 | `interior_cladding_colour`: earth reads as a wall, not a hole |
| 05-hall-from-the-doorway | **123.2** | **72.7** | 159.1 → 159.3 | mushrooms stopped being the subject; the floor did not move |
| 03-mouth | 54.8 | 50.5 | 48.3 → 47.5 | collar occlusion landed |
| 07-den-dressing | 43.1 | **32.0** | 74.0 → 90.3 | **a regression — see §5** |

---

## 4. W3's honest status: the material task is done, the geometry task is not

They were never the same task, and the handoff conflated them.

The handoff's W3 row is a **material** instruction — "extend the earth-clad treatment
(`site.earth_clad_interiors`) to the hall's first bay and the passage walls. Corbels and
beams stay." Doing exactly that is what produced blind round 1's finding:

> "04 uses a brown dirt-and-gravel wall while 05/06/07 add a grey speckled granite for
> the same structural role — two unrelated rock materials in adjacent rooms with no
> transition, so the burrow has no material identity."

A bay of earth beside unclad stone is two materials where there was one. Round 2's own
instruction was "pick ONE wall rock material for the burrow", so `site.earth_clad_walls`
now clads all four walls and the ceiling underside of every chamber, the passages
already were, and the hall's partial bay retires to an empty list (the mechanism stays
in code — it is the right tool for a site that wants a real material transition
somewhere). Evidence: `38 interior earth skins across 5 walls-clad chamber(s) and the
passages`. Round 2 does not repeat the two-materials finding.

**What remains is geometry, and it is out of reach of a config key.** Round 2: "hard 90°
extruded prisms with perfectly flat walls, sharp vertical corners and a flat ceiling.
Nothing about `04`, `05`, `06` or `07` says *dug*. The doorways are plain rectangles cut
in a wall with a flat frame band, no jamb, no lintel, no wear." Round 1 put the same
thing in its **cannot be fixed by scene work** list: "the interior kit. Boxy planes and
unbevelled beams cannot be dressed into a dug burrow. Needs a curved/organic tunnel kit,
or the burrow reads as a cellar forever."

That is a kit decision for an owner, not a tuning pass, and it was not attempted.

---

## 5. What I did NOT get to, and why

1. **`07-den-dressing` value regression, introduced by this lane and unresolved.** Frame
   median fell 46.6 → **32.0** when the den's walls went from pale stone to earth. The
   material identity is right and the value is now wrong: the den's light pools were
   tuned against a wall albedo that no longer exists. The levers are
   `site.interior_cladding_colour` (currently `#6f5840`) and the three den entries in
   `lights`. **This is the first thing to pick up.** Named here rather than left to be
   discovered.
2. **A judge round on the final tree.** The last two commits — the Cloudreach-style
   geology layer and its correction — are rendered but **not blind-judged**. Verdicts 1
   and 2 predate them. Do not read either verdict as acceptance of the geology work.
3. **The geology changed the mound's CHARACTER, and that is an owner call I could not
   make.** The previous lane spent six rounds turning this knoll into "a lit grass mound"
   (its round-6 verdict). With the geology layer on, the upper cone now reads as
   grey-green **stone** with mossy shelves rather than grass. That is the direction the
   owner asked for — Cloudreach-style geology instead of plastic props — and the rock
   language is now one thing instead of two. But it is a change of character, not just of
   material, and no judge has seen it. If the grass mound was the intent, `slope_low_deg`
   is the dial: raising it toward 60 hands the dome back to grass and leaves stone only on
   the dug face. Measured on the final render, `01-knoll` darkest-5 % lifted 39.9 → 50.5
   between the overshoot and the correction, so the black cone is gone; whether the
   remaining amount is right is a look decision.
4. **The geology strength is a guess.** `bank.geology.strength` 0.55 over a 52–68° band
   is my second attempt; the first (0.85 over 44–60°) turned the knoll into a near-black
   cone because this mound's settled flanks already sit near 50°, so there is no clean
   slope gap between "cut face" and "grassy flank". The corrected numbers are rendered
   but unjudged. `strength: 0` reverts the whole layer; nothing else needs touching.
5. **Interior floors** are still the pale sandy `_floor_material(false)` while the walls
   are now earth. Round 2 names the mismatch ("through the doorway in `03-mouth` the
   interior floor reads dark blue-grey; in `04` and `05` the same floor is a bright warm
   cream sand … it is a hue flip"). `earth_clad_interiors` already swaps a chamber's floor
   to apron earth; extending that to the walls-clad rooms is the obvious next move and I
   did not risk it without a judge round.
6. **W2 and W4** were explicitly out of scope and stayed out. Evidence in §6.

---

## 6. Named by the judges, NOT this lane's — recorded so it is not lost

- **The meadow ground** (round 2's ranked #1), with its numbers: exterior ground median
  chroma **0.18–0.28** and brightest-5 % **0.62–0.69**, against the references' 0.42–0.49
  and 0.90–0.94. "A hard blue sky, a sun direction proven by the crate's sharp shadow —
  and a meadow lit as though it were overcast." This is W2: the Meadows-wide terrain
  palette and grass field, sharing a root cause with Cloudreach's C1.
- **"The exterior has no sun"** — no cast shadows on terrain in `00`/`01`/`02` while
  `01`'s crate and `03`'s near ground both have crisp ones. That pattern is a
  directional-shadow **range** limit, not a missing light: `art.json` and the renderer,
  Meadows-wide.
- **The guardian's style seam** — "a hand-painted matte badger head joined at the shoulder
  to a glossy moss-plated rock body, with a third material on the paws". W4, owner call,
  and creature meshes plus `creature_visual.gd` were fenced off from this lane.
- **The guardian reads as floating** — and it is **not**, measured on a real boot by the
  new `tools/_probe_warrens_guardian_stance.gd`:
  ```
  PROBE floor plane y = 4.148
  PROBE guardian origin y = 4.149  (origin - floor = 0.001)
  PROBE is CharacterBody3D, on_floor=true velocity=(0.0, 0.0, 0.0)
  ```
  The body is on the floor, at rest. What reads as a hover is the **mesh's own feet
  sitting above its origin**, magnified by the 3.57 m scale. A mesh matter, not a
  placement one. (The probe's visual-AABB line is not evidence of anything — it merges
  rest-pose bounds of skinned meshes, which is why it reports a nonsensical 16 m span.)
- **"Duplicate chests in three frames"** — real, and confirmed by crop, but **not the
  warrens' dressing list.** `burrow_warrens.json` authors no chest at all, and the new
  `tools/_probe_warrens_prop_overlaps.gd` builds the warrens against the same flat
  fixture `smoke_warrens_fixture` uses, walks all **801** placed props and reports every
  pair closer than 1.4 m: **no Dressing↔Dressing pair exists.** The fixture has no
  playground and the real scene does, so the second copy comes from the playground's own
  band-pickup / harvest pass, which is not warrens-aware (`playground_world.gd` mentions
  the warrens only to build it). Handed over with the probe rather than half-fixed from
  inside the wrong file.
- **The pale terrain strip at the threshold** is the terrain's own baked dirt-path road
  arriving at the mouth, already established by `tools/_probe_warrens_threshold_render.gd`.
  A road that arrives at a den mouth is the world working. `meadow_grass_Color.png` and
  the Meadows bake were out of this lane and were not touched.
- **Asset-set gaps** both rounds say the scene cannot fix: the tree set (two silhouettes,
  flat leaf cards, off-palette trunks), the ground-cover set, the rock family, an organic
  tunnel kit, and the prop family's photographic wood/metal against flat-shaded stylised
  geometry.

---

## 7. Tests — the exact lines this rests on

Run on this branch. A self-report is not evidence; these are the runs.

```
tests/smoke_warrens_fixture.gd  ->  WARRENS FIXTURE OK
  [warrens] 38 interior earth skins across 5 walls-clad chamber(s) and the passages
  [warrens] mouth brow: displaced earth collar, 31 x 8 in the bank's own shader
  [warrens] 2 root masses over the mouth (meshes, not tubes)
  [warrens] 6 root masses on the bank face (meshes, not tubes)
  [warrens] placed 4 accent boulders at the bank's own foot
  [warrens] 3 rock outcrops protruding from the dug face and flanks
  [warrens] 8 fungus clusters, 3 species
  [warrens] earth bank 63x90m, crest 18.1m above the mouth (10.0x the 1.8m trainer);
            chamber clearance past the required 1.5m: mouth +11.8m, hall +2.8m,
            warren +3.5m, den +2.9m, vault +4.7m (worst 2.8m)
  [fixture] mouth arch: clear line from 12.0m out straight to the mouth chamber floor
  [fixture] chamber enclosure: 5 chambers checked, highest cover hit 0.3m above the mouth
  [fixture] capsule shape-cast (r=0.4m): safe 28.0m, unsafe 28.0m, of 28.0m along the
            mouth->hall line
  [fixture] capsule shape-cast: channel to the hall is clear
  [fixture] dome over the throat: 9 rays down, 0 open (all land on earth above the tube)
  [fixture] skyline from the approach: 3 local maxima with >=1.0m prominence:
            x=-21.0 h=16.2m, x=+0.5 h=18.1m, x=+19.0 h=15.2m

tests/smoke_warrens.gd  ->  warrens smoke test passed
  SMOKE_EXIT=0
  ERROR lines: 0
  second build of a cleared warrens spawned no guardian, as it should not
```

**Caveat, stated plainly.** `smoke_warrens` was last run in full on the tree at commit
`2905e2ae` (the one-wall-material change). The four commits after it — the lamp light
offset, the lantern swap, the brow-turf reseat, the geology layer and its correction —
have been verified by `smoke_warrens_fixture` (**WARRENS FIXTURE OK**, quoted above, run
after each) and by rendering, **but the full `smoke_warrens` boot was not re-run on the
final head**. It should be, and it is cheap (~6 minutes). Nothing in those four commits
touches collision, the walk route or chamber geometry — they are materials, a light
position, two prop transforms and a shader layer — but that is an argument, not a run.

**Not verified at all:** CI. No CI run was dispatched from this lane.

---

## 8. Files this lane owns and touched

- `scripts/world/burrow_warrens.gd`
- `data/config/burrow_warrens.json`
- `shaders/earth_bank.gdshader`
- `assets/environment/stylized_nature/Mushroom_{Oyster,RedCap}.{gltf,bin}` (installed)
- `assets/props/quaternius_fantasy/Lantern_Wall.{gltf,bin}` (installed)
- `docs/specs/ASSET_LEDGER.md` (two addendum rows, both written before the files)
- `tools/_probe_warrens_guardian_stance.gd`, `tools/_probe_warrens_prop_overlaps.gd` (new)
- `ralph/reports/WARRENS-ART-0906/`

Nothing under `scripts/world/cloudreach_*`, `scripts/world/stronghold*`,
`data/config/stronghold.json` or `assets/environment/team_tether/` was touched. The
Cloudreach cliff shader was **read** for its technique, never edited or shared.
