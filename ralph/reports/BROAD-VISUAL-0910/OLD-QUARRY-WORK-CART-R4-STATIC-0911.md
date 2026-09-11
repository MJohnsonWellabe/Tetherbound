# The Old Quarry R4 — extraction-wagon static candidate

## Candidate

The production arrival already exposes the quarry floor after the creature and
deadfall corrections, but its authored work story remains almost entirely below
waist height. A single installed `Prop_Wagon` now sits on the west side of the
worked floor, turned toward the haul road. Its first shoulder site disappeared
against the far-left trees in production R4, so the retained candidate moves it
three metres inward, raises it from 1.15 to a restrained 1.25 scale, and turns
it across the view after the aligned first yaw read as another fence. It uses
the same medieval prop family as the village and Highfield, stays within 20 m of
the quarry anchor, and remains at least 8 m from each accepted route corridor.

The wagon adds no resource, interaction, progression, light, terrain, vegetation,
scatter or creature change. Existing foundations, Rootstone, crates, tools,
deadfall, pylons and conduit remain untouched.

## Owned paths

- `data/config/bands/band2_stone_and_root/props.json` — one prop inside the existing
  `quarry_station` cluster.
- `tests/test_old_quarry_visual_identity.gd` — identity, scale, proximity and route
  clearance contract.
- `tools/capture_old_quarry_visual_identity.gd` — fresh R4 output directory only.
- this report.

Production capture and final disposition remain required. Retain only if the wagon
reads as quarry extraction equipment at ordinary arrival distance without hiding
the pylon line, foundations or route.
