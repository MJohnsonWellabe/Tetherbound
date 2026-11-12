STATUS: land

# READY: paving_scale_1112 ON, scoped to the Realm Gate road stands (LANE-PLACES, 12 Nov 2026)

Branch `tb/places-gatepaving-land`, cut from current main.

## Verdict
GPU High, `G-places-gatepaving.md` (tb/item-scout-1108 555ebf04), three code-blind judges: **SPLIT** as one flag.
- F40#0 realm gate: clear 5.78 → 6.71 (+0.93), rain 5.60 → 6.39 (+0.79), 3/3 each.
- F40#1 row (grass stands, no path): 5.46 → 4.85 (−0.61), 0/3: the small stones are "a faint flat grey smear".

## What lands
The fix **only at the stands on the dirt road** (`stands`: gate_road_approach, gate_road_close, f40_gate_road). Every other stand keeps the shipped pieces, so the F40#1 frames are as on main (no loss). This scoped form was not itself GPU-judged: the road frames are the judged winners unchanged, and the grass frames are main.
- `data/config/cloudreach_f40_items.json`: `paving_scale_1112` ON with `_why_on` and `stands`.
- `scripts/world/cloudreach_settlement_life.gd`: the size and sink override, by stand.
- `tests/test_places_gate_paving.gd`: pins.

## CPU check of the scoped form
Realm gate approach (matrix piece 3): small flush stones on the path. F40#1 Realm Gate Crag landmark approach: 2.2% of pixels differ from main (grass motion), no stone change.

## Tests
`--only=places_gate_paving,cloudreach_settlement,f40_items`: see the lane log; all pass.

## Still open at the gate (judges)
The orange path is too saturated and its edges are not blended into the grass; rain has no wet darkening or sheen. F40#1 needs ledges and terraces (terrain or new art).
