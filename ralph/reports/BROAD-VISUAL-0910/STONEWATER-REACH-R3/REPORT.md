# The Stonewater Reach R3 — production disposition, 2026-09-11

The R3 production capture completed eight of eight 1280x720 frames with no
manifest failures. It uses the production Meadows scene, live terrain and
authoritative scatter. The evidence harness now suppresses the gameplay HUD and
freezes player motion so the route views are stable and unobstructed.

## Disposition

**RETAIN AS POLISH; not a hard PASS.** The asymmetric relocation of the three
existing overlook boulders opens the south-west sightline to the authored water
course and gives the rock group a clearer size hierarchy. It introduces no
visible route obstruction or isolated edge rock.

The deeper location gap remains visible: the existing Stonewater surface is
flat and cyan, and ground cover intersects it. The rejected R2 water-card and
wet-bank experiment was removed completely because it amplified those defects.
A credible correction requires the shared depth-aware water/terrain/vegetation
pipeline rather than another decorative mesh local to this landmark.

Focused validation: 6 tests, 34 assertions, zero failures; production composer,
test and capture scripts all pass Godot check-only validation.
