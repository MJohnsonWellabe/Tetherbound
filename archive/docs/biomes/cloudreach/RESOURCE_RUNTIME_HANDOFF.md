# Cloudreach resource preparation checkpoint — 2026-09-04

The six chapter materials now have real satchel definitions. Seven recipes join the
shared recipe book when `cloudreach_chapter_started` is earned by the arrival event:
heartwood boards, gale cordage, skyplume padding, axe/pickaxe bracing, a Sunleaf recipe
for the existing Ridge Tonic, and Cloudberry Trail Preserve. The preserve restores
35 satiety and gives 30% faster stamina regeneration for 240 seconds, or uses the
existing creature feeding/bonding path. No food grants wind immunity.

Camp boards/cordage/padding produce existing wood/fiber, so they immediately support
the existing tent/bedroll/creature-bed construction costs. This is the supported camp
preparation equivalent. A dedicated bridge kit, camp service upgrade, wind-resistant
equipment and a new weather-resistance stat remain deferred; no inert items promise
those effects. Skyplume is defined and useful for padding. Keeper Maela's first
completed creature trial guarantees two through the normal trainer-reward path,
so the padding is craftable without final Cloudreach creature art. The two
encounter-cycle roost sources remain deferred until that population is authored;
naturally shed feathers imply no hunting.

## Integration hook (world owner)

`scripts/world/cloudreach_resource_patch.gd` wraps the production `harvest_node.gd`.
It reuses its imported prop, interact prompt, tool swing, equipped-tool and durability
rules, all-or-nothing inventory grant, audio and world message. The wrapper keeps
Cloudreach's explicitly authored `world_day_regrow` policy separate from permanent
Meadows depletion: progression flags include realm, stable placement id and `Game.day`.
Reloading the same day preserves depletion; day advance creates the next crop. No save
format changes are required. The wrapper also implements `progression_restore` for a
mid-session load. Existing Meadows nodes are unchanged.

World placement is not performed by this package. From the Cloudreach world builder:

```gdscript
const RESOURCE_PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")

for spec: Dictionary in RESOURCE_PATCH.gatherable_nodes():
    var patch := RESOURCE_PATCH.new()
    patch.name = str(spec.id)
    resource_root.add_child(patch)
    # Resolve the chapter's intended surface, preserving stacked ledge height.
    # Do not use an unconditional highest-XZ terrain snap.
    patch.position = resolved_authored_position(spec.position)
    patch.setup(spec)
```

`gatherable_nodes()` reads the chapter's twelve `world_day_regrow` nodes and excludes the
two `encounter_cycle` Skyplume sources. Original coordinates, in metres:

| Placement | Resource | Authored X / Y / Z |
|---|---|---|
| cr_node_gale_fiber_gate | Gale Fiber | 180 / 210 / 620 |
| cr_node_cloudberry_waycamp | Cloudberry | -400 / 175 / 570 |
| cr_node_heartwood_west | Windworn Heartwood | -1080 / 390 / 1500 |
| cr_node_gale_fiber_bridge | Gale Fiber | -420 / 350 / 1420 |
| cr_node_gale_fiber_causeway | Gale Fiber | -245 / 390 / 1582 |
| cr_node_gale_fiber_anchor_picket | Gale Fiber | 30 / 435 / 2025 |
| cr_node_cliffglass_ravine | Cliffglass Ore | -600 / 420 / 2900 |
| cr_node_sunleaf_shrine | Sunleaf | 1200 / 1080 / 3100 |
| cr_node_heartwood_upper | Windworn Heartwood | -850 / 780 / 4300 |
| cr_node_cloudberry_cliffhold | Cloudberry | -500 / 820 / 4100 |
| cr_node_cliffglass_observatory | Cliffglass Ore | 520 / 900 / 4450 |
| cr_node_cliffglass_summit | Cliffglass Ore | -350 / 1080 / 5200 |

Presentation is tunable in `data/config/cloudreach_resources.json` and reuses installed
stylized-nature models with the shared harvest material corrections. Resource icons
reuse existing wood/stone/fiber/berry silhouettes and tints; no new asset provenance or
generation is introduced. In-world rendering, approachability, route density and blind
visual judgment remain part of the world integration checkpoint, not proven here.

## Verification and discovered defect

`test_cloudreach_resources.gd`, all `test_recipes.gd`, and `test_food.gd` pass together:
**58 tests / 629 assertions**. The first run exposed an existing crafting data-loss bug:
a full satchel spent costs and silently dropped an output. `Game.can_craft()` now tests
output capacity against an inventory copy after consuming costs. Tests cover both
refusal without spending and successful crafting when the consumed final ingredient
stacks free room. A test fixture also incorrectly serialized empty slots as dictionaries;
it now follows the real inventory save convention. Recipe source tests now exercise the
real chapter arrival event as well as existing dialogue/trainer reward sources, and the
Meadows material-limit test remains scoped to Meadows recipes.

The inventory and icon suites also pass: **50 tests / 591 assertions**, including
loading every inventory icon as an actual texture. Combined: 108 tests / 1,220 assertions.

`smoke_cloudreach_resources.gd` passes using the production live gather prop/prompt and
Game state: full bag refusal, exact payout, JSON-roundtripped depletion, no same-day
reload regrowth, and new-day regrowth. It calls `gather()` directly and does not claim
controller route evidence or write the owner's save file.
