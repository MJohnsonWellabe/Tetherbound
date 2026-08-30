# Handover — GATE-F-RUN7, 2026-08-30

**Branch:** `ralph/GATE-F-RUN7`, off `origin/ralph/GATE-F-E5`, with
`origin/ralph/LAND-0830I` merged forward.
**Scope as briefed:** run the Meadows chapter from a fresh save to the end,
record the pacing account, rewrite the findings documents from the run's own
evidence.
**Scope as delivered:** the chain's first two segments, one of them the blocker
six runs died on — then, on the owner's mid-run instruction, stopped and turned
to making the fixes landable rather than extending the run.

---

## 1. The headline

**The chapter's entry save is healthy for the first time in this effort.**

`ralph/reports/gate-f-run7/S02/saves/S02-exit.json`, written by a real fresh
save driven through the real title screen:

| | |
|---|---|
| party | **2** — Ripplet L3, Bramblebun L2 |
| `road_gate_open` | **set** |
| `pickup:castle_gate_key` | set, consumed by the gate |
| opening beats | all 8 |
| S02 verdict | **79 PASS / 3 FAIL**, complete, 0 skipped, 0 refused |
| S01 verdict | **13 PASS / 0 FAIL**, complete — the first clean S01 anywhere in this effort |

Every previous run's downstream evidence was taken against a save that either
carried a one-creature party or a shut village gate, or both. That is why S03
onward has never meant anything. It could now.

**Three defects had to go, and none of them was the one the brief pointed at.**

## 2. Segment table

| segment | steps | PASS | FAIL | DELEG | wall | status |
|---|---:|---:|---:|---:|---:|---|
| **S01** | 14 | **13** | **0** | 1 | 546 s | **COMPLETE, clean** |
| **S02** | 90 | **79** | **3** | 8 | 627 s | **COMPLETE**, healthy exit save |
| S03 | 406 | — | — | — | ~16 min | **STOPPED by me**, mid-run, not a defect — see §6 |
| S04–S10e | — | — | — | — | — | **not run** |

Evidence: `ralph/reports/gate-f-run7/`. The run-local freeze record was written
**before** the run, per the harness's own rule.

## 3. What I fixed, all pre-freeze, all verified

### GAME-11 — the practice fight, pinned to the level the repo already documents

RUN6 measured the starter fainting in **4 of 5** fresh saves and filed this as a
design call it would not make. **I did not treat it as one.**
`progression.json`'s award comment already states the number — the chapter's
enemy levels *"run 2 at the practice fight to 22 in the stronghold gauntlet"* —
and `test_trainers_data.gd` is calibrated against that curve. The data did not
honour tuning the repo had written down. Fixing that is a defect fix; choosing a
different number would have been the design call.

**RUN6's suggested fix would not have worked**, and this matters because it is
the obvious thing to reach for. It named the `level` key `spawn_wild()`'s `opts`
supports — real, but on the *imperative* spawn path. The clustered scatter calls
`_roll_wild_level()` unconditionally and never reads a per-entry `level`, so
authoring one into `spawns.json` would have changed nothing, silently.

What changed: `encounter_director.gd` reads an optional per-entry `level`,
applied **after** the band roll rather than instead of it, and
`band1_lower_meadows/spawns.json` pins cluster order 0 — the Practice Meadow —
at 2. **The ordering is the whole design.** `_roll_wild_level()` takes seven
draws from the cluster's shared `rng` and that generator goes on to scatter and
roll every later member; `_set_fixed_level()` takes none from it, so
substituting it would have silently moved and rerolled every creature after it.
Overriding the finished instance costs no draw and leaves IVs, traits, shiny and
the scatter bit-identical. `_apply_elder()`'s `level_bonus` already worked this
way; `level` is its absolute counterpart.

| | RUN6 (5 saves) | RUN7 |
|---|---|---|
| opponent level / HP | rolled 2–6, recorded **5** / 124.2 | **2** / 93.7 |
| starter after the fight | **FAINTED 4 of 5** | **won, 67.9 / 117.6** |
| catch landed | **1 of 5** | **yes** |

### RIG-28 — the gate and the key, found by `ralph/T5-PLAY`

`T5-OPENING` moved the key and rebuilt the gate from config; `T2-GATEF-RUN6`
fixed S02 against the old coordinates. Each lane correct, jointly broken — the
key anchor **7.5 m** off against a 2.4 m radius, the gate anchor **11.9 m** off
against a 4.0 m radius, both presses landing on open ground, and
`road_gate_open` therefore unset in the save S03→S05 inherit. A closed gate is a
`StaticBody3D` with sealed wings, so the chapter could not be left.

**The finding, the measurements and the probe proving the gate itself works are
all T5-PLAY's.** I took their three changes rather than their commit, because
their branch predates the 27-rung ladder and merging it would have reverted
GATE-F-E5.

**Three things added on top:** `S02C.json` never got the fix (third time a
capture twin has been missed after its journey lane was repaired); `S02-50a` now
asserts the key is actually in the satchel, so a future drift fails at the key
instead of surfacing five steps later looking like a gate defect; and nothing
ties `GATE_KEY_AT` to the rig anchor, so this will recur — left open.

### RIG-29 — the corpse-lookup sweep the brief asked for

**The Gate F harness does not have this bug** — `_find_entity()` resolves by
identity and picks nearest-with-a-note, and exactly one segment step in the set
targets an entity by a name containing "creature" (`S03-205a`, a creature bed).
That is the clean negative the brief wanted.

The sweep found the same bug in **six** smoke tests, not one, and
`combat_manager.gd::enemy_body()` — the accessor that fixes it — already
documents the bug in its own header and was applied to exactly one call site.
**`tests/smoke_relay.gd` is on that list, and it is the ~1-in-5 flake
`START_HERE.md` carries as an open ticket with root cause unknown.** A
hypothesis with a mechanism, not a diagnosis; I did not reproduce it. Left for
`ralph/T3-COMBAT`, which owns the finale fix; checked, it has not fixed them.

## 4. Where I disagree with `ralph/T5-PLAY`, and where I do not

**Read their `T5-PLAY-DEFECTS.md`. It is the best account in the repo of why
the chain was blocked, and it beat me to the two defects that mattered most.**

**Agreement, reached independently:** their RIG-T5-2 says S01's first-objective
assert is stale because the opening ladder grew and *"the game is better than
the script expects"*. GATE-F-E5 fixed exactly that from the other side, and this
run is the proof — S01 went 13 PASS / 1 FAIL (run 3) to **13 PASS / 0 FAIL**,
and the one failure that closed is that assert.

**Where I disagree — one, and it is about scope, not fact.** Their
**COST-T5-5** reports the village at 0.2027 s/frame against 0.0479 at run 5 and
calls it *"BLOCKER for the run, open question — game or instrument"*. Their
measurement I do not dispute. But their run and mine are **not on the same
tree**: they ran `LAND-0830I`, I ran `GATE-F-E5 + LAND-0830I`, and the
difference is the E5 protocol work plus my three fixes, none of which touch
world content. So our village numbers should be comparable and I **cannot
confirm theirs** — I stopped S03 before it re-priced, deliberately, and have no
number of my own. **Treat COST-T5-5 as one lane's unreplicated measurement
until someone runs S03 to its cost gate again.** I am not disputing it; I am
saying it currently rests on one sample and I did not add a second.

**Where they are more right than their own report claims.** They mark
**GAME-T5-6** (the starter faints early, recovery costs one of two Revives) as
*"observed, not root-caused"* and *"do not close, do not escalate"*. Their
caution was correct on their evidence and the root cause is now known: it is
GAME-11, and it is fixed. Their pacing concern — two Revives, no resupply named
before the tournament, against a failure mode that reproduced — survives the fix
and is still a real tuning question, but it is no longer being asked against a
fight the player usually loses.

## 5. Landability — what a LAND branch is taking

**Game code and data changed** (everything else is rig, docs and evidence):

| file | change |
|---|---|
| `scripts/combat/encounter_director.gd` | optional per-entry `level` on a spawns cluster, applied after the band roll |
| `data/config/bands/band1_lower_meadows/spawns.json` | `"level": 2` on cluster order 0 only |

Both are additive and inert unless a cluster authors `level`. Exactly one
cluster does. Every other cluster's scatter, level, IVs, traits and shiny draw
are bit-identical by construction — that is what "after the roll, not instead of
it" buys, and it is the reason to prefer this over the obvious fix.

**Rig changes** (`tools/gate_f/`, no gameplay path): the S02/S02C anchors and
the `S02-50a` assert; `run_chain.sh` and `probe_road_gate.gd` taken unmodified
from T5-PLAY; the run-local freeze record.

**Test status: see §7.** The full unit suite was started and this handover was
written while it ran; **whoever lands this must read the result before treating
it as green.** I am not asserting a pass I did not see.

**CI is unverified by me** — this session has no GitHub API access, same as
RUN6. The branch is pushed; check it at the job level, not the run level.

## 6. What I did not do, plainly

- **The chapter was not played to the end.** I got through S02. That is two
  segments of fourteen.
- **S03 did not complete.** It ran ~16 minutes and I **stopped it** on the
  owner's instruction to prioritise landing the fixes. It was not blocked and it
  did not fail — there is no S03 verdict and I have deleted its partial
  directory rather than leave evidence that could be read as a result.
- **No pacing account, no dead-travel intervals, no encounter cadence, no
  wall-clock estimate for a first clear.** Those need the chain, and two
  segments cannot carry them. **I am not estimating a first-clear time from
  S01+S02.** The brief asked for that number and the honest answer is that this
  run did not earn one.
- **The findings documents were updated, not regenerated from `INVENTORY.json`
  as briefed.** A regeneration needs a run; I have two segments. I updated
  GAME-11 from this run's evidence, added RIG-28/29/30, and **deleted nothing I
  had not disproved.**
- **GAME-11's fix is one sample against RUN6's five.** The pin removes the roll,
  so the variance is gone by construction — but "the starter reliably wins" is a
  claim wanting repeats nobody has taken.
- **GAME-12 is untouched** and still open.

## 7. Full unit suite result

_Filled in below when the run finished. If this section still reads as a
placeholder, the suite did not finish in this session and the branch is
UNVERIFIED._

## 8. What I would do next, in order

1. **Read §7, then land this.** The three fixes unblock every future run, and
   every run that starts without them repeats six runs of history.
2. **Re-run S02 three or four times.** Cheap (~10 min each) and it converts
   GAME-11's one sample into a reliability claim. It is the one piece of
   evidence this branch is short of.
3. **Re-derive S02-59 and S02-60's floors** (RIG-30) from the segment as it now
   behaves, and record which run each number came from.
4. **Then chain S03 → S06 before touching X04.** RUN5's ordering finding stands
   and is still unchallenged: X04 re-seeds from `S06-exit.json` partway through,
   so it is chain-gated, not entry-save-gated.
5. **Settle COST-T5-5 with a second measurement** (§4). It is the thing that
   will stop the next run at the village, and it currently rests on one sample.
6. **Six one-line fixes for RIG-29**, and check whether `smoke_relay`'s flake
   goes with them.
