# F04 #2/#3/#6 evidence, round 1 (meadows-f04-bosses)

**Runs** (local xvfb + opengl3/llvmpipe, 1280x720; `tests/smoke_meadows_f04_bosses_run.gd`, the continuous Meadows
smoke plus a passive frame observer). Every fight is the production fight, won by the smoke's own controller-input pilot.
- Captains: `--resume-from=<tb/meadows-route b0f269d9 relay-checkpoint-seed15> --through-hall --fight-log
  --f04-render-captures-only`. Oreth won 68.2 s, Halder 68.3 s, Vess 55.3 s (`logs/captains.log`). The run ends at the Hall
  (declared prefix; resumed runs report counts_as_proof false).
- Warden: `--world-seed=4 --resume-from=seed4_hall --m4-finale --through-meadows --fight-log`. Run 1 (`--f04-render-fights-only`,
  `fightsonly-*` frames, `logs/warden.log`): won 97.0 s, M4 PASS 1. Run 2 (captures-only, `logs/warden2.log`): won 97.8 s,
  M4 PASS 1, with the victory-dialogue frame. One further re-run hit the harness's 9000-frame fight deadline mid-ACE
  (live-combat variance; not in this directory). Runs were stopped after the aftermath frames (wind-down), so no full
  M4 RESULT is claimed.
- `captains_r0.log`: the "before" run (no victory_conversation): 2.5 s after Oreth's win the player is already walking off.

**Frames** `frames/<fight>-m<member>-<species>-t1-{a-start,b-mid,c-strike,d-recovery}` (named member's first tell),
`-entry` (1.5 s after send-out), `-after-{03,05,08,12}s`, `-after-dialogue`; JSON sidecars list bodies in frustum,
visible HUD text and (later runs) other creatures near the camera. `fightsonly-*` frames rendered continuously.

**Shortcuts disclosed:** declared start saves (relay-checkpoint-seed15 from tb/meadows-route, seed4_hall); render loop off
outside captures (captures-only) or outside target fights (fights-only), physics/AI/input unaffected; t2 frames dropped
and JPEG q72 to keep size; the Warden's handover frame is 0.25 s after the panel opens.

Verdict: `VERDICT.md` (no row closes).
