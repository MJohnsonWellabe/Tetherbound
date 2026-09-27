"""Original project geometry: fractured limestone silhouette family.

Reference: inspected Cloudreach Sky Aviary stronghold board (composition and
vertical buttress/ledge language only). No board pixels or third-party mesh data.
Normalized base-centered meshes retain the host's authored placement and size.
"""
from pathlib import Path
import math

OUT = Path(__file__).resolve().parents[2] / 'assets/environment/cloudreach'
N, LEVELS = 64, 28

def build(variant):
    vertices, uvs, faces = [], [], []
    phase = (0.37, 1.83, 3.47)[variant]
    # A few large buttresses, fine fissures and broken sediment shelves.
    for level in range(LEVELS + 1):
        t = level / LEVELS
        for k in range(N):
            angle = k * math.tau / N
            crest = 0.95 + 0.03*math.sin(3*angle+phase) + 0.02*math.sin(5*angle-phase)
            buttress = 0.90 + 0.19*math.cos(5*angle+phase) + 0.065*math.sin(9*angle-0.7*phase)
            fissure = 0.12 * max(0, math.cos(7*angle+phase))**6
            # Shelves erode inward over each layer, then break outward. Their
            # angular phase varies, avoiding perfectly horizontal stacked rings.
            sediment = t*4.0 + 0.055*math.sin(3*angle+phase) + 0.025*math.sin(11*angle)
            fraction = sediment - math.floor(sediment)
            ledge = 0.022 * (1.0-fraction)**3
            taper = 1.0 - 0.16*t + 0.035*math.sin(t*9+phase)
            radius = 0.5 * (buttress-fissure) * taper + ledge
            lean_x = 0.045 * t*t*math.sin(phase)
            lean_z = 0.045 * t*t*math.cos(phase)
            crown_weight = max(0.0,(t-0.65)/0.35)**2
            y = t - (1.0-crest)*crown_weight
            vertices.append((radius*math.cos(angle)+lean_x, y, radius*math.sin(angle)+lean_z))
            uvs.append((k/N,t))
    # Counter-clockwise exterior OBJ winding; Godot's importer handles its
    # native front-face convention. No open underside or floating sections.
    for level in range(LEVELS):
        for k in range(N):
            a=level*N+k; b=level*N+(k+1)%N; c=(level+1)*N+k; d=(level+1)*N+(k+1)%N
            faces.extend([(a,c,b),(b,c,d)])
    bottom=len(vertices); vertices.append((0,0,0)); uvs.append((0.5,0.5))
    top=len(vertices); vertices.append((0,0.95,0)); uvs.append((0.5,0.5))
    for k in range(N):
        faces.append((bottom,k,(k+1)%N))
        faces.append((top,LEVELS*N+(k+1)%N,LEVELS*N+k))
    # Export exact [0,1] height and unit X/Z extents for authored world sizes.
    low=[min(v[j] for v in vertices) for j in range(3)]
    high=[max(v[j] for v in vertices) for j in range(3)]
    vertices=[tuple((v[j]-low[j])/(high[j]-low[j])-(0.5 if j!=1 else 0) for j in range(3)) for v in vertices]
    lines=['# Original Tetherbound limestone spire; see ART_DIRECTION provenance.',f'o LimestoneSpire{variant+1}','s 1']
    lines += ['v %.7f %.7f %.7f'%v for v in vertices]
    lines += ['vt %.7f %.7f'%uv for uv in uvs]
    lines += ['f '+' '.join(f'{i+1}/{i+1}' for i in tri) for tri in faces]
    path=OUT/f'limestone_spire_{variant+1}.obj'
    path.write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    print(f'{path.name}: {len(vertices)} vertices, {len(faces)} triangles')

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    for variant in range(3): build(variant)
