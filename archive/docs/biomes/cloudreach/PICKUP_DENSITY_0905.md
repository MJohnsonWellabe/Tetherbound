# Cloudreach world-pickup density — 2026-09-05

Cloudreach now contains exactly **100 Candy world placements** and **75 recovery world placements**. These are physical placements, not reward quantities or item-stack counts. The chapter also retains its three canonical TM pickups, for 178 pickup rows total.

## Distribution

Every added row has a stable `cr_pickup_density_*` ID, `count: 1`, explicit XYZ coordinates, `persistent: true`, and `one_time: true`. The original 19 rows and the 19 runtime position overrides remain unchanged.

| Region | Good | Great | Rare | Small potion | Large potion | Revive | Speed mushroom | Stamina mushroom | Wild mushroom |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Gate / lower cliffs | 10 | 2 | 0 | 6 | 0 | 2 | 1 | 1 | 0 |
| Broken Causeways | 15 | 6 | 1 | 7 | 2 | 3 | 1 | 1 | 1 |
| Windscar Ravine | 10 | 5 | 1 | 5 | 1 | 3 | 1 | 2 | 1 |
| High Roost / Sky Shrine | 5 | 5 | 2 | 3 | 2 | 2 | 1 | 1 | 1 |
| Upper Cloudreach | 12 | 9 | 3 | 7 | 4 | 4 | 1 | 0 | 1 |
| Summit / final stronghold | 8 | 3 | 3 | 2 | 3 | 4 | 0 | 0 | 1 |
| **Total** | **60** | **30** | **10** | **30** | **12** | **18** | **5** | **5** | **5** |

Of the 159 added placements, Candy is divided across route verges / optional loops / Fly-only pockets as **33 / 42 / 17**. Recovery is divided **31 / 26 / 10**. Fly-pocket rows retain the real Fly-unlock requirement; upper-route placements use the existing chapter unlock where appropriate. New placements are at least 7.5m apart within a region and at least 7.5m from configured interaction, camp, and battle-road anchors.

## Persistence and verification

No alternate pickup system was introduced. The existing `CloudreachPhysicalRuntime` uses the row position when no canonical override exists, constructs realm-qualified cache flags from each stable placement ID, and uses the shared low-cost pickup glow. Collection of one new item does not remove a neighboring placement of the same item; rebuilding the runtime removes only IDs already collected.

Validation on the locked Godot 4.7 executable:

- check-only: pass;
- density/runtime/item-cache/glow/save selection: **92 tests, 7,754 assertions, 0 failures**;
- production surface audit: **215 physical placements checked, 0 failures**;
- focused production unlock/collection/rebuild smoke: **pass**.

## Rendered audit and cost

Real Windows/OpenGL Compatibility evidence was captured at 1280×800 on an NVIDIA GeForce GTX 1060 3GB. The canonical chapter views remain unobstructed, and the existing ground-level two-draw glows make pickups readable without adding loot beams. The dedicated upper-observatory evidence frame places the avatar directly over one mushroom and several other density close-ups are wider than ideal; that is a capture-framing limitation, not evidence of a route obstruction.

Compared with the Round 7 capture from the same machine and cameras:

| View | Draw calls | Primitives | Mean | p95 | p99 |
|---|---:|---:|---:|---:|---:|
| Arrival | +89 | +189,817 | +0.743ms | +1.125ms | +0.892ms |
| Galefoot | +203 | +248,435 | +0.916ms | +0.682ms | +0.990ms |
| Final arena | +19 | +40,737 | +0.026ms | +0.032ms | +0.024ms |

The density capture measured sustained p95 values of **11.364ms / 12.189ms / 8.438ms** at arrival, Galefoot, and the final arena respectively. This comparison also includes intervening continuous-route world changes after Round 7, so it is a conservative same-camera checkpoint comparison rather than a pickup-isolated A/B.

Canonical evidence: `ralph/reports/CLOUDREACH-PICKUP-DENSITY-0905/contact-sheet.png` and `performance.json`. Raw frames remain local and uncommitted.
