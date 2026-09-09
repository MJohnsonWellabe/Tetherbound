# Fresh aim commit race handoff — 2026-09-09

Stop handoff after the third genuine fresh failure in the same aim-verdict class.
Do not run a fourth fresh campaign. No production aim/camera/combat defect has been
established; accurate native stationary/moving/follow cases still pass.

## New exact receipt

Branch head included `3b44f9960`/`cd8f87038`. Root granted one genuine default
`smoke_four_biome_continuous.gd` run after system pressure recovered. It used unused
isolated APPDATA `.artifacts/wave8-memory-watched-fresh-profile`, no arguments, no
prefix stop, injection, copied save or retry.

The run reached a naturally weakened Bramblebun at +88.74s. At the first physical
throw boundary, `.artifacts/wave8-memory-watched-fresh.log:107-109` records:

- helper `input-commit`: camera `(24.96538, 3.049322, -31.53061)`, forward
  `(0.547853, -0.138898, -0.824963)`, player `(26.72267, 0.422268, -36.1136)`,
  target `(29.72923, 1.187151, -40.49218)`;
- current eligible, first hit the target, LOS true, offset
  `1.08311867713928 / 1.132625`;
- preview eligible and clear, offset `1.08771157264709 / 1.132625`;
- actual production commit one process frame later: `eligible=false`, offset
  `1.191 / 1.133`, first hit target, LOS true, `reason=reticle_outside_body`;
- release: `assist=false`, `predicted=none`.

That unassisted orb happened to strike physically at offset 0.158. The race is the
commit verdict changing after the helper's strict boundary check, not an assertion
that this particular orb missed.

This is the named class: readiness was true at the helper's input check, but camera
follow/target motion before production `_physics_process` handled the parsed button
made the actual commit false. Post-settle convergence alone cannot make a verdict
at one phase describe a later phase.

The external operator stop arrived after the helper had begun its next ordinary
throw. That second input check and commit were eligible (`0.637` then
`0.622 / 1.133`) and release retained assist. The live catch completed at +102.09s
with exploration resumed and a two-creature party. The harness printed the earned
opening prefix and had begun ordinary movement toward the Gate Key when its verified
process was stopped. Therefore this run is **OPERATOR-STOPPED on the observed first
off-body commit**. It is not a terminal harness assertion failure or a failed catch.
It does not erase the first stale dispatch and is not permission to continue or
rerun the campaign; the full campaign remains incomplete.

## Healthy memory condition

`tools/allocation_resume_memory_watch.ps1` sampled the real Godot child PID 14108,
not the console wrapper, every two seconds. `.artifacts/wave8-memory-watched-fresh-memory.csv`
has 45 samples: peak private 2.12GB, peak working set 1.65GB, peak system commit 56.7%,
maximum 257 processes. The 90%/400-process safety guard did not fire. Wrapper exit
was -1 because the verified child was stopped under this aim-class stop rule. Owner
save fingerprints are byte-identical; no Godot or watcher remains.

## Focused next question

The next lane must make the physical pad press and readiness observation share an
engine phase whose ordering is proven against camera `_process` and throw
`_physics_process`. It must preserve current eligibility, active aim, and clear
preview; keep the existing time budgets; and use ordinary pad events. A promising
question is whether dispatch immediately after a post-node process callback can
precede the next physics commit without another camera update, while retaining a
physics-refreshed clear preview. Prove the callback order in a tiny native fixture
and demonstrate legacy failure before changing the earned helper.

Do not loosen the body radius, add sleeps/retries, ignore a failed current verdict,
or edit production code without new ownership and evidence. The prior 24/24 native
regression and legacy failure remain valid but did not cover this final process-to-
physics dispatch interval.
