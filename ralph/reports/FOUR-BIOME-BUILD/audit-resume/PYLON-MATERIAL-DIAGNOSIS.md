# Pylon material diagnosis — 2026-09-09

Root/Astra diagnosis of the baseline Stormwood judge's nearly white rod-station
finding. Classification: **systemic material binding / in-engine repair using
installed art**. This is not evidence that a new pylon mesh or texture is needed.
No visual repair is accepted yet.

## Evidence

- `JUDGE-STORMWOOD.md` identifies the nearly white central monument in
  `stormwood__cinder_verge__02__verge_rod_station__day.png` and its night pair.
- `data/config/stormwood_rod_stations.json` selects the installed
  `assets/environment/team_tether/tether_pylon.glb` for all four stations.
- Reading the GLB's JSON chunk confirms a mesh with UV coordinates but no
  `materials` or `images` arrays and no primitive material assignment.
- `docs/specs/ASSET_LEDGER.md` explicitly documents this as a geometry-only
  production hero asset with separate live/dead albedos. Both textures already
  exist; the ledger also explains why whole-object emission is inappropriate
  under the Compatibility renderer.
- `scripts/world/stormwood_rod_stations.gd::mount` instantiates and scales the
  geometry without binding either texture. The same omission appears in
  `stormwood_dynamo_arena.gd::build` and the lightning-rod branch of
  `stormwood_camps.gd::_build_dressing`.
- Existing correct consumers demonstrate the contract:
  `cloudreach_chapter.gd::_apply_pylon_material` binds the installed live albedo
  recursively, and `severed_spokes.gd::_pylon_material` binds the installed
  live/dead texture with roughness 0.82 and no whole-object emission.

The white Stormwood station therefore has a named missing-material cause.
This does not diagnose every white arch, base or monument in the survey.
Those require their own source/asset checks; do not group unrelated silhouettes
under this fix.

## Bounded implementation brief

A lesser-model lane should repair the shared pylon material contract and the
confirmed missing consumers, using the existing albedos and established material
settings. Inventory the remaining direct consumers before choosing the smallest
shared utility; preserve consumers that intentionally implement different states.
Preserve dimensions, placements, collisions, light/gameplay state, authority and
progression. Do not repurpose friendly camp props into new faction semantics or
invent new state transitions. Escalate that ambiguity if material selection
requires a story decision.

Own only the material utility, diagnosed consumer bindings, a meaningful native
fixture and evidence report. No new art, Meshy spend, emission-mask workaround,
scale reduction, parked performance work, or unrelated visual tuning.

Verify actual instantiated mesh materials resolve the installed textures in the
affected consumers, retaining the old unbound geometry as a negative control.
Capture affected locations with the corrected catalogue camera after acquiring
the single full-world lease. Preserve before frames and obtain a fresh code-blind
verdict before claiming the visible finding repaired. This is one bounded cosmetic
repair round; an unchanged visual ceiling is recorded, not repeatedly tuned.
