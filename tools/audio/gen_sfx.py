#!/usr/bin/env python3
"""World-verb and combat one-shots.

Run: `python3 tools/audio/gen_sfx.py` (or `gen_all.py` for everything).

44100 Hz mono, because unlike the ambience beds these are transients and the
first two milliseconds -- the part that says wood or stone or flesh -- lives
above 11 kHz. See `synth.SR_SFX`.

## Variation is the whole job

A footstep is heard several thousand times an hour. One footstep file played
several thousand times is the single most fatiguing thing a game can do, and no
amount of quality in that one file fixes it. So every verb that repeats ships a
SET of variants, generated from the same recipe with different seeds, and
`AudioManager` picks one at random while refusing to repeat the last (see
`pick_variant` there). Pitch is additionally jittered at play time, which
multiplies the set out further for free.

Three or four variants plus pitch jitter is the point of diminishing returns;
past that the ear cannot tell anyway.

## How a material is made to read

Every impact here is the same two ingredients in different proportions:
a noise burst (the strike) and a resonant ring (the object). Grass is almost all
noise with a fast tail; stone is a tight click plus a high, short ring; wood is
a softer click plus a low, longer ring; water adds a rising pitch sweep, which
is the one cue the ear reads as unambiguously wet.
"""

from __future__ import annotations

import numpy as np

import synth
from synth import SR_SFX as SR

OUT = synth.ASSETS / "sfx"


def _hit(gen: np.random.Generator, *, noise_lo: float, noise_hi: float,
         noise_decay: float, noise_curve: float, ring_hz: float, ring_q: float,
         ring_decay: float, ring_mix: float, duration: float) -> np.ndarray:
    """The shared impact recipe: a filtered noise burst plus a resonant ring.

    Kept as one function with parameters rather than five near-identical
    functions because the differences between materials genuinely ARE these
    numbers, and having them side by side in the callers below is what makes
    "stone is brighter and shorter than wood" legible as code.
    """
    n = int(duration * SR)
    burst = synth.band(synth.white(n, gen), noise_lo, noise_hi, SR, order=1.5)
    burst *= synth.percussive(n, noise_decay, SR, attack_s=0.0004, curve=noise_curve)

    ring = synth.resonator(synth.white(n, gen), ring_hz, ring_q, SR)
    ring *= synth.percussive(n, ring_decay, SR, attack_s=0.0008)

    out = synth.mix(burst * (1.0 - ring_mix), synth.normalise(ring) * ring_mix)
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


# --- footsteps ---------------------------------------------------------------
#
# Four surfaces. `world_audio.gd` chooses between them from the ground material
# under the player; `data/config/audio.json` maps material names to these sets.


def step_grass(gen: np.random.Generator) -> np.ndarray:
    """Soft, broadband, no ring at all -- grass and soil do not resonate."""
    return _hit(
        gen,
        noise_lo=200.0, noise_hi=6500.0,
        noise_decay=0.045, noise_curve=0.75,
        ring_hz=180.0, ring_q=0.8, ring_decay=0.02, ring_mix=0.12,
        duration=0.16,
    )


def step_stone(gen: np.random.Generator) -> np.ndarray:
    """Tight, bright, short. The high ring is the whole identity."""
    return _hit(
        gen,
        noise_lo=700.0, noise_hi=13000.0,
        noise_decay=0.012, noise_curve=1.7,
        ring_hz=gen.uniform(1500.0, 2400.0), ring_q=6.0, ring_decay=0.05, ring_mix=0.40,
        duration=0.14,
    )


def step_wood(gen: np.random.Generator) -> np.ndarray:
    """A hollow knock: softer strike, lower and longer ring than stone.

    For the farmhouse, the mill, and every plank the player builds.
    """
    return _hit(
        gen,
        noise_lo=300.0, noise_hi=7000.0,
        noise_decay=0.02, noise_curve=1.2,
        ring_hz=gen.uniform(320.0, 520.0), ring_q=4.5, ring_decay=0.09, ring_mix=0.45,
        duration=0.2,
    )


def step_water(gen: np.random.Generator) -> np.ndarray:
    """A splash: broadband burst plus the rising sweep that reads as wet.

    The sweep direction is doing real work here -- see `river_water`'s bubble in
    gen_ambience.py for the same cue and the same reason.
    """
    n = int(0.28 * SR)
    burst = synth.band(synth.white(n, gen), 400.0, 9000.0, SR, order=1.5)
    burst *= synth.percussive(n, 0.07, SR, attack_s=0.001, curve=0.7)

    m = int(0.09 * SR)
    start = gen.uniform(500.0, 900.0)
    sweep = np.linspace(start, start * 2.2, m)
    blip = synth.sine(sweep, SR, m) * synth.percussive(m, 0.03, SR, attack_s=0.002)

    out = synth.mix(burst, np.concatenate([np.zeros(int(0.01 * SR)), blip * 0.5]))
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


# --- gathering verbs ---------------------------------------------------------


def chop_wood(gen: np.random.Generator) -> np.ndarray:
    """An axe into a trunk. A hard transient, then the trunk's low body."""
    n = int(0.45 * SR)
    bite = synth.band(synth.white(n, gen), 600.0, 11000.0, SR, order=1.8)
    bite *= synth.percussive(n, 0.02, SR, attack_s=0.0003, curve=1.5)

    body = synth.resonator(synth.white(n, gen), gen.uniform(150.0, 230.0), 5.0, SR)
    body *= synth.percussive(n, 0.13, SR, attack_s=0.002)

    # A quiet creak of fibres letting go, offset a little so it reads as a
    # consequence of the strike rather than part of it.
    m = int(0.2 * SR)
    base = gen.uniform(240.0, 340.0)
    tear = synth.sine(np.linspace(base, base * 0.82, m), SR, m)
    tear *= synth.percussive(m, 0.08, SR, attack_s=0.02)

    out = synth.mix(bite * 0.75, synth.normalise(body) * 0.55,
                    np.concatenate([np.zeros(int(0.05 * SR)), tear * 0.18]))
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


def mine_stone(gen: np.random.Generator) -> np.ndarray:
    """A pick into rock: metallic strike, high ring, and grit falling after."""
    n = int(0.5 * SR)
    strike = synth.band(synth.white(n, gen), 1200.0, 15000.0, SR, order=2.0)
    strike *= synth.percussive(n, 0.01, SR, attack_s=0.0002, curve=2.0)

    ring = synth.resonator(synth.white(n, gen), gen.uniform(2400.0, 3600.0), 9.0, SR)
    ring *= synth.percussive(n, 0.08, SR, attack_s=0.0006)

    def grit(g: np.random.Generator) -> np.ndarray:
        m = int(g.uniform(0.006, 0.018) * SR)
        return synth.highpass_fft(
            synth.white(m, g) * synth.percussive(m, 0.004, SR, attack_s=0.0003, curve=1.6),
            2500.0, SR)

    # Only in the tail: grit falls after the strike, never with it.
    debris = np.zeros(n)
    tail_start = int(0.09 * SR)
    scattered = synth.scatter(n - tail_start, grit, 14, gen, gain_range=(0.1, 0.45))
    synth.place(debris, scattered, tail_start)

    out = synth.mix(strike * 0.7, synth.normalise(ring) * 0.5, debris * 0.35)
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


def gather_plant(gen: np.random.Generator) -> np.ndarray:
    """Pulling a plant: a rustle with a soft snap in it. No ring anywhere."""
    n = int(0.3 * SR)
    rustle = synth.band(synth.white(n, gen), 900.0, 9000.0, SR, order=1.3)
    # Gated by noise rather than a smooth envelope: tearing is irregular, and a
    # smooth decay here reads as a cymbal.
    gate = np.abs(synth.lowpass_fft(synth.white(n, gen), 45.0, SR))
    gate = synth.normalise(gate) * synth.percussive(n, 0.09, SR, attack_s=0.004, curve=0.8)
    rustle *= gate

    m = int(0.05 * SR)
    snap = synth.white(m, gen) * synth.percussive(m, 0.006, SR, attack_s=0.0004, curve=1.4)
    snap = synth.band(snap, 1400.0, 8000.0, SR)

    out = synth.mix(rustle, np.concatenate([np.zeros(int(0.04 * SR)), snap * 0.5]))
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


def pickup_item(gen: np.random.Generator) -> np.ndarray:
    """Something goes in the satchel. Deliberately musical, not physical.

    Picking things up is a REWARD, and the player does it constantly; a
    realistic cloth-and-clink would be both duller and more fatiguing. Two
    quick rising notes a fifth apart, which is the shortest phrase that reads
    as "yes" rather than as a beep.
    """
    n = int(0.22 * SR)
    root = 880.0
    first = synth.sine(root, SR, n) * synth.percussive(n, 0.05, SR, attack_s=0.002, curve=1.2)
    second = synth.sine(root * 1.5, SR, n) * synth.percussive(n, 0.07, SR, attack_s=0.002, curve=1.2)
    # A touch of second harmonic keeps it from sounding like a sine test tone.
    # Folded into the same `mix` as the notes rather than added afterwards --
    # `mix` pads to the longest layer, and the delayed second note makes the
    # result longer than `n`.
    harmonic = synth.sine(root * 2.0, SR, n) * synth.percussive(n, 0.04, SR, attack_s=0.002)
    out = synth.mix(
        first * 0.6,
        np.concatenate([np.zeros(int(0.045 * SR)), second * 0.6]),
        harmonic * 0.15,
    )
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


def craft_done(gen: np.random.Generator) -> np.ndarray:
    """A crafted item completes: a three-note rise, warmer than `pickup_item`."""
    n = int(0.45 * SR)
    out = np.zeros(n)
    # A major triad, arpeggiated upward. Same "yes" grammar as pickup but longer
    # and lower, so the two are not confusable in a busy moment at a bench.
    for i, ratio in enumerate([1.0, 1.26, 1.5]):
        m = int(0.28 * SR)
        note = synth.sine(523.25 * ratio, SR, m)
        note += 0.3 * synth.sine(523.25 * ratio * 2.0, SR, m)
        note *= synth.percussive(m, 0.09, SR, attack_s=0.004, curve=1.1)
        synth.place(out, note, int(i * 0.075 * SR), 0.5)
    return synth.fade_edges(synth.normalise(out), 0.005, SR)


# --- combat ------------------------------------------------------------------
#
# `world_audio.gd` subscribes to combat_manager.gd's existing signals for all of
# these; nothing in the combat code needed changing to make them play.


def _impact(gen: np.random.Generator, *, weight: float, bright: float,
            duration: float) -> np.ndarray:
    """A creature attack landing.

    `weight` moves the body resonance down and lengthens it; `bright` moves the
    strike's noise band up. The three effectiveness tiers below are the same
    recipe at three settings, on purpose -- the player has to hear them as three
    strengths of ONE event, not as three unrelated sounds.
    """
    n = int(duration * SR)
    strike = synth.band(synth.white(n, gen), 300.0 * bright, 9000.0 * bright, SR, order=1.6)
    strike *= synth.percussive(n, 0.02 * weight, SR, attack_s=0.0003, curve=1.4)

    body = synth.resonator(synth.white(n, gen), 150.0 / weight, 3.0, SR)
    body *= synth.percussive(n, 0.07 * weight, SR, attack_s=0.001)

    thump = synth.lowpass_fft(synth.brown(n, gen), 160.0, SR)
    thump *= synth.percussive(n, 0.05 * weight, SR, attack_s=0.001)

    out = synth.mix(strike * 0.55, synth.normalise(body) * 0.45,
                    synth.normalise(thump) * 0.5 * weight)
    return synth.fade_edges(synth.normalise(synth.soft_clip(out * 1.3)), 0.004, SR)


def impact_weak(gen: np.random.Generator) -> np.ndarray:
    """Not very effective: light, dull, and short. It should feel like a waste."""
    return _impact(gen, weight=0.7, bright=0.75, duration=0.22)


def impact_normal(gen: np.random.Generator) -> np.ndarray:
    return _impact(gen, weight=1.0, bright=1.0, duration=0.3)


def impact_super(gen: np.random.Generator) -> np.ndarray:
    """Super effective. Heavier and brighter, plus a bright ringing overtone.

    The extra layer, rather than just more volume, is deliberate: loudness alone
    is what a mix engineer removes later, and the cue has to survive that.
    """
    base = _impact(gen, weight=1.5, bright=1.35, duration=0.45)
    n = len(base)
    m = int(0.18 * SR)
    shine = synth.sine(np.linspace(1800.0, 2600.0, m), SR, m)
    shine += 0.5 * synth.sine(np.linspace(2700.0, 3900.0, m), SR, m)
    shine *= synth.percussive(m, 0.06, SR, attack_s=0.001)
    out = np.zeros(n)
    out[:] = base
    synth.place(out, shine, int(0.01 * SR), 0.3)
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


def damage_taken(gen: np.random.Generator) -> np.ndarray:
    """The player's own creature is hit. Muffled, lower, and a little sickening.

    Distinct from the impact set on purpose: in a real-time fight the single
    most important thing the mix must carry is WHO just got hit.
    """
    n = int(0.35 * SR)
    thud = synth.lowpass_fft(synth.brown(n, gen), 400.0, SR)
    thud *= synth.percussive(n, 0.06, SR, attack_s=0.001, curve=0.9)

    # A short downward glide: the universal "that was bad" cue.
    m = int(0.22 * SR)
    fall = synth.sine(np.linspace(420.0, 190.0, m), SR, m)
    fall *= synth.percussive(m, 0.09, SR, attack_s=0.004)

    out = synth.mix(synth.normalise(thud) * 0.7, fall * 0.35)
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


def faint(gen: np.random.Generator) -> np.ndarray:
    """A creature goes down. The longest, saddest cue in the set.

    D40 makes fainting cost a revive, so this is a real loss and should land
    like one: a slow fall through more than an octave, with the body resonance
    following it down.
    """
    n = int(1.1 * SR)
    sweep = np.linspace(520.0, 130.0, n)
    tone = synth.sine(sweep, SR, n) + 0.4 * synth.sine(sweep * 2.0, SR, n)
    tone += 0.2 * synth.sine(sweep * 3.0, SR, n)
    tone *= synth.adsr(n, 0.02, 0.3, 0.45, 0.7, SR)

    air = synth.lowpass_fft(synth.pink(n, gen), 1200.0, SR)
    air *= synth.percussive(n, 0.4, SR, attack_s=0.01, curve=0.8)

    out = synth.mix(synth.normalise(tone) * 0.75, synth.normalise(air) * 0.25)
    return synth.fade_edges(synth.normalise(out), 0.01, SR)


def orb_throw(gen: np.random.Generator) -> np.ndarray:
    """The catch orb leaves the hand: a whoosh with a rising whine."""
    n = int(0.35 * SR)
    whoosh = synth.band(synth.white(n, gen), 400.0, 7000.0, SR, order=1.4)
    whoosh *= synth.percussive(n, 0.1, SR, attack_s=0.02, curve=0.8)

    m = int(0.25 * SR)
    whine = synth.sine(np.linspace(600.0, 1500.0, m), SR, m)
    whine *= synth.adsr(m, 0.03, 0.05, 0.6, 0.15, SR)

    out = synth.mix(whoosh * 0.5, whine * 0.3)
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


def orb_shake(gen: np.random.Generator) -> np.ndarray:
    """One shake of a landed orb. Played up to three times, tension rising.

    Kept SHORT and dry. `world_audio.gd` raises the pitch on each successive
    shake (combat_manager.gd's `orb_shook` carries the index), which is what
    turns three identical clicks into a question the player is waiting on.
    """
    n = int(0.16 * SR)
    click = synth.white(n, gen) * synth.percussive(n, 0.006, SR, attack_s=0.0003, curve=1.8)
    click = synth.band(click, 800.0, 6000.0, SR)
    ring = synth.resonator(synth.white(n, gen), 1100.0, 8.0, SR)
    ring *= synth.percussive(n, 0.04, SR, attack_s=0.001)
    out = synth.mix(click * 0.6, synth.normalise(ring) * 0.4)
    return synth.fade_edges(synth.normalise(out), 0.003, SR)


def catch_fail(gen: np.random.Generator) -> np.ndarray:
    """The orb breaks open. A snap, then a deflating downward sweep."""
    n = int(0.5 * SR)
    snap = synth.band(synth.white(n, gen), 900.0, 11000.0, SR, order=1.8)
    snap *= synth.percussive(n, 0.012, SR, attack_s=0.0003, curve=1.8)

    m = int(0.32 * SR)
    deflate = synth.sine(np.linspace(900.0, 280.0, m), SR, m)
    deflate *= synth.percussive(m, 0.14, SR, attack_s=0.006)

    out = synth.mix(snap * 0.6, np.concatenate([np.zeros(int(0.02 * SR)), deflate * 0.4]))
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


def ability_cue(gen: np.random.Generator) -> np.ndarray:
    """A move is committed: a short bright rising chirp, read as "here it comes".

    Deliberately in a frequency range nothing else in combat occupies, so it
    stays audible under impacts.
    """
    n = int(0.2 * SR)
    sweep = np.linspace(700.0, 1900.0, n)
    tone = synth.sine(sweep, SR, n) + 0.35 * synth.sine(sweep * 1.5, SR, n)
    tone *= synth.percussive(n, 0.06, SR, attack_s=0.003, curve=1.1)
    return synth.fade_edges(synth.normalise(tone), 0.003, SR)


def attack_miss(gen: np.random.Generator) -> np.ndarray:
    """A swing through empty air. Pure filtered-noise whoosh, no strike at all.

    The absence of a transient IS the information; smoke_combat.gd already
    proves a swing can miss, and this is what makes that legible in play.
    """
    n = int(0.26 * SR)
    t = synth.t_axis(n / SR, SR)
    air = synth.white(n, gen)
    # Cutoff sweeps up then down across the swing: a body passing the ear.
    air = synth.band(air, 500.0, 5000.0, SR, order=1.2)
    air *= np.sin(np.pi * np.linspace(0.0, 1.0, n)) ** 1.5
    air *= 0.8 + 0.2 * np.sin(2.0 * np.pi * t * 30.0)
    return synth.fade_edges(synth.normalise(air), 0.005, SR)


def combat_start(gen: np.random.Generator) -> np.ndarray:
    """A fight begins: a low hit and a fast rising tension swell."""
    n = int(0.8 * SR)
    hit = synth.lowpass_fft(synth.brown(n, gen), 220.0, SR)
    hit *= synth.percussive(n, 0.12, SR, attack_s=0.001)

    m = int(0.6 * SR)
    swell = synth.band(synth.white(m, gen), 600.0, 6000.0, SR, order=1.4)
    swell *= np.linspace(0.0, 1.0, m) ** 2.0

    rise = synth.sine(np.linspace(180.0, 420.0, m), SR, m)
    rise *= np.linspace(0.0, 1.0, m) ** 1.6

    out = synth.mix(synth.normalise(hit) * 0.7, swell * 0.25, rise * 0.3)
    return synth.fade_edges(synth.normalise(out), 0.006, SR)


def combat_win(gen: np.random.Generator) -> np.ndarray:
    """The fight resolves in the player's favour. A short rising major figure."""
    n = int(0.9 * SR)
    out = np.zeros(n)
    for i, ratio in enumerate([1.0, 1.25, 1.5, 2.0]):
        m = int(0.5 * SR)
        note = synth.sine(392.0 * ratio, SR, m) + 0.35 * synth.sine(392.0 * ratio * 2.0, SR, m)
        note *= synth.percussive(m, 0.16, SR, attack_s=0.005, curve=1.0)
        synth.place(out, note, int(i * 0.085 * SR), 0.42)
    return synth.fade_edges(synth.normalise(out), 0.006, SR)


def build_place_thud(gen: np.random.Generator) -> np.ndarray:
    """A built piece lands in the world.

    `assets/ui/audio/build_place.wav` already exists and stays where it is -- it
    is the UI CONFIRMATION, on the UI bus. This is the physical event on the SFX
    bus: the same press produces a menu blip and a thing hitting the ground, and
    conflating them is why the existing one reads as weightless.
    """
    n = int(0.4 * SR)
    thud = synth.lowpass_fft(synth.brown(n, gen), 300.0, SR)
    thud *= synth.percussive(n, 0.07, SR, attack_s=0.001, curve=0.9)

    knock = synth.resonator(synth.white(n, gen), 380.0, 4.0, SR)
    knock *= synth.percussive(n, 0.06, SR, attack_s=0.001)

    settle = synth.band(synth.white(n, gen), 700.0, 6000.0, SR)
    settle *= synth.percussive(n, 0.03, SR, attack_s=0.002, curve=1.3)

    out = synth.mix(synth.normalise(thud) * 0.6, synth.normalise(knock) * 0.35, settle * 0.2)
    return synth.fade_edges(synth.normalise(out), 0.004, SR)


# --- registry ----------------------------------------------------------------
#
# `(generator, seed, variant_count, peak_db)`. A variant count above 1 writes
# `<name>_1.wav` .. `<name>_N.wav`; `AudioManager.play` takes the base name and
# picks between them. See this module's header on why the repeating verbs have
# variants and the one-per-fight cues do not.
#
# Peak levels are set per sound rather than normalised flat, and this table is
# the closest thing the project has to a mix sheet. Footsteps sit well below
# combat because the player generates them continuously and never needs to be
# told one happened; `faint` and `combat_start` sit at the top because they are
# rare and structural.

SOUNDS = {
    "step_grass": (step_grass, 2001, 4, -13.0),
    "step_stone": (step_stone, 2002, 4, -14.0),
    "step_wood": (step_wood, 2003, 3, -14.0),
    "step_water": (step_water, 2004, 3, -12.0),

    "chop_wood": (chop_wood, 2010, 3, -6.0),
    "mine_stone": (mine_stone, 2011, 3, -6.0),
    "gather_plant": (gather_plant, 2012, 3, -8.0),
    "pickup_item": (pickup_item, 2013, 1, -9.0),
    "craft_done": (craft_done, 2014, 1, -8.0),
    "build_place_thud": (build_place_thud, 2015, 2, -6.0),

    "impact_weak": (impact_weak, 2020, 3, -8.0),
    "impact_normal": (impact_normal, 2021, 3, -5.0),
    "impact_super": (impact_super, 2022, 3, -3.0),
    "damage_taken": (damage_taken, 2023, 3, -4.0),
    "attack_miss": (attack_miss, 2024, 3, -12.0),
    "faint": (faint, 2025, 1, -3.0),
    "ability_cue": (ability_cue, 2026, 2, -10.0),
    "orb_throw": (orb_throw, 2027, 2, -7.0),
    "orb_shake": (orb_shake, 2028, 2, -8.0),
    "catch_fail": (catch_fail, 2029, 1, -5.0),
    "combat_start": (combat_start, 2030, 1, -4.0),
    "combat_win": (combat_win, 2031, 1, -5.0),
}


def main() -> None:
    total = 0
    for name, (fn, seed, variants, peak_db) in SOUNDS.items():
        for i in range(variants):
            # Seed per variant, so adding a fifth footstep never reshuffles the
            # first four -- the committed .wav diff stays proportional to the
            # change that caused it.
            gen = synth.rng(seed * 100 + i)
            samples = synth.at_db(fn(gen), peak_db)
            stem = name if variants == 1 else f"{name}_{i + 1}"
            path = synth.write_wav(OUT / f"{stem}.wav", samples, SR)
            total += path.stat().st_size
    print(f"  {len(SOUNDS)} sounds, "
          f"{sum(v[2] for v in SOUNDS.values())} files, {total // 1024} KB")


if __name__ == "__main__":
    main()
