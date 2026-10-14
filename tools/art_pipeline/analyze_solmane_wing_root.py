"""Read-only topology census for the disabled Solmane wing-root candidate GLB."""
from __future__ import annotations
import argparse
import json
import struct
from collections import defaultdict, deque
from pathlib import Path
import numpy as np

COMPONENTS = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}

def read_glb(path: Path):
    data = path.read_bytes()
    if data[:4] != b"glTF": raise ValueError("not a GLB")
    _, version, total = struct.unpack_from("<4sII", data, 0)
    if version != 2 or total != len(data): raise ValueError("unexpected GLB header")
    offset, doc, binary = 12, None, None
    while offset < len(data):
        length, kind = struct.unpack_from("<I4s", data, offset); offset += 8
        chunk = data[offset:offset + length]; offset += length
        if kind == b"JSON": doc = json.loads(chunk)
        elif kind == bytes((66, 73, 78, 0)): binary = chunk
    if doc is None or binary is None: raise ValueError("missing JSON/BIN chunk")
    return doc, binary

def accessor(doc, binary, accessor_index):
    a = doc["accessors"][accessor_index]; view = doc["bufferViews"][a["bufferView"]]
    dtype = np.dtype(COMPONENTS[a["componentType"]]); width = WIDTHS[a["type"]]
    stride = view.get("byteStride", dtype.itemsize * width)
    start = view.get("byteOffset", 0) + a.get("byteOffset", 0)
    result = np.ndarray((a["count"], width), dtype=dtype, buffer=binary, offset=start,
                        strides=(stride, dtype.itemsize)).copy()
    return result

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb", type=Path)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--tolerance", type=float, default=1e-4)
    ap.add_argument("--boundary-max-length", type=float, default=.40)
    args = ap.parse_args()
    doc, binary = read_glb(args.glb)
    primitive = doc["meshes"][0]["primitives"][0]
    attrs = primitive["attributes"]
    pos = accessor(doc, binary, attrs["POSITION"]).astype(np.float64)
    joints = accessor(doc, binary, attrs["JOINTS_0"])
    weights = accessor(doc, binary, attrs["WEIGHTS_0"]).astype(np.float64)
    uv = accessor(doc, binary, attrs["TEXCOORD_0"]).astype(np.float64)
    triangles = accessor(doc, binary, primitive["indices"]).reshape(-1, 3).astype(np.int64)
    joint_names = [doc["nodes"][idx].get("name", str(i)) for i, idx in enumerate(doc["skins"][0]["joints"])]
    tol = args.tolerance
    _, weld = np.unique(np.rint(pos / tol).astype(np.int64), axis=0, return_inverse=True)
    tri = weld[triangles]
    edge_tri = np.concatenate((tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]), axis=0)
    edge_tri.sort(axis=1)
    unique_edges, inverse, counts = np.unique(edge_tri, axis=0, return_counts=True, return_inverse=True)
    boundaries = unique_edges[counts == 1]
    nonmanifold = unique_edges[counts > 2]
    # Use mean welded position/UV and dominant skin contribution for contour classification.
    welded_pos = np.zeros((weld.max() + 1, 3)); np.add.at(welded_pos, weld, pos); wcount = np.bincount(weld); welded_pos /= wcount[:, None]
    adjacency = defaultdict(set)
    for a, b in boundaries:
        adjacency[int(a)].add(int(b)); adjacency[int(b)].add(int(a))
    contours, visited = [], set()
    for seed in adjacency:
        if seed in visited: continue
        queue = [seed]; visited.add(seed); vertices = []
        while queue:
            cur = queue.pop(); vertices.append(cur)
            for nxt in adjacency[cur]:
                if nxt not in visited: visited.add(nxt); queue.append(nxt)
        vertex_set = set(vertices)
        edges = [(int(a), int(b)) for a, b in boundaries if int(a) in vertex_set and int(b) in vertex_set]
        q = welded_pos[vertices]
        lengths = [float(np.linalg.norm(welded_pos[a] - welded_pos[b])) for a, b in edges]
        degrees = [len(adjacency[v]) for v in vertices]
        # Average per original vertex skin weights after welding.
        orig = np.flatnonzero(np.isin(weld, vertices))
        score = np.zeros(len(joint_names))
        for row in range(4): np.add.at(score, joints[orig, row], weights[orig, row])
        dominant = int(np.argmax(score))
        uv_range = uv[orig].max(0) - uv[orig].min(0)
        contours.append({
            "id": len(contours), "boundary_edges": len(edges), "vertices": len(vertices),
            "degree_max": max(degrees), "branch_vertices": sum(d != 2 for d in degrees),
            "closed_simple_loop": all(d == 2 for d in degrees),
            "bbox_min_m": q.min(0).round(5).tolist(), "bbox_max_m": q.max(0).round(5).tolist(),
            "center_m": q.mean(0).round(5).tolist(), "perimeter_m": round(sum(lengths), 5),
            "max_edge_m": round(max(lengths), 5), "max_skin_joint": joint_names[dominant],
            "top_skin_joints": sorted([(joint_names[i], round(float(score[i]), 3)) for i in range(len(score))], key=lambda x:-x[1])[:4],
            "uv_extent": uv_range.round(5).tolist(),
        })
    contours.sort(key=lambda c: (-c["boundary_edges"], c["id"]))
    for i, c in enumerate(contours): c["rank"] = i + 1
    wing_roots = []
    for name in ("wing_l_1", "wing_r_1"):
        jidx = joint_names.index(name)
        mask = np.any((joints == jidx) & (weights >= .05), axis=1)
        q = pos[mask]
        wing_roots.append({"joint": name, "vertices": int(mask.sum()), "bbox_min_m": q.min(0).round(5).tolist(),
                           "bbox_max_m": q.max(0).round(5).tolist()})
    result = {
        "source": str(args.glb), "source_bytes": len(args.glb.read_bytes()), "vertices": int(len(pos)),
        "triangles": int(len(triangles)), "bones": len(joint_names), "height_m": float(pos[:, 1].max() - pos[:, 1].min()),
        "weld_tolerance_m": tol, "boundary_edges": int(len(boundaries)), "nonmanifold_edges": int(len(nonmanifold)),
        "contour_components": contours, "wing_root_joint_bounds": wing_roots,
        "selection_note": "Read-only coordinate/skin census. No contour is declared a hole until UV, feather-layer and surface orientation review.",
        "short_boundary_contours": [c["id"] for c in contours if c["closed_simple_loop"] and c["max_edge_m"] <= args.boundary_max_length],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps({k: result[k] for k in ("vertices", "triangles", "bones", "height_m", "weld_tolerance_m", "boundary_edges", "nonmanifold_edges")}, indent=2))
    for c in contours:
        x, y, z = c["center_m"]
        if abs(x) <= 1.7 and 3.2 <= y <= 4.7 and z >= 1.0 and c["boundary_edges"] >= 20:
            print(c["id"], "edges", c["boundary_edges"], "branches", c["branch_vertices"], "root", c["max_skin_joint"], "center", c["center_m"], "UV", c["uv_extent"])

if __name__ == "__main__": main()


