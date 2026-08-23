"""
The Meadows ground surface specification.

Authored as art direction against the project's own key art and the Palworld
reference set, with every number traced to sampled reference pixels rather than
estimated by eye. See ralph/reports/VISUAL_WORLD_SURFACE_2026-08-23.md for the
measurement basis and for why the ground was rebuilt rather than retuned.

TWO COLOURS PER SURFACE, AND ONLY ONE OF THEM LIVES HERE

`hue`/`sat`/`val` below are ALBEDO -- the flat texture mean the generator
targets. They sit deliberately BELOW the on-screen result, roughly 5 value
points and 3 saturation points, because the directional light multiplies both.
`renders_at` records the on-screen target and is the acceptance test:
screenshot the lit ground at noon, eyedropper it, and tune the ALBEDO until it
matches -- never the light. Tolerance +-4 value points, +-5 saturation points,
+-6 degrees of hue.

This is the single most likely way to get this wrong. Copying a key-art swatch
straight into albedo double-applies the painting's own lighting and noon sun
turns S 50 grass into neon; data/config/palette.json carries the same warning in
its own `_caveat`. The inverse error is worse: "fixing" the resulting neon by
dimming the sun, which desaturates every other asset class in the game to
rescue the ground.

OCTAVES ARE IN METRES

Each entry is `(finest_metres, coarsest_metres, amplitude)` where amplitude is a
fraction of base value. The generator converts to cycles per tile using
`tile_metres`. The FIRST octave is the coarsest and is the only one that drives
hue and saturation drift.

Note the shape of the numbers: the largest amplitudes sit at 1-4 metres and the
finest octave is held to +-3%. That inversion relative to a photographic scan is
the art style, not a shortcut. Measured high-pass luminance on the reference
grounds is 2.0-3.5% at pixel scale and only 5.5-11% at ~8px -- the references
carry almost no texel-scale noise, and about 60% of the underfoot read is meant
to come from scattered props rather than from the surface. A ground texture busy
enough to compete with the props is the recorded failure this rewrite exists to
undo. Validate with `--stats`, not by looking at a bare plane.
"""

SPEC = {
    # ---------------------------------------------------------------- grass --
    "meadow_grass": dict(
        seed=20260823,
        hue=77.0, sat=0.47, val=0.43,
        renders_at=(77.0, 0.50, 0.48),
        tile_metres=5.0,
        octaves=[
            (1.2, 2.5, 0.08),    # growth-density blobs; the 5-30m read
            (0.25, 0.50, 0.06),  # clump texture
            (0.06, 0.12, 0.03),  # blade suggestion, NOT drawn blades
        ],
        hue_drift_deg=4.0,       # bright cells toward 60, dark toward 90
        sat_drift=0.03,
        normal_strength=3.0,     # ~2mm apparent relief; no per-blade grain
        note="the default ground; the calm green everything else reads against",
    ),

    "verge_grass": dict(
        # Same generator as meadow_grass, rebased. Sharing the generator is the
        # point: it makes the grass/verge seam a colour step between IDENTICAL
        # texture statistics, which is what lets a hard 2m boundary read as the
        # same meadow drying out rather than as two materials meeting.
        seed=20260824,
        hue=55.0, sat=0.46, val=0.54,
        renders_at=(55.0, 0.49, 0.61),
        tile_metres=5.0,
        octaves=[
            (1.2, 2.5, 0.08),
            (0.25, 0.50, 0.08),  # raised vs meadow: drier, patchier, more straw
            (0.06, 0.12, 0.03),
        ],
        hue_drift_deg=6.0,       # spans roughly 45-65
        sat_drift=0.04,
        normal_strength=3.0,
        note="worn/dry gold: path shoulders, village surrounds, dry crests",
    ),

    # ----------------------------------------------------------------- path --
    "dirt_path": dict(
        seed=20260825,
        hue=38.0, sat=0.41, val=0.68,
        renders_at=(38.0, 0.43, 0.75),
        tile_metres=4.0,
        octaves=[
            (0.8, 2.0, 0.07),    # compaction blotches
            (0.04, 0.10, 0.05),  # pebble and clod stipple, round features only
        ],
        hue_drift_deg=3.0,
        sat_drift=0.02,
        # Embedded stones: count, min/max diameter in metres, then the value,
        # hue and saturation deltas that pull them into the rock family.
        spots=[(8, 0.06, 0.15, 0.10, 9.0, -0.30)],
        spot_relief=0.05,
        normal_strength=4.0,
        note="packed earth; the brightest ground so routes read from a hilltop",
    ),

    # ----------------------------------------------------------- understorey --
    "forest_floor": dict(
        seed=20260826,
        hue=36.0, sat=0.45, val=0.33,
        renders_at=(36.0, 0.47, 0.37),
        tile_metres=4.0,
        octaves=[
            (0.7, 1.5, 0.06),    # duff blotches
            (0.08, 0.20, 0.07),  # leaf-litter patches, no drawn leaves
            (0.05, 0.10, 0.03),
        ],
        hue_drift_deg=8.0,       # dry-leaf browns, roughly 25-45
        sat_drift=0.04,
        spots=[(5, 0.20, 0.40, 0.04, 12.0, 0.02)],  # moss hints, <=8% of tile
        spot_relief=0.03,
        normal_strength=4.0,
        note="oak-grove litter; the dark warm pool that gives groves weight",
    ),

    # --------------------------------------------------------------- margins --
    "wet_earth": dict(
        # The flattest surface in the set on purpose. A wet margin reads through
        # value and gloss, and cracked-mud detail would fight "lush meadow".
        seed=20260827,
        hue=43.0, sat=0.28, val=0.34,
        renders_at=(43.0, 0.29, 0.38),
        tile_metres=4.0,
        octaves=[
            (0.5, 1.5, 0.05),
            (0.05, 0.10, 0.02),
        ],
        hue_drift_deg=2.0,
        sat_drift=0.01,
        normal_strength=2.0,
        note="dark low-chroma mud at pond and river margins; frames the water",
    ),

    # ------------------------------------------------------------------ rock --
    "rock_scree": dict(
        seed=20260828,
        hue=47.0, sat=0.11, val=0.50,
        renders_at=(47.0, 0.12, 0.56),
        tile_metres=6.5,
        octaves=[
            (0.03, 0.08, 0.03),  # interior micro-grain only
        ],
        hue_drift_deg=2.0,
        sat_drift=0.01,
        # (cell size m, value amplitude, warm hue shift, fraction warmed)
        cells=(0.35, 0.08, 6.0, 0.10),
        cell_sat_amp=0.03,
        cell_relief=0.55,
        normal_strength=9.0,     # strongest of the set; bevelled cell edges
        note="exposed stone on steep slopes; the neutral that anchors landmarks",
    ),
}
