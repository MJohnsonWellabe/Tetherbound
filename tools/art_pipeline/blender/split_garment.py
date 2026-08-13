"""Cut one garment out of a fused character mesh so it can be fixed on its own.

    blender --background --python tools/art_pipeline/blender/split_garment.py \
            -- <model.glb> --preset male_trousers --out <out.glb>
            [--debug-select] [--gain 1.10,0.92,0.66] [--report r.json]

WHY THIS EXISTS. `NP4`'s two remaining defects — villager_male's trousers
reading colder and darker than `docs/art/reference/12_NPC_Bases_Reusable.png`,
and a stain on one of villager_female's shins — were both unfixable for the
same structural reason, recorded twice in `ralph/BACKLOG.md`: these Meshy
bases are ONE mesh with ONE material over ONE fused atlas, so every attempt to
correct a garment corrected the satchel, the boots and the face fringe with
it. Retexturing was tried twice per defect and ruled out; a UV-space mask
guided by glTF geometry was tried and ruled out.

What actually separates a garment is not a smarter mask over a shared atlas —
it is not sharing the atlas. This cuts the garment's faces into their own mesh
object with their own material and their own COPY of the texture, and then
edits that copy freely: whatever it does to those pixels can only ever reach
the faces that were cut, because nothing else samples that image. The copy is
flood-filled to a single colour outside the garment's own UV footprint, so it
costs a few hundred KB rather than another 7MB atlas, and the fill colour is
the garment's own mean so mip-level bleeding at island edges stays invisible.

The cut follows `NP7`'s method (its `DONE.md` entry): classify faces by
measurement — dominant vertex group, world height, and the colour the atlas
actually paints them — never by an eyeballed bounding box, then verify by
rendering, never by assuming. Unlike NP7 there is no hole to patch: the cut
piece stays exactly where it was, and both halves keep their original
per-vertex weights, so a trouser leg still deforms with the knee.
"""

import json
import math
import pathlib
import sys

import bmesh
import bpy
import numpy as np


## A face is judged by the colour the atlas paints it, averaged over its
## corners. Warmth is red over blue on that average: leather boots and belts on
## these bases sit at 4-6, cloth trousers at ~1.8, measured (not guessed) over
## villager_male's 27998 faces before any of this was written.
PRESETS = {
    "male_trousers": {
        "object": "trousers",
        "material": "Trousers",
        "groups": ["LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "Hips"],
        ## Below 0.30 is the boot; above 1.00 is the shirt hem. The waistband
        ## between the belt and the pockets IS trouser and has to come with
        ## them — a first cut stopping at 0.84 left an ungraded grey band under
        ## the belt that a render showed immediately.
        "z_range": (0.30, 1.00),
        "max_warmth": 3.0,
        ## The pale wrapped cuff above the boot sits at luma ~0.32 against the
        ## trousers' ~0.14 and is cold enough to pass the warmth test; without
        ## this the grade ran orange drips down it (rendered, round 1).
        "max_luma": 0.24,
        "op": "grade",
    },
    "female_shins": {
        "object": "shins",
        "material": "Shins",
        "groups": ["LeftLeg", "RightLeg", "LeftUpLeg", "RightUpLeg"],
        ## Sock tops land at ~0.33 on this base and the shorts hem at 0.585
        ## (measured: both legs' faces turn olive together there), so the
        ## exposed shin is a purely geometric window. No colour rule on
        ## purpose: the whole defect IS a wrong colour, and a colour filter
        ## would exclude the very faces that need repainting — a first cut
        ## that stopped at the knee bone's own vertex groups left the top
        ## third of the stain behind, which the debug render showed at once.
        "z_range": (0.325, 0.583),
        ## The stain runs up under the shorts hem, whose lowest fringe dips to
        ## ~0.63 on one side, so a flat ceiling either leaves a tan patch on
        ## the knee (rendered, round 3) or eats the shorts. This second window
        ## takes the knee band only where it is far too bright to be the olive
        ## shorts: cloth measures luma 0.17 there, stained skin 0.30-0.41.
        "extra_window": {"z_range": (0.583, 0.63), "min_luma": 0.25},
        "op": "destain",
    },
}

## Faces whose neighbours mostly disagree with them flip. Colour classification
## over a painted atlas is speckly at a garment's edge (a shadowed trouser
## texel can read as leather), and a speckled cut leaves a moth-eaten tint
## boundary — the one artefact a reviewer would name immediately.
SMOOTH_ROUNDS = 4
SMOOTH_MAJORITY = 0.6

## Texels are dilated outward from the garment's UV footprint before anything
## is written, so bilinear filtering and the first mip levels never reach into
## the flood-filled background.
DILATE_TEXELS = 12


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def srgb(v):
    v = np.clip(v, 0.0, 1.0)
    return np.where(v <= 0.0031308, v * 12.92, 1.055 * v ** (1 / 2.4) - 0.055)


def load(path: pathlib.Path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    ## The glTF importer invents an unskinned unit sphere on a rigged file;
    ## turntable.py documents the same phantom and drops it the same way.
    for obj in [o for o in bpy.data.objects if o.type == "MESH"]:
        if not obj.vertex_groups and not obj.data.materials:
            bpy.data.objects.remove(obj, do_unlink=True)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    meshes.sort(key=lambda o: -len(o.data.vertices))
    return meshes[0]


def atlas_pixels(image) -> np.ndarray:
    w, h = image.size
    return np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4)


def face_measurements(obj, px) -> tuple[np.ndarray, np.ndarray, list[str]]:
    """Per-face (centre_z, r, g, b) and the dominant vertex group index."""
    me = obj.data
    uvl = me.uv_layers.active.data
    h, w = px.shape[0], px.shape[1]
    out = np.zeros((len(me.polygons), 4), dtype=np.float32)
    dom = np.full(len(me.polygons), -1, dtype=np.int32)
    for p in me.polygons:
        acc = {}
        for vi in p.vertices:
            for g in me.vertices[vi].groups:
                acc[g.group] = acc.get(g.group, 0.0) + g.weight
        if acc:
            dom[p.index] = max(acc, key=acc.get)
        cols = []
        for li in p.loop_indices:
            u, v = uvl[li].uv
            x = int(np.clip(u * w, 0, w - 1))
            y = int(np.clip(v * h, 0, h - 1))
            cols.append(px[y, x, :3])
        col = np.mean(cols, axis=0)
        centre = obj.matrix_world @ p.center
        out[p.index] = (centre.z, col[0], col[1], col[2])
    return out, dom, [g.name for g in obj.vertex_groups]


def classify(obj, measures, dom, gnames, preset) -> np.ndarray:
    z = measures[:, 0]
    rgb = measures[:, 1:4]
    idx = {n: i for i, n in enumerate(gnames)}
    wanted = [idx[n] for n in preset["groups"] if n in idx]
    sel = np.isin(dom, wanted)
    lo, hi = preset["z_range"]
    sel &= (z > lo) & (z < hi)
    if "max_warmth" in preset:
        warmth = rgb[:, 0] / (rgb[:, 2] + 1e-6)
        sel &= warmth < preset["max_warmth"]
    luma = rgb @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    if "min_luma" in preset:
        sel &= luma > preset["min_luma"]
    if "max_luma" in preset:
        sel &= luma < preset["max_luma"]
    extra = preset.get("extra_window")
    if extra:
        lo2, hi2 = extra["z_range"]
        more = np.isin(dom, wanted) & (z > lo2) & (z < hi2)
        more &= luma > extra["min_luma"]
        sel |= more
    return smooth(obj, sel)


def smooth(obj, sel: np.ndarray) -> np.ndarray:
    """Majority-filter the selection over face adjacency."""
    me = obj.data
    edge_faces: dict[int, list[int]] = {}
    for p in me.polygons:
        for ek in p.edge_keys:
            edge_faces.setdefault(ek, []).append(p.index)
    neighbours: list[list[int]] = [[] for _ in me.polygons]
    for faces in edge_faces.values():
        if len(faces) == 2:
            a, b = faces
            neighbours[a].append(b)
            neighbours[b].append(a)
    for _ in range(SMOOTH_ROUNDS):
        changed = 0
        new = sel.copy()
        for i, ns in enumerate(neighbours):
            if not ns:
                continue
            share = float(np.count_nonzero(sel[ns])) / len(ns)
            if sel[i] and share < 1.0 - SMOOTH_MAJORITY:
                new[i] = False
                changed += 1
            elif not sel[i] and share > SMOOTH_MAJORITY:
                new[i] = True
                changed += 1
        sel = new
        if changed == 0:
            break
    return sel


def separate(obj, sel: np.ndarray, name: str):
    """Cut the selected faces into their own object, weights and all.

    Selection is set through bmesh in edit mode rather than by writing
    `polygon.select` in object mode: the object-mode flags are flushed from
    the vertex selection on the next mode change, which silently widens a
    face selection to every face touching a selected vertex — a cut that
    would take the boot top and the belt with the trousers.
    """
    bpy.context.view_layer.objects.active = obj
    for o in bpy.data.objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_mode(type="FACE")
    bpy.ops.mesh.select_all(action="DESELECT")
    bm = bmesh.from_edit_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    for face in bm.faces:
        face.select_set(bool(sel[face.index]))
    bmesh.update_edit_mesh(obj.data)
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    part = [o for o in bpy.context.selected_objects if o is not obj][0]
    part.name = name
    part.data.name = name
    return part


def uv_mask(part, shape) -> np.ndarray:
    """Rasterise the part's UV triangles into a boolean texel mask."""
    h, w = shape
    mask = np.zeros((h, w), dtype=bool)
    me = part.data
    uvl = me.uv_layers.active.data
    for p in me.polygons:
        loops = list(p.loop_indices)
        uvs = [np.array(uvl[li].uv, dtype=np.float64) for li in loops]
        for i in range(1, len(uvs) - 1):
            tri = np.array([uvs[0], uvs[i], uvs[i + 1]])
            xs = tri[:, 0] * w
            ys = tri[:, 1] * h
            x0 = max(int(math.floor(xs.min())) - 1, 0)
            x1 = min(int(math.ceil(xs.max())) + 1, w)
            y0 = max(int(math.floor(ys.min())) - 1, 0)
            y1 = min(int(math.ceil(ys.max())) + 1, h)
            if x1 <= x0 or y1 <= y0:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
            d = ((ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2]))
            if abs(d) < 1e-12:
                continue
            a = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
            b = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
            c = 1.0 - a - b
            inside = (a >= -0.002) & (b >= -0.002) & (c >= -0.002)
            ## A UV triangle smaller than a texel contains no pixel centre, so
            ## a pixel-centre rasteriser marks nothing for it — while the
            ## renderer still samples the texture there, bilinearly, off
            ## whatever the neighbours hold. On this atlas that left seven
            ## sub-texel faces on villager_female's shin sampling foreign dark
            ## texels: the "vector-sharp black wedge and tan patch below the
            ## knee" a blind critic read as an insect on her leg. Fall back to
            ## a conservative bounding-box fill so no face can ever sample a
            ## texel this mask does not own.
            mask[y0:y1, x0:x1] |= inside if inside.any() else True
    return mask


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    out = mask.copy()
    for _ in range(radius):
        grown = out.copy()
        grown[1:, :] |= out[:-1, :]
        grown[:-1, :] |= out[1:, :]
        grown[:, 1:] |= out[:, :-1]
        grown[:, :-1] |= out[:, 1:]
        out = grown
    return out


def masked_blur(values: np.ndarray, mask: np.ndarray, rounds: int) -> np.ndarray:
    """Box-blur inside a mask, ignoring anything outside it."""
    v = np.where(mask[..., None], values, 0.0).astype(np.float32)
    m = mask.astype(np.float32)[..., None]
    for _ in range(rounds):
        v = (v + np.roll(v, 1, 0) + np.roll(v, -1, 0)
             + np.roll(v, 1, 1) + np.roll(v, -1, 1)) / 5.0
        m = (m + np.roll(m, 1, 0) + np.roll(m, -1, 0)
             + np.roll(m, 1, 1) + np.roll(m, -1, 1)) / 5.0
    return v / np.maximum(m, 1e-6)


def grade(px, mask, gain, report) -> np.ndarray:
    """Warm and lift the garment's own texels. Linear-light, per channel.

    A multiply, not a repaint: the weave, the seams and the painted shading
    all survive, and only the hue and value move — the same reasoning
    `character_model.gd::_shared_variant_material` gives for tinting rather
    than replacing a texture.
    """
    before = px[mask][:, :3].mean(axis=0)
    px[..., :3] = np.where(mask[..., None],
                           np.clip(px[..., :3] * gain, 0.0, 1.0), px[..., :3])
    after = px[mask][:, :3].mean(axis=0)
    report["grade"] = {
        "gain": [float(x) for x in gain],
        "mean_before_srgb": (srgb(before) * 255).round(1).tolist(),
        "mean_after_srgb": (srgb(after) * 255).round(1).tolist(),
    }
    return px


def destain(px, masks, cores, report) -> np.ndarray:
    """Repaint the stained shin out of the clean shin's own texels.

    The defect is not a subtle tint: a rendered close-up shows most of one
    shin painted in the shorts' olive, the atlas island having been packed so
    that this leg's UVs land partly on cloth. Nothing multiplicative recovers
    skin from that, and it is too large a share of the island for a
    flat-field division to treat as a low-frequency stain — measured, the
    stained side's 5th-percentile luma sits at less than half the clean
    side's.

    So the clean shin — the same leg, unwrapped separately into the same
    atlas — becomes the source. Each stained texel is mapped by its position
    within its own island's bounding box to the same relative position in the
    clean island and takes that colour; where a sample lands outside the
    clean island, the clean island's median fills in. Either way this can
    only ever write skin that already exists on this character's other leg.

    BE HONEST ABOUT WHAT THIS ACHIEVES ON villager_female. The two shin
    islands turn out not to correspond: the best of the eight orientations
    below put only 1.7% of samples inside the clean island, so in practice
    the shin is repainted in the clean median — a flat skin tone, not
    recovered painted grain. That is still the right result here (the
    surviving shading comes from the mesh normals, and the clean shin's own
    texel spread is only a few values wide), but a reader should not believe
    a resample happened when the report says `source_hit_rate: 0.017`.
    """
    lw = np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    stats = {}
    for side, m in cores.items():
        vals = px[m][:, :3]
        stats[side] = {
            "texels": int(m.sum()),
            "median_srgb": (srgb(np.median(vals, axis=0)) * 255).round(1).tolist(),
            "luma_median": float(np.median(vals @ lw)),
            "luma_p05": float(np.percentile(vals @ lw, 5)),
        }
    order = sorted(stats, key=lambda s: stats[s]["luma_p05"])
    stained, clean = order[0], order[-1]
    ## Source validity is tested against the UNDILATED island. The dilation
    ## that protects the destination from mip bleeding would, on the source
    ## side, licence sampling the 12 texels of whatever the packer happened to
    ## put next door — which rendered as a brown streak down the repainted
    ## shin on the first attempt.
    src, dst = cores[clean], masks[stained]
    median = np.median(px[src][:, :3], axis=0)

    sy, sx = np.nonzero(src)
    dy, dx = np.nonzero(dst)
    sbox = (sy.min(), sy.max(), sx.min(), sx.max())
    dbox = (dy.min(), dy.max(), dx.min(), dx.max())
    ny = (dy - dbox[0]) / max(dbox[1] - dbox[0], 1)
    nx = (dx - dbox[2]) / max(dbox[3] - dbox[2], 1)

    ## The two islands are the same leg unwrapped twice, but an atlas packer
    ## is free to flip or rotate either of them, and a mapping that assumes
    ## they agree lands 98% of its samples on empty atlas (measured on the
    ## first attempt). Try the eight axis-aligned orientations and keep
    ## whichever puts the most samples inside the clean island — a
    ## measurement, not an assumption about how Meshy packs.
    best = None
    for transpose in (False, True):
        for flip_y in (False, True):
            for flip_x in (False, True):
                a, b = (nx, ny) if transpose else (ny, nx)
                a = 1.0 - a if flip_y else a
                b = 1.0 - b if flip_x else b
                cy = np.clip((sbox[0] + a * (sbox[1] - sbox[0])).round().astype(int),
                             0, px.shape[0] - 1)
                cx = np.clip((sbox[2] + b * (sbox[3] - sbox[2])).round().astype(int),
                             0, px.shape[1] - 1)
                hits = int(src[cy, cx].sum())
                if best is None or hits > best[0]:
                    best = (hits, cy, cx, (transpose, flip_y, flip_x))
    hits, my, mx, orientation = best
    report.setdefault("destain_debug", {})["orientation"] = list(orientation)
    report["destain_debug"]["source_hit_rate"] = round(hits / max(len(dy), 1), 3)

    sampled = px[my, mx, :3].copy()
    outside = ~src[my, mx]
    ## Being inside the clean island is not enough to trust a sample. This
    ## atlas overlaps islands: some of the clean shin's own UV triangles sit
    ## on top of another part's texels, so a "clean" sample can be a dark
    ## fragment of something else entirely. Four faces' worth of exactly that
    ## rendered as a vector-sharp black wedge below the knee, which a blind
    ## critic read as an insect on her leg. Anything whose luma is not within
    ## a quarter of the clean median is not skin, whatever mask it sits in.
    ## Per channel, not just luma: a tan fragment can carry the same
    ## brightness as skin and still read as a blemish. A ±12% window on every
    ## channel is deliberately tight — on this asset it rejects nearly every
    ## sample and the repaint collapses to the clean median, which is the
    ## right trade. A fragment of the wrong thing costs a visible artifact; a
    ## texel of real grain buys almost nothing back on skin whose own spread
    ## is a few values wide.
    lo, hi = median * 0.88, median * 1.12
    outside |= np.any((sampled < lo) | (sampled > hi), axis=1)
    sampled[outside] = median
    px[dy, dx, :3] = sampled
    ## One light smoothing pass inside the repainted island only, so the
    ## nearest-neighbour resample cannot leave a stair-stepped edge where the
    ## two islands' aspect ratios disagree.
    smoothed = masked_blur(px[..., :3], dst, rounds=2)
    px[..., :3] = np.where(dst[..., None], smoothed, px[..., :3])

    after = px[dst][:, :3]
    report["destain"] = {
        "stained_side": stained,
        "clean_side": clean,
        "before": stats,
        "resampled_outside_source": int(outside.sum()),
        "clean_median_srgb": (srgb(median) * 255).round(1).tolist(),
        "after_median_srgb": (srgb(np.median(after, axis=0)) * 255).round(1).tolist(),
        "after_luma_p05": float(np.percentile(after @ lw, 5)),
    }
    return px


def build_image(name, px, mask, out_png) -> "bpy.types.Image":
    """Write the garment's own texture: its own texels, flat fill elsewhere.

    The flat fill is the garment's mean, not black — a mip chain built over a
    black background bleeds a dark rim into every island edge at distance,
    which is the same class of defect this item exists to remove.
    """
    fill = px[mask][:, :3].mean(axis=0) if mask.any() else np.zeros(3)
    out = np.empty_like(px)
    out[..., :3] = np.where(mask[..., None], px[..., :3], fill)
    out[..., 3] = 1.0
    h, w = out.shape[0], out.shape[1]
    image = bpy.data.images.new(name, width=w, height=h, alpha=False)
    image.pixels = out.reshape(-1).tolist()
    image.filepath_raw = str(out_png)
    image.file_format = "PNG"
    image.save()
    return image


def garment_material(source_material, image, name):
    """Clone the base material, pointing every texture node at the new image.

    These Meshy materials wire the SAME painted atlas into Base Color and
    Emission at full strength (a self-lit, painted look — `NP2` measured it),
    so both have to move together or the garment renders its correction under
    an unchanged emissive pass and nothing visible happens.
    """
    material = source_material.copy()
    material.name = name
    for node in material.node_tree.nodes:
        if node.type == "TEX_IMAGE":
            node.image = image
    return material


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... split_garment.py -- <model.glb> --preset <p> --out <glb>")
    model = pathlib.Path(args[0]).resolve()
    preset_name = option(args, "--preset")
    preset = PRESETS[preset_name]
    out_glb = pathlib.Path(option(args, "--out", "/tmp/out.glb")).resolve()
    report_path = option(args, "--report")
    gain = np.array([float(x) for x in option(args, "--gain", "1,1,1").split(",")],
                    dtype=np.float32)
    debug_select = "--debug-select" in args

    body = load(model)
    image = [i for i in bpy.data.images if i.size[0] > 1][0]
    px = atlas_pixels(image)
    measures, dom, gnames = face_measurements(body, px)
    sel = classify(body, measures, dom, gnames, preset)
    report = {"preset": preset_name, "faces_total": int(len(sel)),
              "faces_selected": int(sel.sum())}
    if sel.sum() == 0:
        raise SystemExit("preset selected no faces")

    source_material = body.data.materials[0]
    part = separate(body, sel, preset["object"])
    mask = dilate(uv_mask(part, px.shape[:2]), DILATE_TEXELS)
    report["texels_masked"] = int(mask.sum())

    if debug_select:
        px[..., :3] = np.where(mask[..., None], np.array([0.8, 0.0, 0.6], np.float32),
                               px[..., :3])
    elif preset["op"] == "grade":
        px = grade(px, mask, gain, report)
    elif preset["op"] == "destain":
        ## Sides are split by which side of the body a face actually sits on,
        ## not by which bone owns it: the knee's faces belong to the thigh
        ## bone, and keying off bone names left the top third of the stain
        ## outside the repaint (rendered, round 2).
        centres = np.array([(part.matrix_world @ p.center).x for p in part.data.polygons])
        masks, cores = {}, {}
        for side, side_sel in (("x_pos", centres > 0.0), ("x_neg", centres <= 0.0)):
            if not side_sel.any():
                continue
            cores[side] = side_mask(part, side_sel, px.shape[:2])
            masks[side] = dilate(cores[side], DILATE_TEXELS)
        px = destain(px, masks, cores, report)

    ## Named for the garment, not for this run's output file: Godot's glTF
    ## importer extracts embedded images to siblings named after the image,
    ## and those filenames are committed.
    png = out_glb.with_name(preset["object"] + "_tex.png")
    new_image = build_image(preset["object"] + "_tex", px, mask, png)
    part.data.materials.clear()
    part.data.materials.append(garment_material(source_material, new_image,
                                                preset["material"]))

    bpy.ops.export_scene.gltf(
        filepath=str(out_glb), export_format="GLB", export_animations=True,
        export_skins=True, export_yup=True, export_apply=False,
        export_image_format="AUTO", use_selection=False)
    report["out"] = str(out_glb)
    print("SPLIT", json.dumps(report))
    if report_path:
        pathlib.Path(report_path).write_text(json.dumps(report, indent=1))


def side_mask(part, face_sel, shape) -> np.ndarray:
    """UV mask for a subset of the separated part's faces."""
    h, w = shape
    mask = np.zeros((h, w), dtype=bool)
    me = part.data
    uvl = me.uv_layers.active.data
    for p in me.polygons:
        if not face_sel[p.index]:
            continue
        loops = list(p.loop_indices)
        uvs = [np.array(uvl[li].uv, dtype=np.float64) for li in loops]
        for i in range(1, len(uvs) - 1):
            tri = np.array([uvs[0], uvs[i], uvs[i + 1]])
            xs = tri[:, 0] * w
            ys = tri[:, 1] * h
            x0 = max(int(math.floor(xs.min())) - 1, 0)
            x1 = min(int(math.ceil(xs.max())) + 1, w)
            y0 = max(int(math.floor(ys.min())) - 1, 0)
            y1 = min(int(math.ceil(ys.max())) + 1, h)
            if x1 <= x0 or y1 <= y0:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
            d = ((ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2]))
            if abs(d) < 1e-12:
                continue
            a = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
            b = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
            c = 1.0 - a - b
            inside = (a >= -0.002) & (b >= -0.002) & (c >= -0.002)
            ## Sub-texel triangles: see uv_mask's note.
            mask[y0:y1, x0:x1] |= inside if inside.any() else True
    return mask


main()
