# T1-LIGHT session report — 2026-08-29

Track 1 (Aesthetics) lane, scoped to §13 (lighting/time of day) and §14
(weather/atmosphere) of `docs/owner-direction/TETHERBOUND_VISUAL_STUNNING_PASS.md`.
Branch `ralph/T1-LIGHT`, pushed, no PR opened per instructions. Ran well past
the suggested 60-90 minute bound because the inherited black-frame
investigation and the defect it led to both needed decisive, re-rendered
verification rather than a guess — recorded here rather than left half-done.

## 1. Resolved: the golden-hour black frame is not a lighting bug

Full writeup: `ralph/reports/finding-golden-hour-black-frame.md` (updated,
committed `310f8ad4`).

`tools/_diag_golden_hour.gd` (inherited, built by a previous lane) rendered
day/golden/night correctly in all 13 trials, refuting the hour-drift
hypothesis it was built to test. That sent this session back to the real
`tools/survey.gd`, which still reproduces the black `05-spawn-low-sun.png`
on current `main`. Two scratch probes (not committed) isolated the actual
cause: it needs BOTH the exact same viewpoint as an earlier shot AND several
large camera teleports through other regions in between — a Terrain3D
region-streaming/capture defect, unrelated to `art.json` or time of day.
No art value was touched to "fix" this, because none of them are the cause.
**This belongs to whoever owns Terrain3D streaming / `tools/survey.gd`
reliability (Track 2), not this lane.**

## 2. Fixed and verified: blown-out sun disc during golden→night blend

Commit `b85aaf6f`. A blind visual-judge pass (methodology: `.claude/skills/visual-judge`)
against real production frames flagged a huge blown-out white disc eating
roughly a quarter of the sky at dusk (hour ~21, mid-blend between the
`golden` and `night` `art.json` presets — not either keyframe alone).

Root cause, found by reading `shaders/sky_clouds.gdshader` directly and
confirmed by reading the live `ShaderMaterial`'s own parameters back at the
shutter: `sun_size`/`sun_glow` (the sun disc/glow term) and `cloud_sun_gain`
(the cloud rim highlight, config key for the shader's `sun_gain` uniform)
were never set by ANY time-of-day preset, so they stayed pinned at the
shader's bright daytime defaults all the way to full night while sun energy,
yaw and everything else correctly dimmed. `cloud_lit` (the cloud's own
lit-face colour, also never time-of-day-driven, default near-white) was a
secondary contributor.

Two dead-end attempts before landing the fix (both kept, both real,
neither sufficient alone — see the comment thread in `art.json` itself,
`times.night.sky`): a 27% cut to `sun_size` had no visible effect (the
disc's angular radius on screen scales roughly with `sqrt(sun_size)`, so
that cut was real but far too small to see), and dimming `cloud_lit` alone
did not meaningfully shrink the blob either. Zeroing every term out
confirmed the mechanism (collapsed to a small clean disc), then landed on
a tuned value that keeps a small, tasteful night sun/moon rather than
removing it outright. Re-verified on the exact flagged frame and on a
second viewpoint, at both dusk and night.

## 3. Not reached: full §13/§14 audit

A blind critic pass (full transcript not preserved, summarized in this
session) also flagged, unaddressed:

- **Dawn (~5:30) reads as "dim day," not a distinct cool/warm transition.**
  With only three named `art.json` keyframes (day 8:00, golden 18:00,
  night 0:00), hour 5.5 sits 69% of the way from night to day in the
  continuous blend, which is mathematically close to full day already.
  Matching the owner's explicit "morning: cool/warm readable transition"
  ask may need a fourth named keyframe (a `dawn` preset) rather than
  relying on the night→day blend alone.
- **Night grass stays strongly saturated green**, and in one frame
  (valley-night) a foreground tree trunk reads warm-lit as if still in
  daylight. `NIGHT-LIGHT`'s own history in `art.json` documents this as a
  known, deliberately-limited compromise (partial desaturation via
  `adjustment_saturation`), not something this session re-touched.
- **No aerial perspective/fog gradient at distance** (`03-rise-overlook` in
  the real survey) — distant terrain and the village render at the same
  saturation/contrast as the foreground.
- **§14 (weather) was not separately re-audited this session.**
  `data/config/weather.json`/`world_weather.gd` show an extensive prior
  tuning pass (OP21-21, explicitly fixing "washed-out after several
  minutes" via reweighted presets and a `max_consecutive_non_clear` cap) —
  read but not re-verified with a fresh capture in this session.

None of these were touched. Flagging them plainly rather than leaving them
implicit, per the instruction to report what remains rather than let it
balloon further.

## Constraints observed

- Did not touch `ralph/T1-GROUND`'s terrain/ground-material ownership, the
  grass blade ring, or anything under `tools/gate_f/`.
- Did not change the look of near grass.
- Every capture used the Compatibility renderer under `xvfb-run` + llvmpipe
  (D06) — **frame times are not performance**; no ROG Ally hardware was
  available in this session to measure real frame cost for the sky shader
  change. The change is a shader-uniform value tweak (three floats and two
  colours pulled from JSON), not new geometry, draw calls, or shader
  complexity, so the expected performance delta is zero, but that is an
  expectation, not a measurement — worth a real-hardware sanity check.
