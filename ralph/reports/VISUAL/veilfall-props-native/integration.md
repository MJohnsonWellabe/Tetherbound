# Native prop validation and integration contract

Baseline: Tidewake visuals e993b8977 in a separate detached checkout. All frames are native Windows Godot 4.7 Compatibility at 1920x1080 on GTX1060. Source and screenshots are archived together. This is an asset trial, not a world-code integration.

Independent r2 verdict: pump scoped PASS, banner scoped PASS, sluice gate finished presentation FAIL; whole scene A/B NO. The gate r3 revision now separately passes scoped construction, housing and state readability; see visual-judge-sluice-r3.md. The earlier r2 gate and white material-export frame remain rejected.

## Passing assets

- `res://assets/environment/tidewake/pump_station/pump_station.tscn`: parent under existing `intake_pump` and `sluice_wheel` interaction nodes. Geometry offset (0,-1,0), yaw180; existing parent local positions (-5,1,22), (9,1,49). Preserve interactions, collision and flags. Use new pipe connections/foundation in owning scene lane; the pump body itself passed. No motion or water-connection acceptance implied.
- `res://assets/environment/tidewake/heart_banner/heart_banner.tscn`: front -Z. Native validated positions (-18,3.5,105), yaw-90 and (18,3.5,105), yaw90, in interior-local metres. Crossbar sits at the front edge beneath gallery. Original requested wall-centre height was obscured by the gallery; `rejected-placement` records this. Hide/remove old banner visuals explicitly in production, retaining all unrelated dressing. Root is cloth centre, not floor.

The validation overlay uses position-based selection only to hide original banner primitives in the pinned baseline. Production integration should use explicit named banner nodes, not copy that temporary selector. Claude owns placement and scene integration.

## Shortcuts disclosed

Declared player stands and camera yaw/pitch; granted five-member party; no companion summoned; no earned route or fight test. Production CameraRig and world scripts are unmodified. Before/after time advances 08:02–08:32; first two baseline frames include the auto-hiding party popover. Static interior light configuration is unchanged. No cloth/pump motion, and original instantaneous gate hide behavior retained for the trial. The closest gate frames crop the overhead hoist; the entrance frame includes it. Right banner is partly behind the story HUD in the overview; both dedicated banner frames show complete subjects.

Collision shapes are synchronously167 before and167 after asset insertion. Initial146 count predates completion of asynchronous world population and is not the installation comparison. Run exits0 without engine errors. Imported cache UIDs fell back to valid texture resource paths; perform ordinary project import after cherry-pick. Raw log in run.txt.

Each of18 r2 frames was individually opened by the author. Independent critic inspected all10 after/open frames. See inspection.json for per-frame findings. Full interior scene, water, material and composition defects remain open in the verdict; passing these two props does not close F13#5 or another regional criterion.

## Revised sluice asset

`assets/environment/tidewake/sluice_gate/sluice_gate_18.tscn` and `_30.tscn` each contain FixedFrame and GateLeaf. Place FixedFrame under the interior at original gate z30/z79. Reparent GateLeaf at local zero under the existing barrier; its current visible flag hides the leaf while fixed housing remains. Retain original collision/interaction/state code. No new collider. Full leaf is18/30m wide and7m high; fixed housing tops at11.25m under the12m ceiling. Geometry checks verify no low fixed vertices intrude into the original aperture.

r3 uses jointed boards, seated washers and bolts, thicker reinforcement, articulated grille rows and a slatted receiving drum. The primary vertex colour and authored material factors are explicitly preserved by the reproducible exporter. Nine corrected native before/after/open frames are in sluice-r3; every frame opened individually, exit0, collider count167/167. Final independent gate scope PASS; full scene A/B NO.

Shortcuts disclosed: roll fill is static in both states and the existing instantaneous hide is retained; no winding animation or moving mechanism is claimed. Fixed low posts are embedded outside the original opening in continuous side walls; overhead cheeks provide visible support without narrowing the passage. Material coherence passes its narrow scope but broad panel wear remains cleaner than the pump. Pump-water-channel connections, bridge railing assembly, room volume and lighting remain scene-lane work. Source/integration.md carries the detailed asset API.
