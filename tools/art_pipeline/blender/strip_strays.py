#!/usr/bin/env python3
"""Report the meshes a GLB actually contains, by reading the file, not Blender.

    tools/art_pipeline/blender/strip_strays.py <model.glb> [<model.glb> ...]

Plain Python. It does not need Blender, and that is the entire point.

## What this used to be, and why it was wrong

This file used to remove a stray 42-vertex `Icosphere` — unskinned, no
material, a unit sphere at the origin — that appeared in every rigged model
the project had exported. Five production reports record it. A blind reviewer
found it in renders and called it "detached geometry floating free in the sky".
The removal ran, reported success, re-imported the file it had just written to
verify, and found the sphere still there. Every time.

It found it every time because there was never anything to remove. Reading the
GLB's JSON chunk shows one mesh. The sphere appears only after Blender's glTF
importer reads the file. Reproduced on Blender 4.2.9 with a cube:

    add cube, add armature, parent with automatic weights
    export GLB with this project's settings   -> file contains 1 mesh
    re-import that file                       -> scene contains 2 meshes,
                                                 the second a 42-vert Icosphere

So it is an import artifact of Blender's own round trip, and the consequences
run opposite to what was believed:

  - **Godot never saw it.** `pal_body._fit()` measures what is in the file.
    smoke_art's fitted heights were right all along.
  - **The inspection tool saw it.** A unit sphere wrapped around a creature
    standing 0..2.0 reports the height as 3.0 and the mesh count as 2. Those
    numbers were wrong in every report written from `inspect_glb.py`, which
    now drops the phantom before measuring.
  - **The reviewer's "floating geometry" was real** — in the RENDER, because
    `turntable.py` renders the Blender scene, phantom included.

## What it is now

A check, not a repair. It reads the container and prints what is really in it,
so the next person who sees an Icosphere in a Blender viewport can confirm in
one second that their file is clean. If a genuine stray mesh ever does get
exported, this is what will show it — and the fix then belongs in the stage
that wrote it, not in a repair pass bolted on afterwards.
"""

import json
import pathlib
import struct
import sys

JSON_CHUNK = 0x4E4F534A


def gltf_json(path: pathlib.Path) -> dict:
    with path.open("rb") as handle:
        magic, _version, length = struct.unpack("<III", handle.read(12))
        if magic != 0x46546C67:
            raise SystemExit(f"{path.name} is not a GLB")
        while handle.tell() < length:
            chunk_length, chunk_type = struct.unpack("<II", handle.read(8))
            payload = handle.read(chunk_length)
            if chunk_type == JSON_CHUNK:
                return json.loads(payload)
    raise SystemExit(f"{path.name} has no JSON chunk")


def report(path: pathlib.Path) -> bool:
    document = gltf_json(path)
    meshes = document.get("meshes", [])
    skins = document.get("skins", [])
    skinned = {node["mesh"] for node in document.get("nodes", [])
               if node.get("mesh") is not None and node.get("skin") is not None}

    print(f"{path.name}: {len(meshes)} mesh(es), {len(skins)} skin(s), "
          f"{len(document.get('animations', []))} clip(s)")
    strays = []
    for index, mesh in enumerate(meshes):
        vertices = sum(document["accessors"][primitive["attributes"]["POSITION"]]["count"]
                       for primitive in mesh.get("primitives", []))
        mark = "skinned" if index in skinned else "NOT SKINNED"
        print(f"    mesh {index}: {mesh.get('name')!r}, {vertices} verts, {mark}")
        if skinned and index not in skinned:
            strays.append(index)
    if strays:
        print(f"  REAL STRAY(S): {strays} — fix the stage that exported this")
    return not strays


def main() -> None:
    paths = [pathlib.Path(a).resolve() for a in sys.argv[1:] if not a.startswith("-")]
    if not paths:
        raise SystemExit(__doc__.splitlines()[2].strip())
    if not all(report(path) for path in paths):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
