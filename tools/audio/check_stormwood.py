#!/usr/bin/env python3
"""Offline acceptance checks for the nine Stormwood WAVs (owner, 2026-10-05).

Run: `python3 tools/audio/check_stormwood.py [--out DIR]`

Acceptance for these assets is spectral and loop measurement, not an owner
listen. Each check prints PASS/FAIL with its measured value and threshold, and
`--out` writes `checks.json` and `checks.md`. Exit status is 0 only when every
check passes.

Needs numpy and pyloudnorm (tool-time only; BS.1770 integrated loudness).
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import wave
from pathlib import Path

import numpy as np
import pyloudnorm

REPO = Path(__file__).resolve().parents[2]
DIR = REPO / "assets" / "audio" / "stormwood"
CONFIG = REPO / "data" / "config" / "stormwood_audio.json"
BEDS = ["surge_calm_bed", "surge_building_bed", "surge_break_bed", "surge_fading_decay", "release_forest_sky_bed"]
PHASES = ["surge_calm_bed", "surge_building_bed", "surge_break_bed", "surge_fading_decay"]
STRIKES = ["strike_warning", "strike_crack", "strike_body", "strike_decay"]
FX_SR = 44100
BED_SR = 22050

# Thresholds. Loudness windows are relative to the installed neighbours that
# play on the same bus: the Meadows ambience layers for beds (no Tidewake or
# Cloudreach bed exists in assets/audio/; the eight installed ambience layers
# and five music loops are the comparison set) and the installed impact_super
# set for the strike layers.
MAX_PEAK_DBFS = -0.5
MAX_DC = 0.002
BED_LUFS_WINDOW_LU = 6.0
FX_LUFS_WINDOW_LU = 8.0
SEAM_JUMP_PERCENTILE = 99.9
SEAM_RMS_DB = 3.0
SEAM_FLUX_PERCENTILE = 99.0
MIN_CENTROID_GAP_HZ = 150.0
MIN_PHASE_ENERGY_GAP_DB = 1.5
MIN_PROFILE_DISTANCE_DB = 2.0


def read(path: Path) -> tuple[np.ndarray, int, int, int]:
    with wave.open(str(path), "rb") as handle:
        sr, ch, width = handle.getframerate(), handle.getnchannels(), handle.getsampwidth()
        pcm = np.frombuffer(handle.readframes(handle.getnframes()), dtype="<i2").astype(np.float64)
    return pcm / 32768.0, sr, ch, width


def smpl_loop(path: Path) -> tuple[int, int] | None:
    data = path.read_bytes()
    i = 12
    while i + 8 <= len(data):
        cid, size = data[i:i + 4], struct.unpack("<I", data[i + 4:i + 8])[0]
        if cid == b"smpl" and size >= 60:
            count = struct.unpack("<I", data[i + 8 + 28:i + 8 + 32])[0]
            if count:
                _cue, kind, start, end = struct.unpack("<4I", data[i + 8 + 36:i + 8 + 52])
                return (start, end) if kind == 0 else None
        i += 8 + size + (size & 1)
    return None


def db(x: float) -> float:
    return 20.0 * np.log10(max(x, 1e-12))


def rms(x: np.ndarray) -> float:
    return float(np.sqrt(np.mean(x * x))) if len(x) else 0.0


def lufs(x: np.ndarray, sr: int) -> float:
    # Short one-shots are tiled to the 400 ms gating block minimum.
    if len(x) < int(0.5 * sr):
        x = np.concatenate([x, np.zeros(int(0.5 * sr) - len(x))])
    return float(pyloudnorm.Meter(sr).integrated_loudness(x))


def centroid(x: np.ndarray, sr: int) -> float:
    mag = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    freqs = np.fft.rfftfreq(len(x), 1.0 / sr)
    return float(np.sum(freqs * mag) / max(np.sum(mag), 1e-12))


def band_fraction(x: np.ndarray, sr: int, lo: float, hi: float) -> float:
    power = np.abs(np.fft.rfft(x)) ** 2
    freqs = np.fft.rfftfreq(len(x), 1.0 / sr)
    return float(np.sum(power[(freqs >= lo) & (freqs < hi)]) / max(np.sum(power), 1e-20))


# Third-octave profile from 40 Hz to 10 kHz (under every Nyquist used here),
# level-normalised, so distance measures spectral SHAPE rather than gain.
BANDS = 40.0 * 2.0 ** (np.arange(0, 25) / 3.0)


def profile(x: np.ndarray, sr: int) -> np.ndarray:
    power = np.abs(np.fft.rfft(x)) ** 2
    freqs = np.fft.rfftfreq(len(x), 1.0 / sr)
    out = []
    for lo in BANDS:
        hi = lo * 2 ** (1 / 3)
        out.append(10 * np.log10(max(np.sum(power[(freqs >= lo) & (freqs < hi)]), 1e-20)))
    out = np.array(out)
    return out - np.mean(out)


def tick_rate(x: np.ndarray, sr: int, lo: float = 2500.0, hi: float = 4500.0) -> float:
    """Impulsive onsets per second in a band: 5 ms envelope crossing 4x its median."""
    power = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1.0 / sr)
    b = np.fft.irfft(power * ((freqs >= lo) & (freqs < hi)), len(x))
    w = int(0.005 * sr)
    env = np.sqrt(np.convolve(b * b, np.ones(w) / w, "same"))
    hot = env > 4.0 * np.median(env)
    return float(np.sum(hot[1:] & ~hot[:-1])) / (len(x) / sr)


def profile_distance(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.mean(np.abs(a - b)))


def seam(x: np.ndarray, sr: int) -> dict:
    """Wrap discontinuity: compare the end->start step with every interior step."""
    steps = np.abs(np.diff(x))
    jump = abs(x[0] - x[-1])
    limit = float(np.percentile(steps, SEAM_JUMP_PERCENTILE))
    w = int(0.05 * sr)
    across = np.concatenate([x[-w:], x[:w]])
    windows = [rms(x[i:i + 2 * w]) for i in range(0, len(x) - 2 * w, w)]
    seam_rms_delta = abs(db(rms(across)) - db(float(np.median(windows))))
    # Spectral flux at the wrap vs. flux at every interior frame boundary.
    frame = 1024
    hop = frame
    frames = [x[i:i + frame] for i in range(0, len(x) - frame, hop)]
    spec = [np.abs(np.fft.rfft(f * np.hanning(frame))) for f in frames]
    flux = [float(np.sum((spec[i + 1] - spec[i]) ** 2)) for i in range(len(spec) - 1)]
    wrap_flux = float(np.sum((np.abs(np.fft.rfft(x[:frame] * np.hanning(frame)))
                              - np.abs(np.fft.rfft(x[-frame:] * np.hanning(frame)))) ** 2))
    flux_limit = float(np.percentile(flux, SEAM_FLUX_PERCENTILE))
    return {"jump": jump, "jump_limit_p99_9": limit, "seam_rms_delta_db": seam_rms_delta,
            "wrap_flux": wrap_flux, "flux_limit_p99": flux_limit,
            "ok": jump <= limit and seam_rms_delta <= SEAM_RMS_DB and wrap_flux <= flux_limit}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()

    checks: list[dict] = []

    def check(asset: str, name: str, ok: bool, value, threshold) -> None:
        checks.append({"asset": asset, "check": name, "pass": bool(ok), "value": value, "threshold": threshold})
        print(f"{'PASS' if ok else 'FAIL'}  {asset:24s} {name:34s} {value}  ({threshold})")

    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    cues = [*config["phase_cues"].values(), config["release_cue"], *config["strike_chain"].values()]
    referenced = sorted({c["asset_path"] for c in cues if isinstance(c, dict) and "asset_path" in c})
    on_disk = [p for p in referenced if (REPO / p.removeprefix("res://")).exists()]
    check("(contract)", "referenced assets exist", len(on_disk) == len(referenced) == 9,
          f"{len(on_disk)}/{len(referenced)}", "9/9")

    audio: dict[str, tuple[np.ndarray, int]] = {}
    for name in BEDS + STRIKES:
        path = DIR / f"{name}.wav"
        x, sr, ch, width = read(path)
        audio[name] = (x, sr)
        want_sr = BED_SR if name in BEDS else FX_SR
        check(name, "format 16-bit mono at project rate", sr == want_sr and ch == 1 and width == 2,
              f"{sr} Hz/{ch} ch/{width * 8}-bit", f"{want_sr} Hz/1 ch/16-bit")
        peak = db(float(np.max(np.abs(x))))
        clipped = int(np.sum(np.abs(x) >= 32767 / 32768))
        check(name, "no clipping (peak, full-scale samples)", peak <= MAX_PEAK_DBFS and clipped == 0,
              f"{peak:.2f} dBFS, {clipped} samples", f"<= {MAX_PEAK_DBFS} dBFS, 0")
        dc = abs(float(np.mean(x)))
        check(name, "DC offset", dc <= MAX_DC, f"{dc:.5f}", f"<= {MAX_DC}")
        loop = smpl_loop(path)
        if name in BEDS:
            ok = loop == (0, len(x) - 1)
            check(name, "smpl forward loop = whole clip", ok, str(loop), f"(0, {len(x) - 1})")
            s = seam(x, sr)
            check(name, "seamless loop: wrap step", s["jump"] <= s["jump_limit_p99_9"],
                  f"{s['jump']:.5f}", f"<= interior p{SEAM_JUMP_PERCENTILE} step {s['jump_limit_p99_9']:.5f}")
            check(name, "seamless loop: RMS across wrap", s["seam_rms_delta_db"] <= SEAM_RMS_DB,
                  f"{s['seam_rms_delta_db']:.2f} dB", f"<= {SEAM_RMS_DB} dB from median 100 ms window")
            check(name, "seamless loop: spectral flux at wrap", s["wrap_flux"] <= s["flux_limit_p99"],
                  f"{s['wrap_flux']:.2f}", f"<= interior p{SEAM_FLUX_PERCENTILE} {s['flux_limit_p99']:.2f}")
        else:
            check(name, "one-shot: no loop chunk", loop is None, str(loop), "None")

    # Loudness against installed neighbours on the same bus.
    neighbours = {p.stem: read(p)[:2] for p in sorted((REPO / "assets/audio/ambience").glob("*.wav"))}
    n_lufs = {k: lufs(x, sr) for k, (x, sr) in neighbours.items()}
    lo, hi = min(n_lufs.values()), max(n_lufs.values())
    for name in BEDS:
        value = lufs(*audio[name])
        check(name, "bed loudness vs installed ambience", lo - BED_LUFS_WINDOW_LU <= value <= hi + BED_LUFS_WINDOW_LU,
              f"{value:.1f} LUFS", f"installed ambience {lo:.1f}..{hi:.1f} LUFS +/- {BED_LUFS_WINDOW_LU} LU")
    impacts = {p.stem: read(p)[:2] for p in sorted((REPO / "assets/audio/sfx").glob("impact_super_*.wav"))}
    i_lufs = [lufs(x, sr) for x, sr in impacts.values()]
    ilo, ihi = min(i_lufs), max(i_lufs)
    for name in STRIKES:
        value = lufs(*audio[name])
        check(name, "strike loudness vs installed impacts", ilo - FX_LUFS_WINDOW_LU <= value <= ihi + FX_LUFS_WINDOW_LU,
              f"{value:.1f} LUFS", f"impact_super {ilo:.1f}..{ihi:.1f} LUFS +/- {FX_LUFS_WINDOW_LU} LU")

    # Surge phases: distinct by spectral centroid and energy.
    cents = {p: centroid(*audio[p]) for p in PHASES}
    energy = {p: db(rms(audio[p][0])) for p in PHASES}
    for i, a in enumerate(PHASES):
        for b in PHASES[i + 1:]:
            gap = abs(cents[a] - cents[b])
            egap = abs(energy[a] - energy[b])
            check(f"{a[6:]}|{b[6:]}", "phase pair distinct (centroid, energy)",
                  gap >= MIN_CENTROID_GAP_HZ and egap >= MIN_PHASE_ENERGY_GAP_DB,
                  f"{cents[a]:.0f}/{cents[b]:.0f} Hz, {energy[a]:.1f}/{energy[b]:.1f} dB",
                  f"centroid gap >= {MIN_CENTROID_GAP_HZ:.0f} Hz and energy gap >= {MIN_PHASE_ENERGY_GAP_DB} dB")
    check("(phases)", "energy ordering calm<building<break>fading",
          energy["surge_calm_bed"] < energy["surge_building_bed"] < energy["surge_break_bed"]
          and energy["surge_fading_decay"] < energy["surge_break_bed"],
          ", ".join(f"{p[6:]} {energy[p]:.1f}" for p in PHASES), "monotonic rise to Break, Fading below Break")
    calm_ticks = tick_rate(audio["surge_calm_bed"][0], BED_SR)
    build_ticks = tick_rate(audio["surge_building_bed"][0], BED_SR)
    check("surge_building_bed", "copper-vine ticks (2.5-4.5 kHz onsets/s)", build_ticks >= 2.0 and build_ticks > 2 * calm_ticks,
          f"{build_ticks:.2f}/s vs calm {calm_ticks:.2f}/s", ">= 2/s and > 2x Calm")
    calm_hum = band_fraction(audio["surge_calm_bed"][0], BED_SR, 90, 210)
    build_hum = band_fraction(audio["surge_building_bed"][0], BED_SR, 90, 210)
    check("surge_building_bed", "electrical bed (90-210 Hz share)", build_hum >= 3 * calm_hum,
          f"{build_hum:.3f} vs calm {calm_hum:.3f}", ">= 3x Calm")
    release_elec = band_fraction(audio["release_forest_sky_bed"][0], BED_SR, 80, 220)
    break_elec = band_fraction(audio["surge_break_bed"][0], BED_SR, 80, 220)
    check("release_forest_sky_bed", "no oppressive low electrical/thunder bed", release_elec < 0.5 * break_elec,
          f"80-220 Hz fraction {release_elec:.3f} vs break {break_elec:.3f}", "< half of Break")

    # Strike roles.
    def attack_ms(x: np.ndarray, sr: int) -> float:
        env = np.abs(x)
        peak = float(np.max(env))
        first = int(np.argmax(env >= 0.1 * peak))
        top = int(np.argmax(env >= 0.9 * peak))
        return (top - first) / sr * 1000.0

    x, sr = audio["strike_crack"]
    a_ms = attack_ms(x, sr)
    check("strike_crack", "sharp transient (10->90% attack)", a_ms <= 5.0, f"{a_ms:.2f} ms", "<= 5 ms")
    c = centroid(x, sr)
    check("strike_crack", "broadband/bright (centroid)", c >= 1500.0, f"{c:.0f} Hz", ">= 1500 Hz")
    w50 = int(0.05 * sr)
    crest = db(float(np.max(np.abs(x[:w50])))) - db(rms(x))
    check("strike_crack", "crest factor (peak in first 50 ms over RMS)", crest >= 10.0, f"{crest:.1f} dB", ">= 10 dB")
    for name in ("strike_body", "strike_decay"):
        x, sr = audio[name]
        low = band_fraction(x, sr, 20, 250)
        check(name, "low rumble (energy below 250 Hz)", low >= 0.6, f"{low:.2f}", ">= 0.60")
    x, sr = audio["strike_decay"]
    early, late = rms(x[: sr]), rms(x[sr: 4 * sr])
    check("strike_decay", "tail persists 1-4 s", db(late) - db(early) >= -12.0,
          f"{db(late) - db(early):.1f} dB vs first second", ">= -12 dB")
    # Whole chain as the observer starts it: crack, body and decay together.
    layers = [audio[n][0] for n in ("strike_crack", "strike_body", "strike_decay")]
    chain = np.zeros(max(len(l) for l in layers))
    for l in layers:
        chain[: len(l)] += l
    a_ms = attack_ms(chain[: int(0.1 * FX_SR)], FX_SR)
    tail_low = band_fraction(chain[int(0.5 * FX_SR):], FX_SR, 20, 250)
    check("strike chain", "transient then low rumble tail", a_ms <= 5.0 and tail_low >= 0.6,
          f"attack {a_ms:.2f} ms, tail<250 Hz {tail_low:.2f}", "attack <= 5 ms, tail >= 0.60")
    x, sr = audio["strike_warning"]
    thirds = np.array_split(x, 3)
    rise = db(rms(thirds[2])) - db(rms(thirds[0]))
    check("strike_warning", "rises toward impact (last vs first third)", rise >= 6.0, f"{rise:.1f} dB", ">= 6 dB")
    length = len(x) / sr
    tele = json.loads((REPO / "data/config/stormwood_surge.json").read_text(encoding="utf-8"))
    tele_s = float(tele.get("strike", {}).get("telegraph_seconds", 1.2))
    check("strike_warning", "length matches telegraph", abs(length - tele_s) <= 0.02, f"{length:.3f} s", f"{tele_s} s +/- 0.02")

    # Distinct from one another and from the installed beds/music.
    profs = {n: profile(*audio[n]) for n in BEDS + STRIKES}
    others = dict(neighbours)
    others.update({f"music/{p.stem}": read(p)[:2] for p in sorted((REPO / "assets/audio/music").glob("*.wav"))})
    oprofs = {k: profile(x, sr) for k, (x, sr) in others.items()}
    names = BEDS + STRIKES
    for i, a in enumerate(names):
        nearest = min(((profile_distance(profs[a], profs[b]), b) for b in names if b != a))
        check(a, "distinct from the other eight", nearest[0] >= MIN_PROFILE_DISTANCE_DB,
              f"nearest {nearest[1]} {nearest[0]:.2f} dB", f">= {MIN_PROFILE_DISTANCE_DB} dB mean 1/3-oct shape gap")
        if a in BEDS:
            on = min(((profile_distance(profs[a], v), k) for k, v in oprofs.items()))
            check(a, "distinct from installed beds/music", on[0] >= MIN_PROFILE_DISTANCE_DB,
                  f"nearest {on[1]} {on[0]:.2f} dB", f">= {MIN_PROFILE_DISTANCE_DB} dB")

    failed = [c for c in checks if not c["pass"]]
    print(f"\n{len(checks) - len(failed)}/{len(checks)} checks passed")
    if args.out:
        args.out.mkdir(parents=True, exist_ok=True)
        (args.out / "checks.json").write_text(json.dumps({"checks": checks, "failed": len(failed)}, indent=2) + "\n",
                                              encoding="utf-8")
        md = ["| asset | check | result | value | threshold |", "|---|---|---|---|---|"]
        md += [f"| {c['asset']} | {c['check']} | {'PASS' if c['pass'] else 'FAIL'} | {c['value']} | {c['threshold']} |"
               for c in checks]
        (args.out / "checks.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
