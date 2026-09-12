# Independent visual verdict — `final-far-country-thin-woods-03`

**Overall: PASS — the post-Warden country is a restrained horizon layer, and both authored thin-wood stretches read as walkable alternatives to the dense control**

I verified `manifest.json` and inspected all eight 1280×800 PNGs at native
resolution. The package is structurally complete: 8/8 planned frames, eight
distinct nonempty files, `complete: true`, and no manifest failures or per-frame
capture-check findings. The fixture is appropriately narrow: one production
Meadows boot in persisted post-Warden state, production terrain/scatter,
`RiftCollapse`, and production day/night look. It discloses the disabled/parked
player, hidden CanvasLayers, and ordinary-height diagnostic camera, and it makes no
Cloudreach-playable-space claim.

## Strict owner-row verdicts

| Owner row | Verdict | Native-frame evidence |
|---|---|---|
| T2 #9 — post-Warden far country remains visible without a massive Cloudreach silhouette looming over end Meadows | **PASS** | `01-post-warden-far-country-day` and `02-...-night` show a low, desaturated ridge line confined to the distant horizon behind the end-Meadows trees and existing nearer architecture. It reads as atmospheric country rather than a giant destination card: no ridge rises into the upper sky or competes with the foreground forest, and the night treatment recedes further without disappearing. The runtime receipt supports the pixels: the production `legendary_freed` flag survives world boot; the production transition settles in 9,274 ms inside its 13,700 ms budget; `collapsed` is true, `storm_cover` is zero, and `far_cover` is positive. All five live `RiftCollapse/FarCountry` mesh centres are in frame at 782–940 m camera distance, while their individual projected heights remain only 4.31–8.24% of the frame. Four ridge layers sit 650–780 m beyond the far rim at alpha 0.294–0.423, and the restrained glow sits 620 m out at alpha 0.074. The runtime presentation-only scan finds no collision, navigation, or interaction nodes. |
| T2 #10 — add thinner, walkable woodland stretches at Warrens and Stonewater, contrasted with ordinary dense woods | **PASS** | `03/04-warrens-thin-woods` gives a broad grass floor and long open sightline with separated tree clusters rather than a continuous trunk wall; its den architecture remains visible through the stand in both day and night. `05/06-stonewater-thin-woods` similarly leaves a wide traversable foreground and open right-hand horizon while retaining an identifiable grove at left, so it still reads as woodland rather than a treeless field. By contrast, `07/08-dense-woods-control` encloses the route with near trunks on both sides, overlapping crowns, a continuous deeper tree line, and a much shorter lateral read. The named production receipts agree with that visible hierarchy: `warrens_walkable_thin_wood` is a 62 m clearing at 0.32 retain fraction with 6 blocking scatter items in the common 24 m sample; `stonewater_walkable_thin_wood` is 70 m at 0.35 with 12; the same-radius ordinary Band 2 control has 15 and no clearing override. |

## Production-receipt audit

- **PASS — post-Warden state:** the flag is present before and after boot, and the
  captured production horizon has completed the expected storm-wall-to-far-country
  settlement. This is honest persisted-state evidence, not a replay of the Warden
  fight or the instant the flag is awarded.
- **PASS — presentation-only boundary:** the five live far-country meshes are distant,
  low-alpha render layers. The manifest separately identifies `RiftCrossing` as the
  authorized bridge/realm handoff; it does not mislabel the silhouette itself as
  enterable terrain.
- **PASS — authored clearing identity:** both reduced-density views name their shipped
  clearing IDs, radii, retain fractions, config sources, and same-radius live blocking
  counts. The dense comparison is an unchanged production corridor, not a synthetic
  before/after control.
- **PASS — day/night stability:** both requirements remain legible in their paired
  presets. Night reduces colour and value but does not erase the horizon, clearings,
  route enclosure, or tree-spacing distinction.

## Runtime-log caveat

After frame 08 had been written, Godot emitted eight GLES3 `Parameter "material" is
null` errors: the four-call sequence `material_casts_shadows`,
`material_is_animated`, `material_get_instance_shader_parameters`, and
`material_update_dependency` repeated twice. It then exited 0. The same sequence is
documented in earlier repository runs, and its post-frame timing does not invalidate
the already-complete PNG set, manifest, or row verdicts above. This is nevertheless
real teardown/runtime diagnostic debt: this PASS is not a clean-engine-log claim and
does not prove material lifetime/shutdown hygiene.

This report does not claim the boss transition itself, Cloudreach traversal, the
separate crossing trigger, full-route collision/navigation, or woodland density
outside the three sampled production stands.
