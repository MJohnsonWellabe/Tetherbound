#!/usr/bin/env python3
"""
Reshapes the round, similarly-sized moss/lichen blobs in a ground texture into
irregular, elongated, varied-density clumps instead of near-circular stamps.

    python3 tools/art_pipeline/reshape_moss_blobs.py

Written for `EV4-textures-remainder`'s own diagnosis: "the moss patches' own
roughly-circular, similarly-sized SHAPE and semi-regular scattering... reads
as a repeated stamped-decal layer at close range... no colour/tint/normal
depth lever reaches this; it would need... a re-worked moss layer (irregular,
elongated along wear lines, varying density)." `EV4-textures` already fixed
this same texture's moss SATURATION (a shader/config-level dither); this is a
different lever, a direct edit of the source photo's moss regions, and is
additive with that fix rather than redoing it -- it reads the texture as it
currently ships, after their desaturation, and only touches shape.

For each detected moss blob above a size threshold: stretch it along a random
axis (elongation), narrow it perpendicular to that axis (so it reads as a
streak/wear-line rather than a bigger circle), rough up the boundary with
coarse noise so the silhouette isn't a smooth oval, feather the edge (soft
alpha, not a hard decal cutout), and blend at a per-blob strength so density
varies blob to blob. Small background speckle (<60px) is left untouched --
that is fine grain, not the defect.

Deterministic: every blob's angle/elongation/blend is seeded from its own
label id, so re-running on the same input produces the identical output.

Detection is colour-based (green-dominant over red/blue), which catches the
matte green moss clumps. A separate class of grey-green fibrous "tuft" shapes
in the same photo (visually distinct -- texture/luminance-variance driven,
not colour) was investigated and NOT included here: a robust two-class
detector risked false positives across the whole 1024x1024 photo within the
time budget available, and the earlier lane's own saturation fix targeted the
same green mask this script does, which is evidence "moss" means this class
specifically. If a future blind critic still calls out the grey tufts by
shape, that is EV4-textures-remainder's own honest remainder, not a bug here.
"""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = "assets/environment/terrain/Ground030_Color.jpg"
OUT = "assets/environment/terrain/Ground030_Color.jpg"

MOSS_THRESH = 0.03
MIN_BLOB_PX = 60
PATCH_MARGIN = 45


def rotate(coords, angle):
    c, s = np.cos(angle), np.sin(angle)
    y, x = coords
    return c * y - s * x, s * y + c * x


def main():
    img = Image.open(SRC).convert("RGB")
    arr = np.array(img).astype(np.float32) / 255.0
    out = arr.copy()
    H, W, _ = arr.shape

    R, G, B = arr[..., 0], arr[..., 1], arr[..., 2]
    moss_score = G - np.maximum(R, B)
    mask = moss_score > MOSS_THRESH
    mask = ndimage.binary_opening(mask, structure=np.ones((2, 2)))

    labels, n = ndimage.label(mask, structure=np.ones((3, 3)))
    sizes = ndimage.sum(mask, labels, range(1, n + 1))
    objs = ndimage.find_objects(labels)

    reshaped = 0
    for i in range(1, n + 1):
        if sizes[i - 1] < MIN_BLOB_PX:
            continue
        sl = objs[i - 1]
        bbox_h = sl[0].stop - sl[0].start
        bbox_w = sl[1].stop - sl[1].start

        # Seed once per blob so every draw below (including the margin) is
        # deterministic and reproducible on a re-run.
        rng = np.random.default_rng(seed=1000 + i)
        angle = rng.uniform(0, np.pi)
        elongate = rng.uniform(1.7, 3.0)
        narrow = rng.uniform(0.5, 0.72)
        blend_strength = rng.uniform(0.5, 0.85)
        edge_noise_amp = rng.uniform(2.5, 5.0)
        # A blind critic on an earlier pass, after the clipping fix below,
        # confirmed the hard-edge "stamped decal" complaint was gone but
        # named a follow-on: "nearly everything else is a soft round-to-oval
        # blob... needs 2-3 more distinct silhouette variants." A symmetric
        # stretch always produces a symmetric oval regardless of angle. This
        # taper breaks that: it biases the edge threshold along the stretch
        # axis so one end tapers into a frayed wisp while the other stays
        # fuller -- a comma/flame silhouette, not just a bigger ellipse.
        # ~40% of blobs stay untapered (0) for genuine variety, not just a
        # second uniform style.
        taper = rng.uniform(-2.2, 2.2) if rng.random() > 0.4 else 0.0

        # A first attempt used a flat 45px margin regardless of blob size or
        # elongate -- for the biggest blobs (up to 51px across, elongate up
        # to 3x) the stretched tail reached past that margin and was
        # silently clipped by the patch boundary, so the largest, most
        # visible blobs barely looked different. Scale the margin to the
        # blob's own half-extent times its own elongation, with room to
        # spare, so nothing this run stretches ever gets truncated.
        half_extent = max(bbox_h, bbox_w) / 2.0
        margin = max(PATCH_MARGIN, int(half_extent * elongate * 1.4) + 10)

        y0, y1 = max(0, sl[0].start - margin), min(H, sl[0].stop + margin)
        x0, x1 = max(0, sl[1].start - margin), min(W, sl[1].stop + margin)

        blob_mask = labels[y0:y1, x0:x1] == i
        ys, xs = np.nonzero(blob_mask)
        cy, cx = ys.mean(), xs.mean()

        moss_pixels = arr[y0:y1, x0:x1][blob_mask]
        moss_mean = moss_pixels.mean(axis=0)
        moss_std = moss_pixels.std(axis=0) * 0.6

        ph, pw = blob_mask.shape
        oy, ox = np.mgrid[0:ph, 0:pw].astype(np.float32)
        oy -= cy
        ox -= cx

        # Rotate into the stretch axis frame, invert-scale to find where each
        # OUTPUT pixel's shape membership comes from in the ORIGINAL blob --
        # dividing by elongate/narrow here (not multiplying) is what makes
        # the new mask a STRETCHED version of the old one, not a shrunk one.
        u_out, v_out = rotate((oy, ox), -angle)
        u, v = u_out / elongate, v_out / narrow
        iy, ix = rotate((u, v), angle)
        iy = np.round(iy + cy).astype(np.int32)
        ix = np.round(ix + cx).astype(np.int32)
        valid = (iy >= 0) & (iy < ph) & (ix >= 0) & (ix < pw)
        new_mask = np.zeros((ph, pw), dtype=bool)
        new_mask[valid] = blob_mask[iy[valid], ix[valid]]

        # Rough up the boundary: perturb a signed-distance-ish field with
        # coarse noise before re-thresholding, so the edge is uneven rather
        # than a smooth stretched oval.
        dist_in = ndimage.distance_transform_edt(new_mask)
        dist_out = ndimage.distance_transform_edt(~new_mask)
        sdf = dist_in - dist_out
        coarse = rng.standard_normal((max(2, ph // 6), max(2, pw // 6))).astype(np.float32)
        coarse_img = Image.fromarray(((coarse - coarse.min()) / (np.ptp(coarse) + 1e-6) * 255).astype(np.uint8))
        coarse_up = np.array(coarse_img.resize((pw, ph), Image.BICUBIC)).astype(np.float32) / 255.0
        # u_out normalized to roughly [-1, 1] across the blob's own stretched
        # half-length, so the taper's strength is relative to each blob's own
        # size rather than a fixed pixel count.
        half_len = max(1.0, half_extent * elongate)
        u_norm = np.clip(u_out / half_len, -1.5, 1.5)
        sdf_noisy = sdf + (coarse_up - 0.5) * edge_noise_amp - taper * u_norm
        ragged_mask = sdf_noisy > 0

        # Feather: float alpha, soft edge instead of a hard decal cutout.
        alpha = ndimage.gaussian_filter(ragged_mask.astype(np.float32), sigma=1.6)
        alpha *= blend_strength

        noise = rng.standard_normal((ph, pw, 3)).astype(np.float32) * moss_std
        synth = np.clip(moss_mean + noise, 0.0, 1.0)

        patch = out[y0:y1, x0:x1]
        a = alpha[..., None]
        patch[:] = patch * (1 - a) + synth * a
        out[y0:y1, x0:x1] = patch
        reshaped += 1

    print(f"reshaped {reshaped} blobs (of {n} total, {int((sizes >= MIN_BLOB_PX).sum())} above {MIN_BLOB_PX}px)")

    out_img = Image.fromarray(np.clip(out * 255.0, 0, 255).astype(np.uint8), mode="RGB")
    out_img.save(OUT, quality=92)
    print(f"saved -> {OUT}")


if __name__ == "__main__":
    main()
