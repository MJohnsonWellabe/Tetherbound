# Cloudreach grass baseline — 2026-09-19

Source checkpoint: `34538edb` (approved plan; game source unchanged from main).
Output: `shots/catalogue/cloudreach/grass-0919-baseline-01/`.
Contact sheet: `_sheet-baseline-01.png` beside this report.

## Technical receipt

- Isolated worktree imported successfully on first attempt (exit 0, no ERROR or SCRIPT ERROR); reused an independent copy of the source import cache, never shared cache writes.
- `tools/catalogue_survey_validate.ps1 -Biome cloudreach -Subset @('realm_gate_crag','three_bells_bridge','windscar_beacon','sky_shrine','the_high_perches','cliffhold','old_wind_observatory','summit_eyrie')`: 8 destinations / 16 day-night frames.
- Same subset through `tools/catalogue_survey.ps1`, Godot 4.7.stable.official.5b4e0cb0f, output above, times day/night, trainer: first attempt exit 0, CATALOGUE SURVEY OK 16/16.
- Manifest complete=true, failures=[], 16 distinct frame records and 16 readable 1280x800 PNGs. Production scene `res://scenes/world/cloudreach_cliffs.tscn`, `CameraRig/Camera3D`, FOV 70, original HUD and player.
- Native NVIDIA GeForce GTX 1060 3GB / OpenGL 3.3 Compatibility. No engine or script errors. Existing warning `cr_candy_broken_route_good_07` remains; no gameplay repair attempted.
- Machine render lock acquired/rechecked/released for import and capture. Meadows acquired the released lock afterward. User data isolated by the existing wrapper.
- This is a production-source baseline with debug travel and frozen clock, not campaign evidence or proof of an exported package. Exported-runtime comparison remains required before a promotion.

## Independent code-blind verdict

A fresh-context non-author reviewed the sheet and all sixteen individual frames with the visual-judge skill and both reference sets. No source, plan, or desired outcome was supplied.

| Location | Baseline grass finding |
|---|---|
| Realm Gate | Defect: uninterrupted repeating green foreground; distant grass strip supplies no near layering. |
| Three Bells | Defect: bare lawn jumps abruptly to long crossing strips; no intermediate heights. Night grass is pale against dark turf. |
| Windscar Beacon | Defect: tall, wide isolated angular blades dominate otherwise bare foreground around the trainer. |
| Sky Shrine | Defect: similarly assertive crossing blades fill foreground, partly obscure legs and remove clearings/height hierarchy. |
| High Perches | No identifiable grass defect in this viewpoint: visible stone floor is readable and little grass is shown. Do not claim a grass repair here. |
| Cliffhold | Defect: dense pale hillside bands alternate abruptly with bare intervals; settlement fringe lacks fine transition. |
| Observatory | Defect: thick long-grass band crosses paving and blue markings. Central clearing helps; planting does not read as rooted in cracks or soil. |
| Summit | Defect: isolated tall strips pierce dirt route and overlap trainer legs; dense distant growth is a disconnected regime. |

Reference gaps: ground layering/plant scale first; incoherent night sky/foreground values second; inconsistent rock/tree/landmark finish third. Bar A (belongs to key-art world): NO. Bar B (trying to be the same kind of game as Palworld): YES, genre/intention only, not comparable finish. Still images do not establish motion or performance.

## Candidate boundary

Seven of eight views reproduce grass defects; High Perches is a non-regression view. Role distributions can address strip scale and tangled hierarchy but cannot promise to supply absent Gate vegetation or solve architecture, lighting, paving eligibility, or route-placement defects. Existing local-clearance/count/tip/arc mechanisms remain excluded.

Source trace found the same fixed-width override in the terrain-conforming `LookGroundCoverFinish`/turf-fill grass transforms as in `ProceduralGroundCover`. Both must consume the same Cloudreach role helper so one does not recreate the other's defect. This adds only those grass-transform call sites in `cloudreach_look.gd` to file ownership; it does not change its trees, rocks, lights, route-verges, collision, placement eligibility or counts. Candidate bounds before edits: low scales 0.40–0.60, medium 0.65–0.85, sparse tall 0.90–1.10 on the retained approximately 0.98m tuft; width scales 2.5–2.9 times height. A continuous spatial field must give majority low, fewer medium and no more than 8% tall across a broad fixture grid. Keep accepted origins, RNG progression, placement ceilings, and non-grass transforms unchanged. These are candidate bounds, not visual acceptance.

Ledger delta: none; retained 0 PASS / 9 POLISH / 3 FAIL. No biome promotion.
