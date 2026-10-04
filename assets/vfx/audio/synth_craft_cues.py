"""Render original layered mono cue candidates outside the game export path.

This never changes audio.json, imports or the installed prototype cue bank.
The output is an inactive 48 kHz/24-bit source master bank with provenance.
Inspect/listen and exercise the accepted host path before mapping any asset.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import random
import struct
import subprocess
import wave


def lowpass_coefficient(hz: float, rate: int) -> float:
    return 1.0 - math.exp(-math.tau * hz / rate)


def modal(t: float, modes: list[float], decay: float) -> float:
    if t < 0.0:
        return 0.0
    return sum(math.sin(math.tau * hz * t) * math.exp(-t / (decay / (1.0 + index * 0.3)))
               / (1.0 + index * 0.8) for index, hz in enumerate(modes))


def raw_cue(family: str, recipe: dict, role: str, duration: float, rate: int) -> list[float]:
    # Base/mastery share the same field texture; rank adds detail within a
    # separately gain-matched one-shot rather than opening another voice.
    base_role = role.removesuffix("_mastery")
    seed = int(hashlib.sha256((family + base_role).encode()).hexdigest()[:16], 16)
    rng = random.Random(seed)
    crackles = [(rng.uniform(0.025, duration * 0.85), rng.uniform(0.12, 0.3))
                for _ in range(int(recipe.get("crackle_count", 0)))]
    modes = recipe["modes_hz"]
    decay = recipe["body_decay_seconds"]
    low = lowpass_coefficient(recipe["grit_low_hz"], rate)
    high = lowpass_coefficient(recipe["grit_high_hz"], rate)
    travel_filter = lowpass_coefficient(recipe["travel_high_hz"], rate)
    low_state = high_state = air_state = 0.0
    samples = []
    for index in range(round(rate * duration)):
        t = index / rate
        noise = rng.uniform(-1.0, 1.0)
        low_state += low * (noise - low_state)
        high_state += high * (noise - high_state)
        air_state += travel_filter * (noise - air_state)
        grit = high_state - low_state
        onset_env = sum(math.exp(-(t - onset) / (decay * 0.45))
                        if t >= onset else 0.0 for onset in recipe["onsets_seconds"])
        resonance = sum(modal(t - onset, modes, decay) / (1.0 + number * 0.35)
                        for number, onset in enumerate(recipe["onsets_seconds"]))
        kind = recipe["kind"]
        if kind == "gravel":
            # Several short irregular grains, with distinct stony resonances.
            transient = grit * onset_env * 1.7 + resonance * 0.28
        elif kind == "boulder":
            # One lower body thud plus a short fracture/grit layer.
            transient = resonance * 0.8 + grit * onset_env * 0.62
        elif kind == "combustion":
            crackle = sum(strength * math.exp(-(t - onset) / 0.007)
                          if t >= onset else 0.0 for onset, strength in crackles)
            transient = resonance * 0.45 + air_state * math.exp(-t / decay) * 1.4 + grit * crackle
        else:
            # Short crackle trains and a lower body, rather than a pitched beep.
            discharge = 0.55 + 0.45 * abs(math.sin(math.tau * 43.0 * t))
            transient = grit * onset_env * discharge * 1.8 + resonance * 0.32
        if base_role == "travel":
            value = air_state * math.sin(math.pi * t / duration) ** 1.1
        elif base_role == "launch_travel":
            value = transient * 0.75 + air_state * math.sin(math.pi * t / duration) ** 1.1 * 0.6
        elif base_role == "impact":
            value = transient
        else:
            value = transient * 0.72 + air_state * math.sin(math.pi * t / duration) * 0.45
        if role.endswith("_mastery"):
            value += modal(t, [recipe["mastery_mode_hz"], recipe["mastery_mode_hz"] * 1.37], decay * 0.75) * 0.14
        # Three-millisecond attack and clean twenty-millisecond tail handles.
        value *= min(1.0, t / 0.003) * min(1.0, max(0.0, duration - t) / 0.02)
        samples.append(value)
    return samples


def center(samples: list[float]) -> list[float]:
    # Remove the measured DC component while retaining zero outer handles.
    weights = [math.sin(math.pi * i / (len(samples) - 1)) ** 2 for i in range(len(samples))]
    offset = sum(samples) / sum(weights)
    return [sample - offset * weight for sample, weight in zip(samples, weights)]


def rms(samples: list[float]) -> float:
    return math.sqrt(sum(sample * sample for sample in samples) / len(samples))


def write_master(path: Path, samples: list[float], rate: int) -> None:
    frames = bytearray()
    for sample in samples:
        value = round(sample * 8388607)
        frames.extend(struct.pack("<i", value)[:3])
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(3)
        output.setframerate(rate)
        output.writeframes(frames)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path, help="Fresh folder outside the game checkout")
    parser.add_argument("--families", nargs="*", help="Named recipe subset; default all four")
    args = parser.parse_args()
    folder = Path(__file__).resolve().parent
    repo = folder.parents[2]
    output = args.out.resolve()
    if output == repo or repo in output.parents:
        parser.error("Source masters must stay outside the game checkout/export path")
    if output.exists():
        parser.error("Use a fresh output folder; previous evidence and masters stay intact")
    recipes_path = folder / "craft_recipes.json"
    recipes = json.loads(recipes_path.read_text(encoding="utf-8"))
    names = args.families or list(recipes["families"])
    if len(names) != len(set(names)) or any(name not in recipes["families"] for name in names):
        parser.error("Choose each known family at most once")
    if recipes["sample_rate"] != 48000 or recipes["sample_width_bytes"] != 3:
        parser.error("Source-master recipes require 48 kHz/24-bit PCM")
    source = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    ceiling = 10.0 ** (recipes["peak_ceiling_dbfs"] / 20.0)
    output.mkdir(parents=True, exist_ok=False)
    records = []
    for name in names:
        pending = {}
        for role, spec in recipes["roles"].items():
            samples = center(raw_cue(name, recipes["families"][name], role, spec["seconds"], 48000))
            gain = spec["rms"] / max(rms(samples), 1e-12)
            pending[role] = [sample * gain for sample in samples]
        # Base/mastery share one scale, preserving matched RMS and preventing
        # an added mastery layer from becoming a gain upgrade.
        for role in list(pending):
            if role.endswith("_mastery"):
                continue
            pair = [role] + ([role + "_mastery"] if role + "_mastery" in pending else [])
            peak = max(abs(sample) for key in pair for sample in pending[key])
            scale = min(1.0, ceiling / max(peak, 1e-12))
            for key in pair:
                pending[key] = [sample * scale for sample in pending[key]]
        for role, samples in pending.items():
            path = output / (name + "_" + role + ".wav")
            write_master(path, samples, 48000)
            records.append({"family": name, "role": role, "path": str(path),
                            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                            "rate": 48000, "width_bytes": 3, "channels": 1,
                            "seconds": len(samples) / 48000,
                            "peak": max(map(abs, samples)), "rms": rms(samples),
                            "dc": sum(samples) / len(samples), "mapped": False})
    manifest = {"scope": "Original inactive layered sound candidates; no audible/native/gameplay acceptance",
                "source_commit": source, "generator": "assets/vfx/audio/synth_craft_cues.py",
                "recipe_sha256": hashlib.sha256(recipes_path.read_bytes()).hexdigest(),
                "source": "Original deterministic synthesis; no third-party samples or purchases",
                "active_cue_bank_unchanged": True, "masters_outside_export": True,
                "files": records,
                "limits": ["Peak is sample peak, not oversampled true peak or LUFS/game-mix proof",
                           "No listener judgment, game/device playback, voice-steal or fatigue proof",
                           "Do not remap cues before listening/native receipt and independent review"]}
    (output / "provenance.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"files": len(records), "source_commit": source, "output": str(output),
                      "mapped": False, "active_cue_bank_unchanged": True}))


if __name__ == "__main__":
    main()
