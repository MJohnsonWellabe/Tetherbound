"""Read compressed resource bytes only; no Godot or scene execution."""
from pathlib import Path
import ctypes
import struct
import re

src = Path('D:/tetherbound/foundations-batch-check/data/terrain/playground/terrain3d_00_00.res').read_bytes()
mode, block_size, total = struct.unpack_from('<III', src, 4)
assert src[:4] == b'RSCC' and mode == 2
count = total // block_size + 1
sizes = struct.unpack_from('<' + 'I' * count, src, 16)
lib = ctypes.CDLL('C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/poppler/Library/bin/libzstd.dll')
lib.ZSTD_decompress.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_size_t]
lib.ZSTD_decompress.restype = ctypes.c_size_t
parts = []
at = 16 + count * 4
for size in sizes:
    output = ctypes.create_string_buffer(block_size)
    compressed = ctypes.create_string_buffer(src[at:at + size])
    n = lib.ZSTD_decompress(output, block_size, compressed, size)
    assert n <= block_size, n
    parts.append(output.raw[:n])
    at += size
raw = b''.join(parts)
assert len(raw) == total
Path('D:/tetherbound/feature-f31/.tmp/f31-bed-diagnostic/terrain-resource.bin').write_bytes(raw)
print('Decoded resource bytes:', len(raw))
print('Header:', raw[:150].hex())
print('Strings:', [(m.start(), m.group().decode('ascii')) for m in re.finditer(rb'[A-Za-z_][A-Za-z_0-9]{4,}', raw[:2500])])

# First embedded Image is a 256x256 RFloat height map. Verify the byte-array
# length and format before reading the authored region's 2m vertex lattice.
assert b'RFloat\0' in raw[480:628]
assert struct.unpack_from('<I', raw, 624)[0] == 256 * 256 * 4
def vertex(x, z):
    return struct.unpack_from('<f', raw, 628 + 4 * (z * 256 + x))[0]

def height(x, z):
    import math
    px, pz = x / 2, z / 2
    ix, iz = math.floor(px), math.floor(pz)
    fx, fz = px - ix, pz - iz
    a = vertex(ix, iz) * (1 - fx) + vertex(ix + 1, iz) * fx
    b = vertex(ix, iz + 1) * (1 - fx) + vertex(ix + 1, iz + 1) * fx
    return a * (1 - fz) + b * fz

for aim_z in (67, 70):
    snapped_z = 68 if aim_z == 67 else 70
    raw_height = height(70, aim_z)
    center_height = height(70, snapped_z)
    samples = [height(70 + dx, snapped_z + dz) for dx, dz in ((1.2, 0), (-1.2, 0), (0, 1.2), (0, -1.2))]
    print({'raw': [70, aim_z], 'snapped': [70, snapped_z], 'raw_height': raw_height,
           'center_height': center_height, 'corner_heights': samples,
           'old_rise': max(abs(h - raw_height) for h in samples),
           'center_rise': max(abs(h - center_height) for h in samples)})
