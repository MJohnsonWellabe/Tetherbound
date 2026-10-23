#!/usr/bin/env python3
"""Staticub regen candidate A: shift the warm fur hue off red in the embedded base colour.

    python3 assets/creatures/tetherbound/staticub/candidate_regen/source/regrade_base_color.py \
        <rigged-with-clips.glb> <output.glb> <report.json> [shift_degrees]

Candidate A's fur came out hue ~14 (reddish chocolate; oxblood/red is reserved
for Team Tether). This rotates only warm hues (0-40 deg, plus the 340-360 wrap)
by +shift degrees with a smooth falloff to zero at 50 deg; the mauve fringe
where the violet veins blend into the fur (300-330 deg) is pulled up to 25 deg back
toward violet. Blue eyes and the vein cores (below 300 deg) are untouched. The regraded base colour is embedded
losslessly (PNG). Mesh, skin, rig, clips and every non-image buffer view stay
byte-identical; the script refuses otherwise. GLB helpers and the red/pink/rust
metric come from tools/art_pipeline/apply_multiview_retex.py.
"""
import hashlib, io, json, pathlib, sys
import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[6]
sys.path.insert(0, str(ROOT / 'tools/art_pipeline'))
from apply_multiview_retex import read_glb, write_glb, view_bytes, image_of, put_image, red_fraction  # noqa: E402

VEIN_PULL = 25.0   # degrees toward violet for the 300-330 mauve vein fringe
KEPT = ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'scene']


def strict_red(rgb):
    hsv = np.asarray(Image.fromarray(rgb).convert('HSV'), dtype=np.float64)
    h, s, v = hsv[..., 0] * 360 / 255, hsv[..., 1] / 255, hsv[..., 2] / 255
    m = (s > 0.25) & (v > 0.12)
    return float((((h < 8) | (h > 300)) & m).mean()), float(np.median(h[m & ((h < 60) | (h > 300))]))


def shift_warm(rgb, shift):
    img = Image.fromarray(rgb).convert('HSV')
    hsv = np.asarray(img, dtype=np.float64)
    h = hsv[..., 0] * 360 / 255
    hw = np.where(h > 300, h - 360, h)              # -60..300, warm band centred near 0-40
    weight = np.clip(1 - (hw - 40) / 10, 0, 1) * np.clip((hw + 20) / 10, 0, 1)
    # Mauve fringe where the violet veins blend into brown fur (300-330 deg):
    # pull it back toward the vein violet instead of letting it read pink.
    fringe = np.clip((hw + 60) / 10, 0, 1) * np.clip(1 - (hw + 30) / 10, 0, 1)
    h2 = (hw + shift * weight - VEIN_PULL * fringe) % 360
    hsv[..., 0] = np.round(h2 * 255 / 360) % 256
    return np.asarray(Image.fromarray(hsv.astype(np.uint8), 'HSV').convert('RGB'))


def main():
    src, out, report_path = map(pathlib.Path, sys.argv[1:4])
    shift = float(sys.argv[4]) if len(sys.argv) > 4 else 7.0
    g, chunks = read_glb(src)
    before = json.loads(json.dumps(g)); views = [view_bytes(g, chunks, i) for i in range(len(g['bufferViews']))]
    pbr = g['materials'][0]['pbrMetallicRoughness']
    tex = pbr['baseColorTexture']['index']
    image_view = g['images'][g['textures'][tex]['source']]['bufferView']
    blob, _ = image_of(g, chunks, tex)
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB'))
    graded = shift_warm(rgb, shift)
    buf = io.BytesIO(); Image.fromarray(graded).save(buf, 'PNG', optimize=True)
    put_image(g, chunks, tex, buf.getvalue(), 'image/png', 'base_color_regraded')
    for key in KEPT:
        if g.get(key) != before.get(key):
            sys.exit(f'{key} changed; refusing')
    for i, data in enumerate(views):
        if i != image_view and view_bytes(g, chunks, i) != data:
            sys.exit(f'bufferView {i} bytes changed; refusing')
    write_glb(out, g, chunks)
    sb, hb = strict_red(rgb); sa, ha = strict_red(graded)
    report = {'input': str(src.name), 'input_sha256': hashlib.sha256(src.read_bytes()).hexdigest(),
              'output': str(out.relative_to(ROOT)) if out.is_relative_to(ROOT) else str(out),
              'output_sha256': hashlib.sha256(out.read_bytes()).hexdigest(),
              'hue_shift_deg': shift, 'band': 'warm hues -10..40 deg shifted fully (falloff to 0 at -20 and 50 deg); 310..320 deg pulled VEIN_PULL toward violet (falloff to 0 at 300 and 330)', 'vein_pull_deg': VEIN_PULL,
              'before': {'median_warm_hue_deg': round(hb, 2), 'strict_red_pink_h_lt8_or_gt300': round(sb, 4),
                         'policy_red_pink_rust_h_lt24': round(red_fraction(rgb), 4)},
              'after': {'median_warm_hue_deg': round(ha, 2), 'strict_red_pink_h_lt8_or_gt300': round(sa, 4),
                        'policy_red_pink_rust_h_lt24': round(red_fraction(graded), 4)},
              'base_color_embedding': 'PNG, lossless',
              'kept_unchanged': KEPT + ['all non-image bufferView bytes (%d views)' % (len(views) - 1)]}
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
