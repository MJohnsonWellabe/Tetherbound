# Stormwood strike branches — bounded source review

Date: 2026-09-27. Reviewed the working diff and directly relevant surrounding context in exactly `scripts/world/stormwood_lightning.gd` and `data/config/stormwood_surge.json` under `D:/tetherbound/visual-acceptance`. No production edits, engine runs, images or other implementation files were used. This is a source review, not independent visual acceptance of the candidate.

**Verdict: no blocking correctness issue found in the two-file diff for the current configuration.** The four forked paths and darker fill are presentation-only. A rendering/compiler/performance pass is not established by this review.

## Correctness and shader edge cases

- The obsolete hatch uniform and setter are removed together; the new `branch_width` uniform, setter/default and `branch_width_m` config agree at 0.065. JSON parsed successfully. No stale hatch reference remains within the reviewed file.
- `segment_distance` has an unguarded denominator, but all six hardcoded segments are nondegenerate. Their squared lengths are 0.2701,0.2088,0.29,0.586,0.208 and0.1865. There is no divide-by-zero path for these constants. If this helper later receives generated/coincident endpoints it will need a guard; that is not a current defect.
- `electrical_branches` guards the zero-vector angle and rotates the sample into one of four cardinal sectors. The branch segments lie well inside their sector at the configured width; their coverage does not reach the angular folding boundaries. I do not find a current sector-seam discontinuity in the painted paths from the math.
- The furthest endpoint is approximately 2.369 m from the center. Including the 0.100 m total width-plus-feather support gives a conservative outer bound below 2.47 m, inside the 3 m strike radius and the rim's pulled vertex rows. The branches are additionally multiplied by `inside`, preserving clipping at the actual radius.
- Both color normalization and alpha include the new branch contribution. The denominator retains its0.001 floor; alpha remains clamped and multiplied by the existing fade. Current finite positive parameters do not introduce a NaN, unbounded alpha or unmatched color/coverage term.
- The branch silhouette is authored in meters, independent of the radius. This is sound for the current 3 m design, but it will not scale proportionally if a future configuration substantially changes the radius: small radii would clip branches; large radii would leave them near the center. This is a future configuration limitation, not a current radius regression.
- The new width has no input validation. Negative/nonfinite values or widths approaching a sector boundary are outside the reviewed configuration. The supplied 0.065 value is safe; there is no demonstrated need to block this patch on hypothetical invalid configuration.

## Preserved gameplay and presentation invariants

- `strike.radius_m` remains 3 and `strike.telegraph_seconds` remains 1.2. The host schedule, targeting, exposure/shelter decisions, hit test, damage, networking and warning lifecycle are untouched by this diff. The fixed rim still derives from the same strike radius; neither the branch endpoints nor dark fill controls are used for damage.
- The real progress tween, closing inner ring, accumulating perimeter clock and impact fade are unchanged. Branch brightness grows monotonically from 0.7 to 1.0 with that existing progress; it does not add a separate timing source or visual random number use.
- Reduced motion still supplies `pulse_enabled=0`, disabling the existing faint rim modulation. The branch silhouette is stationary, with only monotonic progress weighting, and does not add flicker, oscillation or screen motion. Countdown cues remain in both modes. This preserves the existing reduced-motion contract; it is not a comprehensive accessibility certification.
- Mesh topology, cached mesh/shader, 16 rim samples plus center, terrain interpolation, depth-test/render modes, ground lift and rim-only camera pull are unchanged. With the supplied width, the branches occupy the unpulled interior. Existing vegetation/actor occlusion and terrain-approximation limitations therefore remain; source correctness does not establish visibility through dense foliage.
- The darker interior is an intentional material change: the former 0.7-to 1.0 hazard-color mix becomes 0.25, and hatch-driven opacity is removed. Whether this increases contrast or makes the hazard less legible is a visual question, not a source verdict.

## Runtime cost and Compatibility limits

The old hatch needed a small `fract`/absolute/smoothstep calculation. The replacement adds a per-fragment angular fold, trigonometric rotation and six segment-distance evaluations, including six length evaluations, then a smoothstep. It runs for fragments over the existing disc, including fragments outside the branch shapes. The source writes repeated sin/cos expressions; a compiler may reuse them and fold constant denominators, but this review does not assume a particular optimization result. Arithmetic cost has increased even though draw calls, vertex count, terrain reads and per-strike node/material counts have not.

No new texture lookup, derivative requirement, screen/depth texture dependency, storage buffer, compute stage or dynamic loop is introduced. The new functions use scalar/vector arithmetic and built-ins already represented in this shader's existing code. I find no obvious feature-level Compatibility obstacle in the diff. Actual Godot Compatibility compilation and target-device cost were not tested here and must not be reported as passing based on static inspection. Close-camera/high-overdraw warnings are the useful performance witness.

The 0.035 m feather is a fixed world-space width rather than a pixel-aware edge. Thin branches at distance or grazing camera angles may alias or lose continuity. This is a concrete rendering risk to inspect at native resolution and in motion, not an observed image defect. Do not infer temporal stability from stills or from successful shader parsing.

## Verification and disposition

`git diff --check` passed for both files; Git emitted only its line-ending conversion warning for the JSON file. The JSON parsed and the inspected values were radius 3, telegraph 1.2 and branch width 0.065. Segment denominators and maximum endpoint radius were checked from the new constants. No engine/shader compilation, gameplay test, GPU timing or image review was performed.

Source disposition: acceptable to proceed to the separate rendering/visual review, with no blocking source finding. Visual electrical identity, stronger hazard readability, no actor washout, slope/vegetation behavior, thin-line stability and runtime performance remain unproven here. No criterion, Bar A or Bar B closes from this source review.
