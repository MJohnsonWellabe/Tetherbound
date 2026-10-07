"""Skin a textured mesh by borrowing weights from its own clean twin.

    blender --background --python tools/art_pipeline/blender/skin_transfer.py \
            -- <rigged_clean.glb> <textured.glb> --out <rigged_textured.glb>

Bone-heat automatic weighting is a lottery on Meshy retexture output. The
retexture stage re-meshes: Terrapup came back weldable and heat succeeded;
Ripplet came back with geometry that fails heat outright — "failed to find
solution", 14,025 of 14,025 vertices unweighted — after the identical weld
pass. The mesh that ALWAYS weights cleanly is the voxel-remeshed manifold
that cleanup_mesh.py produces, because that is the whole point of it.

So: rig the clean mesh (rig_quadruped / rig_glider / rig_sitter — heat
succeeds there), then bring the TEXTURED mesh into the same file and copy
vertex weights across by nearest-face interpolation. The two meshes are the
same shape to within the retexture's remeshing noise, so nearest-surface
transfer is exact for practical purposes. The clean donor mesh is deleted
after the transfer; the textured mesh inherits the armature.

This sidesteps heat entirely for textured models, for every future creature.
"""

import pathlib
import sys
import hashlib
import json
import math

import bpy


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def main() -> None:
    args = argv_after_double_dash()
    if len(args) < 2:
        raise SystemExit("usage: ... skin_transfer.py -- <rigged_clean.glb> "
                         "<textured.glb> --out <out.glb>")
    donor_path = pathlib.Path(args[0]).resolve()
    textured_path = pathlib.Path(args[1]).resolve()
    out = pathlib.Path(option(args, "--out", textured_path.with_name("rigged_textured.glb"))).resolve()
    preserve = "--preserve-target-geometry" in args
    yaw = float(option(args, "--alignment-yaw-deg", "0"))
    report_path = option(args, "--report")
    if preserve and (out in (donor_path, textured_path) or out.exists() or not report_path
                     or not math.isfinite(yaw) or abs(yaw) > 180):
        raise SystemExit("Preserved transfer requires fresh separate output, report and finite alignment yaw")
    input_hashes = {str(p): hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in (donor_path, textured_path)} if preserve else {}

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(donor_path))

    rigs = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    donors = [o for o in bpy.data.objects if o.type == "MESH"]
    if not rigs or not donors:
        raise SystemExit(f"{donor_path.name} must contain an armature and a skinned mesh")
    rig = rigs[0]
    if preserve and len(rigs) != 1:
        raise SystemExit("Preserved transfer requires exactly one donor armature")
    rig_transform = rig.matrix_world.copy()
    pose_position = rig.data.pose_position
    if preserve:
        rig.data.pose_position = "REST"
    # The donor is EVERY mesh that carries weights, joined into one surface.
    #
    # This used to be `max(donors, key=vertex_group_count)`, which is right for
    # a single-object creature and silently catastrophic for a modular one: a
    # character built as body / head / arms / legs / cape gives every part the
    # same 23 groups, so max() returned whichever came first alphabetically —
    # an arm — and the whole target was then weighted from nearest faces on
    # that arm. It reports "0 unweighted" and deforms like nothing on earth.
    skinned = [obj for obj in donors if obj.vertex_groups]
    if not skinned:
        raise SystemExit(f"{donor_path.name} has no mesh with vertex groups — rig it first")
    if preserve and len(skinned) != 1:
        raise SystemExit("Preserved transfer requires one complete skinned donor; no joins")
    for stray in donors:
        if stray not in skinned:
            print(f"  dropping stray unskinned object: {stray.name}")
            bpy.data.objects.remove(stray, do_unlink=True)

    bpy.ops.object.select_all(action="DESELECT")
    for part in skinned:
        part.select_set(True)
    bpy.context.view_layer.objects.active = skinned[0]
    if len(skinned) > 1:
        print(f"  donor is {len(skinned)} skinned parts joined: "
              f"{', '.join(o.name for o in skinned)}")
        bpy.ops.object.join()
    donor = bpy.context.view_layer.objects.active

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(textured_path))
    target_meshes = [o for o in set(bpy.data.objects) - before if o.type == "MESH"]
    if not target_meshes:
        raise SystemExit(f"no mesh in {textured_path.name}")
    if preserve and (len(target_meshes) != 1 or target_meshes[0].vertex_groups):
        raise SystemExit("Preserved transfer requires one untouched unskinned target; no joins")

    # One target mesh: join if the import split it.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in target_meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = target_meshes[0]
    if len(target_meshes) > 1:
        bpy.ops.object.join()
    target = bpy.context.view_layer.objects.active
    def geometry_signature(obj):
        return (tuple(tuple(v.co) for v in obj.data.vertices),
                tuple(tuple(p.vertices) for p in obj.data.polygons),
                tuple(tuple(tuple(loop.uv) for loop in layer.data) for layer in obj.data.uv_layers),
                tuple(obj.data.materials))
    original_geometry = geometry_signature(target) if preserve else None
    if preserve:
        target.rotation_euler.z += math.radians(yaw)
        bpy.context.view_layer.update()
    else:
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # The donor was normalised by its rig script (feet on z=0, centred); the
    # textured mesh arrives however Meshy left it. Align by bounding box so
    # nearest-face lookups land on the right body parts.
    from mathutils import Vector
    import math
    def box(obj):
        low = Vector((math.inf,) * 3)
        high = Vector((-math.inf,) * 3)
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            low = Vector(map(min, low, point))
            high = Vector(map(max, high, point))
        return low, high
    d_low, d_high = box(donor)
    t_low, t_high = box(target)
    scale = max(d_high - d_low) / max(max(t_high - t_low), 1e-9)
    target.scale = target.scale * scale if preserve else Vector((scale,) * 3)
    if preserve:
        bpy.context.view_layer.update()
    else:
        bpy.ops.object.transform_apply(scale=True)
    t_low, t_high = box(target)
    target.location += Vector((
        (d_low.x + d_high.x) / 2 - (t_low.x + t_high.x) / 2,
        (d_low.y + d_high.y) / 2 - (t_low.y + t_high.y) / 2,
        d_low.z - t_low.z,
    ))
    if preserve:
        bpy.context.view_layer.update()
    else:
        bpy.ops.object.transform_apply(location=True)

    # The transfer itself: nearest face interpolation, all vertex groups.
    modifier = target.modifiers.new("weights", "DATA_TRANSFER")
    modifier.object = donor
    modifier.use_vert_data = True
    modifier.data_types_verts = {"VGROUP_WEIGHTS"}
    modifier.vert_mapping = "POLYINTERP_NEAREST"
    modifier.layers_vgroup_select_src = "ALL"
    if preserve:
        modifier.use_object_transform = True
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.datalayout_transfer(modifier=modifier.name)
    bpy.ops.object.modifier_apply(modifier=modifier.name)

    # Bind to the armature without recomputing weights.
    armature_mod = target.modifiers.new("Armature", "ARMATURE")
    armature_mod.object = rig
    aligned_transform = target.matrix_world.copy()
    target.parent = rig
    if preserve:
        target.matrix_world = aligned_transform
        bpy.context.view_layer.update()

    trimmed = 0
    if preserve:
        for vertex in target.data.vertices:
            weights = [(g.group, g.weight) for g in vertex.groups
                       if target.vertex_groups[g.group].name in rig.data.bones]
            if any(not math.isfinite(w) or w < 0 for _, w in weights):
                raise SystemExit("Transferred weights contain invalid numbers")
            weights = sorted(((g, w) for g, w in weights if w > 0), key=lambda pair: (-pair[1], pair[0]))
            trimmed += max(0, len(weights) - 4)
            weights = weights[:4]
            total = sum(w for _, w in weights)
            if total < 1e-4:
                raise SystemExit("Preserved transfer left an unweighted vertex; refusing export")
            for group_index in [g.group for g in vertex.groups]:
                target.vertex_groups[group_index].remove([vertex.index])
            for group, weight in weights:
                target.vertex_groups[group].add([vertex.index], weight / total, "REPLACE")
        if geometry_signature(target) != original_geometry or rig.matrix_world != rig_transform:
            raise SystemExit("Transfer changed target geometry/UV/material bindings or donor rig transform")
        if any(abs(sum(g.weight for g in v.groups) - 1.0) > 1e-5 or len(v.groups) > 4
               for v in target.data.vertices):
            raise SystemExit("Transferred skin is not normalized to at most four influences")
        if any(abs(target.matrix_world[row][col] - aligned_transform[row][col]) > 1e-6
               for row in range(4) for col in range(4)):
            raise SystemExit("Armature parenting changed target world transform")
        rig.data.pose_position = pose_position

    unweighted = sum(1 for v in target.data.vertices
                     if sum(g.weight for g in v.groups) < 1e-4)

    # The donor mesh's job is done.
    bpy.data.objects.remove(donor, do_unlink=True)

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB",
                              export_skins=True, export_animations=True,
                              export_yup=True)
    if preserve:
        if any(hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest() != digest
               for p, digest in input_hashes.items()):
            raise SystemExit("Transfer overwrote an input asset")
        pathlib.Path(report_path).write_text(json.dumps({
            "mode": "preserved_target_skin_transfer", "input_sha256": input_hashes,
            "output_sha256": hashlib.sha256(out.read_bytes()).hexdigest(),
            "target_geometry_uv_material_bindings_unchanged_before_export": True,
            "donor_rig_world_transform_unchanged": True, "transfer_rest_pose": True,
            "parent_world_transform_preserved": True, "alignment_yaw_deg": yaw,
            "alignment_uniform_scale": scale, "vertices": len(target.data.vertices),
            "unweighted_vertices": unweighted, "max_influences": max(len(v.groups) for v in target.data.vertices),
            "trimmed_influences": trimmed, "weights_normalized": True,
            "scope": "Pre-export data and source guards only; export reimport/deformation/native scale/judge still required"
        }, indent=2) + "\n")
    print(f"\n{textured_path.name} skinned from {donor_path.name} -> {out.name}")
    print(f"  {len(target.data.vertices)} vertices, {unweighted} unweighted after transfer")
    if unweighted:
        print("  UNWEIGHTED VERTICES PRESENT — the shapes may not align; inspect.")


if __name__ == "__main__":
    main()
