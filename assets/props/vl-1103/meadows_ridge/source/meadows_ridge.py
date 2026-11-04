# Meadows ridge backdrop (F38#24 / P2-014): one continuous, camera-centred ring
# of naturalistic mountain ridge for scripts/world/horizon_ranges.gd.
#   blender -b -P meadows_ridge.py -- <out.glb> <albedo.png> <ring_preview.png> <scale_check.jpg>
# Built in Blender from a deterministic numpy heightfield in polar coordinates
# (bearing x depth), so every crest belongs to one ridge line: domain-warped
# ridged multifractal crest, a massif envelope that never drops below a saddle
# (no gaps, no isolated cones), drainage gullies down the front faces and a
# forested foothill shelf in front. Albedo is computed at 6x mesh resolution
# from the same field (forest / rock / snow by height and slope, gully
# darkening) and written as a PNG atlas of eight 45-degree strips, so the GLB
# carries an image texture. Bearings follow horizon_ranges.gd: Godot bearing b
# is atan2(z, x); Blender y = -Godot z.
import math, os, struct, sys, zlib
import numpy as np

argv = sys.argv[sys.argv.index('--') + 1:]
OUT, ALBEDO, PREVIEW, SCALE = argv[:4]

R0, R1 = 1400.0, 1945.0          # front skirt edge, back edge (camera far floor is 2000 m)
SEGMENTS, ROWS = 896, 24         # 8 strips x 112 segments; 896 x 24 x 2 = 43k tris
STRIPS = 8
TEX = 2048                       # atlas: 8 strips of 2048 x 256 (240 content + 8 px pads)
STRIP_H, PAD = 256, 8
SKIRT = -150.0
HERO = [(131.0, 7.0, 210.0), (52.0, 9.0, 120.0), (238.0, 8.0, 140.0), (318.0, 10.0, 90.0)]

# ---------------------------------------------------------------- noise
rng = np.random.default_rng(20261103)
PERM = np.concatenate([rng.permutation(256)] * 2)
GRAD = np.array([[1,1,0],[-1,1,0],[1,-1,0],[-1,-1,0],[1,0,1],[-1,0,1],[1,0,-1],[-1,0,-1],
                 [0,1,1],[0,-1,1],[0,1,-1],[0,-1,-1]], dtype=np.float64)

def perlin(x, y, z):
    xi, yi, zi = np.floor(x).astype(int), np.floor(y).astype(int), np.floor(z).astype(int)
    xf, yf, zf = x - xi, y - yi, z - zi
    xi, yi, zi = xi & 255, yi & 255, zi & 255
    f = lambda t: t * t * t * (t * (t * 6 - 15) + 10)
    u, v, w = f(xf), f(yf), f(zf)
    def g(ix, iy, iz, dx, dy, dz):
        h = PERM[PERM[PERM[ix] + iy] + iz] % 12
        gr = GRAD[h]
        return gr[..., 0] * dx + gr[..., 1] * dy + gr[..., 2] * dz
    n000 = g(xi, yi, zi, xf, yf, zf); n100 = g(xi + 1, yi, zi, xf - 1, yf, zf)
    n010 = g(xi, yi + 1, zi, xf, yf - 1, zf); n110 = g(xi + 1, yi + 1, zi, xf - 1, yf - 1, zf)
    n001 = g(xi, yi, zi + 1, xf, yf, zf - 1); n101 = g(xi + 1, yi, zi + 1, xf - 1, yf, zf - 1)
    n011 = g(xi, yi + 1, zi + 1, xf, yf - 1, zf - 1); n111 = g(xi + 1, yi + 1, zi + 1, xf - 1, yf - 1, zf - 1)
    lerp = lambda a, b, t: a + (b - a) * t
    return lerp(lerp(lerp(n000, n100, u), lerp(n010, n110, u), v),
                lerp(lerp(n001, n101, u), lerp(n011, n111, u), v), w)

def fbm(x, y, z, octaves, lac=2.0, gain=0.5):
    out = np.zeros_like(x); amp = 1.0; norm = 0.0
    for o in range(octaves):
        out += perlin(x, y, z + o * 17.3) * amp; norm += amp; amp *= gain
        x, y, z = x * lac, y * lac, z * lac
    return out / norm

def ridged(x, y, z, octaves, lac=2.05, gain=0.5):
    out = np.zeros_like(x); amp = 1.0; weight = np.ones_like(x); norm = 0.0
    for o in range(octaves):
        n = 1.0 - np.abs(perlin(x, y, z + o * 31.7) * 1.6)
        n = np.clip(n, 0, 1) ** 2 * weight
        weight = np.clip(n * 1.6, 0, 1)
        out += n * amp; norm += amp; amp *= gain
        x, y, z = x * lac, y * lac, z * lac
    return out / norm

def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)

# ---------------------------------------------------------------- the field
def field(bearing, t):
    """Height (m above the ring's base) and gully mask at bearing (rad, Godot) and depth t in [0, 1]."""
    cx, cz = np.cos(bearing), np.sin(bearing)
    # low-frequency envelope sampled on a 1 km circle: massif amplitude, crest position
    mass = fbm(cx * 2.2 + 11, cz * 2.2 - 4, 0.3 + 0 * t, 3)
    amp = 250.0 + 150.0 * smoothstep(-0.45, 0.55, mass)
    for b_deg, w_deg, lift in HERO:
        off = np.abs((bearing - math.radians(b_deg) + math.pi) % (2 * math.pi) - math.pi)
        amp = amp + lift * np.exp(-(off / math.radians(w_deg)) ** 2)
    crest_t = 0.70 + 0.06 * fbm(cx * 3.1 - 7, cz * 3.1 + 2, 1.7 + 0 * t, 2)
    # domain-warped ridged crest detail in metres along the ring
    R = 1750.0
    px, pz = cx * R, cz * R
    py = t * (R1 - R0)
    wx = fbm(px / 420 + 3, pz / 420, py / 420, 3) * 160
    wz = fbm(px / 420 - 9, pz / 420, py / 420 + 5, 3) * 160
    crest = ridged((px + wx) / 620, (pz + wz) / 620, py / 620, 7)
    peaks = fbm(px / 260 + 40, pz / 260, py / 900, 3)
    # cross-section: long front slope, short back slope, never a cone
    front = np.exp(-((t - crest_t) / 0.42) ** 2 * 1.6)
    back = np.exp(-((t - crest_t) / 0.16) ** 2 * 1.6)
    profile = np.where(t < crest_t, front, back)
    h = amp * profile * np.clip(0.40 + 0.85 * crest + 0.16 * peaks, 0.25, None)
    # drainage gullies: noise stretched down-slope, carved into the front face
    gx = fbm((px + wx * 1.4) / 95, (pz + wz * 1.4) / 95, py / 380, 3)
    gully = smoothstep(0.6, 0.95, 1.0 - np.abs(gx) * 3.2) * smoothstep(crest_t, crest_t - 0.35, t) * (t < crest_t)
    h = h - gully * 0.05 * h
    # forested foothill shelf in front of the main ridge, melting into it
    foot_amp = 50.0 + 80.0 * (fbm(px / 600 + 21, pz / 600, 4.0 + 0 * t, 3) * 0.5 + 0.5)
    foot = foot_amp * np.exp(-((t - 0.24) / 0.15) ** 2) * (0.7 + 0.6 * fbm(px / 160, pz / 160, py / 160 + 9, 4))
    k = 40.0   # smooth max
    h = k * np.log(np.exp(h / k) + np.exp(foot / k))
    # front skirt sinks below the far plain; back edge stays low behind the crest
    h = np.where(t <= 0.0, SKIRT, h * smoothstep(0.0, 0.07, t) + SKIRT * (1 - smoothstep(0.0, 0.07, t)))
    return h, gully

def ring_radius(t):
    return R0 + (R1 - R0) * t

def grid(nb, nt, b0, b1):
    b = np.linspace(b0, b1, nb)
    t = np.linspace(0.0, 1.0, nt)
    B, T = np.meshgrid(b, t)   # rows = t, cols = bearing
    return B, T

# ---------------------------------------------------------------- albedo atlas
# sRGB colours written straight into the PNG (no linear conversion), kept dark:
# the far ranges sit under heavy aerial fog, which lifts them toward the sky.
FOREST = np.array([0.15, 0.24, 0.15]); FOREST2 = np.array([0.20, 0.29, 0.17])
MEADOW = np.array([0.30, 0.37, 0.20])
ROCK = np.array([0.30, 0.33, 0.35]); ROCK2 = np.array([0.24, 0.28, 0.29])
SNOW = np.array([0.80, 0.84, 0.88])

def colours(B, T):
    h, gully = field(B, T)
    r = ring_radius(T)
    # slope from finite differences in metres
    db = (B[0, 1] - B[0, 0]) * 1750.0; dt = (T[1, 0] - T[0, 0]) * (R1 - R0)
    gy, gx = np.gradient(h, dt, db)
    slope = np.sqrt(gx ** 2 + gy ** 2)
    cx, cz = np.cos(B), np.sin(B)
    n1 = fbm(cx * 1750 / 90, cz * 1750 / 90, T * 4, 4)
    n2 = fbm(cx * 1750 / 30 + 5, cz * 1750 / 30, T * 12, 3)
    tree_line = 170.0 + 45.0 * n1
    snow_line = 365.0 + 30.0 * n1
    forest = FOREST + (FOREST2 - FOREST) * smoothstep(-0.4, 0.5, n2)[..., None]
    forest = forest + (MEADOW - forest) * (smoothstep(0.55, 0.9, n1) * 0.5)[..., None]
    rock = ROCK2 + (ROCK - ROCK2) * smoothstep(-0.5, 0.5, n2)[..., None]
    # strata, gentle and noise-warped (never regular bands)
    strata = 0.92 + 0.08 * np.sin((h + n1 * 22) / 13.0)
    rock = rock * strata[..., None]
    rock_w = np.clip(smoothstep(tree_line - 40, tree_line + 40, h) + smoothstep(0.9, 1.6, slope) * 0.8, 0, 1)
    rock_w = rock_w * smoothstep(0.04, 0.10, T)   # the sunken front skirt stays dark forest
    c = forest + (rock - forest) * rock_w[..., None]
    snow_w = smoothstep(snow_line - 12, snow_line + 12, h) * (1 - smoothstep(1.1, 1.8, slope) * 0.75)
    c = c + (SNOW - c) * snow_w[..., None]
    # gullies and the back slope read darker; crests a touch lighter
    c = c * (1 - 0.12 * gully)[..., None]
    c = c * (0.94 + 0.06 * n2)[..., None]
    return np.clip(c, 0, 1)

def write_png(path, rgb):
    hgt, wid, _ = rgb.shape
    data = (np.clip(rgb, 0, 1) * 255 + 0.5).astype(np.uint8)
    raw = b''.join(b'\x00' + data[y].tobytes() for y in range(hgt))
    def chunk(tag, payload):
        return struct.pack('>I', len(payload)) + tag + payload + struct.pack('>I', zlib.crc32(tag + payload) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', wid, hgt, 8, 2, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))

CONTENT = STRIP_H - 2 * PAD
atlas = np.zeros((TEX, TEX, 3))   # row 0 = top of the image
for k in range(STRIPS):
    b0 = 2 * math.pi * k / STRIPS; b1 = 2 * math.pi * (k + 1) / STRIPS
    B, T = grid(TEX, CONTENT, b0, b1)
    c = colours(B, T)                      # rows: t = 0 .. 1
    c = np.concatenate([np.repeat(c[:1], PAD, 0), c, np.repeat(c[-1:], PAD, 0)], 0)
    # strip k occupies image rows from the bottom: v grows upward in glTF/Blender UV
    top = TEX - (k + 1) * STRIP_H
    atlas[top:top + STRIP_H] = c[::-1]
write_png(ALBEDO, atlas)
print('ALBEDO_OK', ALBEDO)

# ---------------------------------------------------------------- mesh
import bpy, bmesh
bpy.ops.wm.read_factory_settings(use_empty=True)
scn = bpy.context.scene
B, T = grid(SEGMENTS + 1, ROWS + 1, 0.0, 2 * math.pi)
# rows concentrated near the crest region where the silhouette lives
T = T ** 0.92
H, _ = field(B, T)
Rr = ring_radius(T)
verts = []
for j in range(ROWS + 1):
    for i in range(SEGMENTS):           # last column wraps to the first
        b = B[j, i]
        verts.append((math.cos(b) * Rr[j, i], -math.sin(b) * Rr[j, i], float(H[j, i])))
faces = []
uvs = []
per = SEGMENTS // STRIPS
def vidx(i, j): return j * SEGMENTS + (i % SEGMENTS)
def uv(i_local, j, k):
    u = i_local / per
    v_px = k * STRIP_H + PAD + T[j, 0] * (CONTENT - 1) + 0.5
    return (u * (TEX - 1) / TEX + 0.5 / TEX, v_px / TEX)
for i in range(SEGMENTS):
    k = i // per; il = i - k * per
    for j in range(ROWS):
        # wound so normals face the ring centre (the camera)
        faces.append((vidx(i, j), vidx(i, j + 1), vidx(i + 1, j + 1), vidx(i + 1, j)))
        uvs.append((uv(il, j, k), uv(il, j + 1, k), uv(il + 1, j + 1, k), uv(il + 1, j, k)))
mesh = bpy.data.meshes.new('MeadowsRidge')
mesh.from_pydata(verts, [], faces)
mesh.update()
uvl = mesh.uv_layers.new(name='UVMap')
for poly, quad in zip(mesh.polygons, uvs):
    for li, co in zip(poly.loop_indices, quad):
        uvl.data[li].uv = co
obj = bpy.data.objects.new('MeadowsRidge', mesh)
scn.collection.objects.link(obj)
# make the normals face the origin
bm = bmesh.new(); bm.from_mesh(mesh)
bm.faces.ensure_lookup_table()
f0 = bm.faces[len(bm.faces) // 2]
c0 = f0.calc_center_median()
if f0.normal.dot(-c0.normalized()) < 0:
    for f in bm.faces: f.normal_flip()
bm.to_mesh(mesh); bm.free()
mesh.shade_smooth()
mat = bpy.data.materials.new('meadows_ridge'); mat.use_nodes = True
nt = mat.node_tree; bsdf = nt.nodes['Principled BSDF']
img = bpy.data.images.load(ALBEDO); img.pack()
tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = img
tex.interpolation = 'Linear'
nt.links.new(tex.outputs[0], bsdf.inputs['Base Color'])
bsdf.inputs['Roughness'].default_value = 1.0
bsdf.inputs['Specular IOR Level'].default_value = 0.0
mesh.materials.append(mat)
bpy.context.view_layer.objects.active = obj; obj.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_apply=True,
                          export_image_format='AUTO')
print('GLB_OK', OUT, 'tris', len(faces) * 2)

# ---------------------------------------------------------------- previews
sky = bpy.data.worlds.new('w'); scn.world = sky; sky.use_nodes = True
sky.node_tree.nodes['Background'].inputs[0].default_value = (0.42, 0.55, 0.68, 1)
sky.node_tree.nodes['Background'].inputs[1].default_value = 1.0
sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN')); sun.data.energy = 3.5
sun.rotation_euler = (math.radians(57), 0, math.radians(200)); scn.collection.objects.link(sun)
scn.render.engine = 'CYCLES'; scn.cycles.device = 'CPU'; scn.cycles.samples = 16
scn.view_settings.view_transform = 'Standard'
scn.world.mist_settings.start = 300; scn.world.mist_settings.depth = 3000
camd = bpy.data.cameras.new('cam'); camd.lens = 24; camd.clip_end = 5000
cam = bpy.data.objects.new('cam', camd); scn.collection.objects.link(cam); scn.camera = cam
b = math.radians(131.0)
cam.location = (0.0, 0.0, 45.0)
# preview: the whole ring as an equirectangular strip (continuity check)
camd.type = 'PANO'; camd.panorama_type = 'EQUIRECTANGULAR'
camd.latitude_min, camd.latitude_max = math.radians(-6), math.radians(24)
cam.rotation_euler = (math.radians(90), 0, 0)
scn.render.resolution_x, scn.render.resolution_y = 2400, 200
scn.render.filepath = PREVIEW; bpy.ops.render.render(write_still=True)
camd.type = 'PERSP'
# point the camera at bearing b (Blender direction (cos b, -sin b))
d = (math.cos(b), -math.sin(b), 0.0)
cam.rotation_euler = (math.radians(86), 0, math.atan2(d[1], d[0]) - math.pi / 2)
# scale check: a 1.80 m trainer cylinder in the foreground meadow, camera at eye height
bpy.ops.mesh.primitive_plane_add(size=600, location=(d[0] * 260, d[1] * 260, 0.0))
gm = bpy.data.materials.new('grass'); gm.use_nodes = True
gm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.05, 0.12, 0.03, 1)
bpy.context.object.data.materials.append(gm)
bpy.ops.mesh.primitive_cylinder_add(radius=0.25, depth=1.8, location=(d[0] * 12 + d[1] * 1.5, d[1] * 12 - d[0] * 1.5, 0.9))
tm = bpy.data.materials.new('trainer'); tm.use_nodes = True
tm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.35, 0.33, 0.30, 1)
bpy.context.object.data.materials.append(tm)
obj.location.z = -40.0   # horizon_ranges base_y: the ring's base sits 40 m below the play plane
cam.location = (0.0, 0.0, 1.7)
cam.rotation_euler = (math.radians(92), 0, math.atan2(d[1], d[0]) - math.pi / 2)
scn.render.resolution_x, scn.render.resolution_y = 1280, 720
scn.render.image_settings.file_format = 'JPEG'
scn.render.filepath = SCALE; bpy.ops.render.render(write_still=True)
print('PREVIEW_OK')
