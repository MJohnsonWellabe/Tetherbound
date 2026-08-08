"""Grade Terrapup's baked textures toward the concept sheet's palette.

    blender --background --python tools/art_pipeline/blender/grade_terrapup.py \
            -- <animated.glb> --out <graded.glb>

The in-engine gate critique converged on one highest-leverage fix: "darken
the base fur from ginger to the concept's chocolate brown and pull the head's
white back to the narrow cream blaze... killing the glossy specular while in
the material. Colour identity is what a player pattern-matches first at every
distance, and it's the one mismatch present in all eight frames."

Two texture edits, in the pixels, because the pixels are the only place the
glTF format can carry them:

  BASE COLOUR — hue-targeted grade. Browns deepen toward chocolate (value
  down, saturation up), whites warm toward cream instead of blowing out,
  moss shifts from lime toward olive. Hue-targeted rather than a global
  curve so the teal eyes — the one element every critique praised — are
  explicitly excluded and keep their saturation.

  METALLIC-ROUGHNESS — roughness (G channel) floored, metallic (B channel)
  zeroed. The previous attempt inserted a math-max NODE before the roughness
  input, which Blender renders and the glTF exporter silently cannot encode:
  the exported file kept the original shiny map, and the next gate critique
  duly found "plasticky specular sheen" in frames that looked matte in
  Blender. §12 says no wet plastic fur; this time it is in the texture, where
  it cannot be lost in translation.
"""

import math
import pathlib
import sys

import bpy
import numpy as np

## Roughness floor, in texture units. 0.78 reads as fur under the game sun.
ROUGHNESS_FLOOR = 0.78

## Brown grade: value multiplier and saturation multiplier for fur pixels.
## Saturation neutral after the passing gate review still called the fur
## "warmer, redder and more saturated than the concept's muted matte
## chocolate" — the first grade's 1.15 boost overshot.
BROWN_VALUE = 0.72
BROWN_SATURATION = 0.97

## Whites: blended toward warm cream. Cream target from the sheet's own
## SECONDARY FUR swatch neighbourhood. Applies only to WARM whites — the
## first grade matched "any bright low-saturation pixel", which is also an
## exact description of the stone plates, so the mantle came out as pale
## cream caps and the gate critic read it as "a painted turtle shell or
## mushroom caps, not rock". Stone is handled by its own branch now.
CREAM = (0.92, 0.86, 0.74)
CREAM_BLEND = 0.55

## Stone: neutral greys pulled down toward the sheet's mid-grey ROCK swatch.
STONE_VALUE = 0.70

## Moss: lime pulled toward olive.
MOSS_VALUE = 0.78
MOSS_SATURATION = 0.85


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def rgb_to_hsv(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    maxc = rgb.max(axis=-1)
    minc = rgb.min(axis=-1)
    value = maxc
    delta = maxc - minc
    saturation = np.where(maxc > 1e-6, delta / np.maximum(maxc, 1e-6), 0.0)

    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    hue = np.zeros_like(maxc)
    mask = delta > 1e-6
    rmax = mask & (maxc == r)
    gmax = mask & (maxc == g) & ~rmax
    bmax = mask & ~rmax & ~gmax
    hue[rmax] = ((g - b)[rmax] / delta[rmax]) % 6
    hue[gmax] = ((b - r)[gmax] / delta[gmax]) + 2
    hue[bmax] = ((r - g)[bmax] / delta[bmax]) + 4
    return hue * 60.0, saturation, value


def hsv_to_rgb(hue: np.ndarray, saturation: np.ndarray, value: np.ndarray) -> np.ndarray:
    h = (hue / 60.0) % 6
    c = value * saturation
    x = c * (1 - np.abs(h % 2 - 1))
    m = value - c
    zeros = np.zeros_like(c)
    conditions = [
        (h < 1, (c, x, zeros)), ((1 <= h) & (h < 2), (x, c, zeros)),
        ((2 <= h) & (h < 3), (zeros, c, x)), ((3 <= h) & (h < 4), (zeros, x, c)),
        ((4 <= h) & (h < 5), (x, zeros, c)), (h >= 5, (c, zeros, x)),
    ]
    rgb = np.zeros(h.shape + (3,))
    for mask, (rr, gg, bb) in conditions:
        rgb[..., 0] = np.where(mask, rr, rgb[..., 0])
        rgb[..., 1] = np.where(mask, gg, rgb[..., 1])
        rgb[..., 2] = np.where(mask, bb, rgb[..., 2])
    return rgb + m[..., None]


def grade_base_colour(image: bpy.types.Image) -> None:
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(-1, 4)
    rgb = pixels[:, :3].copy()
    hue, saturation, value = rgb_to_hsv(rgb)

    # Teal guard first: the eyes stay exactly as they are.
    teal = (hue > 150) & (hue < 220) & (saturation > 0.25)

    # Browns and golds: the fur, the claws. Deepen toward chocolate.
    brown = (hue >= 10) & (hue <= 55) & (saturation > 0.22) & ~teal
    value = np.where(brown, value * BROWN_VALUE, value)
    saturation = np.where(brown, np.minimum(saturation * BROWN_SATURATION, 1.0), saturation)

    # Moss: lime toward olive.
    moss = (hue > 55) & (hue < 140) & (saturation > 0.15) & ~teal
    value = np.where(moss, value * MOSS_VALUE, value)
    saturation = np.where(moss, saturation * MOSS_SATURATION, saturation)
    hue = np.where(moss, hue * 0.9 + 75.0 * 0.1, hue)

    # Stone: bright NEUTRAL pixels are the mantle plates. Darkened toward the
    # sheet's mid-grey, never creamed.
    stone = (saturation < 0.10) & (value > 0.55) & ~teal
    value = np.where(stone, value * STONE_VALUE, value)

    graded = hsv_to_rgb(hue, saturation, value)

    # Whites last, in RGB: WARM near-white pixels blend toward cream, keeping
    # their shading variation. The saturation floor is what keeps this off the
    # stone.
    white = (value > 0.72) & (saturation >= 0.10) & (saturation < 0.28) & ~teal
    cream = np.array(CREAM, dtype=np.float32)
    graded[white] = graded[white] * (1 - CREAM_BLEND) + cream * (graded[white].mean(axis=-1, keepdims=True) / 0.9) * CREAM_BLEND

    pixels[:, :3] = np.clip(graded, 0.0, 1.0)
    image.pixels[:] = pixels.reshape(-1).tolist()
    image.pack()


def matte_roughness(image: bpy.types.Image) -> None:
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(-1, 4)
    pixels[:, 1] = np.maximum(pixels[:, 1], ROUGHNESS_FLOOR)   # G = roughness
    pixels[:, 2] = 0.0                                          # B = metallic
    image.pixels[:] = pixels.reshape(-1).tolist()
    image.pack()


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... grade_terrapup.py -- <animated.glb> --out <graded.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("graded.glb"))).resolve()

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(model))

    grades = 0
    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        for node in material.node_tree.nodes:
            if node.type != "TEX_IMAGE" or node.image is None:
                continue
            # Classified by where the image's output actually GOES, not by
            # colour space. The first version used "sRGB means base colour,
            # Non-Color means roughness" — and the normal map is Non-Color
            # too, so it got its G floored and its Z channel zeroed, which
            # turns surface normals into noise. A texture is what it feeds.
            feeds = {link.to_node.type
                     for output in node.outputs for link in output.links}
            if "NORMAL_MAP" in feeds:
                continue
            if node.image.colorspace_settings.name == "sRGB":
                grade_base_colour(node.image)
                print(f"  graded base colour: {node.image.name}")
            else:
                matte_roughness(node.image)
                print(f"  floored roughness, zeroed metallic: {node.image.name}")
            grades += 1
        # Belt and braces: the factor sockets too, for any material whose
        # shine comes from factors rather than maps.
        for node in material.node_tree.nodes:
            if node.type == "BSDF_PRINCIPLED":
                node.inputs["Metallic"].default_value = 0.0
                node.inputs["Specular IOR Level"].default_value = 0.25

    if grades == 0:
        raise SystemExit("no textures found to grade")

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB",
                              export_animations=True, export_animation_mode="NLA_TRACKS",
                              export_skins=True, export_yup=True)
    print(f"\n-> {out}")


if __name__ == "__main__":
    main()
