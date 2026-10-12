"""CPU geometry/route evidence only. Does not launch Godot or sample native terrain."""
import hashlib
import json
import math
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
BASE = "5952f16717ae34a282f0dcd04c150c94af78c594"
ASSET = "assets/environment/stylized_nature/DeadTree_3.gltf"


def read(path):
    return json.loads((REPO / path).read_text(encoding="utf-8"))


def blob(path):
    return subprocess.check_output(["git", "show", BASE + ":" + path], cwd=REPO)


gltf_bytes = blob(ASSET)
g = json.loads(gltf_bytes)
assert len(g["nodes"]) == 1
assert not any(k in g["nodes"][0] for k in ("matrix", "translation", "rotation", "scale"))
buffers = [blob(str(Path(ASSET).parent / b["uri"]).replace("\\", "/")) for b in g["buffers"]]


def accessor(i):
    a = g["accessors"][i]
    v = g["bufferViews"][a["bufferView"]]
    dtype = np.dtype({5126: "<f4", 5125: "<u4", 5123: "<u2"}[a["componentType"]])
    n = {"VEC3": 3, "SCALAR": 1}[a["type"]]
    return np.ndarray((a["count"], n), dtype=dtype, buffer=buffers[v["buffer"]],
                      offset=v.get("byteOffset", 0) + a.get("byteOffset", 0),
                      strides=(v.get("byteStride", dtype.itemsize * n), dtype.itemsize)).copy()


triangles = []
for mesh in g["meshes"]:
    for primitive in mesh["primitives"]:
        points = accessor(primitive["attributes"]["POSITION"])
        indices = accessor(primitive["indices"]).reshape(-1)
        triangles.extend(points[indices.reshape(-1, 3)])
triangles = np.array(triangles)
vertices = np.unique(triangles.reshape(-1, 3), axis=0)
cfg = read("data/config/stormwood_destination_dressing.json")["fallen_giant"]
world = read("data/config/stormwood_world.json")


def rot(axis, degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]]) if axis == "y" else np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def transformed(pitch):
    basis = rot("y", cfg["yaw_deg"]) @ rot("z", -90 + pitch) @ rot("y", cfg["roll_deg"])
    return vertices @ basis.T * cfg["uniform_scale"] + np.array([cfg["root_xz"][0], 0, cfg["root_xz"][1]])


def point_segment(p, a, b):
    t = np.clip(np.dot(p - a, b - a) / np.dot(b - a, b - a), 0, 1)
    return float(np.linalg.norm(p - (a + t * (b - a))))


def intersects(a, b, lo, hi):
    t0, t1 = 0., 1.
    for axis in range(2):
        delta = b[axis] - a[axis]
        if abs(delta) < 1e-12:
            if a[axis] < lo[axis] or a[axis] > hi[axis]:
                return False
        else:
            first, last = sorted(((lo[axis] - a[axis]) / delta, (hi[axis] - a[axis]) / delta))
            t0, t1 = max(t0, first), min(t1, last)
            if t0 > t1:
                return False
    return True


def rectangle_segment(a, b, lo, hi):
    if intersects(a, b, lo, hi):
        return 0.
    corners = [lo, np.array([hi[0], lo[1]]), hi, np.array([lo[0], hi[1]])]
    return min([point_segment(p, a, b) for p in corners] +
               [point_segment(p, corners[i], corners[(i + 1) % 4]) for p in (a, b) for i in range(4)])


seats = []


def collect(value, source):
    if isinstance(value, dict):
        pos = value.get("position")
        if isinstance(pos, list) and len(pos) == 3:
            seats.append((source, value.get("id", "unknown"), np.array(pos)[[0, 2]]))
        for child in value.values():
            collect(child, source)
    elif isinstance(value, list):
        for child in value:
            collect(child, source)


for name in ("npcs", "trainers", "encounters"):
    collect(read(f"data/config/stormwood_{name}.json"), name)
poses = []
all_points = []
for pitch in np.arange(cfg["pitch_min_deg"], cfg["pitch_max_deg"] + .01, cfg["pitch_refine_step_deg"]):
    p = transformed(pitch)
    lo, hi = p[:, [0, 2]].min(0), p[:, [0, 2]].max(0)
    all_points.append(p)
    routes = []
    runtime_road_clear = True
    for route in world["routes"]:
        for a, b in zip(route["points"], route["points"][1:]):
            a, b = np.array(a), np.array(b)
            routes.append((rectangle_segment(a, b, lo, hi), route["id"]))
            runtime_road_clear &= rectangle_segment(a, b, lo, hi) >= cfg["road_clearance_m"]
    actors = sorted((float(np.linalg.norm(np.maximum(np.maximum(lo - at, at - hi), 0))), name, source)
                    for source, name, at in seats)
    runtime_actors_clear = actors[0][0] >= cfg["actor_clearance_m"]
    # Flat surface is just an orientation sanity check, NOT native support evidence.
    lift = -p[:, 1].min() + cfg["surface_clearance_m"]
    root = (vertices[:, 1] >= cfg["root_support_source_y"][0]) & (vertices[:, 1] <= cfg["root_support_source_y"][1])
    crown = (vertices[:, 1] >= cfg["crown_support_source_y"][0]) & (vertices[:, 1] <= cfg["crown_support_source_y"][1])
    poses.append({"pitch_deg": float(pitch), "xz_min": lo.tolist(), "xz_max": hi.tolist(),
                  "nearest_road": min(routes), "nearest_actor": actors[0],
                  "runtime_rectangle_clear": bool(runtime_road_clear and runtime_actors_clear),
                  "flat_only_root_gap_m": float((p[root, 1] + lift).min()),
                  "flat_only_crown_gap_m": float((p[crown, 1] + lift).min())})
envelope = np.concatenate(all_points)
lo, hi = envelope.min(0), envelope.max(0)
receipt = {"base_source": BASE, "enabled": cfg["enabled"], "asset": ASSET,
           "gltf_sha256": hashlib.sha256(gltf_bytes).hexdigest(),
           "buffer_sha256": [hashlib.sha256(b).hexdigest() for b in buffers],
           "materials": [m.get("name") for m in g["materials"]], "triangles": len(triangles),
           "unique_vertices": len(vertices), "uniform_scale": cfg["uniform_scale"],
           "all_pitch_envelope_xz_min": lo[[0, 2]].tolist(), "all_pitch_envelope_xz_max": hi[[0, 2]].tolist(),
           "root_distance_from_catalogue_marker_m": float(np.linalg.norm(np.array(cfg["root_xz"]) - [-150, 4460])),
           "poses": poses, "all_poses_clear_routes_and_actor_rectangles": all(p["runtime_rectangle_clear"] for p in poses),
           "native_terrain_fit": "UNVERIFIED: runtime uses shipping Terrain3D; rejects unsupported placement",
           "collision": "UNRESOLVED: separate server/client static trunk collider scope required before activation",
           "engine_runs": 0}
(HERE / "geometry-audit.json").write_text(json.dumps(receipt, indent=2) + "\n")

im = Image.new("RGB", (1000, 850), "#f4f2ed")
d = ImageDraw.Draw(im)
font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 18)
def screen(at):
    return (90 + (at[0] + 185) * 10, 780 - (at[1] - 4430) * 9)
for route in world["routes"]:
    ps = [screen(at) for at in route["points"]]
    d.line(ps, fill="#c1b8a6", width=40)
    d.line(ps, fill="#82796c", width=2)
for source, name, at in seats:
    if -190 < at[0] < -95 and 4430 < at[1] < 4510:
        x, y = screen(at)
        d.ellipse((x-180, y-162, x+180, y+162), outline="#bd7979", width=2)
        d.text((x+5, y+5), name, fill="#753d3d", font=font)
for p in transformed(14)[:, [0, 2]]:
    x, y = screen(p)
    d.ellipse((x-1, y-1, x+1, y+1), fill="#634d3a")
corners = [screen(lo[[0, 2]]), screen(hi[[0, 2]])]
d.rectangle((min(p[0] for p in corners), min(p[1] for p in corners), max(p[0] for p in corners), max(p[1] for p in corners)), outline="#326b83", width=2)
d.rectangle((0, 0, 1000, 75), fill="#f4f2ed")
d.text((20, 12), "Fallen Giant | actual mesh footprint, full pitch envelope in blue", fill="#282722", font=font)
d.text((20, 40), "CPU plan only. Terrain seat, visibility, collision and native appearance remain unverified.", fill="#55524b", font=font)
im.save(HERE / "footprint.png")
print(json.dumps({k: v for k, v in receipt.items() if k != "poses"}, indent=2))
