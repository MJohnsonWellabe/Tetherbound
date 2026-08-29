# Handover — T2-STRANDING, 2026-08-30

**Branch:** `ralph/T2-STRANDING`, off `origin/main` at `a97f3e84`.
**Commit pushed:** `c3c1930e` ("T2-STRANDING: the South Bridge stranding is a
RIG defect, not a GAME one").

---

## 1. What I was asked to do, and where I actually got to

Asked to resolve the single open question five consecutive Gate F journey
segments (S05-S09, plus the first fifth of S10) had left unanswered: is the
South Bridge corridor stranding — every `move_to` past South Bridge missing
by 1.6-6.3 km and landing back at the same tiny cluster of coordinates,
`severed_spokes.gd`'s recovery volume firing 600+ times per segment — a RIG
defect (the harness's straight-line `move_to` failing to navigate a real,
crossable hazard) or a GAME defect (the walkable path or the bridge itself
genuinely broken)? Then fix whichever it is.

**Got to: a conclusive RIG verdict, backed by this run's own real telemetry,
a live-engine probe against the run's own real save, and source reading of
every system in the causal chain — plus a pushed fix.** What I did not
finish: an end-to-end validation run of the fixed `S03.json` producing a real
healthy exit save (in progress as this is written — see §2 and §7).

---

## 2. Done and verified, vs done but unverified, vs still open

**Done and verified (live-engine, this session):**
- The root cause. `tools/gate_f/probe_stranding_cause.gd`, run against this
  run's own real `S05/saves/S05-exit.json`, shows directly:
  `summon_active_creature()` returns `false` and `can_challenge(south_bridge_
  grunt)` returns `false` while the party's one creature is fainted, and both
  flip to `true` the instant that one creature is healed — with nothing else
  touched. Full transcript is in the pushed finding
  (`ralph/reports/FINDING-T2-STRANDING-2026-08-30.md`) and reproducible with:
  ```
  godot --headless --path . --script tools/gate_f/probe_stranding_cause.gd
  ```
- The mechanism chain, each link read from source and cross-checked against
  this run's own telemetry (all citations and line numbers in the finding
  doc): `encounter_director.gd::summon_active_creature()` (L864) and
  `can_challenge()` (L1568) both correctly refuse a fainted, swap-less ally;
  `trainer_npc.gd::_on_challenged()` (L171-172) shows the trainer's `defeated`
  line whenever `can_challenge()` is false for ANY reason, which is why the
  South Bridge grunt appeared to greet the player as already-beaten on a
  fresh approach; `gated_crossing.gd`'s South Bridge gate is a real, correctly
  locked `StaticBody3D` whose key is exclusively the grunt's combat reward
  (`data/config/bands/band1_lower_meadows/trainers.json:188`); `severed_
  spokes.gd::_add_carve_failsafe()`/`_on_carve_failsafe_entered()` is a real,
  correctly-functioning recovery volume, not a broken one — it fires because
  the blind straight-line walker keeps trying to reach a target behind a
  permanently, legitimately locked gate and appears to wander the gully edges
  doing it.
- The actual trigger: this run's own `S03/telemetry/events.jsonl` has a
  `faint` event at `t=256.0` ("Moss fainted", `combat_hit`, `hp: 0.0/1.18`),
  during the RIG-18 catch loop. From that point on, S03's own telemetry has
  exactly one `combat_start`/`combat_end` pair for the rest of the segment
  (the fight in which Moss fainted) — every later "fight" in S03 (Bryn,
  Mira, the CB-13 night fight) and every fight in S04/S05 (confirmed directly
  in S05's telemetry: the "Old Bram" optional fight shows only `dialogue`
  events, never `combat_start`) is dialogue-only. `S05/saves/S05-exit.json`
  itself carries the fainted single creature verbatim: `"fainted": true,
  "hp": 0.0`.
- **RIG-18's own analysis (in `RESTARTS.md`) never looked at the player's own
  creature's HP during those fights** — it was entirely about the wild
  target's catchability. This session's telemetry read is, as far as I can
  tell, the first time anyone noticed the player's own ally was fainting
  during that loop, which is the actual mechanism RIG-18 left as "not
  converging."

**Done, pushed, matches an already-proven pattern, NOT yet independently
run end-to-end:**
- The fix: `tools/gate_f/segments/S03.json` gains five steps
  (`S03-205a`..`S03-205e`) right after the three tutorial creature beds are
  confirmed built and before the segment's own already-scripted sleep:
  `move_to_entity` to the nearest `creature_bed.gd`, `interact_with` (prompt
  "Rest a Creature"), assert the rest panel opened (`context_prefix: panel`),
  press `ui_accept` to confirm the only row (party size 1 at this point,
  RIG-18), close with `menu_cancel`. `data/config/progression.json`'s own
  `creature_bed` comment: "sleeping through the night completes any occupied
  bed's heal immediately" — the sleep step (`S03-223`..`227`) that already
  existed right after this does the rest.
- This exact five-step shape (`interact -> assert panel -> ui_accept ->
  menu_cancel`) is not new: it mirrors `X02.json`'s own already-working bed
  sequence (`X02-091`..`X02-094`), from a segment (X02) that finished
  146/170 PASS with nothing wrong reported in that sequence. I did not invent
  an unproven interaction pattern.
- **What I could NOT get to before writing this handover: a real S03 replay
  from `S02-exit` producing a genuinely healthy `S03-exit.json`.** See §7.

**Still open, explicitly not mine to fix:**
- The secondary UX gap named in the finding: `trainer_npc.gd::_on_challenged`
  cannot distinguish "no usable creature" from "already beaten," and
  `encounter_director.gd::_creature_control_offer()` shows no prompt at all
  (not even an explanation) when the only creature is fainted. Real, minor,
  worth a Track 3 ticket; not the stranding's cause and not fixed here.
- S04 (the tournament) is a full forced-combat gauntlet with no bed
  available at the tournament ground. If a *newly healthy* team takes a hard
  loss there with no swap creature, the same fainted-forever shape could in
  principle recur mid-S04 with nothing downstream to catch it. I did not
  investigate whether this is a real risk (S04 telemetry from this run
  cannot answer it — the team was already down to one fainted creature
  before S04 ever started, so S04 never got a fair test). Flagging as a risk
  for whoever runs the next full chain, not as a finding.
- S10's real cost-gate BLOCKER (0.097 s/frame in real combat vs a
  0.0400 s/frame walking baseline) is unrelated and explicitly not my task
  per the brief; untouched.

---

## 3. RIG or GAME — the answer, stated once, plainly

**RIG.** Every system in the chain — the fainted-ally combat gate, the South
Bridge's physical lock, the carve recovery volume — does exactly what its own
code and comments say it should, and a real player is not stuck: the tutorial
literally builds three creature beds for exactly this ("R4.8...
`heal_fully()` — GAME_DESIGN.md's own phrase: 'revives a fainted creature'"),
and sleeping at home completes any occupied bed's heal instantly. The gap is
narrow and specific: nothing in the RIG's own step-scripts ever put the
fainted creature in one of the beds it built. That is a harness omission, not
a broken game.

---

## 4. What I learned that is not visible in the diff

### The stranding is not really about the bridge, the gate, or `move_to` at all

Every prior session's framing (mine included, at first) treated this as a
navigation/geometry question because that is where the *symptom* concentrates
— severed_spokes firing hundreds of times at one gully. The actual defect is
~250 steps upstream, in a completely different part of the segment (the S03
tutorial catch loop), and by the time it manifests as "stranded at the
bridge" it has already silently voided every fight in three-plus segments.
**Reading `severed_spokes.gd`, `gated_crossing.gd`, or `move_to`'s own
budget-frame logic in isolation would never have found this** — the fix
required reading `encounter_director.gd`'s ally-deployment gate, matching it
against `trainer_npc.gd`'s dialogue fallback, and then going back to this
run's own S03 telemetry to find the actual moment (t=256) the game state
diverged from what every later segment assumed. The lesson for the next
"where did evidence stop matching intent" hunt on this repo: check whether an
early, quiet, un-asserted state change (a faint, in this case) explains a
late, loud, heavily-asserted one, before assuming the loud one's own
immediate neighbourhood is where the cause lives.

### RIG-18's own write-up in `RESTARTS.md` had the exact clue and did not follow it

Its own text: *"'Ripplet is out of the fight.' ... which is also why attempts
2-5 saw a stranger prompt still ... separately caused Moss's own HP to fall
during the segment's earlier, already-working Bryn/wild fights."* That
sentence already named the mechanism — Moss's HP was falling during real
fights — and stopped one inference short of "and it reached zero, and stayed
there for the rest of the game." I did not find anything RIG-18 missed by
being cleverer; I found it by reading the same run's `events.jsonl` for `hp`
values across a wider time window than RIG-18 was scoped to check (it was
diagnosing catch odds specifically, not ally survival).

### The display-server preflight has a gap for `evidence_lane: logic` segments against a stale global freeze record

Attempting a real, honest headless (logic-mode) validation run of the fixed
`S03.json` hit `operator_harness.gd`'s capture pre-flight BLOCKER: `the
freeze record contradicts this process: ... says display_server=X11 under
xvfb-run`. The claim comes from `ralph/reports/gate-f-candidate/RUN_
METADATA.json` — a **stale freeze record from the 2026-08-27 run
(candidate `f082bdf6`), not this run's candidate** — which has no `lanes`
block, so its flat `display_server` claim binds every segment regardless of
its own declared `evidence_lane`, even though `run_segment.sh`'s own CD-1
gate (the shell-script layer) correctly recognises `evidence_lane: logic` and
lets a logic-mode launch proceed. `_freeze_display_claim()`
(`operator_harness.gd:1106`) checks candidates in a fixed order and has no
way for an earlier (or absent) claim to affirmatively rule out a later one —
an empty `{}` at the run's own `RUN_METADATA.json` is skipped rather than
treated as "no claim, stop looking," so it still falls through to the stale
global file. I did not fix this: it is a pre-existing rig behaviour outside
this task's file ownership (touching the shared preflight or the global
candidate freeze record risks the concurrent Gate F/coordination lanes named
in my brief), and the workaround (run under `--capture`, matching the stale
claim) was available and cheap enough not to need it. Flagging it here
because a future logic-only ad hoc validation run will hit the exact same
BLOCKER for the exact same reason.

---

## 5. Disagreements, or things worth owner/coordinator attention

1. **The brief's own framing ("is `move_to` failing to navigate a real
   hazard, or is the path broken") turned out to be a false dichotomy** — the
   honest answer is neither: the path is fine, `move_to` is doing exactly
   what a straight-line walker does against an unreachable target, and the
   actual defect is a state-management gap 250 steps upstream. I want to
   flag this as a pattern for future Gate F triage: a repeated, high-volume
   symptom at one location does not mean the defect lives at that location.
2. **`ralph/reports/handover-GATE-F-RUN-3-2026-08-29.md`'s own suggested
   probe** (whether `_ally`/`_ally.fainted`/`_ally_body`/
   `is_instance_valid(_ally_body)` are true or false at the S05-45 press) was
   the right instinct and I used exactly that shape in
   `probe_stranding_cause.gd`, but the missing piece was never "read these at
   the right frame" — `_ally == null` and `_ally_body == null` the whole
   time, at every frame, because `summon_active_creature()` never runs past
   its fainted-guard. The probe that was needed was simpler than the one that
   was asked for: not "catch the state at the right instant," but "read the
   state at all," which nobody had done for this exact scenario before this
   session.
3. **`ralph/reports/GATE_F_RUN_3_FINDINGS.md` and `GATE_F_RUN_3_RIG_
   FINDINGS.md`** are owned by the concurrent T2-GATEF lane per my brief, so
   I did not touch them, but whoever rewrites them should fold in this
   finding: `party size 1 throughout the run` should be attributed to
   RIG-18's fainted-ally mechanism (this document), not left as a bare
   observation, and the "South Bridge gate still never opens even with
   RIG-13/14 fixed" open item in `RESTARTS.md` should be marked resolved by
   this finding rather than left open.

---

## 6. File footprint

**Touched, committed, pushed (`c3c1930e`):**
- `tools/gate_f/segments/S03.json` — five new steps (`S03-205a`..`S03-205e`),
  no existing steps changed or removed, no ids renumbered.
- `tools/gate_f/probe_stranding_cause.gd` (+ `.uid`) — new, live-engine
  diagnostic probe. Read-only against the game: it loads a save into a fresh
  world instance and calls existing query/action methods
  (`summon_active_creature`, `can_challenge`, `heal_fully`); it does not
  modify any tracked file or any real save.
- `ralph/reports/FINDING-T2-STRANDING-2026-08-30.md` — the finding, pushed
  ahead of full validation per instruction.
- `ralph/reports/handover-T2-STRANDING-2026-08-30.md` — this file.

**Not touched:** `scripts/world/severed_spokes.gd` (read, not edited — it is
not the defect); the South Bridge corridor's terrain/collision/nav (read via
`gated_crossing.gd`/`south_bridge.gd`, not edited — also not the defect);
`data/config/bands/**`; `GATE_F_RUN_3_FINDINGS.md`/`_RIG_FINDINGS.md`; the
original evidence run directory `ralph/reports/gate-f-run-20260828T183531Z/`
— read only, nothing in it was ever modified.

**Scratch, not committed:** an ad hoc validation run at
`/tmp/claude-0/.../scratchpad/gate-f-validation/` (outside the repo, in this
session's scratchpad, seeded only with a copy of the real run's
`S02/saves/S02-exit.json`) — see §7. This directory is not part of the repo
and needs no cleanup by a successor.

---

## 7. Exact commands, and what to do next

**To re-run the live-engine probe** (fast, ~1-2 minutes, needs only the
import cache):
```
godot --headless --path . --script tools/gate_f/probe_stranding_cause.gd
```

**To finish the validation I did not complete**: an S03 run was launched
this session against a scratch copy of the real `S02-exit.json`:
```
export GODOT=/usr/local/bin/godot
export GATE_F_RUN_DIR=/tmp/claude-0/.../scratchpad/gate-f-validation
tools/gate_f/run_segment.sh --capture S03
```
(`--capture` because of the stale-freeze-record preflight gap in §4; a
genuinely headless logic-mode run hits that BLOCKER first.) By the time this
handover was written, that run was still in progress — check
`$GATE_F_RUN_DIR/S03/INVENTORY.json` for `"complete": true`, then check
`$GATE_F_RUN_DIR/S03/telemetry/events.jsonl` for a `combat_start` event after
`t~630` or so (roughly where the CB-13 night fight and the tournament
training fights land) as confirmation the healed party can actually fight
again, and check `$GATE_F_RUN_DIR/S03/saves/S03-exit.json`'s `party[0]`
for `"fainted": false`. If that comes back clean, the fix is fully validated
and the right next move is a real S03→S10 re-run of the actual Gate F
protocol (a new, real run directory, not the scratch one) to get the bands
2-5 evidence Gate F has been missing for five segments running — which was
this task's entire point.

**If the validation run instead surfaces a NEW problem** (a step that doesn't
fire the way I expect, a prompt text mismatch, anything): the five new steps
are isolated and easy to iterate on in `tools/gate_f/segments/S03.json`
without touching anything else in the segment; nothing downstream of
`S03-205e` was changed, so a fix there should not disturb the rest of the
segment's already-working steps.
