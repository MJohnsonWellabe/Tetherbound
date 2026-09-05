#!/usr/bin/env python3
"""N13-NIGHT-RESUME. What the day/night cycle actually asks the renderer for, hour by hour.

`world_look.gd::_apply_blended()` does NOT hand the renderer a named preset. It hands it a
LERP between the two `data/config/art.json` `times` keyframes that bracket the current hour
(`day_cycle.gd::interpolate_at`). Every tool in `tools/` and every probe in `tools/gate_f/`
instead pins a preset by name with `apply_time()`, which snaps to that preset's exact numbers.
So the frames NIGHT-LIGHT and NIGHT-LEGIBILITY were judged on are frames the running game only
ever draws at the single instant the clock crosses that keyframe's own hour.

This reproduces the blend in pure Python, off the same art.json the game reads, so the gap
between "the night preset" and "what night actually looks like while you play" is a number
rather than an argument.

    python3 tools/_daynight_curve.py [path/to/art.json]

Columns: the in-game hour, the two keyframes bracketing it and the blend fraction, then what
`world_look.gd::_apply_environment` actually installs on the Environment. `sun*exp` and
`amb*exp` are the products that reach the ACES curve, because `tonemap_exposure` multiplies
the linear value before the tonemapper -- so a preset that halves its light and doubles its
exposure has changed nothing about how bright the frame is.

Both light columns are weighted by their own colour's Rec.709 luma, and the ambient column
is the COMPATIBILITY-renderer ambient, not the raw `ambient_energy`.
`project.godot` ships `renderer/rendering_method="gl_compatibility"`, and under Compatibility
sky radiance does not reach the terrain at all (D06, and `_apply_environment`'s own comment
says so and measured it) -- so only the `(1 - ambient_sky_contribution)` share of the ambient,
the explicit-colour half, is real light on the shipped renderer.

`dark` is `day_cycle.gd::is_dark()`, i.e. what every gameplay system (torches, camp fill
lights, the creature emission floor) switches on.
"""
import json
import sys

ANGLE_KEYS = {"yaw_deg"}


def luma(hex_colour, fallback):
    """Rec.709 luma of a light's colour, 0..1 -- see world_look.gd::_luma.

    Not a refinement: night's light is a dark blue and day's is near-white, so an
    energy read WITHOUT its colour reports night as the brighter of the two and a
    rendered frame reports the opposite.
    """
    value = hex_colour if isinstance(hex_colour, str) and hex_colour.startswith("#") else fallback
    value = value.lstrip("#")
    r, g, b = (int(value[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def preset_over(config, name):
    """Mirrors world_look.gd::_preset_over -- resolves a `same_as` alias entry."""
    times = config.get("times", {})
    entry = times.get(name, {})
    if not isinstance(entry, dict):
        return {}
    base_name = str(entry.get("same_as", ""))
    if not base_name or base_name == name or base_name not in times:
        return entry
    resolved = json.loads(json.dumps(times[base_name]))
    for key, value in entry.items():
        if key == "same_as":
            continue
        if isinstance(value, dict) and isinstance(resolved.get(key), dict):
            resolved[key].update(value)
        else:
            resolved[key] = value
    return resolved


def merged(config, section, over):
    base = dict(config.get(section, {}))
    base.update(over.get(section, {}))
    return {k: v for k, v in base.items() if not k.startswith("_")}


def lerp(a, b, t):
    return a + (b - a) * t


def blend(a, b, t):
    out = dict(a)
    for k, bv in b.items():
        av = a.get(k, bv)
        if isinstance(av, bool) or isinstance(bv, bool):
            out[k] = bv if t >= 0.5 else av
        elif isinstance(av, (int, float)) and isinstance(bv, (int, float)):
            if k in ANGLE_KEYS:
                diff = ((bv - av + 540.0) % 360.0) - 180.0
                out[k] = av + diff * t
            else:
                out[k] = lerp(float(av), float(bv), t)
        else:
            out[k] = bv if t >= 0.5 else av
    return out


def keyframes(config):
    kfs = []
    for name, entry in config.get("times", {}).items():
        if name.startswith("_") or not isinstance(entry, dict) or "hour" not in entry:
            continue
        kfs.append((float(entry["hour"]) % 24.0, name))
    kfs.sort()
    return kfs


def interpolate_at(kfs, hour):
    """Mirrors day_cycle.gd::interpolate_at."""
    if not kfs:
        return ("", "", 0.0)
    if len(kfs) == 1:
        return (kfs[0][1], kfs[0][1], 0.0)
    h = hour % 24.0
    n = len(kfs)
    for i in range(n):
        cur_hour, cur = kfs[i]
        nxt_hour, nxt = kfs[(i + 1) % n]
        if nxt_hour <= cur_hour:
            nxt_hour += 24.0
        h_adj = h if h >= cur_hour else h + 24.0
        if cur_hour <= h_adj < nxt_hour:
            span = nxt_hour - cur_hour
            return (cur, nxt, (h_adj - cur_hour) / span if span > 0 else 0.0)
    return (kfs[-1][1], kfs[-1][1], 0.0)


def is_dark(config, hour):
    h = hour % 24.0
    frm = float(config.get("dark_from_hour", 20.0)) % 24.0
    to = float(config.get("dark_to_hour", 5.0)) % 24.0
    if frm <= to:
        return frm <= h < to
    return h >= frm or h < to


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else "data/config/art.json"
    with open(path) as fh:
        config = json.load(fh)
    kfs = keyframes(config)
    times = config.get("times", {})
    day_len = float(config.get("day_length_seconds", 600.0))
    print("art.json: day_length_seconds=%.0f  dark_from=%.0f  dark_to=%.0f" % (
        day_len, float(config.get("dark_from_hour", 20.0)), float(config.get("dark_to_hour", 5.0))))
    print("keyframes: " + ", ".join("%s@%.0f" % (n, h) for h, n in kfs))
    print()
    header = "%5s %5s  %-16s %5s | %6s %6s %6s | %7s %7s | %4s"
    print(header % ("hour", "real_s", "blend", "t", "sun_e", "amb*c", "expos", "sun*exp", "amb*exp", "dark"))
    print("-" * 92)
    rows = []
    for step in range(48):
        hour = step * 0.5
        frm, to, t = interpolate_at(kfs, hour)
        from_over, to_over = preset_over(config, frm), preset_over(config, to)
        sun = blend(merged(config, "sun", from_over), merged(config, "sun", to_over), t)
        env = blend(merged(config, "environment", from_over),
                    merged(config, "environment", to_over), t)
        sun_e = float(sun.get("energy", 1.25)) * luma(sun.get("colour"), "#ffffff")
        # See the module docstring: the sky share is dead weight under Compatibility.
        amb_e = float(env.get("ambient_energy", 1.0)) * (
            1.0 - float(env.get("ambient_sky_contribution", 0.55))) * luma(
                env.get("ambient_colour"), "#9fb4c6")
        expo = float(env.get("exposure", 1.0))
        dark = is_dark(config, hour)
        rows.append((hour, sun_e * expo, amb_e * expo, dark))
        print(header % ("%.1f" % hour, "%.0f" % (hour / 24.0 * day_len), "%s->%s" % (frm, to),
                        "%.2f" % t, "%.2f" % sun_e, "%.2f" % amb_e, "%.2f" % expo,
                        "%.3f" % (sun_e * expo), "%.3f" % (amb_e * expo), "yes" if dark else ""))
    print()
    dark_rows = [r for r in rows if r[3]]
    lit_rows = [r for r in rows if not r[3]]

    def span(rs, i):
        return (min(r[i] for r in rs), max(r[i] for r in rs))

    print("What the renderer is asked for, dark window vs lit window (energy x exposure):")
    print("  direct light  lit %.3f-%.3f   dark %.3f-%.3f" % (span(lit_rows, 1) + span(dark_rows, 1)))
    print("  ambient       lit %.3f-%.3f   dark %.3f-%.3f" % (span(lit_rows, 2) + span(dark_rows, 2)))
    darkest = min(dark_rows, key=lambda r: r[1] + r[2])
    brightest = max(lit_rows, key=lambda r: r[1] + r[2])
    print("  darkest dark hour  %.1f: direct %.3f + ambient %.3f = %.3f" % (
        darkest[0], darkest[1], darkest[2], darkest[1] + darkest[2]))
    print("  brightest lit hour %.1f: direct %.3f + ambient %.3f = %.3f" % (
        brightest[0], brightest[1], brightest[2], brightest[1] + brightest[2]))
    print("  darkest/brightest = %.3f  (1.000 would mean the darkest moment of the night asks"
          " for exactly as much light as the brightest moment of the day)" % (
        (darkest[1] + darkest[2]) / (brightest[1] + brightest[2])))
    print()
    # The comparison the owner is actually making, and the one no probe ever made:
    # the keyframe called "night" against the keyframe called "day", each on its own hour.
    named = {name: h for h, name in kfs}
    if "night" in named and "day" in named:
        for label in ("night", "day"):
            hour = named[label]
            row = [r for r in rows if abs(r[0] - hour) < 1e-6]
            if row:
                print("  hour %4.1f (the '%s' keyframe, no blend): direct %.3f + ambient %.3f = %.3f" % (
                    hour, label, row[0][1], row[0][2], row[0][1] + row[0][2]))
        night_row = [r for r in rows if abs(r[0] - named["night"]) < 1e-6][0]
        day_row = [r for r in rows if abs(r[0] - named["day"]) < 1e-6][0]
        ratio = (night_row[1] + night_row[2]) / (day_row[1] + day_row[2])
        print("  night / day = %.3f -- %s" % (
            ratio,
            "night asks for MORE light than day" if ratio > 1.0
            else "night asks for %.0f%% of day's light" % (ratio * 100.0)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
