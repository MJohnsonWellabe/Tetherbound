"""Grade a pale-cool-toned creature's textures toward its sheet's palette.

    blender --background --python tools/art_pipeline/blender/grade_ripplet.py \
            -- <animated.glb> --out <graded.glb> \
            [--target 0.373,0.659,0.745] [--blend 0.62]

Written for Ripplet; Galewisp turned out to need the identical operation with
a different target (both creatures' pale colours blow to white under the game
sun — a generator habit, apparently), so the target and blend are flags now.

The in-engine gate critique: "the body is two or three value steps too pale
... washed-out ice-cyan that blows out to white under the scene light, so
the creature's dominant read is WHITE, not blue, and the water-creature
identity evaporates." Target named: mid-value dusky teal around #5FA8BE.

One hue-targeted pass covers the top two findings at once, because the body
and the tail fan share the same washed-out cyan: pale cyans pull down and
toward the concept teal, which turns the fan from "opaque white squirrel
plume" into a glassy blue in the same stroke. Warm whites (the cream belly
and muzzle) are left alone — they are correct — and pinks (the ear-frill
interiors) gain saturation so the coral read survives combat distance.

True translucency on the fan is NOT attempted: the whole creature is one
glTF material, so per-region alpha means splitting the mesh, and the
critique itself rated membrane treatment "over-investment for one of
nineteen". Faked glassiness via colour, recorded as a known imperfection.
"""

import pathlib
import sys

import bpy
import numpy as np

ROUGHNESS_FLOOR = 0.75

## The concept's body teal, from the critique. Pale cyans blend toward it.
TEAL = (0.373, 0.659, 0.745)
TEAL_BLEND = 0.62

## Cyan band that counts as "washed-out body": cool hues, light, undersaturated.
CYAN_HUE = (150.0, 230.0)

## Pink boost for the frill interiors.
PINK_SATURATION = 1.35


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def rgb_to_hsv(rgb):
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


def hsv_to_rgb(hue, saturation, value):
    h = (hue / 60.0) % 6
    c = value * saturation
    x = c * (1 - np.abs(h % 2 - 1))
    m = value - c
    zeros = np.zeros_like(c)
    rgb = np.zeros(h.shape + (3,))
    for mask, (rr, gg, bb) in [
            (h < 1, (c, x, zeros)), ((1 <= h) & (h < 2), (x, c, zeros)),
            ((2 <= h) & (h < 3), (zeros, c, x)), ((3 <= h) & (h < 4), (zeros, x, c)),
            ((4 <= h) & (h < 5), (x, zeros, c)), (h >= 5, (c, zeros, x))]:
        rgb[..., 0] = np.where(mask, rr, rgb[..., 0])
        rgb[..., 1] = np.where(mask, gg, rgb[..., 1])
        rgb[..., 2] = np.where(mask, bb, rgb[..., 2])
    return rgb + m[..., None]


def grade_base_colour(image) -> None:
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(-1, 4)
    rgb = pixels[:, :3].copy()
    hue, saturation, value = rgb_to_hsv(rgb)

    # Pale cyan body and fan -> concept teal. Includes near-white pixels whose
    # small residual hue is cool, which is exactly the blown-out body the
    # critique described. Warm near-whites (cream belly) do not qualify.
    cool = (hue > CYAN_HUE[0]) & (hue < CYAN_HUE[1])
    pale_body = cool & (value > 0.55) & (saturation < 0.55)
    blown_white = (saturation < 0.08) & (value > 0.80)
    body = pale_body | (blown_white & cool)

    graded = rgb.copy()
    teal = np.array(TEAL, dtype=np.float32)
    shading = np.clip(value[..., None] / 0.95, 0.0, 1.0)
    graded[body] = (rgb[body] * (1 - TEAL_BLEND)
                    + (teal * shading[body]) * TEAL_BLEND)

    # Pink frill interiors: more saturation, same value, so the coral survives
    # combat distance without turning neon.
    hue2, saturation2, value2 = rgb_to_hsv(graded)
    pink = ((hue2 > 310) | (hue2 < 20)) & (saturation2 > 0.10) & (value2 > 0.5)
    saturation2 = np.where(pink, np.minimum(saturation2 * PINK_SATURATION, 1.0), saturation2)
    graded = hsv_to_rgb(hue2, saturation2, value2)

    pixels[:, :3] = np.clip(graded, 0.0, 1.0)
    image.pixels[:] = pixels.reshape(-1).tolist()
    image.pack()


def matte_roughness(image) -> None:
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(-1, 4)
    pixels[:, 1] = np.maximum(pixels[:, 1], ROUGHNESS_FLOOR)
    pixels[:, 2] = 0.0
    image.pixels[:] = pixels.reshape(-1).tolist()
    image.pack()


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... grade_ripplet.py -- <animated.glb> --out <graded.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("graded.glb"))).resolve()

    global TEAL, TEAL_BLEND
    if "--target" in args:
        TEAL = tuple(float(v) for v in option(args, "--target").split(","))
    if "--blend" in args:
        TEAL_BLEND = float(option(args, "--blend"))

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(model))

    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        for node in material.node_tree.nodes:
            if node.type != "TEX_IMAGE" or node.image is None:
                continue
            feeds = {link.to_node.type for output in node.outputs for link in output.links}
            if "NORMAL_MAP" in feeds:
                continue
            if node.image.colorspace_settings.name == "sRGB":
                grade_base_colour(node.image)
                print(f"  graded base colour: {node.image.name}")
            else:
                matte_roughness(node.image)
                print(f"  floored roughness, zeroed metallic: {node.image.name}")
        for node in material.node_tree.nodes:
            if node.type == "BSDF_PRINCIPLED":
                node.inputs["Metallic"].default_value = 0.0
                node.inputs["Specular IOR Level"].default_value = 0.3

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB",
                              export_animations=True, export_animation_mode="NLA_TRACKS",
                              export_skins=True, export_yup=True)
    print(f"\n-> {out}")


if __name__ == "__main__":
    main()
