# P2-023 — exposed landform edges

Disposition: **deferred**, owner **Cloudreach terrain-art lane**, with the Cloudreach gameplay owner responsible for any crown/collision change. No fix or visual acceptance is claimed.

The fresh native chapter baseline at game source `0f2303feb` retains ruler-straight cliff lips (row 01), abruptly ending gate masonry/platform contact (04), large nearly planar banks (07), repeated angular shelves (08), and sharp terrace joins (25). The independent regional review rejects the landform and ground-transition treatment. Obstructed shrine views do not establish the entire island underside's shape, and the lower resolved capture stands are not proof of a gameplay fall.

Evidence: `../p2-022/regional-baseline-judge.md` and `../p2-022/baseline-full-matrix/`; original island/High Perches sightings remain in `catalog.csv`. The native baseline was reviewed independently. Regional Bars A/B: No/No.

Source audit at `bf696ddb8`: `cloudreach_world.gd::_mesa` is shared by region cliff masses, transitions, route ledges, rock shoulders and landmark ledges. It already builds jittered upper/lower wall rings and embedded shelves. Only airborne `LandmarkLedge` masses enter `_emit_mesa_root`; normal region masses do not. The walkable crown is emitted separately for collision, while some crowns use `_carve_mesa_top` to preserve routes. This is not a single absent underside flag, and the original recurring defect combines several geometry roles.

Next work: identify each offending visible mass from the original authored approach/flight repro; revise visual wall/root profiles and contact dressing across those roles; keep the rendered walkable crown and collision agreement intact; compare all affected silhouettes and daylight/night views. Any crown or route-footing change requires the gameplay lane and traversal regression evidence. No geometry candidate is enabled by this disposition; the separate P2-021 skyline candidate failed to address the near/middle-ground defect and remains off.
