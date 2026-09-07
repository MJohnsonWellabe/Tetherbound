# CI-BOSS — Fix intermittent `verify-boss` timeout without hiding it

## Goal
Root-cause the intermittent CI failure where boss verification never resolves within the existing 9000-frame budget. **Do not fix this by simply raising the frame limit.** A timing-dependent boss test is telling us either the harness cannot deterministically start/drive the encounter or production behavior depends on machine load.

## Known symptom
`verify-boss` sometimes reports effectively: **boss fight never resolved inside 9000 frames**. It is intermittent/container-load-sensitive rather than a stable deterministic failure.

Likely areas to investigate include engagement/start position, AI/attack timing, movement distance, encounter start state, path/collision, and test assumptions about frame time. These are hypotheses, not conclusions.

## Required diagnosis
Instrument one failing/slow run enough to answer:
- Did the encounter actually enter ACTIVE combat?
- Were ally and boss bodies spawned on valid ground and in engagement/attack range?
- Did both have valid teams/HP/moves?
- Were attacks being issued and damaging targets?
- Was one actor moving but never reaching effective range?
- Did a state transition, dialogue, camera, or input gate prevent progress?
- Is the test counting frames while physics/gameplay is intentionally paused?
- Does behavior change with fixed physics ticks vs wall-clock/container load?

Log state transitions and meaningful counters, not every frame.

## Deterministic harness preference
A verification test should control setup tightly enough that ordinary CPU load cannot decide whether combat begins. Prefer:
- explicit known start positions derived from the arena/encounter API;
- waiting on semantic readiness signals/states rather than arbitrary settle sleeps;
- fixed/configured test teams and moves;
- deterministic RNG seeds;
- assertions that combat begins before waiting for resolution;
- a separate assertion for progress (HP changes/state advances) so a stuck fight fails quickly with useful diagnosis.

If the actual production boss encounter can also deadlock under certain positions/timing, fix production root cause and keep the deterministic regression.

## Do not
- do not increase 9000 to 18000 and declare success;
- do not skip boss verification on loaded CI;
- do not make test-only production bypasses that avoid the real encounter/combat manager;
- do not assert merely that a timer expired without identifying the stalled state.

## Acceptance criteria
1. The intermittent failure is reproduced or instrumentation captures the stalled state.
2. Root cause is identified as harness nondeterminism or a real production dependency.
3. Boss verification deterministically enters combat and demonstrates progress before waiting for victory/defeat.
4. Repeated local/headless runs and CI runs resolve consistently under varying machine load.
5. Frame/time budget is unchanged unless a separately measured legitimate combat-duration reason justifies a tunable adjustment after root cause is fixed.
6. Failure messages state where the encounter stalled.

## Stress verification
Run the boss verification repeatedly (enough iterations to cover the former intermittent rate) and, if practical, under artificial CPU contention. The same deterministic result should hold. Also run normal boss/stronghold combat smokes to ensure the test fix did not bypass production behavior.

## Definition of done
`verify-boss` is reliable because the encounter itself is driven and observed deterministically—not because CI was given more time to hope the fight eventually starts.