# Handover — T2-BUILDPLACE, round 3, 2026-08-30

**Branch:** `ralph/T2-BUILDPLACE`, continuing on top of the prior session's
own commits (`1729270`..`7988a903`, off `origin/main` at `a97f3e84`).

**Read first:** `ralph/reports/FINDING-T2-BUILDPLACE-2026-08-30.md` in full
— it now carries three rounds of evidence, and this handover summarizes
round 3 specifically (the round this session ran). Also read
`ralph/reports/handover-T2-BUILDPLACE-2026-08-30.md` (round 2's own
handover) if you have not already, since round 3 corrects one of its
findings (see §2 below).

---

## 1. The headline: NOT a healthy `S03-exit.json` yet — read this before anything else

**Both defects this session set out to fix (Mira's shut door, and a
solo-member fainted party) are fixed, live-verified, and hold in two full
real segment replays end to end. The kept `S03-exit.json` from the final
replay is still NOT healthy: `party_size == 1`, that one creature
`hp: 0.0`, `fainted: true`.** The harness's own `INVENTORY.json` reports
`"complete": true` with zero derail for this run — which is exactly the
trap the task brief warned about ("do not trust `"complete": true` ... as
proof of a healthy party"), and I want it stated as plainly as the brief
asked rather than left for someone to discover by reading the save
themselves.

The reason is a FOURTH cause, found live while proving the first two
fixes end to end, sitting well outside this lane's original brief
(`S03-60`, hundreds of lines past where Mira's own sequence ends) — see
§2.4 and `FINDING-T2-BUILDPLACE-2026-08-30.md`'s own "Round 3 — still
open" section for the full chain. In short: the Satchel's 2 Revives get
spent correctly on two real, expected faints (the catch loop, then Bryn's
now-real fight) — both are exactly what they're supposed to do, working
as designed — and then a THIRD, unanticipated fight (Mira's own Band-1
challenge, triggered by surprise when a later, unrelated walk gets stuck
near her building and `answer_prompts` presses `interact` while stuck)
faints the now-Revive-less party a third time, with nothing left in the
segment to recover it. A candidate fix is sketched but NOT run or
verified — see §4 and §7.

---

## 2. What was actually wrong, in one paragraph each

**Round 2 left two things unsolved that this round found and fixed, plus
one thing round 2's own fix broke without noticing:**

1. **Mira's approach was never a positioning or RNG problem.** OF31 (an
   already-landed change, unrelated to this lane) moved Mira inside
   `cottage_a` behind a real, physically shut door
   (`scripts/world/village_door.gd`) — closed by default, with a solid
   `Gate` collider spanning the doorway that blocks both walking AND the
   `interactable.gd::_has_line_of_sight()` check her own greeting needs.
   Every "stuck 2-5m short" and "arrived but still refused" symptom across
   all three rounds was this one collider, read two different ways. Fixed
   by walking to a fixed point outside the door, pressing `interact` on
   its own "Open Door" prompt, then walking in — live-confirmed converging
   in well under 100 frames with `0 held` where it used to wander for
   hundreds.

2. **`party_cycle` (round 2's replacement for round 1's ill-fated dismiss)
   cannot recover a party that never grew past one member.** Two
   independent full replays against the same S02-exit seed both left
   `party_size == 1` at S03-39, the sole starter fainted, from the catch
   loop's own pre-existing steps (unowned by this lane). With no second
   party member, there is nothing to cycle to. Fixed with the game's own
   designed answer: the `revive` item, used through the real Satchel UI,
   validated safe in both directions (nobody-fainted vs. someone-fainted)
   before being added to the segment.

3. **Round 2's own `creature_recall` dismiss before Bryn's fight
   accidentally faked the whole training rung.** `can_challenge()` refuses
   a null ally exactly like a fainted one, so with the ally dismissed,
   Bryn opened his `defeated` conversation instead of `challenge`, and
   every `combat_quick`/`party_cycle` press downstream landed on nothing —
   while every step's own verdict still read PASS. This round's
   `party_cycle` + `revive` combination keeps the ally alive instead of
   nulling it, so Bryn's fight is real now, confirmed live in both
   replays.

---

## 3. Done and verified, this session

- **The closed-door root cause**, confirmed three ways: `is_open() ==
  false` at boot (`tools/gate_f/probe_mira_los_check_v2.gd` /
  ad hoc check), a real physics raycast from outside to inside hitting the
  `Gate` `StaticBody3D` directly, and a live walk (`0 held`, ~51 frames)
  succeeding the instant `force_open(true)` is called and failing (900
  frames, wandering up to 9m off course) when it is not
  (`tools/gate_f/probe_mira_walk_trace.gd`).
- **The door-opening fix in `S03.json`** (`S03-52`..`S03-52c`), live-
  confirmed in two full segment replays: the door opens
  (`events.jsonl`: `pressed interact on "Open Door" ... expect_change:false`),
  the walk to Mira converges cleanly, and her real greeting fires
  (progression continues into the tool-equip/gathering sequence
  afterward — see the note below on how far each replay got).
- **The revive-item fallback** (`S03-39d`..`S03-39k`, `S03-51e`..`S03-51k`),
  live-confirmed both in isolation (`tools/gate_f/probe_revive_menu_flow.gd`,
  both branches: nobody-fainted safely no-ops and closes clean; someone-
  fainted actually revives and closes clean) and in both full replays
  (`events.jsonl`: `"craft" | gained [] lost [revive -1] in menu_backpack"`
  fires exactly twice per run, once before Bryn and once before Mira, both
  times because the starter had genuinely just fainted).
- **Bryn's fight is real again**: both replays show `combat_quick` presses
  landing on a live opponent, a mid-fight `party_cycle` pilot swap, and
  normal XP/level-up progression, none of which happened under round 2's
  own fix (see §2.3).

## 4. Still open — THIS is what stands between here and a healthy exit save

**#1, the actual blocker (see §1): `S03-60`'s walk from Mira's shop back
out to Oskar (22,-6) gets stuck 4.5m short after its full 3000-frame
budget, `0 held`, without ever leaving the vicinity of her building.**
While stuck, `S03-60`'s own `answer_prompts: true` presses `interact`
every 20 held frames — which, this time, lands on MIRA AGAIN (still in
range, still offering something) and advances her now-available
Band-1 challenge conversation (`mira_shop_open` is true, `defeated_mira`
is false), ending in a real, unplanned fight
(`village_mira_challenge`/`battle:trainer_mira`). The party — already
down to its one Revive-less starter after two earlier, legitimate uses —
takes a hit and faints for good. Everything after that (beds never built,
sleep never reached) is a consequence of this, not a separate cause.

This is the reason `S03-60` was never live-tested from this starting
position before now: no earlier round's replay ever got the player
through Mira's door at all, so `S03-60` always started from wherever an
earlier failure left the walker, never from genuinely inside her shop. My
own fix is what exposed it.

A **candidate fix, sketched but not run or verified**, is the last two
blocks of `tools/gate_f/probe_mira_walk_trace.gd`: route `S03-60`'s walk
through the same door-approach staging point `S03-52` already uses on the
way in (`local(1.0, 5.0)` of cottage_a → world `(14.464, -4.121)`) before
continuing to Oskar, on the theory that the exit leg clips the same
counter/doorway geometry the entry leg did, in reverse. **Run the probe
and read both new blocks' output before trusting this** — this session
ran out of time before executing it. If it converges, mirror `S03-52`'s
own staging-point pattern immediately before `S03-60` in `S03.json`, then
re-run a full replay and read the save's `party` array directly (not
`"complete": true`) to confirm health.

**Everything below this was already open before this session and remains
so, not touched:**

- **The catch loop's own pacing** (`S03-32a`..`S03-38j`, pre-existing,
  unowned by this lane): two independent full replays against the same
  seed and the same scripted input both produced `party_size == 1` with
  the starter fainted by the end of the catch loop alone. That is not
  "unlucky twice" — it reads as the deterministic outcome of driving these
  exact ten catch attempts (one attacker, ten fights, no rest between
  them) against this exact save. Whether that pacing is itself a finding
  is a question for whoever owns that loop; named here, not touched. It is
  also WHY the Satchel's 2 Revives are both already spent by the time
  `S03-60` triggers a third fight — a party that grew past one member, or
  a catch loop that cost the ally less HP, would have left slack here.
- **`scripts/combat/encounter_director.gd`'s blanket fainted-ally
  override** (round 2's own GAME finding): still real, still not owned by
  this lane (`scripts/combat/**` is T3-TYPECHART's), still not fixed here.
  This round's fix works AROUND it (keep the ally alive rather than
  dismissing it) rather than fixing the override itself.
- **A second, separate `move_to` FAIL later in the gathering loop**
  (`did not reach (36, -16)` — a different location, not Oskar's), seen in
  an earlier attempt this session, not diagnosed. Possibly the same class
  of "closed door/tight geometry" bug recurring elsewhere; possibly
  unrelated. Not investigated.

## 5. File footprint

**Touched, this session:**
- `tools/gate_f/segments/S03.json` — three changes: (1) `S03-39b`/`S03-51c`
  replace the round-2 dismiss with `party_cycle`; (2) `S03-39d`..`S03-39k`
  and `S03-51e`..`S03-51k` add the revive-item fallback before Bryn and
  before Mira; (3) `S03-52`..`S03-52c` replace the direct `move_to_entity`
  Mira walk with a fixed staging point, an explicit door-open press, a
  settle, then the walk in. `S03-51b`'s note text is rewritten to describe
  the real (door) cause rather than round 2's positioning theory.
- `tools/gate_f/probe_mira_los_check_v2.gd` (+ `.uid`) — new. Calls Mira's
  real live `Interactable` node's own `_has_line_of_sight()`/
  `interaction_offer()` directly (no raycast reimplementation) across a
  ring sweep around her; useful for mapping visibility but NOT sufficient
  on its own to find the closed-door cause (see the finding doc's own
  caution about this).
- `tools/gate_f/probe_mira_walk_trace.gd` (+ `.uid`) — new. Single-boot,
  multi-candidate live walk tracer using the real `stick_navigator.gd`;
  this is what actually found and proved the closed-door cause. Its last
  two blocks (reproducing and candidate-fixing `S03-60`'s own exit-leg
  failure, §4) were added at the very end of this session and are
  UNVERIFIED — the file parses cleanly but has not been executed to
  completion or read. Run it before trusting either block's claims.
- `tools/gate_f/probe_revive_menu_flow.gd` (+ `.uid`) — new. Validates the
  Satchel Revive-item UI flow in both branches before it was trusted in a
  real segment.
- `ralph/reports/FINDING-T2-BUILDPLACE-2026-08-30.md` — extended with a
  "Round 3" section covering both fixes and the Bryn-fight correction.
- `ralph/reports/handover-T2-BUILDPLACE-ROUND2-2026-08-30.md` — this file.
- `ralph/reports/gate-f-buildplace-round3-validation/` — kept as evidence:
  the S02-exit seed and this session's replay attempts (superseded ones
  renamed in place per the restart-protection rule, not overwritten).

**Not touched:** `scripts/combat/encounter_director.gd`,
`scripts/world/village_door.gd`, `scripts/world/interactable.gd`,
`scripts/ui/tab_backpack.gd`, `scripts/creatures/creature_instance.gd` —
all read extensively to understand the real mechanisms this fix drives
through, none edited. `tools/gate_f/operator_harness.gd` — read only, to
understand `move_to`/`move_to_entity`/`interact_with`/`open_menu`/
`focus_move`/the `teleport` DIAG action and how `RUN_METADATA.json`
resolves for the capture pre-flight; not edited.

## 6. Exact commands

**To re-run the three new probes** (fast, ~1-2 minutes each, no S02-exit
seed needed):
```
godot --headless --path . --script tools/gate_f/probe_mira_los_check_v2.gd
godot --headless --path . --script tools/gate_f/probe_mira_walk_trace.gd
godot --headless --path . --script tools/gate_f/probe_revive_menu_flow.gd
```

**To re-run a full S03 replay** (7-10 minutes; needs a scratch run dir
seeded with a real `S02-exit.json` and a run-level `RUN_METADATA.json`
declaring a plain headless `display_server` placed in the run dir's
PARENT, i.e. one level above the segment's own `--gatef-out` — this is
easy to get wrong; `_freeze_display_claim()` in `operator_harness.gd`
reads `_out_dir.get_base_dir().path_join("RUN_METADATA.json")`, not
`_out_dir` itself):
```
mkdir -p ralph/reports/<scratch>/S02/saves
cp <a real S02-exit.json> ralph/reports/<scratch>/S02/saves/S02-exit.json
# write ralph/reports/<scratch>/RUN_METADATA.json (see this session's
# gate-f-buildplace-round3-validation/RUN_METADATA.json for the exact shape)
godot --headless --path . --script tools/gate_f/operator_harness.gd -- \
  --gatef-segment=tools/gate_f/segments/S03.json \
  --gatef-out=ralph/reports/<scratch>/S03
```
Budget 7-10 minutes of wall time per attempt — this round's own replays
ran long enough that a fixed timeout under 10 minutes cut one off before
it finished (it was still making real progress, not stuck; re-run in the
background or with a longer timeout rather than assuming a hang).

## 7. Disagreements / things worth owner attention

1. **I disagree with round 2's own framing of the Mira problem as
   positional/RNG-driven.** It was a closed door from the start; the RNG
   variance round 1 and 2 both chased was real (the catch loop's outcome
   does change where the player stands) but it was never the actual cause
   of the failure — it just changed WHICH way the closed-door symptom
   presented (stuck-short vs. arrived-but-refused). Worth remembering
   generally: a diagnostic that finds a `true` correlation (RNG variance
   correlates with failure severity) is not the same as finding the
   mechanism, and this cost two rounds before someone tried opening the
   door.
2. **The catch loop producing `party_size == 1` in both of this round's
   own replays, against the same seed, is worth someone's attention beyond
   this lane.** I did not touch it (out of ownership and out of scope for
   "fix the Mira approach"), but if the intended chapter experience is "a
   real player usually ends the catch loop with 2-3 creatures," and this
   segment's own scripted replay of it reliably produces 1, that is either
   a sign the catch loop's own difficulty/pacing needs a look, or a sign
   the script itself (not the game) is unrepresentative of how a real
   player would actually play those ten encounters (e.g., a real player
   would likely not spend all ten attacks on the SAME already-weakened
   ally without ever switching or resting). I flagged this rather than
   silently working around it with the revive fallback and calling it
   solved — the revive fallback is a genuine, intended mechanic, but its
   necessity here twice in a row is itself information.
3. **I am NOT claiming this session converged, and I want that
   unambiguous given the coordinator's own note that this lane gates the
   other three.** The door and revive fixes are real, done, and proven —
   but the actual deliverable ("a healthy `S03-exit.json`, HP pasted from
   the real save") was not reached, because a fourth cause was found one
   step further downstream than this session had time to also fix and
   re-verify with the same rigour. I chose to stop and document rather
   than push a guessed-at `S03-60` fix into the segment and claim success
   on an unread replay — the same mistake the task's own brief was written
   to prevent (a probe/fix that "passed" without being checked against a
   real save once already cost a full round here).
