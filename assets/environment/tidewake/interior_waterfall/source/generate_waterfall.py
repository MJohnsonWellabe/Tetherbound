"""Original Veilfall geometry, authored from the inspected stronghold board.

Run with Python 3; standard library only. OBJ coordinates are Godot metres,
centre origin, front -Z. No external textures or board pixels are copied.
The source is intentionally deterministic and carries the geometry audit.
"""
from pathlib import Path
import math
import json
import hashlib

ROOT = Path(__file__).resolve().parents[1]
TAU = math.tau


class Mesh:
    def __init__(self, name):
        self.name, self.vertices, self.uvs, self.faces = name, [], [], []

    def grid(self, rows, cols, point):
        base = len(self.vertices)
        for j in range(rows + 1):
            for i in range(cols + 1):
                p, uv = point(i / cols, j / rows)
                self.vertices.append(p)
                self.uvs.append(uv)
        for j in range(rows):
            for i in range(cols):
                a = base + j * (cols + 1) + i
                b, c, d = a + 1, a + cols + 1, a + cols + 2
                self.faces.extend(((a, b, c), (b, d, c)))

    def write(self):
        normals = [[0., 0., 0.] for _ in self.vertices]
        min_area = float('inf')
        for face in self.faces:
            p, q, r = [self.vertices[i] for i in face]
            a, b = [q[k] - p[k] for k in range(3)], [r[k] - p[k] for k in range(3)]
            cross = [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]
            area = math.sqrt(sum(v*v for v in cross))
            assert area > 1e-9, (self.name, face, 'degenerate triangle')
            min_area = min(min_area, area / 2)
            for idx in face:
                normals[idx] = [normals[idx][k] + cross[k] for k in range(3)]
        for idx, normal in enumerate(normals):
            length = math.sqrt(sum(v*v for v in normal))
            assert length > 1e-9
            normals[idx] = [v / length for v in normal]
            assert abs(sum(v*v for v in normals[idx]) - 1) < 1e-9
        lines = ['# Original Tetherbound Veilfall mesh. See source/generate_waterfall.py.', 'o ' + self.name]
        lines += ['v ' + ' '.join(f'{v:.6f}' for v in p) for p in self.vertices]
        lines += ['vt ' + ' '.join(f'{v:.6f}' for v in p) for p in self.uvs]
        lines += ['vn ' + ' '.join(f'{v:.6f}' for v in p) for p in normals]
        lines += ['f ' + ' '.join(f'{i+1}/{i+1}/{i+1}' for i in f) for f in self.faces]
        path = ROOT / (self.name + '.obj')
        path.write_text('\n'.join(lines) + '\n', encoding='utf-8')
        return {'file': path.name, 'vertices': len(self.vertices), 'triangles': len(self.faces),
                'bounds_min': [round(min(p[k] for p in self.vertices), 4) for k in range(3)],
                'bounds_max': [round(max(p[k] for p in self.vertices), 4) for k in range(3)],
                'minimum_triangle_area_m2': min_area, 'unit_normals': True,
                'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}


def stone_block(mesh, centre, size, bevel=.10):
    """Closed chamfered masonry, including actual mortar gaps between blocks."""
    cx, cy, cz = centre
    sx, sy, sz = [s*.5 for s in size]
    b = min(bevel, sy*.4, sx*.4, sz*.4)
    rings = []
    for yy, inset in [(-sy,b),(-sy+b,0),(sy-b,0),(sy,b)]:
        xx, zz = sx-inset, sz-inset
        bb = b*.45
        ring = []
        for px,pz in [(-xx+bb,-zz),(xx-bb,-zz),(xx,-zz+bb),(xx,zz-bb),(xx-bb,zz),(-xx+bb,zz),(-xx,zz-bb),(-xx,-zz+bb)]:
            ring.append(len(mesh.vertices))
            mesh.vertices.append((cx+px,cy+yy,cz+pz))
            mesh.uvs.append(((cx+px)*.5,(cy+yy+cz+pz)*.5))
        rings.append(ring)
    for a,c in zip(rings,rings[1:]):
        for i in range(8):
            j=(i+1)%8
            mesh.faces.extend([(a[i],c[i],a[j]),(a[j],c[i],c[j])])
    for ring,reverse in [(rings[0],False),(rings[-1],True)]:
        for i in range(1,7):
            tri=(ring[0],ring[i],ring[i+1])
            mesh.faces.append(tuple(reversed(tri)) if reverse else tri)


def ribbon(mesh, centre, width, seed, depth=0., thread=False):
    def point(u, v):
        # Bent crest leading into accelerating, scalloped ribbons. All stream
        # edges are mesh boundaries: the background is visible through air gaps.
        # A full quarter-circle rolls from the recessed source shelf toward
        # the camera. The rounded shoulder is 1.35m deep and 1.05m tall,
        # entirely below the nominal ceiling, rather than clipped at it.
        crest_end = .16
        if v < crest_end:
            angle = v / crest_end * math.pi / 2
            y = 4.65 - 1.05 * (1. - math.cos(angle))
            z = -.45 - 1.35 * math.sin(angle) + depth
        else:
            fall = (v - crest_end) / (1. - crest_end)
            y = 3.60 - 8.96 * fall
            z = -1.80 + depth - .30 * fall * fall
        z += (.08 + .12 * math.sin(u * 7. + seed)) * math.sin(v * 21. + seed + u * 4.) * min(v * 9., 1.)
        # Five broad, asymmetrical masses, not a row of equal strings.
        width_profile = .91 + .06 * math.sin(v * 13. + seed) + .025 * math.sin(v * 39. + seed * 3.)
        width_profile *= 1. - .09 * math.sin(math.pi * v + seed)
        drift = .17 * math.sin(v * 10. + seed) * math.sin(v * math.pi)
        x = centre + (u - .5) * width * width_profile + drift
        z += math.sin(u * math.pi) * (-.06 if thread else -.18)
        return (x, y, z), (u, v)
    mesh.grid(100, 4 if thread else 20, point)


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    sheets, threads, crowns, spray, mist = [Mesh(s) for s in ['fall_ribbons', 'fall_threads', 'plunge_crowns', 'splash_arcs', 'plunge_mist']]
    stone, pool = Mesh('source_and_basin_stone'), Mesh('receiving_water')
    # The top of the source is below the fixed ceiling. A segmented lintel,
    # feeder jambs and protruding wet lip explain the water's origin.
    for n in range(8):
        x=-6.93+n*1.98
        stone_block(stone,(x,5.47,-.12),(1.94,.87,1.24),.14)
        stone_block(stone,(x,4.00,-.70),(1.94,.45,1.82),.13)
        # Low front receiving rim: water remains visible behind the edge.
        stone_block(stone,(x,-5.60,-4.13),(1.94,.70,.70),.11)
    for n,x in enumerate([-7.74,-4.89,-1.79,1.28,4.47,7.74]):
        stone_block(stone,(x,4.77,-.20),(.36,1.34,1.10),.08)
    for x in [-7.71,7.71]:
        for n in range(3):
            stone_block(stone,(x,-5.60,-.10-n*1.30),(.56,.70,1.26),.10)
    # A dark water surface is held inside the shallow masonry trough.
    def pool_point(u,v):
        return ((u-.5)*14.82,-5.36,-.12-v*3.66),(u,v)
    pool.grid(24,64,pool_point)
    # Irregular sheet groups overlap in depth and leave only occasional
    # broken air slots. Secondary sheets interrupt long picket-fence gaps.
    bands = [(-6.20,2.45),(-3.38,2.12),(-.47,2.64),(2.87,2.90),(6.13,2.25)]
    for index, (centre, width) in enumerate(bands):
        ribbon(sheets, centre, width, index * 1.713, .24 * math.sin(index * 2.))
        # Sparingly detached foreground water; do not outline every band.
        if index in (1, 3, 4):
            ribbon(threads, centre - width * .21, width * .15,
                   index * 1.1, -.34, True)
        # Broad impact fans extend forward across the receiving surface.
        def crown(u, v, n=index, x=centre, w=width):
            angle = -.18 + u * (math.pi + .36)
            radius = .14 + v * (1.33 + .20 * math.sin(n * 1.8))
            peak = (.63 + .48 * math.sin(u * 13. + n)**2) * math.sin(v * math.pi * .93)
            height = -5.34 + peak + .34 * (math.sin(u * 23. + n * 2.)**8) * v
            return (x + math.cos(angle) * radius * .94, height, -1.99 - math.sin(angle) * radius), (u, v)
        crowns.grid(14, 42, crown)
        # A broad undulating boil provides an actual receiving footprint.
        def boil(u, v, n=index, x=centre, w=width):
            xx = (u-.5) * w * .98
            zz = -1.85 - 1.80 * v
            yy = -5.32 + .15 * math.sin(u*17. + v*12. + n)**2 * math.sin(v*math.pi)
            return (x+xx, yy, zz), (u,v)
        crowns.grid(14, 30, boil)
        for n in range(7):
            def arc(u, v, x=centre, w=width, seed=index * 7 + n):
                angle = .25 + ((seed * 1.317) % 2.6)
                length = 1.02 + .18 * (seed % 4)
                x_offset = math.cos(angle) * length * v
                y = -5.30 + math.sin(v * math.pi) * (.78 + .21 * (seed % 3))
                z = -1.99 - math.sin(angle) * length * v
                breadth = .085 * (.12 + math.sin(math.pi * v))
                return (x + x_offset + (u-.5)*breadth, y, z), (u, v)
            spray.grid(12, 2, arc)
    for centre, width, seed, depth in [(-4.57,.76,2.6,.30),(1.19,.82,4.5,.26),(4.73,.73,8.3,.31)]:
        ribbon(sheets, centre, width, seed, depth)
    mist_centres = [-6.25,-4.5,-2.0,.2,2.8,5.6,-5.4,-1.2,1.5,4.8]
    for index, centre in enumerate(mist_centres):
        def cloud(u, v, n=index, x=centre):
            # Curved elliptical meshlets low at the physical impact row.
            # Their shader dissolves their borders; no box emitter or billboard.
            xx = (u-.5) * (2.9 + .46 * math.sin(n * 1.9))
            yy = (v-.5) * (2.20 + .40 * math.cos(n))
            z = -3.12 - .65 * math.sin(u * math.pi) * math.sin(v * math.pi) - (n//6)*.55
            return (x + xx, -4.26 + yy, z), (u, v)
        mist.grid(8, 12, cloud)
    report = [mesh.write() for mesh in [sheets, threads, crowns, spray, mist, stone, pool]]
    assert all(-8.01 <= row['bounds_min'][0] and row['bounds_max'][0] <= 8.01 for row in report)
    assert all(-6.01 <= row['bounds_min'][1] and row['bounds_max'][1] <= 6.01 for row in report)
    (ROOT / 'source' / 'geometry_audit.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
