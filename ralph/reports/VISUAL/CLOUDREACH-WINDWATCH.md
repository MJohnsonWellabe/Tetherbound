# Cloudreach settlement windwatch comparison

F08#4 remains open. This packet tests the settlement towers' architectural
identity at Galefoot and Cliffhold; it cannot close the full M1–M12 matrix.

## Build and scope

Baseline is `9425066d003dd20f0faf6bfb0a461f98ab2aee35`, incorporating GitHub main
`f04d82fa1ed07cad05185ad7adc397a26cf174ab`. Candidate is the windwatch patch over
that baseline. [Manifest](cloudreach-windwatch/manifest.json) records normalized
source hashes and original image hashes.

The former tall capped stone columns gain open roofed galleries from installed
Quaternius `WatchTowerWRoof.obj`, over 12 m / 14 m stone bases. The source
mesh remains untouched; a derived mesh clips away the lower scaffold at its
authored gallery floor. Existing stone crowns seat the new deck with 2 cm overlap.
Materials reuse the existing weathered timber and the cottage recipes' neutral
`T_RockTrim_BaseColor.png` substitution with the round-tile normal map.
The whole source model includes its fixed pennant, retained in the roof surface.

No house, route, NPC, activity, camera, progression or collision changes are
included. Existing cloth banners move with the shorter stone tops; their accepted
palette exception is not re-opened here. The tower was already collisionless;
the new gallery is presentation geometry too. These frames do not establish a
walkable or landable rooftop, and that physical limitation remains explicit.

## Evidence and limits

Ten native 1920×1080 baseline frames and ten matching candidate frames use
Godot 4.7 Compatibility, OpenGL 3.3 on NVIDIA GTX 1060 3GB. Stands cover each
settlement's approach and interior, with a closer Cliffhold tower view, by day
and night. Production camera seating and reachable pitch are retained.

This is a **dry visual witness**, not earned gameplay: the harness teleports
and physically seats the trainer, parks the companion behind the camera, hides
the HUD and supplies progression fixtures. Manifest feet/targets/cameras disclose
each stand. No traversal, co-op, full HUD or ROG Ally performance pass is implied.

The initial baseline was 1920×1061 because Windows clamped the boot window; it is
excluded. The adapter now enforces and checks 1920×1080 after world boot. The first
candidate's dangling scaffold legs and orange roof were rejected. Material-name
probes confirmed correct import names; the orange source albedo, not name lookup,
caused the roof colour. The final candidate clips the legs and uses the cottage
texture substitution. Code review found a 5 cm deck gap; it was corrected before
the final retained capture. A geometry check also caught degenerate cut triangles;
the clipping loop now discards them.

Both captures retain inherited Cloudreach fixture/placement diagnostics in their
stderr logs, including the undeclared `fly_tutorial_completed` progression write.
An engine exit of zero and zero skipped frames indicate capture completion only.
They do not clear those diagnostics or establish a visual pass.

## Review and disposition

The first anonymous comparison (A = baseline, B = 12 m / 10 m stone bases)
preferred B in seven pairs, tied two, and preferred A in Galefoot's night
approach (008). Its lower roofed top merged into the cottage/cliff cluster.
That intermediate packet and verdict remain under `intermediate/` and
`intermediate-pair-review.md`. The Galefoot stone base was then raised to 14 m
to recover approach separation while preserving the roofed gallery.

Final code review is archived with this packet. Whole Cloudreach Bars A/B and
the complete F08#4 criterion remain open. The independent critic identifies
square courtyard wear, unsupported/oversized vegetation and crude terrain,
and nighttime focal hierarchy as the three largest remaining scene defects.

**Retain the final candidate (anonymous C).** The final comparison prefers C
over baseline A in **nine pairs, with one tie (006)**. Relative to intermediate B,
six views tie and all four Galefoot views improve. The critic confirms the 008
night-approach overlap regression is reversed and identifies no substantial new
regression. Both whole-frame bars remain **NO**. The upper Cliffhold night view
still trades more architectural identity against a dark top and crowded banners;
the ambiguous source pennant, plain masonry and unlit upper gallery remain weak.

[Initial comparison](cloudreach-windwatch/intermediate-pair-review.md),
[final anonymous comparison](cloudreach-windwatch/final-pair-review.md),
[source review](cloudreach-windwatch/code-review.md),
[final-height smoke log](cloudreach-windwatch/smoke.log).
All ten baseline/final manifests match subject, time, trainer feet, target,
camera position, pitch and yaw exactly. The intermediate set is preserved too;
its only configuration difference from final is the 10 m Galefoot stone base.

The focused imported-geometry smoke passes **21 checks, zero failures**: both
settlement heights, deck seating/overlap, two correct materials, footprint,
retained upper silhouette, finite normalized normals, nondegenerate triangles
and unchanged source geometry. Command:

```text
godot --headless --path . --script tests/smoke_cloudreach_windwatch.gd
```

Native capture command (use a fresh output directory):

```text
godot --path . --rendering-method gl_compatibility --borderless --position 0,0 --resolution 1920x1080 --fixed-fps 60 --script tools/capture_cloudreach_settlement_identity.gd -- --section=region --region=cloudreach --out=res://shots/cloudreach-settlement-review
```

Provenance: installed Quaternius castle and medieval families already recorded in
ART_DIRECTION. No new purchase, generation, reference pixels or source-asset
modification. The Cloudreach Sky Aviary board informs roofed lookout silhouette;
it is a reference, not a shipped texture or geometry source.
