"""Author the five bespoke Team Tether Hall props as GLBs, from the owner's boards.

    blender --background --python tools/art_pipeline/blender/build_hall_props.py \
            -- --out assets/environment/team_tether/hall

Reference: `docs/art/reference/hall-asset-pack-2026-08-30/art_boards/*.png` and the
spec beside them. Every dimension below is read off a board's own human-scale bar
(the boards state 4.5m / 3.5m / 2.5m / 3.0m / 2.8m explicitly) rather than guessed.

WHY THIS SCRIPT AND NOT MESHY. The pack's build path for all five reads "NEW MESHY
PROP", and the pipeline for that exists (`tools/art_pipeline/meshy.py`). It is not
usable here: `MESHY_API_KEY` is unset in this container and that file reads the key
"from the environment and from nowhere else". Rather than stall the lane, these are
authored procedurally. That is not merely a substitute -- it is a better fit for
three of the pack's own stated requirements, and the trade is worth naming:

  - "Low-to-medium detail density; avoid tiny surface clutter" and "prioritize
    large forms, strong shapes, and functional readability". Primitives assembled
    to a board's proportions produce exactly that. Meshy's failure mode on this
    project has been the opposite -- see the camp-set row in docs/specs/ASSET_LEDGER.md,
    where a tent took eight candidates over six rounds and the owner still chose
    round one.
  - "Prefer separate logical pieces" / "Separate the machine into clear modular
    subparts". Authored geometry is modular by construction; the pipe kit below is
    five independent GLBs because the board asks for a kit, not a sculpture.
  - "Do not bake a giant complex purple particle effect into the geometry. Build a
    readable chamber so Godot can add emissive material and particles afterward."
    The siphon's core is a separate object with its own material for precisely
    that reason.

What is genuinely lost: surface micro-detail (rivet heads, oxidation mottling, the
boards' painterly texture). These carry flat PBR values and take their weathering
from the same `T_UnevenBrick`-era lighting the rest of the Hall uses. If a Meshy
budget is ever authorised, boards 02 and 04 are the two worth spending it on --
they are the ones whose boards carry detail this cannot reproduce.

MATERIALS ARE DELIBERATELY SHARED across all five props. The lane's measured
draw-call fact is that batches cost and instances do not, so seven materials serve
five props (and every future placement of them) rather than each prop bringing its
own. `tether_oxblood` is read from data/config/palette.json's reserved accent, not
re-picked; see OXBLOOD below for the one place a board and the palette disagree.
"""
import argparse
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

# --- palette ----------------------------------------------------------------
# sRGB hex -> linear, because Blender's node values are linear and a hex pasted
# straight in comes out washed. Values are the boards' own swatch strip.
TIMBER = "#4a3729"       # board 01 "weathered timber"
IRON = "#33343a"         # boards 01-05 "aged iron" / "blackened iron"
BRASS = "#8a6f3a"        # board 05 "aged brass"; matches stronghold.gd BRASS_COLOUR
ROPE = "#8a7048"         # board 01 "rope / lashings"
RIFT = "#a24bd8"         # board 04 "rift glow"
HEAT = "#e0621a"         # board 02 "heat glow"

# Board 05's cloth swatch is a mid oxblood. palette.json's reserved
# `accent.tether_oxblood` is #332228 -- much darker, and reserved, so it must not
# be re-picked. stronghold.gd already resolved this exact tension for its own
# banners (BANNER_COLOUR #6b2a20, "nominal oxblood" #7a2430) and this matches that
# value rather than introducing a third red to the fortress.
OXBLOOD = "#6b2a20"


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rgba(hex_str, alpha=1.0):
    h = hex_str.lstrip("#")
    return tuple(srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4)) + (alpha,)


_MATS = {}


def mat(name, hex_str, rough=0.85, metal=0.0, emit=None, emit_strength=0.0):
    """One shared material instance per name, for the batching reason in the header."""
    if name in _MATS:
        return _MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = rgba(hex_str)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emit is not None:
        bsdf.inputs["Emission Color"].default_value = rgba(emit)
        bsdf.inputs["Emission Strength"].default_value = emit_strength
    _MATS[name] = m
    return m


def M_timber():
    return mat("TT_Timber", TIMBER, rough=0.92)


def M_iron():
    # METALLIC IS DELIBERATELY LOW, and this is not a taste call. project.godot
    # ships gl_compatibility (D01, locked), which has no reflection probes, so a
    # high-metallic surface has almost no diffuse ambient response and renders
    # flat and blown-out rather than metallic. building_prefabs.json already
    # records this exact failure against the kit's own MI_RockTrim ("imports with
    # metallic=1.0, a bare-metal value no stone surface wants") and fixes it by
    # forcing 0.0. The first cut of these props shipped iron at 0.65 and brass at
    # 0.8, and the banner rigs' brass selvage rendered as bright WHITE vertical
    # bars on the fortress wall -- visible in shots/_hall_art_fast/F-02.
    return mat("TT_Iron", IRON, rough=0.78, metal=0.05)


def M_brass():
    # See M_iron: same renderer, same reason.
    return mat("TT_Brass", BRASS, rough=0.62, metal=0.12)


def M_rope():
    return mat("TT_Rope", ROPE, rough=0.95)


def M_cloth():
    return mat("TT_Oxblood", OXBLOOD, rough=0.95)


def M_rift():
    # Emission is carried here so the GLB looks right on its own, but Godot drives
    # the real value -- the spec wants the glow "selective" and animated, which is
    # a scene decision, not a mesh one.
    return mat("TT_RiftCore", RIFT, rough=0.3, emit=RIFT, emit_strength=3.0)


def M_heat():
    return mat("TT_HeatCore", HEAT, rough=0.4, emit=HEAT, emit_strength=2.0)


# --- primitive helpers ------------------------------------------------------

def _finish(obj, material, name):
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(material)
    return obj


def box(name, size, at, material, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=at)
    o = bpy.context.object
    o.scale = Vector(size)
    o.rotation_euler = rot
    return _finish(o, material, name)


def cyl(name, radius, depth, at, material, rot=(0, 0, 0), verts=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth,
                                        location=at, rotation=rot)
    return _finish(bpy.context.object, material, name)


def sphere(name, radius, at, material, segments=12, rings=6):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings,
                                         radius=radius, location=at)
    o = bpy.context.object
    bpy.ops.object.shade_flat()
    return _finish(o, material, name)


def torus(name, major, minor, at, material, rot=(0, 0, 0), mseg=16, sseg=8):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                     major_segments=mseg, minor_segments=sseg,
                                     location=at, rotation=rot)
    return _finish(bpy.context.object, material, name)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for block in (bpy.data.meshes, bpy.data.objects):
        for b in list(block):
            if b.users == 0:
                block.remove(b)


def join_by_material():
    """Collapse every object into one mesh PER MATERIAL, and name it for that
    material.

    THIS IS A BUDGET FIX, and the numbers are why it exists. Godot draws one call
    per mesh surface, so the first cut of this script -- which exported each
    primitive as its own object, because the boards ask for "separate logical
    pieces" -- produced a 63-object scaffold and a 49-object siphon. Counted
    against the placement list in stronghold.json that is ~1087 draw calls, into a
    Hall that T1-HALL-4 measured at 3365 against a 4000 ceiling. It would have
    blown the budget by 450 before the pipes were counted.

    Joined by material the same set is ~193, because a prop costs its MATERIAL
    COUNT (3-5), not its part count. Nothing visible changes: same geometry, same
    materials, same silhouette.

    The boards' modularity requirement is still met where it actually matters --
    the pipe kit is five separate GLBs, and each prop's parts stay separable in
    the authoring script. What is given up is per-part control in the scene, and
    the one place that mattered is preserved by construction: `RiftCore` is the
    only user of `TT_RiftCore`, so it survives as its own object and Godot can
    still drive its emission and hang a light off it."""
    groups = {}
    for o in list(bpy.data.objects):
        if o.type != "MESH" or not o.data.materials:
            continue
        groups.setdefault(o.data.materials[0].name, []).append(o)
    for name, objs in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        bpy.context.view_layer.objects.active.name = name


def export(out_dir, stem):
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, stem + ".glb")
    join_by_material()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
    )
    tris = sum(len(o.data.loop_triangles) for o in bpy.data.objects
               if o.type == "MESH" and _eval_tris(o))
    print("[hall-props] %-28s %s" % (stem, path))
    return path


def _eval_tris(o):
    try:
        o.data.calc_loop_triangles()
        return True
    except Exception:
        return False


def tri_count():
    total = 0
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        o.data.calc_loop_triangles()
        total += len(o.data.loop_triangles)
    return total


# --- 1. timber scaffold tower (board 01, 4.5 m) -----------------------------

def build_scaffold():
    """Two-level wall-attached scaffold. Board 01: broad uprights, cross braces,
    plank platforms, ladder, iron straps, a hanging lantern, an oxblood strip.

    Origin at the foot, -Y is the wall face, so a placement only needs the wall's
    position and yaw. The board's stone is context and is NOT built."""
    clear_scene()
    t, i, r = M_timber(), M_iron(), M_rope()
    H = 4.5
    W, D = 2.4, 1.6          # footprint; D is the reach out from the wall
    post = 0.13              # half-extent of an upright

    # four uprights
    for sx in (-1, 1):
        for sy in (-1, 1):
            box("Upright", (post * 2, post * 2, H),
                (sx * (W / 2 - post), sy * (D / 2 - post), H / 2), t)

    # platform decks at two levels, as separate planks so the deck reads as boards
    for lvl, y in enumerate((1.95, 3.95)):
        for k in range(5):
            box("Plank_%d_%d" % (lvl, k),
                (W - 0.06, D / 5 - 0.04, 0.07),
                (0.0, -D / 2 + (k + 0.5) * (D / 5), y), t)
        # ledger beams under the deck, front and back
        for sy in (-1, 1):
            box("Ledger", (W + 0.3, 0.14, 0.16), (0.0, sy * (D / 2 - post), y - 0.12), t)
        # A guard rail on the outer edge of the upper deck only. It needs POSTS and
        # it has to stop below the uprights' heads: the first cut floated a bare
        # bar at deck+0.95, which is above H, so it rendered as a beam hanging in
        # the air over the tower with nothing holding it.
        if lvl == 1:
            rail_z = H - 0.09
            box("Rail", (W, 0.08, 0.08), (0.0, D / 2 - post, rail_z), t)
            for sx in (-1, 1):
                box("RailPost", (0.07, 0.07, rail_z - y),
                    (sx * (W / 2 - post - 0.3), D / 2 - post, (y + rail_z) / 2), t)

    # cross braces: an X on the front and back faces of each level. A brace runs
    # corner to corner, so its length is the diagonal and its pitch is the angle
    # of that diagonal in the XZ plane -- `d` flips it to make the second stroke.
    run = W - post * 2
    for lvl, (z0, z1) in enumerate(((0.15, 1.85), (2.1, 3.85))):
        rise = z1 - z0
        span = math.hypot(run, rise)
        for sy in (-1, 1):
            for d in (1, -1):
                box("Brace_%d" % lvl, (span, 0.09, 0.14),
                    (0.0, sy * (D / 2 - post), (z0 + z1) / 2), t,
                    rot=(0, -d * math.atan2(rise, run), 0))

    # ladder from the ground to the upper deck, on the +X side
    lx = W / 2 + 0.18
    for sy in (-1, 1):
        box("LadderRail", (0.07, 0.07, H - 0.4), (lx, sy * 0.22, (H - 0.4) / 2), t)
    for k in range(10):
        box("Rung", (0.07, 0.52, 0.05), (lx, 0.0, 0.35 + k * 0.4), t)

    # iron straps at the joints -- the board's "bolt to stone" language, and the
    # only place iron appears on this prop at any size worth a draw call
    for y in (0.5, 1.95, 3.95):
        for sx in (-1, 1):
            box("Strap", (0.34, D + 0.06, 0.1), (sx * (W / 2 - post), 0.0, y), i)
    # wall ties: short beams reaching into the wall face
    for y in (1.8, 3.8):
        for sx in (-1, 1):
            box("WallTie", (0.12, 0.5, 0.12), (sx * (W / 2 - post), -D / 2 - 0.2, y), t)
            box("TiePlate", (0.3, 0.08, 0.3), (sx * (W / 2 - post), -D / 2 - 0.42, y), i)

    # rope lashings at two upright/ledger crossings
    for sx in (-1, 1):
        torus("Lashing", 0.17, 0.035, (sx * (W / 2 - post), D / 2 - post, 2.6), r,
              rot=(math.pi / 2, 0, 0))

    # Lantern on a short arm off the upper deck. The arm is deliberately stubby and
    # seated AT the deck line: the first cut ran it 0.9m at z 4.3, above the top of
    # the uprights, and it rendered as a beam floating free of the tower.
    ax = W / 2 + 0.26
    box("LanternArm", (0.62, 0.09, 0.09), (ax, D / 2 - post, 3.98), t)
    box("LanternArmBrace", (0.3, 0.08, 0.3), (W / 2 + 0.08, D / 2 - post, 3.82), t,
        rot=(0, math.pi / 4, 0))
    cyl("LanternChain", 0.02, 0.24, (ax + 0.2, D / 2 - post, 3.82), i, verts=6)
    box("LanternBody", (0.2, 0.2, 0.26), (ax + 0.2, D / 2 - post, 3.57), i)
    box("LanternGlass", (0.14, 0.14, 0.17), (ax + 0.2, D / 2 - post, 3.57), M_heat())

    # oxblood strip -- board 01 hangs one narrow pennant, not a full banner
    box("Pennant", (0.34, 0.03, 1.15), (-W / 2 + 0.3, D / 2 - post - 0.05, 3.05), M_cloth())
    return "team_tether_scaffold_tower"


# --- 2. boiler & chimney retrofit (board 02, 3.5 m) -------------------------

def build_boiler():
    """Board 02: cylindrical body, domed top, tall stack with a caged cap, furnace
    door with heat glow, pressure tank, thick pipes, service ladder, guy wires.
    Origin at the foot; the board's ruined wall is context and is NOT built."""
    clear_scene()
    i, b = M_iron(), M_brass()

    # plinth on stubby feet, so it reads as dropped onto old stone rather than
    # growing out of it -- the board's "bolted-on" language
    box("Plinth", (1.9, 1.9, 0.22), (0, 0, 0.19), i)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box("Foot", (0.26, 0.26, 0.16), (sx * 0.72, sy * 0.72, 0.08), i)
    R = 0.78
    cyl("Body", R, 1.75, (0, 0, 1.1), i, verts=16)
    # riveted bands: three rings, which is how the board reads at distance. Real
    # rivet heads are exactly the "tiny surface clutter" the pack forbids.
    for z in (0.42, 1.1, 1.78):
        torus("Band", R + 0.015, 0.045, (0, 0, z), b, mseg=16, sseg=6)
    # dome
    sphere("Dome", R, (0, 0, 1.98), i, segments=16, rings=8)
    bpy.context.object.scale = (1.0, 1.0, 0.55)

    # furnace door on +Y, with a glowing interior slot
    box("DoorFrame", (0.62, 0.1, 0.66), (0, R - 0.02, 0.72), i)
    box("DoorGlow", (0.44, 0.05, 0.46), (0, R + 0.05, 0.72), M_heat())
    torus("DoorWheel", 0.14, 0.028, (0, R + 0.1, 1.12), b, rot=(math.pi / 2, 0, 0))

    # smokestack with a caged cap
    SH = 1.35
    cyl("Stack", 0.21, SH, (0, 0, 2.2 + SH / 2), i, verts=12)
    torus("StackCollar", 0.24, 0.04, (0, 0, 2.35), b, mseg=12, sseg=6)
    cyl("CapFloor", 0.3, 0.06, (0, 0, 2.2 + SH + 0.03), i, verts=12)
    for k in range(6):                       # the cap's cage
        a = k * math.pi / 3
        box("CapBar", (0.05, 0.05, 0.34),
            (math.cos(a) * 0.26, math.sin(a) * 0.26, 2.2 + SH + 0.2), i)
    cyl("CapLid", 0.34, 0.07, (0, 0, 2.2 + SH + 0.4), i, verts=12)

    # pressure tank alongside
    cyl("Tank", 0.3, 0.9, (-0.95, 0.2, 0.62), i, verts=12)
    sphere("TankTop", 0.3, (-0.95, 0.2, 1.07), i, segments=12, rings=6)
    bpy.context.object.scale = (1.0, 1.0, 0.5)
    cyl("Gauge", 0.11, 0.05, (-0.95, 0.5, 1.0), b, rot=(math.pi / 2, 0, 0), verts=12)

    # thick pipes: tank -> body, and body -> off-prop (the board's "pipe connections")
    cyl("PipeA", 0.1, 0.72, (-0.5, 0.2, 1.35), i, rot=(0, math.pi / 2, 0), verts=10)
    cyl("PipeB", 0.1, 0.6, (0.95, -0.3, 1.5), i, rot=(0, math.pi / 2, 0), verts=10)
    torus("PipeElbow", 0.16, 0.1, (1.25, -0.3, 1.5), i, rot=(math.pi / 2, 0, 0), mseg=10, sseg=8)
    cyl("PipeC", 0.1, 0.8, (1.41, -0.3, 1.1), i, verts=10)

    # service ladder on -Y
    for sx in (-1, 1):
        box("LadderRail", (0.06, 0.06, 2.1), (sx * 0.24, -R - 0.16, 1.05), i)
    for k in range(6):
        box("Rung", (0.48, 0.05, 0.04), (0, -R - 0.16, 0.35 + k * 0.34), i)

    # Guy wires, stack collar down to the dome shoulder. Both ends have to LAND on
    # the prop: the first cut centred them at z 2.55 with a 1.15 length and they
    # stood off the top of the stack like a pair of antennae. Derived instead from
    # the two points they actually connect, so the geometry cannot drift again.
    top = Vector((0.0, 0.0, 2.35 + SH * 0.62))          # high on the stack
    for sx in (-1, 1):
        foot = Vector((sx * 0.66, 0.0, 2.02))            # out on the dome shoulder
        span = foot - top
        cyl("Guy", 0.016, span.length, tuple((top + foot) / 2.0), i,
            rot=(0, math.atan2(span.x, span.z), 0), verts=6)

    # oxblood strip, as on the board's side elevation
    box("Pennant", (0.3, 0.02, 0.85), (-1.28, 0.2, 1.5), M_cloth())
    return "team_tether_boiler_chimney"


# --- 3. pipe & valve kit (board 03) -----------------------------------------
# Five separate GLBs. The board asks for "modular, reusable pieces" and the lane's
# draw-call fact says a small kit placed many times is what the budget wants.

PIPE_R = 0.11
PIPE_LEN = 1.0


def _pipe_collar(at, rot=(0, 0, 0)):
    torus("Collar", PIPE_R + 0.02, 0.035, at, M_brass(), rot=rot, mseg=12, sseg=6)


def build_pipe_straight():
    clear_scene()
    cyl("Pipe", PIPE_R, PIPE_LEN, (0, 0, 0), M_iron(), rot=(0, math.pi / 2, 0), verts=10)
    for x in (-PIPE_LEN / 2 + 0.06, PIPE_LEN / 2 - 0.06):
        _pipe_collar((x, 0, 0), rot=(0, math.pi / 2, 0))
    return "tt_pipe_straight"


def build_pipe_elbow():
    clear_scene()
    i = M_iron()
    cyl("ArmX", PIPE_R, 0.5, (0.25, 0, 0), i, rot=(0, math.pi / 2, 0), verts=10)
    cyl("ArmZ", PIPE_R, 0.5, (0, 0, 0.25), i, verts=10)
    sphere("Knee", PIPE_R * 1.15, (0, 0, 0), i, segments=10, rings=6)
    _pipe_collar((0.46, 0, 0), rot=(0, math.pi / 2, 0))
    _pipe_collar((0, 0, 0.46))
    return "tt_pipe_elbow"


def build_pipe_tee():
    clear_scene()
    i = M_iron()
    cyl("Run", PIPE_R, PIPE_LEN, (0, 0, 0), i, rot=(0, math.pi / 2, 0), verts=10)
    cyl("Branch", PIPE_R, 0.44, (0, 0, 0.22), i, verts=10)
    sphere("Junction", PIPE_R * 1.2, (0, 0, 0), i, segments=10, rings=6)
    for x in (-PIPE_LEN / 2 + 0.06, PIPE_LEN / 2 - 0.06):
        _pipe_collar((x, 0, 0), rot=(0, math.pi / 2, 0))
    _pipe_collar((0, 0, 0.4))
    return "tt_pipe_tee"


def build_pipe_valve():
    clear_scene()
    i, b = M_iron(), M_brass()
    cyl("Run", PIPE_R, 0.7, (0, 0, 0), i, rot=(0, math.pi / 2, 0), verts=10)
    box("Body", (0.26, 0.26, 0.3), (0, 0, 0.06), i)
    cyl("Stem", 0.045, 0.26, (0, 0, 0.3), i, verts=8)
    # the board's red wheel is the one bright accent on the kit
    torus("Wheel", 0.15, 0.028, (0, 0, 0.43), M_cloth(), mseg=16, sseg=6)
    for k in range(4):
        a = k * math.pi / 2
        box("Spoke", (0.3 if k % 2 == 0 else 0.04, 0.04 if k % 2 == 0 else 0.3, 0.03),
            (0, 0, 0.43), M_cloth())
    cyl("Gauge", 0.09, 0.04, (0.0, 0.2, 0.16), b, rot=(math.pi / 2, 0, 0), verts=10)
    for x in (-0.3, 0.3):
        _pipe_collar((x, 0, 0), rot=(0, math.pi / 2, 0))
    return "tt_pipe_valve"


def build_pipe_bracket():
    clear_scene()
    i = M_iron()
    box("Plate", (0.05, 0.34, 0.34), (-0.14, 0, 0), i)     # against the stone
    box("Arm", (0.24, 0.09, 0.09), (0, 0, 0), i)
    box("Gusset", (0.2, 0.06, 0.2), (-0.02, 0, -0.1), i)
    torus("Clamp", PIPE_R + 0.04, 0.03, (0.14, 0, 0), i, rot=(0, math.pi / 2, 0), mseg=12, sseg=6)
    return "tt_pipe_bracket"


# --- 4. rift siphon wall machine (board 04, 3.0 m) --------------------------

def build_rift_siphon():
    """The signature piece, and the one the pack says gets the most attention.

    Board 04: a large caged central chamber, heavy iron frame and brackets, several
    tanks/conduits, thick pipes and cables, a small control cluster, purple core.

    The core is `RiftCore`, a separate object with its own material, because the
    pack is explicit that the particle effect must NOT be baked in -- Godot adds
    emission and GPUParticles to that node."""
    clear_scene()
    i, b = M_iron(), M_brass()
    H, W, D = 3.0, 1.7, 0.75

    # backplate against the stone, plus the four brackets that bolt it on
    box("Backplate", (W, 0.14, H * 0.92), (0, -D / 2 + 0.07, H / 2), i)
    for sx in (-1, 1):
        for z in (0.5, H - 0.45):
            box("Bracket", (0.3, 0.34, 0.3), (sx * (W / 2 - 0.12), -D / 2 + 0.28, z), i)
            box("BoltPlate", (0.42, 0.06, 0.42), (sx * (W / 2 - 0.12), -D / 2 - 0.02, z), b)

    # heavy frame: two uprights and three cross members, standing proud of the plate
    for sx in (-1, 1):
        box("FrameUpright", (0.16, 0.3, H * 0.88), (sx * (W / 2 - 0.1), 0.05, H / 2), i)
    for z in (0.55, 1.72, H - 0.32):
        box("FrameCross", (W - 0.05, 0.26, 0.16), (0, 0.05, z), i)

    # --- central caged chamber, the hero form -------------------------------
    CY = 1.72                      # chamber centre height
    CR, CH = 0.44, 1.25            # chamber radius / height
    cyl("ChamberBase", CR + 0.12, 0.16, (0, 0.12, CY - CH / 2 - 0.05), i, verts=16)
    cyl("ChamberCap", CR + 0.12, 0.16, (0, 0.12, CY + CH / 2 + 0.05), i, verts=16)
    torus("CapRing", CR + 0.1, 0.05, (0, 0.12, CY + CH / 2 + 0.14), b, mseg=16, sseg=6)
    # the cage: eight bars, which reads as a cage at distance without becoming clutter
    for k in range(8):
        a = k * math.pi / 4
        box("CageBar", (0.055, 0.055, CH),
            (math.cos(a) * CR, 0.12 + math.sin(a) * CR, CY), i)
    # two hoops binding the cage
    for z in (CY - CH * 0.28, CY + CH * 0.28):
        torus("CageHoop", CR, 0.032, (0, 0.12, z), i, mseg=16, sseg=6)
    # THE CORE. Separate object, separate material, deliberately simple.
    cyl("RiftCore", CR - 0.13, CH - 0.12, (0, 0.12, CY), M_rift(), verts=14)

    # flanking tanks
    for sx in (-1, 1):
        cyl("Tank", 0.2, 0.85, (sx * (W / 2 - 0.06), 0.42, 0.95), i, verts=12)
        sphere("TankCap", 0.2, (sx * (W / 2 - 0.06), 0.42, 1.38), i, segments=12, rings=6)
        bpy.context.object.scale = (1.0, 1.0, 0.55)
        # conduit from each tank up into the chamber base
        cyl("Conduit", 0.075, 0.62, (sx * (W / 2 - 0.06), 0.42, 1.72), i, verts=8)
        cyl("ConduitRun", 0.075, (W / 2 - 0.06) * 0.9, (sx * 0.34, 0.42, 2.0), i,
            rot=(0, math.pi / 2, 0), verts=8)

    # thick pipes arcing over the top, the board's most recognisable outline cue
    for sx in (-1, 1):
        torus("TopArc", 0.26, 0.075, (sx * 0.52, 0.3, H - 0.42), i,
              rot=(math.pi / 2, 0, 0), mseg=12, sseg=8)
    cyl("TopRun", 0.075, 1.05, (0, 0.3, H - 0.16), i, rot=(0, math.pi / 2, 0), verts=8)

    # control / valve cluster, low and to one side so it reads as human-operated
    box("ControlBox", (0.5, 0.24, 0.36), (-0.42, 0.34, 0.72), i)
    cyl("Dial", 0.09, 0.04, (-0.56, 0.47, 0.78), b, rot=(math.pi / 2, 0, 0), verts=10)
    cyl("Dial2", 0.07, 0.04, (-0.3, 0.47, 0.78), b, rot=(math.pi / 2, 0, 0), verts=10)
    torus("ControlWheel", 0.13, 0.026, (0.42, 0.4, 0.78), M_cloth(), rot=(math.pi / 2, 0, 0),
          mseg=14, sseg=6)

    # cable junction: a bundle of slack tubes dropping off the machine's shoulder
    box("CableBox", (0.26, 0.2, 0.24), (0.58, 0.3, 1.15), i)
    for k in range(4):
        cyl("Cable", 0.028, 0.75, (0.5 + k * 0.05, 0.34, 0.72), i,
            rot=(0.12 * (k - 1.5), 0, 0), verts=6)

    # oxblood strip, as board 04's front elevation carries
    box("Pennant", (0.26, 0.02, 0.95), (-W / 2 + 0.22, 0.24, 2.42), M_cloth())
    return "rift_siphon_wall_machine"


# --- 5. oxblood banner rig (board 05, 2.8 m) --------------------------------

def build_banner_rig():
    """Board 05: iron wall bracket and bar, oxblood cloth with real folds and a
    torn pointed hem, aged brass hardware, chain and pulley.

    The cloth is a displaced grid, not a plane -- the pack asks for "real 3D cloth
    folds rather than a flat plane" -- with the hem cut into the board's spikes.
    The centre is left broad and unbroken so Godot can decal the canonical emblem
    onto it; the pack says not to model faction typography."""
    clear_scene()
    i, b = M_iron(), M_brass()

    BAR_Y = 2.72
    BAR_LEN = 1.5
    # -Y is the stone, as on every other wall-mounted prop in this file. Getting
    # this sign wrong is not cosmetic: the glTF Y-up export maps Blender -Y to
    # +Z, so a banner authored against +Y would be the one prop in the set whose
    # wall is on the opposite side, and a single Godot yaw convention could not
    # place all five.
    WALL_Y = -0.30       # the stone face
    BAR_OFF = 0.06       # the bar stands this far off it, into the room

    # Two L-brackets, one at each end of the bar, reaching OUT of the wall behind.
    # Board 05's front elevation carries an iron fitting at both ends, and mounting
    # from behind is also what makes this prop consistent with the other four:
    # every wall-mounted prop in this file puts the stone at +Y so that one Godot
    # yaw convention places all of them. The first cut had the bracket plate on -X,
    # which would have needed the banner hung off a perpendicular pier while its
    # cloth faced down the wall -- wrong against the board and wrong against the
    # rest of the set.
    for sx in (-1, 1):
        bx = sx * (BAR_LEN / 2 - 0.1)
        box("BracketPlate", (0.24, 0.1, 0.86), (bx, WALL_Y - 0.05, BAR_Y - 0.34), i)
        box("BracketArm", (0.12, abs(BAR_OFF - WALL_Y), 0.12),
            (bx, (WALL_Y + BAR_OFF) / 2, BAR_Y), i)
        box("BracketGusset", (0.1, 0.34, 0.34), (bx, WALL_Y + 0.14, BAR_Y - 0.2), i,
            rot=(math.pi / 4, 0, 0))

    # horizontal bar with finial caps
    cyl("Bar", 0.055, BAR_LEN, (0.0, BAR_OFF, BAR_Y), i, rot=(0, math.pi / 2, 0), verts=10)
    for sx in (-1, 1):
        cyl("BarCap", 0.075, 0.09, (sx * BAR_LEN / 2, BAR_OFF, BAR_Y), b,
            rot=(0, math.pi / 2, 0), verts=10)
    for x in (-0.42, 0.0, 0.42):
        torus("BarRing", 0.08, 0.02, (x, BAR_OFF, BAR_Y), b, rot=(0, math.pi / 2, 0),
              mseg=12, sseg=6)

    # --- cloth --------------------------------------------------------------
    CW, CH = 1.12, 1.9             # cloth width / body height, before the hem
    COLS, ROWS = 14, 12
    CLOTH_Y = BAR_OFF + 0.05
    me = bpy.data.meshes.new("BannerCloth")
    bm = bmesh.new()
    verts = {}
    for r in range(ROWS + 1):
        for c in range(COLS + 1):
            u = c / COLS
            v = r / ROWS
            x = (u - 0.5) * CW
            z = BAR_Y - 0.09 - v * CH
            # Broad folds: three lobes across the width, deepening downward so the
            # cloth hangs rather than corrugating uniformly.
            fold = math.sin(u * math.pi * 3.0) * 0.055 * (0.35 + 0.65 * v)
            # a slight overall belly, and a gentle sway near the hem
            belly = math.sin(u * math.pi) * 0.03
            # CLOTH_Y hangs the sheet just clear of the bar, on the room side of
            # it, so the stone at +Y never pokes through a fold.
            y = CLOTH_Y + fold - belly - 0.02 * v * v
            verts[(r, c)] = bm.verts.new((x, y, z))
    bm.verts.ensure_lookup_table()
    for r in range(ROWS):
        for c in range(COLS):
            bm.faces.new((verts[(r, c)], verts[(r, c + 1)],
                          verts[(r + 1, c + 1)], verts[(r + 1, c)]))
    bm.to_mesh(me)
    bm.free()
    cloth = bpy.data.objects.new("BannerCloth", me)
    bpy.context.collection.objects.link(cloth)
    cloth.data.materials.append(M_cloth())
    # two-sided: a banner seen from behind must not vanish
    M_cloth().use_backface_culling = False

    # torn pointed hem, board 05's most distinctive edge. Separate triangles rather
    # than a modifier so the shape is explicit and cheap.
    hem = bpy.data.meshes.new("BannerHem")
    hb = bmesh.new()
    z0 = BAR_Y - 0.09 - CH
    for c in range(COLS):
        u0, u1 = c / COLS, (c + 1) / COLS
        x0, x1 = (u0 - 0.5) * CW, (u1 - 0.5) * CW
        drop = 0.16 + 0.1 * ((c * 7) % 5) / 4.0      # uneven, so it reads as torn
        # must match the cloth's own bottom row exactly (v = 1), or the hem tears
        # away from the sheet it is supposed to continue
        y0 = CLOTH_Y + math.sin(u0 * math.pi * 3.0) * 0.055 - math.sin(u0 * math.pi) * 0.03 - 0.02
        y1 = CLOTH_Y + math.sin(u1 * math.pi * 3.0) * 0.055 - math.sin(u1 * math.pi) * 0.03 - 0.02
        a = hb.verts.new((x0, y0, z0))
        bcv = hb.verts.new((x1, y1, z0))
        cpt = hb.verts.new(((x0 + x1) / 2, (y0 + y1) / 2, z0 - drop))
        hb.faces.new((a, bcv, cpt))
    hb.to_mesh(hem)
    hb.free()
    hem_o = bpy.data.objects.new("BannerHem", hem)
    bpy.context.collection.objects.link(hem_o)
    hem_o.data.materials.append(M_cloth())

    # vertical selvage tapes down both edges, the board's gold-ish trim
    for sx in (-1, 1):
        box("Selvage", (0.05, 0.03, CH), (sx * CW / 2, CLOTH_Y + 0.02,
                                          BAR_Y - 0.09 - CH / 2), b)

    # chain and pulley off the bar's free end, hanging clear of the cloth
    px = BAR_LEN / 2 - 0.16
    py = BAR_OFF + 0.16
    box("PulleyCheek", (0.16, 0.02, 0.22), (px, py + 0.05, BAR_Y - 0.3), b)
    box("PulleyCheek2", (0.16, 0.02, 0.22), (px, py - 0.05, BAR_Y - 0.3), b)
    cyl("PulleyWheel", 0.07, 0.07, (px, py, BAR_Y - 0.3), i, rot=(math.pi / 2, 0, 0), verts=10)
    for k in range(7):
        torus("ChainLink", 0.035, 0.012, (px, py, BAR_Y - 0.46 - k * 0.062), i,
              rot=(0, (k % 2) * math.pi / 2, 0), mseg=8, sseg=5)
    sphere("ChainWeight", 0.065, (px, py, BAR_Y - 0.93), i, segments=10, rings=6)
    return "team_tether_banner_rig"


BUILDERS = [
    build_scaffold,
    build_boiler,
    build_pipe_straight,
    build_pipe_elbow,
    build_pipe_tee,
    build_pipe_valve,
    build_pipe_bracket,
    build_rift_siphon,
    build_banner_rig,
]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/environment/team_tether/hall")
    ap.add_argument("--only", default="")
    args = ap.parse_args(argv)

    total = 0
    for fn in BUILDERS:
        stem = fn()
        if args.only and args.only not in stem:
            continue
        n = tri_count()
        total += n
        export(args.out, stem)
        print("[hall-props]   %s: %d tris" % (stem, n))
    print("[hall-props] TOTAL %d tris across %d props" % (total, len(BUILDERS)))


if __name__ == "__main__":
    main()
