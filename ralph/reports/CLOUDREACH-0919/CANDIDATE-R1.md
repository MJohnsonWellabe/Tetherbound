# Cloudreach grass roles — candidate R1

**Disposition: HOLD / not accepted.** One bounded candidate produced a mixed
independent verdict, including an Observatory regression. No location promotion;
no merge. Retain the baseline and candidate evidence. Do not claim that assigning
roles numerically has solved the visible grass problem.

## Capture validity

Game source 89c176fdcb0eaa0695f8a302c7e85bce7838fcae; capture checkout also
contains documentation-only a12af390. Godot 4.7.stable.official.5b4e0cb0f,
native NVIDIA GTX 1060 3GB, OpenGL 3.3 Compatibility driver 560.94, 1280x800.
Actual `scenes/world/cloudreach_cliffs.tscn`, production trainer, CameraRig/Camera3D
and HUD, same catalogue IDs and day/night clocks as BASELINE.md. No missing-world
fixture or replacement camera. Source-scene evidence; packaged parity is separate.

Command: `tools/catalogue_survey.ps1 -Biome cloudreach -Godot <4.7 console exe>
-Output res://shots/catalogue/cloudreach/grass-0919-candidate-r1 -Subset
realm_gate_crag,three_bells_bridge,windscar_beacon,sky_shrine,the_high_perches,
cliffhold,old_wind_observatory,summit_eyrie -Times 'day,night' -Character trainer`
(PowerShell Subset passed as eight strings, not one comma-separated string).

Local frame root: `shots/catalogue/cloudreach/grass-0919-candidate-r1/`.
Console log: `.artifacts/cloudreach-0919/candidate-capture-r1.log`.
16/16 PNGs and manifest records, complete true, failures empty, exit 0;
no ERROR or SCRIPT ERROR. Existing `cr_candy_broken_route_good_07` warning retained.
One preceding PowerShell invocation failed parameter binding because day,night
was unquoted; it never launched Godot or captured a frame. Successful capture
ran once. Lock checked before launch and repeatedly during the run, released on exit.

All player positions match baseline. Camera component maximum differences are
0 except five floating-point variations, worst 0.00006103515 at High Perches
night; this is not a different authored camera. Capture wall span: baseline
205 seconds, candidate 203 seconds; world-attached log marks: baseline 168029 ms,
candidate 177862 ms. Single runs are not a performance verdict. Counts remain
fixed by the structural tests; frame-rate/motion acceptance is not inferred.

`_sheet-candidate-r1.png` compares SET X (baseline) and SET Y (candidate), day/night
for all eight locations. Raw frames remain local. Reviewer inspected the sheet
and all 32 full-size images plus key art and five Palworld references, without
code, implementation details or a desired outcome.

## Independent code-blind verdict

| Location | Preference, both day/night | Finding |
|---|---|---|
| Realm Gate Crag | Tie | Bare smooth approach and jagged path remain. Extra Y message is not environmental improvement. |
| Three Bells Bridge | Y, slight | Right foreground less tangled/top-heavy; bare foreground, abrupt grass islands and night deck striping remain. |
| Windscar Beacon | Tie | Blade posture change does not improve composition; oversized isolated blades, bright dense fringe and exposed dark ground remain. |
| Sky Shrine | Tie | Continuous crossed-blade carpet remains; trainer lower body and clearings do not materially improve. |
| The High Perches | Tie | Main composition unchanged; grass difference behind columns too small to matter. |
| Cliffhold | Y, slight | Left hillside gaps filled, but now a uniform crop strip; bare right lawn and empty square persist. |
| Old Wind Observatory | X, slight | Candidate foreground crowds stone clearing and blue floor details; tall grass through paving remains. |
| Summit Eyrie | Y | Clearest gain: reduced blade obstruction restores trainer/route/dome hierarchy. Isolated path blades and blocky boundaries remain. |

Reviewer: Y is a modest mixed improvement, carried principally by Summit Eyrie,
not a clean improvement everywhere or evidence that remaining defects are resolved.
Trainer silhouette is readable but generic; nearby creature appeal is not proven
by these views. Night foregrounds remain near-black against pale sky/distant cliffs.

Ranked remaining gaps:

1. Vegetation density lacks natural structure: Shrine/Beacon repeated blades,
   Gate the opposite bare extreme. Roles did not create convincing transitions.
2. Inhabited/material coherence: Cliffhold empty square, Perches primitive props,
   Summit angular boulder; grass alone cannot close this.
3. Landscape lighting: black foregrounds against bleached distant cliffs at
   Beacon/Observatory night; overly uniform bright Shrine grass by day.

Bar A (key-art world): **No**. Bar B (Palworld kind of game): **No**. The reviewer
requires stronger natural vegetation, occupied/coherent places, unified light and
demonstrated creature-led identity. Scene changes can address part of the gap;
distinctive environmental/creature art cannot be established by scatter changes.
Do not average this verdict with the earlier baseline review's different B answer.

## Window decision

No second numerical tuning round is justified by this comparison. The unchanged
placement/exclusion constraints leave paving intrusion and empty terrain intact,
while the permitted role change worsened Observatory. Do not restart the spent
count, local-clearance, basal-storey or tip/arc trials under a new label. Keep this
candidate isolated for review; the approved window does not authorize another
mechanism. Ledger retained at **0 PASS / 9 POLISH / 3 FAIL**. This is a useful
negative result, not accepted visual production.
