"""CPU authoring from the pinned installed castle OBJ; no engine or network."""
import hashlib
import json
import math
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent
REPO = OUT.parents[3]
BASE = '8181ab0802a9d961ef31738e3f58c430ce8dd09a'
SOURCE = 'assets/buildings/quaternius_castle/WallEntranceBricks.obj'


def emit_obj(path, groups):
    lines = ['# Crown-only candidate; authored by source/prepare_candidate.py', 'mtllib crown_arch.mtl']
    vertex = 1
    normal = 1
    for material, triangles in groups.items():
        lines += ['usemtl ' + material]
        for tri in triangles:
            a, b, c = tri
            u = [b[i]-a[i] for i in range(3)]
            v = [c[i]-a[i] for i in range(3)]
            n = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
            length = math.sqrt(sum(x*x for x in n))
            if length < 1e-12:
                continue
            lines += ['v ' + ' '.join(format(x, '.12g') for x in p) for p in tri]
            lines += ['vn ' + ' '.join(format(x/length, '.12g') for x in n)]
            lines += ['f ' + ' '.join(f'{vertex+i}//{normal}' for i in range(3))]
            vertex += 3
            normal += 1
    path.write_text('\n'.join(lines)+'\n', encoding='utf-8', newline='\n')
    return normal - 1


def clip(poly, above):
    out = []
    for a, b in zip(poly, poly[1:]+poly[:1]):
        ia = a[1] >= 2.65 if above else a[1] <= 2.65
        ib = b[1] >= 2.65 if above else b[1] <= 2.65
        if ia:
            out.append(a)
        if ia != ib:
            t = (2.65-a[1])/(b[1]-a[1])
            out.append([a[i]+t*(b[i]-a[i]) for i in range(3)])
    return out


def main():
    raw = subprocess.check_output(['git', '-C', str(REPO), 'show', BASE+':'+SOURCE])
    verts = []
    faces = []
    mat = ''
    for line in raw.decode().splitlines():
        bits = line.split()
        if not bits:
            continue
        if bits[0] == 'v':
            verts.append(list(map(float, bits[1:4])))
        elif bits[0] == 'usemtl':
            mat = bits[1]
        elif bits[0] == 'f':
            ids = [int(s.split('/')[0])-1 for s in bits[1:]]
            faces.extend((mat, [ids[0], ids[i], ids[i+1]]) for i in range(1, len(ids)-1))
    lo = [min(v[i] for v in verts) for i in range(3)]
    hi = [max(v[i] for v in verts) for i in range(3)]
    factor = 4.0/(hi[1]-lo[1])
    centre = [(lo[0]+hi[0])/2, lo[1], (lo[2]+hi[2])/2]
    world = [[(p[i]-centre[i])*factor for i in range(3)] for p in verts]
    width, depth = (hi[0]-lo[0])*factor, (hi[2]-lo[2])*factor
    groups = {'LightRock': [], 'DarkRock': []}
    max_lower_shift = 0.0
    for mat, ids in faces:
        tri = [world[i] for i in ids]
        for above in [False, True]:
            poly = clip(tri, above)
            if len(poly) < 3:
                continue
            changed = []
            for p in poly:
                t = max(0.0, min(1.0, (p[1]-2.65)/1.35))
                q = [p[0]*(1+t*(4.6/width-1)), p[1]+t, p[2]*(1+t*(1.9/depth-1))]
                if p[1] <= 2.65:
                    max_lower_shift = max(max_lower_shift, max(abs(q[i]-p[i]) for i in range(3)))
                # Keep the existing renderer's exact normalization and rear-detail transforms.
                changed.append([q[i]/factor+centre[i] for i in range(3)])
            groups[mat].extend([changed[0], changed[i], changed[i+1]] for i in range(1, len(changed)-1))
    emitted_frame_triangles = emit_obj(OUT/'crown_arch_frame.obj', groups)

    # Each supported top point remains visible at y=.2, including mortar.
    paving = {'PavingA': [], 'PavingB': [], 'PavingC': [], 'Mortar': []}
    def quad(material, a, b, c, d):
        paving[material].extend([[a,b,c],[a,c,d]])
    bands = [-4.5,-2.9,-1.15,0.7,2.55,4.5]
    joints = 0.022
    for j, (z0,z1) in enumerate(zip(bands,bands[1:])):
        cuts = [-4.5,-2.2,0.35,2.8,4.5] if j%2 == 0 else [-4.5,-3.3,-0.8,1.65,4.5]
        a = z0 if j == 0 else z0+joints
        if j:
            quad('Mortar',[-4.5,.2,z0],[4.5,.2,z0],[4.5,.2,a],[-4.5,.2,a])
        for k,(x0,x1) in enumerate(zip(cuts,cuts[1:])):
            b = x0 if k == 0 else x0+joints
            if k:
                quad('Mortar',[x0,.2,a],[b,.2,a],[b,.2,z1],[x0,.2,z1])
            quad(['PavingA','PavingB','PavingC'][(j+k)%3], [b,.2,a],[x1,.2,a],[x1,.2,z1],[b,.2,z1])
    # OBJ top normals must face +Y.
    for material in paving:
        paving[material] = [list(reversed(tri)) for tri in paving[material]]
    quad('PavingB',[-4.5,-.2,-4.5],[4.5,-.2,-4.5],[4.5,.2,-4.5],[-4.5,.2,-4.5])
    quad('PavingB',[4.5,-.2,4.5],[-4.5,-.2,4.5],[-4.5,.2,4.5],[4.5,.2,4.5])
    quad('PavingB',[-4.5,-.2,4.5],[-4.5,-.2,-4.5],[-4.5,.2,-4.5],[-4.5,.2,4.5])
    quad('PavingB',[4.5,-.2,-4.5],[4.5,-.2,4.5],[4.5,.2,4.5],[4.5,.2,-4.5])
    quad('PavingB',[-4.5,-.2,4.5],[4.5,-.2,4.5],[4.5,-.2,-4.5],[-4.5,-.2,-4.5])
    paving['PavingB'][-10:] = [list(reversed(tri)) for tri in paving['PavingB'][-10:]]
    emitted_paving_triangles = emit_obj(OUT/'crown_arch_paving.obj', paving)
    (OUT/'crown_arch.mtl').write_text('\n\n'.join(f'newmtl {name}\nKd 0.5 0.5 0.5' for name in [*groups,*paving])+'\n',encoding='utf-8',newline='\n')
    receipt = {'baseline':BASE,'source':SOURCE,'source_sha256':hashlib.sha256(raw).hexdigest(),
      'normalization_factor':factor,'source_centre':centre,'lower_surface_max_shift_m':max_lower_shift,
      'split_plane_m':2.65,'target_upper_height_m':5.0,'target_upper_width_m':4.6,'target_upper_depth_m':1.9,
      'frame_triangles':{k:len(v) for k,v in groups.items()},'paving_triangles':{k:len(v) for k,v in paving.items()},
      'emitted_frame_triangles':emitted_frame_triangles,'emitted_paving_triangles':emitted_paving_triangles,
      'clip_zero_area_triangles_omitted':sum(len(v) for v in groups.values())-emitted_frame_triangles,
      'paving_support_top_y':0.2,'paving_bounds_m':[9,0.4,9],
      'limits':'CPU authoring receipt, not import, parser, unit or native validation.'}
    effective = [[(p[i]-centre[i])*factor for i in range(3)] for triangles in groups.values() for tri in triangles for p in tri]
    receipt['measured_effective_bounds_min_m'] = [min(p[i] for p in effective) for i in range(3)]
    receipt['measured_effective_bounds_max_m'] = [max(p[i] for p in effective) for i in range(3)]
    receipt['measured_effective_size_m'] = [receipt['measured_effective_bounds_max_m'][i]-receipt['measured_effective_bounds_min_m'][i] for i in range(3)]
    receipt['outputs']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [OUT/'crown_arch_frame.obj',OUT/'crown_arch_paving.obj',OUT/'crown_arch.mtl']}
    (HERE/'geometry-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(receipt,indent=2))


if __name__ == '__main__':
    main()
