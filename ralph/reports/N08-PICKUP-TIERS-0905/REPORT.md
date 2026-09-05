# N08-PICKUP-TIERS — report

Branch: `ralph/N08-PICKUP-TIERS-0905`, from `origin/main` at `f8a47ee4`.
Lane brief: `ralph/briefs/0905-followup/N08-PICKUP-TIERS.md` (with `COMMON.md`) — **not
present on any pushed ref when this lane started** (see "The brief" below). The lane
worked from the session title (*"make pickup tiers distinguishable by more than hue"*),
the W17 round-2 and W18 round-1 code-blind verdicts that raised the defect, and the
owner's board 17.

## What a player gets

Three candy grades that a player can tell apart, and rank, without a key and without
hue: a Good Candy is a small green candy with a leaf-disc on its crown; a Great Candy is
a bigger blue candy wearing a **star** and standing in a **bright ring on the ground**;
a Rare Candy is the biggest, amber, wearing a **spiked crown**, standing in a wider ring,
with two **wings** swept up and out from its wrapper ends, and the widest, loudest glow of
the three. More parts is worth more — one, two, three — which is the owner's own board-17
language (leaf / star and sparkle / crown, wings, glow). Every candy in the world also
turns slowly on the spot, the one motion cue every item game uses, and stays on the
ground.

Rare stopped being cream. Its glow was the same pale gold as its albedo tint, added at
1.7x, which clipped toward the white the meadow's cup flowers already own; it is now a
saturated amber carried on its own emission colour under a light albedo.

## The brief

`ralph/briefs/0905-followup/` exists on no branch, tag or PR head of the repository
(checked every remote ref at 13:40 UTC) and no other session was reachable to supply it.
Per the launch instruction ("make the smallest defensible call and record it"), the lane
took its scope from the session title and the two verdicts that routed this exact ask to
the coordinator: W18's `JUDGE-pickup-tiers.md` — *"give Rare a hue outside the
cream/white flower palette, and make the tiers differ by size or added shape as well as
tint"* — and W17's round 2 (*"what separates them is size, colour hue, and the number of
side attachments — all three changing at once"*; the wings *"appear to float"*). File
ownership was taken as the loader that owns the tier look and its test, plus one new
capture tool. `CURRENT_STATE.md` was not edited: it is the landing lane's file in this
cycle and every N-lane would collide on it.

**What the lane assumed and may be wrong about if the brief says otherwise:** that the
mesh is out of scope (no generation, per `CLAUDE.md`); that `pickup_glow.gd`,
`item_cache_pickup.gd`, `vegetation.gd` and `items.json` are other lanes' files and were
not touched; that grounded candies are wanted (no hover).

## Files changed

- `scripts/world/band_pickups.gd` — the tier look (`CANDY_LOOK` gains `crest`, `ring`,
  `glow`, `emit`; `_dress_candy` builds the crest shape per tier, the ground ring, the
  re-rooted upswept wings; the shared highlight is re-registered with the tier's radius;
  a looping tween turns the visual wrapper); `place_all` is now `place_one` per entry so
  a capture tool can stage a candy through the loader's own path; four small pure
  queries (`parts_for`, `glow_scale_for`, `crest_for`, `spin_phase_for`).
- `tests/test_band_pickups.gd` — seven new tests (below). The existing 22 are untouched
  and still pass.
- `tools/_capture_n08_pickup_tiers.gd` — new: shoots the three tiers side by side on the
  `band1_open` ground and W18's Highfield trio, through the gameplay camera with the
  grass check, for the blind judge.
- `ralph/reports/N08-PICKUP-TIERS-0905/` — this report, the judge verdict(s), one contact
  sheet per round.

Not touched, deliberately: `pickup_glow.gd`, `item_cache_pickup.gd`, `vegetation.gd`,
`items.json`, `candy_pickup.glb`, `docs/CURRENT_STATE.md`.

## Tests

`godot --headless --path . --script tests/run_tests.gd -- --only=test_band_pickups.gd`
— **29 tests, 25,987 assertions, 0 failed** (the 22 that shipped with W17/W18 plus seven
new). The `get_node() with absolute paths` errors in that log are the seam's known
off-tree noise (`tests/test_item_cache_pickup.gd`'s header), present before this lane.

The seven new tests, and what each pins:

| Test | Pins |
|---|---|
| `test_a_tier_is_an_additive_part_count` | `parts_for` is 1 / 2 / 3 and the built nodes carry exactly those parts (crest; crest + `TierRing`; crest + ring + `RareWingL/R`) |
| `test_each_tier_wears_a_different_crest_shape` | disc / star / crown are real geometry: a `CylinderMesh`, a built `ArrayMesh` with the star's own 120 vertices, a disc wearing 5 `CrownSpike` cones |
| `test_a_higher_tier_glows_wider` | the shared-highlight multiplier steps up the ladder; a non-candy stays at 1.0 |
| `test_the_rare_wings_are_rooted_and_sweep_upward` | each wing's box overlaps the body's, its tip is higher than its root, and it points outward |
| `test_the_ground_ring_lies_at_the_foot_and_clears_the_wrapper_ends` | the torus sits at the base and its inner radius clears the wrapper's full length |
| `test_the_tier_hues_are_far_apart_and_rare_is_amber_not_cream` | the three emission hues are ≥ 60° apart; Rare's is amber (20–45°), saturated (> 0.85), over a light albedo |
| `test_a_candy_dressed_off_tree_is_phased_but_not_spinning` | no tween is made without a tree; the phase is a pure function of the placement id; a mushroom is not spun |

**Seen red first.** With the table flattened back to W17's (every crest a disc, no
ring, glow 1.0) and the wing sweep sign flipped back, in a scratch copy of the loader:

```
FAIL  test_a_higher_tier_glows_wider        Great's highlight is not wider than Good's (1.0 vs 1.0)
FAIL  test_a_tier_is_an_additive_part_count expected 2, got 1 (Great carries two parts) / Great has no ring
FAIL  test_each_tier_wears_a_different_crest_shape  expected star, got disc / expected crown, got disc
FAIL  test_the_rare_wings_are_rooted_and_sweep_upward  RareWingL's tip (0.314) is not above its root (0.668): the wing droops
4 tests, 34 assertions, 4 failed
```

The last line is the W17 wings measured by the new test: their tips sat 35 cm below
their roots in mesh space. That is the droop round 2 saw and could not name.

Adjacent files, same command with `--only=test_pickup_glow.gd,test_item_cache_pickup.gd`:
**27 tests, 62 assertions, 0 failed.**

## Runtime validation

`godot --headless --path . --script tests/smoke_playground.gd` on this branch:
`smoke: OK`, `placed 101 band pickups (0 already taken, 24 nudged off scatter, 3 unclear,
0 without ground)` — the same census `main` prints. Grepped for `^ERROR:` as well as
`SCRIPT ERROR` (AGENT_WORKFLOW §6): the distinct set is `ERROR: Parameter "material" is
null` alone (2 lines; the known alpha-build noise whose count varies), zero
`SCRIPT ERROR`. The set did not grow.

## Visual: three code-blind rounds against `main`, same stands, same eye positions

**Method.** `tools/_capture_n08_pickup_tiers.gd` stands Good, Great, Rare and a Stamina
Shroom 1.3 m apart on the `band1_open` ground at (0, 693) — through the loader's own
`place_one()`, so nothing about the look is staged, only where they stand — and shoots
them through the **gameplay camera** (the grass check refuses a frame the ring is not
dressing) with the lens ~7 / 12 / 17 m away and the 1.80 m trainer beside them as the
ruler. Then W18's three Highfield placements in band 4 at ~9 m. The `main` frames come
from `main`'s own loader swapped in for that run (the capture tool calls the loader
dynamically so it parses against both), and every after-frame was shot from the same
logged eye position. Each round's judge was a fresh `opus` sub-agent given only the two
frame sets, `docs/reference/` and the visual-judge skill, told nothing about what
differed or which was newer; the sets were labelled P and Q, never before/after.
Verdicts committed in full: `JUDGE-round1-lineup.md`, `JUDGE-round2-lineup.md`,
`JUDGE-round3-lineup.md`; one sheet per round, `_sheet-round<N>.png` (P above, Q below).

**What `main` looks like, judged for the first time.** W17's round-3 scale correction
shipped unrendered; this is its first blind read. The judge could not find the Good at
7 m at all (*"a green shape, on green grass, inside a green glow… I would not call this
found, I would call it inferred from the light"*), read the Rare as *"a pale cream lobed
mass… nearly the same brightness and hue as the sunlit grass"* whose only surviving part
at 12 m was *"two disembodied white slivers"* (the wings), ranked the four by size and
hue alone, and at 17 m saw *"three coloured light patches and one mushroom"*. Hue was the
only channel the objects themselves carried, exactly as W17 round 2 and W18 round 1 had
said.

**Round 1** (`e5066175`: star/crown crests, a white ground ring on Great and Rare, upswept
wings, amber Rare, per-tier glow radius, spin). *"Q is the better set, but by a narrow and
specific margin… it wins on the one thing that matters most in this test — an object that
is still an object at 12 m"*: the amber Rare *"survives… a small but distinct orange nub"*
where `main`'s *"has dissolved into its own yellow glow"*. But the ring was read as *"the
exact signature of an editor selection gizmo or a HUD decal"* — pure white, constant
stroke — and, on two of four objects, *"a marker language applied to half a set teaches
the wrong rule"*; the white crown spikes read as *"the mesh's normals are inverted at the
top"*; the Good was still invisible.

**Round 2** (`06e5a5c1`: ring on every candy in its own colour and stepping with the
tier, three tier-coloured sparkles on Great and Rare, gold crown and wings, brighter
Good). *"Which makes the hierarchy more legible: Q, clearly… the object hue, the ring hue
and the size all increase together left to right, so the ramp green → blue → gold → amber
is one statement instead of three."* At 12 m *"Q-3 is still an orange object you can
rank, while P-3 at the same distance is a pale smear with two white shards floating in
it."* The Rare's recolour moved it *"from 'artefact' to 'plant'"* and gave it a family
with the mushroom's amber. Still named: the ring hit the frame's white point (RGB 231,
above the clouds' 207) and *"a perfect bright ellipse at the frame's white point around
a prop is the visual language of a targeting reticle"*; the wing still *"a hard-edged
flat plane"*; the Good *"an invisible object wearing a light"*; and the mushroom, which
is not a candy and has no ring, read to the judge as the fourth tier left unmarked. (It
is the other pickup family, tinted per board 17 and untouched by this lane; the judge
could not know that, and a player standing over both families will see the same thing,
which is worth the coordinator's attention rather than a fix here.)

**Round 3** (`56d7feee`) answers the round-2 list inside this lane's file: the ring's
emission 0.9 → 0.25 on a darkened tier colour, so it sits under the sky value; the wings
shorter, taller and 2.4× thicker in the plain tier gold, fins rather than blades, rooted
deeper; the Good lighter and minty at emission 0.8 (Great raised to 0.9 to keep the
glow ladder monotonic); sparkles a little larger. Its verdict is in the section below.

**What the judges named that is not this lane's, routed to the coordinator:**

- The shared highlight's mote reads as *"a hard-edged rectangle… an unfaded billboard
  quad meeting the terrain"* (both rounds, every set including `main`) and as a flat
  quad through the mushroom cap; `pickup_glow.gd` / `shaders/pickup_glow.gdshader`.
- No contact shadow under any pickup; pickups sit on a *lighter* patch. Same file.
- A bush grows through the herd-bull Rare (band 4) and through the staged Rare on the
  `band1_open` ground: W18's own finding that `has_solid_scatter_near` sees collision
  batches, not bushes; `vegetation.gd`.
- The mushroom's near-white stems are the frame's brightest value and duplicate the
  meadow's white parasol flowers; `mushroom_pickup.glb` / `MUSHROOM_LOOK`.
- Scale: the round-2 judge measured nothing in the line as palmable (Good ≈0.4 m long,
  Rare ≈0.8 m with wings, the mushroom 0.9 m tall) and asked for 0.15–0.30 m. W17 set the
  candy family at 0.34/0.42/0.52 after its own round-2 judge, and the mushrooms are the
  size that judge called right; this lane did not move either, because shrinking the
  family halves every channel that survives distance and the two verdicts disagree. The
  owner's call.
- `candy_pickup.glb`'s own silhouette: both judges, like W17's and W18's, say a lobed
  wrapper with no facets reads as a fungus or a creature, never as a made thing.
  ASSET_LEDGER already records it; no generation was spent.

## Decision for the landing lane (a decision number is theirs to assign)

**A candy tier is an additive part count, not a hue.** Every candy wears the family's
two marks (a crest on the crown, a coloured ring on the ground, both in the tier's
colour); Great adds a star crest and sparkles; Rare adds a crown crest and wings. Size,
emission and the shared highlight's radius step with the tier. Rare's glow is amber, not
cream, because the meadow already owns cream. No candy hovers: finds stay on the ground
(owner directive 2026-08-30, board 17's "fits in world, not UI-looking"); they turn
slowly instead. `parts_for`, `crest_for` and `glow_scale_for` in `band_pickups.gd` are
the queries a test pins; `tests/test_band_pickups.gd` refuses a flatter ladder.

## Round 3, and where verification stopped

The coordinator's 15:58 UTC nudge (*"converge fast… if something genuinely needs a
visual check, do one pass, not multiple rounds… note in your report exactly what
verification is incomplete"*) arrived while round 3's render was on its first frame.
This lane stopped there. Round 3's changes are the direct answer to round 2's three
named defects and every one is pinned by a test (`RING_EMISSION` under the sky value and
the ring never white; the wings rooted, upswept and outward; the Good's emission
brighter than before with the hue ladder intact), so they are verified by test and code
inspection, not by a third blind pass.

**Verification that is incomplete, exactly:**

- **Round 3 has no blind verdict.** Its 7 m line-up frame
  (`shots/n08_pickup_tiers/AFTER3/01-lineup-cam7m.png`, local only) was rendered and
  inspected by this lane — the ring reads as a coloured ground mark rather than the
  frame's white point, the Good is a visible pale-mint form, the Rare is amber with gold
  fins — but that is this lane's eye, not a judge's. Frames 02–03 and the band-4 stands
  were still rendering. The last *judged* state is round 2 (`06e5a5c1`); the difference
  between round 2 and the shipped round 3 is three constants and two colours in
  `CANDY_LOOK` / the ring and wing blocks, all of them in the direction round 2's judge
  asked for.
- **The band-4 authored stands were captured but never blind-judged.** `main` pairs
  (`BEFORE-b4`, three frames, bearing search on) and round-2 pairs (`AFTER2` 04–06) exist
  locally at identical eye positions. Read by this lane: the Good in the south-paddock
  glade is found by its glow and green ring in shade; the Great on the wind ridge is
  found by its blue ring under the canopy edge; the herd-bull Rare is an amber glow with
  **a bush growing through it** — W18's own finding, unchanged, because the site validator
  cannot see non-colliding scatter (`vegetation.gd`, not this lane). No sheet is committed
  for them (one sheet per judged round; there was no judged round).
- **`smoke_playground`'s chop-swing timing check flakes on this box on `main` and on
  this branch alike, and the branch does not move it.** The check
  (`tests/smoke_playground.gd`, "the gather resolved N through the swing, well past the
  0.60 impact pose") fails above 0.80. Every run, same box, headless, one at a time
  unless noted:

  | loader | runs (fraction of the swing) | verdict |
  |---|---|---|
  | `main` (`f8a47ee4`) | 0.71 · **0.81** | 1 of 2 red |
  | this branch, round 1 | 0.78 (beside a render) | green |
  | this branch, round 2 | **0.86** (beside a render) | red |
  | this branch, round 3 | **0.84** · **0.81** (spin off) · 0.76 | 2 of 3 red |

  A headless world frame is tens of milliseconds, so the fraction moves in steps that
  size; `main` itself lands on both sides of the ceiling. Everything else in every run
  is green: `placed 101 band pickups`, the `ERROR:` set is `Parameter "material" is
  null` alone, zero `SCRIPT ERROR`, and every other gate-A step prints its expected
  line. The check is the pre-existing flake CI's `RETRIES: 3` hides, not a regression
  from this loader; it is recorded here because a red run is a red run.
- **Unit tests on the idle box, final loader:** `--only=test_band_pickups.gd,
  test_pickup_glow.gd,test_item_cache_pickup.gd` — **56 tests, 26,063 assertions, 0
  failed.**
- **No CI run has verified the branch.** Every commit up to the report carries
  `[skip ci]` as a checkpoint; the commit that records this report carries no marker, so
  the push that lands it is the first CI run, and its result is not in this report. The
  base is the merge-base with `main`, so the code jobs will run on a report-only head.
- **The spin is invisible in a still.** `_spin()` is exercised only by `place_one()` in a
  booted world; the unit test proves the off-tree path stays still and the phase is
  deterministic, and `smoke_playground` boots the world with every candy spinning without
  error. Whether eight seconds a turn is the right speed is a playtest question.

## Known limitations, and what was deliberately not done

- **The mesh is the mesh.** Both judges, like W17's and W18's, say `candy_pickup.glb`'s
  lobed wrapper reads as a fungus or a creature. `CLAUDE.md` bars a generation without
  owner reference art and the owner shipped the mesh as-is on 2026-09-04; nothing here
  changes that, and the parts are built around it.
- **Mushrooms untouched.** The other pickup family keeps its W17 look and no ring; a judge
  who sees both families in one line reads the ringless mushroom as an unmarked fourth
  tier. Whether the mushrooms should carry the family mark too is the coordinator's.
- **Scale untouched** (see the routed list above).
- **No hover.** Deliberate; recorded in the decision.
- **Tunables stay in `CANDY_LOOK` and its sibling constants**, where W17 put them, rather
  than a new `data/config/` file — one place for the whole tier look was worth more than
  the split, and the file's header says every number is tunable.
- **Twelve untracked `.gd.uid` sidecars** for the Cloudreach lane's scripts are generated
  by any local import of `main` and were not committed, per the file-ownership rule and
  W18's precedent; the repo's stop hook flags them every turn. Whoever owns Cloudreach
  should commit them.
- **`docs/CURRENT_STATE.md` not edited** — the landing lane's file this cycle.

## Commit hash and branch

Final code commit: **`56d7feee`** on `ralph/N08-PICKUP-TIERS-0905` (round 3 of the
loader; the capture tool's last change is `0a2a5ce3`, the tests' last change is
`06e5a5c1`). The report commits that follow it are its children; the one that records
this line carries no `[skip ci]`.
