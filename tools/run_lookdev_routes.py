"""Run F26 computer routes serially, preserving raw native logs and frame data.

The coordinator must grant the Godot writer slot before invoking this tool.
It never imports, exports, retries a failed run, or edits acceptance status.
Use --biome/--preset for one initial route before running the remaining matrix.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import time


ROOT = Path(__file__).resolve().parents[1]


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    index = (len(ordered) - 1) * fraction
    lower = int(index)
    upper = min(lower + 1, len(ordered) - 1)
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (index - lower)


def run() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--biome", choices=["meadows", "water", "cloudreach", "stormwood"], action="append")
    parser.add_argument("--preset", choices=["Low", "Medium", "High"], action="append")
    parser.add_argument("--output", type=Path, required=True, help="New evidence directory, never overwritten")
    args = parser.parse_args()
    if git("status", "--porcelain", "--untracked-files=all"):
        parser.error("Commit the source first; captures require a clean checkout and exact source SHA.")
    godot = args.godot.resolve(strict=True)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    source = git("rev-parse", "HEAD")
    config_bytes = (ROOT / "data/config/lookdev_routes.json").read_bytes()
    config = json.loads(config_bytes)
    cases = [(biome, preset) for biome in (args.biome or list(config["routes"]))
             for preset in (args.preset or ["Low", "Medium", "High"])]
    if len(cases) != len(set(cases)):
        parser.error("Request each biome/preset once.")
    groups: dict[tuple[str, str], list[str]] = {}
    for biome, preset in cases:
        renderer = "gl_compatibility" if preset == "Low" else "forward_plus"
        groups.setdefault((biome, renderer), []).append(preset)
    matrix = {"source_commit": source, "route_config_sha256": hashlib.sha256(config_bytes).hexdigest(),
              "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "cases": [],
              "requested_cases": [{"biome": biome, "preset": preset} for biome, preset in cases],
              "scope": "Computer production-scene render routes. No earned campaign, blinded visual approval, Hall proof or owner Ally result."}
    failed = False
    for (biome, renderer), presets in groups.items():
        # Medium/High share a renderer, scene mount and warm process. Each
        # resets its declared route pose, applies real prefs, warms up again,
        # and writes independent raw frames/screenshots/receipt.
        group_name = f"{biome}-{'-'.join(presets).lower()}"
        group_dir = output / group_name
        home = output / f"home-{group_name}"
        home.mkdir()
        env = os.environ.copy()
        # Every process owns an isolated device config/save directory.
        env.update(APPDATA=str(home), XDG_DATA_HOME=str(home), XDG_CONFIG_HOME=str(home))
        command = [str(godot), "--path", str(ROOT), "--rendering-method", renderer,
                   "--resolution", "1920x1080", "--script", "tools/capture_lookdev_route.gd", "--",
                   f"--biome={biome}", f"--preset={','.join(presets)}", f"--source-commit={source}",
                   f"--output={group_dir.as_posix()}"]
        started = time.monotonic()
        log_path = output / f"{group_name}.log"
        timed_out = False
        with log_path.open("wb") as log:
            process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
            try:
                # Production shell build plus declared timed route, with a small shutdown margin.
                exit_code = process.wait(timeout=900 + len(presets) * config["capture"]["maximum_wall_seconds"] + 60)
            except subprocess.TimeoutExpired:
                timed_out = True
                # The Windows console executable delegates to a GUI child.
                # End its whole owned process tree before releasing the writer
                # slot; killing only the console leaves that renderer running.
                if os.name == "nt":
                    subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                                   stdout=log, stderr=subprocess.STDOUT, check=False)
                else:
                    process.kill()
                exit_code = process.wait()
        raw_log = log_path.read_text(encoding="utf-8", errors="replace")
        errors = [line for line in raw_log.splitlines() if "ERROR:" in line or "SCRIPT ERROR:" in line]
        for ordinal, preset in enumerate(presets):
            case_dir = group_dir / preset.lower() if len(presets) > 1 else group_dir
            receipt_path = case_dir / "route.json"
            receipt_error = ""
            try:
                receipt = json.loads(receipt_path.read_text(encoding="utf-8")) if receipt_path.exists() else {}
                if not isinstance(receipt, dict):
                    raise ValueError("Receipt must be a JSON object")
            except (OSError, ValueError) as exc:
                receipt = {}
                receipt_error = str(exc)
            try:
                samples = [float(row["wall_ms"]) for row in receipt.get("samples", [])]
                if any(not math.isfinite(value) or value <= 0 for value in samples):
                    raise ValueError("Frame samples must be finite positive milliseconds")
            except (KeyError, TypeError, ValueError) as exc:
                samples = []
                receipt_error = f"Malformed frame samples: {exc}"
            complete = (exit_code == 0 and not timed_out and not errors and not receipt_error and receipt.get("complete") is True
                        and receipt.get("source_commit") == source and receipt.get("preset") == preset
                        and receipt.get("route_config_sha256") == matrix["route_config_sha256"]
                        and len(samples) >= config["capture"]["minimum_timed_frames"])
            case = {"biome": biome, "preset": preset, "complete": complete, "exit_code": exit_code,
                    "timed_out": timed_out, "native_errors": errors, "command": command,
                    "isolated_home": str(home), "elapsed_seconds": time.monotonic() - started,
                    "process_presets": presets, "case_index": ordinal,
                    "scene_reused_across_presets": len(presets) > 1,
                    "raw_log": str(log_path), "receipt": str(receipt_path), "receipt_error": receipt_error,
                    "sample_count": len(samples)}
            if samples:
                case["wall_frame_ms"] = {"mean": sum(samples) / len(samples), "p50": percentile(samples, .5),
                                         "p95": percentile(samples, .95), "p99": percentile(samples, .99),
                                         "maximum": max(samples)}
            matrix["cases"].append(case)
            matrix["complete"] = all(item["complete"] for item in matrix["cases"]) and len(matrix["cases"]) == len(cases)
            matrix["all_twelve_route_cases_complete"] = matrix["complete"] and set(cases) == {
                (biome_id, quality) for biome_id in config["routes"] for quality in ("Low", "Medium", "High")}
            (output / "matrix.json").write_text(json.dumps(matrix, indent=2) + "\n", encoding="utf-8")
            print(f"{biome}/{preset}: {'PASS' if complete else 'FAIL'} ({len(samples)} frames, exit {exit_code})", flush=True)
            if not complete:
                failed = True
                # Preserve the first failure and avoid repeated broken setups.
                break
        if failed:
            break
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(run())
