#!/usr/bin/env python3
"""Ground Torrentoad's authored attack without changing its silhouette or timing.

The installed clip rotates the rig through the floor: a native Godot sweep measured
the rendered minimum at -0.92 m near contact.  Its root translation has only two
constant keys, so this replaces that channel with one calibrated lift key per source
frame.  The values are model-local and therefore remain correct for both the base and
namespaced Water presentation scales.
"""

from __future__ import annotations

import hashlib
import json
import pathlib
import struct


ROOT = pathlib.Path(__file__).resolve().parents[1]
MODEL = ROOT / "assets/creatures/tetherbound/torrentoad/models/creature_torrentoad_lod0.glb"
SOURCE_SHA256 = "98A492C3A12E751E418D39D8E8704AA74E2A39F6A23DB89FD74A8ABF777DA230"
ROOT_SAFETY_MARGIN = 0.006

# (seconds, model-local Y lift). Derived from the calibrated CPU skinning model at
# every 24 fps source frame, with a 0.5 mm local safety margin only where the
# uncorrected deformed mesh crossed the floor.
LIFT_KEYS = [
    (0.000000000, 0.191654611), (0.041666667, 0.191654611),
    (0.083333333, 0.200132296), (0.125000000, 0.221955451),
    (0.166666667, 0.250922450), (0.208333333, 0.280929718),
    (0.250000000, 0.307097265), (0.291666667, 0.326946478),
    (0.333333333, 0.339371633), (0.375000000, 0.345688603),
    (0.416666667, 0.347944783), (0.458333333, 0.348340386),
    (0.500000000, 0.303896651), (0.541666667, 0.184892339),
    (0.583333333, 0.021714210), (0.625000000, 0.014275387),
    (0.666666667, 0.021716715), (0.708333333, 0.020780528),
    (0.750000000, 0.018149921), (0.791666667, 0.014199599),
    (0.833333333, 0.009363781), (0.875000000, 0.004584988),
    (0.916666667, 0.001299365), (0.958333333, 0.000000000),
]


def chunks(raw: bytes) -> tuple[dict, bytearray]:
    magic, version, length = struct.unpack_from("<III", raw, 0)
    if magic != 0x46546C67 or version != 2 or length != len(raw):
        raise SystemExit("Torrentoad source is not a valid glTF 2 GLB")
    offset = 12
    document = None
    binary = None
    while offset < len(raw):
        size, kind = struct.unpack_from("<II", raw, offset)
        payload = raw[offset + 8:offset + 8 + size]
        if kind == 0x4E4F534A:
            document = json.loads(payload)
        elif kind == 0x004E4942:
            binary = bytearray(payload)
        offset += 8 + size
    if document is None or binary is None:
        raise SystemExit("Torrentoad GLB lacks JSON or BIN data")
    return document, binary


def accessor_values(document: dict, binary: bytearray, index: int) -> list[tuple[float, ...]]:
    accessor = document["accessors"][index]
    view = document["bufferViews"][accessor["bufferView"]]
    width = {"SCALAR": 1, "VEC3": 3}[accessor["type"]]
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    stride = view.get("byteStride", width * 4)
    return [struct.unpack_from("<" + "f" * width, binary, start + row * stride)
            for row in range(accessor["count"])]


def append_accessor(document: dict, binary: bytearray, values: list[tuple[float, ...]], kind: str) -> int:
    while len(binary) % 4:
        binary.append(0)
    offset = len(binary)
    width = 1 if kind == "SCALAR" else 3
    for value in values:
        binary.extend(struct.pack("<" + "f" * width, *value))
    view_index = len(document["bufferViews"])
    document["bufferViews"].append({"buffer": 0, "byteOffset": offset,
                                     "byteLength": len(values) * width * 4})
    flattened = list(zip(*values))
    accessor = {"bufferView": view_index, "componentType": 5126,
                "count": len(values), "type": kind,
                "min": [min(axis) for axis in flattened],
                "max": [max(axis) for axis in flattened]}
    document["accessors"].append(accessor)
    return len(document["accessors"]) - 1


def overwrite_vec3_accessor(document: dict, binary: bytearray, index: int,
                            values: list[tuple[float, float, float]]) -> None:
    accessor = document["accessors"][index]
    view = document["bufferViews"][accessor["bufferView"]]
    if accessor["componentType"] != 5126 or accessor["type"] != "VEC3" or accessor["count"] != len(values):
        raise SystemExit("corrected Torrentoad root accessor has an unexpected shape")
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    stride = view.get("byteStride", 12)
    for row, value in enumerate(values):
        struct.pack_into("<fff", binary, start + row * stride, *value)
    accessor["min"] = [min(axis) for axis in zip(*values)]
    accessor["max"] = [max(axis) for axis in zip(*values)]


def write_glb(document: dict, binary: bytearray) -> None:
    document["buffers"][0]["byteLength"] = len(binary)
    encoded_json = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    encoded_json += b" " * ((-len(encoded_json)) % 4)
    binary += b"\0" * ((-len(binary)) % 4)
    total = 12 + 8 + len(encoded_json) + 8 + len(binary)
    rebuilt = (struct.pack("<III", 0x46546C67, 2, total)
               + struct.pack("<II", len(encoded_json), 0x4E4F534A) + encoded_json
               + struct.pack("<II", len(binary), 0x004E4942) + binary)
    temporary = MODEL.with_suffix(".glb.tmp")
    temporary.write_bytes(rebuilt)
    temporary.replace(MODEL)


def main() -> None:
    raw = MODEL.read_bytes()
    source_hash = hashlib.sha256(raw).hexdigest().upper()
    document, binary = chunks(raw)
    animation = next((item for item in document.get("animations", [])
                      if item.get("name") == "attack"), None)
    root = next((index for index, node in enumerate(document.get("nodes", []))
                 if node.get("name") == "root"), None)
    channel = next((item for item in animation.get("channels", [])
                    if item["target"] == {"node": root, "path": "translation"}), None) \
        if animation is not None else None
    if channel is None:
        raise SystemExit("Torrentoad attack root-translation channel is unavailable")
    sampler = animation["samplers"][channel["sampler"]]
    existing_times = accessor_values(document, binary, sampler["input"])
    existing_values = accessor_values(document, binary, sampler["output"])
    desired_first = LIFT_KEYS[0][1] + ROOT_SAFETY_MARGIN
    if len(existing_times) == len(LIFT_KEYS):
        if abs(existing_values[0][1] - desired_first) < 1e-5:
            print("Torrentoad attack grounding already applied")
            return
        if abs(existing_values[0][1] - LIFT_KEYS[0][1]) < 1e-5:
            translations = [(value[0], value[1] + (ROOT_SAFETY_MARGIN if lift > 0.0 else 0.0), value[2])
                            for value, (_time, lift) in zip(existing_values, LIFT_KEYS)]
            overwrite_vec3_accessor(document, binary, sampler["output"], translations)
            write_glb(document, binary)
            print("Raised corrected Torrentoad root keys by the trajectory interpolation margin")
            return
    if source_hash != SOURCE_SHA256 or len(existing_times) != 2 or len(existing_values) != 2:
        raise SystemExit("Torrentoad GLB differs from the calibrated source; refusing a blind rewrite")

    start_time, end_time = existing_times[0][0], existing_times[-1][0]
    start_value, end_value = existing_values
    times = [(time,) for time, _lift in LIFT_KEYS]
    translations = []
    for time, lift in LIFT_KEYS:
        amount = max(0.0, min(1.0, (time - start_time) / (end_time - start_time)))
        base = tuple(start_value[axis] + (end_value[axis] - start_value[axis]) * amount
                     for axis in range(3))
        translations.append((base[0], base[1] + lift + (ROOT_SAFETY_MARGIN if lift > 0.0 else 0.0), base[2]))
    sampler["input"] = append_accessor(document, binary, times, "SCALAR")
    sampler["output"] = append_accessor(document, binary, translations, "VEC3")
    sampler["interpolation"] = "LINEAR"
    write_glb(document, binary)
    print("Grounded Torrentoad attack with %d calibrated root keys" % len(LIFT_KEYS))


if __name__ == "__main__":
    main()
