#!/usr/bin/env python3
"""Terrapup installed-retex v4: deterministic masked grade of the v3 base colour (no new Meshy pass).

    python3 assets/creatures/tetherbound/terrapup/candidate_installed_retex/source/regrade_installed_retex_v4.py

Code-blind judges at the fight camera (bar 6.7; v3 6.23 vs installed 5.63) asked for:
  stones that no longer render near-white ("marshmallow") under CPU light -> mid-grey albedo
  (median value ~0.45) with darker cracks; olive moss sitting in the seams instead of a lime
  rim; keep the cream chest and muzzle; tan claws. No red/oxblood anywhere (Team Tether).
Input: the committed v3 candidate GLB, itself a byte-identical copy of the installed rigged
creature_terrapup_lod0.glb except its texture images. Only the base-colour image changes here;
meshes, accessors, UVs, skin, nodes, clips and every non-image bufferView stay byte-identical to
both v3 and the installed GLB (the script refuses otherwise).
Masks (HSV on the 2048 atlas):
  stone  neutral blobs: sat <0.08, value 0.30-0.70, opened 9 px, grown 21 px, limited to sat <0.12;
  moss   hue 45-110, sat >0.25, value >0.12; 'seam' moss lies within 12 px of stone, the rest is rim;
  claws  warm cream texels (hue 22-52, sat 0.10-0.40, value >0.55) inside 19 hand-picked UV boxes
         (the claw ovals on the paw islands, found by connected-component inspection of v3);
  cream  everything else keeps its value and hue (chest, blaze, muzzle untouched).
"""
import hashlib, io, json, os, pathlib, sys
import numpy as np
from PIL import Image, ImageFilter

ROOT = pathlib.Path(os.environ.get('TB_ROOT') or pathlib.Path(__file__).resolve().parents[6])
sys.path.insert(0, str(ROOT / 'tools/art_pipeline'))
sys.path.insert(0, str(ROOT / 'assets/creatures/tetherbound/terrapup/candidate_installed_retex/source'))
from apply_multiview_retex import read_glb, write_glb, view_bytes, image_of, put_image, red_fraction  # noqa: E402
from regrade_installed_retex_v2 import hsv, from_hsv, morph, soft, red_clamp, red_metric  # noqa: E402

KEPT = ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'scene', 'samplers']
CLAW_BOXES = [[540, 0, 652, 86], [510, 48, 584, 140], [1086, 60, 1164, 148], [1202, 62, 1244, 138],
              [996, 108, 1078, 198], [1076, 176, 1096, 198], [1034, 188, 1110, 246], [378, 308, 462, 404],
              [580, 312, 668, 404], [466, 338, 564, 426], [1766, 720, 1846, 796], [1786, 834, 1860, 874],
              [1266, 910, 1328, 990], [1646, 1118, 1724, 1218], [1734, 1120, 1822, 1226], [92, 1186, 172, 1296],
              [1662, 1316, 1740, 1382], [936, 1318, 1012, 1394], [180, 1320, 292, 1388]]
STONE_MEDIAN = 0.44


def blur(x, r):
    im = Image.fromarray(np.clip(x * 255, 0, 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(r))).astype(np.float32) / 255


def grade(rgb):
    h, s, v = hsv(rgb)
    out = rgb.copy()
    core = (s < 0.08) & (v > 0.30) & (v < 0.70)
    core = morph(morph(core, 9, 'min'), 9, 'max')
    stone = morph(core, 21, 'max') & (s < 0.12) & (v > 0.10)
    moss = (h > 45) & (h < 110) & (s > 0.25) & (v > 0.12) & ~stone
    near = morph(stone, 25, 'max')
    seam = moss & near; rim = moss & ~near
    # stones: knee-compressed value so the light rims stop blowing out, then crack darkening from
    # local contrast (texel darker than its 5 px neighbourhood), neutral warm grey hue 35 sat 0.05
    sm = float(np.median(v[stone]))
    x = v / sm
    sv = np.where(x < 1, x ** 1.35, 1 + 0.22 * np.tanh((x - 1) / 0.22))
    sv = 0.47 * sv
    crack = np.clip((blur(v, 5) - v) / 0.10, 0, 1)
    sv = sv * (1 - 0.55 * crack)
    sv = np.clip(sv, 0.05, 0.54)
    # renormalise so the stone median lands on the target after crack darkening
    sv = np.clip(sv * (STONE_MEDIAN / float(np.median(sv[stone]))), 0.05, 0.54)
    out[stone] = from_hsv(np.full(int(stone.sum()), 35.0), np.full(int(stone.sum()), 0.05), sv[stone])
    # moss: olive (hue ~62), seam moss darker so the seams read as cracks, rim moss darker still and
    # browner so the lime fringe recedes into the fur
    hm = 62 + (h - 59) * 0.25
    out[seam] = from_hsv(hm[seam], np.clip(s[seam] * 0.85, 0.25, 0.50), np.clip(v[seam] * 0.78, 0.06, 0.40))
    out[rim] = from_hsv(np.clip(hm[rim] - 8, 45, 70), np.clip(s[rim] * 0.80, 0.25, 0.46), np.clip(v[rim] * 0.66, 0.05, 0.32))
    # soften the moss/stone boundary a touch
    # claws: tan (hue 33, sat 0.42, value x0.74 of the cream, clipped 0.32-0.66), inside the claw boxes only
    box = np.zeros(v.shape, bool)
    for x0, y0, x1, y1 in CLAW_BOXES:
        box[max(y0, 0):y1, max(x0, 0):x1] = True
    claw = box & (h > 22) & (h < 52) & (s > 0.10) & (s < 0.40) & (v > 0.55)
    claw = morph(morph(claw, 3, 'max'), 3, 'min') & box & (v > 0.45)
    out[claw] = from_hsv(np.full(int(claw.sum()), 33.0), np.full(int(claw.sum()), 0.42), np.clip(v[claw] * 0.74, 0.32, 0.66))
    stats = {'stone_pct': round(100 * float(stone.mean()), 3), 'seam_moss_pct': round(100 * float(seam.mean()), 3),
             'rim_moss_pct': round(100 * float(rim.mean()), 3), 'claw_pct': round(100 * float(claw.mean()), 3),
             'stone_value_median_before': round(sm, 3),
             'stone_target': 'hue 35, sat 0.05, value 0.47*knee(v/median) (gamma 1.35 below, tanh knee 0.22 above), cracks x(1-0.55*local contrast), renormalised to median 0.44, clipped 0.05-0.54',
             'seam_moss_target': 'hue 62+0.25*(h-59), sat x0.85 (0.25-0.50), value x0.78 (max 0.40)',
             'rim_moss_target': 'hue 54+0.25*(h-59) (45-70), sat x0.80 (0.25-0.46), value x0.66 (max 0.32)',
             'claw_target': 'hue 33, sat 0.42, value x0.74 (0.32-0.66) inside 19 claw UV boxes',
             'cream_fur_eyes': 'unchanged from v3'}
    return out, stats, stone, claw


def main():
    d = ROOT / 'assets/creatures/tetherbound/terrapup'
    src = d / 'models/creature_terrapup_installed_retex_v3_lod0.glb'
    inst = d / 'models/creature_terrapup_lod0.glb'
    out_path = d / 'models/creature_terrapup_installed_retex_v4_lod0.glb'
    rep_path = d / 'candidate_installed_retex/source/regrade-report-v4.json'
    if len(sys.argv) > 1:
        out_path = pathlib.Path(sys.argv[1]); rep_path = out_path.with_suffix('.report.json')
    g, chunks = read_glb(src); orig, orig_chunks = read_glb(src); ig, ich = read_glb(inst)
    tex = g['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index']
    blob, _ = image_of(g, chunks, tex)
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    graded, stats, stone, claw = grade(rgb)
    graded = np.clip(graded, 0, 1)
    clamped = red_clamp(graded)
    b = io.BytesIO(); Image.fromarray((graded * 255).round().astype(np.uint8)).save(b, 'PNG', optimize=True)
    put_image(g, chunks, tex, b.getvalue(), 'image/png', 'base_color_v4')
    for key in KEPT:
        if g.get(key) != orig.get(key) or g.get(key) != ig.get(key):
            sys.exit(f'{key} differs from v3 or installed; refusing')
    skip = {im['bufferView'] for im in orig['images']}
    nonimg = [i for i in range(len(orig['bufferViews'])) if i not in skip]
    iskip = {im['bufferView'] for im in ig['images']}
    inonimg = [i for i in range(len(ig['bufferViews'])) if i not in iskip]
    if len(nonimg) != len(inonimg):
        sys.exit('non-image bufferView count differs from installed; refusing')
    for i, j in zip(nonimg, inonimg):
        if view_bytes(g, chunks, i) != view_bytes(orig, orig_chunks, i) or view_bytes(g, chunks, i) != view_bytes(ig, ich, j):
            sys.exit(f'bufferView {i} differs; refusing')
    write_glb(out_path, g, chunks)
    gu = (graded * 255).round().astype(np.uint8)
    rep = {'species': 'terrapup', 'variant': 'installed_retex_v4',
           'method': 'deterministic masked HSV grade of the v3 Meshy retexture base colour (no new Meshy pass, no credits)',
           'input': str(src.relative_to(ROOT)), 'input_sha256': hashlib.sha256(src.read_bytes()).hexdigest(),
           'installed': str(inst.relative_to(ROOT)), 'installed_sha256': hashlib.sha256(inst.read_bytes()).hexdigest(),
           'output': str(out_path.relative_to(ROOT)) if out_path.is_relative_to(ROOT) else str(out_path),
           'output_sha256': hashlib.sha256(out_path.read_bytes()).hexdigest(),
           'grade': stats, 'red_clamped_texels': clamped,
           'red_metric_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'before': red_metric(rgb), 'after': red_metric(graded)},
           'policy_red_pink_rust_h_lt24': {'before': round(red_fraction((rgb * 255).round().astype(np.uint8)), 4), 'after': round(red_fraction(gu), 4)},
           'stone_albedo_value_median': {'before': round(float(np.median(rgb.max(2)[stone])), 3), 'after': round(float(np.median(graded.max(2)[stone])), 3)},
           'claw_value_median': {'before': round(float(np.median(rgb.max(2)[claw])), 3), 'after': round(float(np.median(graded.max(2)[claw])), 3)},
           'non_image_buffer_views_byte_identical_to_installed': len(nonimg),
           'base_color_embedding': 'PNG, lossless',
           'kept_unchanged': KEPT + ['normal, metallic-roughness and emissive images (v3)', 'all non-image bufferView bytes (installed)']}
    rep_path.write_text(json.dumps(rep, indent=2) + '\n')
    Image.fromarray(gu).resize((768, 768)).save(pathlib.Path(rep_path).parent / '_v4_base_small.jpg') if len(sys.argv) > 1 else None
    print(json.dumps(rep, indent=1))


if __name__ == '__main__':
    main()
