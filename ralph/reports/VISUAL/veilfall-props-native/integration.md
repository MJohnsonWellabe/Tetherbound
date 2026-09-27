# Native prop validation and integration contract

Baseline: Tidewake visuals e993b8977 in a separate detached checkout. All frames are native Windows Godot 4.7 Compatibility at 1920x1080 on GTX1060. Source and screenshots are archived together. This is an asset trial, not a world-code integration.

Independent r2 verdict: pump scoped PASS, banner scoped PASS, sluice gate finished presentation FAIL; whole scene A/B NO. The gate requires a separate construction/housing revision. Do not integrate its rejected trial.

## Passing assets

- `res://assets/environment/tidewake/pump_station/pump_station.tscn`: parent under existing `intake_pump` and `sluice_wheel` interaction nodes. Geometry offset (0,-1,0), yaw180; existing parent local positions (-5,1,22), (9,1,49). Preserve interactions, collision and flags. Use new pipe connections/foundation in owning scene lane; the pump body itself passed. No motion or water-connection acceptance implied.
- `res://assets/environment/tidewake/heart_banner/heart_banner.tscn`: front -Z. Native validated positions (-18,3.5,105), yaw-90 and (18,3.5,105), yaw90, in interior-local metres. Crossbar sits at the front edge beneath gallery. Original requested wall-centre height was obscured by the gallery; `rejected-placement` records this. Hide/remove old banner visuals explicitly in production, retaining all unrelated dressing. Root is cloth centre, not floor.

The validation overlay uses position-based selection only to hide original banner primitives in the pinned baseline. Production integration should use explicit named banner nodes, not copy that temporary selector. Claude owns placement and scene integration.

## Shortcuts disclosed

Declared player stands and camera yaw/pitch; granted five-member party; no companion summoned; no earned route or fight test. Production CameraRig and world scripts are unmodified. Before/after time advances 08:02–08:32; first two baseline frames include the auto-hiding party popover. Static interior light configuration is unchanged. No cloth/pump motion, and original instantaneous gate hide behavior retained for the trial. The closest gate frames crop the overhead hoist; the entrance frame includes it. Right banner is partly behind the story HUD in the overview; both dedicated banner frames show complete subjects.

Collision shapes are synchronously167 before and167 after asset insertion. Initial146 count predates completion of asynchronous world population and is not the installation comparison. Run exits0 without engine errors. Imported cache UIDs fell back to valid texture resource paths; perform ordinary project import after cherry-pick. Raw log in run.txt.

Each of18 r2 frames was individually opened by the author. Independent critic inspected all10 after/open frames. See inspection.json for per-frame findings. Full interior scene, water, material and composition defects remain open in the verdict; passing these two props does not close F13#5 or another regional criterion.
