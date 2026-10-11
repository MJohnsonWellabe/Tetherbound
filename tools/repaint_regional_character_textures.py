#!/usr/bin/env python3
"""Author six OFF Tidewake cloth-accent candidates from installed rig paint.

This is an offline asset producer, never a runtime tint or acceptance test.
The exact GLB and atlas hashes are locked below. Skinning excludes every UV
triangle touched by head/neck, hand or foot weights; a source-specific cool
paint selector then excludes warm skin, hair, leather and gold details.
Only selected cloth and its unused gutter change. The installed rig, source
atlas and base portraits are never written. Matching plates are authored by
tools/_capture_portraits.gd --author-appearance=<existing variant ID> later.
All global/individual shipping gates must remain OFF during this authoring.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from creature_anatomy_maps import accessor, read_glb

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "data/config/character_appearance_variants.json"
PROFILES = {
    "field_researcher": {
        "model_sha256": "5b9164827d099f661de5d1ed6a4420ccd011a90005765977c43f06d1ef5487b3",
        "texture_sha256": "3d8f74bd6a1747ac206044be3394ee6326c4a92f594536e55fbf46e5bc66bfbe",
        "hue_range": (44.0, 66.0), "minimum_saturation": 0.18, "maximum_value": 0.55,
    },
    "wandering_trainer": {
        "model_sha256": "a857736af4fd815733e83b4e127255482c8e7cdb626218c8c47510a523b6c913",
        "texture_sha256": "fa6988e74d6c369c287285effd2ed8d216eb806bfe3004f07ff8be4f82c3eefd",
        "hue_range": (175.0, 225.0), "minimum_saturation": 0.12, "maximum_value": 0.50,
    },
}
CANDIDATES = {
    "p2055_water_adair": "field_researcher",
    "p2055_water_iona": "field_researcher",
    "p2055_water_orsen": "wandering_trainer",
    "p2055_water_otto": "wandering_trainer",
    "p2055_water_trainer_fen": "wandering_trainer",
    "p2055_water_trainer_evi": "wandering_trainer",
}
PROTECTED_BONES = {
    "head", "head_end", "headfront", "neck", "lefthand", "righthand",
    "leftfoot", "rightfoot", "lefttoebase", "righttoebase",
}
PROTECTED_WEIGHT = 0.03
GUTTER_TEXELS = 8


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition: bool, detail: str) -> None:
    if not condition:
        raise SystemExit(detail)


def rgb_to_hsv(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    value = rgb.max(axis=2)
    delta = value - rgb.min(axis=2)
    hue = np.zeros(value.shape, dtype=np.float64)
    divisor = np.maximum(delta, 1e-9)
    for channel in range(3):
        selected = (rgb[:, :, channel] == value) & (delta > 0.0)
        if channel == 0:
            sector = ((rgb[:, :, 1] - rgb[:, :, 2]) / divisor) % 6.0
        elif channel == 1:
            sector = (rgb[:, :, 2] - rgb[:, :, 0]) / divisor + 2.0
        else:
            sector = (rgb[:, :, 0] - rgb[:, :, 1]) / divisor + 4.0
        hue[selected] = sector[selected] * 60.0
    return hue, delta / np.maximum(value, 1e-9), value


def protected_uvs(model: Path, size: tuple[int, int]) -> tuple[np.ndarray, np.ndarray]:
    doc, blob = read_glb(model)
    require(len(doc.get("skins", [])) == 1, f"unexpected skin count: {model}")
    names = [doc["nodes"][i]["name"].lower() for i in doc["skins"][0]["joints"]]
    require(PROTECTED_BONES.issubset(names), f"missing protected joints: {model}")
    indices = [i for i, name in enumerate(names) if name in PROTECTED_BONES]
    used_image = Image.new("L", size, 0)
    protected_image = Image.new("L", size, 0)
    used_draw, protected_draw = ImageDraw.Draw(used_image), ImageDraw.Draw(protected_image)
    for mesh in doc["meshes"]:
        for primitive in mesh["primitives"]:
            attrs = primitive["attributes"]
            require(all(key in attrs for key in ("TEXCOORD_0", "JOINTS_0", "WEIGHTS_0")),
                    f"unskinned/unmapped surface: {model}")
            uv = accessor(doc, blob, attrs["TEXCOORD_0"])
            joints = accessor(doc, blob, attrs["JOINTS_0"])
            weights = accessor(doc, blob, attrs["WEIGHTS_0"])
            triangles = accessor(doc, blob, primitive["indices"]).astype(np.int64).reshape(-1, 3)
            require(np.isfinite(uv).all() and (uv >= 0.0).all() and (uv <= 1.0).all(),
                    f"unexpected UV coordinates: {model}")
            protected_vertices = (np.isin(joints, indices) * weights).sum(axis=1) > PROTECTED_WEIGHT
            # glTF V maps directly to PIL rows; no vertical flip. Protected
            # triangles union across every surface, including any shared UVs.
            for triangle in triangles:
                points = [(float(uv[i, 0] * (size[0] - 1)), float(uv[i, 1] * (size[1] - 1)))
                          for i in triangle]
                used_draw.polygon(points, fill=255)
                if protected_vertices[triangle].any():
                    protected_draw.polygon(points, fill=255)
    # A two-texel guard prevents bilinear edge sampling into protected paint.
    protected_image = protected_image.filter(ImageFilter.MaxFilter(5))
    return np.asarray(used_image) > 0, np.asarray(protected_image) > 0


def build_profile(profile: str) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, dict]:
    settings = PROFILES[profile]
    directory = ROOT / "assets/characters" / profile
    model = directory / f"{profile}_lod0.glb"
    texture = directory / f"{profile}_lod0_texture_0.png"
    require(sha256(model) == settings["model_sha256"], f"model source changed: {model}")
    require(sha256(texture) == settings["texture_sha256"], f"texture source changed: {texture}")
    image = Image.open(texture).convert("RGBA")
    require(image.size == (2048, 2048), f"unexpected atlas dimensions: {texture}")
    rgba = np.asarray(image).copy()
    _, saturation, value = rgb_to_hsv(rgba[:, :, :3].astype(np.float64) / 255.0)
    # Classify the local painted region, not each speckle in its weave. A raw
    # per-pixel hue threshold leaves brown pinholes across an otherwise olive
    # or navy cloth island. The original pixel values/saturation still drive
    # the recolor, so this changes selector continuity, never source shading.
    selector_rgb = np.asarray(image.convert("RGB").filter(ImageFilter.MedianFilter(9))).astype(np.float64) / 255.0
    hue, selector_saturation, selector_value = rgb_to_hsv(selector_rgb)
    used, protected = protected_uvs(model, image.size)
    lo, hi = settings["hue_range"]
    paint = ((hue >= lo) & (hue <= hi) & (selector_saturation >= settings["minimum_saturation"])
             & (selector_value >= 0.06) & (selector_value <= settings["maximum_value"]))
    cloth = used & ~protected & paint
    require(int(cloth.sum()) >= 100000, f"unexpectedly sparse cloth selector: {profile}")
    mask = cloth.copy()
    for _ in range(GUTTER_TEXELS):
        grown = np.asarray(Image.fromarray(mask.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(3))) > 0
        mask |= grown & ~used & ~protected & paint
    require(not (mask & protected).any(), f"protected UV overlap: {profile}")
    mask_path = directory / f"p2055_{profile}_cloth_mask.png"
    provenance = {
        "producer": "res://tools/repaint_regional_character_textures.py",
        "source_model": f"res://assets/characters/{profile}/{model.name}",
        "source_model_sha256": settings["model_sha256"],
        "source_texture": f"res://assets/characters/{profile}/{texture.name}",
        "source_texture_sha256": settings["texture_sha256"],
        "cloth_mask": f"res://assets/characters/{profile}/{mask_path.name}",
        "selector_hue_degrees": list(settings["hue_range"]),
        "selector_minimum_saturation": settings["minimum_saturation"],
        "selector_median_window_texels": 9,
        "selector_value_range": [0.06, settings["maximum_value"]],
        "protected_bones": sorted(PROTECTED_BONES), "protected_weight_threshold": PROTECTED_WEIGHT,
        "protected_uv_guard_texels": 2, "unused_gutter_texels": GUTTER_TEXELS,
        "selected_surface_texels": int(cloth.sum()), "selected_total_texels": int(mask.sum()),
        "mask_status": "source_derived_candidate_pending_production_visual_review",
    }
    return rgba, saturation, value, mask, provenance


def recolor(rgba: np.ndarray, saturation: np.ndarray, value: np.ndarray, mask: np.ndarray,
            palette: dict) -> np.ndarray:
    hue = float(palette["hue_degrees"])
    saturation_scale, value_gain = float(palette["saturation_scale"]), float(palette["value_gain"])
    require(np.isfinite([hue, saturation_scale, value_gain]).all()
            and 40.0 <= hue <= 240.0 and 0.5 <= saturation_scale <= 2.5 and 1.0 <= value_gain <= 1.8,
            "invalid/reserved-red candidate palette")
    sat = np.clip(saturation[mask] * saturation_scale, 0.0, 0.80)
    val = np.clip(value[mask] * value_gain, 0.0, 1.0)
    chroma = val * sat
    x = chroma * (1.0 - abs((hue / 60.0) % 2.0 - 1.0))
    zero = np.zeros_like(chroma)
    sector = int(hue / 60.0) % 6
    channels = [(chroma, x, zero), (x, chroma, zero), (zero, chroma, x),
                (zero, x, chroma), (x, zero, chroma), (chroma, zero, x)][sector]
    out = rgba.copy()
    out[:, :, :3][mask] = np.rint((np.stack(channels, axis=1) + (val - chroma)[:, None]) * 255.0).astype(np.uint8)
    require(np.array_equal(out[~mask], rgba[~mask]), "paint changed outside cloth selector")
    require(np.array_equal(out[:, :, 3], rgba[:, :, 3]), "source alpha changed")
    return out


def main() -> None:
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    records = config["variants"]
    require(config.get("enabled") is False, "authoring requires global shipping gate OFF")
    products = []
    profiles = {profile: build_profile(profile) for profile in PROFILES}
    # Validate every intended destination before writing any candidate.
    for variant, profile in CANDIDATES.items():
        record = records[variant]
        expected_model = f"res://assets/characters/{profile}/{profile}_lod0.glb"
        expected_output = f"res://assets/characters/{profile}/{variant}_albedo.png"
        require(record.get("enabled") is False and record.get("expected_base_profile") == profile
                and record.get("expected_model") == expected_model
                and record.get("body_albedo_override") == expected_output
                and record.get("portrait") == f"res://assets/ui/portraits/{variant}.png",
                f"candidate binding/gate/destination changed: {variant}")
        source, sat, val, mask, provenance = profiles[profile]
        output = ROOT / expected_output.removeprefix("res://")
        require(output.parent == ROOT / "assets/characters" / profile, "output escaped installed profile")
        pixels = recolor(source, sat, val, mask, record["authoring_palette"])
        products.append((variant, output, pixels, provenance))
    for profile, (_, _, _, mask, provenance) in profiles.items():
        path = ROOT / provenance["cloth_mask"].removeprefix("res://")
        Image.fromarray(mask.astype(np.uint8) * 255).save(path, optimize=False)
        provenance["cloth_mask_sha256"] = sha256(path)
    for variant, output, pixels, provenance in products:
        Image.fromarray(pixels).save(output, optimize=False)
        records[variant]["authoring_provenance"] = dict(provenance, derivative_sha256=sha256(output))
        records[variant]["review_status"] = "cloth_derivative_authored_pending_matching_portrait_and_production_visual_review"
        print(f"{variant}: selected={provenance['selected_surface_texels']} sha256={sha256(output)}")
    CONFIG.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
