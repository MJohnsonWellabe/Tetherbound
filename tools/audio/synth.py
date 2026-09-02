#!/usr/bin/env python3
"""The shared synthesis library behind every Tetherbound audio asset.

`gen_ui_cues.py` (spec 20) established the pattern this generalises: the game's
audio is WRITTEN, in Python, from the standard library plus numpy, and the .wav
output is committed. Nothing is fetched, so `docs/specs/ASSET_LEDGER.md` needs one row
saying "written for this task" rather than a licence audit per file, and nobody
has to wonder whether a sample library is redistributable in a shipped build.

**Why synthesis rather than a sample pack**, recorded here because it is a real
trade and the next session should be able to disagree with it on the evidence:

- *Cohesion.* CLAUDE.md's asset rule is "maintain visual cohesion"; the audio
  equivalent is a soundscape that sounds like one place. Ten free packs recorded
  in ten rooms at ten distances do not, and fixing that is a mastering project.
  Everything here shares one synthesis chain, so it already matches.
- *Memory.* ROG Ally is primary and shares VRAM with system RAM (see
  project.godot's shadow-atlas comments for how tight that already is). Wind and
  water are noise shaped by filters; a recording of them is megabytes of
  incompressible hiss. The whole ambience layer set below is smaller than one
  minute of stereo 44.1k.
- *Parameterisation.* A creature's voice wants to vary per species. A generator
  takes a pitch and a formant; a .wav does not.

Where synthesis is genuinely worse -- real birdsong, a human voice -- nothing
here pretends otherwise, and the ledger row says so.

## Conventions

Everything is float64 numpy in [-1, 1] until `write_wav` quantises it. Mono
unless a generator says otherwise: the game is third-person with a moving
camera, so positional audio comes from `AudioStreamPlayer3D` placing a mono
source in the world, not from baked stereo.

22050 Hz for ambience and creature voices, 44100 Hz for short transients. Wind
and water have nothing above 8 kHz worth storing; an impact's initial click
does. See `SR_AMBIENCE` / `SR_SFX`.

Every generator takes an explicit `seed` and uses its own `numpy.random.Generator`.
Regenerating must produce byte-identical files or the committed .wav diff
becomes noise on every run and reviewers stop reading it.
"""

from __future__ import annotations

import struct
import wave
from pathlib import Path

import numpy as np

# Ambience and voices are band-limited by nature; halving the rate halves the
# file with no audible loss. Short transients keep the full rate because their
# attack is the part that carries the material (see `impact`).
SR_AMBIENCE = 22050
SR_SFX = 44100

REPO_ROOT = Path(__file__).resolve().parents[2]
ASSETS = REPO_ROOT / "assets" / "audio"


def db_to_amp(db: float) -> float:
    return 10.0 ** (db / 20.0)


# --- oscillators and noise ---------------------------------------------------


def rng(seed: int) -> np.random.Generator:
    """A generator seeded per asset, never the global numpy state.

    Determinism is the whole contract: `gen_all.py` regenerates every file on
    every run, and a file whose bytes move without its parameters moving turns
    the committed .wav set into permanent diff noise.
    """
    return np.random.default_rng(seed)


def t_axis(duration_s: float, sr: int) -> np.ndarray:
    return np.arange(int(round(duration_s * sr)), dtype=np.float64) / sr


def white(n: int, gen: np.random.Generator) -> np.ndarray:
    return gen.uniform(-1.0, 1.0, n)


def pink(n: int, gen: np.random.Generator) -> np.ndarray:
    """Pink (1/f) noise via spectral shaping.

    Wind, distant water and room tone are all closer to pink than to white --
    white noise reads as "hiss from a device", pink as "air". Done in the
    frequency domain rather than with the usual Voss-McCartney octave trick
    because the FFT version has no low-frequency drift artefacts to hide, and at
    these lengths it costs nothing.
    """
    spectrum = np.fft.rfft(white(n, gen))
    freqs = np.fft.rfftfreq(n, 1.0)
    # freqs[0] is DC; dividing by sqrt(0) would be inf, and DC is inaudible
    # offset anyway, so it is zeroed rather than scaled.
    scale = np.ones_like(freqs)
    scale[1:] = 1.0 / np.sqrt(freqs[1:])
    scale[0] = 0.0
    out = np.fft.irfft(spectrum * scale, n)
    return normalise(out)


def brown(n: int, gen: np.random.Generator) -> np.ndarray:
    """Brown (1/f^2) noise -- the low rumble under heavy wind and rockfall."""
    spectrum = np.fft.rfft(white(n, gen))
    freqs = np.fft.rfftfreq(n, 1.0)
    scale = np.ones_like(freqs)
    scale[1:] = 1.0 / freqs[1:]
    scale[0] = 0.0
    out = np.fft.irfft(spectrum * scale, n)
    return normalise(out)


def sine(freq: np.ndarray | float, sr: int, n: int, phase: float = 0.0) -> np.ndarray:
    """A sine whose frequency may itself be an array (an FM/glide source).

    Phase is integrated rather than computed as `2*pi*f*t` so a swept frequency
    stays continuous. The naive form clicks audibly on every glide, which is
    exactly what a creature call and a catch-orb whine are made of.
    """
    freqs = np.full(n, float(freq)) if np.isscalar(freq) else np.asarray(freq, dtype=np.float64)
    return np.sin(2.0 * np.pi * np.cumsum(freqs) / sr + phase)


# --- filters -----------------------------------------------------------------
#
# One-pole and state-variable filters written out rather than pulled from scipy:
# scipy is not in this repo's tool dependencies (numpy is -- see the other
# tools/*.py) and these are ten lines each. The one-pole versions are applied
# with `lfilter_onepole`, which is a Python loop and therefore the slowest thing
# in this file; the FFT-domain `band` below is used wherever the shape is static,
# which is most places.


def lowpass_fft(x: np.ndarray, cutoff_hz: float, sr: int, order: float = 2.0) -> np.ndarray:
    """Static low-pass in the frequency domain (Butterworth-shaped magnitude).

    Zero-phase and effectively free compared with a sample loop. Used for every
    fixed filter shape; only genuinely time-varying cutoffs need the one-pole.
    """
    n = len(x)
    spectrum = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    with np.errstate(divide="ignore"):
        mag = 1.0 / np.sqrt(1.0 + (freqs / max(cutoff_hz, 1e-6)) ** (2.0 * order))
    return np.fft.irfft(spectrum * mag, n)


def highpass_fft(x: np.ndarray, cutoff_hz: float, sr: int, order: float = 2.0) -> np.ndarray:
    n = len(x)
    spectrum = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    ratio = np.divide(max(cutoff_hz, 1e-6), np.maximum(freqs, 1e-6))
    mag = 1.0 / np.sqrt(1.0 + ratio ** (2.0 * order))
    mag[0] = 0.0
    return np.fft.irfft(spectrum * mag, n)


def band(x: np.ndarray, low_hz: float, high_hz: float, sr: int, order: float = 2.0) -> np.ndarray:
    return lowpass_fft(highpass_fft(x, low_hz, sr, order), high_hz, sr, order)


def resonator(x: np.ndarray, freq_hz: float, q: float, sr: int) -> np.ndarray:
    """A single resonant peak -- the formant that makes noise sound like a throat.

    Two-pole, applied as a real IIR sample loop because a resonance is exactly
    the case where the frequency-domain shortcut misleads: the ringing tail is
    the point, and a zero-phase magnitude mask does not produce one.
    """
    w = 2.0 * np.pi * freq_hz / sr
    r = np.exp(-w / (2.0 * max(q, 0.01)))
    a1 = 2.0 * r * np.cos(w)
    a2 = -(r * r)
    b0 = (1.0 - r) * np.sqrt(1.0 - 2.0 * r * np.cos(2.0 * w) + r * r)
    out = np.zeros_like(x)
    y1 = 0.0
    y2 = 0.0
    for i in range(len(x)):
        y = b0 * x[i] + a1 * y1 + a2 * y2
        out[i] = y
        y2 = y1
        y1 = y
    return out


# --- envelopes and shaping ---------------------------------------------------


def adsr(n: int, attack_s: float, decay_s: float, sustain: float, release_s: float,
         sr: int) -> np.ndarray:
    a = int(attack_s * sr)
    d = int(decay_s * sr)
    r = int(release_s * sr)
    s = max(0, n - a - d - r)
    parts = [
        np.linspace(0.0, 1.0, a, endpoint=False) if a else np.empty(0),
        np.linspace(1.0, sustain, d, endpoint=False) if d else np.empty(0),
        np.full(s, sustain),
        np.linspace(sustain, 0.0, r) if r else np.empty(0),
    ]
    env = np.concatenate(parts)
    # Rounding across four segments can land a sample or two either side.
    if len(env) < n:
        env = np.concatenate([env, np.zeros(n - len(env))])
    return env[:n]


def percussive(n: int, decay_s: float, sr: int, attack_s: float = 0.001,
               curve: float = 1.0) -> np.ndarray:
    """Fast attack, exponential decay -- every impact, step and click.

    `curve` > 1 tightens the tail (a dry stone tap), < 1 loosens it (a soft
    thud on grass). It is the single most useful knob for making two hits of
    the same pitch read as two different materials.
    """
    a = max(1, int(attack_s * sr))
    env = np.ones(n)
    env[:a] = np.linspace(0.0, 1.0, a)
    tail = np.exp(-np.arange(n - a) / max(decay_s * sr, 1.0) * 3.0) ** curve
    env[a:] = tail
    return env


def fade_edges(x: np.ndarray, seconds: float, sr: int) -> np.ndarray:
    """Fade the first and last `seconds` to zero. Stops a one-shot clicking."""
    n = min(int(seconds * sr), len(x) // 2)
    if n <= 0:
        return x
    out = x.copy()
    ramp = np.linspace(0.0, 1.0, n)
    out[:n] *= ramp
    out[-n:] *= ramp[::-1]
    return out


def seamless_loop(x: np.ndarray, crossfade_s: float, sr: int) -> np.ndarray:
    """Make a clip loop without a seam, by cross-fading its tail over its head.

    An ambience bed loops for the whole time the player is in a region, so a
    click at the wrap is a click the player hears hundreds of times. This is the
    standard equal-power overlap: the last `crossfade_s` is mixed into the first
    `crossfade_s` and then cut, so the file's end already IS its beginning.

    Costs `crossfade_s` of length -- ask for a slightly longer clip than the loop
    you want.
    """
    n = int(crossfade_s * sr)
    if n <= 0 or len(x) <= 2 * n:
        return x
    head = x[:n]
    tail = x[-n:]
    # Equal-power (sin/cos) rather than linear: two uncorrelated noise sources
    # crossfaded linearly dip ~3 dB in the middle, and a periodic dip in a wind
    # bed is exactly as noticeable as the click it replaced.
    fade = np.linspace(0.0, np.pi / 2.0, n)
    blended = head * np.sin(fade) + tail * np.cos(fade)
    return np.concatenate([blended, x[n:-n]])


def normalise(x: np.ndarray, peak: float = 1.0) -> np.ndarray:
    top = np.max(np.abs(x))
    if top < 1e-12:
        return x
    return x * (peak / top)


def soft_clip(x: np.ndarray) -> np.ndarray:
    """tanh saturation. Guarantees [-1, 1] without the flat tops of hard clipping."""
    return np.tanh(x)


def at_db(x: np.ndarray, db: float) -> np.ndarray:
    """Normalise to a peak of `db` dBFS. The last call before mixing or writing."""
    return normalise(x, db_to_amp(db))


def mix(*layers: np.ndarray) -> np.ndarray:
    """Sum layers of differing length, padding to the longest."""
    if not layers:
        return np.zeros(0)
    n = max(len(layer) for layer in layers)
    out = np.zeros(n)
    for layer in layers:
        out[: len(layer)] += layer
    return out


def place(base: np.ndarray, clip: np.ndarray, at_sample: int, gain: float = 1.0) -> None:
    """Add `clip` into `base` at a sample offset, clipped to the buffer.

    In place, and silently truncating at both edges: the scatter helpers below
    place hundreds of grains at random offsets and an out-of-range one is
    ordinary, not an error.
    """
    if at_sample >= len(base):
        return
    start = max(0, at_sample)
    head = start - at_sample
    end = min(len(base), at_sample + len(clip))
    if end <= start:
        return
    base[start:end] += clip[head : head + (end - start)] * gain


def scatter(n: int, clip_fn, count: int, gen: np.random.Generator,
            gain_range: tuple[float, float] = (0.5, 1.0),
            wrap: bool = False) -> np.ndarray:
    """Sprinkle `count` independently generated clips across an `n`-sample buffer.

    This is how every "many small events" texture is built: birdsong over a
    meadow, water breaking over stones, insects at night, gravel under a boot.
    `clip_fn(gen)` returns one event.

    `wrap=True` wraps an event that runs off the end back around to the start,
    which is what a LOOPING bed needs -- otherwise every loop has a thinning
    patch at its tail where no event was allowed to begin.
    """
    out = np.zeros(n)
    for _ in range(count):
        clip = clip_fn(gen)
        gain = gen.uniform(*gain_range)
        at = int(gen.integers(0, n))
        place(out, clip, at, gain)
        if wrap and at + len(clip) > n:
            place(out, clip[n - at :], 0, gain)
    return out


# --- output ------------------------------------------------------------------


def write_wav(path: Path, samples: np.ndarray, sr: int, *, loop: bool = False) -> Path:
    """16-bit mono PCM, optionally carrying a loop region.

    Not .ogg: Godot's `AudioStreamWAV` importer can carry a loop region, and
    every ambience bed here needs one. The sizes involved (see `SR_AMBIENCE`)
    do not justify a compressed format with a decoder cost on a handheld.

    **How the loop reaches the engine.** `loop=True` appends a `smpl` chunk
    naming the whole clip as one forward loop. This is deliberately NOT done by
    hand-writing a `.import` sidecar with `edit/loop_mode` set: Godot's WAV
    importer defaults that setting to 0, which is "Detect From WAV", not
    "disabled" -- so a `smpl` chunk in the file is the setting, and the sidecar
    Godot generates on first import is already correct with nothing to patch.
    Encoding the intent in the asset rather than in a generated file beside it
    also means the loop survives anyone deleting `.godot/` and re-importing,
    which is a routine thing to do here.

    Samples are hard-limited before quantisation. A generator that sums layers
    can exceed [-1, 1], and the wrap-around on int16 overflow is a loud buzz --
    the failure mode is much worse than the clipping it would replace.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    clipped = np.clip(samples, -1.0, 1.0)
    pcm = (clipped * 32767.0).astype(np.int16)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(sr)
        handle.writeframes(pcm.tobytes())
    if loop:
        _append_smpl_chunk(path, len(pcm), sr)
    return path


def _append_smpl_chunk(path: Path, frames: int, sr: int) -> None:
    """Append a RIFF `smpl` chunk marking [0, frames-1] as a forward loop.

    The layout is the standard one from the MIDI Manufacturers Association
    sampler spec that every DAW writes and Godot's importer reads: a 36-byte
    header, then one 24-byte loop record. Only the fields Godot actually looks
    at carry meaning here (loop count, loop type 0 = forward, start, end);
    the rest are the conventional zeros/defaults.

    Appending after `wave` has closed the file, then fixing the RIFF size field,
    is simpler than reimplementing the whole writer -- `wave` has no hook for
    extra chunks and subclassing it to add one is more code than this.
    """
    sample_period_ns = int(round(1e9 / sr))
    smpl = struct.pack(
        "<9I",
        0,                   # manufacturer
        0,                   # product
        sample_period_ns,    # sample period, nanoseconds
        60,                  # MIDI unity note (middle C; unused by Godot)
        0,                   # MIDI pitch fraction
        0,                   # SMPTE format
        0,                   # SMPTE offset
        1,                   # number of sample loops
        0,                   # sampler-data byte count
    ) + struct.pack(
        "<6I",
        0,                   # cue point id
        0,                   # type: 0 = forward loop
        0,                   # start frame
        max(frames - 1, 0),  # end frame, inclusive
        0,                   # fraction
        0,                   # play count: 0 = forever
    )
    chunk = b"smpl" + struct.pack("<I", len(smpl)) + smpl
    with open(path, "r+b") as handle:
        handle.seek(0, 2)
        handle.write(chunk)
        # RIFF's size field counts everything after the first 8 bytes.
        total = handle.tell()
        handle.seek(4)
        handle.write(struct.pack("<I", total - 8))
