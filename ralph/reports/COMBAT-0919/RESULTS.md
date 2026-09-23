# Combat depth — work in progress, 2026-09-19

Owner requested wrap-up and continuation elsewhere. See `HANDOFF.md` for the final
checkpoint state and restart sequence. COMBAT-1 remains unaccepted.

Approval: `bcdb3526`, following plan `c307c652036d42b881d82bd2443b93a6c1105031`.
Implementation base: `8990a743ce6d4126a0c826a0f66ae20ee81f953e`.
Branch: `ralph/combat-depth-0919`; isolated checkout `D:/tetherbound/combat-0919`.

## COMBAT-1: open, not accepted

The audited stagger/wind/burst implementation exists. Verification found an actual
stagger recovery defect: poise stayed at zero, so another quick hit immediately
staggered a recovered fighter. Both sides now reset poise on stagger recovery;
regression tests failed against the old implementation and pass with the fix.

Feedback changes under verification: state-bound enemy telegraph and cyan stagger
rings, plus a short charged-impact camera roll. These still require fresh production
captures and independent visual/motion review. No capture has been taken yet.

The new paired harness drives real input, manager, AI, creature bodies and collision
on a flat fixture. It does not duplicate combat arithmetic. Production-world smokes
remain required. Seeds are installed before encounter startup. Different policies
consume random draws in different orders; this is paired scenario sampling, not
identical damage luck. Reports explicitly remain `accepted: false` and record missing
burst/skill/teaching/visual/owner-feel coverage.

The first controlled 24-seed Mira sample after the recovery fix measured masher HP
cost 23.99%, reader 58.87%; both won 24/24. Telemetry then exposed cooldown closing:
the enemy advanced to contact while waiting to attack despite a much larger authored
preferred distance. Existing IDLE now holds preferred spacing during cooldown.
The spacing regression was red before this change and green afterwards. Its 24-seed
sample measured masher 23.99%, reader 38.52%; both won 24/24. Both the reader ratio
and the older floor minimum remained unmet. No thresholds were relaxed.

Independent pilot review found excessive retreat beyond safe strike range, an
opponent-relative rather than arena-relative boundary tangent, and unnecessarily
stopped approach late in recovery. Corrections are under retest. A single-seed
diagnostic recorded reader 0% HP cost versus masher 23.2%. The subsequent 24-seed
sample measured reader 19.85% versus masher 23.99%, both winning 24/24. This remains
above the required reader ratio (82.75% observed, at most 55% required), and the
masher remains below the older 25% floor minimum. COMBAT-1 is still open.

### Validation and retained evidence

Godot: installed 4.7 stable console binary. Unit command:
`--headless --path . --script tests/run_tests.gd -- --only=<selectors>`.

- Initial combat stagger/wind/burst/math/AI/encounter override: 83 tests,
  250 assertions, zero failures.
- Latest AI/stagger/feedback/depth-target/telegraph selection: 44 tests,
  154 assertions, zero failures (`D:/tetherbound/combat-spacing-green.log`).
- Broader combat/encounter selection: 167 tests, 611 assertions, zero failures
  (`D:/tetherbound/combat-checkpoint-units.log`). The deliberate unknown-species
  negative test emits its expected error; shutdown reports four resources in use.
- Production `tests/smoke_playground.gd`: exit 0 and `smoke: OK`, but **not a clean
  world validation**. `D:/tetherbound/combat-playground.log` contains one null-material
  error from the dummy renderer during the tool/gather checks and shutdown RID/resource
  leaks. This requires investigation; it is not silently waived as a passing boot.
- Recovery regression red: `D:/tetherbound/combat-stagger-red-corrected.log`.
- Spacing regression red: `D:/tetherbound/combat-spacing-red.log`.
- Paired command: `--headless --path . --fixed-fps 60 --script
  tests/smoke_combat_baseline.gd -- --paired --seeds=24 --case=trainer_mira
  --json=<output>`.
- Controlled recovery results: `D:/tetherbound/combat-depth-floor-recovery.json`.
- Controlled spacing results: `D:/tetherbound/combat-depth-spacing-24.json`.
- Pilot correction diagnostic: `D:/tetherbound/combat-depth-reader-spacing.json`.
- Pilot correction 24-seed sample: `D:/tetherbound/combat-depth-reader-spacing-24.json`.

First harness attempts exposed a GDScript type inference error, a Node3D trainer
fixture lacking velocity, and an intermediate missing matrix method during editing.
These were corrected; the runner now fails closed when its helper cannot instantiate.
An early recovery regression fixture lacked its species instance and was corrected
before obtaining the meaningful red/green result. These failed attempts are not
counted as game behavior evidence.

### Follow-up: impulse accumulation reproduced

Checkpoint `94f87e6ba` is pushed in draft PR
<https://github.com/MJohnsonWellabe/Tetherbound/pull/130>; CI is queued/running.
Its production `smoke_combat.gd` completed entry, stick movement, attack miss/hit,
enemy retaliation, type application, victory and return to exploration. Log:
`D:/tetherbound/combat-production-smoke.log`; gameplay assertions passed. Only
shutdown RID/resource errors appeared in this smoke, unlike the playground's
additional runtime null-material error. Neither log is represented as error-free.

A new real-body impulse regression reproduced a single 6 m/s shove accelerating
without input to 24.030 m/s. The old integrator repeatedly added remaining impulse
to velocity already containing its previous contribution. The follow-up routes
impulse through the existing transient-velocity subtraction/collision projection.
Peak speed now decays from 5.100 m/s. Independent review identified an arena edge
variant: a diagonal shove reached 13.830 m/s after soft boundary clamping invalidated
the bookkeeping. Projecting the surviving contribution through the same arena
normal reduces that peak to 3.587 m/s. Red/green logs are
`D:/tetherbound/combat-impulse-{red,green}.log` and
`D:/tetherbound/combat-impulse-edge-{red,green}.log`.

The first impulse-corrected 24-seed Mira sample measured reader 2.59% HP cost versus
masher 23.99%; both won 24/24. The reader ratio passes in this sample, while the old
25% masher floor minimum still fails. The subsequent arena-edge correction needs
its own repeat measurement; do not conflate source versions.

Follow-up validation: production burst displacement/stop passed; production
environment velocity smoke passed wind, walls, lee and cleanup; 50 focused tests /
215 assertions passed including arena and impulse/environment interaction. A further
mixed inward-impulse/outward-locomotion regression now brings that selection to 51
tests / 216 assertions. The impulse smoke also rejects missing impulses and lingering
movement tails. The arena-edge 24-seed Mira repeat preserved the 2.59% / 23.99% result.

The follow-up playground invocation incorrectly included `--fixed-fps 60`, which is
appropriate for the paired physics matrix but not this smoke's wall-clock gather
timing assertion. It failed that assertion (0.383s simulated swing elapsed versus
0.725s wall-clock receipt) and repeated the null-material/shutdown errors. Retained
log: `D:/tetherbound/combat-playground-impulse.log`. Repeat with the documented command
before interpreting this as an impulse regression; do not erase the failed attempt.

First native capture completed 30 frames with all requested events, lock released.
However, inspection of the blind review's HUD-overlap finding exposed a capture
fixture error: `root.add_child(world)` without assigning `current_scene` prevented
the existing HUD combat-priority lookup from finding CombatManager. Therefore
`D:/tetherbound/combat-captures-0919` and `VISUAL-VERDICT-01.md` are retained diagnostic
evidence, **not shipping UI acceptance**. The tool now sets `current_scene` as normal
startup does. Corrected capture is running into `D:/tetherbound/combat-captures-0919-b`
with fresh application data, per-frame ownership checks and finally-path lock
release. Additional trace fields record physics frame, hitstop and both body states.
No visual or motion acceptance has been claimed.

Corrected capture B completed 30 native frames and all requested event observations
on code now committed as `0d3b79703`. Its report SHA-256 is
`BA712BA01B04C70B65C02C9C2A750B7AEED7436A530F24FB855F91D4C992BA40`.
Trace includes real 0.03s and 0.07s hitstop with both bodies' physics disabled;
this does not prove subjective feel or the 0.12s critical case. No player stagger
was photographed. `VISUAL-VERDICT-02.md` identifies consistent genre/world identity
but explicitly rejects any inference of Palworld-equivalent finish: active opponent
visibility, effect clarity and character material coherence remain weak. The lock
was released; the wrapper's timestamp comparison required correcting PowerShell's
automatic JSON timestamp conversion before release of our verified claim.

The documented real-time playground command was repeated on the impulse correction:
`D:/tetherbound/combat-playground-impulse-realtime.log` reports `smoke: OK`. It still
contains the same runtime null-material error and shutdown leaks. Thus the gather
timing failure is not reproduced without fixed-FPS mode, while the engine-error
limitation remains open and explicitly blocks a clean-world claim.

Next bounded presentation corrections are underway: state rings currently shrink
under their own creature footprint and a flat ring intersects uphill terrain.
Both defects reproduced in a geometry regression; body-aware perimeter pulsing and
ground-conforming vertices now pass 7 ring/feedback tests, 35 assertions. These edits
are not yet captured or accepted. Camera review also found a fixed clearance that
ignores body width and a shoulder offset that goes stale after takeover; investigation
is confined to combat framing, preserving room bounds and manual control.

At wrap-up the bounded camera correction is implemented with focused tests: it
uses live rendered lateral extents and refreshes shoulder clearance as the fight
moves, preserving manual-look grace, throw/catch ownership, room limits and the
existing shoulder cap. Final ring/camera/environment/stagger/AI test selection:
46 tests, 144 assertions, zero failures (`D:/tetherbound/combat-wrap-units.log`).
Fresh capture and full camera smokes for these last presentation edits remain
outstanding at the owner's requested stop. Capture B is not evidence for them.

### Wider diagnostic (two seeds, not statistical acceptance)

`D:/tetherbound/combat-depth-all-diagnostic.json` covers 57 cases / 228 real-input
fights across all five bands. It records 38 unmet criteria. Both seeds alone cannot
establish a win/wipe probability; the sample locates defects for the 24-seed matrix.

| Band | Floor masher / reader HP cost | Top masher lead faints | Top masher team wipes | Top reader wins |
|---|---|---|---|---|
| 1 | 22.8% / 0.0% | 0/2 | 0/2 | 2/2 |
| 2 | 75.0% / 13.0% | 0/2 | 0/2 | 2/2 |
| 3 | 33.3% / 17.8% | 2/2 | 0/2 | 2/2 |
| 4 | 75.2% / 6.7% | 0/2 | 0/2 | 2/2 |
| 5 | 63.4% / 2.2% | 2/2 | 0/2 | 2/2 |

The sampled floor reader ratios meet the target, but several ordinary wild species
remain below the 25% masher cost, early/top Band 4 trainers do not reliably faint
the masher's lead, and no sampled top trainer wipes the masher's team. No damage
or acceptance thresholds were changed to force a pass. Final ladder balance remains
unmet; skill/AI/type/teaching work is not represented as already completed.

### Remaining work

Finish paired verification beyond Mira; run production combat and playground smokes;
capture and judge feedback when the render lock is available; review hosted paths;
finish draft COMBAT-1 PR CI. Verify the follow-up impulse changes in the production
world and complete independent capture review. Do not move to COMBAT-2 on
source presence or a single passing diagnostic. The full ladder and owner feel
criteria, including the Valheim/Palworld quality ambition, remain unfinished.

Render priority remains Meadows, Cloudreach, Combat, survey. Read and claim the
machine lock before any capture/import, release only our claim in a finally path.
No source-checkout or other-lane edits were made.
