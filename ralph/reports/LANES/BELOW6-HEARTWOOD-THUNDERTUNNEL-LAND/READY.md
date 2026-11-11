STATUS: land
BRANCH: tb/below6-heartwood-thundertunnel-land (cut from origin/main 8df122a83; READY is in the same commit)

# F41#1 Stormheart heartwood and F36#80 Thundertunnel coat, ON (LANE-BELOW6, 11 Nov 2026)

## Verdict
`ralph/reports/GPU-PASS/1108/G-below6-thundertunnel-heartwood.md` on `tb/item-scout-1108` 4515bd926 (GPU High, three code-blind judges, confirming batch, fit r 0.991):

| Set | Base | Arm | Gain | Prefer arm |
|---|---|---|---|---|
| F36#80 Thundertunnel | 4.63 | 6.04 | +1.41 | 3/3 |
| F41#1 Stormheart, row (4 frames) | 4.29 | 5.66 | +1.37 | 3/3 |
| F41#1 Stormheart, close only (2 frames) | 4.39 | 5.95 | +1.56 | 3/3 |

- Thundertunnel: flat pinkish-tan flesh PRESENT -> FIXED 3/3; cracks as mud fissures PRESENT -> PARTIAL 3/3. Leaves the below-6 band.
- Stormheart: flat white strokes PRESENT -> FIXED 2/3; no core or crown in view PRESENT -> PARTIAL 3/3. Still under 6 on the row.
- No loss on any set. High only; Medium has not been judged.

## Flags
- ON: `creature_coat_flags.json below6_floor_thundertunnel`; `stormheart_presentation.json heartwood_1111`. Each carries `_why_on` with the score and the verdict file.
- OFF inside the heartwood block: `body_enabled` (see below).

## One difference from the judged arm
The judged arm built a 4.6 m static cylinder on the hollow axis so players could not walk through the root cage. The landing tests caught it breaking the tree's pinned physics contract (`test_stormheart_ancient_trunk.gd`: every floor, ramp and rail shape byte-identical with and without presentation). The body is now an opt-in (`body_enabled`) that ships OFF. It has no visual, so the judged frames are unchanged. **Consequence: a player can walk into the heartwood's root cage and core.** Turning the body on means changing that physics pin on purpose; it is not done here.

## Files
- `scripts/world/stormheart_tree.gd` (`_heartwood`, `_heartwood_body`, core cooling on release)
- `data/config/stormheart_presentation.json`, `data/config/creature_coat_flags.json`
- `assets/props/blender-1111/stormheart_heartwood/` (GLB, import sidecar, provenance; Blender procedural, no Meshy), with its build script and scale check in `ralph/reports/LANES/BELOW6-HEARTWOOD/`
- Thundertunnel `_value_lift_floor1.png` and `_value_lift_floor1_glow.png` with VRAM-compressed sidecars; `tools/art_pipeline/grade_remakes_floor.py` (adds the `thundertunnel` grade; the `fulgocobra` grade in it has no flag or texture on main)
- `tests/test_stormheart_heartwood.gd`, `tests/test_below6_thundertunnel_landed.gd`

## Tests
Run in the lane checkout with these files copied over: `--only=stormheart,below6_thundertunnel_landed,remakes_floor_landed,creature_coat_flags,texture_import_policy,remake_owner1101_finish,stormwood_world,smoke_stormheart_ascent`: 16 test files, 55 tests, 7860 assertions, 0 failed. The per-file lines show both new test files ran. No full suite. The first run failed two existing Stormheart physics tests because of the axis body; that is what led to the change above.

## Not fixed (judges)
- Stormheart: both approach frames look into a bark wall, with an orange wood-grain slab at the left (3/3); the core reads as "a flat gradient slab, hard edges" and wants internal arcs, bloom falloff and light on the bark; no crown in view.
- Thundertunnel: the lines read as uniform white decals with no glow (3/3); the faint is a faceless ball; the hit barely differs from standing.
