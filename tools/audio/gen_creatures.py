#!/usr/bin/env python3
"""Creature voices: four archetypes, two calls each.

Run: `python3 tools/audio/gen_creatures.py` (or `gen_all.py`).

## Four archetypes, not twenty species

The roster is around twenty species and growing, and one voice per species is
both a lot of files and -- worse -- twenty separate chances to make one that
does not match the others. Instead each archetype ships an `idle` and an
`alert`, and `data/config/audio.json` gives every species an archetype plus a
PITCH. Playback multiplies the two.

Pitch is the right differentiator because it is the real one: within a family of
animals, size sets voice, and the roster's own size guide is already the thing
telling the player how big something is. Ashtusk at 0.74 and Sparkit at 1.24 are
recognisably different animals to the ear, and they cost one file between them.

This does mean two species sharing an archetype and a similar pitch will sound
similar. That is a real limit and the config's `_comment_species` says so; the
fix when it matters is a fifth archetype, not twenty files.

## Idle and alert must be the same animal

The pair is the point: a player learns a creature's voice from its idle call and
must recognise the alert as THE SAME THROAT, or the alert teaches them nothing.
So each pair shares its formant structure and differs in contour -- alert is
shorter, louder, higher and harder-edged, which is what actual animal alarm
calls do.
"""

from __future__ import annotations

import numpy as np

import synth
from synth import SR_AMBIENCE as SR  # voices are band-limited; see synth.py

OUT = synth.ASSETS / "creatures"


def _voice(gen: np.random.Generator, *, base_hz: float, formants: list[float],
           duration: float, contour: list[float], noise_mix: float,
           roughness: float, attack: float = 0.02) -> np.ndarray:
    """The shared voice engine: a rough glottal source through fixed formants.

    This is a crude source-filter model, which is what an animal voice actually
    is -- a buzzy source at the larynx, shaped by resonances that do not move
    with pitch. Keeping the formants FIXED while `contour` moves the pitch is
    exactly what makes a call read as one creature changing its voice rather
    than as a whole sound being pitch-shifted, and it is why the runtime can
    pitch these per species without them turning into chipmunks.

    `contour` is a small list of pitch multipliers, interpolated across the
    call. `roughness` adds jitter to the source period -- a perfectly regular
    source sounds synthetic, and a little irregularity is most of what reads as
    "alive".
    """
    n = int(duration * SR)

    # Pitch track: the contour, resampled to the full length.
    track = np.interp(np.linspace(0.0, 1.0, n),
                      np.linspace(0.0, 1.0, len(contour)),
                      np.array(contour) * base_hz)
    # Jitter the pitch slightly and irregularly.
    if roughness > 0.0:
        wobble = synth.lowpass_fft(synth.white(n, gen), 22.0, SR)
        track = track * (1.0 + roughness * synth.normalise(wobble))

    # A sawtooth-ish source: rich in harmonics, which the formants then carve.
    # Built from the integrated phase so the sweep stays continuous.
    phase = np.cumsum(track) / SR
    source = 2.0 * (phase - np.floor(phase)) - 1.0
    source = synth.soft_clip(source * 1.4)

    # Breath. Every real voice has some; a pure oscillator does not sound alive.
    breath = synth.band(synth.white(n, gen), 700.0, 6000.0, SR, order=1.2)
    source = source * (1.0 - noise_mix) + breath * noise_mix

    voiced = np.zeros(n)
    # Descending weights: the first formant carries the vowel, the upper ones
    # add presence. Equal weights make everything sound like a kazoo.
    for i, freq in enumerate(formants):
        weight = 1.0 / (i + 1.0)
        voiced += synth.resonator(source, freq, 7.0, SR) * weight

    env = synth.adsr(n, attack, duration * 0.25, 0.62, duration * 0.45, SR)
    return synth.fade_edges(synth.normalise(voiced * env), 0.006, SR)


# --- the four archetypes -----------------------------------------------------
#
# Each is a pair. See the module header on why idle and alert must share a
# formant set.


def chirp_idle(gen: np.random.Generator) -> np.ndarray:
    """Small, bright, birdlike. The roster's little creatures.

    Two short rising notes -- a small animal announcing itself rather than
    warning anyone.
    """
    first = _voice(gen, base_hz=520.0, formants=[1400.0, 2800.0, 4100.0],
                   duration=0.16, contour=[1.0, 1.18, 1.10], noise_mix=0.12,
                   roughness=0.03)
    second = _voice(gen, base_hz=590.0, formants=[1400.0, 2800.0, 4100.0],
                    duration=0.13, contour=[1.05, 1.25], noise_mix=0.12,
                    roughness=0.03)
    out = synth.mix(first, np.concatenate([np.zeros(int(0.19 * SR)), second * 0.85]))
    return synth.normalise(out)


def chirp_alert(gen: np.random.Generator) -> np.ndarray:
    """Same throat, three fast hard notes. Alarm, not conversation."""
    parts = []
    for i in range(3):
        note = _voice(gen, base_hz=640.0 + i * 40.0,
                      formants=[1400.0, 2800.0, 4100.0],
                      duration=0.1, contour=[1.15, 1.35], noise_mix=0.16,
                      roughness=0.05, attack=0.006)
        parts.append(note)
        parts.append(np.zeros(int(0.055 * SR)))
    return synth.normalise(np.concatenate(parts))


def growl_idle(gen: np.random.Generator) -> np.ndarray:
    """Mid-sized and canine. A low rolling note that sags at the end."""
    return _voice(gen, base_hz=155.0, formants=[520.0, 1150.0, 2400.0],
                  duration=0.62, contour=[1.0, 1.06, 0.92], noise_mix=0.22,
                  roughness=0.09, attack=0.05)


def growl_alert(gen: np.random.Generator) -> np.ndarray:
    """A bark: same formants, a fraction of the length, hard attack, rising."""
    bark = _voice(gen, base_hz=210.0, formants=[520.0, 1150.0, 2400.0],
                  duration=0.2, contour=[1.3, 1.0], noise_mix=0.3,
                  roughness=0.13, attack=0.004)
    # A transient on the front. A bark starts with an impact; without one this
    # reads as a short growl instead.
    m = int(0.03 * SR)
    onset = synth.band(synth.white(m, gen), 400.0, 5000.0, SR)
    onset *= synth.percussive(m, 0.008, SR, attack_s=0.0004, curve=1.5)
    return synth.normalise(synth.mix(bark, onset * 0.4))


def rumble_idle(gen: np.random.Generator) -> np.ndarray:
    """Big and heavy. Low, long, and felt more than heard.

    The roster's large creatures. Formants sit low and close together, which is
    what a big resonant chest does.
    """
    return _voice(gen, base_hz=72.0, formants=[240.0, 520.0, 980.0],
                  duration=1.05, contour=[0.95, 1.0, 0.92], noise_mix=0.14,
                  roughness=0.06, attack=0.12)


def rumble_alert(gen: np.random.Generator) -> np.ndarray:
    """A roar. Louder, rougher, with a real rise, and saturated."""
    roar = _voice(gen, base_hz=96.0, formants=[240.0, 520.0, 980.0],
                  duration=0.75, contour=[0.9, 1.25, 1.1, 0.95], noise_mix=0.26,
                  roughness=0.14, attack=0.02)
    # Saturation adds the upper harmonics that make a roar carry over a fight.
    return synth.normalise(synth.soft_clip(roar * 2.2))


def trill_idle(gen: np.random.Generator) -> np.ndarray:
    """Amphibian and strange. A warbling note with a fast vibrato.

    The water and rift creatures. The vibrato is the identity -- nothing else in
    the set warbles, so this archetype is recognisable at any pitch.
    """
    n = int(0.5 * SR)
    t = synth.t_axis(n / SR, SR)
    warble = 1.0 + 0.09 * np.sin(2.0 * np.pi * t * 17.0)
    return _voice(gen, base_hz=300.0, formants=[820.0, 1700.0, 3200.0],
                  duration=0.5, contour=list(warble[::400]), noise_mix=0.18,
                  roughness=0.04, attack=0.03)


def trill_alert(gen: np.random.Generator) -> np.ndarray:
    """A faster, higher, more agitated warble that climbs."""
    n = int(0.34 * SR)
    t = synth.t_axis(n / SR, SR)
    warble = np.linspace(1.1, 1.45, n) * (1.0 + 0.13 * np.sin(2.0 * np.pi * t * 26.0))
    return _voice(gen, base_hz=340.0, formants=[820.0, 1700.0, 3200.0],
                  duration=0.34, contour=list(warble[::250]), noise_mix=0.24,
                  roughness=0.07, attack=0.008)


# `<archetype>_<call>` is the filename and the key world_audio.gd builds.
VOICES = {
    "chirp_idle": (chirp_idle, 3001, -12.0),
    "chirp_alert": (chirp_alert, 3002, -8.0),
    "growl_idle": (growl_idle, 3003, -11.0),
    "growl_alert": (growl_alert, 3004, -6.0),
    "rumble_idle": (rumble_idle, 3005, -10.0),
    "rumble_alert": (rumble_alert, 3006, -5.0),
    "trill_idle": (trill_idle, 3007, -12.0),
    "trill_alert": (trill_alert, 3008, -8.0),
}


def main() -> None:
    total = 0
    for name, (fn, seed, peak_db) in VOICES.items():
        samples = synth.at_db(fn(synth.rng(seed)), peak_db)
        path = synth.write_wav(OUT / f"{name}.wav", samples, SR)
        total += path.stat().st_size
    print(f"  {len(VOICES)} voices, {total // 1024} KB")


if __name__ == "__main__":
    main()
