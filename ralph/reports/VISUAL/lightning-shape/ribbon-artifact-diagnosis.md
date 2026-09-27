# Lightning ribbon wedge diagnosis

Reviewed the supplied native frame `shots/vis_f10_3_motion/art-shape-normal-segments/art-shape-normal-segments_h12_t120.png` and current `scripts/world/stormwood_lightning.gd`. No edits, engine runs, or Cloudreach inspection.

**Leading diagnosis: hard butt-ended independent ribbon segments create unfilled outer-corner wedges and overlapping inner-corner glow.** This is strongly consistent with both the frame and the current construction. It is a source-backed hypothesis, not an experimentally isolated result.

## What the frame shows

The broad central discharge has repeated sharp triangular dark cuts and bright fan-shaped patches near changes in direction, especially against the sky. The much thinner branches show the problem less strongly. These are hard boundaries inside an otherwise soft halo, so changing only tint/intensity would not address their shape.

## Concrete source mechanism

`_build_strike_bolt` now gives every refined segment its own four-vertex quad, using one tangent for both endpoints. That correctly avoids the earlier averaged-corner tangent reversal within a quad, but it disconnects the transverse geometry at each shared centerline point: the preceding quad ends with one transverse axis, while the next quad starts with a different axis.

Both core and halo fragment shaders calculate alpha only from `UV.x`:

`exp(-4.0 * UV.x * UV.x) * (1.0 - smoothstep(0.8, 1.0, abs(UV.x))) * tint.a`

That is a soft transverse profile, not a soft finite-segment profile. The alpha remains strongest at the centerline all the way to each segment's end; triangle coverage then terminates abruptly. No longitudinal coordinate, end-cap fade, round cap, bevel/round join geometry, or shared outer-corner fill exists.

At a bend, the two butt caps rotate about the shared endpoint:

- On the outside of the bend their covered regions separate, leaving a triangular gap with less/no halo.
- On the inside they overlap, and additive halo contributions accumulate into a bright triangular fan.
- Increasing fracture subdivision makes more such joins without narrowing the halo. Current core radii are 0.055–0.095 m before modulation, with halo radius scale 4, so the halo can extend up to 0.38 m each side. That is a large join footprint for a densely subdivided channel.

The shader does not have a negative-alpha mechanism. In particular, the additive halo cannot directly subtract light. The dark wedges are consistent with missing glow coverage next to brighter overlapping regions; they should not be diagnosed as negative light solely from the screenshot.

## Why the current per-segment tangent change did not solve it

The indexing is internally correct: `[a,a+1,a+2, a+1,a+3,a+2]` connects the four vertices of one segment, with signed UV sides -1/+1 at each endpoint. Indices do not bridge unrelated paths. For a straight segment, its endpoint view-space centers differ by a multiple of its tangent; consequently `cross(tangent, -centre)` has the same direction at both endpoints (apart from the near-parallel fallback). So the segment itself is generally untwisted. The remaining discontinuity lies *between* independently oriented quads.

`MODELVIEW` followed by `PROJECTION` applies the placement transform once. There is no obvious double-transform mistake. `extra_cull_margin=1` exceeds the current maximum 0.38 m lateral expansion. Whole-instance culling would not explain a repeated wedge at each bend. `cull_disabled` renders each ribbon triangle once; this is no longer the duplicate front/back tube-shell problem.

## Recommended fix

Build soft finite segments with rounded ends, or explicitly join the ribbon. Do not keep hard butt caps while only reducing intensity.

A practical bounded option for the current segment architecture:

1. Expand each segment's support beyond its endpoints by its radius (or a bounded multiple for the halo).
2. Supply a longitudinal coordinate/segment length, e.g. through UV2 or a custom varying; UV.y currently carries radius and does not identify the end distance.
3. Compute alpha from distance to the **finite centerline segment**, with the nearest longitudinal point clamped to the segment ends. A Gaussian/soft capsule profile then produces smooth round ends instead of an abrupt rectangular cutoff.
4. Keep junction intensity bounded: adjacent capsules overlap, so blindly adding full-strength halos can still make bright knots. Tune overlap or use a continuous ribbon with explicit round/bevel joins if uniform junction energy is required.

The more exact geometric solution is a continuous strip with sign-consistent projected side vectors and bounded miter/bevel or round join triangles. This fills outer corners and avoids uncontrolled inner overlap, but requires robust treatment of sharp projected reversals. Merely restoring averaged tangents risks recreating the previous folding problem.

A longitudinal fade without extending/rounding the geometry may soften the hard wedges but can introduce dark gaps at every joint; it is a useful diagnostic, not the strongest final construction.

## Focused falsification after implementation

Use the same deterministic strike and camera. Isolate the halo, then inspect the corrected finite-segment/join profile on the same impact frame. The hypothesis predicts that changing only join/end coverage removes the repeated triangular cuts/fans while retaining the centerline shape. If the cuts persist in a single isolated straight quad, this diagnosis is insufficient; investigate the render path or attribute interpolation next. No need to alter gameplay, ground warning timing, world lighting, or camera for this check.

The custom POSITION path leaves VERTEX itself at the centerline. That can matter for renderer features that consume vertex position independently, but these shaders are unshaded, fog-disabled, shadow-disabled, and do not sample screen/depth buffers. I found no direct source evidence that this mismatch explains the repeated join-shaped artifacts; treat it as a secondary investigation only if the simple join isolation fails.

## Identity and limits

Source SHA256: `A0BB7FA1EEAF50F738339FD027158D9F06A93A7ABEFC7A9D7427878B94E7A442`.

This diagnosis uses one supplied frame and the current source/config. It does not prove the exact source bytes used to render that frame, does not assert a runtime shader/compiler defect, and does not certify a fix that has not yet been implemented and captured.
