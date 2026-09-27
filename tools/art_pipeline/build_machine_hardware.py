"""Blender 4.2: author board-15 iron/brass chain fittings in fitted machine metres.

blender --background --python tools/art_pipeline/build_machine_hardware.py
The installed Meshy source is untouched. Coordinates come from triangle probes
of its 19.5 m fit; output belongs beside Model, never inside its measured cage.
"""
from pathlib import Path
import math
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/environment/team_tether/machine_hardware.glb"
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def material(name, color, metallic, roughness, emission=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bs = mat.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Metallic"].default_value = metallic
    bs.inputs["Roughness"].default_value = roughness
    if emission:
        bs.inputs["Emission Color"].default_value = (*color, 1)
        bs.inputs["Emission Strength"].default_value = emission
    return mat


# Linear values, matching the Hall's brass and reserved Tether teal direction.
IRON = material("Blackened chain iron", (.065, .069, .068), .65, .6)
BRASS = material("Worn brass fittings", (.32, .20, .075), .7, .56)
PANEL = material("Recessed iron enamel", (.017, .025, .025), .25, .7)
RUNE = material("Tether rune inlay", (.047, .807, .558), .1, .55, .20)


def point(p):
    return Vector((p[0], -p[2], p[1]))


def box(name, p, size, mat, bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=point(p))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Forged edge", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def bar(name, a, b, radius, mat, vertices=8):
    a, b = point(a), point(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=(b-a).length, location=(a+b)/2)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    obj.data.materials.append(mat)
    return obj


def link(p, twist):
    # Closed elliptical torus. Alternating planes are actual interlinked metal.
    vertices, faces = [], []
    for i in range(16):
        a = math.tau * i / 16
        for j in range(6):
            b = math.tau * j / 6
            x = (.145 + .052 * math.cos(b)) * math.cos(a)
            y = (.245 + .052 * math.cos(b)) * math.sin(a)
            z = .052 * math.sin(b)
            x, z = x*math.cos(twist)-z*math.sin(twist), x*math.sin(twist)+z*math.cos(twist)
            vertices.append(point((p[0]+x, p[1]+y, p[2]+z)))
    for i in range(16):
        for j in range(6):
            faces.append((i*6+j, ((i+1)%16)*6+j, ((i+1)%16)*6+(j+1)%6, i*6+(j+1)%6))
    mesh = bpy.data.meshes.new("Closed chain link")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Interlinked chain", mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(IRON)


def plaque(x, y, z, size=1):
    sign = 1 if z > 0 else -1
    box("Brass plaque rim", (x,y,z), (1.12*size,2.28*size,.24), BRASS, .075)
    front = z + sign*.14
    box("Recessed plaque field", (x,y,front), (.86*size,2.02*size,.08), PANEL, .025)
    surface = front + sign*.058
    # Tall broken diamond and stem; a broad inlay, not tiny text at hero scale.
    for a,b in [((0,-.70),(0,.70)), ((-.27,0),(0,.44)), ((0,.44),(.27,0)),
                ((.27,0),(0,-.44)), ((0,-.44),(-.27,0)),
                ((-.24,.76),(.24,.76)), ((-.24,-.76),(.24,-.76))]:
        bar("Runic inlay", (x+a[0]*size,y+a[1]*size,surface), (x+b[0]*size,y+b[1]*size,surface), .038*size, RUNE, 6)
    for dx in [-.44,.44]:
        for dy in [-.98,.98]:
            bar("Hex rivet", (x+dx*size,y+dy*size,front), (x+dx*size,y+dy*size,front+sign*.075), .065*size, IRON, 6)


for side in [-1, 1]:
    # Source strip runs from the bell shoulder to the arch. Actual metal links
    # cover that paper-thin strip without entering the captive's measured void.
    for k in range(15):
        t = k / 14
        link((side*(1.55+.15*t),13.53+k*.30,0), (k%2)*math.pi/2)
    for x,y,depth in [(1.55,13.53,.66),(1.70,17.75,.85)]:
        box("Suspension anchor", (side*x,y,0), (.56,.32,depth), BRASS, .045)
        bar("Anchor pin", (side*x,y,-depth*.57), (side*x,y,depth*.57), .11, IRON, 8)
    for sign in [-1,1]:
        plaque(side*4.5,14,sign*.52,.64)

# Join per material to keep the large hero object's extra draw calls bounded.
for mat in [IRON, BRASS, PANEL, RUNE]:
    objects = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.data.materials[0] == mat]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    bpy.context.object.name = mat.name
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=str(OUT), export_format='GLB', use_selection=True, export_yup=True)
print("Wrote", OUT)
