# D25 — The sky is a shader, and golden hour is a schedule rather than a preset

**Status:** accepted
**Decided by:** implementation, during M10
**Related:** `D06-the-screenshot-critic-under-godot.md`,
`D18-the-meadow-was-rendering-rock.md`, `docs/reviews/MA-05-…`

Two decisions, recorded together because the second is only reachable once the
first exists.

## 1. `PanoramaSkyMaterial` replaced by a hand-written sky shader

A day/night cycle has to **cross-fade** between two sky panoramas. Godot's
`PanoramaSkyMaterial` samples exactly one, so a cycle built on it can only cut
between hours — and a cut is precisely the thing a dawn is not. The replacement
samples three: the two bracketing hours and a cloud dome, blended per frame.

### The check that came with it, and what it caught

Replacing a built-in with hand-written maths means the new path has to prove it
samples *the same panorama*. So `tools/preview_weather.gd` renders one sky
through both and compares pixels before any frame is judged.

**First run: mean difference 0.118, worst pixel 0.910.**

The obvious azimuth — `atan(x, z)` — renders the sky **mirrored**. Same
panorama, same clouds, wrong half of the world. In a still image of a sky nobody
has memorised this is completely invisible; it would have shipped, and it would
have put the moon on the opposite side of the sky from the moonlight, which is
the kind of wrongness a player feels and cannot name.

The correct form, `-atan(x, z) / 2π + 0.5`, measures **0.0147**, and an
amplified difference image shows the residual is a one-pixel outline on cloud
edges — sub-texel resampling, not a difference in what is sampled. The threshold
is 0.04; a 3.6° rotation error measures 0.030, so the check has real teeth.

**The check is permanent and fails the tool.** This is D18's lesson applied
before the fact rather than after: *when a shader picks between inputs, verify
which input is on screen before tuning either.* D18 cost four review rounds
because nobody did. This cost one probe.

## 2. Golden hour ships as the default, via the clock

`MA-05` measured every frame of the world and its verdict on the best one was
unambiguous: `05-spawn-low-sun` outperformed the four noon frames "by a wide
margin on every value metric", and its recommendation was to **ship a dusk or
golden-hour lighting setup as the default look**.

With a cycle, that stops being a choice of preset and becomes a choice of *when
the game starts*. `weather.json` sets `clock.start_hour: 17.0` — the player
opens the game an hour before golden hour, in the light MA-05 praised, and the
world moves on from there.

This is better than pinning the look, because pinning it would have thrown away
the milestone. A player who never sees noon does not have a day/night cycle;
a player who *starts* at the best hour has one, and gets the best frame first.

## What the cycle needed that a preset never would

Two findings that are properties of interpolation rather than of taste, both
found by rendering:

**Deep night needs a keyframe at both ends.** With `night` as a single
keyframe, linear interpolation makes true night a single *instant* — every other
moment is on a ramp toward dawn or dusk. The first render was a star field over
grass at nearly its noon brightness. `night_late` at 04:00 (`same_as: night`)
creates a plateau. A cycle is keyframes on a curve, and a curve with one point
at the extreme has no extreme.

**Night's fill has to be a stated colour, not sky radiance.**
`ambient_sky_contribution` is **0.05** at night against 0.5 at noon. At 0.3 the
settled frame measured mean luminance **0.016** with the near foreground at
zero — a creature ten metres away would have been invisible. Sky radiance from a
star field is nothing, and under Compatibility (D06) it does not reach terrain
at all.

## The night sky was sourced, not faked

No energy multiplier turns a blue-scattered dome with a sun disc into night, so
`day.hdr` could not be dimmed into one. Kloppenheim 02 Pure Sky was chosen over
two brighter moonlit candidates because **it is the same photographer and
location family as `day.hdr`** — cohesion between the hours of one cycle matters
more than any single frame looking best alone. Dawn costs no asset at all: it is
`golden.hdr` spun 180°.

Both new HDRIs are CC0 and in `docs/ASSET_LEDGER.md` with the licence as found.

## What this does not fix

Ground-half value variation is **0.041–0.094** across the whole cycle, against
the references' ≈0.20. MA-05's headline gap is not closed and this milestone was
never going to close it: that number is albedo and scene content, not
scheduling. What *did* move is the dynamic range — 0.067 to 0.533 mean across
the day, with eight of eighteen frames containing a true black, where MA-05
refused a frame whose 5th-percentile luminance was 0.47.

Still open and recorded rather than hidden: the moon's azimuth does not match
the directional light's yaw (a pre-existing mismatch shared by `day.hdr` and
`golden.hdr`); lightning reads as an exposure jump rather than a strike, because
it has no bolt and no directional key change; rain near the camera renders as a
translucent pane; and there are no wet surfaces or splashes, because both need
depth reads that D06 rules out.
