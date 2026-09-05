# N13-NIGHT-RESUME

**Source:** the original `ralph/briefs/0904/W15-NIGHT.md` brief (reproduced in full below) —
that lane pushed exactly one commit (`45144af3`, "exported-build day/night probe through the
title screen") and never wrote a final report or a fix. This is a genuine resume of unfinished
work, not a routed finding from another lane.

## Original brief, unchanged

> Owner, flat, on the ROG Ally release build: "There is no night time." The in-engine probes
> pass (`tools/gate_f/probe_daynight_*.gd`), NIGHT-LEGIBILITY tuned real rendered night frames
> — those frames are real. So **the shipped build reaches the clock by a different path than
> the harness does, and that gap is the defect.** Read
> `docs/owner/OWNER_PLAYTEST_2026-09-04.md` OP-0904-2, closure plan CL-O2 and §7's note,
> `docs/CURRENT_STATE.md` §3's night row, `scripts/world/day_cycle.gd`,
> `scripts/world/world_look.gd`, `docs/GAMEPLAY_SYSTEMS.md` §Day/night,
> `docs/prompts/07-RG21-continuous-day-night-short-night.md`, `export_presets.cfg`,
> `tools/verify_export.sh`, `scripts/save/save_game.gd` (is the clock saved/restored? does a
> load reset it to morning?), the settings (`smoke_settings.gd`: is there a "time" or "skip
> night" setting the release defaults differently?), and the title/new-game path
> (`title_screen.gd` — does New Game freeze the clock until a flag that the shipped opening
> never sets?).
>
> **Hypotheses to test, in order of likelihood, each with a probe you commit:** (1) the clock
> only advances while some harness-only condition holds (a debug flag, an
> `OS.has_feature("editor")`, a `--` user arg the harness passes, a `user://` file the harness
> writes); (2) the clock advances but `world_look.gd`'s night look is gated on a
> resource/shader that the export does not pack (check `export_presets.cfg` `include_filter`
> and `tools/verify_export.sh` against every resource `world_look.gd`/`day_cycle.gd` loads at
> runtime by path string); (3) the day length is so long relative to a session that the owner
> never reached night; (4) sleeping/resting advances to morning and the owner rests often, so
> night is skipped; (5) the release build's `project.godot` overrides differ. Do a real Linux
> export (`godot --headless --path . --export-release "Linux Test" /tmp/tb.x86_64` per
> `tools/verify_export.sh`) and run the exported binary under xvfb with a real-frame probe to
> read the sun angle / ambient over accelerated time — that is the shipped path, not the
> editor path.
>
> **Owns:** `scripts/world/day_cycle.gd`, `scripts/world/world_look.gd`, `data/config`
> day-cycle tunables, `export_presets.cfg` and `tools/verify_export.sh` (only if hypothesis 2
> is confirmed), `tools/gate_f/probe_daynight_*.gd` and new probes, `tests/test_day_cycle*.gd`,
> `tests/smoke_night_ecology.gd`. Do not touch `camp_fill_light.gd`, `creature_body.gd`, or the
> art.json night values NIGHT-LEGIBILITY tuned.
>
> **Acceptance.** A written root cause with the probe that demonstrates it on the exported
> binary, the fix, and a regression test that fails on the old code; `docs/CURRENT_STATE.md`
> night row rewritten. If the cause is genuinely hardware-only after all five hypotheses are
> eliminated with evidence, say so with the numbers (minutes to first dusk on a fresh save)
> and add a `--time-scale` user setting so the owner can prove it on the next kickoff run.

## What to do differently this time
1. `git fetch origin && git checkout ralph/W15-NIGHT-0904` if that branch still exists
   (check first — it may have been pruned since it never merged); if gone, start fresh from
   `origin/main` and re-read the one surviving commit's diff via
   `git log -p 45144af3^..45144af3` on whichever remote/reflog still has it, to avoid
   re-deriving the same starting probe from scratch.
2. Actually complete the exported-binary probe the one existing commit started, work through
   the five hypotheses in order, and land a real fix — this brief exists because that lane
   stopped after one investigative commit and never reached a root cause, fix, or report.
3. Write the final report at `ralph/reports/N13-NIGHT-RESUME-0905/REPORT.md` per
   `ralph/briefs/0905-followup/COMMON.md` — this is the one thing the original run never did.

## Acceptance
Same as the original brief: root cause demonstrated on the exported binary, a fix, a
regression test that fails on the old code, `docs/CURRENT_STATE.md`'s night row rewritten with
real evidence — or, if genuinely hardware-only, that conclusion stated with numbers and a
`--time-scale` setting added.
