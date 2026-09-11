# Old Wind Observatory R1 — static candidate handoff

Status: **awaiting focused test, production render and independent judgment**.
This static lane makes no POLISH or PASS claim.

## Candidate

Current evidence shows a strong altitude panorama but almost no named observatory:
only a sliver of apparatus appears while hard overlapping cloud cards and banded
cliffs dominate. The production landmark itself is a plain cylinder, flattened dome,
spire and single bar.

This location-specific, collisionless presentation keeps that tower as its core and
adds:

- a 30 m paved compass/dial court that replaces the anonymous grass immediately around
  the tower;
- eight masonry ribs and three cornice courses to break the cylinder into architecture;
- a three-axis bronze/cyan armillary crown with four braces and a focal wind-reading
  core;
- four wind standards, three keeper instrument stations and visible sighting tubes;
- four restrained warm night pools; and
- four wind-shaped trees plus six rocks around the supported crown edge.

The dedicated capture uses three supported close-crown approaches. The shared cloud sea
remains visible as altitude context, but can no longer substitute for the landmark in
the acceptance frame. This is local composition mitigation, not a claim that the shared
cloud-card art is fixed.

## Preserved contracts

- landmark and survey target: `[430,920,4500]`;
- 38 x 36 m `ObservatoryWalkableCrown` and all production collision;
- `upper_plateau_circuit` grounded route and its unlock;
- observatory updraft/lift and Fly access;
- side-aerie survey approach and completion flag;
- potion pickup override and map marker; and
- encounters, progression, terrain and actor transforms.

## Required mount hook

Root should add the following constant beside the other Cloudreach location-specific
presentations in `scripts/world/cloudreach_world.gd`:

```gdscript
const OLD_WIND_OBSERVATORY_PRESENTATION := preload(
	"res://scripts/world/cloudreach_old_wind_observatory_presentation.gd")
```

Then replace the existing observatory branch body:

```gdscript
elif landmark_id == "old_wind_observatory":
	_build_observatory(landmark)
```

with:

```gdscript
elif landmark_id == "old_wind_observatory":
	_build_observatory(landmark)
	var observatory_identity := OLD_WIND_OBSERVATORY_PRESENTATION.new()
	observatory_identity.name = "OldWindObservatoryPresentation"
	landmark.add_child(observatory_identity)
	observatory_identity.build(_materials, simulation_only)
```

## Static validation and next gate

The JSON parses as one Cloudreach/observatory package. All authored tree, rock, banner,
lantern and instrument seats remain inside the supported 38 x 36 m crown. The script
contains no `CollisionObject3D`, `CollisionShape3D`, `StaticBody3D`, `Area3D` or gameplay
interaction. `git diff --check` is clean.

Per brief, this lane did not run Godot, rendering, stage or commit. After adding the
mount hook, run `test_cloudreach_old_wind_observatory_presentation.gd`, capture all six
production frames with `capture_cloudreach_old_wind_observatory.gd`, and obtain an
independent verdict. Reject or iterate if the armillary looks like raw rings, the tower
still reads as a primitive cylinder, the dial swallows the player scale, edge ecology
floats, clouds dominate, or night becomes four isolated light blobs.
