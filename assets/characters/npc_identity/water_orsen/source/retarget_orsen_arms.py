"""Private, exact-input Orsen upper-arm track correction. Root-authorized exact recipe; writes only new private outputs.

After root code review only:
  python retarget_orsen_arms.py --apply-reviewed-recipe

Writes a NEW private GLB and receipt. Never writes repository/stage assets.
Hamilton xyzw: Q_new = (R_rest * D_local * inverse(R_rest)) * Q_old.
All 14 bound tracks are LINEAR. Refuse unexpected interpolation rather than
silently treating cubic tangents as quaternion values.
"""
import argparse
import copy
import hashlib
import json
import math
import struct
from pathlib import Path

ROOT = Path.cwd().resolve()  # Run with the repository root as cwd.
INPUT = ROOT / 'assets_raw/water_orsen/local-bake-v1/orsen_animated.glb'
RECIPE = Path(__file__).with_name('arm_retarget_recipe.json')
OUTPUT = ROOT / 'assets_raw/water_orsen/local-arm-retarget-v1/orsen_arms_corrected.glb'
RECEIPT = OUTPUT.with_suffix('.receipt.json')
INPUT_SHA = 'a3fd8bd4fa66936e2cace642e2ca0370a12353ce8f8eb288a204f6153d61bd91'
RECIPE_SHA = '6d234dbc6ecca80a1a2836bc121153aae3652533c6ac17ea8a2e6064160b12a9'
CLIPS = ('idle', 'walk', 'sprint', 'jump', 'throw', 'chop', 'defeated')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def unit(q):
    require(len(q) == 4 and all(math.isfinite(x) for x in q), 'Invalid quaternion')
    n = math.sqrt(sum(x*x for x in q))
    require(n > 1e-10, 'Zero quaternion')
    return tuple(x/n for x in q)


def mul(a, b):
    x,y,z,w = a
    X,Y,Z,W = b
    return (w*X+x*W+y*Z-z*Y, w*Y-x*Z+y*W+z*X,
            w*Z+x*Y-y*X+z*W, w*W-x*X-y*Y-z*Z)


def parse(raw):
    require(len(raw) >= 20, 'Truncated GLB')
    magic, version, length = struct.unpack_from('<III', raw)
    require((magic, version, length) == (0x46546c67, 2, len(raw)), 'Invalid GLB header')
    chunks = []
    offset = 12
    while offset < len(raw):
        require(offset+8 <= len(raw), 'Truncated chunk header')
        size, kind = struct.unpack_from('<II', raw, offset)
        offset += 8
        require(size % 4 == 0 and offset+size <= len(raw), 'Invalid chunk size')
        chunks.append((kind, raw[offset:offset+size]))
        offset += size
    require([c[0] for c in chunks] == [0x4e4f534a, 0x004e4942], 'Unexpected GLB chunks')
    return json.loads(chunks[0][1]), chunks[1][1]


def floats(g, binary, index, kind):
    a = g['accessors'][index]
    require(a['type'] == kind and a['componentType'] == 5126, 'Unexpected accessor type')
    require(not a.get('normalized', False) and 'sparse' not in a, 'Unsupported accessor encoding')
    v = g['bufferViews'][a['bufferView']]
    require(v.get('buffer', 0) == 0, 'External buffer')
    dims = {'VEC4': 4, 'SCALAR': 1}[kind]
    stride = v.get('byteStride', dims*4)
    start = v.get('byteOffset', 0)+a.get('byteOffset', 0)
    require(a['count'] > 0 and stride >= dims*4, 'Invalid accessor layout')
    end = start+(a['count']-1)*stride+dims*4
    require(end <= v.get('byteOffset', 0)+v['byteLength'] and end <= len(binary), 'Accessor out of bounds')
    rows = [struct.unpack_from('<'+'f'*dims, binary, start+i*stride) for i in range(a['count'])]
    require(all(math.isfinite(x) for row in rows for x in row), 'Nonfinite accessor')
    return rows


def encode(g, binary):
    j = json.dumps(g, separators=(',', ':'), ensure_ascii=False, allow_nan=False).encode('utf-8')
    j += b' ' * (-len(j) % 4)
    b = bytes(binary) + b'\0' * (-len(binary) % 4)
    return (struct.pack('<III', 0x46546c67, 2, 12+8+len(j)+8+len(b))
            +struct.pack('<II', len(j), 0x4e4f534a)+j
            +struct.pack('<II', len(b), 0x004e4942)+b)


def transform(raw, recipe):
    require(sha(raw) == INPUT_SHA == recipe['input_sha256'], 'Input hash mismatch')
    original, binary = parse(raw)
    require(len(original['buffers']) == 1 and 'uri' not in original['buffers'][0], 'Expected one embedded buffer')
    require(0 <= len(binary)-original['buffers'][0]['byteLength'] <= 3, 'Unexpected BIN padding')
    require(tuple(a['name'] for a in original['animations']) == CLIPS, 'Clip set/order mismatch')
    require(tuple(a['clip'] for a in recipe['channels']) == CLIPS, 'Recipe clip mismatch')
    g = copy.deepcopy(original)
    outbin = bytearray(binary)  # Preserve the entire original BIN, including padding.
    edits = []
    for ai, binding in enumerate(recipe['channels']):
        anim = g['animations'][ai]
        original_anim = original['animations'][ai]
        require([c['bone'] for c in binding['channels']] == ['LeftArm', 'RightArm'], 'Recipe targets mismatch')
        target_channels = [i for i,c in enumerate(original_anim['channels'])
            if c['target']['path'] == 'rotation'
            and original['nodes'][c['target']['node']].get('name') in ('LeftArm', 'RightArm')]
        require(len(target_channels) == 2, 'Expected exactly two upper-arm rotation tracks')
        for bound in binding['channels']:
            matches = [ci for ci in target_channels if original['nodes'][original_anim['channels'][ci]['target']['node']]['name'] == bound['bone']]
            require(len(matches) == 1, 'Ambiguous target channel')
            ci = matches[0]
            channel = original_anim['channels'][ci]
            require(channel['sampler'] == bound['sampler'], 'Sampler binding mismatch')
            sampler = original_anim['samplers'][channel['sampler']]
            require(sampler['output'] == bound['output_accessor'], 'Output binding mismatch')
            require(sampler.get('interpolation', 'LINEAR') == bound['interpolation'] == 'LINEAR', 'Expected exact LINEAR recipe')
            values = floats(original, binary, sampler['output'], 'VEC4')
            times = floats(original, binary, sampler['input'], 'SCALAR')
            require(len(values) == len(times) == bound['output_count'], 'Key count mismatch')
            require(all(times[i][0] < times[i+1][0] for i in range(len(times)-1)), 'Non-increasing key times')
            node = original['nodes'][channel['target']['node']]
            require('matrix' not in node, 'Matrix rest node unsupported')
            rest = unit(node.get('rotation', [0,0,0,1]))
            delta = unit(recipe['bias_xyzw'][bound['bone'].removesuffix('Arm')])
            inv = (-rest[0], -rest[1], -rest[2], rest[3])
            bias = unit(mul(mul(rest, delta), inv))
            for q in values:
                require(abs(sum(x*x for x in q)-1) < 1e-4, 'Input key is not unit length')
            adjusted = [unit(mul(bias, q)) for q in values]
            offset = len(outbin)
            require(offset % 4 == 0, 'Unaligned append')
            packed = b''.join(struct.pack('<4f', *q) for q in adjusted)
            outbin.extend(packed)
            view_index = len(g['bufferViews'])
            g['bufferViews'].append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(packed)})
            # Clone the output metadata, with fresh storage and corrected optional bounds.
            accessor = copy.deepcopy(original['accessors'][sampler['output']])
            accessor.update(bufferView=view_index, byteOffset=0)
            for key, fn in [('min', min), ('max', max)]:
                if key in accessor:
                    accessor[key] = [fn(q[d] for q in adjusted) for d in range(4)]
            output_index = len(g['accessors'])
            g['accessors'].append(accessor)
            # Clone sampler too: another channel may share the original sampler.
            new_sampler = copy.deepcopy(sampler)
            new_sampler['output'] = output_index
            new_sampler_index = len(anim['samplers'])
            anim['samplers'].append(new_sampler)
            anim['channels'][ci]['sampler'] = new_sampler_index
            edits.append({'clip': anim['name'], 'animation_index': ai, 'channel_index': ci,
                'bone': bound['bone'], 'old_sampler': channel['sampler'],
                'new_sampler': new_sampler_index, 'new_accessor': output_index,
                'keys': len(values), 'left_multiplier_xyzw': bias})
    require(len(edits) == 14, 'Unexpected edit count')
    g['buffers'][0]['byteLength'] = len(outbin)
    encoded = encode(g, outbin)
    verified, verified_binary = parse(encoded)
    require(verified_binary[:len(binary)] == binary, 'Original BIN changed')
    # Reversing ONLY the permitted metadata changes must recover the entire JSON.
    restored = copy.deepcopy(verified)
    for edit in edits:
        restored['animations'][edit['animation_index']]['channels'][edit['channel_index']]['sampler'] = edit['old_sampler']
        rows = floats(verified, verified_binary, edit['new_accessor'], 'VEC4')
        require(all(abs(sum(x*x for x in q)-1) < 2e-6 for q in rows), 'Output quaternion norm failure')
    for ai, anim in enumerate(restored['animations']):
        anim['samplers'] = anim['samplers'][:len(original['animations'][ai]['samplers'])]
    restored['accessors'] = restored['accessors'][:len(original['accessors'])]
    restored['bufferViews'] = restored['bufferViews'][:len(original['bufferViews'])]
    restored['buffers'][0]['byteLength'] = original['buffers'][0]['byteLength']
    require(restored == original, 'Unexpected non-target JSON change')
    return encoded, edits, len(binary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply-reviewed-recipe', action='store_true')
    args = parser.parse_args()
    require(args.apply_reviewed_recipe, 'Root review required; no action without explicit apply flag')
    require(not OUTPUT.exists() and not RECEIPT.exists(), 'Private output already exists; refusing overwrite')
    recipe_bytes = RECIPE.read_bytes()
    require(sha(recipe_bytes) == RECIPE_SHA, 'Recipe changed since code review')
    recipe = json.loads(recipe_bytes)
    require((ROOT / recipe['input_model']).resolve() == INPUT.resolve(), 'Recipe input path mismatch')
    config = json.loads((ROOT/'data/config/character_appearance_variants.json').read_text())
    require(config['enabled'] is False, 'Global gate must be OFF')
    require(config['variants']['npc_identity_water_adair_v1']['enabled'] is False, 'Adair gate must be OFF')
    require(config['variants']['npc_identity_water_iona_v1']['enabled'] is False, 'Iona gate must be OFF')
    require('npc_identity_water_orsen_v1' not in config['variants'], 'Orsen must remain outside runtime configuration')
    result, edits, prefix_length = transform(INPUT.read_bytes(), recipe)
    source = Path(__file__).read_text(encoding='utf-8').replace('\r\n', '\n').encode('utf-8')
    receipt = {'status': 'CPU_TRANSFORM_ONLY_NATIVE_REVIEW_PENDING', 'input_sha256': INPUT_SHA,
        'output_sha256': sha(result), 'recipe_sha256': RECIPE_SHA, 'postprocessor_sha256_lf': sha(source),
        'postprocessor': str(Path(__file__).resolve()), 'input': str(INPUT), 'output': str(OUTPUT),
        'composition': recipe['composition'], 'original_bin_prefix_bytes_preserved': prefix_length,
        'non_target_json_and_original_accessors_unchanged': True, 'edits': edits,
        'global_enabled': False, 'candidate_enabled': False}
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT.open('xb') as f:
        f.write(result)
    with RECEIPT.open('x', encoding='utf-8') as f:
        json.dump(receipt, f, indent=2, allow_nan=False)
        f.write('\n')
    print(json.dumps({'output': str(OUTPUT), 'receipt': str(RECEIPT), 'changed_tracks': len(edits),
        'native_review': 'PENDING', 'output_sha256': sha(result)}))


if __name__ == '__main__':
    main()
