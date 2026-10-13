"""Installed-skin evaluator for the F36 pose post-pass.

Reads an installed GLB's skinned mesh, joints, weights and triangles once and
poses it with the same rule the runtime uses: each bone's local rest times
the recipe's Euler delta, composed parent-first, times its inverse bind, then
the pivot rotation. Measurements are in model space (+Y up) and only used to
author recipe numbers; nothing here touches meshes, binds or runtime data.
"""
import json
import math
import struct
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
TORSO_BONES = {'root', 'pelvis', 'spine', 'chest', 'abdomen', 'thorax'}
_FORMATS = {5121: np.uint8, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
_WIDTHS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}


def euler_matrix(degrees):
    """Godot Quaternion.from_euler (YXZ) as a 3x3 rotation."""
    x, y, z = (math.radians(v) for v in degrees)
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return ry @ rx @ rz


def column_major(values):
    return np.array(values, dtype=float).reshape(4, 4).T


class Skin:
    def __init__(self, model_path, rig_contract, bones):
        raw = (ROOT / model_path.replace('res://', '')).read_bytes()
        length = struct.unpack_from('<I', raw, 12)[0]
        gltf = json.loads(raw[20:20 + length])
        binary = raw[20 + length + 8:]
        self.bones = list(bones)
        self.index = {b: i for i, b in enumerate(self.bones)}
        self.parent = [self.index.get(rig_contract[b].get('parent') or '', -1) for b in self.bones]
        self.rest = [column_major(rig_contract[b]['rest']) for b in self.bones]
        order, seen = [], set()

        def visit(i):
            if i in seen:
                return
            if self.parent[i] >= 0:
                visit(self.parent[i])
            seen.add(i)
            order.append(i)
        for i in range(len(self.bones)):
            visit(i)
        self.order = order

        def accessor(index):
            item = gltf['accessors'][index]
            view = gltf['bufferViews'][item['bufferView']]
            dtype = _FORMATS[item['componentType']]
            width = _WIDTHS[item['type']]
            start = view.get('byteOffset', 0) + item.get('byteOffset', 0)
            itemsize = np.dtype(dtype).itemsize * width
            stride = view.get('byteStride', itemsize)
            if stride == itemsize:
                data = np.frombuffer(binary, dtype=dtype, count=item['count'] * width, offset=start)
                data = data.reshape(item['count'], width)
            else:
                rows = [np.frombuffer(binary, dtype=dtype, count=width, offset=start + i * stride)
                        for i in range(item['count'])]
                data = np.stack(rows)
            data = data.astype(float)
            if item.get('normalized') and item['componentType'] != 5126:
                data /= {5121: 255.0, 5123: 65535.0}[item['componentType']]
            return data

        positions, weights, joints, tris = [], [], [], []
        offset = 0
        for node in gltf['nodes']:
            if 'mesh' not in node or 'skin' not in node:
                continue
            skin = gltf['skins'][node['skin']]
            names = [gltf['nodes'][j]['name'] for j in skin['joints']]
            inverse = accessor(skin['inverseBindMatrices'])
            binds = {n: inverse[k].reshape(4, 4).T for k, n in enumerate(names)}
            self.binds = [binds.get(b, np.eye(4)) for b in self.bones]
            remap = np.array([self.index[n] for n in names])
            for primitive in gltf['meshes'][node['mesh']]['primitives']:
                attributes = primitive['attributes']
                p = accessor(attributes['POSITION'])
                j = remap[accessor(attributes['JOINTS_0']).astype(int)]
                w = accessor(attributes['WEIGHTS_0'])
                w = w / np.maximum(w.sum(axis=1, keepdims=True), 1e-9)
                positions.append(p)
                joints.append(j)
                weights.append(w)
                if 'indices' in primitive:
                    tris.append(accessor(primitive['indices']).astype(int).reshape(-1, 3) + offset)
                offset += len(p)
        self.positions = np.concatenate(positions)
        self.joints = np.concatenate(joints)
        self.weights = np.concatenate(weights)
        tri = np.concatenate(tris) if tris else np.zeros((0, 3), int)
        edges = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
        edges = np.unique(np.sort(edges, axis=1), axis=0)
        self.edges = edges
        dominant = self.joints[np.arange(len(self.joints)), self.weights.argmax(axis=1)]
        self.dominant = dominant
        torso = np.zeros(len(self.positions))
        for b in TORSO_BONES & set(self.bones):
            torso += np.where(self.joints == self.index[b], self.weights, 0).sum(axis=1)
        self.torso = torso >= 0.5
        if self.torso.sum() < len(self.positions) * 0.02:
            centre = self.positions.mean(axis=0)
            distance = np.linalg.norm(self.positions - centre, axis=1)
            self.torso = distance <= np.quantile(distance, 0.33)
        self.rest_points = self.pose({})
        self.rest_edges = np.linalg.norm(self.rest_points[edges[:, 0]] - self.rest_points[edges[:, 1]], axis=1)
        self.height = float(np.ptp(self.rest_points[:, 1]))

    def globals(self, eulers):
        out = [None] * len(self.bones)
        for i in self.order:
            local = self.rest[i].copy()
            delta = eulers.get(self.bones[i])
            if delta is not None:
                local[:3, :3] = local[:3, :3] @ euler_matrix(delta)
            out[i] = out[self.parent[i]] @ local if self.parent[i] >= 0 else local
        return out

    def pose(self, eulers, pivot=None):
        g = self.globals(eulers)
        mats = np.stack([g[i] @ self.binds[i] for i in range(len(self.bones))])
        p = np.concatenate([self.positions, np.ones((len(self.positions), 1))], axis=1)
        posed = np.zeros((len(p), 3))
        for k in range(self.joints.shape[1]):
            m = mats[self.joints[:, k]]
            posed += self.weights[:, k:k + 1] * np.einsum('nij,nj->ni', m[:, :3, :], p)
        if pivot is not None:
            posed = posed @ euler_matrix(pivot).T
        return posed

    def joint_positions(self, eulers, pivot=None):
        g = self.globals(eulers)
        pts = np.stack([m[:3, 3] for m in g])
        return pts @ euler_matrix(pivot).T if pivot is not None else pts

    def descendants(self, bone):
        root = self.index[bone]
        out = {root}
        changed = True
        while changed:
            changed = False
            for i, p in enumerate(self.parent):
                if p in out and i not in out:
                    out.add(i)
                    changed = True
        return out

    def stretch(self, points):
        posed = np.linalg.norm(points[self.edges[:, 0]] - points[self.edges[:, 1]], axis=1)
        valid = self.rest_edges > self.height * 0.002
        return float((posed[valid] / self.rest_edges[valid]).max()) if valid.any() else 1.0
