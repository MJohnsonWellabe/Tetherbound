# X07 — incomplete record: 79 of 80 frames, no harness verdicts

**Status:** killed by my own 4,200 s wall-clock cap at the 79th of 80 planned
captures. Exit 143 is that SIGTERM, not a crash. **It was still working when it
died** — the last event is `captured GF-14-COMBAT-13b at 1920x1080` at
`t=3461.5` — so this is a run that ran out of my clock, not one that hung.

**What is here:** 79 real 1920×1080 PNGs under `shots/`, `telemetry/events.jsonl`
(265 records), `telemetry/route.csv` (136 rows), and `CAPTURE_RESOLUTION.json`
recording no fallback — every frame is at the requested size.

**What is missing, and why:** `notes/X07.md` is empty. The harness writes its
per-step verdict table only at segment end, and this segment had no end. The 80th
capture is also absent.

## Verdicts derived by hand from `events.jsonl`, and labelled as such

Every event carries `expected` and `actual`, so the assertion outcomes are
recoverable — but **the harness did not adjudicate them; I did, after the fact,
by comparing those two fields.** They are recorded here as derived, not as
harness output, and Phase B should treat them accordingly.

Of the 22 assertions, 19 are clean (`0.0 m` from the target point, region matching
the expected id). **Three are not:**

| t (s) | derived FAIL |
|---|---|
| 1964.2 | teleport to `the_long_water` centre `(-150, 4200)` landed **11.3 m off**, against a 5.0 m tolerance — region id still matched |
| 2580.1 | at the stronghold approach's own centre: **`region=corridor`, expected `stronghold_approach`** |
| 2709.3 | at the Hall's own centre: **`region=corridor`, expected `hall`** |

The last two are the substantive ones and they are E.7's own subject. Standing at
the published centre point of two named late-chapter regions, the game's region
containment reports neither — it reports `corridor`, the id meaning "between
places." Whether that is a gap in `data/config/map_landmarks.json`'s volumes or
intended for those two sites is a diagnosis, and not mine to make (§13).

This is DIAG-legal ground: X07 audits the world and the instrument, not the
player's route, so a teleport-sited region-identity finding is exactly what this
segment is for. **No pacing, navigation, difficulty or economy claim is drawn from
it** (§0.6).
