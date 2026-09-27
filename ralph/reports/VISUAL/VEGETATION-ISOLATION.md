# Cloudreach vegetation layer isolation

Diagnostic evidence for Claude's existing-asset placement lane, under the
owner's revised split. No production vegetation change or acceptance claim.
The proposed grounding resolver was removed from the worktree before integration.

Build `f8b07a0814308b1bf08f8b9f88a19b6f46014209`, main `ddaf7a7bd` integrated.
Godot 4.7 Compatibility, hardware GTX 1060, 12 native 1920×1080 images, exit 0,
zero skips. The adapter uses the production camera and seated diagnostic stands,
with hidden HUD and companion parked behind camera. It toggles one layer at a
time and restores visibility after every image. These are isolation images,
not proposed before/after art or an earned-play witness.

At Cliffhold, disabling `ProceduralGroundCover` removes the floating grass clump
at the left and the dense roof-high grass mass on the right. Some foreground
wispy plants remain from other layers. The source audit finds that this pass
uses flat ellipse heights even where the crown geometry descends; ordinary
generated blades are about one metre, so scale tuning alone is not supported
as the remedy. The later raycast/triangle finish pass adds more cover but does
not move or remove those original instances.

Start with [all layers](vegetation-isolation/001_cloudreach_place_cliffhold_court_all_day.png)
and [original procedural cover hidden](vegetation-isolation/002_cloudreach_place_cliffhold_court_no_procedural_day.png).
The folder also contains finish/alpine/all-cover/cloud-bank isolation views,
the same six views at Galefoot, exact frame metadata and original logs. The
source audit documents flat-height patch examples and potential support-query
approaches; these are recommendations for the owning lane, not tested fixes.

The logs retain the inherited unscoped flag and physical placement warnings.
No code-blind PASS is claimed, and no criterion closes from disabling a layer.
