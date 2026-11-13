# ARM: Stormwood swing 3 (umber road + one thin gold line), LANE-PLACES, 12 Nov 2026

Branch `tb/places`. Flags ship OFF; `overlay.json` turns on `road_value_1112` and `thin_1112`.

## Why
Two GPU rounds bracketed the road charge on the umber road. The umber road itself won twice against the black slab (3/3). The shipped line lost contrast and lost F41#4 (`G-places-roadvalue`); a brighter, branching line lost F41#12 by 0.71 as "thick, bright, saturated gold stripes" (`G-places-swing2`). Judges ask for one thin line and no branching.

## Change
- `road_value_1112` (unchanged, judged): cool dark-umber road, softer road-to-moss blend, lifted pools; no puddles.
- `thin_1112` (`stormwood_road_current.json`): one continuous thin line. No hairline web (0.08 → 0), a small halo (0.07 → 0.04), core 1.25 → 2.2, width and breakup about as shipped (0.026, 0.6). `contrast_1112` is removed.
- **The line stays yellow-gold.** That colour is an owner direction (WO-F09-04). The judges' white-violet suggestion is an owner decision and is raised in the lane NOTE, not taken here. The shader is additive, so a dark edge is not possible without new shader work; not attempted.

## CPU proof (`_sheet_cpu_base_vs_arm.jpg`: F41#4 fallen_giant, lantern_pools, crown_overlook; base row, then arm row)
The arm shows the umber road with one thin gold line, about as visible as base's line is on the black road, and no web or stripes. Round 1 of this candidate (narrower, more broken) made the line vanish and was replaced.

## Not in this arm
The recolour of the salmon bears and the pink or copper distant tree cards, and the layered treeline. Bears are creature art (LANE-THINGS). `fading_clear_1112` is dropped from the overlay: GPU Fading on main is already brighter than Building once the Break-only fix (#919) is in.

## Reject if
Gold stripes or a repeated pattern on the road; a line that cannot be seen; a dry-sand or salmon road.
