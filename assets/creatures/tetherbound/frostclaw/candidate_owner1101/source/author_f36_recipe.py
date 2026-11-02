"""F36 pose recipe for the Frostclaw owner-rule remake (1 Nov 2026).

The F36 pose library (data/creatures/f36_pose_candidates.json) binds the
judged `frostclaw_quadruped_anatomical` profile to the installed Frostclaw rig
by file hash, resource uid and measured bone rests. The remake's dog3 rig has
the same 15 bone names and hierarchy (no `neutral_bone`) but different rest
frames (axis flips on pelvis, neck, tail and the upper legs).

`install` poses each bone as `rest * delta` (local). With C_i the change of
bone i's skeleton-space rest rotation (C_i = W_old_i^-1 W_new_i), the delta
`C_i^-1 delta_i C_i` gives every bone the same skeleton-space motion, so the
skinned deformation (posed * inverse bind) and the judged pose carry over
exactly. Euler triples use Godot's Quaternion.from_euler order (YXZ).
Pivot roll/rotation act on the model pivot and are unchanged.

Writes `species.frostclaw.model_alternates[0]` (the remake recipe) and the
converted profile `frostclaw_owner1101_quadruped_anatomical`, by targeted text
insertion so the rest of the file is untouched. Idempotent.

    python3 assets/creatures/tetherbound/frostclaw/candidate_owner1101/source/author_f36_recipe.py
"""
import hashlib
import json
import os
import re
import struct

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
DATA = os.path.join(ROOT, "data", "creatures", "f36_pose_candidates.json")
OLD = os.path.join(ROOT, "assets/creatures/tetherbound/frostclaw/models/creature_frostclaw_lod0.glb")
NEW_RES = "res://assets/creatures/tetherbound/frostclaw/candidate_owner1101/models/creature_frostclaw_owner1101.glb"
NEW = os.path.join(ROOT, NEW_RES[len("res://"):])
SOURCE_PROFILE = "frostclaw_quadruped_anatomical"
PROFILE = "frostclaw_owner1101_quadruped_anatomical"
CT = {5126: np.float32}


def read_glb(path):
    data = open(path, "rb").read()
    n = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20:20 + n])
    blob = data[20 + n + 8:]
    return gltf, blob


def accessor(gltf, blob, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    count = {"MAT4": 16, "VEC3": 3, "VEC4": 4, "SCALAR": 1}[acc["type"]]
    off = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    return np.frombuffer(blob, CT[acc["componentType"]], acc["count"] * count, off).reshape(acc["count"], count).astype(np.float64)


def quat_matrix(q):
    x, y, z, w = np.asarray(q, np.float64) / np.linalg.norm(q)
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def local(node):
    m = np.eye(4)
    m[:3, :3] = quat_matrix(node.get("rotation", [0, 0, 0, 1])) * np.asarray(node.get("scale", [1, 1, 1]))
    m[:3, 3] = node.get("translation", [0, 0, 0])
    return m


def rig(path):
    gltf, blob = read_glb(path)
    nodes = gltf["nodes"]
    skin = gltf["skins"][0]
    joints = skin["joints"]
    names = {i: nodes[i].get("name") for i in joints}
    parent = {}
    for i, node in enumerate(nodes):
        for child in node.get("children", []):
            parent[child] = i
    world = {}

    def skeleton_space(i):
        if i not in world:
            m = local(nodes[i])
            if i in parent and parent[i] in names:
                m = skeleton_space(parent[i]) @ m
            world[i] = m
        return world[i]

    ibm = accessor(gltf, blob, skin["inverseBindMatrices"])
    out = {}
    for k, i in enumerate(joints):
        w = skeleton_space(i)[:3, :3]
        u, _, vt = np.linalg.svd(w)
        out[names[i]] = {
            "parent": names.get(parent.get(i), ""),
            "rest": [float(v) for v in local(nodes[i]).T.ravel()],
            "bind": [float(v) for v in ibm[k]],
            "world_rot": u @ vt,
        }
    return out


def rx(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def ry(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rz(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def from_euler_yxz(deg):
    x, y, z = np.radians(deg)
    return ry(y) @ rx(x) @ rz(z)


def to_euler_yxz(m):
    x = np.arcsin(np.clip(-m[1, 2], -1.0, 1.0))
    if abs(m[1, 2]) < 0.9999999:
        y = np.arctan2(m[0, 2], m[2, 2])
        z = np.arctan2(m[1, 0], m[1, 1])
    else:
        y = np.arctan2(-m[2, 0], m[0, 0])
        z = 0.0
    return [round(float(v), 4) for v in np.degrees([x, y, z])]


def dumps(value, indent):
    """json.dumps(indent=1) with number arrays kept on one line, like the file."""
    text = json.dumps(value, indent=1)
    text = re.sub(r"\[\s*(-?[0-9][-0-9.e+,\s]*?)\s*\]",
                  lambda m: "[" + ", ".join(x.strip() for x in m.group(1).split(",")) + "]", text)
    return text.replace("\n", "\n" + indent)


def main():
    data = json.load(open(DATA))
    old_rig, new_rig = rig(OLD), rig(NEW)
    bones = [b for b in data["species"]["frostclaw"]["bones"] if b in new_rig]
    assert sorted(bones) == sorted(new_rig), (bones, sorted(new_rig))
    change = {b: old_rig[b]["world_rot"].T @ new_rig[b]["world_rot"] for b in bones}
    source = data["profiles"][SOURCE_PROFILE]
    profile = {}
    worst = 0.0
    for role, spec in source.items():
        converted = json.loads(json.dumps(spec))
        for frame in converted["frames"]:
            rotations = {}
            for bone in bones:
                delta = from_euler_yxz(frame["bones"][bone])
                c = change[bone]
                rotations[bone] = to_euler_yxz(c.T @ delta @ c)
                worst = max(worst, float(np.abs(from_euler_yxz(rotations[bone]) - c.T @ delta @ c).max()))
            frame["bones"] = rotations
        profile[role] = converted
    # Check: posed skeleton-space rotations agree up to each bone's rest change.
    for role, spec in profile.items():
        for frame, old_frame in zip(spec["frames"], source[role]["frames"]):
            posed_old, posed_new = {}, {}
            for bone in bones:
                for rig_, frame_, out in ((old_rig, old_frame, posed_old), (new_rig, frame, posed_new)):
                    rest = np.array(rig_[bone]["rest"]).reshape(4, 4).T[:3, :3]
                    u, _, vt = np.linalg.svd(rest)
                    p = rig_[bone]["parent"]
                    out[bone] = (out[p] if p else np.eye(3)) @ (u @ vt) @ from_euler_yxz(frame_["bones"][bone])
            for bone in bones:
                worst = max(worst, float(np.abs(posed_new[bone] - posed_old[bone] @ change[bone]).max()))
    assert worst < 1e-3, worst
    import_text = open(NEW + ".import").read()
    uid = re.search(r'uid="(uid://[^"]+)"', import_text).group(1)
    recipe = {
        "_why": "Owner-rule remake (remake_owner1101_frostclaw, 1 Nov 2026): the judged frostclaw_quadruped_anatomical poses converted onto the remake's dog3 rig (same bone names; rest frames differ), so the measured-rig preview and the owner-enabled poses install on it. Script: frostclaw/candidate_owner1101/source/author_f36_recipe.py.",
        "model": NEW_RES,
        "source_sha256": hashlib.sha256(open(NEW, "rb").read()).hexdigest(),
        "resource_uid": uid,
        "rig_contract": {b: {"parent": new_rig[b]["parent"], "rest": new_rig[b]["rest"]} for b in bones},
        "bind_contract": {b: new_rig[b]["bind"] for b in bones},
        "rig_family": data["species"]["frostclaw"]["rig_family"],
        "bones": bones,
        "profile": PROFILE,
        "grounded_roles": data["species"]["frostclaw"]["grounded_roles"],
    }
    text = open(DATA).read()
    # Targeted insertions: the species row gains `model_alternates`, and the
    # profiles block gains the converted profile; nothing else is rewritten.
    row_start = text.index('"frostclaw": {', text.index('"species": {'))
    profile_key = text.index('"profile": "%s"' % SOURCE_PROFILE, row_start)
    if '"model_alternates"' not in text[row_start:text.index('"profile": "%s"' % SOURCE_PROFILE, row_start) + 400]:
        line = text.rfind("\n", 0, profile_key) + 1
        indent = text[line:profile_key]
        block = dumps([recipe], indent)
        text = text[:line] + indent + '"model_alternates": ' + block + ",\n" + text[line:]
    if '"%s": {' % PROFILE not in text:
        src = text.index('"%s": {' % SOURCE_PROFILE, text.index('"profiles": {'))
        line = text.rfind("\n", 0, src) + 1
        indent = text[line:src]
        block = dumps(profile, indent)
        text = text[:line] + indent + '"%s": ' % PROFILE + block + ",\n" + text[line:]
    json.loads(text)
    open(DATA, "w").write(text)
    print("bones %d, max conversion error %.2e, sha %s, uid %s" % (len(bones), worst, recipe["source_sha256"][:12], uid))


if __name__ == "__main__":
    main()
