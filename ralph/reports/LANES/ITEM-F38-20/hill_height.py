# Shared heightfield of the F38#20 keep hill (used by build_keep_hill.py and build_keep_walls.py).
import math
from mathutils import Vector, noise

X_HALF, Z0, Z1 = 430.0, -40.0, 520.0   # local extent (z from the gate mouth)
CX, CZ = 0.0, 200.0                    # hill crown behind the keep (keep centre z 149)
RX, RZ = 420.0, 300.0
H = 78.0                               # crown height above the hill base
BASE_SINK = 14.0                       # base sits this far below the hall floor (config offset y)
NOTCH_X, NOTCH_Z = 70.0, 125.0         # hall footprint: kept below the floor
NOTCH_TOP = BASE_SINK - 3.0            # 3 m under the hall floor
STEP = 8.0

def smooth(t):
    t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)

def height(x, z):
    d = math.sqrt(((x - CX) / RX) ** 2 + ((z - CZ) / RZ) ** 2)
    h = H * (0.5 + 0.5 * math.cos(math.pi * min(1.0, d))) if d < 1.0 else 0.0
    h += 9.0 * noise.noise(Vector((x / 140.0, z / 140.0, 0.3))) * smooth(1.0 - d)
    h += 3.0 * noise.noise(Vector((x / 37.0, z / 37.0, 1.7))) * smooth(1.0 - d)
    h *= smooth((z - Z0) / 60.0)                                   # nothing in front of the mouth
    # hall notch: capped under the floor across the footprint, blended out over 40 m
    nx = smooth((abs(x) - NOTCH_X) / 40.0)
    nz = smooth((z - NOTCH_Z) / 40.0)
    inside = 1.0 - max(nx, nz)
    cap = NOTCH_TOP
    if h > cap:
        h = h * (1.0 - inside) + cap * inside
    return max(0.0, h)

