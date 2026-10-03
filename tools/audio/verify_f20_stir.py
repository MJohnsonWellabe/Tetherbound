"""Check an untouched result-window recording against the production fifth hum.

This verifies mixed PCM output, not speaker playback or subjective sound quality.
Only gain and phase are fitted; frequency, duration and envelope come from config.
"""
import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import statistics
import sys
import wave


def verify(wav_path, config_path):
    raw = wav_path.read_bytes()
    config_bytes = config_path.read_bytes()
    cue = json.loads(config_bytes)["fifth_stir"]
    hz = float(cue["hum_hz"])
    duration = float(cue["glow_seconds"])
    if not (math.isfinite(hz) and hz > 0 and math.isfinite(duration) and 0 < duration < 30):
        raise ValueError("invalid production cue frequency or duration")
    with wave.open(str(wav_path)) as clip:
        channels, width, rate, frames = (clip.getnchannels(), clip.getsampwidth(),
                                       clip.getframerate(), clip.getnframes())
        if width != 2 or channels not in (1, 2) or clip.getcomptype() != "NONE":
            raise ValueError("recording must contain mono/stereo signed 16-bit PCM")
        if hz >= rate / 2 or not duration + 0.25 <= frames / rate <= 120:
            raise ValueError("recording needs the complete cue and a silence tail")
        pcm = array("h", clip.readframes(frames))
    if sys.byteorder != "little":
        pcm.byteswap()
    if len(pcm) != frames * channels:
        raise ValueError("truncated PCM frame data")
    tracks = [pcm[channel::channels] for channel in range(channels)]
    peaks = [max(map(abs, track), default=0) for track in tracks]
    clipping = sum(abs(sample) >= 32767 for sample in pcm)
    # Two LSBs reject quantisation chatter when locating the half-sine envelope.
    active = [index for index in range(frames)
              if any(abs(track[index]) > 2 for track in tracks)]
    if not active:
        raise ValueError("mixed result window is silent")
    first, last = active[0], active[-1]
    active_duration = (last - first + 1) / rate
    # Quantisation trims both envelope ends. Their midpoint locates the cue;
    # its length remains the configured value, never a freely fitted duration.
    onset = (first + last) / (2 * rate) - duration / 2
    dominant = tracks[max(range(channels), key=lambda c: sum(v * v for v in tracks[c]))]
    lo = max(1, int((onset + duration * 0.25) * rate))
    hi = min(frames, int((onset + duration * 0.75) * rate))
    crossings = []
    for index in range(lo, hi):
        before, after = dominant[index - 1], dominant[index]
        if before <= 0 < after:
            crossings.append((index - 1 + (-before) / (after - before)) / rate)
    if len(crossings) < 8:
        raise ValueError("too few coherent tone cycles in the envelope centre")
    measured_hz = 1 / statistics.median(b - a for a, b in zip(crossings, crossings[1:]))

    begin = max(0, math.floor(onset * rate))
    end = min(frames, math.ceil((onset + duration) * rate))
    ss = cc = sc = 0.0
    ys, yc, energy = [0.0] * channels, [0.0] * channels, [0.0] * channels
    for index in range(begin, end):
        elapsed = index / rate - onset
        envelope = math.sin(math.pi * max(0.0, min(1.0, elapsed / duration)))
        s = envelope * math.sin(math.tau * hz * elapsed)
        c = envelope * math.cos(math.tau * hz * elapsed)
        ss += s * s
        cc += c * c
        sc += s * c
        for channel, track in enumerate(tracks):
            value = track[index] / 32768
            ys[channel] += value * s
            yc[channel] += value * c
            energy[channel] += value * value
    determinant = ss * cc - sc * sc
    if determinant <= 0:
        raise ValueError("degenerate production reference")
    fitted = []
    total_residual = 0.0
    for channel in range(channels):
        a = (ys[channel] * cc - yc[channel] * sc) / determinant
        b = (yc[channel] * ss - ys[channel] * sc) / determinant
        residual = max(0.0, energy[channel] - a * ys[channel] - b * yc[channel])
        total_residual += residual
        fitted.append({"channel": channel, "peak_pcm": peaks[channel],
                       "fitted_gain": math.hypot(a, b),
                       "fitted_phase_radians": math.atan2(b, a),
                       "residual_energy": residual})
    residual_fraction = total_residual / max(sum(energy), 1e-30)
    tail = pcm[end * channels:]
    tail_rms_lsb = math.sqrt(sum(v * v for v in tail) / max(len(tail), 1))
    checks = {
        "signal_above_quantisation_floor": max(peaks) >= 32,
        "no_clipped_samples": clipping == 0,
        "configured_frequency": abs(measured_hz - hz) <= 0.5,
        "configured_duration": abs(active_duration - duration) <= 0.05,
        "configured_half_sine_envelope_and_tone": residual_fraction <= 0.02,
        "silence_after_cue": tail_rms_lsb <= 1 and (frames - end) / rate >= 0.25,
    }
    return {"verdict": "PASS" if all(checks.values()) else "FAIL", "checks": checks,
            "wav_sha256": hashlib.sha256(raw).hexdigest(),
            "config_sha256": hashlib.sha256(config_bytes).hexdigest(),
            "pcm": {"channels": channels, "sample_width": width, "rate": rate,
                    "frames": frames, "seconds": frames / rate, "clipped_samples": clipping},
            "expected": {"frequency_hz": hz, "duration_seconds": duration,
                         "envelope": "sin(pi * t / duration)"},
            "measured": {"frequency_hz": measured_hz, "active_seconds": active_duration,
                         "first_active_seconds": first / rate, "last_active_seconds": last / rate,
                         "reference_onset_seconds": onset, "residual_energy_fraction": residual_fraction,
                         "tail_rms_lsb": tail_rms_lsb, "channels": fitted},
            "tolerances": {"frequency_hz": 0.5, "duration_seconds": 0.05,
                           "residual_energy_fraction": 0.02, "tail_rms_lsb": 1},
            "scope": "Configured low hum in mixed PCM output; no human listening, speaker or subjective quality verdict."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wav", type=Path, required=True)
    parser.add_argument("--config", type=Path, default=Path("data/config/portals.json"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        result = verify(args.wav, args.config)
    except (ValueError, KeyError, OSError, wave.Error, json.JSONDecodeError) as error:
        result = {"verdict": "FAIL", "error": str(error)}
    rendered = json.dumps(result, indent=2, allow_nan=False) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    print(rendered, end="")
    return 0 if result["verdict"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
