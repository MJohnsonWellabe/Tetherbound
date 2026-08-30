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

### This was specified three times and built zero times

The single most useful thing found this lane: **none of this is a design
invention.** The population was already named, by location and by species, in
three separate places, and never placed.

1. `data/config/terrain_playground.json` — the `oak_grove_ring` terrain feature
   (band 1, leaves `(230,830)`, rejoins `(330,1130)`) carries, in its own
   `_why` field: **"Duskhush at night, the trainer circuit's second fight, wood
   at scale"**. Two of those three existed. The Duskhush did not.
2. `docs/MEADOWS_MACRO_LAYOUT.md` §10's band-loop table — the same loop, the
   same sentence, verbatim, as the player's reason to take the detour.
3. `docs/MEADOWS_PROGRESSION_SPEC.md` §13's ecology table — Grove =
   Trailpup / **Duskhush at night** / Burrowback.

Plus `data/config/spawns.json`'s `roles.nocturnal`, which is already `duskhush`.

Per `CLAUDE.md`, implementing a documented owner directive is ordinary work, not
invention. So the species was not a choice this lane made, and the location was
not either.

### What shipped

Eight clusters, 22 individuals, orders 1050–1057, in
`data/config/bands/band1_lower_meadows/spawns.json` (bands 0 and 1 share that
file — the audit's own note is that band 0 has no directory of its own).

| order | site | count | why there |
|---|---|---:|---|
| 1050 | band 0, treed ground east of the village | 1 | the hook: band 0 is where the player actually sleeps on night one (`tournament_sleep`), so it is the one place night content is guaranteed to be *seen* rather than merely reachable |
| 1051 | band 0/1 seam, the road north out of the village | 2 | for the player who leaves after dark instead of sleeping through it — on the route, because the finding is that the road reads the same by day and by night |
| 1052 | oak grove ring, the mouth at `(230,830)` | 3 | first thing on the loop, so the detour explains itself within 20 m |
| 1053 | grove interior, west | 4 | deepest inside the ring — the centre of the pocket |
| 1054 | grove interior, east | 3 | between the ring path and Old Bram's ground |
| 1055 | the camp grove, 27 m from `trail_camp` | 4 | **see below** |
| 1056 | the ring's far side at `(400,1040)` | 3 | the loop's turn back toward the spine |
| 1057 | the rejoin at `(330,1130)` | 2 | thinning out — a pocket with edges, not a uniform sprinkle |

**Order 1055 is the one that ties the lane together.** The trail camp only
became a place a player can stop at in T5-CADENCE's work, merged in this same
branch. Before that it was scenery, and night content beside it would have had
nobody standing there to see it. Now both halves exist: you stop at the camp
because you can, and the grove around it is awake in a way it is not by day.
That is criterion 13 delivered as a *place* rather than as a config flag.

**Calibrated against the audit's own protected example.** The audit names band
2's night ecology as one of two things "worth protecting" and the template for
everyone else. Band 2 runs 12 clusters / 40 individuals over 2653 m; this runs
8 / 22 over 2403 m — deliberately lighter, because band 1 is the tutorial meadow
`prompt 71` keeps gentle, and because Duskhush is `species.json`'s
**non-aggressive** watcher/scout (`aggressive: false`), which is why it is the
right night species for a band that must not start ambushing new players after
dark.

**No alpha anywhere in this pass.** `band2/spawns.json`'s own `_comment_alpha`
records the standing rule: alphas run "one per band from band 2 on, **never in
band 1**". **No `table` either** — these are anchors, so the ecology those three
documents asked for is what stands there at every world seed.

### Sited by measurement, not by taste

Every candidate had to clear **≥38 m from every existing cluster centre in the
band** and **≥25 m from the trail camp clearing**, swept programmatically over
the ring polyline, and was then ground-probed with `tools/_probe_night_sites.gd`
(committed). Worst local slope across the eight sites is 17.2°, worst relief
3.33 m over a 12 m ring — all comfortably walkable.

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

<!--VERIFICATION_TABLE-->

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
