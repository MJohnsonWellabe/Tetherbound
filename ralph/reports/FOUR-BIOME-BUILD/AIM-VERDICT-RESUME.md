# Aim verdict diagnosis and Sol implementation brief — 2026-09-08

Diagnosis only on `codex/four-biome-audit-resume-0908`. No production or campaign
helper edit, fresh opening rerun, save copying, or campaign state injection.

## Named cause and confidence

**Confirmed driver defect: instantaneous camera-angle convergence is treated as
launch readiness while the camera's follow position can still change.**
`tests/helpers/gate_a_opening_drive.gd:782–830` returns success immediately when
the current camera-space yaw/pitch is within one degree, without advancing the
camera after releasing input or checking the production verdict. `_aim_at_wild`
also immediately returns that success. The camera applies look AND exponential
position follow in `scripts/player/camera_rig.gd:278–393`; stopping the right
stick stops rotation input, not follow translation. A previously centered target
therefore need not remain centered at the next launch sample.

The fresh wrapper's `fresh_opening_segment.gd:188–195` correctly added a final
read-only rejection, but this only detects that stale success; it does not make
the driver's convergence contract correct. The ray-to-target first hit is a LOS
measurement, not evidence that the screen-center ray is inside the target.
`throw_aim.gd:669–709` independently computes both facts and correctly rejects
outside-body geometry. No production eligibility/assist change is justified.

## Exact evidence

* `.artifacts/wave6-fresh-campaign.log:180–188`, head `526bb5aac`: two actual
  commits were ineligible, reticle offsets 2.892 and 2.637 against radius 1.133;
  both had target first hit and LOS true. Their unassisted orbs struck fence
  geometry. Terminal result 302.373s was a lost fight. Later neighboring-creature
  obstruction is real but does not explain those earlier off-reticle commits.
* `.artifacts/wave6-fresh-final-verdict.log`, head `10fb6f1db`: final current
  offset 1.18455195426941 exceeded 1.132625, reason `reticle_outside_body`, LOS
  true. Preview agrees within 0.000012; `trajectory_blocked=false`. Failure at
  212.729s preceded orb spending. This is not a stale-preview-only problem.
* Existing `.artifacts/aim-follow-near-baseline.log`: native camera follow alone
  changed offset 0 to 2.632630825 after `_aim_camera_at` returned true, radius
  1.36. The old proposed follow hook also failed its own test after 12 seconds
  despite eligible final geometry; it is not a verified repair.
* New `tools/aim_verdict_resume_probe.gd` isolates this mechanism using real
  camera rig, throw aim, physics target and inherited driver. The player fixture
  is moved 3m sideways while its centered camera has not yet followed. Driver
  reports success at offset 0. One explicit production `_process(0.25)` advances
  follow and changes offset to **2.9094078540802 > 1.36**, LOS still true.
  `.artifacts/aim-verdict-resume-follow-v2.log`: one check, zero failures, exit 0.
* Control omits only that follow update: offset remains 0 and eligible.
  `.artifacts/aim-verdict-resume-control.log`: one check, zero failures, exit 0.
  Both logs contain no engine errors. Diagnostic success means reproduction of
  the defect, not repair or gameplay acceptance. Initial `follow.log` is retained:
  a source replacement failed to insert the follow step, giving one expected-
  diagnosis assertion failure; corrected source then tested the intended cause.

Reproduce with isolated APPDATA and Godot 4.7:
`--headless --path . --script tools/aim_verdict_resume_probe.gd`; append
`-- --stationary-control` for the control. This is a tiny fixture without a world
boot. Its direct fixture pose and manually advanced camera are diagnostic setup,
not permitted campaign actions.

**Remaining uncertainty:** the old fresh logs lack camera/target transforms at
convergence and commit, so they cannot divide the historical movement between
camera follow, target movement and process ordering. Follow is a confirmed
sufficient mechanism, not a claim to have measured the exclusive cause in those
runs. Moving targets can produce the same readiness race. No evidence here
establishes a production input or aim failure for an accurately aimed human.

## Bounded implementation brief for Sol

Outcome: earned fresh capture uses right-stick tracking and the unchanged real
launch verdict, with no stale convergence success between look release and throw.
Own `tests/helpers/fresh_opening_segment.gd`, and request/receive ownership of
`tests/helpers/gate_a_opening_drive.gd` before touching that shared base. Own a
new tiny native regression and relevant additions to
`tests/test_fresh_opening_target.gd`. Do not edit production aim/camera/combat,
invent progression, restore the withdrawn hook wholesale, or widen tolerances.

1. Replace the fresh driver's one-shot aim-then-fatal-check handoff with bounded
   convergence that includes the actual post-look-release camera/physics sample.
   A transient outside-body verdict remains part of the SAME existing convergence
   budget, not a new attempt, extra timeout, extra launch or ignored failure.
   Re-read the live target. Resume ordinary stick steering if that sample moved
   outside; do not merely sleep then return false. Preserve obstruction handling,
   combat-ended handling, budget ceilings and the final strict refusal.
2. Keep production `launch_assist_diagnostics().eligible`, current aiming state,
   and nonblocked preview as required launch conditions. Check readiness at the
   actual input-dispatch boundary; ordinary physical pad events only. Account for
   camera `_process` and throw `_physics_process` sequencing. Never call launch or
   alter rig yaw/position directly in the earned path. If implementation requires
   production changes, return evidence and obtain new ownership first.
3. Native regression must reproduce pre-settle camera-follow success, stationary
   control, and a moving target under real input. Verify eligibility survives
   release/physics refresh through actual throw commit, not a mocked boolean or
   just a one-degree angle. Include a genuine blocked-line negative and ensure no
   orb spend when final current verdict is false. Keep regression tiny; no Terrain3D.
4. Run `test_fresh_opening_target.gd`, `test_camera_aim_response.gd` and the new
   focused native regression; use `smoke_throw_preview_occlusion.gd` if preview
   integration changes. Tests must fail on the old behavior for the named reason.
   Preserve failed first attempts in the report. Two no-yield narrow attempts:
   stop and hand back a focused diagnosis, not another tuning round.
5. Only after root reviews evidence and grants the full-world lease, run one
   changed genuine fresh campaign. Add read-only transform/verdict receipts at
   convergence, post-settle and input commit so a failure names what moved.
   A third same-class fresh failure requires a fresh focused handoff; never a
   fourth repetition. Full chapter, four-biome and Beta Ready remain unproved.
