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
from mathutils import Euler, Matrix, Vector


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def body_signature(body, rig):
    return (tuple(tuple(v.co) for v in body.data.vertices),
            tuple((tuple(p.vertices), p.material_index) for p in body.data.polygons),
            tuple((layer.name, tuple(tuple(loop.uv) for loop in layer.data)) for layer in body.data.uv_layers),
            tuple(group.name for group in body.vertex_groups),
            tuple(tuple((g.group, g.weight) for g in v.groups) for v in body.data.vertices),
            tuple((b.name, b.parent.name if b.parent else None,
                   tuple(tuple(row) for row in b.matrix_local)) for b in rig.data.bones),
            tuple(tuple(row) for row in body.matrix_world),
            tuple(tuple(row) for row in rig.matrix_world), tuple(bpy.data.actions))


def attach_components(args: list[str]) -> None:
    """Attach inspected additions to the existing body; never join or edit it."""
    required = ("--out", "--report", "--attachment-settings")
    if len(args) < 2 or any(args.count(key) != 1 or args.index(key) + 1 >= len(args)
                            for key in required):
        raise SystemExit("Attachment requires body, component, fresh out/report and settings")
    body_path, component_path = (pathlib.Path(value).resolve() for value in args[:2])
    out, report, settings_path = (pathlib.Path(option(args, key)).resolve() for key in required)
    inputs = (body_path, component_path, settings_path)
    if len(set(inputs + (out, report))) != 5 or out.exists() or report.exists():
        raise SystemExit("Attachment paths must be separate, with fresh output and report")
    hashes = {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in inputs}
    settings = json.loads(settings_path.read_text())["component_attachments"]
    parts = settings.get("parts", [])
    budget = settings.get("addition_triangle_budget")
    if budget != 2816 or settings.get("total_triangle_budget") != 30000 or len(parts) != 2:
        raise SystemExit("Stormursa attachment requires exactly two parts within the authorized budgets")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(body_path))
    sys.path.insert(0, str(pathlib.Path(__file__).parent))
    import inspect_glb
    inspect_glb.drop_import_phantoms()
    rigs = [obj for obj in bpy.data.objects if obj.type == "ARMATURE"]
    bodies = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    if len(rigs) != 1 or len(bodies) != 1 or not bodies[0].vertex_groups:
        raise SystemExit("Attachment requires one original weighted body and its own rig")
    body, rig = bodies[0], rigs[0]
    original = body_signature(body, rig)
    original_pose = rig.data.pose_position
    rig.data.pose_position = "REST"
    bpy.context.view_layer.update()
    body_triangles = sum(len(p.vertices) - 2 for p in body.data.polygons)
    if body_triangles != 27184:
        raise SystemExit("Attachment refuses a replaced Stormursa body")
    points = [body.matrix_world @ vertex.co for vertex in body.data.vertices]
    height = max(v.z for v in points) - min(v.z for v in points)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(component_path))
    imported = set(bpy.data.objects) - before
    sources = [obj for obj in imported if obj.type == "MESH"]
    if len(sources) != 1 or sources[0].vertex_groups or any(o.type == "ARMATURE" for o in imported):
        raise SystemExit("Attachment requires one unskinned, inspected component")
    source = sources[0]
    if not source.data.materials or not source.data.uv_layers or body_signature(body, rig) != original:
        raise SystemExit("Component has no material/UV, or import modified the body/rig/actions")
    # Weld only the component's coincident glTF UV seam vertices. Loop UVs
    # remain per-face; the body is never selected for a mesh operator.
    bpy.ops.object.select_all(action="DESELECT")
    source.select_set(True); bpy.context.view_layer.objects.active = source
    bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.0000001)
    bpy.ops.object.mode_set(mode="OBJECT")
    limit = budget // len(parts)
    count = sum(len(p.vertices) - 2 for p in source.data.polygons)
    if count > limit:
        modifier = source.modifiers.new("AdditionOnlyBudget", "DECIMATE")
        modifier.ratio = (limit - 8) / count
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    component_triangles = sum(len(p.vertices) - 2 for p in source.data.polygons)
    if component_triangles <= 0 or component_triangles > limit:
        raise SystemExit("Component reduction did not meet the pair budget; body untouched")
    bounds = [source.matrix_world @ vertex.co for vertex in source.data.vertices]
    low = Vector([min(v[i] for v in bounds) for i in range(3)])
    high = Vector([max(v[i] for v in bounds) for i in range(3)])
    component_height = high.z - low.z
    if component_height <= 0.00001:
        raise SystemExit("Component has no vertical extent")
    receipts = []
    additions = []
    names = set()
    for spec in parts:
        name, bone_name = spec.get("name"), spec.get("anchor_bone")
        offset, angles, ratio = spec.get("offset_height"), spec.get("rotation_deg"), spec.get("height_ratio")
        if not isinstance(name, str) or not name or name in names or name in bpy.data.objects \
                or bone_name not in rig.data.bones or not isinstance(ratio, (int, float)) \
                or not math.isfinite(ratio) or not .1 <= ratio <= .5 \
                or not isinstance(spec.get("mirror_world_x"), bool) \
                or any(not isinstance(values, list) or len(values) != 3
                       or any(not isinstance(v, (int, float)) or not math.isfinite(v) for v in values)
                       for values in (offset, angles)) \
                or any(abs(v) > .5 for v in offset) or any(abs(v) > 180 for v in angles):
            raise SystemExit("Invalid named bounded attachment transform")
        names.add(name)
        anchor = rig.matrix_world @ rig.data.bones[bone_name].head_local + Vector(offset) * height
        orientation = Euler([math.radians(v) for v in angles], "XYZ").to_matrix().to_4x4()
        if spec["mirror_world_x"]:
            orientation = Matrix.Diagonal((-1.0, 1.0, 1.0, 1.0)) @ orientation
        transform = Matrix.Translation(anchor) @ orientation @ Matrix.Scale(height * ratio / component_height, 4) \
                    @ Matrix.Translation(-(low + high) * .5) @ source.matrix_world
        part = bpy.data.objects.new(name, source.data.copy())
        bpy.context.collection.objects.link(part)
        part.data.transform(transform)
        if transform.to_3x3().determinant() < 0:
            import bmesh
            bm = bmesh.new(); bm.from_mesh(part.data)
            bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
            bm.to_mesh(part.data); bm.free()
        bpy.ops.object.select_all(action="DESELECT")
        part.select_set(True); bpy.context.view_layer.objects.active = part
        transfer = part.modifiers.new("OriginalBodyWeights", "DATA_TRANSFER")
        transfer.object = body; transfer.use_vert_data = True
        transfer.data_types_verts = {"VGROUP_WEIGHTS"}; transfer.vert_mapping = "POLYINTERP_NEAREST"
        transfer.layers_vgroup_select_src = "ALL"; transfer.use_object_transform = True
        bpy.ops.object.datalayout_transfer(modifier=transfer.name)
        bpy.ops.object.modifier_apply(modifier=transfer.name)
        for vertex in part.data.vertices:
            weights = sorted(((g.group, g.weight) for g in vertex.groups if g.weight > 0
                              and part.vertex_groups[g.group].name in rig.data.bones),
                             key=lambda pair: (-pair[1], pair[0]))[:4]
            if not weights or any(not math.isfinite(w) for _, w in weights):
                raise SystemExit("Attachment has unweighted/invalid vertices; refusing export")
            total = sum(w for _, w in weights)
            for index in [g.group for g in vertex.groups]:
                part.vertex_groups[index].remove([vertex.index])
            for index, weight in weights:
                part.vertex_groups[index].add([vertex.index], weight / total, "REPLACE")
        armature = part.modifiers.new("OriginalArmature", "ARMATURE"); armature.object = rig
        part.parent = rig; part.matrix_world = Matrix.Identity(4)
        additions.append(part)
        receipts.append({"name": name, "anchor_bone": bone_name, "transform": [list(row) for row in transform],
                         "triangles": component_triangles, "max_influences": max(len(v.groups) for v in part.data.vertices),
                         "weights_normalized": all(abs(sum(g.weight for g in v.groups) - 1) <= 1e-5 for v in part.data.vertices)})
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)
    rig.data.pose_position = original_pose
    bpy.context.view_layer.update()
    if body_signature(body, rig) != original or any(not row["weights_normalized"] for row in receipts):
        raise SystemExit("Attachment altered the original body/rig/UV/weights or normalization")
    total = body_triangles + component_triangles * len(parts)
    if total > 30000:
        raise SystemExit("Composite exceeds authorized triangle budget")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in [body, rig] + additions: obj.select_set(True)
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True,
                              export_skins=True, export_animations=True, export_yup=True)
    if any(hashlib.sha256(path.read_bytes()).hexdigest() != digest for path, digest in
           ((path, hashes[str(path)]) for path in inputs)):
        raise SystemExit("Attachment modified an input file")
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps({"mode": "preserved_body_component_attachment", "input_sha256": hashes,
        "output_sha256": hashlib.sha256(out.read_bytes()).hexdigest(), "body_triangles": body_triangles,
        "addition_triangles": total - body_triangles, "total_triangles": total,
        "original_body_positions_faces_uvs_weights_rig_actions_transforms_unchanged_before_export": True,
        "components": receipts, "scope": "DCC guards only; reimport/fit/intersections/deformation/native judgment still required"}, indent=2) + "\n")


def restore_registered_pbr(args: list[str]) -> None:
    """Restore the held donor's PBR on its transferred UVs, keeping body/albedo."""
    required = ("--out", "--report")
    if len(args) < 2 or any(args.count(key) != 1 or args.index(key) + 1 >= len(args) for key in required):
        raise SystemExit("PBR restoration requires UV-mapped body, held donor, fresh output/report")
    body_path, donor_path = (pathlib.Path(value).resolve() for value in args[:2])
    out, report = (pathlib.Path(option(args, key)).resolve() for key in required)
    inputs = (body_path, donor_path)
    if len(set(inputs + (out, report))) != 4 or out.exists() or report.exists():
        raise SystemExit("PBR restoration paths must be separate and outputs fresh")
    hashes = {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in inputs}
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(body_path))
    sys.path.insert(0, str(pathlib.Path(__file__).parent))
    import inspect_glb
    inspect_glb.drop_import_phantoms()
    rigs = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    bodies = [o for o in bpy.data.objects if o.type == "MESH"]
    if len(rigs) != 1 or len(bodies) != 1:
        raise SystemExit("PBR restoration requires the single existing body and rig")
    body, rig = bodies[0], rigs[0]
    if len(body.data.uv_layers) != 1 or len(body.data.materials) != 1 or not body.vertex_groups:
        raise SystemExit("PBR restoration requires the held nearest-surface UV body")
    original = body_signature(body, rig)
    shader = next(n for n in body.data.materials[0].node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    colour = shader.inputs["Base Color"].links[0].from_node
    if colour.type != "TEX_IMAGE" or colour.image is None:
        raise SystemExit("Body has no held baked albedo")
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(donor_path))
    imported = set(bpy.data.objects) - before
    sources = [o for o in imported if o.type == "MESH"]
    if len(sources) != 1 or len(sources[0].data.materials) != 1 or sources[0].vertex_groups:
        raise SystemExit("PBR restoration requires the registered unskinned texture donor")
    material = sources[0].data.materials[0].copy()
    material.name = "Stormursa_registered_surface_pbr"
    restored = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    if any(not restored.inputs[key].is_linked for key in ["Normal", "Metallic", "Roughness"]):
        raise SystemExit("Registered donor does not supply all three PBR channels")
    image = material.node_tree.nodes.new("ShaderNodeTexImage"); image.image = colour.image
    material.node_tree.links.new(image.outputs["Color"], restored.inputs["Base Color"])
    restored.inputs["Base Color"].default_value = shader.inputs["Base Color"].default_value
    for node in material.node_tree.nodes:
        if node.type in ["UVMAP", "NORMAL_MAP"]:
            node.uv_map = body.data.uv_layers.active.name
    body.data.materials[0] = material
    for obj in imported: bpy.data.objects.remove(obj, do_unlink=True)
    if body_signature(body, rig) != original:
        raise SystemExit("PBR restoration altered original geometry/UVs/weights/rig/actions")
    bpy.ops.object.select_all(action="DESELECT"); body.select_set(True); rig.select_set(True)
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True,
                              export_skins=True, export_animations=True, export_yup=True)
    if any(hashlib.sha256(path.read_bytes()).hexdigest() != hashes[str(path)] for path in inputs):
        raise SystemExit("PBR restoration modified an input file")
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps({"mode": "registered_pbr_restoration", "input_sha256": hashes,
        "output_sha256": hashlib.sha256(out.read_bytes()).hexdigest(),
        "original_geometry_uv_weights_rig_actions_transforms_unchanged_before_export": True,
        "held_baked_albedo_preserved": True, "restored_channels": ["Normal", "Metallic", "Roughness"],
        "scope": "Material restoration only; no new geometry or native visual PASS"}, indent=2) + "\n")


def bake_to_rig(args: list[str]) -> None:
    """Project held texture colour onto an unchanged rigged body; no remeshing."""
    required = ("--out", "--report", "--material-settings")
    if len(args) < 2 or any(args.count(key) != 1 or args.index(key) + 1 >= len(args)
                            for key in required):
        raise SystemExit("Local bake requires rig, texture, fresh out/report and material settings")
    rig_path, texture_path = (pathlib.Path(value).resolve() for value in args[:2])
    out, report, settings_path = (pathlib.Path(option(args, key)).resolve() for key in required)
    inputs = (rig_path, texture_path, settings_path)
    if len(set(inputs + (out, report))) != 5 or out.exists() or report.exists():
        raise SystemExit("Local bake paths must be separate, with fresh output and report")
    hashes = {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in inputs}
    settings = json.loads(settings_path.read_text())["local_material_transfer"]
    resolution = settings["resolution"]
    surface_uv = "--surface-uv-transfer" in args
    if args.count("--surface-uv-transfer") > 1:
        raise SystemExit("Surface UV mode may be selected once")
    if resolution not in (1024, 2048):
        raise SystemExit("Local bake resolution must be 1024 or 2048")
    for key in ("fur_hue", "fur_saturation_scale", "fur_value_scale", "shoulder_radius_height"):
        if not isinstance(settings[key], (int, float)) or not math.isfinite(settings[key]) or not 0 < settings[key] <= 1:
            raise SystemExit("Invalid bounded local material setting: " + key)
    copper = settings["copper_linear_rgba"]
    if len(copper) != 4 or any(not isinstance(v, (int, float)) or not math.isfinite(v) or not 0 <= v <= 1 for v in copper):
        raise SystemExit("Invalid local copper colour")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(rig_path))
    sys.path.insert(0, str(pathlib.Path(__file__).parent))
    import inspect_glb
    inspect_glb.drop_import_phantoms()
    rigs = [obj for obj in bpy.data.objects if obj.type == "ARMATURE"]
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    if len(rigs) != 1 or len(meshes) != 1 or not meshes[0].vertex_groups:
        raise SystemExit("Local bake requires one already weighted body and one armature")
    rig, target = rigs[0], meshes[0]
    if target.data.materials or target.data.uv_layers:
        raise SystemExit("Local bake expects the held untextured body; refuses existing UV/material replacement")
    def signature():
        return (tuple(tuple(v.co) for v in target.data.vertices),
                tuple((tuple(p.vertices), p.material_index) for p in target.data.polygons),
                tuple(tuple((g.group, g.weight) for g in v.groups) for v in target.data.vertices),
                tuple((b.name, tuple(tuple(row) for row in b.matrix_local)) for b in rig.data.bones),
                tuple(tuple(row) for row in target.matrix_world),
                tuple(tuple(row) for row in rig.matrix_world), tuple(bpy.data.actions))
    preserved = signature()
    old_pose = rig.data.pose_position
    rig.data.pose_position = "REST"
    bpy.context.view_layer.update()
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(texture_path))
    imported = set(bpy.data.objects) - before
    sources = [obj for obj in imported if obj.type == "MESH"]
    if len(sources) != 1 or sources[0].vertex_groups or any(obj.type == "ARMATURE" for obj in imported):
        raise SystemExit("Local bake requires one unskinned held textured source")
    source = sources[0]
    if surface_uv and (len(source.data.uv_layers) != 1 or len(source.data.materials) != 1):
        raise SystemExit("Surface UV transfer requires exactly one held UV layer and material")
    def box(obj):
        points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        return Vector([min(p[i] for p in points) for i in range(3)]), Vector([max(p[i] for p in points) for i in range(3)])
    low, high = box(target)
    s_low, s_high = box(source)
    scale = max(high - low) / max(s_high - s_low)
    source.scale *= scale
    bpy.context.view_layer.update()
    s_low, s_high = box(source)
    source.matrix_world.translation += Vector(((low.x + high.x - s_low.x - s_high.x) / 2,
                                              (low.y + high.y - s_low.y - s_high.y) / 2, low.z - s_low.z))
    bpy.context.view_layer.update()
    height = high.z - low.z
    centers = []
    for name in ("front_upper_l", "front_upper_r"):
        if name not in rig.data.bones:
            raise SystemExit("Local shoulder colour needs the held rig's front shoulder joints")
        centers.append(rig.matrix_world @ rig.data.bones[name].head_local + Vector((0, 0, height * .08)))
    for material in source.data.materials:
        if not material or not material.use_nodes:
            raise SystemExit("Held texture source has no node material")
        nodes, links = material.node_tree.nodes, material.node_tree.links
        shader = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
        if shader is None or not shader.inputs["Base Color"].links:
            raise SystemExit("Held texture source has no linked albedo")
        original = shader.inputs["Base Color"].links[0].from_socket
        def math_node(operation, left, right):
            node = nodes.new("ShaderNodeMath"); node.operation = operation
            for slot, value in zip(node.inputs, (left, right)):
                if isinstance(value, (int, float)): slot.default_value = value
                else: links.new(value, slot)
            return node.outputs[0]
        separate = nodes.new("ShaderNodeSeparateColor"); separate.mode = "HSV"
        links.new(original, separate.inputs[0])
        warm = math_node("MULTIPLY", math_node("LESS_THAN", separate.outputs[0], .18),
                         math_node("GREATER_THAN", separate.outputs[1], .15))
        warm = math_node("MULTIPLY", warm, math_node("GREATER_THAN", separate.outputs[2], .08))
        combine = nodes.new("ShaderNodeCombineColor"); combine.mode = "HSV"
        combine.inputs[0].default_value = settings["fur_hue"]
        links.new(math_node("MULTIPLY", separate.outputs[1], settings["fur_saturation_scale"]), combine.inputs[1])
        links.new(math_node("MULTIPLY", separate.outputs[2], settings["fur_value_scale"]), combine.inputs[2])
        grade = nodes.new("ShaderNodeMixRGB")
        links.new(warm, grade.inputs[0]); links.new(original, grade.inputs[1]); links.new(combine.outputs[0], grade.inputs[2])
        position = nodes.new("ShaderNodeNewGeometry").outputs["Position"]
        masks = []
        for center in centers:
            distance = nodes.new("ShaderNodeVectorMath"); distance.operation = "DISTANCE"
            links.new(position, distance.inputs[0]); distance.inputs[1].default_value = center
            mask = math_node("SUBTRACT", 1, math_node("DIVIDE", distance.outputs["Value"], height * settings["shoulder_radius_height"]))
            masks.append(math_node("MAXIMUM", 0, mask))
        shoulder = math_node("MULTIPLY", warm, math_node("MAXIMUM", *masks))
        copper_mix = nodes.new("ShaderNodeMixRGB")
        links.new(shoulder, copper_mix.inputs[0]); links.new(grade.outputs[0], copper_mix.inputs[1])
        copper_mix.inputs[2].default_value = copper
        links.new(copper_mix.outputs[0], shader.inputs["Base Color"])
    bpy.ops.object.select_all(action="DESELECT")
    target.select_set(True); bpy.context.view_layer.objects.active = target
    if surface_uv:
        modifier = target.modifiers.new("held_surface_uv", "DATA_TRANSFER")
        modifier.object = source
        modifier.use_loop_data = True
        modifier.data_types_loops = {"UV"}
        modifier.loop_mapping = "POLYINTERP_NEAREST"
        modifier.layers_uv_select_src = "ALL"
        modifier.use_object_transform = True
        bpy.ops.object.datalayout_transfer(modifier=modifier.name)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        if len(target.data.uv_layers) != 1:
            raise SystemExit("Surface UV transfer did not create the held UV layer")
        target.data.materials.append(source.data.materials[0])
        bake_surface_colour_image(target, resolution)
    else:
        bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(island_margin=.015)
        bpy.ops.object.mode_set(mode="OBJECT")
    if not surface_uv:
        bake_colour_image(target, source, resolution, height)
    for obj in imported: bpy.data.objects.remove(obj, do_unlink=True)
    rig.data.pose_position = old_pose
    bpy.context.view_layer.update()
    if signature() != preserved:
        raise SystemExit("Local material transfer altered original vertices/faces/weights/rig/actions/transforms")
    bpy.ops.object.select_all(action="DESELECT"); target.select_set(True); rig.select_set(True)
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True,
                              export_skins=True, export_animations=True, export_yup=True)
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps({"method": "local_nearest_surface_uv_preserved_rig" if surface_uv else "local_selected_to_active_colour_bake_preserved_rig",
        "input_sha256": hashes, "output_sha256": hashlib.sha256(out.read_bytes()).hexdigest(),
        "vertices_before_export": len(target.data.vertices), "triangles_before_export": sum(len(p.vertices)-2 for p in target.data.polygons),
        "original_geometry_weights_rig_actions_transforms_unchanged_before_export": True,
        "added_uv_layers": len(target.data.uv_layers), "added_materials": len(target.data.materials),
        "resolution": resolution, "source_alignment_uniform_scale": scale,
        "settings": settings, "new_meshy_tasks": 0,
        "scope": "Staged material only. UV export may split vertices; reimport, blind appearance, clips and native scale/pose proofs remain required"}, indent=2) + "\n")
    if any(hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest() != digest for path, digest in hashes.items()):
        raise SystemExit("Local material transfer overwrote an input")


def bake_colour_image(target, source, resolution, height):
    """Bake shader colour only; keep the destination image out of its own input."""
    material = bpy.data.materials.new("Stormursa_local_colour"); material.use_nodes = True
    target.data.materials.append(material)
    image = bpy.data.images.new("Stormursa_local_albedo", width=resolution, height=resolution, alpha=False)
    image.colorspace_settings.name = "sRGB"
    texture = material.node_tree.nodes.new("ShaderNodeTexImage"); texture.image = image
    material.node_tree.nodes.active = texture
    shader = next(n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    shader.inputs["Roughness"].default_value = .85
    source.select_set(True)
    scene = bpy.context.scene; scene.render.engine = "CYCLES"; scene.cycles.samples = 1
    bake = scene.render.bake; bake.use_selected_to_active = True
    bake.use_pass_direct = False; bake.use_pass_indirect = False; bake.use_pass_color = True
    bake.cage_extrusion = height * .025; bake.max_ray_distance = height * .10; bake.margin = 16
    bpy.ops.object.bake(type="DIFFUSE")
    image.pack()
    material.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])


def bake_surface_colour_image(target, resolution):
    """Bake held nearest-surface UV colour without a directional ray projection."""
    material = target.data.materials[0]
    nodes, links = material.node_tree.nodes, material.node_tree.links
    shader = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    albedo = shader.inputs["Base Color"].links[0].from_socket
    output = next(n for n in nodes if n.type == "OUTPUT_MATERIAL" and n.is_active_output)
    emission = nodes.new("ShaderNodeEmission")
    links.new(albedo, emission.inputs["Color"]); links.new(emission.outputs[0], output.inputs["Surface"])
    image = bpy.data.images.new("Stormursa_surface_albedo", width=resolution, height=resolution, alpha=False)
    image.colorspace_settings.name = "sRGB"
    texture = nodes.new("ShaderNodeTexImage"); texture.image = image; nodes.active = texture
    scene = bpy.context.scene; scene.render.engine = "CYCLES"; scene.cycles.samples = 1
    scene.render.bake.use_selected_to_active = False; scene.render.bake.margin = 16
    bpy.ops.object.bake(type="EMIT")
    image.pack()
    final = bpy.data.materials.new("Stormursa_surface_colour"); final.use_nodes = True
    texture = final.node_tree.nodes.new("ShaderNodeTexImage"); texture.image = image
    shader = next(n for n in final.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    final.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    shader.inputs["Roughness"].default_value = .85
    target.data.materials[0] = final


def main() -> None:
    args = argv_after_double_dash()
    modes = [flag for flag in ["--attach-components", "--restore-registered-pbr", "--bake-to-rig"] if flag in args]
    if len(modes) > 1 or any(args.count(flag) != 1 for flag in modes):
        raise SystemExit("Choose one pipeline mode exactly once")
    if "--restore-registered-pbr" in args:
        restore_registered_pbr(args)
        return
    if "--attach-components" in args:
        attach_components(args)
        return
    if "--bake-to-rig" in args:
        bake_to_rig(args)
        return
    if len(args) < 2:
        raise SystemExit("usage: ... skin_transfer.py -- <rigged_clean.glb> "
                         "<textured.glb> --out <out.glb>")
    donor_path = pathlib.Path(args[0]).resolve()
    textured_path = pathlib.Path(args[1]).resolve()
    out = pathlib.Path(option(args, "--out", textured_path.with_name("rigged_textured.glb"))).resolve()
    preserve = "--preserve-target-geometry" in args
    yaw = float(option(args, "--alignment-yaw-deg", "0"))
    report_value = option(args, "--report")
    report_path = pathlib.Path(report_value).resolve() if report_value else None
    if preserve and (out in (donor_path, textured_path) or out.exists() or not report_path
                     or report_path in (donor_path, textured_path, out) or report_path.exists()
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
                tuple((tuple(p.vertices), p.material_index) for p in obj.data.polygons),
                tuple(tuple(tuple(loop.uv) for loop in layer.data) for layer in obj.data.uv_layers),
                tuple(obj.data.materials))
    original_geometry = geometry_signature(target) if preserve else None
    if preserve:
        target.matrix_world = Matrix.Rotation(math.radians(yaw), 4, "Z") @ target.matrix_world
        bpy.context.view_layer.update()
    else:
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # The donor was normalised by its rig script (feet on z=0, centred); the
    # textured mesh arrives however Meshy left it. Align by bounding box so
    # nearest-face lookups land on the right body parts.
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
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps({
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
        if any(hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest() != digest
               for p, digest in input_hashes.items()):
            raise SystemExit("Transfer overwrote an input asset")
    print(f"\n{textured_path.name} skinned from {donor_path.name} -> {out.name}")
    print(f"  {len(target.data.vertices)} vertices, {unweighted} unweighted after transfer")
    if unweighted:
        print("  UNWEIGHTED VERTICES PRESENT — the shapes may not align; inspect.")


if __name__ == "__main__":
    main()
