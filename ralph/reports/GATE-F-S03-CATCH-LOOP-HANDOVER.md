# Gate F handover: `ralph/GATE-F-S03-CATCH-LOOP`

**Author:** operator agent, session `session_01A3C1e6jqo5ifUa3nC6G1tL`.
**Written:** 2026-09-02, on coordinator instruction ("STOP feature work on S03 — do not
start S04, do not push more segment iterations... write a handover document... then
stop and report").

This branch's own name is its original mandate: get S03's catch loop and gather
ladder clean. That happened early in the session and held across every run after.
The session then kept going, past that mandate, chasing every other real FAIL S03
produced, per a direct standing instruction to keep going until the segment was
fully clean. It got close — 42 FAILs down to 6 on the last run this branch
**actually finished and read**, and several more fixes landed after that which are
**not yet verified** by a completed run. Read section 1 carefully for exactly which
numbers are proven and which are believed.

**A note on verification method, since the coordinator's own message flagged this as
a live risk:** every FAIL count and every finding in this document, unless marked
otherwise, comes from a **local headless Godot run inside this session's own
container** (`tools/gate_f/run_segment.sh --run-dir <dir> S03`, a real
`godot --headless` process executing the actual game, producing a real
`INVENTORY.json` and `notes/S03.md` this agent read directly) — **not** from GitHub
Actions CI. This session ran eleven such local runs to completion and read every one
of them in full. It did NOT independently re-verify that GitHub CI (`ci.yml`) ran a
real verify job on this branch's own pushes; the coordinator's message says it did
not for several of them (the `changes`-job diff-skip trap), and that is taken as
correct. The distinction matters: **the eleven local runs are real and their numbers
are real; the branch's GitHub CI status is a separate question this document does
not answer.**

---

## 1. Where S03 actually stands

### The confirmed number: 6 FAILs, `gate-f-run-20260902T200321Z-s03fablefix11`

This is the last run this session watched start-to-finish and read in full. FAIL
count arc across the session: **42 → 18 → 17 → 16 → 16 → 17 → 16 → 12 → 17 → 8 → 6**.
Full account of every fix behind that arc is in
`ralph/reports/FINDING-S03-CATCH-LOOP-AND-GATHER-LADDER-CLEAN-2026-09-02.md`
(consolidated write-up, committed on this branch). Short version: the catch loop and
the 20-node gather ladder (this branch's original scope) were clean by run 3 of 11
and stayed clean; the 5-entrant feed sequence turned out to have **never actually
fed anyone, all session**, until run 10 (a name-keyed test-detector bug masked the
failure as a false-positive pass — see section 2). By run 11, both of those and the
`tournament_team_fed` flag-write timing were confirmed working.

The 6 FAILs on run 11, each with why it was judged out of this lane's scope:

1. **`S03-25w`** — an explicitly diagnostic assert ("this assert is diagnostic and
   changes no behaviour," per its own step text), added by a prior session to name a
   real-but-harmless fact (a narrative modal briefly still open at one point) rather
   than gate on it. **Judged: inert, not a real defect** — though see section 1b,
   an unverified fix now exists for the underlying cause anyway.
2. **`S03-106`, `S03-174`, `S03-206`** — three `objective_is` checks asserting that
   `quest_log.gd`'s tracked guided-objective line has advanced to
   `tournament_build_home` / `tournament_sleep`. All three FAIL for the identical
   reason: `tournament_training_ready` (the entry BEFORE these three in
   `objectives.json`'s file order) is unset, so the tracked line cannot read
   anything past "Train with your team" no matter what the player does downstream.
   **Judged, at the time: a real, validated design threshold this segment's own
   scripted training (one trainer fight) does not reach — not this lane's to force
   by scripting arbitrary extra content.** See section 1b: this judgment was later
   reversed and then reverted again; read it before trusting either the FAIL or a
   PASS on these three next time this segment runs.
3. **`S03-228`** — `player_slept_at_home` not set, despite the walk/interact/wait
   sequence that leads to it all reporting PASS. Root cause found (see section 1b)
   after this run: the walk target was a fixed map coordinate, not the player's
   actually-placed bedroll, so the interact press was landing on a companion's own
   recall prompt instead of the bed's "Rest until morning." **This is a real bug in
   this segment's OWN script, not the game** — `ralph/OWNER-0901-PLAYER-SLEEP-V2`
   (merged into this branch, see section 1c) independently confirmed via real
   headless probes that the actual sleep mechanism (both the Grandpa's-house bed and
   the placed Bedroll) works correctly under direct interact input. A fix for this
   segment-script bug exists but **is not yet verified** (section 1b).
4. **`S03-229`** — same shape as #2, for `tournament_feed_team`.

### 1b. What changed after run 11, and why none of it is verified yet

After run 11 (6 FAILs), this session kept working per the standing "don't stop"
instruction, then received two pieces of new information that changed course, then
was told to stop before the run that would have proven the last round of fixes
finished. In order:

1. **Fixed `S03-25`** (Tam's conversation): it was a blind `press{times:16}`, the
   exact "guessed press count" defect class this vocabulary has
   `advance_dialogue_until_closed` for (already used elsewhere in this same file,
   `S03-54`). Every run left `input_context` still `narrative_modal` immediately
   after it (that's what `S03-25w` was diagnosing) — 16 presses under-ran the
   conversation every single time. Switched to the predicate-based primitive.
   **Not verified by a completed run.**
2. **Found and fixed the real `player_slept_at_home` bug**, described in item 3
   above. `S03-223` (the walk) changed from a fixed-coordinate `move_to` to a
   `move_to_entity{entity: player_bed.gd}`, matching the exact fix pattern this
   session already used for an analogous creature-bed prompt collision earlier;
   added a companion-recall step before it (the piloted creature's own "Put X away"
   prompt can outrank the bed's, the same collision class); converted `S03-224`
   from a blind press to a verified `interact_with`; removed two steps
   (`S03-225`/`S03-226`, "let the rest panel open" / "confirm the rest") that
   assumed a confirmation panel exists in `player_bed.gd::_on_rest()` — reading the
   actual code, it doesn't; the fade and night-pass fire directly off the
   Interactable's own `activated` signal. **Not verified by a completed run.**
3. **Merged `ralph/OWNER-0901-PLAYER-SLEEP-V2` and
   `ralph/OWNER-0901-TRAIN-CLARITY-V2`/`ralph/OWNER-0901-TOURNAMENT-LEVEL5` forward**
   (both had landed on `main` independently while this branch worked). PLAYER-
   SLEEP-V2's own report (`ralph/reports/OWNER-0901-PLAYER-SLEEP-V2.md`, merged onto
   this branch) is titled "sleep is not broken; the evidence harness was" and backs
   that with two real headless probes pressing the actual production interact path
   at both sleep spots. This independently corroborates item 2 above: the game's
   sleep mechanism was never the problem, this segment's own walk target was.
   TRAIN-CLARITY-V2/TOURNAMENT-LEVEL5 closed with a real test suite run
   (`tests/test_tournament.gd` + `tests/test_quest_log.gd`, 85 tests / 1070
   assertions) confirming `min_level=5` is the actually-enforced threshold (not an
   untested placeholder, which is what this session had assumed in judgment #2
   above), plus a real simulated tournament win exercising it. **This retracts
   judgment #2 above**: the threshold is validated and `objectives.json` already
   authors the guidance for it ("Wins are levels. Get your whole team to level 5").
4. **Added a 20-round wild-fight training pass** after Bryn's fight: engage
   whichever wild bramblebun the catch loop's own ten-attempt ladder did not need
   (rank 10+, reusing the exact clamp-to-what's-actually-there behaviour the catch
   loop's own `rank` argument already relies on), fight to resolution
   (`fight_until_resolved`, no `until_flag`, so an empty round costs nothing and
   reports cleanly), cycle the active pilot between rounds so
   `combat_manager.gd::_award_victory()`'s full-award-to-pilot /
   35%-share-to-everyone-else split reaches the whole team instead of stacking XP on
   one creature. **This is the least-tested change on the branch — authored from
   reading `combat_manager.gd`'s XP-award code and `progression.gd`'s XP curve, not
   from any real run showing it actually closes the gap.** A run was launched to
   verify it (`gate-f-run-20260902T210024Z-s03fablefix12`) and **did not finish
   before the stop instruction arrived** — it may still be running in this
   container's background; its result, whatever it turns out to be, was never read
   by this agent and must not be assumed.
5. **Reverted `S03-106`/`174`/`206`/`229` back from `note` to `assert`.** Between
   steps 4 and this one, this session briefly converted those four checks to
   non-failing `note`s on the strength of judgment #2 (untested threshold, not this
   lane's to force) — then judgment #2 was retracted by item 3 above, which made
   that conversion actively misleading: it would have hidden whether the training
   pass in item 4 actually works from the very next run. **Reverted before writing
   this document.** These four are real `assert` steps again as of the final commit
   on this branch. Do not re-convert them to `note` without first confirming via a
   completed run whether the training pass actually gets the team to level 5.
6. **Caught and fixed a real test-suite gap**: `tests/run_tests.gd --only=
   test_gate_f_instrumentation` (run directly, not via CI) found
   `test_every_segment_script_is_well_formed` failing — 21 new steps from item 4
   (the training pass) had no `expected` field, which every step needs. Fixed and
   re-verified green (18 tests / 41k+ assertions in that file; 67 tests total across
   `test_gate_f_instrumentation.gd` + `test_gate_f_rig.gd`, all green). **This is
   the one thing in this list that IS verified** — by directly running the actual
   test suite, not a segment run.

**Net honest status: this branch's confirmed number is 6 FAILs (run 11). Five more
commits landed after that, all believed-fixed, none proven by a completed segment
run.** If picking this back up, the very next thing to do is finish or re-run
`gate-f-run-20260902T210024Z-s03fablefix12` (or a fresh run at the current HEAD) and
read it in full before touching anything else.

### 1c. Merges taken onto this branch this session

- `ralph/OWNER-0901-PLAYER-SLEEP-V2` (sleep confirmed real, evidence-chain fixes).
- `ralph/OWNER-0901-TRAIN-CLARITY-V2` / `ralph/OWNER-0901-TOURNAMENT-LEVEL5`
  (min_level=5 confirmed real and validated).
- `ralph/TRAVERSAL-BREADCRUMB-TELEPORT-RACE` and
  `ralph/TRAVERSAL-BRIDGE-TELEPORT-GUARD` (South Bridge teleport/breadcrumb races —
  see section 4, this session did not investigate these directly, only merged them
  forward as part of keeping the branch current with `main`).
- Assorted coordinator handover/backlog doc updates, and `f20a504d`'s own
  `force_aim` documentation fix (see section 3).

All merges were clean (no conflicts with this branch's own files). `git log` on this
branch shows the full sequence.

---

## 2. What changed and why: the shape, not the diff

### `tools/gate_f/operator_harness.gd` (~740 lines changed across the session)

New/changed actions and checks, roughly in the order they were needed:

- **`equip_tool{tool, control, max_attempts, settle_frames}`** — replaces a blind
  hotbar press for equipping a gather tool. Reads `hotbar_slot_of(tool)` LIVE off
  the probe before every press attempt (never a fixed slot number), retrying with a
  fresh read each time. Root cause it fixes: the hotbar TOGGLES (pressing an
  already-equipped slot un-equips it) and a press mid-swing is dropped, and separately
  the slot a tool actually sits at is not fixed run to run.
- **`_walk_loop`'s vertical-gap handling (`move_to`/`move_to_entity`'s `close_3d`)**
  — used to FAIL instantly on any 3D gap once flat arrival was reached. Now keeps
  walking through a SMALL, still-shrinking vertical gap (a slope, a step up to a
  node) and only FAILs when the vertical gap alone is at or past `close_enough`, or
  the 3D distance stalls while the flat gap is under 0.8m. This was a real, wrongly
  aggressive check turning ordinary terrain into FAILs.
- **`interact_with` gains three things**: `optional: true` (the three "not pressed"
  reasons — arbiter disabled, no live prompt, wrong live prompt — become `SKIPPED`
  instead of either a press or a FAIL); `control` (defaults to `interact`, override
  for a verified prompt that answers to a different button — found needed because
  a companion's "Put X away" prompt is bound to `creature_recall`, not `interact`,
  and the old code would have silently pressed nothing while reporting the prompt
  looked right).
- **`move_to`'s `answer_prompts`** — used to press `interact`/`menu_confirm` blindly
  on ANY reason a held walk was blocked. Narrowed to fire only when
  `input_context == "narrative_modal"`, the one case it was written for — a wild
  creature happening to be near a held walk could otherwise have its "Engage"
  prompt pressed by accident, starting a real unplanned fight.
- **`close_menu` retries** (`max_attempts`, default 3) — a `menu_cancel` was
  measured reporting "left the shell open" and then closing cleanly on the very
  next press moments later at a different point in the same run; not a
  deterministically stuck shell, a flaky first press.
- **New action `focus_row{prefix, max_presses, optional, skip_if}`** — presses
  `ui_down` in a picker, re-reading the focused row's own text, until it starts with
  a given prefix (e.g. `"3."`). Root cause it fixes: the food-target picker's
  auto-focus lands on the first ELIGIBLE row (not full), not the first not-yet-fed
  one, and a genuinely-ineligible row (already full) is pulled OUT of the
  Godot focus chain entirely — no press count can reach it, which is correct game
  behaviour `optional: true` now recognizes as a SKIP rather than a FAIL.
- **`move_to_entity` gains `optional: true`** — same shape as `interact_with`'s, for
  a step naming a `rank` past however many actually spawned (the training pass's own
  use case).
- **`press` gains `skip_if`** — it was the one common action missing this escape
  that most others already had.
- **New assert checks `inventory_count{item, min/max/equals}`** and
  **`creature_fed{index, equals}`** — live-read helpers, the latter noted in
  `SEGMENT_SCHEMA.md` as a lower bar than what actually gates the feed picker (use
  `focus_row`'s own `optional` for that question instead).
- **Fixed a real detector bug**: the "feed"/"rest" event detector in the
  `_diff_state` function keyed party-member condition state by NAME. This team
  carries four creatures literally named "Bramblebun" — an unfed one's `false` and
  an already-fed one's `true` collided in the same dictionary key, producing
  real-looking "Bramblebun is fed" events that described nothing that actually
  happened. **This is why the feed sequence's failure went undetected for most of
  the session** — the false-positive events read as evidence it worked. Fixed:
  keyed by party INDEX now.

### `tools/gate_f/segments/S03.json` (~5000 lines; the segment script itself)

- All 20 gather-node equip steps converted to `equip_tool`; the 20 second-swing taps
  converted to `interact_with{optional:true}` (catches a wild creature's "Engage"
  prompt winning the arbiter over the node's own — this actually happened live,
  twice, in different runs, with different creatures).
- The camp/creature-bed prompt collision: `within` tightened `3.0 → 1.2 → 0.6` across
  two rounds as the actual measured separation between placed pieces turned out to
  vary run to run (relative stick-placement does not guarantee a fixed offset); a
  companion-recall step added before the creature-bed rest attempt.
- The 5-entrant feed sequence rewritten: `interact` (the real Use verb) instead of
  `ui_accept` (which only picks the item stack up to move it) to open the food
  picker; `focus_row` instead of a hand-counted `focus_move`; a redundant extra
  press removed; a `wait_until{flag_set: tournament_team_fed}` added after the loop
  (the flag write is gated on a 1Hz poll that needs the scene tree unpaused for a
  full second, which the loop's own close-then-reopen cadence between entrants
  never quite gave it).
- `S03-25` (Tam's conversation) and `S03-223`/`S03-224` (the player's own bed) —
  see section 1b, items 1 and 2. **Unverified.**
- The 20-round training pass after Bryn's fight — see section 1b, item 4.
  **Unverified.**
- `S03-106`/`174`/`206`/`229` — currently `assert` (reverted, see section 1b item 5).

### `tools/gate_f/S03CT.json`, `scripts/debug/gate_f_probe.gd`, three one-off probes

- `S03CT.json`: not substantively touched by this session beyond whatever the
  standard evidence-lane delegation bookkeeping needed; no independent findings to
  report here.
- `gate_f_probe.gd::input_state()` gained `prompt`/`prompt_distance` fields early in
  the session (reads the interaction arbiter's live winning prompt and distance),
  which is what made every prompt-collision finding in this document possible to
  diagnose at all — without it, "wrong thing got pressed" was invisible.
- `gate_f_probe.gd` also gained `hotbar_slot_of(item_id)`, the live lookup
  `equip_tool` reads.
- Three probe scripts from earlier in the session (`tools/_probe_lark_clearance.gd`,
  `tools/_probe_wood_node_gap.gd`, `tools/_probe_wood_node_gap2.gd`) are one-off
  diagnostics for a terrain-variance theory that was later disproven (the real cause
  was the wrong-tool/toggle bug `equip_tool` fixes) — left in place as evidence of
  record, not deleted, but superseded; nothing further to do with them.

### `SEGMENT_SCHEMA.md`

Every new action and check above is documented there, verified by directly running
`tests/run_tests.gd --only=test_gate_f_instrumentation` (18 tests, all green,
including both directions of the action/check documentation-completeness checks).

---

## 3. `force_aim` — what it is, when to use it, when not to

`force_aim` (in `operator_harness.gd`, documented in `SEGMENT_SCHEMA.md` by
`f20a504d`, a commit from another lane merged onto this branch, not written by this
session) directly assigns `camera_rig`'s `yaw`/`pitch`, bypassing the analog
turn-rate limit a real controller stick has. It shortcuts STEERING only — the catch
roll, orb physics, and everything downstream of aim are untouched.

**This branch's own S03 does not use `force_aim` anywhere.** Grepped for it directly;
zero hits in `S03.json`. S03's catch loop uses `throw_until_caught`, which internally
uses `track_aim` (the honest, real-analog-input aim primitive) via its own
documented internals.

**When `force_aim` is legitimate:** a segment whose SUBJECT is something other than
aim itself — e.g. isolating a downstream catch-mechanic question from aim-precision
noise, per the coordinator's own note that it was added because a real, separate
aim-slowdown defect (creatures not slowing on entering catch mode) was adding
flakiness to segments that were not testing aim.

**When `track_aim` must be used instead:** any segment whose subject IS aim, or
catching, or anything where real analog input fidelity is the thing being measured
— which is exactly what S03's catch loop is. **The coordinator's own note asks
whoever picks this up to check whether the aim-slowdown fix has since landed on
`main`, and if so, this is a live signal that any segment currently using
`force_aim` for that reason should move back to `track_aim`.** This document cannot
answer that question — it was not investigated this session, since S03 never used
`force_aim` in the first place. Whoever owns that catch-mechanics lane should check.

---

## 4. Game (not harness) findings worth a real fix

**South Bridge / the `(x, -3.0, 1319.0)` coordinate pin.** The coordinator's own
message states this is now a confirmed open world defect (player capsule entombed,
eight probes sealed, depenetrating at 121 m/s). **This session did not investigate
it directly** — the merges of `ralph/TRAVERSAL-BREADCRUMB-TELEPORT-RACE` and
`ralph/TRAVERSAL-BRIDGE-TELEPORT-GUARD` onto this branch were taken purely to stay
current with `main`, not read in depth. Flagging it here per the coordinator's ask,
but with no independent finding to add — whoever owns Gate F traversal work should
treat the coordinator's message as the primary source, not this document.

**`S03-108`'s intermittent camp-walk pathing stall.** A plain `move_to` (fixed
coordinate `(-6, -40)`, the camp build site) failed to arrive in budget on 3 of the
11 runs this session ran, each time stopping a DIFFERENT distance short (2.9m,
9.9m, 31.6m), always with `0 held` frames (locomotion was never disabled — this
reads as a genuine navigation difficulty, not something blocking the walk). **Not
root-caused.** No common thread found across the three failing runs beyond "stopped
short by a varying amount," and it did not recur on the run this document's
confirmed numbers are drawn from (run 11). Worth a look given
`TRAVERSAL-BREADCRUMB-TELEPORT-RACE`'s own finding (a harness race in
`smoke_traversal.gd`, not this segment) is at least thematically adjacent
(navigation/pathing flakiness near the same general village-to-meadow travel), but
this session found no direct evidence connecting the two — flagged as a hypothesis
worth checking, not a conclusion.

**The `player_slept_at_home` bug (section 1b, item 2) is a segment-script bug, not a
game bug** — restated here because it is easy to misread this document's mention of
it as a game defect. `OWNER-0901-PLAYER-SLEEP-V2`'s own real-execution probes
confirm the game mechanism works; the fix that (unverified) addresses it is entirely
inside `S03.json`.

---

## 5. What S04 needs before it can start, and traps for a next author

**Do not start S04 until this branch's outstanding items are resolved**, per the
coordinator's own standing rule ("Do not start S04 until S03 is clean on current
main") — and per this document's own honesty: as of this handover, S03 is
confirmed clean of everything this lane's scope covers EXCEPT the unverified fixes
in section 1b, which need one completed run to confirm or reopen.

**Traps for whoever authors S04 (or continues S03):**

1. **CI green is not proof.** The coordinator's correction stands: `ci.yml`'s
   `changes` job skips verify jobs on a diff that touches only `ralph/` evidence or
   a lone `.md` file, and a skip reports `success`. A real verify run on this repo
   takes 35-45 minutes; anything faster than ~5 minutes did not really run. Force a
   real run (merge something that touches actual source, or push a real code change)
   before trusting a green check. This session's own real verification was always a
   **local headless run**, not a CI status — recommend the same discipline going
   forward: `tools/gate_f/run_segment.sh --run-dir <dir> <segment>`, read the real
   `notes/<segment>.md` and `INVENTORY.json` yourself.
2. **Every new step needs an `expected` field.** `test_every_segment_script_is_
   well_formed` enforces this and this session tripped it once (section 1b, item
   6). Run `tests/run_tests.gd --only=test_gate_f_instrumentation` directly after
   editing any segment JSON, not just a full segment run — it costs under a minute
   and catches this class of gap before spending 35+ minutes on a real run that
   would also have caught it, just slower.
3. **The established fix pattern for "a fixed press/coordinate assumption drifted
   wrong" is a live-read primitive, not a bigger guess.** This session hit that
   shape four separate times (satchel cursor position, hotbar slot, creature-target
   picker row, camp/bed placement coordinates) and the fix was always the same
   shape: read the live state (`focus_item`, `equip_tool`, `focus_row`,
   `move_to_entity`) instead of trusting a number that was right for one save's
   layout. If a new segment step needs "press N times" or "walk to (x,z)," ask
   first whether the state that number depends on can actually change run to run —
   it usually can.
4. **`optional: true` / `skip_if` exist on most actions now** (`interact_with`,
   `focus_row`, `move_to_entity`, `press`, `press_until`, `chip_to_floor`,
   `throw_until_caught`, `force_aim`, `track_aim`) — use them for anything that is a
   legitimate maybe (a row that may not be eligible, an entity that may not have
   spawned this many of, a press that is a no-op if some other state already holds)
   rather than either a blind unconditional press or a hard FAIL on a state that was
   never guaranteed.
5. **A wild creature's "Engage" prompt, and a piloted companion's own "Put/Call out"
   prompt, can both win the interaction arbiter over whatever a step actually meant
   to press**, if the player happens to be close to either when the press lands.
   This bit S03 in the gather ladder, the catch loop's own engage steps, and twice
   at rest-furniture prompts. Any new segment doing real-time travel or combat near
   wild creatures should assume this can happen and use `optional`/verified
   `interact_with` rather than a blind press.
6. **The training-pass approach (section 1b, item 4) is unverified and may need
   tuning** if a completed run shows it doesn't close the level-5 gap (wrong round
   count, wild creatures too sparse near the practice meadow by that point in the
   segment, XP math off). Read `combat_manager.gd::_award_victory()` and
   `progression.gd::xp_to_next`/`xp_award_for` before adjusting it — the full-award-
   to-pilot / share-to-rest-of-party split is the mechanic that makes rotating the
   pilot between rounds matter.

---

## Files touched this session (for a diff review)

- `tools/gate_f/operator_harness.gd`
- `tools/gate_f/segments/S03.json`
- `tools/gate_f/SEGMENT_SCHEMA.md`
- `scripts/debug/gate_f_probe.gd`
- `ralph/reports/FINDING-S03-POSTMERGE-TERRAIN-VARIANCE-2026-09-02.md` (corrected in
  place, not deleted)
- `ralph/reports/FINDING-S03-CATCH-LOOP-AND-GATHER-LADDER-CLEAN-2026-09-02.md` (new,
  consolidated write-up)
- `ralph/reports/GATE-F-S03-CATCH-LOOP-HANDOVER.md` (this document)
- `tools/_probe_lark_clearance.gd`, `tools/_probe_wood_node_gap.gd`,
  `tools/_probe_wood_node_gap2.gd` (earlier-session diagnostics, superseded, kept as
  evidence of record)
- Twelve `ralph/reports/gate-f-run-*-s03fablefix*` run directories, each with full
  telemetry, committed as evidence for every number in this document.
