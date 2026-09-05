# Cloudreach camp creature recovery — 2026-09-05

## Scope

The five Cloudreach chapter camps now carry explicit creature-bed data in
`data/config/cloudreach_chapter.json`. The physical runtime passes that bed
only when the camp's `services` includes `creature_recovery`, while preserving
the shared player rest and craft payload. The existing installed `Bed_Twin1`
asset remains camp dressing for the trainer; the runtime offsets it to its own
side of the camp and leaves the creature pad on the authored recovery point.

Beds use the reserved negative namespace and are intentionally stable across
data ordering:

| Camp | Bed index | Bed [x, z] |
| --- | ---: | ---: |
| Galefoot Waycamp | -21 | [-276.5, 523.0] |
| West Causeway Refuge | -22 | [-756.5, 2053.0] |
| Windscar Flight Aerie Camp | -23 | [391.5, 3261.0] |
| Cliffhold Commons | -24 | [-336.5, 3973.0] |
| Summit Bivouac | -25 | [-516.5, 5303.0] |

The reserved range is `<= -10`; player-built beds remain numbered from zero
and the Meadow authored beds occupy a separate stable range. No save format,
party healing call, inventory rule, or visual asset was changed.

## Verification

`tests/test_cloudreach_camp_recovery.gd` checks all five authored records,
unique reserved indices, separation from each camp's player-rest/dressing
centre, and the runtime opt-in payload. The input fixture
`tests/smoke_cloudreach_camp_recovery.gd` builds the production Cloudreach
scene, assigns a fainted member through the creature-bed controller prompt,
passes the night through the ordinary camp rest prompt, and checks that the
bedded member revives while an unbedded half-health member keeps its HP.

## Evidence run

The focused unit run passed **2 tests / 46 assertions**. The one-world
production fixture was then run with all five camp unlock flags seeded. It
passed the following for every camp: node and creature-bed construction,
bed-to-rest-centre separation, and real collision floor rays under both the
camp and its creature bed. It then used controller input at Galefoot to assign
a fainted member, used the ordinary player-rest prompt to pass one night, and
passed the bedded revival / unbedded HP-preservation checks.

```text
CLOUDREACH CAMP RECOVERY PASS
```

The captured Godot log is
`ralph/reports/CLOUDREACH-CAMP-RECOVERY-0905.log`.
