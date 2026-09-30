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
    matrix = {"source_commit": source, "route_config_sha256": hashlib.sha256(config_bytes).hexdigest(),
              "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "cases": [],
              "scope": "Computer production-scene render routes. No earned campaign, blinded visual approval, Hall proof or owner Ally result."}
    failed = False
    for biome, preset in cases:
        case_dir = output / f"{biome}-{preset.lower()}"
        home = output / f"home-{biome}-{preset.lower()}"
        home.mkdir()
        env = os.environ.copy()
        # Every process owns an isolated device config/save directory.
        env.update(APPDATA=str(home), XDG_DATA_HOME=str(home), XDG_CONFIG_HOME=str(home))
        renderer = "gl_compatibility" if preset == "Low" else "forward_plus"
        command = [str(godot), "--path", str(ROOT), "--rendering-method", renderer,
                   "--resolution", "1920x1080", "--script", "tools/capture_lookdev_route.gd", "--",
                   f"--biome={biome}", f"--preset={preset}", f"--source-commit={source}",
                   f"--output={case_dir.as_posix()}"]
        started = time.monotonic()
        log_path = output / f"{biome}-{preset.lower()}.log"
        timed_out = False
        with log_path.open("wb") as log:
            process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
            try:
                # Production shell build plus declared timed route, with a small shutdown margin.
                exit_code = process.wait(timeout=900 + config["capture"]["maximum_wall_seconds"] + 60)
            except subprocess.TimeoutExpired:
                timed_out = True
                process.kill()
                exit_code = process.wait()
        raw_log = log_path.read_text(encoding="utf-8", errors="replace")
        errors = [line for line in raw_log.splitlines() if "ERROR:" in line or "SCRIPT ERROR:" in line]
        receipt_path = case_dir / "route.json"
        receipt_error = ""
        try:
            receipt = json.loads(receipt_path.read_text(encoding="utf-8")) if receipt_path.exists() else {}
        except (OSError, ValueError) as exc:
            receipt = {}
            receipt_error = str(exc)
        try:
            samples = [float(row["wall_ms"]) for row in receipt.get("samples", [])]
        except (KeyError, TypeError, ValueError) as exc:
            samples = []
            receipt_error = f"Malformed frame samples: {exc}"
        complete = (exit_code == 0 and not timed_out and not errors and not receipt_error and receipt.get("complete") is True
                    and receipt.get("source_commit") == source
                    and receipt.get("route_config_sha256") == matrix["route_config_sha256"]
                    and len(samples) >= config["capture"]["minimum_timed_frames"]
                    and all(value > 0 for value in samples))
        case = {"biome": biome, "preset": preset, "complete": complete, "exit_code": exit_code,
                "timed_out": timed_out, "native_errors": errors, "command": command,
                "isolated_home": str(home), "elapsed_seconds": time.monotonic() - started,
                "raw_log": str(log_path), "receipt": str(receipt_path), "receipt_error": receipt_error,
                "sample_count": len(samples)}
        if samples:
            case["wall_frame_ms"] = {"mean": sum(samples) / len(samples), "p50": percentile(samples, .5),
                                     "p95": percentile(samples, .95), "p99": percentile(samples, .99),
                                     "maximum": max(samples)}
        matrix["cases"].append(case)
        matrix["complete"] = all(item["complete"] for item in matrix["cases"]) and len(matrix["cases"]) == len(cases)
        (output / "matrix.json").write_text(json.dumps(matrix, indent=2) + "\n", encoding="utf-8")
        print(f"{biome}/{preset}: {'PASS' if complete else 'FAIL'} ({len(samples)} frames, exit {exit_code})", flush=True)
        if not complete:
            failed = True
            # Preserve the first failure and avoid twelve copies of a broken setup.
            break
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(run())
