# Stormwood insulated gear — receiver mitigation

Date: 2026-09-09  
Status: focused production candidate; no full-world or campaign run

## Contract and reproduced gap

`docs/biomes/stormwood/BUILD_STORMWOOD_TO_COMPLETION.md` lines 446–453 and
799–802 require every worn insulated piece to reduce strike damage and Static
duration, while the complete four-piece set leaves only the stagger. The item
database already authored both values on all four pieces and
`stormwood_surge.json` already authored the complete-set count as four.

The negative control used the shipping lightning receiver plus the real ItemDB
and PlayerEquipment with `insulated_vest` equipped. It failed exactly the two
new expectations: health was 80 instead of 84, and Static lasted 8 seconds
instead of 6.4. Receipt:

- `.artifacts/stormwood-insulation-0909/negative-control`
- 2026-09-09T16:46:37.5075339Z–16:46:38.9322653Z, PID 14836, exit 1,
  Godot remaining 0
- 14 assertions, 2 failures
- the two assertion errors appear in both `engine.log` and `stderr.log`; these
  are duplicate sinks for the same two failures

## Production behavior

`PlayerEquipment.storm_mitigation()` reads only definitions in the five worn
slots. It identifies insulating equipment from the two authored fields rather
than from hard-coded item IDs. Strike reductions add and are clamped; Static
duration scales multiply. Reaching the configured complete-set count overrides
both result scales to zero.

The lightning host still decides the hit and publishes its unchanged regional
base effect. After impact-ID replay rejection and local-peer addressing, the
receiver reads local worn equipment and computes:

`min(host_damage, max_health * 0.25) * damage_scale`

This preserves the existing health cap before applying armor, including for a
low-max-health trainer. Static uses the resulting multiplicative duration
scale. A zero duration skips creation of a new Static buff and does not clear
an existing buff. Velocity stagger remains unchanged. Inventory alone provides
no protection, remote-addressed events do not touch local vitals, and fall
defense does not enter lightning math.

The four item descriptions now state the wired per-piece values and the
complete-set stagger-only result in both item sources.

## Focused verification

The lightning fixture is a real initialized SceneTree child. Its test subclass
only bypasses production dependency discovery because world, session, and surge
are injected before it enters the tree; production `_receive()` therefore has a
valid `/root/Game` lookup.

- `.artifacts/stormwood-insulation-0909/fixed-lightning-final`
  - 2026-09-09T16:55:31.4104774Z–16:55:33.0005134Z
  - exit 0, Godot before/after 0, 24 assertions, 0 failures
  - covers unchanged host verdict, no-gear duplicate replay, real worn vest,
    full-set health/no-new-Static/stagger, one-piece unequip, remote-addressed
    ignore, and low-max-health cap ordering
- `.artifacts/stormwood-insulation-0909/fixed-equipment`
  - 2026-09-09T16:52:27.7949479Z–16:52:29.2355403Z
  - exit 0, Godot before/after 0, 24 tests, 279 assertions, 0 failures
  - covers real definitions, additive/multiplicative aggregation, configured
    count override, unworn inventory, existing armor/fall behavior, and the
    Stormwood item/recipe payload

Both fixed console and Godot logs contain zero `ERROR`, `SCRIPT ERROR`, or
`WARNING` lines. `git diff --check` passes for all scoped files.

## Scoped files

- `scripts/player/player_equipment.gd`
- `scripts/world/stormwood_lightning.gd`
- `tests/helpers/stormwood_lightning_cases.gd`
- `tests/smoke_stormwood_lightning.gd`
- `tests/test_player_hp.gd`
- `data/items/items.json`
- `data/config/stormwood_items_recipes.json`

No session, network, world-placement, combat, or host hit-selection source was
changed.
