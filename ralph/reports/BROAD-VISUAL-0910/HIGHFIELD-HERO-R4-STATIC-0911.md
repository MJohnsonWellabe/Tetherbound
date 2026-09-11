# The Highfield hero composition R4 — static compression candidate, 2026-09-11

## Outcome

**Static candidate only; visual verdict withheld.** R3 production evidence proved the
pasture clearing and the individual herd and gate/camp reads, but the broad views left
the working threshold as a small ridge detail while the close pair dropped the herd.
R4 addresses that measured composition gap without a new asset, encounter move, route
change, clearing, scatter bake, or production render.

## One bounded change

The existing drove gate and visual stock-camp scenery move 12 m south, from the
`z ~= 5892..5908` group into the already-served `z ~= 5879..5896` middle plane. The
canonical herd-facing stand at `(400,5832)` is therefore about 54 m from the south
gate rail instead of 66 m, an 18% distance reduction. The ordinary herd centre at
`(377.5,5855.3)` and bull at `(425,5844)` are unchanged.

The installed timber rails rise from scale `1.25` to `1.4`, the existing wagon from
`1.35` to `1.6`, and the generated-camp tent from `1.45` to `1.7`. The ordinary warm
fire receives a smaller corresponding lift (`0.42 -> 0.5`, glow `1.35 -> 1.55`). This
strengthens the three silhouettes that must survive the herd-facing distance without
reintroducing R2's rejected arrow-like pennants or adding faction colour.

## Preservation measurements

- The gate opening remains 15 m between the nearest west/east prop centres; the stock
  lane is not closed.
- Every visual camp prop remains at least 35 m from both unchanged encounter centres.
- The moved scenery stays within the overlap of the existing Highfield sightline lens
  `(407,5877) r25` and camp clearing `(420,5891) r12`; no vegetation authoring or bake
  is required for this candidate.
- The Band 4 spine runs east of the group. Moving south increases rather than reduces
  route separation, and the focused contract retains the 8 m minimum.
- The functional `highfield_stockcamp` remains at its authored rest site about 280 m
  away; this group remains scenery and adds no interaction.

## Evidence and validation contract

`tools/capture_highfield_hero_identity.gd` now targets an R4 output directory and the
compressed middle plane, retaining matched day/night pairs and production-world
grounding/displacement checks. Its manifest additionally records distance to both herd
centres. No production renderer was started for this static lane.

The focused Highfield tests pin the compressed gate plane, herd-facing distance,
strengthened wagon/tent silhouettes, open lane, route clearance, unchanged herd
centres, and encounter separation. A fresh six-frame R4 production receipt is required
before promotion from POLISH to PASS.

Focused validation completed on the static candidate:

- `test_highfield_hero_composition.gd`: 6 tests, 98 assertions, zero failures.
- `test_highfield_visual_identity.gd`: 1 test, 6 assertions, zero failures.
- `capture_highfield_hero_identity.gd`: Godot `--check-only`, exit 0.
- `props.json`: PowerShell JSON parse successful.
- Owned diff: `git diff --check`, no whitespace errors.
