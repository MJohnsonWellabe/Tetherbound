# Combat depth — work in progress, 2026-09-19

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

### Remaining work

Finish paired verification beyond Mira; run production combat and playground smokes;
capture and judge feedback when the render lock is available; review hosted paths;
publish a draft COMBAT-1 PR with CI. A body impulse accumulation concern is identified
but remains unmodified pending isolated reproduction. Do not move to COMBAT-2 on
source presence or a single passing diagnostic. The full ladder and owner feel
criteria, including the Valheim/Palworld quality ambition, remain unfinished.

Render priority remains Meadows, Cloudreach, Combat, survey. Read and claim the
machine lock before any capture/import, release only our claim in a finally path.
No source-checkout or other-lane edits were made.
