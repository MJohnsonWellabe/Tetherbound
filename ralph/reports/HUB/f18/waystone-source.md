# F18 waystone source evidence

Implementation source evidence only. No acceptance MET verdict; independent review and serialized engine/player-path proof remain required.

The owned component submits touch intents and presents committed local-character state. It does not mutate durable state, award items or move actors. UX12.2/F18#3 touch activation takes precedence over WORLD2.7 obsolete interact wording.

## Frozen owned candidate

- `data/config/waystones.json` SHA256 `4e98dc6bde5b4eea9b9d87c89b7f437cac0cf9b7c0f2c8b084b2673923328e83`
- `scripts/world/waystone.gd` SHA256 `aa9a52a8a2322d3c650422187feefadbad1f4b551b3c96509d77f6880d6669ab`

## Named source-anchor audit

Node JSON audit checked all 19 unique IDs against their canonical source collection, id and coordinate field. Counts: Meadows 5, Tidewake 5, Cloudreach 4, Stormwood 5. Each frozen XZ matches its source exactly; Cloudreach preferred Y matches authored platform height.

| Stone | Canonical anchor XZ | Source row |
|---|---|---|
| Trail Camp | 344.3, 936.6 | `res://data/config/bands/band1_lower_meadows/props.json` / `trail_camp` |
| Quarry Ranger Camp | -256.4, 2260.1 | `res://data/config/bands/band2_stone_and_root/props.json` / `ranger_camp` |
| Riverwatch Camp | 211, 3700 | `res://data/config/bands/band3_the_river_lock/props.json` / `riverwatch_rest` |
| Upper Meadows Camp | 276.7, 5652.5 | `res://data/config/bands/band4_upper_meadows_ironwood/props.json` / `highfield_stockcamp` |
| Sigil Gate Waystop | -23.8, 7456.9 | `res://data/config/bands/band5_stronghold_approach/props.json` / `the_waystop` |
| First Shore | 7, 142 | `res://data/config/water_camps.json` / `water_camp_first_shore` |
| Shellwatch | 359.289459228516, 971.46923828125 | `res://data/config/water_camps.json` / `water_camp_shellwatch` |
| Tidal Cradle | 556.092163085938, 1367.17846679688 | `res://data/config/water_camps.json` / `water_camp_tidal_cradle` |
| Salt Crown | 284.932739257813, 2128.56884765625 | `res://data/config/water_camps.json` / `water_camp_salt_crown` |
| Sluice Isle | 672.336120605469, 2788.5263671875 | `res://data/config/water_camps.json` / `water_camp_sluice_isle` |
| Galefoot Waycamp | -280, 520 | `res://data/config/cloudreach_chapter.json` / `galefoot_waycamp` |
| Windscar Aerie | 388, 3258 | `res://data/config/cloudreach_chapter.json` / `windscar_flight_aerie_camp` |
| Cliffhold Commons | -340, 3970 | `res://data/config/cloudreach_chapter.json` / `cliffhold_commons` |
| Summit Bivouac | 132, 5342 | `res://data/config/cloudreach_chapter.json` / `summit_bivouac` |
| Ashfoot Waycamp | -325, 466 | `res://data/config/stormwood_camps.json` / `ashfoot_waycamp` |
| Lantern Pools Camp | -410, 1425 | `res://data/config/stormwood_camps.json` / `lantern_pools_camp` |
| Still Grove Shelter | -130, 2730 | `res://data/config/stormwood_camps.json` / `still_grove_shelter` |
| Lantern Hollow Waycamp | -422, 3924 | `res://data/config/stormwood_camps.json` / `lantern_hollow_waycamp` |
| Ember Bivouac | -140, 5242 | `res://data/config/stormwood_camps.json` / `ember_bivouac` |

Old Mill map pin was rejected because it is a bridge centre: Meadows ground_height_at reads terrain, not the bridge deck. Riverwatch Camp is the existing named camp on that approach. Cloudreach uses existing Galefoot, Windscar Aerie, Cliffhold and Summit camps instead of guessing a High Roost shelter position.

## Shrine source and placement limits

Installed model: `assets/props/tideglass_shrine/tideglass_shrine.glb`, already used by playground_world.gd Realm Heart sockets. GLB POSITION accessor bounds (identity node transform): 1.6786659955978394 x 1.1505600810050964 x 1.9027611017227173 m. Uniform height normalization to 1.8m yields 2.9768m maximum footprint, within configured 3m support envelope. This is geometry inspection, not native visual proof. No assets expanded or copied.

Configured shrine offsets are candidate local placements beside canonical camps (normally 7m toward -Z; Galefoot 7m toward +X). Arrival stands 3m toward -Z from the shrine. Every support resolves through the existing world ground_height_at; Cloudreach passes preferred Y. Four corner samples refuse missing/steep support, and Water refuses submerged support. ROOT must prove all 19 candidates mount, all arrival points have dry collision/body clearance and each shrine reads as inactive/active at gameplay distance. These conditions have not been measured here.

## Shared authority contract still required

- ROOT mounts `build(world, runtime_realm)` once under each world after ground surfaces exist. Host simulation shells retain positions/identity and disabled inspect prompts, and skip all shrine asset loads.
- `Game.request_portal_action({kind:waystone_touch, waystone_id:id})` returns `{ok, request_id, reason}`. A stable nonempty request identity is required. `portal_action_result` emits deferred after queue return and contains matching request_id, kind, waystone_id/id, character_id, ok, reason and first_activation.
- `Game.portal_character_state()` returns only the bound local character snapshot: character_id, waystones_activated by canonical biome and last_waystones. Commit/publish that snapshot before success ACK. No success banner or light is applied from a queue response.
- Host derives stable character/actor from peer/session binding; verifies source realm, known configured stone, authored grounded proximity and refusal state. Client-supplied positions/unlocks are forbidden. First activation is idempotent; later touches update the own-character last return point in admitted request order. Only bool-save success permits an ACK; save failure must roll back. Reconnect/rejoin resolves commit vs rollback exactly once.
- Existing redesign_state.gd rejects all concrete IDs except biome_entry. ROOT must validate waystone IDs against this config and its biome, preserve entry fallbacks and existing saves; component cannot bypass that shared validator.
- Portal destination uses resolve_position(world,row,true) from own persisted last touch, else configured biome entry. Waystones never teleport to each other.

## Remaining acceptance proofs

Independent strict source review; named ROOT engine import/parse; all 19 dry supports/arrival collision/presentation; touch and first/return messaging; reload and cross-host portability; failed save and duplicate/stale request recovery; and F18#5 ordinary deep-biome → Home Key → homestead station → portal-back/save loop. No Godot, import, render, gameplay, GPU, ImageGen or Meshy jobs were launched by this session.
