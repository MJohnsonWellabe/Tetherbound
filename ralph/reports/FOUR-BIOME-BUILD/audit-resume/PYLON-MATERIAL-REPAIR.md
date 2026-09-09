# Pylon material repair — 2026-09-08

Status: **implementation and native proof complete; rendered visual proof and a
fresh code-blind verdict remain required.** This report does not claim that the
baseline white-pylon finding is visually closed.

## Cause and bounded result

`assets/environment/team_tether/tether_pylon.glb` is intentionally a
geometry-and-UV asset. A raw Godot instance has real mesh surfaces, but neither
installed pylon albedo resolves until a runtime consumer applies one. Several
consumers already implemented that contract; five files instantiated the same
geometry without doing so.

`scripts/world/tether_pylon_materials.gd` now owns the shared live/dead material
construction and recursive mesh binding. It uses the installed live and drained
albedos, roughness `0.82`, metallic `0.0`, and no emission. That matches the
existing production treatment and retains the Compatibility limitation recorded
in `ASSET_LEDGER.md`: a whole-object emission map is not reintroduced.

The five confirmed missing consumer files now bind:

- `stormwood_rod_stations.gd`: live until the existing station-disabled flag is
  present, then drained. The existing progression restore is the only selector.
- `stormwood_dynamo_arena.gd`: live. Existing charge, firing and recovery state
  continues to drive only the bank's light and discharge lane.
- `stormwood_camps.gd`: drained. This is a visual material selection for the
  friendly camp prop and creates no faction flag, powered state or transition.
- `cloudreach_summit_presentation.gd`: live for the authored Team Tether pylons
  installed by its shared fitter.
- `cloudreach_world.gd`: live for the four stronghold-corner pylons and the
  occupied summit pylon.

No dimensions, fitted scales, placements, rotations, collision, lights,
interaction, authority, progression or gameplay values changed.

## Consumer inventory

There are eight direct code consumers of the pylon GLB or its extracted mesh.

| Direct consumer | Binding before this repair | Result |
|---|---|---|
| `cloudreach_chapter.gd` | Live albedo, recursive override | Already correct; unchanged |
| `cloudreach_physical_runtime.gd` | Live albedo, recursive override | Already correct; unchanged |
| `severed_spokes.gd` | Cached live/dead materials on extracted mesh | Already correct; unchanged |
| `cloudreach_summit_presentation.gd` | None | Shared live finish applied |
| `cloudreach_world.gd` | None | Shared live finish applied |
| `stormwood_rod_stations.gd` | None | Shared live/dead finish follows existing disabled state |
| `stormwood_dynamo_arena.gd` | None | Shared live finish applied |
| `stormwood_camps.gd` | None | Shared drained finish applied |

`tether_relay.gd` is a ninth relevant file but is not a direct GLB consumer. It
changes the identity-cached materials produced by `severed_spokes.gd` during the
existing relay shutdown and remains unchanged.

The two Cloudreach omissions were found during the required inventory after the
original Stormwood diagnosis. Root independently confirmed that both instantiate
the geometry-only asset without a binding and extended the diagnosis to material
binding only at those consumers. No other Cloudreach presentation or visual
tuning entered this repair.

## Native regression proof

`tests/test_tether_pylon_material_binding.gd` instantiates the real production
GLB as a negative control and proves that its mesh surfaces do not resolve either
installed pylon texture. Positive cases then exercise each repaired production
consumer against actual `MeshInstance3D` geometry:

- shared live and drained binding, exact installed texture identity, roughness,
  metallic value and emission disabled;
- all four rod stations before and after their real disabled-state restore;
- every Dynamo capacitor bank and a firing-state update;
- all six authored camp lightning rods;
- Cloudreach's world helper and summit presentation fitter;
- unchanged geometry hierarchy and transforms, plus the existing rod prompt,
  disabled light, Dynamo lane and firing-light behavior.

Validation on Godot `4.7.stable.official.5b4e0cb0f`:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=test_tether_pylon_material_binding.gd
4 tests, 147 assertions, 0 failed

godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_camps.gd,test_stormwood_dynamo.gd,test_stormwood_rod_ledger.gd
15 tests, 175 assertions, 0 failed

godot --headless --path . --import
exit 0; no script or resource error

git diff --check
clean
```

The station test launches an initialized native child process because the unit
runner discovers tests during `SceneTree._init()`. That child mounts the actual
station runtime with `/root/Game` available and must complete more than 60
additional geometry/state assertions; its result is checked by the parent test.

## Remaining visual evidence

Acquire the single full-world render lease and produce corrected-camera
Cloudreach and Stormwood sheets from this branch. Preserve the baseline frames.
A fresh code-blind judge must compare the affected locations and decide whether
the installed texture is visibly present and whether the nearly white pylon
finding is repaired. At minimum the evidence must cover the Stormwood Verge rod
station in day and night, other affected Stormwood pylon contexts, and the
Cloudreach stronghold/summit pylon contexts exposed by the expanded diagnosis.

If the rendered result still fails, record the remaining visual ceiling. This
was the one permitted binding round; it does not authorize emission workarounds,
new art, geometry, scale, placement or unrelated material tuning.
