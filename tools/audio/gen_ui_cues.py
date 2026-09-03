#!/usr/bin/env python3
"""Synthesizes Tetherbound's small UI audio set (spec 20).

Nine short, subtle cues, 44100 Hz 16-bit mono WAV, written straight to
assets/ui/audio/ with the wave/struct standard-library modules -- no network
fetch, no third-party samples, so provenance is "written for this task" per
docs/specs/ASSET_LEDGER.md's row for these files.

Run: python3 tools/audio/gen_ui_cues.py
Regenerate any time the cue list changes; nothing hand-edits the .wav files
directly.
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ui", "audio")


def db_to_amp(db: float) -> float:
    return 10.0 ** (db / 20.0)


def envelope(i: int, n: int, attack: int, release: int) -> float:
    """Linear attack/release, flat in between. Avoids clicks at edges."""
    if n <= 0:
        return 0.0
    if i < attack:
        return i / max(attack, 1)
    if i > n - release:
        return max(0.0, (n - i) / max(release, 1))
    return 1.0


def tone(freq_start: float, freq_end: float, duration_s: float, gain_db: float,
         attack_s: float = 0.005, release_s: float = 0.015, wave_shape: str = "sine") -> list:
    n = int(SAMPLE_RATE * duration_s)
    attack = int(SAMPLE_RATE * attack_s)
    release = int(SAMPLE_RATE * release_s)
    amp = db_to_amp(gain_db)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = freq_start + (freq_end - freq_start) * (i / max(n - 1, 1))
        phase += freq / SAMPLE_RATE
        if wave_shape == "square":
            frac = phase - math.floor(phase)
            s = 1.0 if frac < 0.5 else -1.0
        else:
            s = math.sin(2.0 * math.pi * phase)
        s *= amp * envelope(i, n, attack, release)
        out.append(s)
    return out


def noise_sweep(duration_s: float, gain_db: float, low_hz: float, high_hz: float) -> list:
    """A short filtered-noise sweep: white noise through a crude moving
    one-pole low-pass whose cutoff rises over the clip, for the "tab swipe"
    whoosh -- distinct in texture from every tone-based cue in the set."""
    import random
    random.seed(20260813)  # deterministic output across regenerations
    n = int(SAMPLE_RATE * duration_s)
    attack = int(SAMPLE_RATE * 0.004)
    release = int(SAMPLE_RATE * 0.02)
    amp = db_to_amp(gain_db)
    out = []
    lp = 0.0
    for i in range(n):
        cutoff = low_hz + (high_hz - low_hz) * (i / max(n - 1, 1))
        alpha = min(1.0, cutoff / SAMPLE_RATE * 4.0)
        raw = random.uniform(-1.0, 1.0)
        lp += alpha * (raw - lp)
        s = lp * amp * envelope(i, n, attack, release)
        out.append(s)
    return out


def mix(*layers_with_offsets):
    """layers_with_offsets: list of (samples, offset_in_samples). Returns one
    combined buffer sized to the longest layer, clipped to [-1, 1]."""
    total_len = max(off + len(layer) for layer, off in layers_with_offsets)
    out = [0.0] * total_len
    for layer, off in layers_with_offsets:
        for i, s in enumerate(layer):
            out[off + i] += s
    return [max(-1.0, min(1.0, s)) for s in out]


def write_wav(name: str, samples: list) -> None:
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        frames = b"".join(struct.pack("<h", int(s * 32767)) for s in samples)
        f.writeframes(frames)
    print("wrote", path, "%.0fms" % (len(samples) * 1000.0 / SAMPLE_RATE))


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    # ui_focus: a short, quiet tick -- has to disappear under rapid hover.
    write_wav("ui_focus.wav", tone(1800, 1800, 0.030, -18, 0.002, 0.010))

    # ui_accept: two-tone rising confirm.
    write_wav("ui_accept.wav", mix(
        (tone(880, 880, 0.045, -12, 0.003, 0.015), 0),
        (tone(1320, 1320, 0.050, -12, 0.003, 0.020), int(SAMPLE_RATE * 0.045)),
    ))

    # ui_cancel: falling two-tone, the mirror of accept.
    write_wav("ui_cancel.wav", mix(
        (tone(660, 660, 0.040, -12, 0.003, 0.014), 0),
        (tone(440, 440, 0.045, -12, 0.003, 0.020), int(SAMPLE_RATE * 0.038)),
    ))

    # ui_tab: filtered-noise swipe, textured differently from every tone cue
    # so it reads as "page turned" rather than another beep.
    write_wav("ui_tab.wav", noise_sweep(0.060, -16, 400, 2600))

    # ui_error: low square-ish buzz -- the one cue that should NOT sound nice.
    write_wav("ui_error.wav", tone(220, 220, 0.120, -14, 0.004, 0.030, wave_shape="square"))

    # aim_enter: a longer, gentle rise into combat aiming.
    write_wav("aim_enter.wav", tone(440, 880, 0.120, -14, 0.006, 0.030))

    # build_snap: a tiny high click for the ghost locking onto a neighbour.
    write_wav("build_snap.wav", tone(2200, 2200, 0.025, -12, 0.001, 0.008))

    # build_place: a low thud plus a short click on top, for the moment a
    # piece is actually planted.
    write_wav("build_place.wav", mix(
        (tone(180, 140, 0.120, -12, 0.004, 0.070), 0),
        (tone(1800, 1800, 0.018, -16, 0.001, 0.008), 0),
    ))

    # capture_success: a bright three-note arpeggio.
    step = int(SAMPLE_RATE * 0.075)
    write_wav("capture_success.wav", mix(
        (tone(880, 880, 0.090, -13, 0.003, 0.040), 0),
        (tone(1100, 1100, 0.090, -13, 0.003, 0.040), step),
        (tone(1320, 1320, 0.110, -13, 0.003, 0.060), step * 2),
    ))


if __name__ == "__main__":
    main()
