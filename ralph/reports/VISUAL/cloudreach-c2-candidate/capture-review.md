# Cloudreach capture fixture review

Disposition: **no blockers found** in the bounded diff to `tools/capture_cloudreach_frame_matrix.gd` against HEAD. Source review only; no engine run, no scene/spire review, and no repository edits. This report is the only written artifact.

The diff removes `fly_tutorial_completed` from BOOT_FLAGS, replaces `_place_companion()` with an awaited native-follower interval, and awaits that interval in both static and motion capture setup. The existing direct party/progression fixture and trainer teleport remain explicitly disclosed in the file; this change does not turn these frames into earned traversal/progression proof.

## Flag removal

`fly_tutorial_completed` has no entry in `data/progression/flag_scopes.json`; `fly_traversal_unlocked` does (line 117). The merged progression writer rejects unknown scopes (`autoload/merged_progression.gd:55–72`). Removing the unscoped attempted write is appropriate, while retaining the actual Fly unlock preserves the relevant capture gating. Repo searches found the removed flag only in the chapter data's persistent list and an objective reward, with no direct script consumer or `requires_flags` dependency. The stale chapter data is outside this change; describing the flag as obsolete for this fixture is justified, but it is not absent from all repository data.

## Native follower semantics

- `tools/capture_cloudreach_frame_matrix.gd:529` and `:774` both await `_settle_companion()` after seating the trainer and orienting the production camera. `_settle_companion()` at lines 662–669 yields 120 physics-frame signals and does not place, resize, hide, or otherwise override the companion.
- Summoning uses the production director, which creates a `follower_creature.gd`, assigns the trainer as leader, and enables following (`scripts/combat/encounter_director.gd:1380–1421`). The Cloudreach director assigns its collision-aware station validator when grounding that ally (`scripts/combat/cloudreach_encounter_director.gd:645–652`).
- The native follower ticks during physics, uses the current camera for its safe flank/depth, and snaps back through its verified-floor placement when its planar gap exceeds the 45 m leash (`scripts/creatures/follower_creature.gd:215–249`, `:298–315`, `:406–444`). This directly supports letting it recover from the fixture's large stand teleports and then choose the same formation it uses in play.
- Disabling the render loop only toggles `RenderingServer.render_loop_enabled` (`tools/capture_cloudreach_frame_matrix.gd:693–694`); the fixture does not disable the follower's physics or pause the tree for this wait. The extra native simulation interval is therefore effective. The capture setup waits for it in both modes; the motion witness's timer starts afterward, so its advertised 30 seconds of input-driven motion is unchanged.
- Removing the old fixed offsets avoids manufacturing a companion station smaller than the runtime's visual-envelope-aware placement. The native behavior remains visible, including any inability to find a safe station, which is appropriate visual evidence.

## Evidence limits and minor robustness observations

120 ticks are an observation interval, not a convergence assertion. At 60 Hz they provide about two simulated seconds. The runtime can take longer in some situations: it only leash-snaps beyond 45 m planar distance, and its stranded-below-trainer recovery defaults to three seconds (`scripts/world/cloudreach_companion_fall.gd:61–62`). Consequently the resulting capture proves the native follower's state after this interval, not universally settled formation or successful companion recovery. No guarantee beyond that should be inferred from the helper name. This is not a blocker for the stated visual capture correction.

The helper retains the ally reference across the await and reads it without a second validity check at line 669. No dismissal/replacement trigger was identified in this unattended setup; a future capture mode that changes party/deployment during the wait should re-fetch `_ally()` afterward. Similarly the static manifest records the helper's observed position before the subsequent pose/render frames, so it is a setup-time position rather than exact screenshot-time telemetry. Neither issue introduces fixture placement or invalidates the actual image.

No runtime or visual pass is claimed by this source review.
