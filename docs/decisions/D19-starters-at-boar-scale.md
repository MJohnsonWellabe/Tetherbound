# D19 — The size band rises again: starters at boar scale

**Status:** accepted, by the owner
**Decided:** during the creature-size pass that shipped the wild spawn table

## The decision

D12's peer band moves up a second time. Starters now stand **1.90–2.00 m** —
boar scale beside the 1.8 m trainer — and the wild roster runs **1.35–2.15 m**
around them. Veridian stays at 2.60 m, still above everything.

| | D12/R0.7 | D19 |
|---|---|---|
| Terrapup | 1.70 m | **2.00 m** |
| Ripplet | 1.60 m | **1.95 m** |
| Galewisp | 1.55 m | **1.90 m** |
| Pipwing (smallest) | 1.20 m | **1.35 m** |
| Bramblebun | 1.35 m | **1.50 m** |
| Tuskroot (largest wild line) | 2.00 m | **2.15 m** |

Every other species moved the same direction; `data/pals/species.json` is the
full table.

## What carries over unchanged

- **Radii scale by the same ratio as height**, D12's own rule, so nothing gets
  easier to hit relative to its own size and the catch formula's accuracy
  bonus keeps its tuning.
- **D13's relative ordering.** Pipwing and Bramblebun stay the smallest pair;
  Meadowhart, Galecrest and Tuskroot stay the largest tier.
- **D17.** Mudsnout 1.55 m → Tuskroot 2.15 m is still strictly increasing, and
  `tests/test_evolution_links.gd` still enforces it.
- **The sheets' biology figures.** Game scale and creature biology remain
  allowed to differ, exactly as D12 established.
