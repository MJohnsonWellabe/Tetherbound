# P2-005 ground-cover source scope

P2-005 is the next Codex-owned, nonclosed impact row in catalog order after P2-003 (impact 36). This is a source investigation only; no visual candidate, verdict, score, status, or closure is claimed.

## Current evidence boundary

The blind baseline follow-up supports repeated thin grass and pale flower patches in three broad views: the Stronghold approach, the Burrow Warrens approach, and Old Mill Crossing. None of those retained broad-survey frames has an exact catalog sighting ID, so the row still needs the catalog's own matched High and Medium views.

Exact matched evidence requested by the survey audit:

- `meadows__band5_stronghold_approach__09__stronghold_approach__day__approach`
- `meadows__band2_stone_and_root__04__the_burrow_warrens__day__approach`
- `meadows__band3_the_river_lock__06__old_mill_crossing__day__close`

The audit lists no retained exact High or Medium receipts for these IDs.

## Source candidate (OFF)

Do not repeat global flower-density or noise tuning. `data/config/grass_field.json` records five prior tuning rounds whose flower-pixel variation moved within measurement noise, because that camera-relative field does not control the baked broadleaf groundmat/bush layers. The catalog source audit identifies a different, bounded first candidate: concentrated low nature-family colonies along village shoulders. Keep any candidate OFF until it has matched native High/Medium captures and blind review. A village-only result would not close the three regional sightings or establish full-Meadows coverage.

Implemented OFF at `data/config/props.json` and `scripts/world/props.gd`: twelve installed stylized-nature meshes form three uneven four-piece colonies between north-row houses, sampled from the production terrain at each authored point. `props.gd` forces these review entries to visual-only, so they add no collider. Each scaled mesh is 0.40–0.45 m tall; its glTF bottom sits 1 cm or less below the sampled ground. The closest bound remains 2.75 m beyond the road's paved-plus-shoulder envelope and 3.86 m from the nearest authored north-row workshop collider. Both the P2-005 colony flag and both P2-003 candidate flags remain OFF.

The native-ready A/B recipe and asset/bounds ledger are in `CAPTURE-PACKET.md`. It reviews the village-shoulder candidate only. The catalog's three exact regional sightings still need matched High/Medium before/candidate captures and blind review; this village-only source does not close or re-score P2-005.
