# Stage C6 audit-resume briefs

Run start: 2026-09-09 00:01:09 UTC. First checkpoint due 2026-09-09
02:01:09 UTC. This is the queued ownership/interface record, not an audit verdict.
The resumed run executes the pulled-forward general audit, then continues through the
standing prompt 78 plan to its section 7 Beta Ready definition of done.

## Shared catalogue survey interface

`tools/catalogue_survey.gd` reads the Settings source
`data/config/debug_teleport_spots.json` and captures one selected production biome.
It accepts:

- required `--biome=meadows|cloudreach|stormwood|water`;
- optional `--output=res://...` (the wrapper defaults to a unique UTC-stamped
  `res://shots/catalogue/<biome>/<round>` directory);
- optional repeatable `--subset=<id-or-name-substring>`;
- optional `--times=day,night|day|night` (default both).

Use the Windows wrapper to isolate `user://` under `.artifacts` and preserve owner
settings/saves:

```powershell
tools/catalogue_survey.ps1 -Biome meadows -Godot C:\path\to\Godot_console.exe
```

Enumerate and validate exact IDs without starting Godot:

```powershell
tools/catalogue_survey_validate.ps1 -Biome meadows
tools/catalogue_survey_validate.ps1 -Biome cloudreach -Subset summit
```

The harness refuses to overwrite an existing manifest or selected frame, preserving
failed rounds as evidence. Every output directory contains `manifest.json` with the catalogue/band/
destination/time identity, stable frame IDs, requested and actual player/camera
positions, immutable full-catalogue-derived view heading, full camera transform,
production and capture camera IDs, trainer framing intent, nearby-creature
count, fixture disclosure, errors, and completeness. Captures use the real scene and
ordinary gameplay HUD. The real trainer is moved by `Game.debug_teleport_to`; only the
day/night clock and weather are pinned for the audit. This is debug-travel visual
evidence and cannot prove campaign progress.

Only one Godot render/full-world process may run at a time. A lane asks root for the
lease, runs its biome, reports command/coverage/errors, and explicitly returns the
lease. Two no-yield attempts on one narrow issue stop that approach.

## Queued lane ownership

| Lane | Catalogue coverage | Minimum frames | Owner |
|---|---:|---:|---|
| Meadows | 10 destinations × day/night | 20 | Meadows survey lane |
| Cloudreach | 12 destinations × day/night | 24 | separate Cloudreach biome lane |
| Stormwood | 12 destinations × day/night | 24 | separate Stormwood biome lane |
| Water/Tidewake | 24 destinations × day/night | 48 | separate Water biome lane |
| Contact sheets | four biome sheets plus one combined sheet, retaining full frames and manifest order | 5 sheets | separate Sol contact-sheet lane |
| Blind judging | every sheet and legible individual frames; unchanged full visual-judge rubric and references only | no numeric scores | fresh Astra agent with no implementation context |
| Finding triage | priority, exact frame/location, likely owner, proposed fix/criterion/Beta impact, LOCAL or SYSTEMIC, in-engine or new-art/reference | all accepted findings | separate Astra triage lane |

Biome lanes capture only their assigned biome. They do not judge their own images.
