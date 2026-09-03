# LAND-FIX-2 — the three CI failures on `ralph/LAND-0830J`, diagnosed

**Branch:** `ralph/LAND-0830J` (worked directly, no side branch)
**Run under diagnosis:** 33315848886
**Status:** stood down mid-task on owner instruction. Failure 1 is **fixed and
verified**. Failure 3 is **diagnosed, not fixed** — it is a real content defect,
not a harness defect, and the fix is larger than this landing should absorb.
Failure 2 was **not touched at all**.

Godot 4.7-stable was installed locally and the project imported clean, so every
claim below is measured against the built world, not read off config.

---

## 1. `verify-unit-tests (5)` — `test_band_content.gd` · FIXED, VERIFIED

### The brief's reading was right in shape and wrong in direction

The brief said T1-HALL-3 (and earlier T3-INSTALL) *added* body assignments to
the live config without updating the mirror. Verified against the tree: it is
the other way round, and T3-INSTALL is innocent.

`_first_difference()` reports `X is missing` only from its **first** loop, which
walks the keys of `want` — the fixture — and looks for them in `got` — the merged
live arrays. So `trainers[8].base is missing` means **the mirror has `base` and
the live config does not**. The live config lost it; the mirror kept it.

The history bears that out exactly:

| commit | what it did | mirrored? |
|---|---|---|
| `f4f885d0` T3-INSTALL | **added** `base: grunt_c/officer_b/captain_a` to the three `stronghold_*` trainers | **yes** — same commit touched live *and* fixture. Policy followed. |
| `7112d888` T1-HALL-3 | **deleted** those three `base` overrides, reverting to the rank's shared grunt silhouette on JUDGE-5's ranked read | **no** |
| `3d169c43` T1-CAST | changed `practice_trainer`'s `config_key` `villager_farmer` → `young_trainer` and dropped its `hair` override | **no** |

So the defect is T1-HALL-3's, not T3-INSTALL's, and it is a *deletion* left
unmirrored rather than an addition.

### There were four drifts, not three

The run reported indices 8, 9 and 10. Replaying the test's exact comparison
semantics over all four split configs found a **fourth**:

```
trainers.json: trainers[0].config_key is young_trainer, expected villager_farmer   [practice_trainer]
trainers.json: trainers[8].base is missing                                         [stronghold_patrol]
trainers.json: trainers[9].base is missing                                         [stronghold_courtyard]
trainers.json: trainers[10].base is missing                                        [stronghold_elite]
```

Index 0 is T1-CAST's, which landed in `017e625e` — **after** run 33315848886 was
cut. It would have reddened the same job on the next push regardless. `spawns`,
`props` and `harvest` are clean; only `trainers` drifted.

### What was done, and why this over the alternative

Per the policy block at the top of `tests/test_band_content.gd` (amended
2026-08-23, `ralph/GATE_D_REMAINDERS.md` §6): the fixtures are a **tracked
mirror, not a frozen original**, and a deliberate identity move must be made
twice — live config and mirror — each carrying a `_why_*` rationale. Both live
edits are deliberate and already carry their rationale in the live config. So
the mirror was brought into line:

- **`trainers[0]` `practice_trainer`** — mirror now reads `config_key:
  "young_trainer"`, the `hair` override is gone, and it carries T1-CAST's own
  `_comment_body_t1_cast` rationale **verbatim**.
- **`trainers[8]` `stronghold_patrol`**, **`[9]` `stronghold_courtyard`**,
  **`[10]` `stronghold_elite`** — `base` and T3-INSTALL's now-superseded
  `_comment_base_0830` removed, replaced by T1-HALL-3's own
  `_comment_base_t1_hall_3` rationale **verbatim**.

The rationale strings are copied byte-for-byte from the live config rather than
paraphrased. That is deliberate and it matters mechanically: `_first_difference`
ignores a `_comment*` key that is **extra in `got`**, but a comment present in
`want` and absent (or differently worded) in `got` fails like any other key. A
paraphrase would have re-broken the test. Verbatim copies compare equal and
satisfy the policy's "each with a rationale" at the same time.

**The alternative rejected:** relaxing the comparison so `base` may disappear, or
deleting the rows. The policy block forbids exactly this and explains why — "a
fixture edit is a deliberate act that shows up in a diff; a relaxed comparison is
a check that silently stops working". Nothing was relaxed. No assertion was
weakened, no row deleted, every entry stayed at its index.

**Note for GATE-F-RUN7's competing fix.** That lane pushed "Mirror the GAME-11
level pin into the band-split baseline fixture" for the same job. Its claim that
the `trainers[8..10].base` failure is not its doing **checks out** — the drift is
`7112d888`'s, which is T1-HALL-3. Its change is to `level` values, which is a
different amendment (the GATEC-CURVE balance carve-out) and does not overlap the
four entries touched here. The two edits should compose, but **verify that rather
than trusting it** — this file has now been edited by three lanes.

### Verified

```
$ godot --headless --path . --script tests/run_tests.gd -- --only=test_band_content.gd
  ok    test_band_content.gd :: test_merged_arrays_are_identical_to_the_pre_split_files
  ok    test_band_content.gd :: test_no_band_file_entry_is_dropped_by_the_merge
  ok    test_band_content.gd :: test_order_is_unique_across_every_band
  ok    test_band_content.gd :: test_the_head_files_keep_every_global_they_had
  ok    test_band_content.gd :: test_the_head_files_no_longer_carry_the_positional_array
  ok    test_band_content.gd :: test_the_loader_knows_exactly_the_bands_the_trail_has
6 tests, 1079 assertions, 0 failed
```

Run once. **Not** re-run, because the stand-down arrived first.

---

## 2. `verify-unit-tests (8)` — stale scatter bake · NOT TOUCHED

Nothing in `data/scatter/**` was baked, edited, moved or deleted. The bake
command was never run. This was scheduled to be the last commit on the branch,
after T1-WORLD's re-bake landed, and the branch stood down before that point.

**Nothing here to redo or undo.**

---

## 3. `verify-owner-regressions-shard (party_count_after_catches)` · REAL GAME DEFECT

Reproduced locally on the first attempt. This is **not** intermittent on this
branch — it is deterministic, and it is not a harness problem.

### The arbiter is innocent. That line is a bad diagnostic.

**No, this is not the same defect T5-CARE found on the build verb.** I went
looking for the shared cause and it is not there.

`_why_the_engage_failed()` (line 434) decides "the winning prompt is X, not the
target" by **node identity alone**. But the wild engage line is published by
`encounter_director.gd::interaction_offer()` — the director *is* the correct
winning provider for exactly the press this harness wants, and it is neither the
target nor an ancestor of it. The harness's *real* check,
`_arbiter_offers()` (line 526), knows this and asks the director which body the
press would take. Its own docstring spells the trap out at length. The failure
message uses the naive check the working code deliberately does not use.

The repo has already been round this loop once and written it down.
`tests/helpers/stick_navigator.gd`'s header records the identical misreading on
a different harness — "the EncounterDirector was **not** stealing the interact
line, it was the only thing still bidding for it" — and concludes "nothing about
the game is wrong here."

So the two are different classes:

- **T5-CARE's build verb is a genuine arbiter defect.** An actionable
  interaction winner *takes* the interact press away from a verb that should own
  it. Hammer in hand + a gatherable within 2.4 m = the build button silently
  stops being the build button. That one is real, is player-facing, and is still
  open.
- **This one is not an arbiter event at all.** The director winning is the
  arbiter working correctly. The press never happened in range because the
  player never got there.

The `EncounterDirector` string is worth deleting or fixing in
`_why_the_engage_failed()` — it has now sent two investigations down the wrong
road, this one included.

### What is actually wrong

`tools/_probe_engage_walk.gd`, run on this tree, from the harnesses' shared start
point (48, 0, −58):

```
Wild_bramblebun_0_1   ARRIVED at frame 102 (3.57m)
Wild_bramblebun_0_2   final 8.90m; 19 of 25 sampled seconds moved under 0.5m   <-- STOPPED SHORT
Wild_bramblebun_0_3   ARRIVED at frame 229 (3.54m)
```

The walk to `0_2` goes `on_wall=true` at (33.2, −47.7) and then grinds — 0.00 m
in most sampled seconds for twenty seconds. Two siblings arrive in under four
seconds. So it is one obstacle on one line, not speed, aggro or the cluster.

I wrote `tools/_probe_engage_obstacle.gd` to name it. Sweeping the player's own
shape along that line:

```
     18.5m along: FencePanelCollision_35
     29.0m along: Wild_bramblebun_0_2
stick_navigator.gd: arrived=false, final 6.39m
```

**A village fence panel is the only thing on the line**, and the repo's own
detouring walker cannot get past it either.

That fence is new. `scripts/world/village_boundary.gd` is `7da75ac7`,
**T5-OPENING / OP-0830-1**, in this very consolidation — the owner directive
*"the village gate is pointless. it doesn't keep you in. it should keep you in
until you find the key."*

### The defect, stated plainly

The opening's practice cluster now straddles a wall the player is confined
behind.

- `data/config/bands/band1_lower_meadows/spawns.json` order 0: bramblebun,
  centre **(30, 0, −40)**, radius **15.0**, count 3.
- That centre sits **6.0 m** inside `data/config/village_boundary.json`'s
  outline. A 15 m radius therefore puts most of the disc **outside** the fence.
- `data/progression/objectives.json`'s `main` chain is
  `opening_first_catch` (3) **before** `open_road_gate` (4). The player is
  confined by that fence at the moment the game requires the first catch.
- Measured containment: `0_1` (41.3, −48.2) **outside**; `0_2` (22.3, −42.2)
  **inside**; `0_3` (33.7, −39.8) **inside**.

So no single vantage reaches all three members. From outside you get `0_1`;
from inside you get `0_2` and `0_3`. `smoke_catching.gd` and `smoke_combat.gd`
stay green because they only ever need **one** creature and take the nearest.
`smoke_party_count_after_catches.gd` needs **three**, so it is the only harness
that must cross the fence — and it is the only one that fails.

Audited every cluster in every band against the outline. **Exactly one straddles
it**, and it is the chapter's first one:

```
order 0  bramblebun  centre=(30,-40)  r=15.0  clearance=6.0  centre_inside=True
```

This is precisely the class of defect T5-OPENING already caught and fixed for one
object and did not then sweep for: its own handover records *"The key at
(31.2, −8.4) falls outside the line the fence now takes. A key on the far side of
the wall is a key the confined player cannot reach."* The same audit was never
run against the wild spawn clusters, and the first catch the chapter asks for can
land on the far side of the same wall.

### Why I did not fix it

The honest fix is content, not test: make the cluster sit wholly inside the
fence. Measured options —

- keep centre (30, −40), radius **15.0 → ~5.0** (clearance is 6.0 m), or
- move centre to **(4, −36)**, where 17.5 m of fence clearance and 18.0 m of
  structure clearance let the authored 15 m radius survive intact.

Either is a **deliberate identity move** on a pinned fixture entry (`centre` and
`count` are named identity keys; the seed for scatter, level rolls, IVs, traits
and shiny draw comes off it), so it must be made twice with rationale — the same
policy as §1.

And then it ripples. **17 files** hard-code the start point `Vector3(48.0, 0.0,
−58.0)` — 4 smoke tests and 13 tools — and that point is now *outside* the fence,
which is not where the real player stands at that beat. Moving the cluster inside
breaks `smoke_catching`, `smoke_combat` and `smoke_controller_catching`, which are
currently green.

Trading one red job for three, on a 896-file consolidation, at the end of the
landing, is not a call I should make unilaterally — and the brief was explicit:
*if a failure turns out to be a real game defect rather than a test problem, say
so plainly rather than adjusting the test around it.* So it is said plainly, and
the test is untouched.

**Recommended sequencing:** land the consolidation with this job red and
documented; fix the cluster placement and the 17 start points as its own lane
with its own CI run.

### Probes left on the branch

- `tools/_probe_engage_obstacle.gd` — **complete and run.** Names what is on the
  line and asks whether `stick_navigator.gd` can get round it.
- `tools/_probe_fence_vs_cluster.gd` — **written, never run.** Would have
  measured where the fence panels actually stand and whether each of the three
  walks is sealed. It is worth running: `0_3` is inside the outline yet was
  reached by a straight walk from outside, and the straight line between them
  crosses the outline at about (36, −42.7). Either a road hole sits there — the
  design intends holes where roads cross — or the fence does not seal on that
  bearing, which would reopen OP-0830-1's own owner complaint. **I did not
  establish which, and it should not be assumed either way.**

---

## Not safe to land as-is

- **`tools/_probe_fence_vs_cluster.gd` has never been executed.** It parses (the
  project imported clean with it present) but its output has never been seen. It
  is a diagnostic, not shipped game code, so it cannot redden a gameplay job —
  but do not cite it as evidence of anything.
- **The scatter bake is still stale** (failure 2), untouched, and will still fail
  `test_scatter_perf_budget.gd :: test_playground_bake_is_committed_and_fresh`.
- **`party_count_after_catches` is still red** and will stay red until the
  cluster placement is fixed. It is not a flake and a retry will not green it —
  which vindicates the `retries: 1` note in `ci.yml`'s matrix.
- **The band fixture is now edited by three lanes.** Verify this against
  GATE-F-RUN7's level-pin edit rather than assuming they compose.
- Godot generated `.uid` files locally for scripts that arrived from merged lanes
  without theirs. **Deliberately not committed** — the UIDs are freshly generated
  and would differ from anyone else's import.
