# P2-118 disposition

**Deferred. Owner: Shared catch/menu UI lane, with Cloudreach reproduction.** No fix or visual acceptance is claimed.

The catch-to-full-party panel transition needs a joint HUD-layer and instruction-contrast pass. A static frame cannot distinguish persistent layering from the transition; no paired presentation fix has been validated.

## Evidence and source audit

The original 09-caught-banner frame follows a forced successful throw into a full five-member party. _one_throw waits BEAT_FRAMES, captures the verdict and waits 70 physics frames before returning; the caller then waits another 30 physics frames before 09-caught-banner. These are fixture frame waits, not a measured ordinary-play modal transition duration. game_menu.gd::open calls _set_world_hud_visible(false); the catch result HUD and the creatures-tab release ceremony also have their own visibility/timing paths. The existence of that hide call does not disprove the photographed overlapping layers. tab_creatures.gd overrides menu footer instructions during choose/confirm; changing a single global background alpha would not establish the full transition and instruction hierarchy.

Original capture IDs and reproduction provenance remain in `../../catalog.csv` and the biome manifest. This disposition preserves the unresolved defect; source inspection is not a visual PASS.

## Required follow-up

Capture normal full-party catch through choose, confirm and return, including controller focus, and inspect the shared menu/combat layers together. Improve the panel backing and instruction contrast without changing the five-owned rule, release confirmation, input ownership or save transaction. Validate readable 1920x1080 before/after states independently. No UI acceptance is claimed.
