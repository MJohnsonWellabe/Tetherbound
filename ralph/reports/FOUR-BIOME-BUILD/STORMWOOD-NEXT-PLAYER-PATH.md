# Stormwood next player-path evidence map

Date: 2026-09-09
Evidence basis: current `codex/four-biome-audit-resume-0908` tree; no new runtime

## Result

There are two different continuity boundaries, and neither may stand in for the
other.

The genuine title-start campaign has **not reached Stormwood**. Its latest run earned
the first live Bramblebun catch and a two-creature party at
`.artifacts/wave8-memory-watched-fresh.log:121-122`, then the operator stopped it after
the already-recorded aim commit race. Therefore the earliest Stormwood step missing
from a fresh campaign is the Cloudreach-to-Stormwood arrival itself. This is missing
evidence, not a Stormwood arrival failure. The current composition would record that
arrival at `tests/smoke_four_biome_continuous.gd:199-202`, but no genuine run has
executed that far.

The existing Stormwood continuous smoke has a disclosed completed-Cloudreach,
five-level-44-party and tool fixture at `tests/smoke_stormwood_continuous.gd:3-11`.
It sets no Stormwood facts or post-entry materials. Within that boundary, ordinary
movement, prompts, combat, weather and harvests have earned a continuous Stormwood
prefix through `stormwood:arch_recipe_known`. The earliest still-unproved next step is
the durable named **Capacitor Alpha clear** in the same live route. Paid Crown gathering,
crafting and placement come after that and are also unproved.

## Short ordered path

| Order | Player path | Best evidence | Status |
|---:|---|---|---|
| 1 | Earn Cloudreach completion and enter Stormwood | Four-biome composition calls the earned Stormward handoff before marking `stormwood_arrived` (`tests/smoke_four_biome_continuous.gd:192-202`). | **Missing in genuine title-start play.** |
| 2 | Ashfoot arrival; Hesk/Tamsin; sheltered Break; pair A; Maren/Verge; Dace/Hollows; Pools pair B; Rodline; Varga; route 09; Ondra | The uninterrupted chapter-boundary run records route 09 and the recipe at `%TEMP%/wave1-stormwood-fenn-crown-console.log:263-264`. `STORMWOOD-WAVE1-20260908.md` documents the fixture and unchanged owner-save fingerprints. | **Earned inside the disclosed Stormwood seam only.** Ondra's recipe is the last genuinely earned Stormwood step. |
| 3 | Follow Conductor Road and defeat named Capacitor Alpha | The current helper walks the road point and requires `_clear_capacitor_alpha()` before any Crown harvest (`tests/helpers/stormwood_crown_build_segment.gd:91-105`). | **First failing/unproved continuation.** |
| 4 | Gather six Crown Stormglass, eight Thunderwood and six vine; craft two frames; place one paid Crown arch | The helper orders six real harvests, two controller crafts and paid placement (`tests/helpers/stormwood_crown_build_segment.gd:103-137`). | **Missing after the Alpha boundary.** No earned run reached these actions. |
| 5 | Cross the paid arch; guardian, Wen and Rootgate; Dynamo; Marrow; Waterward | The four-biome composition orders Crown, Rootgate, Dynamo, Marrow and Waterward at `tests/smoke_four_biome_continuous.gd:203-215`; focused contracts and prepared helpers exist. | **Prepared/static or isolated evidence only; no earned continuous runtime.** |

## Exact first failure and what is known

The latest same-live prefix attempt first proves Ondra's recipe, then fails here:

- `%TEMP%/wave1-stormwood-alpha-engage-console.log:263-264`: route-09 reward and
  Stormglass Arch recipe earned.
- The first three Alpha approaches select a nearer ordinary Tanglevolt
  (`:265-270`).
- On approach four the exact `Named_capacitor_alpha` is the candidate, the
  `EncounterDirector` wins with actionable `Engage Voltarach`, but physical Interact
  leaves `fighting=false` (`:271-273`).
- The terminal failure is at `:274` and the paid-Crown endpoint consequently fails at
  `:280`.

That log establishes the failed behavior but not its final cause. Later bounded work
changed the helper's input and fight clock discipline. A synthetic actual-Stormwood
scene then cleared the named Alpha with ordinary combat and published its durable flag
at `%TEMP%/wave2-alpha-normal-fight-console.log:91-107`. Because that probe supplies a
synthetic party, entitlement and starting position, it proves the current callback and
combat path can work; it does **not** prove Alpha clearance after the earned Ondra
prefix. The current remaining classification is therefore **missing earned verification
after a historical harness/input-timing failure**, not a presently reproduced
production softlock.

## Next bounded real-behavior proof

Run the existing chapter-boundary smoke once with `--through-crown`:

```text
godot --headless --path . --log-file <unique-engine-log> --script tests/smoke_stormwood_continuous.gd -- --through-crown
```

This is independent of the blocked title-start aim path and adds no new prerequisite
injection beyond the smoke's already-disclosed Cloudreach seam. Stop at its first new
failure. A useful pass must re-earn the complete post-entry prefix and Ondra recipe,
clear the exact named Alpha with its durable receipt, gather the real Crown materials,
craft both frames, and publish the paid Crown arch record. The wrapper composes the
Crown helper only after the prefix succeeds (`tests/smoke_stormwood_continuous.gd:141-157`).
It should end there: Rootgate and later helpers remain separate unproved work, and this
seam run still cannot be credited as a fresh opening-to-Stormwood campaign.

## Sources checked

- `docs/CURRENT_STATE.md` and `docs/DEVELOPMENT_ROADMAP.md`
- `docs/HANDOFF_FOUR_BIOME_2026-09-08_SESSION_WRAP.md`
- `ralph/reports/FOUR-BIOME-BUILD/AIM-COMMIT-RACE-HANDOFF.md`
- `ralph/reports/FOUR-BIOME-BUILD/STORMWOOD-CONTINUOUS-PREFIX.md`
- `ralph/reports/FOUR-BIOME-BUILD/STORMWOOD-CROWN-NEXT.md`
- `ralph/reports/FOUR-BIOME-BUILD/STORMWOOD-WAVE1-20260908.md`
- `ralph/reports/FOUR-BIOME-BUILD/stormwood-continuous/REPORT.md`
- `tests/smoke_four_biome_continuous.gd`, `tests/smoke_stormwood_continuous.gd`,
  and `tests/helpers/stormwood_crown_build_segment.gd`
