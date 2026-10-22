#!/usr/bin/env python3
"""Map one judging batch's Bar A scores onto the reference (original accepted) scale.

Input is a batch JSON scored by the same judges, with the same prompt, in the
same batch:

    {"anchors":    {"<anchor id from anchors.json>": [j1, j2, j3] or mean, ...},
     "candidates": {"<label>": [j1, j2, j3] or mean, ...}}

Each anchor gives one point (its judges' mean, its reference). With at least
three points a least-squares line measured -> reference is fitted; with fewer
points, a degenerate spread, or a slope outside 0.5-2.0, the map falls back to
the mean offset (reference - measured). Candidates are mapped through it and
clamped to 0-10. Output is JSON: the fit, per-anchor residuals and the mapped
candidate scores against the bar.

    python3 tools/visual_judge/calibrate.py batch.json [--bar 7.5] [--out mapped.json]
"""
import argparse
import json
import math
import sys
from pathlib import Path

ANCHORS = Path(__file__).resolve().parent / "anchors" / "anchors.json"
SLOPE_RANGE = (0.5, 2.0)
MIN_POINTS = 3
RMSE_WARN = 0.75


def mean(x):
    return sum(x) / len(x)


def as_scores(v):
    return [float(s) for s in v] if isinstance(v, (list, tuple)) else [float(v)]


def fit(points):
    """points: [(measured, reference)]. Returns the map and how it was chosen."""
    n = len(points)
    if n == 0:
        raise ValueError("no anchor scores in the batch")
    xs, ys = [p[0] for p in points], [p[1] for p in points]
    mx, my = mean(xs), mean(ys)
    sxx = sum((x - mx) ** 2 for x in xs)
    syy = sum((y - my) ** 2 for y in ys)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    r = sxy / math.sqrt(sxx * syy) if sxx > 0 and syy > 0 else None
    out = {"n_points": n, "pearson_r": r, "least_squares_slope": sxy / sxx if sxx > 0 else None}
    reason = None
    if n < MIN_POINTS:
        reason = f"fewer than {MIN_POINTS} anchor points"
    elif sxx == 0:
        reason = "anchor measured scores have no spread"
    else:
        slope = sxy / sxx
        if not SLOPE_RANGE[0] <= slope <= SLOPE_RANGE[1]:
            reason = f"least-squares slope {slope:.3f} outside {SLOPE_RANGE[0]}-{SLOPE_RANGE[1]}"
    if reason:
        out.update(method="offset", slope=1.0, intercept=my - mx, fallback_reason=reason)
    else:
        slope = sxy / sxx
        out.update(method="linear", slope=slope, intercept=my - slope * mx, fallback_reason=None)
    return out


def apply(f, x):
    return f["slope"] * x + f["intercept"]


def clamp(v):
    return min(10.0, max(0.0, v))


def calibrate(batch, references, bar=7.5):
    points, rows = [], []
    for aid, scores in batch["anchors"].items():
        if aid not in references:
            raise KeyError(f"unknown anchor id: {aid}")
        m = mean(as_scores(scores))
        points.append((m, references[aid]))
        rows.append((aid, m, references[aid]))
    f = fit(points)
    residuals = {}
    for aid, m, ref in rows:
        mapped = apply(f, m)
        residuals[aid] = {"measured": round(m, 3), "reference": ref,
                          "mapped": round(mapped, 3), "residual": round(ref - mapped, 3)}
    rmse = math.sqrt(mean([r["residual"] ** 2 for r in residuals.values()]))
    lo, hi = min(p[0] for p in points), max(p[0] for p in points)
    candidates = {}
    for label, scores in batch.get("candidates", {}).items():
        js = as_scores(scores)
        m = mean(js)
        raw = apply(f, m)
        candidates[label] = {
            "measured_mean": round(m, 3),
            "mapped_mean": round(clamp(raw), 2),
            "mapped_judges": [round(clamp(apply(f, j)), 2) for j in js],
            "clamped": raw != clamp(raw),
            "outside_anchor_range": not lo - 0.5 <= m <= hi + 0.5,
            "meets_bar": clamp(raw) >= bar,
        }
    warnings = []
    if f["fallback_reason"] and "slope" in f["fallback_reason"]:
        warnings.append("slope fallback: these judges spread the anchors differently from the reference judges, "
                        "so the map is only a mean offset; mix anchors from more items into the next batch")
    if rmse > RMSE_WARN:
        warnings.append(f"anchor residual RMSE {rmse:.2f} > {RMSE_WARN}: these judges do not rank the anchors "
                        "like the reference judges; report the mapped scores with this caveat")
    if any(c["outside_anchor_range"] for c in candidates.values()):
        warnings.append("some candidates lie more than 0.5 outside the anchors' measured range (extrapolated)")
    for k in ("slope", "intercept", "pearson_r", "least_squares_slope"):
        if f[k] is not None:
            f[k] = round(f[k], 4)
    return {"bar": bar, "fit": f, "anchor_rmse": round(rmse, 3), "anchors": residuals,
            "candidates": candidates, "warnings": warnings}


def references(path=ANCHORS):
    return {a["id"]: a["reference"] for a in json.loads(Path(path).read_text())["anchors"]}


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("batch", help="batch JSON with 'anchors' and 'candidates'")
    p.add_argument("--anchors", default=str(ANCHORS))
    p.add_argument("--bar", type=float, default=7.5)
    p.add_argument("--out", help="write the result here as well as stdout")
    args = p.parse_args(argv)
    result = calibrate(json.loads(Path(args.batch).read_text()), references(args.anchors), args.bar)
    text = json.dumps(result, indent=1)
    if args.out:
        Path(args.out).write_text(text + "\n")
    sys.stdout.write(text + "\n")


if __name__ == "__main__":
    main()
