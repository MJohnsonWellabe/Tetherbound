#!/usr/bin/env python3
"""The chapter's five music cues.

Run: `python3 tools/audio/gen_music.py` (or `gen_all.py`).

The beats are named in `docs/GAME_VISION.md`, and each cue below
says which line of it that cue is answering. Nothing here is invented mood: the
Warden is "the culmination of the chapter" (§10), the release ceremony needs
"enough history to hurt" (§ Meadows Hall), and home "should remain emotionally
and mechanically relevant throughout" (§ home).

## What "written, not sourced" costs here

Ambience and impacts are cases where synthesis is as good as or better than a
sample library. Music is not one of them: these are five short loops built from
filtered oscillators, and they are a long way from a scored soundtrack. They are
here because a chapter with a wind bed, footsteps and no music at all still
reads as unfinished, and because a placeholder that fits the harmony and pacing
of the game is a better brief for a real composer than a silence.

Judged on their own terms -- do they carry the right feeling, in the right key,
at the right length, without fatiguing over an hour -- they are shippable. They
should be replaced.

## The shared musical language

One mode across all five, so the chapter sounds like one place: D dorian for
everything except the Warden and the drained approach, which flatten the second
degree to get the same instrument set to sound wrong. Reusing the mode rather
than modulating for each cue is the cheapest thing that makes five separately
generated pieces sound like they belong together.
"""

from __future__ import annotations

import numpy as np

import synth
from synth import SR_AMBIENCE as SR

OUT = synth.ASSETS / "music"

# Enough that a loop is not a phrase the player can hum along to by the second
# hearing, short enough to keep five of them affordable in memory.
LENGTH_S = 38.0
CROSSFADE_S = 3.0

# Semitone offsets from the root. Dorian is the pastoral-but-not-saccharine mode
# -- a natural minor with a raised sixth, which is why folk music lives in it.
DORIAN = [0, 2, 3, 5, 7, 9, 10]
# The Warden's mode: dorian with a flattened second. Same instruments, same
# root, unmistakably wrong.
PHRYGIAN = [0, 1, 3, 5, 7, 8, 10]

ROOT_HZ = 146.83  # D3


def note_hz(root: float, scale: list[int], degree: int, octave: int = 0) -> float:
    """Frequency of a scale degree, wrapping octaves. Degrees may be negative."""
    index = degree % len(scale)
    span = degree // len(scale)
    return root * (2.0 ** (octave + span)) * (2.0 ** (scale[index] / 12.0))


# --- instruments -------------------------------------------------------------


def pad(freq: float, duration: float, gen: np.random.Generator,
        brightness: float = 1.0) -> np.ndarray:
    """A soft sustained voice: three detuned saws through a low-pass.

    Detuning is what turns three oscillators into one wide instrument -- exactly
    the same beating trick `tether_drone` uses in gen_ambience.py, at a musical
    rather than an unsettling interval.
    """
    n = int(duration * SR)
    out = np.zeros(n)
    for detune in (0.997, 1.0, 1.004):
        phase = np.cumsum(np.full(n, freq * detune)) / SR
        out += 2.0 * (phase - np.floor(phase)) - 1.0
    out = synth.lowpass_fft(out / 3.0, 900.0 * brightness, SR, order=2.0)
    env = synth.adsr(n, duration * 0.25, duration * 0.2, 0.75, duration * 0.45, SR)
    return out * env


def pluck(freq: float, duration: float, gen: np.random.Generator) -> np.ndarray:
    """A plucked string, by Karplus-Strong.

    A short burst of noise in a delay line that averages itself each pass: the
    noise decays into a pitched tone whose harmonics die off from the top down,
    which is what a real string does and what no envelope on a sine achieves.
    Nine lines of code for the most convincing instrument in this file.
    """
    n = int(duration * SR)
    period = max(int(SR / freq), 2)
    buffer = gen.uniform(-1.0, 1.0, period)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buffer[i % period]
        # 0.996 sets the decay: lower is a duller, shorter string.
        buffer[i % period] = 0.996 * 0.5 * (buffer[i % period] + buffer[(i + 1) % period])
    return out * synth.percussive(n, duration * 0.4, SR, attack_s=0.002)


def bell(freq: float, duration: float, gen: np.random.Generator) -> np.ndarray:
    """A soft struck tone with inharmonic partials -- ceremony, not melody."""
    n = int(duration * SR)
    out = np.zeros(n)
    # Deliberately not integer multiples. Integer partials give an organ; these
    # ratios are roughly a struck metal bar's, which is what reads as a bell.
    for ratio, weight, decay in ((1.0, 1.0, 0.55), (2.76, 0.4, 0.3), (5.4, 0.2, 0.18)):
        out += synth.sine(freq * ratio, SR, n) * weight * \
            synth.percussive(n, duration * decay, SR, attack_s=0.004)
    return out / 1.6


def breath_pad(freq: float, duration: float, gen: np.random.Generator) -> np.ndarray:
    """A noise-based pad: resonated noise instead of oscillators.

    Airier and less present than `pad`; used where the music has to sit under
    dialogue or a fight without competing for the same frequencies.
    """
    n = int(duration * SR)
    source = synth.band(synth.white(n, gen), 200.0, 4000.0, SR)
    out = synth.resonator(source, freq, 14.0, SR)
    out += 0.5 * synth.resonator(source, freq * 2.0, 14.0, SR)
    env = synth.adsr(n, duration * 0.3, duration * 0.2, 0.8, duration * 0.4, SR)
    return synth.normalise(out) * env


def kick(duration: float, gen: np.random.Generator) -> np.ndarray:
    """A soft low drum: a pitch drop plus a click."""
    n = int(duration * SR)
    sweep = np.linspace(120.0, 45.0, n)
    body = synth.sine(sweep, SR, n) * synth.percussive(n, duration * 0.25, SR)
    click = synth.white(int(0.006 * SR), gen)
    click *= synth.percussive(len(click), 0.003, SR, attack_s=0.0002, curve=1.6)
    return synth.mix(body, click * 0.25)


# --- arrangement helpers -----------------------------------------------------


def canvas() -> np.ndarray:
    return np.zeros(int((LENGTH_S + CROSSFADE_S) * SR))


def bar(index: float, beat_s: float) -> int:
    return int(index * beat_s * SR)


def finish(track: np.ndarray, peak_db: float) -> np.ndarray:
    """Loop the seam and set the level. Same contract as the ambience layers."""
    looped = synth.seamless_loop(track, CROSSFADE_S, SR)
    return synth.at_db(synth.soft_clip(synth.normalise(looped) * 1.1), peak_db)


# --- the five cues -----------------------------------------------------------


def music_exploration(gen: np.random.Generator) -> np.ndarray:
    """The travelling bed. VISION §2's core loop -- curiosity, not urgency.

    Sparse on purpose: this plays in stretches over three hours (see audio.json's
    `_comment_silence`), so anything with a strong hook would become unbearable.
    A slow pad progression with an occasional plucked figure over it.
    """
    out = canvas()
    beat = 0.75

    # i - VII - IV - i, the plainest dorian loop there is. Four bars each.
    progression = [0, 6, 3, 0]
    for i, degree in enumerate(progression):
        at = bar(i * 8.0, beat)
        for interval in (0, 2, 4):
            voice = pad(note_hz(ROOT_HZ, DORIAN, degree + interval, 0),
                        beat * 8.4, gen, brightness=0.9)
            synth.place(out, voice, at, 0.3)
        # A bass note an octave down, on the bar.
        synth.place(out, pad(note_hz(ROOT_HZ, DORIAN, degree, -1), beat * 8.4, gen, 0.6),
                    at, 0.35)

    # A plucked melody over bars 2-3 and 6-7 only, so two of the four bars stay
    # open. The gaps are what keep this listenable on the twentieth pass.
    melody = [4, 6, 5, 4, 2, 4, 3, 2]
    for repeat, offset in enumerate((8.0, 24.0)):
        for i, degree in enumerate(melody):
            if gen.random() < 0.25:
                continue  # dropped notes: the phrase varies between repeats
            at = bar(offset + i * 1.0, beat)
            synth.place(out, pluck(note_hz(ROOT_HZ, DORIAN, degree, 1), beat * 1.8, gen),
                        at, 0.16 if repeat else 0.2)

    return finish(out, -12.0)


def music_village(gen: np.random.Generator) -> np.ndarray:
    """Home. VISION: home stays "emotionally and mechanically relevant".

    Warmer and more consonant than exploration, with a gentle repeating figure
    -- the one cue in the chapter that is allowed to be comforting and a little
    sentimental. Major-ish colour by leaning on the raised sixth that makes
    dorian dorian.
    """
    out = canvas()
    beat = 0.62

    progression = [0, 3, 5, 3]
    for i, degree in enumerate(progression):
        at = bar(i * 8.0, beat)
        for interval in (0, 2, 4):
            synth.place(out, pad(note_hz(ROOT_HZ, DORIAN, degree + interval, 0),
                                 beat * 8.4, gen, brightness=1.15), at, 0.26)
        synth.place(out, pad(note_hz(ROOT_HZ, DORIAN, degree, -1), beat * 8.4, gen, 0.7),
                    at, 0.3)

    # A rocking two-note accompaniment throughout: the musical equivalent of a
    # hearth. Constant, undemanding, easy to stop hearing.
    for i in range(int(LENGTH_S / (beat * 2.0))):
        degree = 0 if i % 2 == 0 else 4
        synth.place(out, pluck(note_hz(ROOT_HZ, DORIAN, degree, 1), beat * 1.6, gen),
                    bar(i * 2.0, beat), 0.13)

    # A short warm phrase, twice, high up.
    for offset in (12.0, 28.0):
        for i, degree in enumerate([4, 5, 4, 2, 3]):
            synth.place(out, pluck(note_hz(ROOT_HZ, DORIAN, degree, 1), beat * 2.2, gen),
                        bar(offset + i * 1.5, beat), 0.18)

    return finish(out, -12.5)


def music_combat(gen: np.random.Generator) -> np.ndarray:
    """A fight. D07: combat is real-time and directly piloted.

    So this must not be a fanfare -- the player is steering, and the music's job
    is to raise the floor without taking attention. A driving pulse, a low
    ostinato, and almost no melody: everything melodic is left to the ability
    cues and impacts, which are the sounds the player actually needs to hear.
    """
    out = canvas()
    beat = 0.32

    # A four-note bass ostinato, relentless.
    figure = [0, 0, 3, 2]
    for i in range(int(LENGTH_S / (beat * 4.0)) + 1):
        for j, degree in enumerate(figure):
            at = bar(i * 4.0 + j, beat)
            synth.place(out, pluck(note_hz(ROOT_HZ, DORIAN, degree, -1), beat * 1.5, gen),
                        at, 0.3)

    # Drum on 1 and 3.
    for i in range(int(LENGTH_S / (beat * 2.0)) + 1):
        synth.place(out, kick(beat * 1.4, gen), bar(i * 2.0, beat), 0.32)

    # Held breath pads over the top, changing every eight bars. Airy rather than
    # bright so they leave the mid-range clear for impacts.
    for i, degree in enumerate([0, 5, 3, 6]):
        synth.place(out, breath_pad(note_hz(ROOT_HZ, DORIAN, degree, 1), beat * 8.4, gen),
                    bar(i * 8.0, beat), 0.16)

    return finish(out, -11.0)


def music_warden(gen: np.random.Generator) -> np.ndarray:
    """The Warden. VISION §10: "the culmination of the chapter".

    Everything about this is the combat cue made heavier and wrong: the same
    root, the same pulse, but phrygian instead of dorian (that flattened second
    is the whole trick), slower, with a bell on top and a low drone underneath.
    It must sound like the same game and a worse day.
    """
    out = canvas()
    beat = 0.42

    # A drone under the entire cue. Nothing else in the chapter's music does
    # this, and it is what makes the fight feel like it has no exits.
    drone = pad(note_hz(ROOT_HZ, PHRYGIAN, 0, -1), LENGTH_S + CROSSFADE_S, gen, 0.55)
    drone += pad(note_hz(ROOT_HZ, PHRYGIAN, 0, -2), LENGTH_S + CROSSFADE_S, gen, 0.5)
    synth.place(out, drone, 0, 0.22)

    figure = [0, 1, 0, 4, 3, 1]
    for i in range(int(LENGTH_S / (beat * 6.0)) + 1):
        for j, degree in enumerate(figure):
            synth.place(out, pluck(note_hz(ROOT_HZ, PHRYGIAN, degree, 0), beat * 1.6, gen),
                        bar(i * 6.0 + j, beat), 0.26)

    for i in range(int(LENGTH_S / (beat * 3.0)) + 1):
        synth.place(out, kick(beat * 1.6, gen), bar(i * 3.0, beat), 0.36)

    # A slow bell every eight bars: a clock the player cannot stop.
    for i in range(int(LENGTH_S / (beat * 8.0)) + 1):
        synth.place(out, bell(note_hz(ROOT_HZ, PHRYGIAN, 1, 1), 2.4, gen),
                    bar(i * 8.0, beat), 0.2)

    return finish(out, -10.0)


def music_release(gen: np.random.Generator) -> np.ndarray:
    """The release ceremony. VISION: "enough history to hurt".

    The hardest brief in the file, and the one place the cue must NOT be
    triumphant: the player is giving up a creature they have carried for hours
    (D08, D38). So it resolves upward but keeps the minor sixth in the chord
    that stops it landing as a victory -- bittersweet, which is a specific
    harmonic thing and not just "slow".

    Bells and a breath pad only. No pulse: nothing here is urgent, and the beat
    that was driving the Warden fight is exactly what this must not have.
    """
    out = canvas()
    beat = 1.1

    progression = [0, 5, 3, 4]
    for i, degree in enumerate(progression):
        at = bar(i * 4.0, beat)
        for interval in (0, 2, 4):
            synth.place(out, breath_pad(note_hz(ROOT_HZ, DORIAN, degree + interval, 0),
                                        beat * 4.4, gen), at, 0.24)
        # The sixth, quietly, over everything: the note that keeps this from
        # resolving cleanly into "well done".
        synth.place(out, breath_pad(note_hz(ROOT_HZ, DORIAN, 5, 1), beat * 4.4, gen),
                    at, 0.09)

    for i, degree in enumerate([4, 2, 4, 6, 5, 4, 2, 0]):
        synth.place(out, bell(note_hz(ROOT_HZ, DORIAN, degree, 1), 3.0, gen),
                    bar(i * 2.0, beat), 0.22)

    return finish(out, -13.0)


TRACKS = {
    "music_exploration": (music_exploration, 4001),
    "music_village": (music_village, 4002),
    "music_combat": (music_combat, 4003),
    "music_warden": (music_warden, 4004),
    "music_release": (music_release, 4005),
}


def main() -> None:
    total = 0
    for name, (fn, seed) in TRACKS.items():
        samples = fn(synth.rng(seed))
        path = synth.write_wav(OUT / f"{name}.wav", samples, SR, loop=True)
        total += path.stat().st_size
        print(f"  {path.relative_to(synth.REPO_ROOT)}  "
              f"{len(samples) / SR:.1f}s  {path.stat().st_size // 1024} KB")
    print(f"  {len(TRACKS)} tracks, {total // 1024} KB")


if __name__ == "__main__":
    main()
