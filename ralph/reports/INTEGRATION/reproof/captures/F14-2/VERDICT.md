# F14#2 — Water/current network visibly changes and persists

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3
- Commands:
  1. Smoke (rendered, 1280x720): `xvfb-run ... godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --script tests/smoke_tidewake_b_current_restore.gd -- --capture=<dir>` → **exit 0, 87 PASS / 0 FAIL** (smoke_checks.txt), incl. "reload: uniform … (restored set)" and "differs between live and restored" for fleck_amount, speed_scale, min_speed_m_s, brightness, comet_opacity. Frames: smoke_frames/{overview,shore}_{before,after_reload}.png
  2. Matched-pose (1920x1080): `xvfb-run ... --resolution 1920x1080 --script tools/capture_tidewake_b_current_restore.gd -- --out=<dir>` → `F14_2 CURRENT CAPTURE OK failures=0`; S1_{live,restored}_{t0,t1}.jpg (matched_lines.txt)
- Randomised A/B: four pairs in ab/, A/B order randomised per pair by $RANDOM; key withheld from the judge until after its answer (ab/KEY.txt). P1/P2 = matched-pose live vs restored (t0, t1); P3/P4 = smoke before vs after-reload (shore, overview).
- Replaces: TIDEWAKE/b/f14_2_current_restore/PROOF.md and TIDEWAKE/b/f14_2_visible_current/PROOF.md

## Blind judge result

| Pair | Judge pick (calmed) | Confidence | Key | Correct |
|---|---|---|---|---|
| P1 (matched t0) | A | high | A=restored | yes |
| P2 (matched t1) | B | high | B=restored | yes |
| P3 (smoke shore before/after reload) | A | guess — poses differ | A=restored | n/a |
| P4 (smoke overview before/after reload) | A | guess — poses differ | A=restored | n/a |

Judge (verbatim): P1/P2 "a dense, bright white band of streaks runs diagonally past the three sand islands and through the reef … only a few sparse, faint thin streaks remain along the same path. The water colour and the rest of the sea are the same" — the change stays on the authored path, whole sea not repainted, faint residual streaks still show flow direction.
Defects (verbatim): "P3_A and P4_A were captured at a different location or pose from their B frames: open sea with no landmarks. The camera most likely did not reach the intended pose, or the capture fired before it settled. These two pairs are invalid as evidence." "Persistence cannot be judged from single frames."
Judge verdict: **FAIL** (strict: not identifiable in every pair; recapture P3/P4 at matched pose).

## Verdict: FAIL (visible change PASS; visual persistence not shown)

- Visible change: PASS — 2/2 matched-pose pairs identified correctly at high confidence.
- Persistence: numerically PASS (smoke reload uniforms), but the smoke's after-reload frames land on open sea with no landmarks, not the before pose (the after-reload "restored" views show no current or shore at all), so the restored current is never shown after reload. Owning-lane work: after-reload capture at the matched pose (or a pose/camera check after reload).
