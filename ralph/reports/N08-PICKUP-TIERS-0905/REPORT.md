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
