# Whole-game visual review evidence

This is an audit snapshot supporting the ranked queue in [AUDIT.md](AUDIT.md),
not a second backlog and not a chapter acceptance claim. The owner requested a
whole-game audit after too much effort had gone into isolated locations.

## Build and review boundary

GitHub main was fetched and verified as `1ba253eb05aa728dd06424854d7523c5ce6e0068`.
Captures use `b2fe128ef8922debc635e44b8ae5aea230f660ed` on the owned
`tb/x04-cross-game-visual-sweep` checkout. This includes unmerged PR365's machine
hardware, Tidewake stations, Stormwood strike presentation, foliage fading and
timber filtering. It is **not a raw-main comparison**. The exact main-to-capture
file list, PR dispositions, frame hashes, dimensions and camera metadata are
preserved in [the evidence manifest](ranked-audit/evidence.json).

Godot 4.7 stable, Compatibility/OpenGL 3.3, GTX 1060 3GB; native 1920×1080.
The engine runs were serialized in the isolated visual checkout. Claude's
checkout and gameplay files were not changed for this audit. Native PNGs remain
under `shots/ranked-audit-current`; committed contact sheets are review indexes,
not substitutes for the native inspection. Driver and runner snapshots are in
`ranked-audit/` with their source hashes in the manifest.

## Coverage and limitations

The fresh matrix contains **508 native frames**: Meadows 36, Cloudreach 44,
Stormwood 41, Tidewake 76, creatures 183 and human cast 128. This covers 57
species and 41 humanoid entries, plus a separately assembled 89-item icon sheet.
All six engine processes exited 0. Five wrappers were clean; Cloudreach's
wrapper failed on the disclosed flag diagnostic. The Meadows manifest also
records a nonselected dynamic grazing-ground marker without a fixed stand;
it is not a failed selected environment capture.

| Sample | Native frames | Contact-sheet index |
|---|---:|---|
| Meadows | 36 | [Environment](ranked-audit/_sheet_meadows_env.jpg), [approaches](ranked-audit/_sheet_meadows_places.jpg) |
| Cloudreach | 44 | [Environment](ranked-audit/_sheet_cloudreach_env.jpg), [approaches](ranked-audit/_sheet_cloudreach_places.jpg) |
| Stormwood | 41 | [Environment](ranked-audit/_sheet_stormwood_env.jpg), [approaches](ranked-audit/_sheet_stormwood_places.jpg) |
| Tidewake | 76 | [Environment](ranked-audit/_sheet_tidewake_env.jpg), [approaches](ranked-audit/_sheet_tidewake_places.jpg) |
| Creatures | 183 | [Fronts](ranked-audit/_sheet_roster_front.jpg), [lineups](ranked-audit/_sheet_roster_lineups.jpg) |
| Human cast | 128 | [Bodies](ranked-audit/_sheet_cast_front.jpg), [faces](ranked-audit/_sheet_cast_faces.jpg), [lineups](ranked-audit/_sheet_cast_lineups.jpg) |
| Inventory | 89 icon entries | [All icons at 64 px](ranked-audit/_sheet_inventory_icons.jpg) |

Environment sampling includes both configured debug stands in every Meadows
band, Cloudreach region, Stormwood region and Tidewake island, with selected
major approaches. Meadows, Cloudreach and Tidewake have day/dusk/night samples;
Stormwood has Calm/Building/Break instead. Major approaches use the phases
selected by the existing parent capture tool and are not a complete phase matrix.

Region captures mount the production world and camera but stage travel flags,
clock, trainer and companion positions, pause encounters and hide HUD layers.
They are **dry-run visual samples**, not earned continuous journeys. Large
companions obscure some environment samples, and manual staging sometimes
produces dubious ground contact. Those observations require normal movement
confirmation before becoming gameplay defects.

The approach chooser's metadata saying “clear sightline” is not proof of a
visible destination. Meadows South Bridge, relay and stronghold samples and
Cloudreach shrine samples do not adequately show their named targets. They
remain useful terrain/composition evidence; they cannot prove missing assets.
Stormwood Hollow Crown019–021 faces a dark near surface; Crown037 and Hall038
do not show useful landmark subjects. Dynamo041 crops the crown and supports
only observations about the visible lower/core construction.
Tidewake's four selected approaches also do not establish recognizable named
destinations. Valid ordinary-route stands are needed before asserting absence;
the visible cut walls and ground/shore finish are independently reviewable.
Cloudreach produced its full image set but emitted an obsolete fixture flag
error, `unscoped flag: fly_tutorial_completed`; its wrapper returned failure.
That run is not clean execution or progression evidence.

Creature front/rear/45%-attack poses and human front/rear/face/lineups use a
neutral stage. A sampled attack below the stage floor is a strong inspection
lead, but root seating can contribute: verify in-world before choosing a rig
repair. These poses do not prove anticipation, recovery, locomotion or combat
readability. Human face crops are diagnostic close-ups, not ordinary camera
distance.

The inventory census has 89 definitions, 46 unique icon paths and no missing
icon files. Reused icons can fail identity despite existing on disk. Twenty-one
explicit world-model fields do not measure model completeness: runtime fallbacks
exist. See [source census](ranked-audit/source_inventory.json).

Uncovered by this new still matrix: interiors; every optional destination;
actual HUD/menu/controller flows; full combat and defeat motion; flight/swimming,
mounts and saddles; all held tools, camp pieces and 3D pickups in use; portal
entry/exit motion; earned finale transformations; co-op occlusion; Ally 15 W
telemetry. Existing scoped reports remain evidence for their own builds only.
These are coverage gaps, not passes or automatic asset-replacement orders.

## Independent findings

Reviewers saw current images, ART_DIRECTION and the approved key art,
Palworld references and chapter boards. They did not inspect implementation or
use the old defect list to choose their findings. Their frame-specific verdicts
are preserved separately:

- [Meadows](ranked-audit/meadows-verdict.md)
- [Cloudreach](ranked-audit/cloudreach-verdict.md)
- [Stormwood](ranked-audit/stormwood-verdict.md)
- [Tidewake](ranked-audit/tidewake-verdict.md)
- [Creatures](ranked-audit/roster-verdict.md)
- [Human cast](ranked-audit/cast-verdict.md)
- [Inventory and sampled props](ranked-audit/items-verdict.md)

All four region reviewers inspected their full native image sets. Roster review
covered all front/lineup sheets and 22 native outlier images; cast review covered
all entry sheets, every native rear/lineup view and selected native front/face
witnesses. The packet contains 508 frames; that does not mean every creature
attack/rear and human front/face was independently enlarged. Individual reports
state their scope. The roster's stronger existing identities should be retained;
the broad repair priority is surface/value coherence, with severe diagnostic
attack intersections sent to urgent in-world confirmation.

## Reconcile already-produced work before commissioning more

GitHub status at this snapshot:

| Subject | PR disposition | What it establishes |
|---|---|---|
| Meadowhart replacement | #318 merged | Current roster includes the replacement; retire the stale claim that main still contains the old body. Whole-scene acceptance remains separate. |
| Veilfall cascade | #322 merged | Current Tidewake contains the cascade slice; cliff/terrace massing remains independently judgeable. |
| Meshy realm portals | #328 merged | The requested generation exists on main; this audit does not close all portal views or transitions. |
| Cast shading and six stat-drink icons | #331 merged | Evaluate current shading/icons rather than repeating the old emission diagnosis. Geometry/identity are separate. |
| Aviary architecture | #338 merged | The architecture slice exists in current frames; the fresh reviewer still finds broader landmark form below the board. |
| First Shore fence/current | #329 open draft | The fence retirement is not in this capture; water readability remains open. |
| Attack grounding/hit treatment | #342 open draft | Fresh current-stage findings do not include this candidate. Compare it before duplicating work. |
| Steep Meadows terrain | #352 open draft | A candidate exists; it does not establish a cross-region terrain solution. |
| Shared Meshy bottle and six badges | #355 open draft | Already generated; candidate family is promising. Merge/disposition and pickup-distance verification come before another bottle generation. |
| Cloudreach night lighting | #363 open draft | Existing candidate, not present in these frames. Compare its scoped result before changing the same lights. |
| Cross-game visual slices | #365 open draft | Included in this capture; local passes do not close their broader categories. |

## How the ranking should change the work

Rank the recurring whole-scene and subject failures by visual severity and
exposure, then work through a representative repair that can extend to its
family. Do not rank by easiest implementation or by the number of tiny props
that can be changed. Preserve the appealing creature identities, coherent
cottage family and strong existing route silhouettes.

Terrain and vegetation need geometry/material/distribution work using coherent
installed families. Hero models whose form cannot meet the reference need the
authorized reference-backed Meshy workflow. A texture, tint or extra prop is
not a substitute for missing form. Two failed polish iterations trigger a
different asset or approach, as ART_DIRECTION requires.

Every batch must end with matched native gameplay views, an independent
reference comparison and the relevant motion witness. A new local pass should
remove or narrow a named queue defect; it must not silently become a whole-game
Bar A/B pass. Claude retains merge ownership.
