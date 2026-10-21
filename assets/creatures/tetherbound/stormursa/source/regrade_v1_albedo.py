"""F29#3 r8 (close-1020): regrade Stormursa v1's base colour away from the red-mauve
cast the r7 judges flagged (toward the reserved oxblood) to a cooler chestnut-umber,
leaving the violet/blue lightning veins untouched, capping near-white albedo and raising
the fur roughness that threw white speculars under the key light. Rewrites the GLB's embedded base-colour image and
the extracted Image_0.jpg Godot imports. Deterministic; run once from the original v1.

  python3 assets/creatures/tetherbound/stormursa/source/regrade_v1_albedo.py
  python3 .../regrade_v1_albedo.py --glb=<model.glb> --jpg=<extracted base colour> [--rma=<extracted MR>]
  python3 .../regrade_v1_albedo.py --png=<colourway texture, e.g. staticub_extracted_base_color_vivid.png>
Close-1020 also runs it on Staticub (same mauve cast) so the cub and the adult
read as one line.
"""
import colorsys, io, json, struct, sys
from pathlib import Path
import numpy as np
from PIL import Image

MODELS = Path(__file__).resolve().parents[1] / 'models'
GLB = MODELS / 'creature_stormursa_lod0.glb'
JPG = MODELS / 'creature_stormursa_lod0_Image_0.jpg'
RMA = MODELS / 'creature_stormursa_lod0_Image_1.jpg'  # metallic-roughness
MIN_ROUGHNESS = 218  # 0.85: matte fur; the 0.52-0.72 source threw white speculars on the flank and throat
VALUE_CAP = 0.84
TARGET_HUE = 26.0 / 360.0   # chestnut-umber
SAT_SCALE = 1.0
VALUE_SCALE = 0.95
BRIGHT_TAN = 0.78           # value above which low-saturation fur is pulled down
BRIGHT_SCALE = 0.86


def rgb_to_hsv(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx, mn = rgb.max(-1), rgb.min(-1)
    d = mx - mn
    safe = np.where(d > 1e-6, d, 1.0)
    h = np.where(mx == r, ((g - b) / safe) % 6, np.where(mx == g, (b - r) / safe + 2, (r - g) / safe + 4)) / 6.0
    h = np.where(d > 1e-6, h, 0.0)
    s = np.where(mx > 1e-6, d / np.where(mx > 1e-6, mx, 1.0), 0.0)
    return np.stack([h % 1.0, s, mx], -1)


def hsv_to_rgb(hsv):
    h, s, v = hsv[..., 0] * 6.0, hsv[..., 1], hsv[..., 2]
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    choices = [np.stack(c, -1) for c in ((v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q))]
    out = np.zeros_like(hsv)
    for k in range(6):
        out = np.where((i == k)[..., None], choices[k], out)
    return out


def regrade(img):
    rgb = np.asarray(img.convert('RGB')).astype(np.float32) / 255.0
    hsv = rgb_to_hsv(rgb)
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    vein = (h > 200 / 360) & (h < 315 / 360) & (s > 0.30)
    fur = ~vein
    # Blend hue toward the target in proportion to saturation so greys stay grey.
    w = np.clip(s / 0.25, 0, 1) * fur
    dh = ((TARGET_HUE - h + 0.5) % 1.0) - 0.5
    h2 = (h + dh * w) % 1.0
    s2 = np.where(fur, s * SAT_SCALE, s)
    v2 = np.where(fur, v * VALUE_SCALE, v)
    v2 = np.where(fur & (v2 > BRIGHT_TAN) & (s < 0.35), BRIGHT_TAN + (v2 - BRIGHT_TAN) * BRIGHT_SCALE - 0.04, v2)
    out = hsv_to_rgb(np.stack([h2, s2, np.clip(v2, 0, VALUE_CAP)], -1))
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8))


def rewrite_glb(replacements):
    data = GLB.read_bytes()
    jlen = struct.unpack('<I', data[12:16])[0]
    j = json.loads(data[20:20 + jlen])
    bin_start = 20 + jlen + 8
    blen = struct.unpack('<I', data[20 + jlen:24 + jlen])[0]
    blob = data[bin_start:bin_start + blen]
    pbr = j['materials'][0]['pbrMetallicRoughness']
    targets = {j['images'][j['textures'][pbr[key]['index']]['source']]['bufferView']: data_
               for key, data_ in replacements.items()}
    views = j['bufferViews']
    pieces, offset = [], 0
    for i, view in enumerate(views):
        chunk = targets[i] if i in targets else blob[view.get('byteOffset', 0):view.get('byteOffset', 0) + view['byteLength']]
        pad = (-offset) % 4
        pieces.append(b'\0' * pad)
        offset += pad
        view['byteOffset'] = offset
        view['byteLength'] = len(chunk)
        pieces.append(chunk)
        offset += len(chunk)
    new_bin = b''.join(pieces)
    new_bin += b'\0' * ((-len(new_bin)) % 4)
    j['buffers'][0]['byteLength'] = len(new_bin)
    js = json.dumps(j, separators=(',', ':')).encode()
    js += b' ' * ((-len(js)) % 4)
    total = 12 + 8 + len(js) + 8 + len(new_bin)
    out = struct.pack('<III', 0x46546C67, 2, total) + struct.pack('<II', len(js), 0x4E4F534A) + js \
        + struct.pack('<II', len(new_bin), 0x004E4942) + new_bin
    GLB.write_bytes(out)


def main():
    global GLB, JPG, RMA
    args = dict(a[2:].split('=', 1) for a in sys.argv[1:] if a.startswith('--') and '=' in a)
    if 'png' in args:  # a standalone colourway texture (e.g. *_vivid.png), no GLB
        path = Path(args['png'])
        regrade(Image.open(path)).save(path, optimize=True)
        print('regraded', path.name)
        return
    if 'glb' in args:
        GLB, JPG = Path(args['glb']), Path(args['jpg'])
        RMA = Path(args['rma']) if 'rma' in args else None
    src = Image.open(JPG)
    graded = regrade(src)
    buf = io.BytesIO()
    graded.save(buf, 'JPEG', quality=92)
    JPG.write_bytes(buf.getvalue())
    images = {'baseColorTexture': buf.getvalue()}
    if RMA is not None:
        rma = np.asarray(Image.open(RMA).convert('RGB')).copy()
        rma[..., 1] = np.maximum(rma[..., 1], MIN_ROUGHNESS)
        rbuf = io.BytesIO()
        Image.fromarray(rma).save(rbuf, 'JPEG', quality=92)
        RMA.write_bytes(rbuf.getvalue())
        images['metallicRoughnessTexture'] = rbuf.getvalue()
    rewrite_glb(images)
    print('regraded', JPG.name, 'and', GLB.name)


if __name__ == '__main__':
    main()
