# Gate F evidence — the full Meadows chapter, 2026-08-23

Gate F coordinator session. Branch `ralph/GATE-F`, cut from `origin/main` at
`397b3ed2`. Godot 4.7 headless in this container; no ROG Ally here, so every
handheld item below is code-verified only and says so.

**This document presents evidence. It does not rule.** Prompt 70's pass is the
meta-coordinator's call (`ralph/lanes/COORDINATORS.md`), and one of its two
named conditions — the VISUAL coordinator's full-corridor blind pass, item 6 —
belongs to another lane and has not reported here.

Read with `ralph/ASSESSMENT_2026-08-23.md`, which this supersedes on four
specific points recorded under "What moved since the assessment".

---

## 1. The chaining harness (Prompt 70's missing instrument)

Prompt 70 asks for the chapter "from fresh launch through post-Warden world
change as one uninterrupted game chapter". Nothing in the repo ran that. Gate
B's continuous smoke proved the opening, five per-band probes proved five
regions, and the Gate E finale smoke proved the ending — and every one of those
passing says nothing about the joins, which is where a 3–4 hour chapter fails.

Two files now do:

**`tools/gate_f_chapter_run.py`** — runs the three segments in player order
(Gate B head → D corridor → Gate E finale tail), captures each one's log, lifts
its measurements, and writes one timestamped record under
`ralph/reports/gate-f-run-<stamp>/`. `--only <ids>` runs a subset, because the
method law is to iterate on focused segment probes and never on full runs.

**`tools/_probe_gate_f_corridor.gd`** — the corridor as ONE walk. The five band
spines chain end to end in `terrain_playground.json` (band N's last point is
band N+1's first), so this reads the route from that file rather than
transcribing it, walks all 11.5 km in a single boot, and carries `seen` and the
running dead-walk counter ACROSS the band handoffs. That last detail is the
whole point: the longest dead walk in a chapter is never inside a band — every
band lane tuned its own interior and each passes on its own numbers — it is at
the seams, which no per-band probe can see and nobody owned.

### What "continuous" honestly means here

- **The record is continuous.** One report, title through healing, in player
  order.
- **The world is continuous inside each segment**, and the corridor's 11.5 km is
  genuinely one boot with one counter.
- **The save is not yet carried BETWEEN the three segments.** Each is its own
  process: the head starts a real fresh game at the title, the tail grants a
  finale-level five. Closing that seam means having the head write a South
  Bridge save for the tail to load, which edits
  `tests/smoke_gate_b_continuous.gd` — a file `ralph/GATEB-PATH` is actively
  rewriting. Per the claim protocol that branch owns it, so the hook lands when
  GATEB-PATH does. The harness header says this rather than implying a
  continuity it does not have.

### A number this harness must never be quoted for

Harness wall time is not the player's 3–4 hours. The head grants the
tournament's team instead of grinding six levels, the corridor steps its route
instead of walking it, the tail tops fighters up. Player time comes from
`tools/_probe_pacing.py` and the corridor's own metres, never from this clock.

---

## 2. Segment verdicts

| segment | covers | verdict |
|---|---|---|
| head — `smoke_gate_b_continuous.gd` | title → opening → catch → village → home → bed → sleep → tournament → South Bridge | **RED, and not mine.** Owned by the Gate B coordinator on `ralph/GATEB-PATH`. |
| corridor — `_probe_gate_f_corridor.gd` | South Bridge → band1..band5 → Hall approach | **recorded**, 11,519 m walked in one boot |
| tail — `smoke_gate_e_finale.gd` | Hall entry → Warden → legendary → world healing → post-win | **PASS** |

The head is red on `main` (harness pathing at Mira's door) and still red on
`ralph/GATEB-PATH`: that branch's own commit `a6c64bf8` states it plainly —
"Gate B's continuous evidence still does NOT pass. It now reaches the live
scatter fill and stalls there." So the amended precondition was correct, and the
full title-to-healing run cannot be closed by anyone until Gate B goes green.
Everything in this document is the work that did not depend on it.

### The tail, in its own words

The Gate E finale ran 6m17s and passed end to end:

```
arrived at the Hall with 5 creatures
walked in from the entrance; 13.5m from the Outer Works' centre
  beat stronghold_patrol / stronghold_courtyard
  rested a fainted creature at the recovery point: 16.3/196 hp back
  beat stronghold_elite; the shutter lifted once the elite fell
read the reveal on the threshold, before the Warden
beat the Warden
[meadow] the tether let go: 115 plants back, 17 tether lights out, 4 beaten patrols withdrawn
[climax] the belt is full; R4.10's release ceremony has the decision
the decision resolved: 'Kettle' released, the legendary on a belt of five
the Meadows acknowledged the victory and the objective chain terminated
```

That is conditions 10, 11 and 12 demonstrated live rather than argued from data.

---

## 3. The rubric, measured

### Travel and dead walking — PASS, comfortably

The corridor is **11,519 m**, ~48 min if every metre of the spine is walked
at 4 m/s. That is the cadence yardstick, not the player's travel budget, and
it does not contradict the pacing probe's 25 min: this walks the spine
exhaustively including its wanderings, while a player takes beat-to-beat
lines at an effective 7.16 m/s and rides the back half of the chapter at 10.
Both numbers are used for what they measure — metres between things here,
minutes of play there.

| band | metres | POI | POI/km | median gap | worst gap |
|---|---|---|---|---|---|
| band1 Lower Meadows | 2,403 | 126 | 52.4 | 8 m | 100 m |
| band2 Stone & Root | 2,653 | 97 | 36.6 | 8 m | 165 m |
| band3 The River Lock | 2,375 | 100 | 42.1 | 12 m | 163 m |
| band4 Upper Meadows | 3,436 | 195 | 56.8 | 8 m | 156 m |
| band5 Stronghold approach | 651 | 53 | 81.4 | 8 m | 64 m |
| **chapter** | **11,519** | **571** | **49.6** | **8 m** | **165 m** |

**Zero intervals of 250 m or more.** The worst stretch meeting nothing new
anywhere in the chapter is 165 m — about 41 seconds — and it is broken by a
berry cluster in band 2. Eighteen intervals reach 100 m; seven of those are in
band 2. There is no dead-travel problem in this corridor, at the seams or
inside any band.

### Encounter density and reality — PASS

571 points of interest within 30 m of the route: **503 wild creatures, 14
trainers, 51 harvest nodes, 2 TMs, 1 key.** 909 wild bodies stand in the world
overall.

Those 14 trainers are not the critical path's 15 and the two lists should not be
confused. The corridor probe counts BODIES near the spine, so it picks up field
and picket trainers the critical path skips (`south_bridge_grunt`,
`quarry_picket_dorn`, `warrens_watch_pell`, `stronghold_outer_watch`,
`stronghold_checkpoint`) and misses the ones standing off it — the three village
trainers indoors, and the courtyard/elite/Warden fights inside the Hall, which
the finale segment walks instead. Both numbers are right about different things:
the ladder is 15 fights, and 14 fightable bodies are visible from the road.

**0 of 909 are underground.** GATE-D's regrounding fix holds chapter-wide —
worth re-measuring because a body under the terrain is authored content the
player never meets, and it is invisible to every count above since the body IS
in the tree.

The snapshot is trustworthy for wilds because
`encounter_director.gd::_set_wild_active()` only ever flips
`set_physics_process` — distance streaming never hides, moves or frees a body —
while `visible` is still checked, since R5.3's time/weather gates express
themselves as visibility and a gated-out creature is not an encounter.

### XP curve vs `docs/MEADOWS_PROGRESSION_CURVE.md` — PASS, conforms

Measured wild levels against each region's declared `wild_band`:

| band | declared | measured | reading |
|---|---|---|---|
| band1 | 2–6 | 2–8 | conforms — see below |
| band2 | 6–8 | 6–9 | conforms (alpha at z=2900, +3) |
| band3 | 9–12 | 9–12 | exact |
| band4 | 11–14 | 11–16 | conforms (alpha at z=5150, +3) |
| band5 | 14–17 | 14–19 | conforms (alpha at z=7255, +4) |

Two apparent over-ceilings are not defects and were checked before being
written down:

- **Alphas add on top of the band roll by design.** `_make_alpha()` applies
  `level_bonus` additively "so an alpha is always ahead of its neighbours rather
  than at some absolute level that would fight the curve". Four alpha clusters
  exist (z=2900, 3890, 5150, 7255). The curve doc's column is the base band, not
  the band-plus-alpha ceiling.
- **Band 1's two over-ceiling creatures are my probe's own seam bleed.** Both
  are Trailpups at 2,394 m and 2,398 m of band 1's 2,403 m — 9 m and 5 m from
  the band 2 boundary, inside the probe's 30 m notice radius, and they are
  band 2 creatures rolling band 2's 6–8. Band 1's field is 2–6 exactly as
  declared. Band 1 has no alpha.

The curve's four invariants hold in every band: nothing out-levels what its
region brings the team to, something is beatable on arrival, a catch is a real
option, and neither band goes backwards.

### Pacing — the one condition that does not clear

`tools/_probe_pacing.py`, after the fix in §4:

```
TOTAL: 2.04 hours   (target 3-4h, D42)
  of which forced wild grinding: 0.07 hours across 6 extra fights
  critical-path fights: 47 creature battles
  projected first completion: 4.08 hours (floor x 2.0)
  verdict: OVER the 3-4 hour target (D42)
```

The floor is 2.04 h of optimal play; the probe's first-completion projection is
floor × 2.0 = 4.08 h, which is **2% over the 4 h ceiling** and the reason the
tool still prints OVER. Forced grinding is 0.07 h across six fights — the curve
is not making anybody farm.

This is a marginal miss on a modelled number, not a measured playthrough, and it
sits on a ×2.0 first-timer multiplier that nothing in the repo derives. It is
recorded as the open item against condition 13 rather than tuned away, because
tuning the chapter to beat a projection multiplier would be fitting the game to
the instrument.

### Rest usefulness — PASS, and the obvious measurement is the wrong one

The corridor probe found **zero rest structures on the route**, which is correct
and is not a finding. The chapter has exactly one rest structure —
`scripts/build/camp.gd` — and the player builds it. The authored "camps" along
the corridor are prop dressing that says a traveller stopped here; the band
files state the distinction themselves, twice, unprompted:

> "the game has exactly one rest structure (`scripts/build/camp.gd`) and this is
> not a second one ... It reads as an obvious place to plant your own camp
> before pushing into Team Tether ground, not as a free-heal station inside the
> gauntlet." — `band3_the_river_lock/props.json`

So the real question is whether a player can AFFORD a rest point wherever they
are, and `tests/test_camp_supply_reaches_every_band.gd` is the test that pins
it: every band pays for a camp and a creature bed out of its own ground. **It
passes in all five bands.** At the assessment it was red on band 4.

### Five-slot pressure — PASS

12 distinct wild species on the route against `five_slot.min_distinct_wild_species: 6`.
Per band: band1 8, band2 4, band3 9, band4 6, band5 5. More desirable creatures
than slots, everywhere, which is the whole mechanism.

The finale exercised the cap for real: the belt was full when the legendary was
freed, R4.10's release ceremony took the decision, and 'Kettle' was released to
make room.

### Objective clarity — PASS structurally

`data/progression/objectives.json` carries a 22-entry main chain from
`opening_first_catch` to `see_what_changed`, unbroken across all three segments.
The tail's log shows the tracked line moving on every beat and terminating after
the post-win acknowledgment. The head's ladder is Gate B's to prove.

### Reward economy — PASS

`chapter_rewards.json`'s invariants (`every_tm_is_obtainable`,
`no_orphan_materials`, `coin_income_covers_at_least_n_expensive_tms: 2`) are
enforced by `test_chapter_rewards.gd`, green in the suite below. The pacing
probe's material check: 28 rootstone supplied against 12 spent on the saddle and
a greater orb; 30 ironwood against 4 for `orb_prime`.

### Regional loops and milestones — PASS, run live

`tests/run_tests.gd` auto-discovers `test_*.gd` only, so the regional GAMEPLAY
smokes are not in the 1362 and had to be run separately. Gate F is the lane that
has to care whether the milestones actually work, not just whether their data
loads. All five pass on this branch:

| smoke | milestone it proves | verdict |
|---|---|---|
| `smoke_tournament_bracket` | the village tournament ladder | PASS |
| `smoke_warrens` | Burrow Warrens, guardian, vault gating, first-clear reward | PASS |
| `smoke_relay` | Tether Relay, Captain Vance, captive, crossing restored | PASS |
| `smoke_riding` | the saddle/mount traversal payoff | PASS |
| `smoke_stronghold` | the five-space Hall route and its gauntlet placement | PASS |

Together with the finale smoke that is every named milestone in Prompt 70's
difficulty list — tournament, Warrens guardian, Relay gauntlet and Vance,
regional captains, Warden — exercised in the running game rather than argued
from the trainer table.

### Reliability — PASS at suite level

**Full suite: 1362 tests, 836,549 assertions, 0 failed** (19m35s). No freeze,
input loss, bad save/load or stuck objective was seen in any run this session.

---

## 4. Findings

### SHIP — fixed here

**`tools/_probe_pacing.py` charged the chapter a 13,934 m phantom detour.**
The probe picks the Meadowhart cluster the player rides from. Its loop assigned
`meadowhart_at` on every match with no `break` and no distance comparison, so it
kept whichever cluster was **last in the merged spawn table** — (-165, 7345), in
the stronghold approach at the far end of the corridor. The species has 17
clusters from z=1230 to z=7345, several within a few hundred metres of the Old
Quarry where the saddle is actually crafted. No player walks past sixteen
meadowharts to catch the seventeenth.

Fixed to resolve nearest-to-the-player at the saddle beat. Effect:

| | before | after |
|---|---|---|
| saddle detour | 13,934 m | 1,343 m |
| band 2 travel | 39 min | 10 min |
| chapter travel | 54 min | 25 min |
| floor | 2.53 h | **2.04 h** |
| projected first completion | 5.06 h | **4.08 h** |

This is SHIP-class because Gate F's judgement of condition 13 rests entirely on
this number, and it was wrong by an hour. No test asserts the probe's output, so
nothing was masking it. Level is not a filter in the fix: wild level resolves
from world position with no player scaling, and the quarry's band rolls 6–8
against a team the same probe has at L8 by then, so the near clusters are
catchable as well as close.

### QUALITY — for BACKLOG

**Band 2 (Stone & Root) is the chapter's thinnest stretch**, consistently across
four independent measurements: the sparsest cadence (36.6 POI/km vs 49.6
chapter), the fewest distinct species (4 vs 12 chapter-wide), seven of the
chapter's eighteen 100 m+ intervals, and the single worst gap (165 m). Nothing
here fails a threshold and no individual number is alarming — it is the band a
player is most likely to describe as the quiet one. Band 2's own lane should
decide whether that is the Warrens' breathing room or a hole.

### POLISH — for BACKLOG

**`docs/MEADOWS_PROGRESSION_CURVE.md` §6 is stale in the player's favour.** It
records "Band 3 and Band 5 have zero wild spawns; Band 4 has one Meadowhart
cluster ... half the corridor has no creatures in it" and "Band 2 has no
trainers at all". Measured today: band3 91 wilds and 5 trainers, band4 184 wilds
and 2 trainers, band5 48 wilds and 3 trainers, band2 2 trainers. D3/D4/D5 landed
the ecology after that section was written. Fix the section rather than let a
future lane plan against it.

---

## 5. What moved since `ralph/ASSESSMENT_2026-08-23.md`

The assessment is older than `main` and is wrong in the project's favour on four
points, all re-measured here:

1. **Its 4 red tests are all green.** `test_map_fog` ×2, `test_wild_alphas` and
   `test_camp_supply_reaches_every_band` now pass; the suite is 1362/0-failed.
2. **SHIP BLOCKER 2 (band 4 harvest) is closed.** Band 4 fields wood, stone and
   fiber alongside its ironwood; every band pays for its own rest point.
3. **SHIP BLOCKER 3 ("Gate E does not exist") is closed.**
   `tests/smoke_gate_e_finale.gd` exists and passes end to end.
4. **Alphas are 4, not 2.**

Its SHIP BLOCKER 1 (Gate B harness pathing) stands, and remains the chapter's
one hard blocker.

---

## 6. The 15 completion conditions (`ACTIVE_GAME_PLAN.md` §6)

§6 lists **fifteen** bullets; the Gate F brief says fourteen. Judged all fifteen.

| # | condition | evidence | state |
|---|---|---|---|
| 1 | strong opening-to-tournament first session | Gate B head | **BLOCKED** — Gate B red |
| 2 | coherent team progression/reward economy | curve conforms; reward invariants green | met |
| 3 | desirable wild creatures across every region | 503 on-route, 12 species, 0 underground | met |
| 4 | authored trainer escalation ladder | 15 critical-path fights L2→Warden's L20 ace, ladder tests green; 14 bodies stand within 30 m of the route | met |
| 5 | useful resource progression | 51 nodes; rootstone/ironwood supply covers spend | met |
| 6 | natural expedition/rest decisions | every band pays for camp + bed from its own ground | met |
| 7 | real five-creature roster pressure | 12 species vs 5 slots; release ceremony ran live | met |
| 8 | distinct finished regional loops | warrens/relay/riding/stronghold/tournament smokes all PASS | met |
| 9 | clear objectives without a quest engine | 22-entry chain, unbroken, terminates | met |
| 10 | strong final approach and Warden climax | finale smoke, live | met |
| 11 | meaningful legendary/release decision | 'Kettle' released for the legendary, live | met |
| 12 | visible post-Warden world healing | 115 plants, 17 lights out, 4 patrols withdrawn | met |
| 13 | 3–4 h focused pacing | floor 2.04 h; projection 4.08 h | **marginal — 2% over** |
| 14 | acceptable ROG Ally/Windows performance | PERF-ROG landed mid-session: per-frame CPU −86..−90% at six corridor sites, 33–40 ms → 3.8–4.7 ms against a 16.7 ms budget. Still not a device frame rate. | **improved, unproven on hardware** |
| 15 | no major core-verb reliability failures | 1362 tests / 0 failed; no failure seen in any run | met |

**11 of 15 met on measured evidence. One blocked on Gate B, one marginal, one
materially improved but unprovable without the hardware, and the full-corridor
visual pass belongs to another lane.**

---

## 7. What is not proven

- **The chapter has not been run end to end by anyone**, because the head is
  red. When `ralph/GATEB-PATH` lands, `tools/gate_f_chapter_run.py` closes the
  loop in one command.
- **Save continuity across the three segments** — designed, not built; waiting
  on the same branch.
- **Target hardware.** No ROG Ally here. `ralph/PERF-ROG` landed on `main`
  while this session ran and closes the CPU half of OP23-01: the arbiter was
  polling 24,461 prompt providers a frame, and per-frame GDScript cost is down
  86–90% at six corridor sites — from 33–40 ms, twice a 60fps frame's entire
  budget before the renderer drew anything, to 3.8–4.7 ms. That is the single
  biggest change to condition 14 the chapter has had, and it happened after the
  measurements above were taken, so nothing else in this document reflects it.
  It is still not a device frame rate, and that report says so itself. The GPU
  half is filed as `PERF-ROG-GPU` and needs an Ally.
- **The full-corridor visual pass** — the VISUAL coordinator's item 6, and the
  second of the two conditions Prompt 70's pass requires. The
  2026-08-23 blind critique answered NO to both bar questions; whether the
  density re-bake and the branches in flight moved it is not this lane's call.
