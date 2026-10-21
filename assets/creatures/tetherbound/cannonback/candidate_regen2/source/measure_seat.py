"""Measure the rider seat point between the cannons on the fitted rest mesh.

Blender --background --python this.py -- fitted.glb report.json
Scans the centre line (|x| < 4 cm) of the rest-pose mesh from the front legs to the
rear legs and takes the top of the shell at each station. The cannons rise above the
shell; the seat is the lowest shell-top station in the middle band of the back
(between the front-half peak and the rear cannon), reported in Godot axes
(x, y up, z = -Blender y) as the suggested water_mounts.json rider/saddle anchor.
"""
import bpy, sys, json
a = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
body = max((o for o in bpy.data.objects if o.type == 'MESH'), key=lambda o: len(o.data.vertices))
vs = [body.matrix_world @ v.co for v in body.data.vertices]
ys = [p.y for p in vs]; lo, hi = min(ys), max(ys); L = hi - lo
H = max(p.z for p in vs)
R = 0.15


def top(y, x=0.0, r=R):
    pts = [p.z for p in vs if abs(p.x - x) < r and abs(p.y - y) < r]
    return max(pts) if pts else None


profile = []
n = 60
for i in range(n + 1):
    y = lo + L * i / n
    t = top(y)
    if t is not None and t > .5 * H:      # shell/cannon top, not a gap in the sparse mesh
        profile.append((round(y, 3), round(t, 3)))
# Seat: the lowest centre-line top between the highest front-half top (front shell
# rim / front cannon line) and the highest rear-half top (rear cannon).
mid = lo + .5 * L
front_peak = max((yt for yt in profile if lo + .2 * L < yt[0] < mid), key=lambda yt: yt[1])
rear_peak = max((yt for yt in profile if mid <= yt[0] < lo + .9 * L), key=lambda yt: yt[1])
band = [(y, t) for y, t in profile if front_peak[0] < y < rear_peak[0]]
seat_y, seat_z = min(band, key=lambda yt: yt[1])
# Side check: highest point to the left and right of the seat (front cannon pair).
side = {}
for nm, sx in (('left', -1), ('right', 1)):
    pts = [p for p in vs if sx * p.x > .25 and abs(p.y - seat_y) < .25 * L]
    side[nm] = round(max(p.z for p in pts), 3) if pts else None
out = {
    'method': 'centre-line shell-top scan (15 cm column), lowest top between the front-half peak and the rear-half peak (rear cannon)',
    'front_peak_blender_y_z': front_peak, 'rear_peak_blender_y_z': rear_peak,
    'seat_point_blender_xyz': [0.0, round(seat_y, 4), round(seat_z, 4)],
    'seat_point_godot_xyz': [0.0, round(seat_z, 4), round(-seat_y, 4)],
    'body_height_m': round(H, 4), 'body_length_m': round(L, 4),
    'highest_point_within_quarter_length_of_seat': side,
    'centre_line_profile_blender_y_z': profile,
}
open(a[1], 'w').write(json.dumps(out, indent=1))
print('SEAT', json.dumps({k: v for k, v in out.items() if k != 'centre_line_profile_blender_y_z'}))
