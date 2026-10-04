"""Encode retained native F17 samples with their actual variable timing."""
import argparse
import hashlib
import json
import pathlib
import shutil
import subprocess


def package(output: pathlib.Path, ffmpeg: str) -> list[dict]:
    manifest_file = output / "manifest.json"
    manifest_bytes = manifest_file.read_bytes()
    manifest = json.loads(manifest_bytes)
    if not manifest["complete"] or manifest["resolution"] != [1920, 1080]:
        raise ValueError("Require a complete native 1920x1080 witness")
    jobs = []
    receipt_path = output / "motion-receipt.json"
    if receipt_path.exists():
        raise FileExistsError(receipt_path)
    for preset in manifest["presets"]:
        if preset not in {"Low", "Medium", "High"}:
            raise ValueError("Unknown preset")
        views = [v for v in manifest["views"] if v.get("motion_sample") and v["preset"] == preset]
        if len(views) < 2:
            raise ValueError("Missing motion samples for " + preset)
        for view in views:
            name = view["image"]
            if pathlib.Path(name).name != name or "'" in name or not (output / name).is_file():
                raise ValueError("Invalid or absent native image " + name)
        gaps = [(b["elapsed_ms"] - a["elapsed_ms"]) / 1000 for a, b in zip(views, views[1:])]
        interval = (views[-1]["elapsed_ms"] - views[0]["elapsed_ms"]) / 1000
        if min(gaps) <= 0 or interval < 30:
            raise ValueError("Require increasing timestamps spanning at least thirty native seconds")
        concat = output / ("motion-" + preset.lower() + ".ffconcat")
        video = output / ("motion-" + preset.lower() + ".mp4")
        if concat.exists() or video.exists():
            raise FileExistsError("Refuse overwriting prior motion output")
        jobs.append((preset, views, gaps, interval, concat, video))
    receipt = []
    for preset, views, gaps, interval, concat, video in jobs:
        lines = ["ffconcat version 1.0"]
        for view, duration in zip(views, gaps + [0.1]):
            lines.extend(["file '" + view["image"] + "'", "duration " + str(duration)])
        lines.append("file '" + views[-1]["image"] + "'")
        concat.write_text("\n".join(lines) + "\n", encoding="utf-8")
        command = [ffmpeg, "-v", "error", "-n", "-safe", "0", "-i", str(concat),
                   "-fps_mode", "vfr", "-c:v", "libx264", "-crf", "16", "-pix_fmt", "yuv420p", str(video)]
        subprocess.run(command, check=True)
        receipt.append({"preset": preset, "video": video.name, "samples": len(views),
                        "source": manifest["source"], "manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
                        "native_interval_seconds": interval, "max_sample_gap_seconds": max(gaps),
                        "resolution": [1920, 1080], "command": command,
                        "encoding": "JPEG95 native samples to H264 CRF16; original samples retained",
                        "timing": "Actual variable sample durations; no interpolation or resizing"})
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return receipt


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=pathlib.Path)
    parser.add_argument("--ffmpeg", default=shutil.which("ffmpeg"))
    args = parser.parse_args()
    if not args.ffmpeg:
        parser.error("Supply an existing ffmpeg executable with --ffmpeg")
    print(json.dumps(package(args.output.resolve(), args.ffmpeg)))
