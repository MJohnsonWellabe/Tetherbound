# Handover — T2-GATEF-RUN4, 2026-08-30

**Branch:** `ralph/T2-GATEF-RUN4`, off `origin/main` at `cba700b5`.
**Commits pushed, oldest first:**
```
7490fc18  Fix GAME-0 fainted-ally interaction-offer lockout and T1 trainer dialogue collapse
0bcbaa67  Update Gate F run 3 findings: GAME-0/T1 fixed, add GAME-8/9 and RIG-23/24
4c9ef313  Add S03 validation run evidence (pre/post GAME-0 fix)
```

---

## 1. What I was asked to do, and where I actually got to

The mission brief named six items, in priority order: (1) root-cause and fix
the `home_built`/`creature_bed_built_3` blocker in the rig, (2) fix
`trainer_npc.gd`'s dialogue collapse (T1, dark-features), (3) produce a
healthy S03 -> S09 exit-save chain, (4) run the remaining segments
(X04, X07/X08, X01, X06, X05, S10), (5) rewrite the two findings documents,
(6) verify/create `band4_upper_meadows_ironwood/harvest.json`.

**Got to:**
- **(2) fully done, live-tested, pushed.**
- **A bonus fix not in the original brief, but a hard prerequisite for (2)
  to matter**: GAME-0, the single highest-priority unfixed defect already on
  record in `GATE_F_RUN_3_FINDINGS.md` before this session started. Done,
  live-tested, pushed.
- **(6) already true on `main`** — verified, no action needed.
- **(1) and (3): investigated thoroughly, not resolved.** The blocker named
  in the brief (`home_built`/`creature_bed_built_3` "never register") was
  already substantially fixed by `T2-BUILDPLACE`'s three rounds before this
  session started (door, revive, tool-equip). What's left blocking a healthy
  S03 exit save are two **new** defects this session found and documented
  but did not fix — see §3.
- **(4): not run.** Every one of those segments is gated on (3) per the run-3
  handover's own stated order, and (3) did not complete.
- **(5): the docs were already substantially current**, contrary to the
  brief's description of them as narrating RIG-11 as open with staleness
  banners — that was not true of the state I found on `main`. Updated
  (not rewritten) with this session's findings.

---

## 2. Done and verified

- **GAME-0** (`scripts/combat/encounter_director.gd::interaction_offer()`):
  the fainted-ally "is out of the fight" statement carried priority 100 at
  distance 0.0, which `prompt_arbiter.gd`'s priority-before-distance rule
  let outrank *every* other interaction in the world — village greetings,
  trainer prompts, harvest nodes, creature beds — for the rest of a live
  session once a deployed ally fainted. This was flagged by two prior lanes
  (`T2-STRANDING`, `T2-BUILDPLACE`) as the most severe unfixed finding in the
  whole Gate F run 3 record. Now priority 0 (`interactable.gd`'s own
  default) and distance 9999.0 (was 0.0): still wins, and still tells the
  player why, when it's the only offer, but loses the arbiter's tie-break to
  any real, closer offer instead of substituting for one.

- **T1** (dark-features inventory item, `trainer_npc.gd:171-172`):
  `_on_challenged` collapsed all four reasons `can_challenge()` can be false
  into the trainer's `defeated` line, so a player with no usable creature got
  falsely told they'd already won. Added
  `encounter_director.gd::no_usable_ally()` — a sibling query,
  `can_challenge()`'s own bare-bool contract (8+ call sites) is untouched —
  and one new branch in `_on_challenged` that opens a single generic
  conversation (`trainer_no_usable_creature`, `data/dialogue/trainers.json`,
  one line, not per-trainer data) instead.

- **New test:** `tests/smoke_trainer_no_usable_ally.gd` — live-engine, full
  world stand-up, faints a real deployed ally, confirms the honest line
  opens (not `defeated`), confirms no fight starts and the defeat flag stays
  unset, then heals the same ally and confirms the *real* challenge
  conversation reopens on the same trainer in the same session. **PASS.**

- **Regression check:** `tests/smoke_trainer_battle.gd` (the existing
  full-trainer-fight smoke test) still PASSes unmodified — the priority
  change doesn't disturb an ordinary challenge/fight/reward/re-challenge
  cycle. `tests/run_tests.gd` (full unit suite, no filter): **1600 tests,
  3,388,789 assertions, 0 failed.** The `ERROR:`/`SCRIPT ERROR:` lines in the
  raw log are deliberate negative-test probes (bad species ids, malformed
  JSON, missing autoloads under `--script`) and Godot's own shutdown-time
  resource-leak warnings, not failures — read the `0 failed` line, not the
  grep count.

- **`data/config/bands/band4_upper_meadows_ironwood/harvest.json`** already
  exists on `main` with real wood/stone/fiber nodes (3/4/4 respectively,
  alongside the 10 ironwood nodes D4 was about). The documented blocker is
  stale; no action taken.

---

## 3. Investigated, NOT resolved: the S03 blocker has moved, not closed

The brief's framing ("home_built/creature_bed_built_3 never register... fix
it in the rig") describes `T2-BUILDPLACE`'s own *starting* diagnosis from
round 1. By the time that lane's three rounds landed on `main`
(`ralph/reports/FINDING-T2-BUILDPLACE-2026-08-30.md`), the picture had moved
a long way: round 1 fixed the tool-equip gap, round 2 found and partially
mitigated GAME-0 (the fainted-ally lockout, which this session finished
fixing — see §2), round 3 fixed a shut door blocking Mira's own shop and
added a revive-on-faint fallback — and round 3's own last section says
plainly that the kept `S03-exit.json` was **still** unhealthy, for a fourth,
not-yet-diagnosed reason it names but does not solve (`S03-60`, "walk past
Oskar on the way back", fails and the resulting stuck-mashing accidentally
re-triggers Mira's own second-visit fight, spending the party's last Revive
with nothing left to catch a third faint).

This session picked up exactly there. What I found:

### GAME-8 / RIG-23 — the exit walk from Mira's shop traps the harness's navigator against the counter/shelf collision

A new staging step (`S03-59a`, mirroring `S03-52`'s own already-proven
door-approach point) does **not** fix `S03-60`. Two new live probes
(`tools/gate_f/probe_oskar_walk_trace.gd`,
`tools/gate_f/probe_oskar_stuck_geometry.gd`, both committed) pin the cause
precisely: the walker gets wedged in building-local space `(-1.37,
0.3..2.37)` — directly between `shop_interior.gd`'s own west wall and the
two stock-crate shelf boxes it places at local `(-1.3, ..., 1.5)` — because
the straight line from Mira's own stand-behind-the-counter position to the
door clips the counter itself, and `tests/helpers/stick_navigator.gd`'s
generic wall-slide detour (written for open outdoor obstacles, by its own
header's admission) picks the wrong side and gets stuck in a ~0.3-0.4m gap.
**Every waypoint I tried** — the raw target, the proven door-staging point,
an explicit door-lane point 0.4m clear of the counter's own edge — hit the
same or a near-identical stuck point. This is not a coordinate-tuning
problem the way the door was; the entry leg through this exact room is
live-confirmed clean every time, only the exit leg traps, which points at
the detour's side-choice heuristic behaving differently by direction of
travel. Full detail, exact coordinates, and both probes' output are in
`GATE_F_RUN_3_FINDINGS.md`'s new GAME-8 entry.

### GAME-9 / RIG-24 — the tool-equip sequence does not reliably hold inside a full replay

Re-running S03 with GAME-0's fix in place produced a genuinely new, positive
result: **six real `gather` events fire** with the party permanently
fainted — GAME-0's fix means gathering is no longer blocked by the
fainted-ally lockout at all. But `home_materials_gathered` still never sets:
all six events' own `equipped` field reads `{hotbar_slot: 3, item: "knife"}`
— the *same* tool, the *same* slot, on every attempt — despite the
segment's own `hotbar_2`/`hotbar_3`/`hotbar_4` presses rotating between
nodes, and despite `tools/gate_f/probe_tool_equip_sequence.gd` (BUILDPLACE's
own probe) proving the identical assign sequence correct **from a fresh
`S02-exit.json`**. Something about the state that accumulates over a real
~450-second prior replay (two real fights, two revives, a third unhealed
faint, the door detour) leaves this sequence not behaving the way the
isolated probe predicts. Not root-caused past this point this session — see
GAME-9's own entry for exactly what was and wasn't checked.

### Why I stopped here rather than pushing further

Both of these are genuine defects, each independently confirmed live and
each requiring different, non-trivial follow-up (either a per-room waypoint
table or a `shop_interior.gd` geometry revisit for GAME-8; a stateful replay
vs. fresh-load divergence hunt for GAME-9) — not the kind of thing a few
more coordinate guesses fixes. `T2-BUILDPLACE`'s own three rounds already
demonstrated how expensive that iteration style is (ten-plus full-segment
replays, each several minutes, converging slowly one symptom at a time). I
judged that documenting both precisely, with live-engine proof and working
diagnostic tooling left behind, was worth more to whoever picks this up next
than a fourth or fifth speculative fix attempt inside this session's own
remaining budget. This is the same judgment call `T2-BUILDPLACE` itself made
at the end of its own round 3.

**Two validation run directories are kept as evidence**, both seeded from
the same real `S02-exit.json`
(`ralph/reports/gate-f-run-20260828T183531Z/S02/saves/S02-exit.json`):
- `ralph/reports/gate-f-run4-s03-validation/` — before the GAME-0 fix.
- `ralph/reports/gate-f-run4-s03-validation-2/` — after it. This is the one
  that shows the six real `gather` events and the `equipped` mismatch;
  read its `S03/telemetry/events.jsonl` directly if you want the raw trail
  rather than my summary of it.

---

## 4. What I learned that is not visible in the diff

### GAME-0 was reachable, once I actually tried to exercise T1 live

I did not set out to fix GAME-0. I found it because my first version of
`tests/smoke_trainer_no_usable_ally.gd` — which faints a real deployed ally
and then presses `interact` at a never-fought trainer — FAILed with "no
dialogue opened at all," even though `can_challenge()`/`no_usable_ally()`
were reading exactly as expected. Reading `interaction_offer()`'s full body
(not just the branch `can_challenge()` uses) showed why: the fainted-ally
statement was winning the *global* prompt arbiter regardless of the
trainer's own distance, so `interaction_arbiter.gd::activate()` never even
called the trainer's `interaction_activate()`. T1's fix would have been
correct but practically unreachable by a real player (or by this session's
own test) without also fixing GAME-0 — the two are much more tightly
coupled than the two prior lanes' own separate write-ups suggested, because
neither of them tried to drive a live interaction through both gates at
once.

### A fresh-load probe and a full-replay outcome are two different experiments, confirmed a third time this run

`T2-BUILDPLACE`'s own handover already named this pattern once (a probe
that sets state directly can miss a bug that lives in a different system's
cached copy of the same fact) and named it again for its own Mira-approach
work (round 2's LOS sweep answered a narrower question than it looked like
it answered). GAME-9 is a third, independent instance of the same shape:
`probe_tool_equip_sequence.gd`'s own PASS, from a clean load, said nothing
reliable about the same sequence's behavior 450 seconds into a real replay.
Worth stating as a standing caution for this repo rather than three
separate one-off lessons: **an isolated probe proves a mechanism works in
isolation, not that it works in place.** A full-segment replay is still the
only real check.

### The "answer_prompts stuck-mashing" framing in BUILDPLACE round 3's own writeup was slightly imprecise, and it mattered for what I tried next

Round 3 attributed the accidental Mira re-fight to `_walk_loop`'s own
stuck-mashing behavior (pressing `interact` every 20 *held* frames).
Reading this run's own telemetry closely: the walker was never actually
`held` (locomotion never disabled) during the `S03-60` stall — it kept
sliding, just never arriving. The re-fight trigger is `S03-61`
("speak to Oskar"), the very next scripted step, pressing `interact`
unconditionally regardless of where the walk actually stopped. This is a
small correction, but it changed where I looked for a fix (the walk itself,
not the held-frame mashing logic) and is worth recording so the next reader
doesn't inherit the same slightly-off mental model.

---

## 5. Disagreements, or things worth coordinator/owner attention

1. **The mission brief's own description of `GATE_F_RUN_3_FINDINGS.md`/
   `_RIG_FINDINGS.md` as stale (narrating RIG-11 as open, staleness
   banners) did not match what I found on `main`.** Both files already
   carried a `T2-GATEF`-branch "Rewritten: 2026-08-30" header, correctly
   documented RIG-11 as fixed with commit evidence, and were current through
   `T2-BUILDPLACE`'s own landing. I updated rather than rewrote them. If a
   genuinely stale copy exists somewhere else (a different branch, an older
   local checkout), that's worth reconciling, but it was not what `main`
   had.

2. **I want to flag GAME-8 and GAME-9 as the actual current blocker for
   Gate F's entire remaining evidence plan**, the same way `T2-STRANDING`'s
   own handover flagged the South Bridge stranding as "the dominant fact
   this run has to report" rather than a footnote. Every segment from S04
   onward in this run's own priority order (X04, X01, X06, X05, S10) is
   gated on a healthy S03 -> S09 chain, and that chain still does not exist
   after four dedicated sessions' worth of work on it (T2-STRANDING,
   T2-BUILDPLACE x3, this one). I don't think the next session should start
   a fifth speculative-coordinate-fix attempt without first deciding, as an
   explicit choice: is a per-room waypoint table for `stick_navigator.gd`
   (a shared, widely-used test helper) worth the risk of touching it, or is
   revisiting `shop_interior.gd`'s own counter/shelf placement the safer
   surface? I don't have a strong recommendation between the two — both are
   real, bounded pieces of work, neither is a five-minute fix.

3. **A structurally different way to get bands 2-5 evidence exists and I
   did not pursue it**: since GAME-8/GAME-9 are specific to the S03
   tutorial's own tool-equip/shop-interior sequence, a healthy hand-authored
   `S03-exit.json` (built once, by hand or by a targeted script, rather than
   through the full tutorial replay) could unblock S04 onward immediately
   without waiting on either fix. I did not attempt this because it steps
   outside "fix it in the rig, not by teleporting past it," which is this
   lane's own standing instruction, but it is a real option if the
   coordinator judges unblocking bands 2-5 evidence is more urgent than a
   fully-organic S03 replay right now.

---

## 6. File footprint

**Touched, committed, pushed:**
- `scripts/combat/encounter_director.gd` — GAME-0 fix (priority/distance
  tuning on the fainted-ally statement) + `no_usable_ally()` (new method,
  T1).
- `scripts/world/trainer_npc.gd` — T1 fix (`_on_challenged`'s new branch,
  `_progression()` helper, `NO_USABLE_CREATURE_CONVERSATION` constant).
- `data/dialogue/trainers.json` — one new generic conversation,
  `trainer_no_usable_creature`.
- `tools/gate_f/segments/S03.json` — one new step, `S03-59a` (the Mira-door
  exit staging attempt; live-confirmed not sufficient on its own, kept
  because it is a strict improvement and does no harm).
- `tests/smoke_trainer_no_usable_ally.gd` (+`.uid`) — new, live-engine,
  PASSes.
- `tools/gate_f/probe_oskar_walk_trace.gd`,
  `tools/gate_f/probe_oskar_stuck_geometry.gd` (+`.uid`s) — new, live-engine
  diagnostics behind GAME-8/RIG-23, kept as committed tooling per this
  branch's own precedent (`T2-BUILDPLACE`'s probes).
- `ralph/reports/GATE_F_RUN_3_FINDINGS.md` — GAME-0 and the T1 half of
  GAME-5 marked fixed; new GAME-8, GAME-9.
- `ralph/reports/GATE_F_RUN_3_RIG_FINDINGS.md` — new RIG-23, RIG-24,
  cross-referencing the above.
- `ralph/reports/gate-f-run4-s03-validation/`,
  `ralph/reports/gate-f-run4-s03-validation-2/` — validation run evidence,
  pre/post the GAME-0 fix.
- `ralph/reports/handover-T2-GATEF-RUN4-2026-08-30.md` — this file.

**Not touched:** `tests/helpers/stick_navigator.gd` (read extensively, not
edited — a fix here is real candidate work for GAME-8 but is shared by
every segment in the protocol and needs its own dedicated, validated pass,
not a change folded into this session's already-large diff);
`scripts/world/shop_interior.gd` (read, not edited — same reasoning);
`data/config/bands/band4_upper_meadows_ironwood/harvest.json` (verified
correct, not edited — nothing to fix); X04/X07/X08/X01/X06/X05/S10 and
their segment JSON (not run, not touched — gated on the S03 blocker above).

---

## 7. Exact commands, and what I'd do next

**To re-run the two new probes** (fast, ~2-3 min each including world
stand-up):
```
godot --headless --path . --script tools/gate_f/probe_oskar_walk_trace.gd
godot --headless --path . --script tools/gate_f/probe_oskar_stuck_geometry.gd
```

**To re-run the new smoke test:**
```
godot --headless --path . --script tests/smoke_trainer_no_usable_ally.gd
```
Should print "trainer no-usable-ally dialogue: OK".

**To re-attempt a full S03 replay** (several minutes; needs a scratch run
dir seeded with a real `S02-exit.json` and a local `RUN_METADATA.json`
declaring a plain headless `display_server` — copy the shape from
`ralph/reports/gate-f-run4-s03-validation-2/RUN_METADATA.json`):
```
tools/gate_f/run_segment.sh --run-dir <scratch-dir> S03
```

**What I'd do next, in order:**
1. Decide, explicitly, between the two GAME-8 fix shapes named in §5.2
   (a `stick_navigator.gd` waypoint table, or a `shop_interior.gd` geometry
   revisit) — this is a real design choice, not something to default into.
2. Once S03-60 converges, re-check GAME-9 live: does the tool-equip mismatch
   still reproduce, or was it downstream of the same navigation trap
   (possible but not confirmed — I did not have time to test this
   hypothesis)?
3. Once a genuinely healthy `S03-exit.json` exists, chain S04 through S09
   and confirm each exit save's party stays healthy — this is the actual
   prerequisite the whole Gate F evidence plan has been waiting on since
   `T2-STRANDING`'s own session.
4. Only then run X04 first (per the run-3 handover's own stated order —
   its combat lab needs a real fight to be possible at all), then
   X07/X08, X01, X06 (stop early if it degrades, per the same handover),
   X05, and S10 via the already-landed `T2-S10-COST` split.
