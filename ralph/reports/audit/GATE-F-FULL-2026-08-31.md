# GATE-F-FULL — how far the Meadows chapter runs today

**Lane:** `GATE-F-FULL`, Lane 12 of `ralph/NEXT_COORDINATOR_FULL_STATE_AUDIT.md`.
**Candidate:** `main` at **`453107fb`** (LAND-0830J landed 2026-08-30). Every
finding below is true on that SHA.
**Branch:** `ralph/GATE-F-FULL`. **Run directory:** `ralph/reports/gate-f-full/`.
**Full defect log with evidence:** `ralph/reports/gate-f-full/DEFECTS.md`.
**Envelope:** logic lane, headless, Godot **4.7.stable.official.5b4e0cb0f**
(CI's pin, installed per `.github/workflows/ci.yml`), 4 cores, software
rasteriser, no display server. **No frames were taken; nothing here is a claim
about how the chapter looks.**

**The game was not modified.** `git diff --name-only 453107fb..HEAD -- scripts
scenes data assets shaders` returns nothing. Only `tools/` and `ralph/` changed,
which is what the audit directive permits and requires.

---

## 1. The answer, in one paragraph

**The chapter runs for about 26 minutes of play and then stops in the village,
and it stops for game reasons, not instrument ones.** S01 and S02 are healthy:
the front door, the starter, the first fight, the first catch, the key and the
gate all work, and S02's exit save is the good entry save six earlier Gate F
runs could not produce. S03, the village tutorial ladder, cannot finish — the
player's starter loses the team-building fight, the team never reaches three,
`tournament.json` requires three, and the home is never built, so nothing sleeps
and nothing is fed. Behind that sits a defect that would have stopped the
chapter later even if S03 had passed: **every creature loaded from a save has
silently lost its species base stats, and the first level-up after that reduces
it to about one hit point.** The Meadows chapter is a chain of save handoffs;
that defect sits in the joint of every one of them.

---

## 2. What ran

| segment | steps | PASS | FAIL | DELEG | play | wall | stand-up | exit save | verdict |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| S01 | 14 | 13 | 0 | 1 | 180 s | 262 s | 80 s | **none** | complete |
| S02 | 90 | 77 | 5 | 8 | 297 s | 346 s | 48 s | yes | complete |
| S03 | 422 | 383 | 32 | 7 | 1115 s | 1167 s | 40 s | yes | complete |
| S04 | — | — | — | — | — | — | — | — | **not run** |
| S05 | — | — | — | — | — | — | — | — | **not run** |
| S06 | — | — | — | — | — | — | — | — | **not run** |
| S07 | — | — | — | — | — | — | — | — | **not run** |
| S08 | — | — | — | — | — | — | — | — | **not run** |
| S09 | — | — | — | — | — | — | — | — | **not run** |
| S10a | — | — | — | — | — | — | — | — | **not run** |
| S10b | — | — | — | — | — | — | — | — | **not run** |
| S10c | — | — | — | — | — | — | — | — | **not run** |
| S10d | — | — | — | — | — | — | — | — | **not run** |
| S10e | — | — | — | — | — | — | — | — | **not run** |
| **total** | | | | | **1592 s (26.5 min)** | **1775 s (29.6 min)** | | | |

`S03-superseded-1/` is a complete first attempt at S03, preserved per protocol
§A and cited throughout `DEFECTS.md`; `RESTARTS.md` says why it was restarted.
S04 onward run against a party that **cannot legally enter the tournament**, and
their verdicts describe a degraded state rather than the chapter. No pacing,
cadence or progression claim in this report is drawn from them.

**No study segment (X01–X08) was run.** They branch from journey saves — X01 and
X02 from `S03-exit`, X03 from `S05-exit`, X04 from `S04`/`S06`/`S09` — and this
run has no healthy save later than S02's. Running them against a fainted party
of two would have produced numbers about a broken state, which is the failure
mode this audit exists to stop. **X04 additionally remains chain-gated behind
S06**, per run 5's finding, which is still unchallenged.

---

## 3. What stopped it, in the order it matters

Full evidence, telemetry paths and proposed fixes for every one of these is in
`ralph/reports/gate-f-full/DEFECTS.md`. Ranked by what it costs the chapter.

### 3.1 GAME-F4 — a loaded creature loses its base stats; the next level-up destroys it. **BLOCKER**

`save_game.gd::_party_to_array` writes 34 keys per creature and none of them is
`base_hp`, `base_attack` or `base_defence`. `_array_to_party` therefore leaves
them at `creature_instance.gd:62`'s class default of `1.0`. The stored
`max_hp`/`attack`/`defence` are restored directly, so a loaded creature looks
perfect — until anything calls `_apply_level_stats()`, which recomputes every
stat **from the base stats** (deliberately, per D30, so growth cannot compound):

```
S03, t=498.0   level_up "Moss reached level 4"
               max_hp 117.60 -> 1.18   attack 26.40 -> 1.15   defence 18.70 -> 1.15
```

`1.0 × (1 + 0.06 × 3) = 1.18`. With ripplet's real `base_hp` of 105.0 it is
123.90. Every observed figure matches the arithmetic exactly.

Four ordinary things call it: winning a fight, `set_level`, drinking a vitality
elixir, and evolving. A save/load is not an edge case in this game — it is how
a session ends and the next begins, and it is how every Gate F segment after
S01 starts.

**Two comments — `save_game.gd:751` and `creature_instance.gd:40` — say the
field is repaired "on the next `apply_species_definition`". No such function
exists anywhere in the repository; those two comments are its only mentions.**
Each file points at the other's promise.

**Reproduction, one command, about one second, no world:**
`godot --headless --path . --script tools/gate_f/diag/probe_base_stats_after_load.gd`
(added by this lane; drives the production round-trip pair and the real
`gain_xp`; exit 1 while the defect stands).

**Why the suite is green:** `tests/smoke_save_persistence.gd` exercises the real
save/load lifecycle and correctly finds the creature comes back. Nothing in the
suite levels a creature up **after** loading it, which is the only moment the
defect is observable. That is the whole gap, and it is one test.

**And it is not new. It is in sixteen previous run directories, and no lane ever
named it.** A sweep of every Gate F run in `ralph/reports/` for a party member
with `max_hp` under 5 returns sixteen hits, **all at level 4** — the first
level-up after the S02 → S03 handoff, the chain's first load — and **all at
exactly 1.18**, because it is not a roll. Gate F run 3, the deepest any attempt
has reached, begins S04, S05, S06, S07, S08 **and S09** at `t≈1.1` already
carrying it; its evidence from the tournament onward describes a chapter being
played by a creature that dies to anything.
`ralph/reports/FINDING-T2-STRANDING-2026-08-30.md` prints, in its own probe
output, *"after `heal_fully()`: fainted=false hp=**1.18/1.18**"* — a fully
healed starter with one hit point — and reasons past it to a RIG verdict that is
correct on its own terms and downstream of this. **The evidence was there for
three days in sixteen directories; what was missing was somebody asking why a
number was small.** Findings filed as RIG defects about fainting starters,
parties that could not challenge, and Revives spent before the first trainer
should be re-read against this rather than trusted. None of them is retracted
here — their mechanisms were verified live — but their *cause* changes, and so
does what fixing them is worth.

### 3.2 GAME-F2 — the practice-fight level pin is gone from `main`. **SHIP**

`scripts/combat/encounter_director.gd:438` still reads the per-cluster `level`
key that run 7 added. `data/config/bands/band1_lower_meadows/spawns.json` no
longer carries it. `cfce9d54` reverted the practice cluster to its authored
centre by restoring the pre-pin entry wholesale and deleted the pin **its own
commit message says it left untouched**; `841cdd42` restored the radius and not
the level. An absent `level` silently means "roll it", so nothing failed, and
the fixture that was meant to catch it (`tests/fixtures/band_split_baseline/`)
was reverted alongside the live file, so the baseline now agrees with the
regression.

Measured, not argued: the practice bramblebun rolled **level 5 / 124.2 HP** and
the level-3 starter finished the opening at **45.2 of 117.6**. Run 6 measured
that same roll fainting the starter in **four of five** fresh saves.

**And the cost is not theoretical, because this run then paid it.** A starter
that leaves the opening at 38% health walks into S03's first village fight and
loses it in seven hits, after which every remaining engage attempt is correctly
refused with `"Ripplet is out of the fight."` **That is why the team never
reached three, and it is why S03 cannot finish.**

### 3.3 GAME-F3 — the interact button goes to whatever is nearest, and in a meadow that is often the meadow. **SHIP candidate, owner's call**

Engage and harvest both carry priority 0 and `prompt_arbiter.gd` breaks that tie
by distance. In S03's ten-attempt ladder the winner was `Gather deadwood` at
attempt 6 and **`Strip meadow grass`** at attempt 9. The grass is not a node
that can be moved: the boot log reports **59,165 harvestable props**. A player
who steps forward gets the creature, and the priority mechanism is deliberate —
`encounter_director.gd`'s own comment records what happened the last time engage
carried a high priority (GAME-0: it outranked every prompt in the world). Four
options are laid out in `DEFECTS.md`; **none is chosen here**, because this is
exactly the kind of decision the audit is meant to hand over.

### 3.4 GAME-F5 — one sweep of the village's authored nodes does not pay for the home. **SHIP candidate, open question**

Costs from `data/items/buildables.json`, availability from
`data/config/bands/band1_lower_meadows/harvest.json`:

| | wood | stone | fiber |
|---|---:|---:|---:|
| all 20 village-area nodes, one pass, worked out | 28 | 9 | 32 |
| `progression.json` `home.required_pieces` + three creature beds | **30** | 8 | **34** |
| what S03 actually builds (camp+floor+wall+door+roof + three beds) | **45** | **17** | **34** |

The run never set `home_materials_gathered`, never built the home, and so never
slept and never fed. The owner directive of 2026-08-23 that S03's own step
quotes is *"the village gatherable budget must afford three beds before
sign-up"*; on one sweep it does not, even on the game's own minimum.

**Stated as an open question, not a verdict**, because two facts cut against the
simple reading and both are real: nodes respawn after 60 s
(`harvest_node.gd::RESPAWN_SECONDS`), and 59,165 scatter props are harvestable.
The materials exist. What does not is a budget that covers a ladder written as
one pass. What does **not** rescue it is buying the shortfall: `trade.json`
gives Mira `stock: 0` on wood, stone and fiber — she only buys.

### 3.5 GAME-F1 — two of the first day's twenty harvest nodes are outside the village fence. **SHIP, minor**

`(44,−24)` and `(52,−30)` fell outside the 2026-08-30 boundary line.
`tests/test_village_boundary.gd`'s `MUST_BE_INSIDE` list is hand-written and
does not carry the harvest nodes, so nothing caught it. **Confirmed in play in
both S03 attempts**: the walk from the outer node back inside stopped short at
(47,−29) and (52,−36), on the wrong side of a fence that is a hard
`StaticBody3D`. Predicted from config before the run reached it, then observed
twice.

---

## 4. The wall-clock question

**The data does not support an estimate for a first clear, and I am not going to
produce one.** Three disqualifiers, each sufficient on its own:

1. **The chapter does not complete.** Three of fourteen journey segments
   produced a healthy exit save. Nothing about four of the five bands, the
   Warrens, the river, the Stronghold or the finale has been played.
2. **The state the later segments would be measured from is invalid.** A party
   of two, both fainted, cannot enter the tournament, so any time measured after
   it is time spent in a game the player could not be in.
3. **The harness's clock is a floor, not a forecast.** It walks straight lines
   to named anchors, never hesitates, never reads a line of dialogue at human
   speed, never gets lost and never explores.

**What the data does support, stated exactly:**

- **The play clock is real time on this box.** `route.csv` carries both clocks
  per row; with the single cold world stand-up subtracted, wall ÷ play is
  **1.007, 1.004 and 1.014** across S01, S02 and S03. So a play second is a
  player's second, and the harness's own numbers are directly comparable to a
  human's for the parts that ran. This also settles `ralph/T5-PLAY`'s COST-T5-5
  with the second and third samples run 7's handover asked for: **there is no
  village frame-cost regression.**
- **The opening, played end to end, is 8.0 minutes of play clock** (S01 180 s +
  S02 297 s) — bedroom, Grandpa, starter, naming, practice fight, first catch,
  key, gate, arrival in the village.
- **The village ladder is 18.6 minutes** and does not finish.
- **The harness's own planned worst case for the whole journey chain is 419
  minutes (7.0 h)**, and the two walk-heavy segments that ran came in at
  **0.43 and 0.40** of their plan. Extending that ratio would give roughly
  170–180 minutes of harness play clock for the chapter. **That is not an
  estimate and must not be read as one**: both samples come from segments
  confined to the village, and S05–S09 are dominated by kilometres of open
  travel this run never touched, where a walk budget behaves nothing like it
  does across a village square. It is offered only so a planner can see the
  shape of what is and is not known.

A human first-clear time remains **[OWNER-ONLY]**, as protocol §K has always
said, and it cannot be approached at all until a run finishes.

---

## 5. What this lane changed, and what it deliberately did not

**Fixed, all in the instrument:**

| id | change |
|---|---|
| **RIG-F1** | Added `wait_until` to `operator_harness.gd` — CD-3's rule ("reach a state, then assert it") applied to waiting instead of pressing. Polls `assert`'s own `check` vocabulary, priced at its full budget by the cost gate, SKIPs an unevaluable check rather than polling it. S02-45/46 and their capture twins now use it. They had been reading the world **0.53 s of play before the catch resolved** and recording a healthy catch as two FAILs — the third run to report that shape. |
| **RIG-F4** | Added `rank` to `move_to_entity` — pick the Nth-nearest match, clamped, and say so. S03's ten-attempt engage ladder had resolved the same creature ten times and pressed from the identical spot every time; it now varies rank and tolerance, and attempt 1 engages cleanly. |
| **RIG-F6** | **The journey walked into the village fence at both ends of the chapter.** `S05-19` crossed the outline 37.6 m from the nearest gate and stopped 155.8 m short against its `[-15,27]` vertex, pinning the player there for every walk that followed; `S10e-99`, the homecoming, crosses 30.9 m from a gate and would have ended the chapter's last beat against a panel; and S03's gather ladder could not walk back in from the two nodes outside the wall. All three now go through a gate, in legs checked against the outline before authoring. Not a game defect — both gates open on `road_gate_open` and the authored Pond road crosses the outline *at* PondGate. |

The first two are documented in `tools/gate_f/SEGMENT_SCHEMA.md`.
`tools/gate_f/diag/probe_base_stats_after_load.gd` was added as GAME-F4's
one-second reproduction.

**And RIG-F6 got a test, because it will happen again.**
`tests/test_gate_f_instrumentation.gd::test_no_journey_walk_crosses_the_village_fence_away_from_a_gate`
joins the chain's `move_to` legs in play order **across** segments — S05's first
walk begins where S04's last one ended, and that is exactly the pair that broke,
so a per-segment check would have missed it — and asserts none of the 96 legs
crosses the outline further than `gate_clear_m` from a gate. It is the same
check `test_every_road_leaves_through_a_gate` already makes for the authored
roads. **It was proved to fail without the fix**: with `S05.json` checked out
from `453107fb` it goes red and names the leg (*"the walk S04-58 → S05-19
((20, 15) to (−40, 180)) crosses the village fence at (17.8, 21.1), 38.8 m from
the nearest gate"*), and green again once restored. The file's 18 tests pass.
Finding these two cost a run each; finding the next one costs a second.

**Not fixed, deliberately:** every GAME-F item above. `scripts/`, `data/`,
`scenes/`, `assets/` and `shaders/` are untouched, and each defect carries a
proposed fix in `DEFECTS.md` rather than a patch.

**Also recorded and deliberately not changed:** `RIG-F2` (the aim assert reads a
toggle at the wrong parity — the honest fix needs a press-until-predicate
primitive this protocol does not have), `RIG-F3` (S02's distance and route-row
floors are stale and this run is the *second* data point, not a derivation), and
`RIG-F5` — two side-effects of this lane's own ladder fix, written down against
itself so nobody has to work out which version produced which number.

---

## 6. For whoever runs this next

In order, and the first two are not close:

1. **Fix GAME-F4 and write its test.** Restore the base stats in
   `_array_to_party` from `creature_species.definition(species_id)` — the save
   already carries the id, so no format change and no old save is lost — and
   promote the probe to `tests/` as the acceptance criterion. Until this is
   done, no Gate F run past S02 can produce evidence that means anything,
   because every segment after S01 begins with a load and every fight after it
   levels somebody up.
2. **Re-apply GAME-F2's two lines** to `spawns.json` and re-mirror them into the
   band-split baseline fixture, and then put the number somewhere a revert
   cannot silently take it — `progression.json` already writes "2 at the
   practice fight" down in prose, and a test that reads the curve and asserts
   the cluster carries it would have failed at `cfce9d54`.
3. **Then re-run the chain from S02.** With those two fixed, S03's ladder has a
   starter that can win a fight and a party that can reach three, and the run
   reaches the tournament for the first time in this effort.
4. **Decide GAME-F3** before tuning anything else in the Practice Meadow; it is
   an owner call and four options are costed.
5. **Settle GAME-F5's open number** — eleven `gather` events across eighteen
   reached nodes, each pressed twice with the right tool equipped. Until that is
   explained, the measured shortfall and the authored shortfall are not the same
   claim.
6. **Do not chase the village frame cost.** It is settled: §4 above.

---

## 7. What this run could not determine

Named so the gap is not mistaken for a verdict:

- **Anything about how the chapter looks.** No frames were taken. The capture
  lane was not run: this container has no GPU, and Gate F run 2 measured a
  rendered 1920×1080 frame at 12.7 s, which prices the capture lane in hundreds
  of hours. Every prescribed shot was **delegated** to its capture lane and
  remains owed by the run: `tools/gate_f/run_inventory.py` reports
  **0 of 61 prescribed frames present on disk**, itemised in
  `ralph/reports/gate-f-full/RUN_INCOMPLETE.md`. That debt is recorded, not
  discharged — which is the distinction CD-2 exists to keep.
- **Everything from the tournament onward.** S04–S10e, five of six bands, the
  Warrens, the river, the Stronghold, the Warden, the legendary choice and the
  world healing are all unplayed at this candidate.
- **Every study.** X01's controller/menu exhaustion matrix, X02's build lab,
  X03's catch lab, X04's combat lab, X05's save lifecycle, X06's abuse sweep,
  X07's world audit and X08's performance audit are unrun, for the reason in §2.
- **Device frame rate, GPU time, VRAM, thermals, and how any of this feels on a
  ROG Ally.** [OWNER-ONLY], unchanged.
- **Whether GAME-F3 reaches a real player at all**, and how often. The practice
  cluster is randomised per boot, so how often a creature lands next to a
  harvest point is a question about the seed distribution and one run cannot
  answer it.
- **The known intermittent this run was told not to chase** — the arbiter's
  "prompt offered, press activates nothing" family, measured at 1-in-4 at
  `trail_camp` on 2026-08-30 — was neither reproduced nor ruled out here. The
  run never reached a trail camp.
