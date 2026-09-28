# P2-117 disposition

**Deferred. Owner: Shared combat/UI gameplay owner, with Cloudreach reproduction.** No fix or visual acceptance is claimed.

The HUD gives its 1.8-second failed-catch message precedence over aiming; the capture immediately forces the target to low HP for its second throw. Normal-input timing evidence is needed before changing the message update rules.

## Evidence and source audit

scripts/ui/combat_hud.gd::_on_catch_resolved sets _miss_left=1.8 after failure, and _draw_grid displays that message ahead of the aiming branch. tools/phase2_capture_catch.gd immediately tops up and sets foe HP to 6% before sequence B, while also forcing catch chance. This is consistent with the photographed stale advice but does not measure how long it persists when the player weakens the target through attacks. It does not invalidate the observed overlap.

Original capture IDs and reproduction provenance remain in `../../catalog.csv` and the biome manifest. This disposition preserves the unresolved defect; source inspection is not a visual PASS.

## Required follow-up

Record a continuous ordinary-input failure, weakening and re-aim sequence. The combat/UI owner should decide the update/clear trigger and verify both failure advice and current chance feedback. Timing and state changes are outside this presentation-only lane; no behavior change is claimed.
