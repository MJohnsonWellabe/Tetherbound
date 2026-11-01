"""Pipwing owner-picked remake (1 Nov 2026): owl, white and pale-blue, folded wings.

    blender --background --python this.py -- pipwing_a.glb --out rigged.glb --report report.json

tools/art_pipeline/blender/rig_bird.py unchanged (measured bird rig and its six
gameplay clips: idle, walk, run, attack, hit, faint), with one measurement
replaced, the way galecrest/source/rebuild/prepare_galecrest.py replaces
rig_bird.measure. rig_bird.torso_half_width walks out from the centreline to
the first air gap; Meshy's owl is a surface shell, so the first gap is the
hollow between the centreline and the flank and the torso measured 0.05 m wide
(wingspan 10x torso, rigged as SPREAD wings on a bird whose wings lie folded on
its flanks). Here each thin hip row's outer extent is used instead (median of
rows), which is the torso including the folded wings, as rig_bird intends for
a folded wing.
"""
import sys, pathlib
ROOT = next(p for p in pathlib.Path(__file__).resolve().parents if (p / 'project.godot').is_file())
sys.path.insert(0, str(ROOT / 'tools/art_pipeline/blender'))
import rig_bird as r


def shell_torso_half_width(pts, crotch_z, top_z, mid_x, hip_y, size):
    rows = 12
    z0 = crotch_z
    z1 = crotch_z + (top_z - crotch_z) * 0.40
    step = (z1 - z0) / rows
    near = [p for p in pts if abs(p.y - hip_y) < size.y * 0.16] or pts
    edges = []
    for i in range(rows):
        row = [abs(p.x - mid_x) for p in near if z0 + step * i <= p.z < z0 + step * (i + 1)]
        if len(row) >= 8:
            edges.append(sorted(row)[int(len(row) * .95)])
    return sorted(edges)[len(edges) // 2] if edges else size.x * .25


r.torso_half_width = shell_torso_half_width
r.main()
