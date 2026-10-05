# Independent F17 night-rain source review

Verdict: **PASS for the bounded source change; no source blocker found.**

Reviewed the working-tree `scripts/world/world_look.gd` diff and its existing caller, preset-resolution, blending and color-conversion context; relevant `data/config/art.json` night metadata; ART_DIRECTION §4.1; and `f17-night-rain-source-findings.md`. Read-only inspection plus this review artifact only; no engine, GPU, tests or timing jobs were run.

- `apply_time` supplies the selected preset's weight before moving the clock. Invalid names already fall back to the default before weight selection. `_apply_blended` uses the exact `from`/`to`/`t` metadata that produced its time-derived palette. `set_weather` reaches one of these same paths, so weather changes do not introduce a separate time calculation.
- The authored `night` keyframe is at 23:00; `night_end` is at 01:00 with `same_as: night`. Both weigh 1, preserving the overnight plateau. Golden and dawn weigh 0. Direct aliases to night are recognized consistently with the existing one-level preset inheritance. No new recursive-alias behavior is claimed.
- For a rain-overridden color, the new result is `(1-w) * rain_color + w * time_color`, with `w` clamped to [0, 1]. At zero the prior assignment executes unchanged; at one the time-derived night color is retained. Sunset/dawn use the same interpolation parameter as the time palette, yielding a continuous, potentially nonlinear color transition without a new threshold or midpoint snap. Clear and non-rain weather retain their previous branch.
- Dictionaries carry the existing string or Color values; `_as_colour` accepts both. The helper's comparisons infer booleans, its endpoints and `lerpf` return floats, and the supplied blend metadata is explicitly converted to String/float. No static type inconsistency was identified; this is not a parser result.

This addresses the reported sky-overwrite mechanism and is consistent with the blue village night target. Sun, fog and ambient weather terms are unchanged. Rain's ambient-color override can still affect façade brightness; that finding is not declared resolved.

**OPEN:** Godot parsing; matched clear-versus-rain Medium/High night screenshots; ambient/façade brightness; ordinary-distance lower-body, route, Hall and warm-opening readability; Low regression; sunset/dawn continuity and daytime-rain visual identity. No runtime, F17/F26, or full Bars A/B acceptance follows from this source review.
