#!/usr/bin/env python3
"""The Meadows ambience layer set.

Run: `python3 tools/audio/gen_ambience.py` (or `gen_all.py` for everything).

## Layers, not beds

The obvious build is one finished ambience file per region per time of day: five
bands times day/night is ten beds. This produces EIGHT layers instead, and
`data/config/audio.json` gives each band a gain for each layer at day and at
night. Three reasons, in order of how much they mattered:

1. **A band's identity becomes data.** "Band 2 is drier and has no birds" is a
   number a designer can change and hear, without a Python run and a 900 KB
   binary diff. The whole project already works this way -- see
   `data/config/art.json` for the lighting equivalent.
2. **Memory.** Ten beds is ten files' worth of RAM; eight layers cover the same
   ten cases because most layers appear in several. ROG Ally is primary and
   shares VRAM with system RAM.
3. **Day and night can CROSSFADE.** Ten separate beds can only hard-cut at
   dusk, or need a second copy of the mixing logic to blend two whole beds. Per
   layer gains interpolate for free, so dusk is birds receding while crickets
   arrive -- which is what dusk sounds like.

The cost is that no single file sounds like a finished place on its own. Judge
these in the game, through `world_audio.gd`, not in a media player.

## Length and rate

18 seconds at 22050 Hz mono. Long enough that the loop is not a recognisable
phrase (the ear starts spotting repeats in a noise bed at around 8-10s), short
enough that eight of them fit in a few MB. Every layer goes through
`seamless_loop` so the wrap is inaudible, and carries a `smpl` loop chunk so
Godot's importer loops it without a patched sidecar.
"""

from __future__ import annotations

import numpy as np

import synth
from synth import SR_AMBIENCE as SR

OUT = synth.ASSETS / "ambience"

# See the module docstring. The crossfade is taken off the top, so the generators
# below build LENGTH + CROSSFADE seconds of material.
LENGTH_S = 18.0
CROSSFADE_S = 2.5


def _canvas(seconds: float = LENGTH_S + CROSSFADE_S) -> int:
    return int(seconds * SR)


def _finish(x: np.ndarray, peak_db: float) -> np.ndarray:
    """Every layer ends here: loop the seam, then set the level.

    Levels are set per layer in dBFS rather than left at full scale because
    these are MIXED at runtime -- eight layers normalised to 0 dBFS and summed
    would clip instantly. The per-band gains in audio.json are relative to
    these, so a layer's headroom is part of the asset, not the config's problem.
    """
    return synth.at_db(synth.seamless_loop(x, CROSSFADE_S, SR), peak_db)


# --- the layers --------------------------------------------------------------


def wind_low(gen: np.random.Generator) -> np.ndarray:
    """The base air, present in every band at some gain.

    Brown noise low-passed hard, with two slow amplitude LFOs at incommensurate
    rates. The two-LFO trick is the whole reason this does not sound like a fan:
    one LFO gives a pulse the ear locks onto within a couple of cycles, two at
    an irrational ratio never quite repeat inside the loop.
    """
    n = _canvas()
    base = synth.brown(n, gen)
    base = synth.lowpass_fft(base, 420.0, SR, order=1.5)

    t = synth.t_axis(n / SR, SR)
    slow = 0.62 + 0.38 * np.sin(2.0 * np.pi * t / 7.3)
    slower = 0.75 + 0.25 * np.sin(2.0 * np.pi * t / 11.9 + 1.1)
    return _finish(base * slow * slower, -14.0)


def wind_high(gen: np.random.Generator) -> np.ndarray:
    """Exposed, higher ground: the hiss of wind over open grass and bare rock.

    Band-passed pink noise with deeper, faster gusting than `wind_low`. Used at
    real gain only in bands 4 and 5, where the corridor climbs out of shelter.
    """
    n = _canvas()
    base = synth.pink(n, gen)
    base = synth.band(base, 300.0, 5200.0, SR, order=1.5)

    t = synth.t_axis(n / SR, SR)
    # Gusts: a slow carrier shaped by a power curve so the quiet parts are long
    # and the loud parts brief, which is how wind actually behaves. A plain sine
    # spends half its time loud and reads as a synthesiser.
    gust = (0.5 + 0.5 * np.sin(2.0 * np.pi * t / 5.1)) ** 2.2
    ripple = 0.7 + 0.3 * np.sin(2.0 * np.pi * t / 2.7 + 0.6)
    return _finish(base * (0.25 + 0.75 * gust) * ripple, -16.0)


def meadow_birds(gen: np.random.Generator) -> np.ndarray:
    """Daytime songbirds over the lower meadows.

    Each call is 2-5 chirps; each chirp is a short frequency glide with a
    harmonic. Real birdsong is the one thing in this file that synthesis is
    clearly worse at than a recording -- these read as "small bird" rather than
    as any particular species -- and that is an accepted trade for a soundscape
    with no licence surface (see synth.py's header). Kept sparse and fairly
    quiet, which is both more realistic and more forgiving of the shortfall.
    """
    n = _canvas()

    def call(g: np.random.Generator) -> np.ndarray:
        pitch = g.uniform(1900.0, 3400.0)
        parts = []
        for _ in range(int(g.integers(2, 6))):
            dur = g.uniform(0.045, 0.11)
            m = int(dur * SR)
            # Up-glide or down-glide, roughly a musical third either way.
            start = pitch * g.uniform(0.86, 1.14)
            end = start * g.uniform(0.78, 1.28)
            sweep = np.linspace(start, end, m)
            tone = synth.sine(sweep, SR, m)
            # A quiet second harmonic: a pure sine reads as a test tone, and
            # this is the cheapest thing that makes it read as a throat.
            tone += 0.3 * synth.sine(sweep * 2.0, SR, m)
            env = synth.percussive(m, dur * 0.55, SR, attack_s=0.006, curve=0.8)
            parts.append(tone * env)
            gap = np.zeros(int(g.uniform(0.03, 0.13) * SR))
            parts.append(gap)
        return np.concatenate(parts) if parts else np.zeros(0)

    out = synth.scatter(n, call, 26, gen, gain_range=(0.25, 1.0), wrap=True)
    # Rolled off below 900 Hz: birdsong carries no real energy there, and
    # leaving it in muddies the wind layers it will be mixed with.
    return _finish(synth.highpass_fft(out, 900.0, SR), -19.0)


def night_insects(gen: np.random.Generator) -> np.ndarray:
    """Crickets, and the steady high shimmer of a summer night.

    Two textures at once: a continuous narrow-band shimmer around 4.5 kHz, and
    discrete cricket chirps. The shimmer is what actually sells "night" -- the
    chirps alone read as a sound effect played repeatedly.
    """
    n = _canvas()

    shimmer = synth.band(synth.white(n, gen), 3900.0, 5400.0, SR, order=3.0)
    t = synth.t_axis(n / SR, SR)
    shimmer *= 0.7 + 0.3 * np.sin(2.0 * np.pi * t / 6.7)

    def chirp(g: np.random.Generator) -> np.ndarray:
        """One cricket: a burst of 3-5 pulses of a narrow band around 4-5 kHz."""
        freq = g.uniform(3800.0, 5200.0)
        pulses = int(g.integers(3, 6))
        parts = []
        for _ in range(pulses):
            m = int(g.uniform(0.012, 0.022) * SR)
            tone = synth.sine(freq, SR, m) * synth.percussive(m, 0.008, SR, attack_s=0.002)
            parts.append(tone)
            parts.append(np.zeros(int(g.uniform(0.02, 0.035) * SR)))
        return np.concatenate(parts)

    chirps = synth.scatter(n, chirp, 90, gen, gain_range=(0.15, 0.7), wrap=True)
    return _finish(synth.mix(shimmer * 0.35, chirps), -20.0)


def river_water(gen: np.random.Generator) -> np.ndarray:
    """The river lock (band 3): moving water over stone.

    This is the layer synthesis is BEST at, and the reason the whole approach is
    defensible. Running water genuinely is filtered noise plus bubbles; a
    recording of it is several MB of incompressible hiss that will not loop.

    Built as a wide noise bed (the body of the flow) plus scattered short
    resonant blips (the bubbles and breaks over rocks). The blips are what stop
    it sounding like radio static.
    """
    n = _canvas()

    flow = synth.band(synth.pink(n, gen), 220.0, 7000.0, SR, order=1.5)
    t = synth.t_axis(n / SR, SR)
    flow *= 0.82 + 0.18 * np.sin(2.0 * np.pi * t / 4.3 + 0.4)

    def bubble(g: np.random.Generator) -> np.ndarray:
        """A rising resonant blip -- the sound of a bubble surfacing.

        The rise matters: a bubble's pitch goes UP as it shrinks and bursts.
        A falling or flat blip reads as a water drop into a cave instead.
        """
        dur = g.uniform(0.02, 0.06)
        m = int(dur * SR)
        start = g.uniform(400.0, 1100.0)
        sweep = np.linspace(start, start * g.uniform(1.5, 2.6), m)
        tone = synth.sine(sweep, SR, m)
        return tone * synth.percussive(m, dur * 0.4, SR, attack_s=0.003)

    bubbles = synth.scatter(n, bubble, 220, gen, gain_range=(0.1, 0.5), wrap=True)
    return _finish(synth.mix(flow * 0.55, bubbles * 0.5), -15.0)


def quarry_stone(gen: np.random.Generator) -> np.ndarray:
    """Band 2, stone and root: a dry, hollow, half-enclosed place.

    The design problem for band 2 is that it must read as DIFFERENT from open
    meadow while still being outdoors, and the honest answer is not "add a stone
    sound" but "take the air away": a low hollow resonance where the scarp
    encloses it, very little high content, and sparse discrete ticks of settling
    grit rather than a continuous texture. Emptiness is the character.
    """
    n = _canvas()

    # The enclosure: brown noise squeezed into a narrow low band and rung
    # through a resonator, which is what a rock hollow does to wind.
    body = synth.brown(n, gen)
    body = synth.band(body, 70.0, 340.0, SR, order=2.0)
    body = synth.resonator(body, 128.0, 3.5, SR)
    t = synth.t_axis(n / SR, SR)
    body *= 0.6 + 0.4 * np.sin(2.0 * np.pi * t / 9.1)

    def tick(g: np.random.Generator) -> np.ndarray:
        """A pebble settling: a click with a short pitched ring."""
        m = int(g.uniform(0.02, 0.05) * SR)
        freq = g.uniform(900.0, 2600.0)
        click = synth.white(m, g) * synth.percussive(m, 0.004, SR, attack_s=0.0005, curve=1.6)
        ring = synth.sine(freq, SR, m) * synth.percussive(m, 0.018, SR, attack_s=0.001)
        return synth.mix(click * 0.6, ring * 0.4)

    ticks = synth.scatter(n, tick, 22, gen, gain_range=(0.1, 0.55), wrap=True)
    return _finish(synth.mix(synth.normalise(body) * 0.8, ticks * 0.35), -18.0)


def ironwood_canopy(gen: np.random.Generator) -> np.ndarray:
    """Band 4, the upper meadows' ironwood: wind through a canopy, and creaks.

    Leaf rustle is band-passed noise gated by a fast irregular envelope -- the
    gating is essential, since ungated it is just more wind. The creaks are slow
    pitch-bending resonances: big timber under load, spaced far apart so each
    one registers as an event.
    """
    n = _canvas()

    rustle = synth.band(synth.pink(n, gen), 1100.0, 6500.0, SR, order=1.5)
    t = synth.t_axis(n / SR, SR)
    # Three incommensurate rates: leaves move in overlapping waves, not in time.
    gate = (
        (0.5 + 0.5 * np.sin(2.0 * np.pi * t / 3.1))
        * (0.5 + 0.5 * np.sin(2.0 * np.pi * t / 1.37 + 2.0))
        * (0.6 + 0.4 * np.sin(2.0 * np.pi * t / 0.71 + 0.3))
    )
    rustle *= 0.15 + 0.85 * gate

    def creak(g: np.random.Generator) -> np.ndarray:
        dur = g.uniform(0.5, 1.4)
        m = int(dur * SR)
        base = g.uniform(90.0, 210.0)
        # The bend is the creak. Wood under load changes pitch as it gives.
        sweep = np.linspace(base, base * g.uniform(1.06, 1.3), m)
        tone = synth.sine(sweep, SR, m) + 0.4 * synth.sine(sweep * 2.01, SR, m)
        tone += 0.2 * synth.sine(sweep * 3.03, SR, m)
        env = synth.adsr(m, dur * 0.35, dur * 0.2, 0.55, dur * 0.45, SR)
        # Saturated: a creak is a stick-slip event, not a clean tone, and mild
        # distortion is the cheapest way to get that grain.
        return synth.soft_clip(tone * env * 1.6) * 0.5

    creaks = synth.scatter(n, creak, 7, gen, gain_range=(0.2, 0.7), wrap=True)
    low = synth.lowpass_fft(synth.brown(n, gen), 300.0, SR) * 0.5
    return _finish(synth.mix(rustle * 0.5, creaks * 0.4, low), -17.0)


def tether_drone(gen: np.random.Generator) -> np.ndarray:
    """Band 5, the stronghold approach: Team Tether's machinery bleeding out.

    The chapter's climax approach should sound WRONG -- the only layer here that
    is not a natural sound. A detuned pair of low tones beating against each
    other, a hollow fifth above, and an irregular electrical crackle.

    The beat frequency is the trick: two sines a fraction of a hertz apart
    produce a slow throb no single oscillator can, and the ear reads it as
    something powered and badly maintained rather than as a musical note.
    """
    n = _canvas()
    t = synth.t_axis(n / SR, SR)

    root = 55.0
    drone = synth.sine(root, SR, n) + synth.sine(root * 1.004, SR, n)
    drone += 0.5 * (synth.sine(root * 1.5, SR, n) + synth.sine(root * 1.503, SR, n))
    # A dissonant tritone, very quiet: enough to unsettle, not enough to name.
    drone += 0.18 * synth.sine(root * 1.414, SR, n)
    drone *= 0.7 + 0.3 * np.sin(2.0 * np.pi * t / 13.0)

    def crackle(g: np.random.Generator) -> np.ndarray:
        m = int(g.uniform(0.008, 0.03) * SR)
        burst = synth.white(m, g) * synth.percussive(m, 0.006, SR, attack_s=0.0004, curve=1.8)
        return synth.highpass_fft(burst, 2200.0, SR)

    crackles = synth.scatter(n, crackle, 40, gen, gain_range=(0.05, 0.4), wrap=True)
    return _finish(synth.mix(synth.normalise(drone) * 0.8, crackles * 0.3), -17.0)


# --- registry ----------------------------------------------------------------
#
# The name here is the key `data/config/audio.json` uses in every band's layer
# gain table, and the file stem on disk. Seeds are arbitrary but fixed; see
# synth.rng on why they are explicit.

LAYERS = {
    "wind_low": (wind_low, 1001),
    "wind_high": (wind_high, 1002),
    "meadow_birds": (meadow_birds, 1003),
    "night_insects": (night_insects, 1004),
    "river_water": (river_water, 1005),
    "quarry_stone": (quarry_stone, 1006),
    "ironwood_canopy": (ironwood_canopy, 1007),
    "tether_drone": (tether_drone, 1008),
}


def main() -> None:
    for name, (fn, seed) in LAYERS.items():
        samples = fn(synth.rng(seed))
        path = synth.write_wav(OUT / f"{name}.wav", samples, SR, loop=True)
        print(f"  {path.relative_to(synth.REPO_ROOT)}  "
              f"{len(samples) / SR:.1f}s  {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
