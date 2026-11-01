"""One natural-magic trait per plain realistic species (VIS-CREATURES group 3, 1 Nov 2026).

Owner direction (via the coordinator, 1 Nov): the favoured creatures (Mosshell,
Stormtrail, Veridian) are a believable animal base PLUS one bold natural-magic
trait grown into the body and its material, readable at gameplay distance; the
plain realistic animals are not favoured. CLAUDE.md still binds: no red, glow
only where the element makes it natural (lightning on storm, bioluminescence on
water), never glowing seams on fur or hide; subtle, not overboard.

Reuses the existing anatomy and overlay tooling unchanged:
- tools/creature_anatomy_maps.py rasterises the LIVE glb's own UVs into
  anatomy channels (height, normal, distance from the centre line);
- tools/creature_overlays.py composites `grow`/`tint` overlays in anatomy;
- tools/generate_aspect_variant_textures.py::build_glow_map paints a glow mask.
Each species writes <stem>_trait1.png (albedo; built over the group-1 grade
<stem>_vis1.png where one exists) and, for glow traits, <stem>_trait1_glow.png,
selected only by creatures_vis_trait_<species> in creature_coat_flags.json
(OFF by default).

    python3 tools/art_pipeline/grade_vis_traits.py [species ...]
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import creature_anatomy_maps as A  # noqa: E402
import creature_overlays as O  # noqa: E402
import generate_aspect_variant_textures as V  # noqa: E402

C = "assets/creatures/tetherbound/"

SPECIES = {
    "bramblebun": {
        "glb": C + "bramblebun/candidate_nat1022/models/creature_bramblebun_nat1022.glb",
        "albedo": C + "bramblebun/candidate_nat1022/models/creature_bramblebun_nat1022_Image_0.jpg",
        "overlays": [
            {"id": "bramble_back", "where": {"y_min": 0.5, "up_min": 0.15}, "mode": "grow",
             "color": "#5b7d33", "shade": "#263f17", "coverage": 0.72, "grain": 6.0, "softness": 0.12},
            {"id": "bramble_stems", "where": {"y_min": 0.55, "up_min": 0.2}, "mode": "grow",
             "color": "#6a5634", "shade": "#33281a", "coverage": 0.08, "grain": 14.0, "softness": 0.08},
            {"id": "leaf_ears", "where": {"y_min": 0.86, "radial_min": 0.08}, "mode": "grow",
             "color": "#6a9a3a", "shade": "#2f4d1c", "coverage": 0.5, "grain": 7.0, "softness": 0.06},
        ],
    },
    "trailpup": {
        "glb": C + "trailpup/candidate_nat1024/models/creature_trailpup_nat1024.glb",
        "albedo": C + "trailpup/candidate_nat1024/models/creature_trailpup_nat1024_Image_0.jpg",
        "overlays": [
            {"id": "earth_stripe", "where": {"y_min": 0.6, "up_min": 0.45}, "mode": "tint",
             "color": "#b8823c", "coverage": 0.62, "grain": 5.0, "softness": 0.1, "strength": 0.85},
        ],
        "glow": [
            {"id": "earth_stripe_glow", "where": {"y_min": 0.66, "up_min": 0.6}, "select": "match",
             "sample": "albedo", "hue": [25, 45], "sat_min": 0.35, "val_min": 0.3,
             "color": "#e8a04a", "intensity": 0.8, "clump_coverage": 0.45, "blur_px": 3.0},
        ],
        "emission_energy": 0.5,
    },
    "mudsnout": {
        "glb": C + "mudsnout/candidate_nat1024t/models/creature_mudsnout_nat1024t.glb",
        "albedo": C + "mudsnout/candidate_nat1024t/models/creature_mudsnout_nat1024t_Image_0.jpg",
        "overlays": [
            {"id": "moss_shoulders", "where": {"y_min": 0.58, "up_min": 0.3}, "mode": "grow",
             "color": "#5f7d35", "shade": "#2c4318", "coverage": 0.55, "grain": 5.0, "softness": 0.12},
        ],
    },
    "mirejaw": {
        "glb": C + "mirejaw/candidate/models/creature_mirejaw_native.glb",
        "albedo": C + "mirejaw/candidate/models/creature_mirejaw_native_Image_0.jpg",
        "overlays": [
            {"id": "swamp_moss_back", "where": {"y_min": 0.55, "up_min": 0.4}, "mode": "grow",
             "color": "#52713a", "shade": "#243819", "coverage": 0.5, "grain": 6.0, "softness": 0.12},
        ],
    },
    "cannonback": {
        "glb": C + "cannonback/models/creature_cannonback_lod0.glb",
        "albedo": C + "cannonback/models/cannonback_extracted_base_color_vivid.png",
        "overlays": [
            {"id": "weed_shell", "where": {"y_min": 0.55, "up_min": 0.35}, "mode": "grow",
             "color": "#56783a", "shade": "#263c1a", "coverage": 0.78, "grain": 5.0, "softness": 0.12},
        ],
    },
    "fulgocobra": {
        "glb": C + "fulgocobra/models/creature_fulgocobra_lod0.glb",
        "albedo": C + "fulgocobra/models/fulgocobra_extracted_base_color_vivid.png",
        "overlays": [],
        "glow": [
            {"id": "gold_veins", "where": {}, "select": "match", "sample": "albedo",
             "hue": [25, 50], "sat_min": 0.3, "val_min": 0.58,
             "color": "#ffd25a", "intensity": 1.0, "clump_coverage": 0.8, "blur_px": 1.0},
        ],
        # Lightning runs along the pattern's edges, never across the hide.
        "glow_edge_px": 4,
        "emission_energy": 0.9,
    },
    "riverdrake": {
        "glb": C + "riverdrake/models/creature_riverdrake_lod0.glb",
        "albedo": C + "riverdrake/models/riverdrake_extracted_base_color_vivid.png",
        "overlays": [],
        "glow": [
            {"id": "frill_biolume", "where": {"y_min": 0.68}, "select": "match", "sample": "albedo",
             "hue": [25, 55], "val_min": 0.68,
             "color": "#7fe6ff", "intensity": 0.9, "clump_coverage": 0.85, "blur_px": 1.0},
        ],
        # Bioluminescence along the crest and frill rims, not across the hide.
        "glow_edge_px": 4,
        "emission_energy": 0.8,
    },
    "solmane": {
        "glb": C + "solmane/models/creature_solmane_lod0.glb",
        "albedo": C + "solmane/models/solmane_extracted_base_color_vivid.png",
        "overlays": [
            {"id": "sky_wing_tips", "where": {"y_min": 0.8, "radial_min": 0.5}, "mode": "tint",
             "color": "#5f97cf", "coverage": 0.7, "grain": 4.0, "softness": 0.08, "strength": 0.8},
        ],
    },
}


def anatomy_for(glb, size):
    gltf, binary = A.read_glb(os.path.join(ROOT, glb))
    pos, nrm, uv, tris = A.mesh_arrays(gltf, binary)
    pos_map, nrm_map, valid = A.rasterise(pos, nrm, uv, tris, size)
    lo, hi = pos.min(axis=0), pos.max(axis=0)
    extent = np.maximum(hi - lo, 1e-6)
    unit = np.clip((pos_map - lo) / extent, 0.0, 1.0)
    unit_nrm = nrm_map / np.maximum(np.linalg.norm(nrm_map, axis=-1, keepdims=True), 1e-9)
    half = max(extent[0], extent[2]) * 0.5
    radial = np.sqrt((pos_map[..., 0] - (lo[0] + hi[0]) * 0.5) ** 2
                     + (pos_map[..., 2] - (lo[2] + hi[2]) * 0.5) ** 2) / max(half, 1e-6)
    return {"unit": unit.astype(np.float32), "nrm": unit_nrm.astype(np.float32),
            "radial": np.clip(radial, 0.0, 1.5).astype(np.float32), "valid": valid,
            "size": np.int32(size)}


def stem(path):
    return os.path.splitext(path)[0]


def main():
    for name in sys.argv[1:] or sorted(SPECIES):
        spec = SPECIES[name]
        live = spec["albedo"]
        base = stem(live) + "_vis1.png"
        base = base if os.path.exists(os.path.join(ROOT, base)) else live
        image = Image.open(os.path.join(ROOT, base)).convert("RGB")
        size = image.size[0]
        rgb = np.asarray(image).astype(np.float64) / 255.0
        anatomy = anatomy_for(spec["glb"], size)
        O.build_anatomy = lambda species, size=size, force=False: (anatomy, None)
        out, notes = O.apply_overlays(rgb, name, spec.get("overlays", []), size)
        Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(
            os.path.join(ROOT, stem(live) + "_trait1.png"), optimize=True)
        print("%s: base %s" % (name, os.path.basename(base)))
        for line in notes:
            print("   ", line)
        if spec.get("glow"):
            source = np.asarray(Image.open(os.path.join(ROOT, live)).convert("RGB").resize((size, size))).astype(np.float64) / 255.0
            glow, gnotes = V.build_glow_map(out, source, anatomy, spec["glow"], size, seed_key=name)
            edge = int(spec.get("glow_edge_px", 0))
            if edge:
                lum = glow.max(axis=-1)
                rim = np.clip(lum - O._erode(lum, edge), 0.0, 1.0)
                glow = glow * (rim / np.maximum(lum, 1e-6))[..., None]
                gnotes.append("edge rim %dpx: %.2f%% lit" % (edge, 100.0 * float((rim > 0.25).mean())))
            Image.fromarray((glow * 255 + 0.5).astype(np.uint8), "RGB").save(
                os.path.join(ROOT, stem(live) + "_trait1_glow.png"), optimize=True)
            for line in gnotes:
                print("    glow", line)


if __name__ == "__main__":
    main()
