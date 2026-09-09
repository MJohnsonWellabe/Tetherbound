# Meadows catalogue capture — verified fresh round

Capture status: **complete and accepted as catalogue-survey input**. This is visual
audit evidence only. It used Settings debug travel and an audit-only frozen clock;
it is not campaign or progression evidence. No visual quality verdict was made by
this lane.

## Evidence identity

- Branch: `codex/four-biome-audit-resume-0908`
- Capture command: `tools/catalogue_survey.ps1 -Biome meadows -Godot C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe -Output res://shots/catalogue/meadows/round-20260909T002752Z`
- Output: `shots/catalogue/meadows/round-20260909T002752Z/`
- Persistent logs: `engine.log`, `wrapper.stdout.log`, `wrapper.stderr.log`
- Resource samples: `memory-samples.csv`, five-second cadence
- Exit: 0; manifest `complete=true`; 20 planned / 20 captured; failures `[]`
- Engine log: zero lines matching `^ERROR:` or `SCRIPT ERROR`
- Fixture disclosure: production Meadows scene and ordinary gameplay HUD; real
  1.80 m trainer moved with `Game.debug_teleport_to`; clear weather and day/night
  clock are audit-only controls. No progress, HP, items, save state, or encounters
  were injected.

The preflight validator enumerated 10 canonical Meadows destinations and 20 stable
day/night frame IDs from `data/config/debug_teleport_spots.json`. The render used the
corrected numeric-array parser already present in the survey tool. All 20 PNGs are
1280×800, nonempty, have unique SHA-256 hashes, and every day/night pair differs at
the byte level. The manifest carries the requested time identity for every frame.
Spot inspection confirms the ordinary gameplay HUD and trainer are present and that
day is 08:00 while night is 23:00. These are composition/identity checks, not a visual
rubric verdict.

## Destination and coordinate verification

Requested X/Z below are the canonical catalogue values. Actual X/Z are the manifest's
post-settle player position. Day and night agreed at every destination.

| Destination | Band | Requested X/Z | Actual X/Z | Delta |
|---|---|---:|---:|---:|
| Grandpa's Village | Lower Meadows | 6, -22 | 6, -22 | 0.000 m |
| The South Bridge | Lower Meadows | 9, 1300 | 9, 1300 | 0.000 m |
| The Old Quarry | Stone & Root | 403, 1794 | 403, 1794 | 0.000 m |
| The Burrow Warrens | Stone & Root | -357, 2610 | -357, 2610 | 0.000 m |
| The Tether Relay | River Lock | 350, 3760 | 350, 3760 | 0.000 m |
| Old Mill Crossing | River Lock | -152, 4170 | -152, 4170 | 0.000 m |
| The Ironwood Grove | Upper Meadows / Ironwood | -345, 5060 | -345, 5060 | 0.000 m |
| The Ridgeline Watch | Upper Meadows / Ironwood | -250, 6490 | -250, 6490 | 0.000 m |
| Stronghold Approach | Stronghold Approach | -40, 7010 | -40.0808, 7008.7515 | 1.251 m |
| Meadows Hall | Stronghold Approach | 8, 7590 | 8, 7590 | 0.000 m |

The Stronghold Approach trainer settled 1.251 m from the requested X/Z during the
post-teleport pose frames; both time variants settled at the identical point. This is
within the same authored destination and is disclosed rather than described as an
exact coordinate match. The other 18 frames match their requested X/Z exactly.

Every frame records `trainer_visible_intent=true`, the production and capture camera
identities and transforms, a 5.775 m camera-to-player distance, and a nonzero nearby
creature count (11–35 within 160 m). Full-resolution frames are retained for the
separate contact-sheet and blind-judge lanes. No supplemental render was required to
establish catalogue identity; any aesthetic or occlusion finding belongs to the blind
judge.

## Host resource note and lease release

The capture started while the lane held the exclusive full-world RAM/render lease.
Seventeen samples recorded system-available physical memory between 271.1 MB and
2315.9 MB. The sampler's Godot process match selected a small console process and its
per-process working-set values are therefore not reliable evidence of the renderer's
allocation. The system-level readings are retained because the host was critically
tight near completion. Godot and the wrapper exited after the successful manifest;
the full-world RAM/render lease was explicitly returned and this lane launched no
further world render.

## Retained invalid evidence

Earlier `round-20260909-b` and `round-20260909-c` remain untouched. Round C's 20 PNGs
are still invalid because the old parser collapsed every requested X coordinate to
zero. They must not be used in contact sheets or judging. This verified round is the
replacement input.
