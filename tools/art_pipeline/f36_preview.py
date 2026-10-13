"""Point-splat previews of posed F36 recipes for authoring self-checks.

Not evidence: in-engine captures (capture_f36_poses.gd) remain the visual
proof. This only lets an author see a recipe's silhouette and floor contact
without an import cache.

  python3 tools/art_pipeline/f36_preview.py OUT.png species[,species...] [--roles=faint,swim] [--recipes=FILE]
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
import f36_skin  # noqa: E402

CELL = 220


def render(points, view, size=CELL, floor=None, scale=None, centre=None):
    """view: (right, up, toward-camera) unit vectors."""
    right, up, toward = (np.array(v, float) for v in view)
    x, y, z = points @ right, points @ up, points @ toward
    if scale is None:
        span = max(np.ptp(x), np.ptp(y), 1e-6)
        scale = size * 0.8 / span
        centre = ((x.max() + x.min()) / 2, (y.max() + y.min()) / 2)
    px = (size / 2 + (x - centre[0]) * scale).astype(int)
    py = (size / 2 - (y - centre[1]) * scale).astype(int)
    img = np.full((size, size, 3), 40, np.uint8)
    if floor is not None:
        fy = int(size / 2 - (floor - centre[1]) * scale)
        if 0 <= fy < size:
            img[fy:, :] = (70, 80, 78)
    order = np.argsort(z)
    shade = (z - z.min()) / max(np.ptp(z), 1e-6)
    keep = order[(px[order] >= 0) & (px[order] < size - 1) & (py[order] >= 0) & (py[order] < size - 1)]
    c = 90 + 150 * shade[keep]
    colour = np.stack([c, c * 0.85, c * 0.7], axis=1).astype(np.uint8)
    for dy in (0, 1):
        for dx in (0, 1):
            img[py[keep] + dy, px[keep] + dx] = colour
    return Image.fromarray(img)


def species_cells(recipes, name, roles, phase_index=-1):
    row = recipes['species'][name]
    skin = f36_skin.Skin(row['model'], row['rig_contract'], row['bones'])
    profile = recipes['profiles'][row['profile']]
    import f36_pose_postpass as post
    rig = post.Rig(row['rig_contract'], row['bones'])
    f, l = np.array(rig.forward), np.array(rig.lateral)
    side = (f, np.array([0, 1.0, 0]), l)
    three = ((f - l) / np.sqrt(2), np.array([0, 1.0, 0]), (f + l) / np.sqrt(2))
    cells = [render(skin.rest_points, side, floor=skin.rest_points[:, 1].min())]
    for role in roles:
        frames = profile[role]['frames']
        frame = frames[phase_index if role != 'swim' else len(frames) // 4]
        pts = skin.pose(frame['bones'], frame.get('pivot_rotation_deg'))
        pts[:, 1] -= pts[:, 1].min()
        cells.append(render(pts, side, floor=0.0))
        cells.append(render(pts, three, floor=0.0))
    return cells


def main():
    out = Path(sys.argv[1])
    names = sys.argv[2].split(',')
    roles = ['hit', 'faint', 'swim', 'fly_grip', 'ride']
    path = f36_skin.ROOT / 'data/creatures/f36_pose_candidates.json'
    for arg in sys.argv[3:]:
        if arg.startswith('--roles='):
            roles = arg.split('=', 1)[1].split(',')
        if arg.startswith('--recipes='):
            path = Path(arg.split('=', 1)[1])
    recipes = json.loads(path.read_text())
    rows = [species_cells(recipes, n, roles) for n in names]
    width = max(len(r) for r in rows)
    sheet = Image.new('RGB', (width * CELL, len(rows) * CELL), (20, 20, 20))
    draw = ImageDraw.Draw(sheet)
    for r, cells in enumerate(rows):
        for c, cell in enumerate(cells):
            sheet.paste(cell, (c * CELL, r * CELL))
        draw.text((4, r * CELL + 4), names[r], fill=(255, 220, 120))
    for c, label in enumerate(['rest'] + [f'{x} {v}' for x in roles for v in ('side', '3/4')]):
        draw.text((c * CELL + 4, 16), label, fill=(200, 200, 200))
    sheet.save(out)


if __name__ == '__main__':
    main()
