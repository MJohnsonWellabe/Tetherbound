"""Retime the Torrentoad remake's attack clip to the installed contact timing.

The installed Torrentoad attack (animate_quadruped.py) spans 23 frame intervals
(23/24 s) with contact at frame 15 (0.625 s), and species.json carries
attack_contact_phase 15/23 for WildCreature's telegraph stretch
(tests/test_creature_attack_telegraph_animation.gd). The dog3 clip author gives
the remake a 24-frame attack keyed at times 1/24..25/24 whose strike peaks at
t = 0.325 (frame 7.8: pulse = sin(pi * t / 0.65)). This remaps the clip's key
times piecewise so the wind-up runs from 0 to the 15/24 s contact and the
recovery to 23/24 s. Poses, bones and every other clip are untouched.

    python3 assets/creatures/tetherbound/torrentoad/candidate_owner1101/source/retime_attack_contact.py
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (_read_glb / _write_glb)

MODEL = os.path.join(HERE, "..", "models", "creature_torrentoad_owner1101.glb")
FPS = 24.0
SOURCE_FRAMES = 24.0       # dog3 attack: frames 0..24, exported at (f + 1) / 24
SOURCE_PEAK = 0.325 * 24.0  # frame 7.8
CONTACT = 15.0 / FPS
LENGTH = 23.0 / FPS


def remap(t):
    f = t * FPS - 1.0
    if f <= SOURCE_PEAK:
        return CONTACT * f / SOURCE_PEAK
    return CONTACT + (LENGTH - CONTACT) * (f - SOURCE_PEAK) / (SOURCE_FRAMES - SOURCE_PEAK)


def main():
    gltf, views = T._read_glb(MODEL)
    attack = [a for a in gltf["animations"] if a["name"] == "attack"][0]
    inputs = sorted({s["input"] for s in attack["samplers"]})
    for other in gltf["animations"]:
        if other is not attack:
            assert not {s["input"] for s in other["samplers"]} & set(inputs), "attack key times are shared"
    for index in inputs:
        acc = gltf["accessors"][index]
        assert acc["componentType"] == 5126 and acc["type"] == "SCALAR" and "byteOffset" not in acc
        view = bytearray(views[acc["bufferView"]])
        times = list(struct.unpack_from("<%df" % acc["count"], view, 0))
        if abs(times[-1] - LENGTH) < 1e-6 and abs(times[0]) < 1e-6:
            print("accessor %d already retimed" % index)
            continue
        assert abs(times[0] - 1.0 / FPS) < 1e-5 and abs(times[-1] - (SOURCE_FRAMES + 1.0) / FPS) < 1e-5, times
        new = [remap(t) for t in times]
        struct.pack_into("<%df" % acc["count"], view, 0, *new)
        views[acc["bufferView"]] = bytes(view)
        acc["min"], acc["max"] = [min(new)], [max(new)]
        print("accessor %d: %.6f..%.6f -> %.6f..%.6f" % (index, times[0], times[-1], new[0], new[-1]))
    T._write_glb(MODEL, gltf, views)


if __name__ == "__main__":
    main()
