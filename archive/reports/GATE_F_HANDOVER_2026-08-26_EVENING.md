# Gate F — handover, 2026-08-26 evening

**For a successor with no memory of this session.** Read this before touching
anything. It supersedes nothing in `GATE_F_RUN_HANDOVER_2026-08-26.md`; it is the
next shift's notes on top of it, and that file is still the authority on the
2026-08-25 run itself.

This session ran the **defect-fix lane**, then briefly the operator role, and is
standing down on a cost rotation — not a correction.

---

## 1. What shipped, and where it is

Everything below is **on `main`** at `0d83213e` or earlier. No branch of mine is
outstanding; the sweep auto-deleted them, so do not go looking for
`ralph/GATE-F-DEFECT-FIX`, `ralph/GATE-F-RUN-20260826` or `ralph/CATCH3-ENGAGE`.

| what | where |
|---|---|
| Entombment failsafe | `scripts/player/player_controller.gd::_recover_if_entombed`, tuned from `data/config/movement.json`'s `unstick` block |
| Its discriminating test | `tests/smoke_unstick.gd`, wired into `verify-core-verb-shard` |
| X07's six distinct camera variants + 19 real `pin_clock` steps | `tools/gate_f/segments/X07.json` |
| Engage-failure diagnostics | `tests/smoke_party_count_after_catches.gd::_why_the_engage_failed` |
| Measurement tools | `tools/_probe_night_crimson.gd`, `tools/_probe_night_carrier.gd`, `tools/_probe_engage_walk.gd`, `tools/_probe_stand_aside.gd`, `tools/_capture_gate_f_defect_sites.gd` |
| Full session narrative, including every dead end | `ralph/reports/gate-f-lane-log.md`, check-ins 1–9 |

---

## 2. THE OPEN DEFECT — the catch-3 engage failure

**This is the most important thing in this document.** It randomly reddens
branches across the whole repo, and it is still open.

### The symptom

`tests/smoke_party_count_after_catches.gd` fails intermittently on CI:

> could not engage the real wild body at `Wild_bramblebun_0_3` (stopped 23.7m away (engage range 6.0m))

That fails catch 3 and cascades into every downstream assertion.

### Four hypotheses, all killed, with the measurement that killed each

**Do not re-run these.** Each cost a world boot.

1. **A chase that could not converge.** Dead. `data/config/combat.json` puts
   `wild.wander_speed` at **1.4 m/s** against the player's **5.0** walk, and
   `wild.wander_radius` at **7.0 m**, so the target can neither outrun the player
   nor leave its anchor. The walk holds forward for 1500 frames — 25 s, about
   125 m of travel. It is not a chase problem.

2. **The entombment class this session fixed.** Dead. `grep -c entombed` over a
   full local pass of the test is **0**: the failsafe never fires. Its
   eight-direction probe correctly finds open ground behind a body that is
   merely pressed against something, which is the guard that stops it firing in
   ordinary play. **§6.2 therefore has at least two failure modes** — the sealed
   pocket (fixed) and this one (open). Do not merge them under one heading.

3. **The route to `0_3` is blocked.** Dead, and this is the finding that matters
   most. `tools/_probe_engage_walk.gd` walks to every practice-cluster member
   from the test's own start point, each approach independent:

   | target | distance | result |
   |---|---|---|
   | `Wild_bramblebun_0_1` | 11.9 m | ARRIVED, frame 102 |
   | `Wild_bramblebun_0_2` | 30.2 m | ARRIVED, frame 299 |
   | `Wild_bramblebun_0_3` | 23.2 m | ARRIVED, frame 228 |

   All three reachable, none on a wall. CI reports stopping **23.7 m** away from
   a target that sits **23.2 m** from the start — the body covered essentially
   nothing. **So the route is fine and the START is not.** The catch-3 walk
   begins wherever catch 2's fight left the body, not at the start point.

4. **`_stand_the_trainer_aside` parks the trainer in something solid.** Dead, and
   this one surprised me. `combat_manager.gd::_stand_the_trainer_aside` teleports
   the player to `centre + side * (radius * 0.55) - forward * 1.2` with a raw
   position write; only the *height* is validated, nothing checks whether
   anything is standing there. That looked conclusive. `tools/_probe_stand_aside.gd`
   engages three real fights and reports **8/8 directions clear every time**, and
   in two of the three the trainer was not moved at all (0.0 m). Not the
   mechanism — though the unchecked write is still a latent hazard worth fixing
   on its own merits, just not this bug.

### What replaces guessing: the failure now diagnoses itself

I could not reproduce it locally in four attempts, so I made the next CI red
carry its own diagnosis. `_why_the_engage_failed` now also prints:

- **how far the body actually walked**, in how many frames, and from where;
- **`THE BODY DID NOT MOVE -- blocked at the start, not short of the target`**
  when the walk covered under 1 m in 120+ frames;
- **`N/8 directions clear now`**, plus `on_wall` / `on_floor`, using the same
  physics-sweep predicate as `_entombed_at`.

**How to read it, because the two cases want opposite fixes:**

- *"THE BODY DID NOT MOVE" + a low clear count* → the body was **blocked at the
  start**. Fix where catch 2 leaves it, or make the placement collision-checked.
  Look hard at `_stand_the_trainer_aside` and at the arena teardown.
- *A large "walked Nm" and 8/8 clear* → the body **travelled and ended up
  somewhere unhelpful**. That is a targeting or arbiter problem, not a movement
  one, and the existing arbiter-winner line in the same message is the thread to
  pull.

### The fix that is deliberately NOT applied

`tests/helpers/stick_navigator.gd` is the repo's one walker that detours around
geometry, and the Gate F harness's own `move_to` routes through it. Both failing
tests use a raw straight-line walk instead. **Routing them through the navigator
would almost certainly turn both green — and would hide this defect.** It is
withheld on purpose. If a successor decides the CI noise is worth more than the
finding, that is a legitimate call, but make it knowingly and say so in the
commit.

---

## 3. Candidate freeze state — the current one is VOID

`ralph/reports/gate-f-candidate/RUN_METADATA.json` records a freeze at
**`14e88c7c`, dated 2026-08-26**. **It is void.** It exists only because
`ralph/reports/gate-f-run-20260826T110000Z/ABORTED.md` beside it explains why
that run stopped.

**A successor re-freezes from the new `main`**, which now carries the grass
consolidation, the Sigil Gate fix, the stuck-check fix and the CI work — none of
which `14e88c7c` had. Overwrite that file when you do.

---

## 4. What the aborted `20260826T110000Z` run is worth

| segment | state | worth |
|---|---|---|
| `S01/` | complete, **13 PASS / 1 FAIL** | evidence against a **superseded candidate** |
| `S02-aborted-1/` | killed mid-flight | **nothing** — truncated `route.csv`, no exit save, no verdicts |

The single S01 failure is `S01-12`, the objective-id naming mismatch the previous
handover's §3 already triaged as a protocol expectation, not a game defect. The
counts match the 2026-08-25 run exactly.

**§1.6 splice rule: none of it may be spliced into the new run.** All of it
belongs to `14e88c7c`, which will not be the candidate. S01 must be re-run. The
directory is kept, not deleted, because a deleted attempt is invisible — the same
reason the previous run kept its seven S02 attempts.

Also worth recording, because it is a positive result about the new failsafe:
**the entombment recovery fired zero times across S01's 354 route rows.** That
was its first exposure to the real corridor rather than a purpose-built test box,
and silence is the correct behaviour on ground with a way out.

---

## 5. The colour artefact — a warning that must travel with any X07 batch

**Spot-check colour on a LATE X07 frame against an EARLY one before trusting the
batch.**

On this container, in four separate probes, **every frame after the first in a
single process came back hue-rotated** — R/B around 2.9–3.9 against a correct
0.42–0.54 — **deterministically**, with shots 2–7 identical to the digit across
two runs of the same probe.

Five explanations were eliminated: the colour grade (an A/B gave the opposite
direction), the `adjustment_enabled` boolean snap at hour 21.0, a live clock
outrunning the renderer (frozen 2.90 against live **2.91**), the config / blend /
weather values (resolved offline — nothing warm exists anywhere in the merge),
and read-back synchronisation (`await RenderingServer.frame_post_draw` changed
nothing). **The cause is unidentified.**

Two corrections a successor must not inherit wrong:
- **Night renders correctly.** Three independent fresh-process first frames at
  pinned hour 22 read 0.42–0.44. There is no player-facing night defect. An
  earlier check-in of mine claimed there was; it is withdrawn in check-in 6.
- **`pin_clock` does NOT make X07 immune.** The artefact is
  position-in-process, not clock-driven. X07 takes 80 frames in one process. Its
  own 79 frames from 2026-08-25 looked normal, so its capture path may not hit
  this — but that is **untested**, and X07 is the run's only real visual evidence.

Also on the record: `X07.json`'s own note blames the "2026-08-23 crimson
artefact" on an unpinned clock. **That attribution is wrong.**

---

## 6. Standing rules a successor inherits

- **`tools/gate_f/**` and `scripts/debug/gate_f_probe.gd` are FROZEN.** A single
  genuinely blocking error may be fixed, recorded in `gate-f-lane-log.md` *and*
  in the step's own `observation`. Both of this session's `X07.json` changes are
  recorded that way. "I could make the harness better" is not a reason.
- **The operator never diagnoses or fixes during a run (§13).** Record the
  defect, continue if possible, report inability to continue as a BLOCKER.
  Leaving the operator role happens *outside* the run, on a separate branch.
- **Never fabricate an [OWNER-ONLY] number**: device frame rate, GPU, VRAM,
  thermals, controller feel, audio, Windows-export identity. None can be
  measured in a Linux container. Nothing in this session's evidence claims any.
- **Commit per segment and push.** A container reclaim must cost one segment,
  never the run. This session was reclaimed once; it cost nothing because of it.
- **Do not read `ralph/reports/gate-f-historical-snapshot.md` during the run**
  (§16.1 blind-first; the capture-rate metric depends on it).
- **`DIAG-` segments are the only place teleports are legal**, and no pacing,
  navigation, difficulty or economy claim may be sourced from one.
- **Merge, never rebase.** This repo's scatter bakes are binary and conflict on
  rebase. Never let the sweep rebase a branch carrying a scatter re-bake.
- **Prove a fix before shipping it.** A test that passes with and without the
  change has proved nothing. This session shipped one fix that had to be
  reverted and one severity claim that had to be withdrawn, both because the
  confirming render was still running when the claim went out. Wait for it.

---

## 7. Budget model and value ordering — reuse, do not rebuild

Cost is **per-turn context, not wall clock** — a segment running in the
background costs nothing while it runs. Held to launch / poll-rarely /
bounded-summary / commit / one log line, a segment cycle is **4–6 tool calls,
about $3–6**.

Wall clock from the step-scripts (`wait` seconds + `stick` frames/60 + `move_to`
at ~20 s against its 2400-frame ceiling), excluding boot:
**S01–S10 ≈ 71 min scripted + ~10 boots at ~90 s**; **X01–X07 ≈ 190 min** minus
X05's ~79 min if dropped.

**The expensive mistake is polling.** Launch with `run_in_background`, arm a
waiter on the exit marker, do other work in between. Never re-read large
telemetry: `grep -c 'verdict: PASS' notes/<segment>.md` is the whole summary.

**Value ordering:** S01–S04 unconditional, then S05–S10, then **X07, X01, X04,
X03, X02, X06, X05**. X07 is the best evidence-per-dollar. **X08 is DROPPED by
owner decision.**

Measured cost of *this* session's mistakes, so a successor can price the same
trap: the night investigation took **five world boots at ~16 min each** and
killed five hypotheses to arrive at "the tooling lies about colour after frame
1." Worth knowing before starting a sixth.

---

## 8. What the successor does next

1. **Merge the new `main` forward** into any working branch (merge, never
   rebase).
2. **Re-freeze a candidate from the new `main`** and overwrite
   `gate-f-candidate/RUN_METADATA.json`.
3. **Run S01–S10, then X01–X07, in one chain.** X08 is dropped.
4. **The visual judge is now permitted** — the ordering constraint that held it
   is satisfied.
5. **The engage defect (§2) is still open.** The diagnostics are in place; the
   next CI red should name which of the two cases it is.

## 9. Two things that were never this lane's, so do not re-investigate

Both were diagnosed and fixed by the coordinator, and I was sent a wrong
diagnosis on the first before it was corrected:

- **The Sigil Gate leak** was a grass-bake regression, not a gate defect.
  `road_gate.gd::_build_wings` sized each wing's collider from the ground under
  its own centre; the +1 side falls ~1 m per wing, leaving 0.84 m of wall at the
  +6.10 m seam. Now sized from the whole footprint.
- **The `(53,-65)` wedge** was `Vegetation/Rock_Medium_1_Collision`. The player
  walked into a rock, and a 1700-frame one-direction hold dead-stops there for
  the rest of the leg. `smoke_traversal` now asks whether the player can walk
  away before calling a stall a wedge.
