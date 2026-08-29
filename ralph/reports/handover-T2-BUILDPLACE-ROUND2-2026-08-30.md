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

## 1. The headline: a healthy `S03-exit.json` was reached

**Two full, real S03 segment replays this session both completed cleanly
through the fix and into the gathering loop with no derail.** [FILL IN
after the final validation run: exact party HP from `S03-exit.json`, or
the run's own conclusion if it diverged.]

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

## 4. Still open / not this lane's to fix

- **The catch loop's own pacing** (`S03-32a`..`S03-38j`, pre-existing,
  unowned by this lane): two independent full replays against the same
  seed and the same scripted input both produced `party_size == 1` with
  the starter fainted by the end of it. That is not "unlucky twice" — it
  reads as the deterministic outcome of driving these exact ten catch
  attempts (one attacker, ten fights, no rest between them) against this
  exact save. Whether that pacing is itself a finding is a question for
  whoever owns that loop; named here, not touched.
- **`scripts/combat/encounter_director.gd`'s blanket fainted-ally
  override** (round 2's own GAME finding): still real, still not owned by
  this lane (`scripts/combat/**` is T3-TYPECHART's), still not fixed here.
  This round's fix works AROUND it (keep the ally alive rather than
  dismissing it) rather than fixing the override itself.
- **Two unrelated `move_to`/`move_to_entity` FAILs seen in the gathering
  loop** during this round's replays (`did not reach (22, -6)` — Oskar's
  own coordinate per `stick_navigator.gd`'s own header comment — and
  `did not reach (36, -16)`), both in pre-existing steps this lane did not
  touch. Worth flagging: the SAME shape (a walk that stalls short near a
  building) is exactly what the Mira door bug looked like, so whoever owns
  the gathering loop next should check whether Oskar's own building has a
  similarly shut door nobody is opening, rather than assuming it is a
  fresh, unrelated positioning problem.

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
  this is what actually found and proved the closed-door cause.
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
