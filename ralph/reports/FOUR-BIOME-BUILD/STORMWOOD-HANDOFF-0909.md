# Stormwood handoff — owner stop, 2026-09-09

**Frozen. HELD; no visual acceptance.** No more edits or native launches are
authorized by this handoff. Stormwood's last native process tree (10976, 14208,
6040) exited at 23:47:37Z; the subsequent census was zero Godot processes and the
lease was explicitly returned to Creature. There are no active Stormwood sessions.

## Captured checkpoint and evidence

Root committed the forest/tree foundation as `0cf8d8855`: four production/config
files, all 122 bake outputs, tree fixture, ground-cover capture probe and report.
Tree build: 1 test / 127 assertions / zero failed. Bake freshness: 1 / 1 / zero
failed. Fingerprint `8963329852361785`. Production ground cover visibly appears at
Rodline Post and Lantern Hollow; the parent still rejected whole-scene quality.
First runtime failure remains separately attributed; it was not erased by the
corrected capture. Full evidence and every bake file are listed in
[STORMWOOD-FOREST-AND-STORMHEART-0909.md](STORMWOOD-FOREST-AND-STORMHEART-0909.md)
and its `-BAKE-FILES.txt` companion.

Tested `tools/_capture_stormwood_stormheart_context.gd` hash
`A8F0C16F25BD2929105B57CD96CE101B75654341F71D90E3433C0E57EB2C76B0`:
parser exit 0, production capture exit 0, three frames, no script/engine errors,
peak 77.31% commit and 264 processes. Evidence:
`.artifacts/stormheart-context-0909/{check,capture}/` and
`shots/catalogue/stormwood/stormheart-context-first-0909/`.
The first look intersects Voltarach; 12.146m ordinary backstep clears the camera
from its mesh but still leaves the creature blocking the tree. This is direct
crowding evidence, **not useful clear finale composition or tree acceptance**.

## Owned changes after the captured foundation

Root owns Git; this lane did not run Git. These are the exact owned source paths
to inspect against the root's latest checkpoint:

| Path | Status |
|---|---|
| `data/config/stormwood_encounters.json` | **Source only.** Only `glass_field_alpha` XZ changes from `(-310,5050)` to `(-250,5080)`; Y remains authored 100 and runtime resolves actual terrain. |
| `scripts/world/stormwood_ending.gd` | **Source only.** Shrine preload switches to the new Stormwood subclass. No state logic changed. |
| `scripts/world/stormwood_heart_shrine.gd` | **New, source only.** Inherits shared relic behavior/collision and companion sockets. Textures base/socket, hides four rectangular visual fins and adds installed rock masonry. Socket material reference and heart/light state remain inherited. |
| `tests/test_stormwood_glass_field_approach.gd` | **New, unparsed/unrun.** Actual imported skinned-model footprint plus 2m idle allowance, 7m wander, route/camera clearance, old-position negative regression, actual terrain slopes, official baked solids and unchanged encounter metadata. |
| `tests/test_stormwood_heart_shrine.gd` | **New, unparsed/unrun.** Pins original cylinder collision, masonry count, socket material/state transitions and companion realm/script identity. |
| `tools/_capture_stormwood_stormheart_context.gd` | Tested first approach above; frozen. Root may have checkpointed it separately. |
| `tools/_capture_stormwood_stormheart_lateral.gd` | **New, unparsed/unrun.** Retains canonical/look/backstep, adds 20m ordinary lateral movement and production named-alpha witness. No creature relocation/hiding/scaling. |
| `ralph/reports/FOUR-BIOME-BUILD/STORMWOOD-FOREST-AND-STORMHEART-0909.md` | Updated source attribution and terminal first-approach evidence; root may have checkpointed separately. |
| This handoff | New evidence only. |

Local non-commit payloads also include `.artifacts/stormheart-context-0909/run.ps1`,
`analyse-candidates.ps1` and `nearby-baked-solids.json`. The guarded launcher is
currently configured for the **first** probe, not the unrun lateral probe/tests.

## Exact causes and remaining decisions

- Glass Field's fixed named Voltarach was at the exact Settings destination and
  critical-route waypoint. Offline analysis of official bake files supports the
  new candidate: 67.08m from catalogue, 31.95m from nearest route, 15.29m clear of
  nearest baked trunk/rock collider. **Actual native terrain/model validation is
  pending.** Encounter count/identity/level/catchability/rewards are unchanged;
  there is no global size reduction. Creature lane owns rejected pink alpha color.
- Lantern Hollow gray forms are the shared four-relic shrine cluster, mounted by
  `stormwood_ending.gd::_build_spark_shrine` at `(-450,3960)`, exactly the catalogue
  and potion coordinate. Canonical trainer placement resolves onto its central
  collider. The new subclass is owner-authorized presentation work but has no
  native test or render evidence yet; keep it held.
- Owner reports houses in terrain. Root owns shared `village.gd` seating/threshold
  investigation. Stormwood buildings use default scale 1.0; no building, shared
  village, terrain or settlement placement edits were made by this lane. Actual
  production floor/door terrain witnesses are still needed.
- No further Stormheart geometry tuning occurred after checkpoint. Current tree
  still needs a clear full silhouette and visible ascent compared with owner
  `docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png`
  and `-b.png`, plus key art and five Palworld references under `docs/reference/`.

**Next single meaningful step when work resumes:** obtain the native lease and run
the new route-clearance fixture under the 120s guard. Preserve its first failure;
do not claim the source-only candidate is supported terrain until that passes.
Then validate the shrine fixture and lateral probe before any new production
capture. Next capture must show the real production offset and shrine changes,
retain the canonical view, and seek a useful tree approach without moving wildlife
in the probe. Root coordinates independent visual review; no self-acceptance.
