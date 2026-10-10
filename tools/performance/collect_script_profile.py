"""Capture Godot 4.7 built-in script SELF times over the fixed F26 route.

No engine import/export is performed. ROOT must serialize this rendered run.
This is DEBUG engine attribution, not a release FPS acceptance measurement.
"""
import argparse
import collections
import hashlib
import json
import math
import pathlib
import socket
import struct
import subprocess
import time


def encode(value):
    if value is None:
        return struct.pack('<I', 0)
    if isinstance(value, bool):
        return struct.pack('<II', 1, value)
    if isinstance(value, int):
        return struct.pack('<Iq', 2 | 65536, value)
    if isinstance(value, float):
        return struct.pack('<Id', 3 | 65536, value)
    if isinstance(value, str):
        raw = value.encode('utf-8')
        return struct.pack('<II', 4, len(raw)) + raw + b'\0' * (-len(raw) % 4)
    if isinstance(value, list):
        return struct.pack('<II', 28, len(value)) + b''.join(map(encode, value))
    raise ValueError('Unsupported outgoing Variant')


def decode(data, offset=0):
    def take(fmt):
        nonlocal offset
        size = struct.calcsize(fmt)
        val = struct.unpack_from(fmt, data, offset)
        offset += size
        return val[0] if len(val) == 1 else val
    header = take('<I')
    kind = header & 65535
    wide = bool(header & 65536)
    if kind == 0:
        return None, offset
    if kind == 1:
        return bool(take('<I')), offset
    if kind == 2:
        return take('<q' if wide else '<i'), offset
    if kind == 3:
        return take('<d' if wide else '<f'), offset
    if kind in (4, 21, 22):  # String, StringName, NodePath (not needed by profiler).
        if kind == 22:
            raise ValueError('NodePath is outside profiler protocol')
        size = take('<I')
        value = data[offset:offset + size].decode('utf-8')
        offset += size + (-size % 4)
        return value, offset
    if kind == 28:
        if header & ~65535:
            raise ValueError('Typed array is outside profiler protocol')
        size = take('<I') & 0x7fffffff
        value = []
        for _ in range(size):
            item, offset = decode(data, offset)
            value.append(item)
        return value, offset
    raise ValueError(f'Variant type {kind} is outside profiler protocol')


def read_exact(conn, length):
    chunks = bytearray()
    while len(chunks) < length:
        part = conn.recv(length - len(chunks))
        if not part:
            raise EOFError
        chunks.extend(part)
    return bytes(chunks)


def send(conn, name, payload):
    raw = encode([name, 1, payload])  # Thread::MAIN_ID = 1 in Godot 4.7.
    conn.sendall(struct.pack('<I', len(raw)) + raw)


def is_warning_packet(payload):
    # Godot 4.7 DebuggerMarshalls::OutputError::serialize/deserialize:
    # hr,min,sec,msec,file,func,line,error,description,warning,stack_size,...
    # Malformed/unknown messages fail closed as actual errors.
    return (isinstance(payload, list) and len(payload) >= 11
            and isinstance(payload[9], bool) and payload[9] is True
            and type(payload[10]) is int and payload[10] >= 0
            and payload[10] % 3 == 0 and len(payload) == 11 + payload[10])


def frame_record(payload):
    if len(payload) < 8:
        raise ValueError('Short profiler frame')
    index = 7
    for _ in range(payload[6]):
        index += 2 + payload[index + 1]
    count = payload[index]
    index += 1
    if count % 5 or index + count != len(payload):
        raise ValueError('Malformed profiler function list')
    functions = [payload[i:i + 5] for i in range(index, index + count, 5)]
    return {'frame': payload[0], 'frame_ms': payload[1] * 1000,
            'process_ms': payload[2] * 1000, 'physics_ms': payload[3] * 1000,
            'functions': functions}


def is_frame_callback(signature):
    # Inner classes are reported as ClassName._physics_process, e.g. CliffWild.
    return signature.rsplit('::', 1)[-1].rsplit('.', 1)[-1] in ('_process', '_physics_process')


def native_symbol(row):
    # Godot _profile_native_call uses path::0::NativeClass.method signatures.
    # Native row self/total/internal are all the same measured call time.
    parts = row['signature'].split('::')
    if (len(parts) != 3 or parts[1] != '0' or row['internal_ms_total'] <= 0
            or not math.isclose(row['self_ms_total'], row['inclusive_ms_total'], rel_tol=1e-9, abs_tol=1e-9)
            or not math.isclose(row['internal_ms_total'], row['inclusive_ms_total'], rel_tol=1e-9, abs_tol=1e-9)):
        return None
    return parts[2]


def summarize_native_calls(rows, frame_count):
    # Godot collates native symbols across script callers. The surviving path
    # is bookkeeping, NOT caller ownership. Aggregate by NativeClass.method.
    result = {}
    for row in rows:
        symbol = native_symbol(row)
        if symbol is None:
            continue
        item = result.setdefault(symbol, {'symbol': symbol, 'calls': 0,
            'measured_native_ms_total': 0.0, 'retained_signatures': []})
        item['calls'] += row['calls']
        item['measured_native_ms_total'] += row['inclusive_ms_total']
        item['retained_signatures'].append(row['signature'])
    for item in result.values():
        item['measured_native_ms_per_process_frame'] = item['measured_native_ms_total'] / max(1, frame_count)
    return sorted(result.values(), key=lambda item: item['measured_native_ms_total'], reverse=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine', required=True)
    parser.add_argument('--pack', required=True)
    parser.add_argument('--source-commit', required=True)
    parser.add_argument('--biome', choices=['meadows', 'water'], required=True)
    parser.add_argument('--preset', choices=['Low', 'Medium', 'High'], default='Medium')
    parser.add_argument('--output', type=pathlib.Path, required=True)
    parser.add_argument('--timeout-seconds', type=int, default=1100)
    parser.add_argument('--max-functions', type=int, default=4096)
    parser.add_argument('--profile-native-calls', action='store_true', help='Instrument native calls in the DEBUG engine; adds profiler overhead and changes raw SELF accounting')
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists():
        parser.error('Output already exists; keep earlier evidence')
    output.mkdir(parents=True)
    wrapper = pathlib.Path(__file__).with_name('profiled_route.gd').resolve()
    pack = pathlib.Path(args.pack).resolve()
    engine = pathlib.Path(args.engine).resolve()
    route_output = output / 'route'
    renderer = 'gl_compatibility' if args.preset == 'Low' else 'forward_plus'
    signatures, frames, errors, warnings = {}, [], [], []
    start, end = None, None
    ignored = collections.Counter()
    saturated = 0
    deadline = time.monotonic() + args.timeout_seconds
    with socket.socket() as server, (output / 'engine.log').open('wb') as log:
        server.bind(('127.0.0.1', 0))
        server.listen(1)
        server.settimeout(60)
        port = server.getsockname()[1]
        command = [str(engine), '--path', str(pack.parent), '--main-pack', str(pack),
                   '--script', str(wrapper), '--remote-debug', f'tcp://127.0.0.1:{port}',
                   '--ignore-error-breaks', '--rendering-method', renderer,
                   '--resolution', '1920x1080', '--', '--quiet-baseline',
                   f'--biome={args.biome}', f'--preset={args.preset}',
                   f'--source-commit={args.source_commit}', f'--output={route_output.as_posix()}']
        runtime = engine.with_name(engine.name.replace('_console.exe', '.exe'))
        if not runtime.is_file():
            runtime = engine
        metadata = {'command': command, 'engine_sha256': hashlib.file_digest(engine.open('rb'), 'sha256').hexdigest(),
                    'engine_runtime_path': str(runtime),
                    'engine_runtime_sha256': hashlib.file_digest(runtime.open('rb'), 'sha256').hexdigest(),
                    'pack_sha256': hashlib.file_digest(pack.open('rb'), 'sha256').hexdigest(),
                    'max_functions': args.max_functions,
                    'profile_native_calls': args.profile_native_calls,
                    'scope': 'DEBUG engine built-in script attribution; release QUIET remains performance authority.'}
        (output / 'launch.json').write_text(json.dumps(metadata, indent=2) + '\n')
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, cwd=pack.parent)
        try:
            conn, _ = server.accept()
            with conn:
                conn.settimeout(20)
                send(conn, 'profiler:servers', [True, [args.max_functions, args.profile_native_calls]])
                while time.monotonic() < deadline:
                    try:
                        size = struct.unpack('<I', read_exact(conn, 4))[0]
                        if size > 8 * 1024 * 1024:
                            raise ValueError('Oversized debugger packet')
                        raw = read_exact(conn, size)
                        try:
                            message, used = decode(raw)
                            if used != size or not isinstance(message, list) or len(message) != 3:
                                raise ValueError('Malformed debugger message')
                        except (ValueError, struct.error, UnicodeError) as exc:
                            ignored[str(exc)] += 1
                            continue
                        name, thread, payload = message
                        if name == 'servers:function_signature':
                            signatures[payload[1]] = payload[0]
                        elif name == 'owner_profile:start':
                            start = payload
                        elif name == 'owner_profile:end':
                            end = payload
                        elif name == 'servers:profile_frame' and start is not None and end is None:
                            record = frame_record(payload)
                            saturated += len(record['functions']) >= args.max_functions
                            frames.append(record)
                        elif name == 'error':
                            (warnings if is_warning_packet(payload) else errors).append(payload)
                    except EOFError:
                        break
                    except socket.timeout:
                        if process.poll() is not None:
                            break
                else:
                    raise TimeoutError('Fixed route/profiler exceeded time budget')
            process.wait(timeout=30)
        except Exception as exc:
            errors.append({'collector_error': str(exc)})
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=30)
    # Trim both boundary frames: profiling payload describes the previous
    # completed script frame; this avoids attributing warmup or PNG capture.
    # Native extension initialization can fail before the debugger connects.
    raw_engine_errors = [line for line in (output / 'engine.log').read_text(errors='replace').splitlines()
                         if line.startswith(('ERROR:', 'SCRIPT ERROR:'))]
    selected = [f for f in frames if start and end and start[0] < f['frame'] < end[1]]
    totals = collections.defaultdict(lambda: [0, 0.0, 0.0, 0.0, 0.0])
    with (output / 'frames.jsonl').open('w') as raw:
        for frame in selected:
            raw.write(json.dumps(frame, separators=(',', ':')) + '\n')
            for sig, calls, own, total, internal in frame['functions']:
                row = totals[sig]
                row[0] += calls
                row[1] += own * 1000
                row[2] += total * 1000
                row[3] += internal * 1000
                row[4] = max(row[4], own * 1000)
    rows = [{'signature': signatures.get(sig, f'UNRESOLVED:{sig}'), 'calls': values[0],
             'self_ms_total': values[1], 'self_ms_per_process_frame': values[1] / max(1, len(selected)),
             'inclusive_ms_total': values[2], 'internal_ms_total': values[3],
             'self_ms_peak_process_frame': values[4]} for sig, values in totals.items()]
    rows.sort(key=lambda row: row['self_ms_total'], reverse=True)
    native_calls = summarize_native_calls(rows, len(selected)) if args.profile_native_calls else []
    callbacks = [row for row in rows if is_frame_callback(row['signature']) and native_symbol(row) is None]
    gaps = sum(b['frame'] != a['frame'] + 1 for a, b in zip(selected, selected[1:]))
    success = bool(start and start[1] and end and end[2] and selected and callbacks
                   and not saturated and not gaps and not errors and not raw_engine_errors and process.returncode == 0
                   and (not args.profile_native_calls or native_calls))
    receipt = {'complete': success, **metadata, 'biome': args.biome, 'preset': args.preset,
               'source_commit': args.source_commit, 'start': start, 'end': end,
               'profile_frames': len(selected), 'frame_gaps': gaps, 'saturated_frames': saturated,
               'ignored_non_profile_packets': dict(ignored), 'engine_exit_code': process.returncode,
               'engine_errors': errors, 'engine_warnings': warnings,
               'engine_error_count': len(errors), 'engine_warning_count': len(warnings),
               'raw_engine_error_lines': raw_engine_errors,
               'warning_classification': 'Godot 4.7 OutputError payload[9] boolean warning; raw packets retained; malformed packets remain errors',
               'top_ten_callbacks': callbacks[:10], 'all_functions': rows,
               'function_signatures': signatures,
               'top_ten_native_calls': native_calls[:10], 'all_native_calls': native_calls,
               'definitions': {'self': 'Raw Godot4.7 script function self_time. Ordinary script calls are subtracted; inherited super calls are not subtracted by OPCODE_CALL_SELF_BASE. Native work may be inside self when native call profiling is off. Inheritance chain rows overlap and must not be summed.',
                               'native_calls': 'With native profiling ON, instrumented native call time is subtracted from the direct script caller SELF. Inherited super calls remain unsubtracted; raw inheritance-chain SELF rows still overlap. Native time aggregates by NativeClass.method across script callers; retained path does not identify the caller. Not every native/property/engine task is instrumented. Debug profiler overhead is not release performance.',
                               'internal': 'Raw Godot internal_time is retained for auditing; native collation changes its per-script attribution, so do not use it as a per-caller native budget or add it to SELF/native totals.',
                               'per_frame': 'Total callback self milliseconds divided by captured process frames; physics calls are not normalized per physics tick.',
                               'boundaries': 'Only process frame numbers strictly inside fixed route start/end; both boundary frames excluded.'}}
    (output / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps({'complete': success, 'frames': len(selected), 'top_ten_callbacks': callbacks[:10],
                      'profile_native_calls': args.profile_native_calls, 'top_ten_native_calls': native_calls[:10],
                      'receipt': str(output / 'receipt.json')}, indent=2))
    return 0 if success else 1


if __name__ == '__main__':
    raise SystemExit(main())
