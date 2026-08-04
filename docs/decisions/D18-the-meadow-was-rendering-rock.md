# D18 — The meadow was rendering rock, and four art rounds tuned a texture nobody could see

**Status:** accepted
**Found during:** M7
**Supersedes the ground half of:** `docs/reviews/MA-01` … `MA-04`

## What was wrong

Terrain3D's auto shader picks between two textures by slope:

```
auto_blend = clamp(auto_slope * 2.0 * (normal.y - 1.0) + 1.0, 0.0, 1.0)
```

On level ground `normal.y` is 1.0, so **`auto_blend` is 1.0** — and blend 1.0
selects the **overlay**, not the base. The config had the defaults:
`auto_base_texture: 0` (grass), `auto_overlay_texture: 1` (rock).

So the flat meadow — every square metre of it — rendered **`Rock030`**. The
grass texture appeared only on steep faces, which in a rolling meadow is almost
nowhere.

## Why this went unnoticed for four review rounds

Every complaint the blind visual critic filed about the ground was an accurate
description of wet stone:

- MA-01 — "fractured plates"
- MA-02 — "cracked fissure lines running through the field"
- MA-03 — a brown near-field under a green horizon
- MA-04 — "a flat untextured colour fill"

And every fix went into `Grass008`'s `uv_scale`, `tint` and `normal_depth` — a
texture that was not on screen. One of those rounds moved a measured brightness
value from 0.28 to 0.33, exactly as predicted, and the frames still looked like
rock. That result was read as "the tuning is not enough yet". It was in fact
proof that the thing being tuned was not the thing being rendered.

This is the project's recurring failure in its purest form. The measurements
were correct. The predictions were correct. They were about the wrong object,
and nothing in a number can tell you that.

## The second half: the slope material must be light

Fixing the swap alone was not enough, and the reason is not obvious.

Terrain3D evaluates **both** auto textures whenever the blend is below 1.0, and
the blend only reaches exactly 1.0 on perfectly level ground. Rolling terrain is
never exactly level. So a few percent of the slope material is height-blended
into the whole meadow — and because height blending is not a uniform mix, it
appears as **thin dendritic veins**, not as an even tint.

With a dark rock as the slope material, those veins were the black cracks.
`blend_sharpness` does not remove them. Contrast does.

The auto pair is now light grass over light soil (`Grass004` / `Ground003`).
`Rock030` stays in the texture array, unselected by the auto shader; stone reads
through the colour map's rock tint and through actual boulder meshes, which is
where stone belongs — on things that are stone, not smeared through a field.

## The rule this leaves behind

**When a shader picks between two inputs, verify which input is on screen before
tuning either.** The cheapest possible check would have caught this in minutes:
set the two textures to flat red and flat green and take one frame.

Corollary, and the reason this gets a decision record rather than a bug fix
note: *a measurement that moves exactly as predicted while the picture does not
improve is evidence that the measurement is not of the picture.* Four rounds
treated that as a tuning problem.

## What is still open

The ground is fixed; the frames are not finished. Recorded honestly rather than
closed:

1. The middle and far distance is still a flat pale sheet with little tonal
   variation — MA-04's ranked gap #2, only half addressed. Fog and aerial
   perspective live in `art.json`.
2. The trail reads as scattered pale gravel rather than a laid path. A real dirt
   track needs texture index 2 painted into Terrain3D's **control map**, which
   is a uint32 bitfield in an RF image that nothing in this project has ever
   written. Not attempted, and recorded as not attempted.
3. The pond is a pale flat cyan: its disc is 32m wide but the waterline is ~18m,
   so the shader's shore gradient never reaches the deep colour or the foam band.
4. Tree trunks are salmon pink, and cast shadows band hard across the low-sun
   frame.

The creature half of the art bar is untouched by this decision and remains where
`D10` and `MA-04` left it.
