"""Serial native, pinned-package A/B with an external monitor-only overlay.

Never changes a package or source checkout. Full logs and raw per-frame rows
are retained; no default, owner-device acceptance or pure causal claim.
"""
import argparse
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import re
import statistics
import subprocess
import time

PINS = {'before': '946bb39e55ba4485868b611eb0c15e5eb7c7be0c',
        'after': '1b85fb4d985b7d622e022867055770b2f0de6b18'}
BIOMES = ('meadows', 'water', 'cloudreach', 'stormwood')
MONITORS = ('draw_calls', 'primitives', 'objects_in_frame', 'physics_ms',
            'process_ms', 'video_memory_bytes', 'node_count', 'render_gpu_ms',
            'render_cpu_ms', 'render_setup_cpu_ms')
LOCK = Path('D:/tetherbound/RENDER_LOCK.json')
BUSY = Path('D:/tetherbound/.artifacts/GPU_OWNER_PLAY.json')


def sha(path):
    with path.open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def verify_package(package, label):
    manifest = package / 'PERF_DIAGNOSTIC.json'
    document = json.loads(manifest.read_text())
    assert document['source_commit'] == PINS[label], 'Wrong package pin'
    listed = [item['path'] for item in document['files']]
    assert len(listed) == len(set(listed)), 'Duplicate manifest payload'
    assert listed.count('Tetherbound.exe') == listed.count('Tetherbound.pck') == 1
    for item in document['files']:
        target = (package / item['path']).resolve()
        assert target.is_relative_to(package.resolve()) and sha(target) == item['sha256']
    assert (package / 'Tetherbound.exe').is_file() and (package / 'Tetherbound.pck').is_file()
    return {'source_commit': PINS[label], 'manifest_sha256': sha(manifest),
            'route_config_sha256': document['route_config_sha256'],
            'expected_camera_far_m': document['expected_camera_far_m'],
            'manifest': str(manifest), 'exe_sha256': sha(package / 'Tetherbound.exe'),
            'pck_sha256': sha(package / 'Tetherbound.pck')}


def gpu_profiles(log):
    """Keep profiler blocks printed wholly inside the timed route interval."""
    active = False
    blocks = []
    block = None
    for line in log.splitlines():
        if line.startswith('PERF_ROUTE_BEGIN'):
            active = True
        elif line.startswith('PERF_ROUTE_END'):
            active = False
            if block and block['tasks_ms']:
                blocks.append(block)
            block = None
        elif active:
            header = re.match(r'GPU PROFILE \(total ([\d.eE+-]+)ms\)', line)
            if header:
                if block and block['tasks_ms']:
                    blocks.append(block)
                block = {'total_last_frame_ms': float(header[1]), 'tasks_ms': {}}
            else:
                task = re.match(r'\s*-(.+): ([\d.eE+-]+)ms', line)
                if block is not None and task:
                    block['tasks_ms'][task[1]] = float(task[2])
    # The first block can straddle warmup; retain raw, exclude it from costs.
    names = sorted({name for b in blocks[1:] for name in b['tasks_ms']})
    averages = {name: statistics.mean(b['tasks_ms'].get(name, 0) for b in blocks[1:])
                for name in names}
    return {'raw_blocks': blocks, 'cost_blocks': max(0, len(blocks) - 1),
            'mean_task_ms': averages,
            'top_task': max(averages, key=averages.get) if averages else None,
            'scope': 'Godot --gpu-profile one-second task means; total is the last frame. First timed block excluded because it can include warmup. GPU passes do not identify individual scene meshes.'}


def metrics(rows):
    assert rows and all(math.isfinite(row['wall_ms']) and row['wall_ms'] > 0 for row in rows)
    slow_count = max(1, math.ceil(len(rows) * .01))
    slow = sorted(rows, key=lambda row: row['wall_ms'], reverse=True)[:slow_count]
    wall = [row['wall_ms'] for row in rows]
    return {'frames': len(rows), 'minimum_fps': 1000 / max(wall),
            'average_fps': 1000 / statistics.mean(wall),
            'one_percent_low_fps': 1000 / statistics.mean(row['wall_ms'] for row in slow),
            'slowest_one_percent_frames': slow_count,
            'monitors': {key: {'average': statistics.mean(row[key] for row in rows),
                              'slowest_one_percent_mean': statistics.mean(row[key] for row in slow)}
                         for key in MONITORS}}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--before', type=Path, required=True)
    parser.add_argument('--after', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    assert not args.output.exists(), 'Keep prior evidence; output must be fresh'
    args.output.mkdir(parents=True)
    overlay = Path(__file__).with_name('profile_packaged_route.gd').resolve()
    packages = {'before': args.before.resolve(), 'after': args.after.resolve()}
    summary = {'pins': PINS, 'packages': {k: verify_package(v, k) for k, v in packages.items()},
               'overlay': str(overlay), 'overlay_sha256': sha(overlay), 'cases': [],
               'dependencies': {name: sha(overlay.with_name(name)) for name in
                                ('capture_manifest_writer.gd', 'packaged_engine_profiler.gd')},
               'scope': 'Identical pinned editor-capable engine hosts with --main-pack loading byte-identical pinned release game PCKs and external instrumentation, not shipping release FPS. Standard export templates refuse --script. No source filesystem fallback or Ally acceptance. Pins differ in realm far floors and other integrated runtime changes; this is not a pure isolated far-plane experiment.'}
    env_base = os.environ.copy()
    env_base.pop('PSModulePath', None)
    assert not BUSY.exists(), 'Owner is using the PC'
    live = subprocess.check_output(['powershell', '-NoProfile', '-Command',
            "@(Get-Process -Name valheim,Tetherbound,Godot* -ErrorAction SilentlyContinue).Count"],
            env=env_base, text=True).strip()
    assert live == '0', 'Another game/renderer is live'
    owner = {'held_by': 'codex-PERF-packaged-AB', 'shell_pid': os.getpid(),
             'since_utc': dt.datetime.now(dt.timezone.utc).isoformat()}
    with LOCK.open('x') as file:
        json.dump(owner, file)
    try:
        for biome in BIOMES:
            for label, package in packages.items():
                assert not BUSY.exists(), 'Owner PC marker changed; stop before next case'
                case_root = args.output / label / biome
                case_root.mkdir(parents=True)
                route_out = case_root / 'route'
                profile = case_root / 'profile'
                profile.mkdir()
                env = env_base.copy()
                env.update(APPDATA=str(profile), XDG_DATA_HOME=str(profile), XDG_CONFIG_HOME=str(profile))
                command = [str(package / 'Tetherbound.exe'), '--rendering-method', 'forward_plus',
                           '--path', str(package), '--main-pack', str(package / 'Tetherbound.pck'),
                           '--resolution', '1920x1080', '--gpu-profile', '--debug', '--ignore-error-breaks', '--audio-driver', 'Dummy',
                           '--script', str(overlay), '--', '--biome=' + biome, '--preset=Medium',
                           '--source-commit=' + PINS[label], '--output=' + route_out.as_posix()]
                log = case_root / 'native.log'
                started = time.monotonic()
                with log.open('wb') as file:
                    process = subprocess.Popen(command, cwd=package, env=env, stdout=file, stderr=subprocess.STDOUT)
                    timed_out = False
                    try:
                        owner.update(pid=process.pid, label=label, biome=biome, source_commit=PINS[label])
                        LOCK.write_text(json.dumps(owner))
                        print('PERF_CASE_STARTED ' + label + '/' + biome + ' pid=' + str(process.pid), flush=True)
                        try:
                            code = process.wait(timeout=2100)
                        except subprocess.TimeoutExpired:
                            timed_out = True
                    finally:
                        if process.poll() is None:
                            subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'], stdout=file, stderr=subprocess.STDOUT)
                        code = process.wait()
                text = log.read_text(errors='replace')
                errors = [line[:500] for line in text.splitlines() if 'ERROR:' in line]
                case = {'label': label, 'biome': biome, 'source_commit': PINS[label],
                        'command': command, 'exit_code': code, 'timed_out': timed_out,
                        'elapsed_seconds': time.monotonic() - started, 'errors': errors,
                        'log_sha256': sha(log), 'complete': False}
                if code == 0 and not timed_out and not errors:
                    route = json.loads((route_out / 'route.json').read_text())
                    performance = json.loads((route_out / 'performance.json').read_text())
                    assert route['complete'] and performance['complete'] and not route['failures']
                    assert not performance['failures'] and route['biome'] == performance['biome'] == biome
                    assert route['source_commit'] == PINS[label] == performance['source_commit']
                    assert route['route_config_sha256'] == summary['packages'][label]['route_config_sha256']
                    assert route['preset'] == performance['preset'] == 'Medium'
                    assert route['resolution'] == performance['resolution'] == [1920, 1080]
                    assert route['renderer'] == performance['renderer'] == 'forward_plus'
                    assert performance['max_fps'] == performance['vsync_mode'] == 0
                    assert performance['render_loop_enabled'] and performance['time_scale'] == 1
                    assert performance['physics_ticks_per_second'] == 60
                    assert performance['instrumentation_sha256'] == summary['overlay_sha256']
                    assert performance['writer_sha256'] == summary['dependencies']['capture_manifest_writer.gd']
                    assert performance['engine_profiler_sha256'] == summary['dependencies']['packaged_engine_profiler.gd']
                    assert len(route['samples']) == len(performance['rows']) >= 120
                    assert route['waypoints_reached'] == len(route['route']['waypoints'])
                    for ordinary, instrumented in zip(route['samples'], performance['rows']):
                        assert ordinary['wall_ms'] == instrumented['wall_ms']
                        assert all(math.isfinite(instrumented[key]) and instrumented[key] >= 0 for key in MONITORS)
                    assert route['camera']['far'] == performance['camera_far_m'] == summary['packages'][label]['expected_camera_far_m'][biome]
                    assert performance['engine_iterations'], 'Engine profiler callbacks missing'
                    recorded_frames = {row['process_frame'] for row in performance['rows']}
                    previous_engine_frame = -1
                    for iteration in performance['engine_iterations']:
                        assert iteration['process_frame'] in recorded_frames and iteration['process_frame'] > previous_engine_frame
                        previous_engine_frame = iteration['process_frame']
                        assert iteration['executed_physics_steps'] >= 0 and iteration['executed_physics_steps'] == int(iteration['executed_physics_steps'])
                        assert all(math.isfinite(iteration[key]) and iteration[key] >= 0 for key in
                                   ('engine_iteration_ms', 'engine_process_ms', 'physics_max_step_ms', 'physics_simulation_delta_seconds'))
                    profile = gpu_profiles(text)
                    assert profile['cost_blocks'] > 0 and profile['top_task'], 'Required GPU profiler cost blocks missing'
                    assert performance['debug_build'], 'Diagnostic template must identify debug mode'
                    assert any(row['render_gpu_ms'] > 0 for row in performance['rows']), 'GPU timing unavailable'
                    case.update(complete=True, camera_far_m=route['camera']['far'], adapter=route['adapter'],
                                metrics=metrics(performance['rows']), gpu_profile=profile,
                                route_sha256=sha(route_out / 'route.json'), performance_sha256=sha(route_out / 'performance.json'))
                (case_root / 'receipt.json').write_text(json.dumps(case, indent=2) + '\n')
                summary['cases'].append(case)
                (args.output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
                print(json.dumps({k: v for k, v in case.items() if k not in ('command', 'gpu_profile')}), flush=True)
                if not case['complete']:
                    print(text[-3500:], flush=True)
                    raise SystemExit(1)
        summary['complete'] = len(summary['cases']) == 8 and all(case['complete'] for case in summary['cases'])
        (args.output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
        print('PERF_AB_COMPLETE ' + str(args.output), flush=True)
    finally:
        if LOCK.exists() and json.loads(LOCK.read_text()).get('shell_pid') == os.getpid():
            LOCK.unlink()


if __name__ == '__main__':
    main()
