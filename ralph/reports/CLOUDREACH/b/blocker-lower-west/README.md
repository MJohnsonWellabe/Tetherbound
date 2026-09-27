# Cloudreach-B blocker: lower-west anchor route obstructed (main 32bd3307)

Four independent runs of the continuous normal-input route all stop in stage `lower_west_anchor`. They ran as the four Cloudreach-B witnesses (F06#1, F06#2, F06#3, and F08#0 with `--live-combat`), each extending `tests/smoke_cloudreach_continuous.gd` unchanged. The runs used local Godot 4.7, headless, with `--accelerated`, starting from the committed completed-Meadows fixture. The route failed before reaching any witness-specific step.

- Three runs stalled or timed out at about (-129.1, 205.6, 704.4) while walking the authored route toward (-260, 235, 790).
  - The recorded wall contact is `/root/CloudreachCliffs/AuthoredRoutes/LowerOverlookLoopCliffShoulders/Ridge002RockShoulder38/VegetatedGeologicalShelf2/Collision` at (-128.4, 205.5, 704.5).
  - Its normals are about (0.01, -0.48, -0.88): an overhanging shelf over the route.
- The fourth run fell below the authored segment toward the same target.

Per-run rows are in `*.fail.log`. This is a product or scene-generation change (cliff shoulder dressing on the lower route). The Cloudreach-B lane does not own it, so it was raised as a SHARED-FILE REQUEST to the coordinator. None of F06#1, F06#2, F06#3 or F08#0 can produce a witness result until the route is walkable again.
