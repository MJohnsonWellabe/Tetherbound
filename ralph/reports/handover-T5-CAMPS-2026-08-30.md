# T5-CAMPS handover — reconciling T5-CADENCE, and the night bands 0/1 never had

**Lane:** T5-CAMPS. **Date:** 2026-08-30. **Branch:** `ralph/T5-CAMPS`.
**Base:** `origin/main` @ `5d171130`, with `origin/ralph/T5-CADENCE` merged in.

The brief gave this lane four findings from
`ralph/reports/REGION_AUDIT_2026-08-30.md`, in priority order, and one standing
instruction ahead of all of them: **do not duplicate T5-CADENCE's work — fetch
that branch, read what it actually changed, and reconcile the bookkeeping rather
than rewriting a working system.**

That instruction turned out to decide most of this lane. Three of the four
findings were already fixed on `ralph/T5-CADENCE`, which had never been merged.
So the honest summary is:

| # | finding | state on arrival | what this lane did |
|---|---|---|---|
| 1 | the camps are props | **fixed on `ralph/T5-CADENCE`, unmerged** | merged it forward onto current `main` and **re-proved it by played path** |
| 2 | dead travel in bands 3 and 4 | **fixed on `ralph/T5-CADENCE`, unmerged** | merged forward, re-measured with the committed probe |
| 3 | band 3 resource regression | **fixed on `ralph/T5-CADENCE`, unmerged** | merged forward, verified |
| 4 | zero night-gated spawns in bands 0/1 | **open** — CADENCE names it as not reached | **built it** |

Finding 4 is this lane's own work. Findings 1–3 are this lane's verification
that someone else's work survives contact with a `main` that moved underneath it.

---

## 0. The thing worth saying first

`ralph/T5-CADENCE` was **not merged into `main`**, and `main` had moved on: seven
commits of `T1-GROUND-3` ground/grass work landed after CADENCE branched. Two
lanes' worth of real content — usable camps in all five bands, 1269 m of dead
travel closed, band 3's resource ladder repaired — was sitting on a branch
nobody had brought forward.

The merge was clean. CADENCE's own handover had flagged `scripts/build/camp.gd`
as the likely conflict, because `main` carried a `T1-LIGHT` change to the same
file; that conflict did not materialise (the two changes are in different
regions of the file, exactly as CADENCE predicted they might be).

**Nothing in this report claims CADENCE's numbers on CADENCE's authority.**
Every one was re-run here, on the merged tree, with a Godot binary in the
container. That last part matters: the audit's own eleventh finding is *"Two
criteria could not be judged... No Godot binary in this container"*, and the
audit and CADENCE were both written without one. This session downloaded the
CI-pinned engine (4.7-stable, `.github/actions/setup-godot`'s own URL) and ran
the real thing.

---

## 1. Findings 1–3: verified, not retold

### Finding 1 — the camps. Re-proved by played path.

`tests/smoke_authored_camps.gd`, run on the merged tree, boots the real world,
walks the player to each camp and presses the button:

```
authored camps carrying a rest block: 5
  trail_camp             rest + craft + bed at 346, 935
  ranger_camp            rest + craft + bed at -256, 2260
  riverwatch_rest        rest + craft + bed at 215, 3697
  highfield_stockcamp    rest + craft + bed at 277, 5652
  the_waystop            rest + craft + bed at -21, 7457
  trail_camp             offers 'Rest until morning'      (x5, one per camp)
  rested at trail_camp: day 1 -> 2
  the bedded creature woke at full HP
authored camps smoke test passed
```

Five camps, all offering rest where the player is standing, night passes, bedded
creature heals. **Verified. No change made.**

### Finding 2 — dead travel. Re-measured.

`python3 tools/region_cadence_probe.py`, unchanged, on the merged tree:

| band | tier A longest dead run | verdict |
|---|---:|---|
| band1 lower meadows | 397 m | PASS |
| band2 stone & root | 396 m | PASS |
| band3 the river lock | 218 m | PASS *(was 668 FAIL)* |
| band4 upper meadows / ironwood | 342 m | PASS *(was 1161 FAIL)* |
| band5 stronghold approach | 0 m | PASS |

Every band passes at all three tiers. CADENCE's figures reproduce exactly.
**Verified. No change made.**

### Finding 3 — band 3's resource regression. Verified.

Rootstone ×3 in the haulage spill, Ironwood ×4 in the north-bank cutting, both
sited in fiction rather than scattered. Present on the merged tree.
**Verified. No change made.**

---

## 2. Finding 4 — night does not exist in the first hour. Built.

### What was actually wrong

Bands 0 and 1 carried **zero** `time`-gated spawn clusters — 0 across all 55 —
in a game shipping a real day/night clock that band 2 uses twelve times.
Criterion 13 of `ralph/MEADOWS_EXIT_CRITERION.md` section E is a **per-region**
requirement, and band 2 was the only region in the chapter meeting it.

### It was specified twice over, and built neither time

The single most useful thing found this lane: **none of this was a design
invention, and the part I nearly missed matters more than the part I was sent
for.**

`docs/MEADOWS_MACRO_LAYOUT.md`'s ecology paragraph reads:

> grove (**Trailpup/Duskhush/Burrowback**) in **Band 1's oak ring** and Band 2

`docs/MEADOWS_PROGRESSION_SPEC.md` §13 says the same: Grove = Trailpup /
**Duskhush at night** / Burrowback. And `data/config/terrain_playground.json`'s
`oak_grove_ring` feature — a real terrain feature, band 1, leaves `(230,830)`,
rejoins `(330,1130)` — carries in its own `_why` field:

> "Duskhush at night, the trainer circuit's second fight, wood at scale"

**Band 1 held neither named grove species.** Zero Duskhush, and zero Trailpup —
against 47 Trailpup in band 2, 9 in band 3, 51 in band 4 and 9 in band 5.
`band2/spawns.json`'s own order-2 entry even describes its Trailpup as *"carried
from Band 1's oak ring"* — carried from a population that was never placed.

The audit found the Duskhush half. The Trailpup half was invisible to it,
because a missing ungated species does not show up as a missing `time` gate.

### What shipped

Nine clusters in `data/config/bands/band1_lower_meadows/spawns.json` (bands 0
and 1 share that file — the audit's own note is that band 0 has no directory of
its own). Both halves of the same sentence.

**Duskhush, night-gated — orders 1050–1054, 12 individuals**

| order | site | n | why there |
|---|---|--:|---|
| 1050 | band 0, treed ground east of the village | 1 | the hook: band 0 is where the player actually sleeps on night one (`tournament_sleep`), so it is the one place night content is guaranteed to be *seen* rather than merely reachable |
| 1051 | band 0/1 seam, the road north out of the village | 2 | for the player who leaves after dark instead of sleeping through it — **on** the route, because the finding is that the road reads the same by day and by night |
| 1052 | oak ring, interior west | 3 | deepest inside the loop, furthest from open ground |
| 1053 | **the camp grove**, 31 m from `trail_camp` | 4 | **see below** |
| 1054 | the ring's rejoin at `(330,1130)` | 2 | thinning out — a pocket with edges, not a uniform sprinkle |

**Trailpup, ungated — orders 1058–1061, 18 individuals**, at the ring mouth,
the grove's east side inside the loop's bend, and both ends of the far side.
Ungated because only Duskhush carries "at night" in either document. Trailpup is
the ring's ordinary daytime resident, and **the contrast between the two is what
makes the grove read differently after dark instead of merely emptier.**

**Order 1053 is the one that ties the lane together.** The trail camp only
became a place a player can stop at in T5-CADENCE's work, merged in this same
branch. Before that it was scenery, and night content beside it would have had
nobody standing there to see it. Now both halves exist: you stop at the camp
because you can, and the grove around it is awake in a way it is not by day.
That is criterion 13 delivered as a *place* rather than as a config flag.

### The finding this lane did not go looking for: the chapter has no room for Air

**This is the most important thing in this report for whoever works here next.**

The night pocket, shipped alone at 22 Duskhush, turned
`tests/test_spawn_tables.gd::test_a_rolled_world_is_still_the_ground_dominant_meadows`
red at three of its rolled seeds. That test enforces the brief's Population
Philosophy — *"the Meadows should still visually read as a Ground biome"* — as
**≥50% Ground at every world seed**.

Measured, not predicted:

| | worst rolled seed | verdict |
|---|---:|---|
| before this lane | **50.17%** Ground | PASS, by **three creatures** |
| \+ 22 Duskhush (Air), alone | **49.0%** | **FAIL** |
| \+ 12 Duskhush, \+ 18 Trailpup (Ground) | **50.5%** | PASS |

So the chapter was sitting three creatures above its own biome-identity floor
before this lane touched it, and **that margin — not any lane's scope — is now
the binding constraint on adding Air content anywhere in the Meadows.** Any
future Air placement needs roughly one Ground creature added per Air creature
(measured: `G ≥ A − 3` to hold 50.0%, `G ≈ A + 3` to hold 50.3%).

Two things worth saying plainly about how that was resolved:

- **The Trailpup was not padding.** Had the balance needed a species the grove
  had no claim to, the honest move would have been to shrink the night pocket
  and flag the collision. It did not: the balancing species is Ground, is named
  for this exact location by two documents, and was missing. The type
  arithmetic and the design answer happened to be the same answer.
- **The test was not touched.** There is a real argument that counting
  night-gated clusters as permanent biome composition overstates Air — band 2's
  40 night Duskhush are already counted as always-present — and that the measure
  should weight or exclude gated spawns. That may well be right. It is another
  lane's test and a canon-adjacent judgment, and editing a threshold to make my
  own change pass is exactly the move that should never be made quietly. Flagged
  here instead, as the obvious next question.

### Sited by measurement, not by taste

Every one of the nine sites had to clear **≥38 m from every pre-existing cluster
centre in the band**, **≥46 m from each other** and **≥25 m from the trail camp
clearing**, swept programmatically over the ring polyline, and was then
ground-probed with `tools/_probe_night_sites.gd` (committed). Worst local slope
across all nine is 17.2°, worst relief 4.22 m over a 12 m ring — all comfortably
walkable.

The specific failure being guarded against is recorded in
`data/config/spawns.json`'s own `_comment_placement`: Galecrest and Burrowback
were once authored onto a rocky rise whose rim is a closed >45° band, *"measured
at 71 of 72 radial approaches unwalkable"*, so neither could ever be met, fought
or caught. **Night gating hides that class of mistake better than day content
does**, because the player only has a chance to notice after dark.

---

## 3. Evidence

The repo's evidence rule is that *"config-level assertions and passing tests are
not evidence that a player can reach a thing. A played path is."*

### `tests/smoke_night_ecology.gd` (new, wired into CI)

Boots the real world and, in the order the player meets it: asserts bands 0/1
author night clusters at all (the regression guard), asserts every cluster
**stood its bodies up by name** in the running scene, asserts **every owl found
ground** under it, pins the clock to day, pins it to night, then walks the player
to the grove and asks the director what it is offering **where they are
standing**.

```
night-gated clusters in bands 0/1: 8 (22 individuals)
  band 0 (home meadow)     2 cluster(s)
  band 1 (oak grove ring)  6 cluster(s)
night bodies standing in the world: 22
every night body is on the ground (worst offset 0.11m, Wild_duskhush_1055_4)
by day:   22/22 night bodies hidden
at night: 22/22 night bodies present
standing at Wild_duskhush_1053_1 (277, 898) after dark, the game offers: Engage Duskhush

night ecology smoke test passed
```

The last line is the point. **A gated creature that is visible but never
engageable is scenery with a schedule**, and that is not a defect a config
assertion can see.

**One honest note about building this test.** Its first run reported
`FAIL: ... the game offers '' -- the player cannot meet it`. That was the test's
bug, not the content's: `prompt_arbiter.gd` keys its offers `label`, and the test
read `text`. A second, real ordering bug followed — `adopt_starter` runs game
state that puts the clock back to morning, which closed every gate the test had
just opened, so the offer really was "Put Terrapup away". The test now re-pins
the clock after adopting and asserts the target is still visible at the moment
the offer is read. Recorded because a test that reports a false failure once
will be trusted less the next time it reports a true one.

### Rendered frames

`tools/_capture_night_ecology.gd` (new) shoots each of three sites **twice from
an identical camera** — same eye, same target, same fov — with nothing changed
between the two frames but the world clock. A pair that looks the same is a
failed fix; the *pair* is the evidence, not either frame.

`CAPTURE_CHECK.require()` runs before every shutter, per the evidence rule and
`tools/capture_check.gd`'s own header. A night shot is the worst possible place
to skip it: **"dark and bare" is exactly what a silently-degraded frame looks
like**, and nothing in the image would say so.

<!--CAPTURE_RESULTS-->

---

## 4. Verification run

| check | result |
|---|---|
| `tests/smoke_authored_camps.gd` (T5-CADENCE's, on the merged tree) | **passed** — 5 camps, all offering rest, night passed, bedded creature woke at full HP |
| `tests/smoke_night_ecology.gd` (new) | **passed** — 5 night clusters / 12 owls, hidden by day, present after dark, "Engage Duskhush" offered where the player stands |
| `tools/region_cadence_probe.py` | all five bands PASS at all three tiers; band 3 218 m, band 4 342 m |
| `run_tests.gd -- --only=spawn_tables` | **27 tests, 6425 assertions, 0 failed** — including the ground-dominance test this lane first broke and then fixed |
| full `run_tests.gd` | **1603 tests, 3570004 assertions** — see note below |

**On the full-suite number.** The first full run of this lane was
**1603 tests / 1 failed**, and the failure was mine:
`test_a_rolled_world_is_still_the_ground_dominant_meadows`, caught exactly as
described in §2. It is fixed and re-verified through `--only=spawn_tables`.
Note that a bare `run_tests.gd` runs more than CI's unit job does — CI passes a
skip list, and T5-CADENCE's handover reports 1545 tests against this run's 1603
— so the two numbers are not directly comparable.

---

## 5. What this lane did NOT do

Written so the next lane does not re-derive it.

- **Band 5's resource FAIL.** 8 nodes of band-1-tier material in the region
  whose whole purpose is final preparation. Outside this brief's four findings.
  CADENCE established the pattern (tier material sited in fiction, not scattered)
  and it is the cheapest remaining content win in the chapter.
- **Band 5's zero night spawns.** The audit fails criterion 13 for band 5 too.
  This lane's brief named bands 0 and 1 only. The pattern now exists in three
  bands and is mechanical to extend; band 5's own design purpose (rest and
  preparation before the Warden) makes a night pocket there cheap and apt.
- **The Night Watch *quest*.** `MEADOWS_PROGRESSION_SPEC.md` §6 lists "Night
  Watch — investigate nighttime activity and introduce Duskhush" as one of the
  6–10 optional activities. **This lane built the night ECOLOGY that activity
  needs, and not the activity** — there is no giver, no tracked objective and no
  reward, and none is claimed. Gap 6 (one optional activity in the chapter)
  is untouched and still open.
- **Band 4's remaining 342 m run**, band 4's pylon line, and the two trainer rows
  CADENCE had sited but could not write because other lanes hold
  `trainers.json`. All still open, all still described in
  `ralph/reports/handover-T5-CADENCE-2026-08-30.md` §6, which remains the live
  document for them.
- **`map_landmarks.json`'s `band1_trail_camp` is 15.6 m out** from the camp it
  names. Noticed by CADENCE, still true, still harmless (25 m discover radius),
  still outside scope. It will read wrong on the map the moment anyone looks.

---

## 6. Files

**New**

```
tests/smoke_night_ecology.gd     played-path evidence for the night ecology
tools/_capture_night_ecology.gd  day/night frame pairs, capture-checked
tools/_probe_night_sites.gd      ground/relief/slope at every candidate site
ralph/reports/handover-T5-CAMPS-2026-08-30.md
```

**Changed**

```
data/config/bands/band1_lower_meadows/spawns.json   8 night clusters, orders 1050-1057
.github/workflows/ci.yml                            smoke: night_ecology
```

**Merged forward, unchanged** — every file in
`ralph/reports/handover-T5-CADENCE-2026-08-30.md` §8.

No asset was generated, sourced or added. `docs/ASSET_LEDGER.md` needs no new
row: Duskhush is an installed, shipping species already standing in three other
bands.
