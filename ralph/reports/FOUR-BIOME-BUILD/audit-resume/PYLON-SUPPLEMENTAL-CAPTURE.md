# Pylon supplemental capture — stopped on first route failure

Date: 2026-09-09 UTC  
Branch: `codex/four-biome-audit-resume-0908`  
Launch HEAD: `b931976b943f31def173859e3a2f8822d6fe28ba`  
Helper: `tools/capture_pylon_material_supplement.gd`

## Result

The approved eight-frame Cloudreach/Stormwood supplement stopped on its first
failure. The single Cloudreach process exited `1` with zero accepted PNGs.
Stormwood was not launched, and neither biome was retried.

This is a capture-route failure, not evidence of a missing material or a
production pylon-placement defect. Runtime inspection resolved the production
node `Landmarks/SummitEyrieStronghold/OccupiedSummitPylon`, verified that an
active mesh material uses
`res://assets/environment/team_tether/tether_pylon_albedo.png`, and measured its
rendered global bounds as:

- position `(95.43381, 1195.475, 5345.444)`
- size `(9.132393, 18.0, 9.111328)`
- derived center approximately `(100.0, 1204.475, 5350.0)`

Catalogue travel arrived at `(100.0, 1160.13, 5350.0)`. The approved ordinary
south walk toward the candidate exterior viewpoint ended at
`(99.99995, 1025.925, 5311.16)`, about 134 metres below the arrival elevation.
That viewpoint was unsuitable for framing the target center with ordinary
camera input. The helper allowed 360 look frames, used 0.65-strength look
actions, required yaw and pitch errors within 2 degrees for eight stable
frames, then reported
`cloudreach__stronghold_occupied_summit_pylon: ordinary camera orbit could not frame target`.
The failed path also emitted 193 player runaway-velocity clamp warnings while
descending. No production engine error preceded the helper's single terminal
error.

Because this was the first blocked capture, the process did not visit the
Cloudreach summit-presentation pylon, the Stormwood Rodline Refuge rod, or the
Stormwood Dynamo bank-0 pylon. It recorded no accepted frame, clock, or camera
transform. Those four day/night pairs remain missing visual context; the
runtime binding check above is mechanical evidence only and is not a visual
acceptance claim.

## Preserved run

Output root:
`shots/catalogue/cloudreach/round-pylon-supplement-20260909T024817Z`

- capture clock: `2026-09-09T02:48:23Z` to `2026-09-09T02:50:25Z`
- wrapper clock: `2026-09-09T02:48:17.7079734Z` to
  `2026-09-09T02:50:28.9027852Z`
- console PID: `23532`
- actual non-console renderer PID: `22472`
- resource samples: `43`
- peak renderer private bytes: `5,205,667,840`
- peak committed-memory use: `76.60084948330206%`
- peak process count: `257`
- resource guard: not tripped (`>90%` committed / `>400` processes)
- manifest: `complete=false`, `captured_frame_count=0`

The output preserves `manifest.json`, separate stdout/stderr logs,
`resource-monitor.csv`, and `launch-summary.json`. The round name and recorded
UTC clocks are kept exactly as produced.

## Helper boundary

The dedicated helper mounts one unmodified production biome per process,
resolves production targets and active albedo textures at runtime, and records
actual mesh bounds before capture. Travel uses the Settings catalogue debug
path, followed only by input actions through the existing stick navigator and
camera look actions. It does not write player or camera transforms, scales,
progress, inventory, unlocks, gameplay state, or assertions. The Stormwood
Dynamo route retains the existing 6,000-frame earned-ascent budget, but that
route was not exercised in this stopped run.

No production file was changed from this supplemental result. Fresh blind
visual judgment remains pending on any future context frames authorized under
a separate bounded capture plan.
