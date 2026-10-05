#!/usr/bin/env python3
"""The nine Stormwood Surge and lightning assets (AUDIO §4.3, §10).

Run: `python3 tools/audio/gen_stormwood.py`

Owner decision, 2026-10-05: these files are authored from sound sources already
installed in this repository -- no purchase, no new third-party download and no
text-to-audio service. Every layer below is either an installed project WAV
(`assets/audio/ambience/`, `assets/audio/sfx/`), re-pitched, filtered and
enveloped, or the shared `synth.py` chain that wrote those WAVs in the first
place. The installed WAVs are themselves original synthesis by `tools/audio/`
(archive ASSET_LEDGER row "Meadows soundscape"), so no third-party licence
attaches to the result either.

The paths and roles are fixed by `data/config/stormwood_audio.json`; this file
adds no cue and wires nothing. `scripts/world/stormwood_surge_audio.gd` plays
each one as soon as `ResourceLoader.exists()` sees it.

## Format

Same conventions as the rest of `assets/audio/`: 16-bit mono PCM. Beds are
22050 Hz (the ambience rate) and carry a `smpl` forward loop over the whole
clip, so Godot's importer loops them ("Detect From WAV") and the observer's
single `play_file` call sustains for the whole phase. The four strike layers
are 44100 Hz one-shots (the sfx rate; the attack is the material) and mono
because they are positional.

## Provenance

`write_manifest()` records, per asset, the installed source files (with their
SHA-256), every processing step, the seed and the output hash in
`assets/audio/stormwood/MANIFEST.json`. Regenerating with no source change is
byte-identical.
"""

from __future__ import annotations

import hashlib
import json
import wave
from pathlib import Path

import numpy as np

import synth

SR_BED = synth.SR_AMBIENCE
SR_FX = synth.SR_SFX
OUT = synth.ASSETS / "stormwood"
REPO = synth.REPO_ROOT

# Beds are a little longer than the Meadows layers (18 s): the calm bed's
# "distant thunder with long spacing" needs room for two rolls that do not
# land on a recognisable period.
BED_S = 24.0
CROSSFADE_S = 2.5

# Bed loudness is set by integrated level, not peak, so the five beds sit
# where the installed ambience beds sit (checked by check_stormwood.py).
# Break is louder than Building is louder than Calm: the Surge must be
# nameable from sound (AUDIO §4.3), and energy is one of the two axes.
BED_RMS_DB = {
    "surge_calm_bed": -28.5,
    "surge_building_bed": -26.0,
    "surge_break_bed": -24.0,
    "surge_fading_decay": -31.0,
    "release_forest_sky_bed": -28.5,
}
BED_PEAK_CEILING_DB = -3.0
FX_PEAK_DB = {"strike_warning": -4.0, "strike_crack": -1.0, "strike_body": -1.5, "strike_decay": -4.0}

_steps: dict[str, list[str]] = {}
_sources: dict[str, set[str]] = {}
_seeds: dict[str, int] = {}


def _log(asset: str, step: str) -> None:
    _steps.setdefault(asset, []).append(step)


# --- installed sources ---------------------------------------------------------


def load_installed(rel: str, asset: str) -> tuple[np.ndarray, int]:
    """Read an installed project WAV (16-bit mono) as float64 in [-1, 1]."""
    path = REPO / rel
    with wave.open(str(path), "rb") as handle:
        if handle.getnchannels() != 1 or handle.getsampwidth() != 2:
            raise ValueError(f"{rel}: expected 16-bit mono")
        sr = handle.getframerate()
        pcm = np.frombuffer(handle.readframes(handle.getnframes()), dtype="<i2")
    _sources.setdefault(asset, set()).add(rel)
    return pcm.astype(np.float64) / 32767.0, sr


def resample(x: np.ndarray, src_sr: int, dst_sr: int, speed: float = 1.0) -> np.ndarray:
    """Linear-interpolation resample, `speed` > 1 pitches up (tape style).

    Linear is enough here: every source is band-limited noise or a low
    transient, and every result is filtered afterwards anyway.
    """
    ratio = src_sr * speed / dst_sr
    n_out = int(len(x) / ratio)
    pos = np.arange(n_out) * ratio
    return np.interp(pos, np.arange(len(x)), x)


def tiled(x: np.ndarray, n: int) -> np.ndarray:
    """Repeat a (looping) source to length n. The final seam is crossfaded later."""
    return np.resize(x, n)


def installed_layer(rel: str, asset: str, n: int, sr: int, speed: float = 1.0,
                    offset_s: float = 0.0) -> np.ndarray:
    raw, src_sr = load_installed(rel, asset)
    x = resample(raw, src_sr, sr, speed)
    x = np.roll(x, -int(offset_s * sr))
    return tiled(x, n)


# --- small synth parts -------------------------------------------------------


def rolling_thunder(n: int, sr: int, gen: np.random.Generator, cutoff: float,
                    attack_s: float, length_s: float) -> np.ndarray:
    """A thunder roll: brown noise, low-passed, with several overlapping swells."""
    m = int(length_s * sr)
    # High-passed at 30 Hz: brown noise puts most of its power below 20 Hz,
    # which is inaudible, offsets DC and would eat the level budget.
    body = synth.band(synth.brown(m, gen), 30.0, cutoff, sr, order=2.0)
    env = np.zeros(m)
    t = np.arange(m) / sr
    for k in range(int(gen.integers(3, 6))):
        at = gen.uniform(0.0, length_s * 0.55)
        width = gen.uniform(0.5, 1.6)
        env += gen.uniform(0.4, 1.0) * np.exp(-((t - at - attack_s) / width) ** 2)
    env *= np.minimum(1.0, t / max(attack_s, 1e-3))
    env *= np.exp(-t / (length_s * 0.45))
    out = np.zeros(n)
    out[:m] = (body * env)[:n]
    return synth.normalise(out)


def drip(gen: np.random.Generator, sr: int) -> np.ndarray:
    """One drop off a leaf: a short resonant ping."""
    m = int(0.09 * sr)
    pulse = synth.white(m, gen) * synth.percussive(m, 0.004, sr)
    return synth.normalise(synth.resonator(pulse, gen.uniform(1400.0, 3200.0), 18.0, sr))


def copper_tick(gen: np.random.Generator, sr: int) -> np.ndarray:
    """Copper-vine tick: a dry metallic click with two inharmonic partials."""
    m = int(0.06 * sr)
    pulse = synth.white(m, gen) * synth.percussive(m, 0.002, sr)
    f = gen.uniform(2600.0, 4200.0)
    ring = synth.resonator(pulse, f, 40.0, sr) + 0.6 * synth.resonator(pulse, f * 1.47, 30.0, sr)
    return synth.normalise(ring * synth.percussive(m, 0.03, sr, curve=1.4))


def glass_ping(gen: np.random.Generator, sr: int) -> np.ndarray:
    """Cooling stormglass: a bell-like inharmonic ping with a long tail."""
    m = int(1.2 * sr)
    f = gen.uniform(1800.0, 3600.0)
    tone = sum(a * synth.sine(f * r, sr, m) for r, a in ((1.0, 1.0), (2.76, 0.5), (5.40, 0.25)))
    return synth.normalise(tone * synth.percussive(m, 0.5, sr, attack_s=0.002, curve=1.2))


def crackle(n: int, sr: int, gen: np.random.Generator, density_hz: float,
            density_env: np.ndarray | None = None) -> np.ndarray:
    """Electrical crackle: sparse impulses, high-passed, randomly signed."""
    p = density_hz / sr
    if density_env is not None:
        p = p * density_env
    hits = (gen.random(n) < p).astype(np.float64) * gen.choice([-1.0, 1.0], n) * gen.uniform(0.3, 1.0, n)
    # Each impulse gets a ~2 ms ring so it reads as a spark, not a digital click.
    kernel = np.exp(-np.arange(int(0.002 * sr)) / (0.0006 * sr)) * synth.white(int(0.002 * sr), gen)
    out = np.convolve(hits, kernel)[:n]
    return synth.normalise(synth.highpass_fft(out, 1500.0, sr))


def rms_db(x: np.ndarray) -> float:
    return 20.0 * np.log10(max(np.sqrt(np.mean(x * x)), 1e-12))


def finish_bed(asset: str, x: np.ndarray) -> np.ndarray:
    looped = synth.seamless_loop(x, CROSSFADE_S, SR_BED)
    looped = looped - np.mean(looped)
    target = BED_RMS_DB[asset]
    out = looped * synth.db_to_amp(target - rms_db(looped))
    peak = np.max(np.abs(out))
    ceiling = synth.db_to_amp(BED_PEAK_CEILING_DB)
    if peak > ceiling:
        # tanh-shape only the rare peaks above the ceiling, keeping the RMS.
        out = np.tanh(out / ceiling) * ceiling
    _log(asset, f"equal-power seamless loop crossfade {CROSSFADE_S} s; DC removed; "
                f"scaled to {target} dBFS RMS with a {BED_PEAK_CEILING_DB} dBFS tanh peak ceiling")
    return out


def finish_fx(asset: str, x: np.ndarray, fade_out_s: float) -> np.ndarray:
    x = x - np.mean(x)
    m = int(fade_out_s * SR_FX)
    if m:
        x[-m:] *= np.linspace(1.0, 0.0, m)
    _log(asset, f"DC removed; {fade_out_s} s linear tail fade; peak-normalised to {FX_PEAK_DB[asset]} dBFS")
    return synth.at_db(x, FX_PEAK_DB[asset])


# --- the five beds -----------------------------------------------------------


def _bed_canvas() -> int:
    return int((BED_S + CROSSFADE_S) * SR_BED)


def surge_calm_bed(gen: np.random.Generator) -> np.ndarray:
    """Calm: rain/drip, low moss/forest life, distant thunder with long spacing."""
    a, sr, n = "surge_calm_bed", SR_BED, _bed_canvas()
    t = np.arange(n) / sr
    rain = synth.band(installed_layer("assets/audio/ambience/river_water.wav", a, n, sr, 1.35), 900.0, 7000.0, sr)
    _log(a, "river_water.wav at 1.35x speed, band-passed 900-7000 Hz -> steady rain wash")
    canopy = installed_layer("assets/audio/ambience/ironwood_canopy.wav", a, n, sr, 0.85, 3.0)
    _log(a, "ironwood_canopy.wav at 0.85x speed, offset 3 s -> low wet canopy")
    life = synth.lowpass_fft(installed_layer("assets/audio/ambience/night_insects.wav", a, n, sr, 0.7), 2500.0, sr)
    _log(a, "night_insects.wav at 0.7x speed, low-passed 2.5 kHz -> low moss/forest life")
    drips = synth.scatter(n, lambda g: drip(g, sr), 70, gen, (0.2, 0.7), wrap=True)
    _log(a, "70 synth drips (resonant pings 1.4-3.2 kHz), wrap-scattered")
    thunder = np.zeros(n)
    for at_s in (4.5, 16.8):
        roll = rolling_thunder(int(6.0 * sr), sr, gen, 140.0, 0.9, 6.0)
        synth.place(thunder, roll, int(at_s * sr))
    _log(a, "two distant thunder rolls (brown noise 30-140 Hz, 6 s) at 4.5 s and 16.8 s -> long spacing")
    sway = 0.8 + 0.2 * np.sin(2 * np.pi * t / 9.7)
    return finish_bed(a, synth.mix(1.0 * synth.normalise(rain) * sway, 0.45 * synth.normalise(canopy),
                                   0.18 * synth.normalise(life), 0.22 * drips, 0.55 * thunder))


def surge_building_bed(gen: np.random.Generator) -> np.ndarray:
    """Building: copper-vine ticks, canopy motion, rising electrical bed; no strike, no life."""
    a, sr, n = "surge_building_bed", SR_BED, _bed_canvas()
    t = np.arange(n) / sr
    canopy = installed_layer("assets/audio/ambience/ironwood_canopy.wav", a, n, sr, 1.15)
    wind = installed_layer("assets/audio/ambience/wind_high.wav", a, n, sr, 1.1, 5.0)
    motion = 0.55 + 0.45 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 6.1)) ** 1.5
    _log(a, "ironwood_canopy.wav 1.15x + wind_high.wav 1.1x (offset 5 s), gust-modulated -> increasing canopy motion")
    drone = installed_layer("assets/audio/ambience/tether_drone.wav", a, n, sr, 1.6)
    drone = synth.band(drone, 120.0, 3000.0, sr)
    # Rising pulses that swell over ~4 s and reset under the next one: the
    # bed reads as "rising" without a ramp that would break the loop.
    swell = np.zeros(n)
    period = int(4.0 * sr)
    ramp = np.linspace(0.2, 1.0, period) ** 2
    for start in range(0, n, period):
        swell[start:start + period] = ramp[: n - start]
    swell = synth.lowpass_fft(swell, 3.0, sr, order=1.0)
    hum = synth.sine(100.0 + 6.0 * np.sin(2 * np.pi * t / 4.0), sr, n) + 0.4 * synth.sine(200.0, sr, n)
    _log(a, "tether_drone.wav 1.6x band-passed 120-3000 Hz + 100/200 Hz synth hum, 4 s rising swells -> rising electrical bed")
    ticks = synth.scatter(n, lambda g: copper_tick(g, sr), 160, gen, (0.3, 1.0), wrap=True)
    _log(a, "160 synth copper-vine ticks (2.6-4.2 kHz inharmonic resonators), wrap-scattered")
    sparks = crackle(n, sr, gen, 9.0, swell)
    _log(a, "electrical crackle (~9 impulses/s scaled by swell, HP 1.5 kHz); no birds/insects, no strike")
    return finish_bed(a, synth.mix(0.6 * synth.normalise(canopy) * motion, 0.4 * synth.normalise(wind) * motion,
                                   0.55 * synth.normalise(drone) * (0.4 + 0.6 * swell), 0.25 * hum * swell,
                                   0.7 * ticks, 0.2 * sparks))


def surge_break_bed(gen: np.random.Generator) -> np.ndarray:
    """Break: heavy rain, driven wind, constant electrical pressure and thunder."""
    a, sr, n = "surge_break_bed", SR_BED, _bed_canvas()
    t = np.arange(n) / sr
    rain = synth.band(installed_layer("assets/audio/ambience/river_water.wav", a, n, sr, 1.8, 7.0), 1200.0, 9000.0, sr)
    rain2 = synth.band(synth.pink(n, gen), 2000.0, 9500.0, sr)
    _log(a, "river_water.wav 1.8x (offset 7 s) band-passed 1.2-9 kHz + synth pink 2-9.5 kHz -> heavy rain")
    wind = installed_layer("assets/audio/ambience/wind_low.wav", a, n, sr, 1.3)
    wind_hi = installed_layer("assets/audio/ambience/wind_high.wav", a, n, sr, 0.9, 11.0)
    gust = 0.5 + 0.5 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 3.3)) ** 1.8
    _log(a, "wind_low.wav 1.3x + wind_high.wav 0.9x (offset 11 s), 3.3 s gusts -> driven wind")
    drone = synth.band(installed_layer("assets/audio/ambience/tether_drone.wav", a, n, sr, 2.0), 150.0, 4000.0, sr)
    sparks = crackle(n, sr, gen, 30.0)
    _log(a, "tether_drone.wav 2.0x band-passed 150-4000 Hz + crackle ~30/s -> electrical pressure")
    thunder = np.zeros(n)
    for at_s in (1.0, 7.5, 13.0, 19.5):
        synth.place(thunder, rolling_thunder(int(5.0 * sr), sr, gen, 220.0, 0.25, 5.0), int(at_s * sr))
    rumble = synth.band(synth.brown(n, gen), 30.0, 90.0, sr)
    _log(a, "four rolling thunder beds (brown 30-220 Hz, 5 s) + continuous brown 30-90 Hz under-rumble; "
            "the strike chain carries every actual strike")
    return finish_bed(a, synth.mix(0.8 * synth.normalise(rain), 0.45 * synth.normalise(rain2),
                                   0.55 * synth.normalise(wind) * gust, 0.3 * synth.normalise(wind_hi) * gust,
                                   0.35 * synth.normalise(drone), 0.25 * sparks, 0.6 * thunder,
                                   0.35 * synth.normalise(rumble)))


def surge_fading_decay(gen: np.random.Generator) -> np.ndarray:
    """Fading: no strikes; steam, glass and low rolling thunder decay; afterglow hum."""
    a, sr, n = "surge_fading_decay", SR_BED, _bed_canvas()
    t = np.arange(n) / sr
    steam = synth.highpass_fft(installed_layer("assets/audio/ambience/wind_high.wav", a, n, sr, 1.9, 2.0), 3000.0, sr)
    breath = (0.5 + 0.5 * np.sin(2 * np.pi * t / 5.7)) ** 2
    _log(a, "wind_high.wav 1.9x (offset 2 s) high-passed 3 kHz, 5.7 s breathing -> steam hiss")
    glass = synth.scatter(n, lambda g: glass_ping(g, sr), 26, gen, (0.3, 1.0), wrap=True)
    _log(a, "26 synth stormglass pings (inharmonic 1/2.76/5.40 partials, 1.8-3.6 kHz), wrap-scattered")
    thunder = np.zeros(n)
    for at_s in (0.0, 12.0):
        synth.place(thunder, rolling_thunder(int(9.0 * sr), sr, gen, 110.0, 1.5, 9.0), int(at_s * sr))
    _log(a, "two long low thunder rolls (brown 30-110 Hz, 9 s) -> rolling thunder decay")
    glow = synth.lowpass_fft(installed_layer("assets/audio/ambience/tether_drone.wav", a, n, sr, 0.75), 600.0, sr)
    _log(a, "tether_drone.wav 0.75x low-passed 600 Hz -> charged-node afterglow")
    drips = synth.scatter(n, lambda g: drip(g, sr), 40, gen, (0.15, 0.5), wrap=True)
    _log(a, "40 synth drips")
    return finish_bed(a, synth.mix(0.35 * synth.normalise(steam) * (0.3 + 0.7 * breath), 0.35 * glass,
                                   0.75 * thunder, 0.3 * synth.normalise(glow), 0.15 * drips))


def release_forest_sky_bed(gen: np.random.Generator) -> np.ndarray:
    """Stormheart release: ordinary forest and sky; no rod-line bed, no electricity."""
    a, sr, n = "release_forest_sky_bed", SR_BED, _bed_canvas()
    birds = installed_layer("assets/audio/ambience/meadow_birds.wav", a, n, sr, 0.92, 6.0)
    _log(a, "meadow_birds.wav 0.92x (offset 6 s) -> returning forest birds, a shade lower than Meadows")
    canopy = installed_layer("assets/audio/ambience/ironwood_canopy.wav", a, n, sr, 1.0, 9.0)
    _log(a, "ironwood_canopy.wav 1.0x (offset 9 s) -> settled canopy")
    sky = synth.lowpass_fft(installed_layer("assets/audio/ambience/wind_high.wav", a, n, sr, 0.8), 2500.0, sr)
    _log(a, "wind_high.wav 0.8x low-passed 2.5 kHz -> open sky air")
    drips = synth.scatter(n, lambda g: drip(g, sr), 30, gen, (0.1, 0.4), wrap=True)
    _log(a, "30 synth drips -> the last of the rain; no drone, crackle or thunder")
    return finish_bed(a, synth.mix(0.7 * synth.normalise(birds), 0.55 * synth.normalise(canopy),
                                   0.35 * synth.normalise(sky), 0.12 * drips))


# --- the four strike layers --------------------------------------------------


def strike_warning(gen: np.random.Generator) -> np.ndarray:
    """1.2 s spatial warning: a charge that rises to the impact moment."""
    a, sr = "strike_warning", SR_FX
    n = int(1.2 * sr)
    t = np.arange(n) / sr
    rise = (t / 1.2) ** 1.6
    whine = synth.sine(350.0 + 1450.0 * rise, sr, n) * (0.15 + 0.85 * rise)
    _log(a, "synth whine glide 350 -> 1800 Hz over 1.2 s, power-curve rise")
    drone_raw, dsr = load_installed("assets/audio/ambience/tether_drone.wav", a)
    seg = drone_raw[: int(1.6 * dsr)]
    speed = np.interp(np.arange(n), [0, n - 1], [1.5, 4.0])
    pos = np.cumsum(speed * dsr / sr)
    drone = np.interp(np.clip(pos, 0, len(seg) - 1), np.arange(len(seg)), seg)
    drone = synth.highpass_fft(drone, 200.0, sr)
    _log(a, "tether_drone.wav first 1.6 s, varispeed 1.5x -> 4.0x, high-passed 200 Hz -> charging buzz")
    sparks = crackle(n, sr, gen, 120.0, 0.05 + rise ** 2)
    _log(a, "crackle ~120 impulses/s scaled by rise^2 -> densifying sparks")
    fizz = synth.band(synth.white(n, gen), 3000.0, 12000.0, sr) * rise ** 3
    _log(a, "white noise 3-12 kHz, cubic swell -> final sizzle at ground point")
    attack = np.minimum(1.0, t / 0.05)
    x = synth.mix(0.35 * synth.normalise(whine), 0.4 * synth.normalise(drone) * rise, 0.5 * sparks,
                  0.3 * synth.normalise(fizz)) * attack
    return finish_fx(a, x, 0.004)


def strike_crack(gen: np.random.Generator) -> np.ndarray:
    """The strike: a sharp broadband crack with a few re-strikes."""
    a, sr = "strike_crack", SR_FX
    n = int(0.7 * sr)
    burst = synth.white(n, gen) * synth.percussive(n, 0.07, sr, attack_s=0.0003, curve=1.6)
    for at_ms, g in ((18, 0.7), (41, 0.5), (77, 0.35)):
        m = int(0.04 * sr)
        synth.place(burst, synth.white(m, gen) * synth.percussive(m, 0.012, sr, attack_s=0.0002), int(at_ms * sr / 1000), g)
    burst = synth.highpass_fft(burst, 700.0, sr)
    _log(a, "white noise 0.3 ms attack / 70 ms decay + re-strikes at 18/41/77 ms, high-passed 700 Hz")
    impact, isr = load_installed("assets/audio/sfx/impact_super_1.wav", a)
    impact = synth.highpass_fft(resample(impact, isr, sr, 1.6), 400.0, sr)
    _log(a, "impact_super_1.wav 1.6x speed, high-passed 400 Hz -> hard body to the crack")
    snap, ssr = load_installed("assets/audio/sfx/mine_stone_2.wav", a)
    snap = resample(snap, ssr, sr, 1.3)
    _log(a, "mine_stone_2.wav 1.3x speed -> splintering edge")
    return finish_fx(a, synth.mix(1.0 * synth.normalise(burst), 0.55 * synth.normalise(impact),
                                  0.3 * synth.normalise(snap))[:n], 0.03)


def strike_body(gen: np.random.Generator) -> np.ndarray:
    """The body: a low boom under the crack."""
    a, sr = "strike_body", SR_FX
    n = int(1.8 * sr)
    t = np.arange(n) / sr
    boom = synth.band(synth.brown(n, gen), 30.0, 220.0, sr) * synth.percussive(n, 0.7, sr, attack_s=0.006, curve=0.9)
    _log(a, "brown noise band-passed 30-220 Hz, 6 ms attack / 0.7 s decay -> boom")
    sub = synth.sine(70.0 * np.exp(-t / 0.6) + 32.0, sr, n) * synth.percussive(n, 0.9, sr, attack_s=0.004)
    _log(a, "synth sub sine sweep 102 -> 32 Hz, 0.9 s decay")
    thud, tsr = load_installed("assets/audio/sfx/build_place_thud_1.wav", a)
    thud = synth.lowpass_fft(resample(thud, tsr, sr, 0.45), 600.0, sr)
    _log(a, "build_place_thud_1.wav 0.45x speed, low-passed 600 Hz -> ground hit")
    impact, isr = load_installed("assets/audio/sfx/impact_super_2.wav", a)
    impact = synth.lowpass_fft(resample(impact, isr, sr, 0.5), 900.0, sr)
    _log(a, "impact_super_2.wav 0.5x speed, low-passed 900 Hz")
    return finish_fx(a, synth.mix(1.0 * synth.normalise(boom), 0.7 * synth.normalise(sub),
                                  0.5 * synth.normalise(thud), 0.35 * synth.normalise(impact))[:n], 0.25)


def strike_decay(gen: np.random.Generator) -> np.ndarray:
    """The decay: thunder rolling away from the strike point."""
    a, sr = "strike_decay", SR_FX
    n = int(5.0 * sr)
    roll = rolling_thunder(n, sr, gen, 160.0, 0.35, 5.0)
    _log(a, "rolling thunder: brown noise 30-160 Hz, 3-5 overlapping swells, 5 s")
    wind, wsr = load_installed("assets/audio/ambience/wind_low.wav", a)
    wind = synth.band(resample(wind[: int(3.0 * wsr)], wsr, sr, 0.6), 30.0, 300.0, sr)[:n]
    wind = wind * synth.percussive(len(wind), 2.0, sr, attack_s=0.2)
    _log(a, "wind_low.wav first 3 s at 0.6x speed, band-passed 30-300 Hz, 2 s decay -> air push after the roll")
    x = synth.mix(1.0 * roll, 0.4 * synth.normalise(wind))[:n]
    x *= np.minimum(1.0, np.arange(n) / (0.02 * sr))
    return finish_fx(a, x, 0.8)


ASSETS = [
    ("surge_calm_bed", surge_calm_bed, SR_BED, True, 7101),
    ("surge_building_bed", surge_building_bed, SR_BED, True, 7102),
    ("surge_break_bed", surge_break_bed, SR_BED, True, 7103),
    ("surge_fading_decay", surge_fading_decay, SR_BED, True, 7104),
    ("release_forest_sky_bed", release_forest_sky_bed, SR_BED, True, 7105),
    ("strike_warning", strike_warning, SR_FX, False, 7201),
    ("strike_crack", strike_crack, SR_FX, False, 7202),
    ("strike_body", strike_body, SR_FX, False, 7203),
    ("strike_decay", strike_decay, SR_FX, False, 7204),
]


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_manifest(outputs: dict[str, Path]) -> Path:
    rows = []
    for name, _fn, sr, loop, seed in ASSETS:
        out = outputs[name]
        rows.append({
            "asset": f"res://assets/audio/stormwood/{name}.wav",
            "format": {"sample_rate_hz": sr, "channels": 1, "bits": 16, "loop": "smpl forward, whole clip" if loop else "none"},
            "seed": seed,
            "installed_sources": [{"path": rel, "sha256": _sha(REPO / rel)} for rel in sorted(_sources.get(name, ()))],
            "synthesis": "tools/audio/synth.py (project-owned)",
            "steps": _steps.get(name, []),
            "sha256": _sha(out),
        })
    manifest = {
        "generator": "tools/audio/gen_stormwood.py",
        "authority": "Owner decision 2026-10-05: author the nine Stormwood WAVs from sound sources already installed in the repository (AUDIO §10); no purchase, download or text-to-audio service.",
        "licence": "Original project work. Every installed source is itself original synthesis by tools/audio/ (archive/docs/specs-2026-09-19/ASSET_LEDGER.md, Meadows soundscape row); no third-party licence attaches.",
        "regenerate": "python3 tools/audio/gen_stormwood.py  (deterministic; byte-identical with no source change)",
        "assets": rows,
    }
    path = OUT / "MANIFEST.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return path


def main() -> None:
    outputs: dict[str, Path] = {}
    for name, fn, sr, loop, seed in ASSETS:
        _seeds[name] = seed
        samples = fn(synth.rng(seed))
        outputs[name] = synth.write_wav(OUT / f"{name}.wav", samples, sr, loop=loop)
        print(f"  {name}.wav  {len(samples) / sr:5.2f} s  {sr} Hz  loop={loop}")
    print(f"  {write_manifest(outputs).relative_to(REPO)}")


if __name__ == "__main__":
    main()
