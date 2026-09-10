# Basal grass leaves: withdrawn

Six low, spreading triangular leaves were added beneath the shared procedural
tuft. The candidate reused all four biomes' existing placement, masks and
clearances; it added geometry without increasing instances or draw calls.
The far tuft thinned the added leaves with its existing blade LOD.

The first focused run failed two assertions: one tip did not reach the intended
20 cm radius, and the far mesh retained all six leaves. The revised geometry
corrected both. `basal-lod-alpha-import-policy-first` passed 25 tests and
88,387 assertions, including the existing grass and texture-import suites,
with no engine errors. This is geometry/integration evidence, not visual success.

Native captures all completed cleanly:

- Stormwood: six rows in `broad-platform-basal01`, 64 seconds. These also
  contain the independently proven creature platform-transfer fix.
- Water: two Gull Rest rows in `broad-basal01`, 37 seconds. The additional
  `reedhaven_village` filter matched no catalogue row; no Reedhaven proof is claimed.
- Meadows: four Grandpa/South Bridge rows in `broad-basal01`, 96 seconds.
- Cloudreach: two Gate Crag rows in `broad-basal01`, 118 seconds.

Blind Gull Rest comparison found effectively unchanged coverage. Blind South
Bridge comparison weakly preferred the fuller local foreground but found no
meaningful overall improvement. Both remained below commercial quality.
Root's Cloudreach inspection likewise still showed the dominant bare centre
and distant green surfaces; no independent Cloudreach verdict is claimed.

The candidate was withdrawn after these two independent no-progress results.
Its exact tracked-source patch is
`.artifacts/broad-visual-0910/grass-basal01-held.patch`; the focused test and UID
are preserved under `.artifacts/broad-visual-0910/held-tests/`. Both forward and
reverse patch checks passed around withdrawal. Existing retained grass clump02
is unchanged. No additional shape iteration is scheduled.

Neutral mapping: Gull Rest F01/F02 are the retained rim01 baseline, F03/F04
are basal01. South Bridge F01 is basal01 and F02 is retained clump02. All
original captures and negative verdicts remain available.
