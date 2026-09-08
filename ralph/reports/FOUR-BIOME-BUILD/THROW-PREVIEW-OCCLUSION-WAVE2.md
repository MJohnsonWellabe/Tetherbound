# Throw preview physical obstruction — 2026-09-08

The fresh campaign's second catch exposed two different questions. In
`.artifacts/wave2-fresh-local-supply-campaign-engine.log`, four camera rays
reported the intended `Wild_mudsnout_1070_2` eligible with line of sight, but
the physical orbs struck neighboring `Wild_mudsnout_1070_1` after 0.15–0.18s.
The fifth orb reached the target too late to save the fight. Camera eligibility
is an assist gate, not a guarantee that the lower hand trajectory is clear.

The production preview previously checked the target sphere and terrain height,
but no physical bodies. It could draw a successful arc through another creature.
The manager also accepted camera eligibility even if the preview did not reach
the target. This was a real UI mismatch independent of the campaign driver's
failure to reposition after a physical miss (root owns that separate repair).

`throw_preview.gd` now queries each sampled trajectory segment for the nearest
physical body, using the actual thrower's/owned ally's exclusions from
`throw_aim.gd`, plus the target exclusion used by the orb. A target-sphere entry
fraction orders target entry against obstruction within the same segment; an
obstacle beyond target entry cannot incorrectly veto an already landed throw.
The report exposes `trajectory_blocked` and the observed collider name. The
manager's HUD lock explicitly rejects an observed obstruction before applying
its existing eligible-or-preview-hit rule. Hiding the preview clears the result.

Actual orb physics, collision handling, assist eligibility, resource spending,
input budgets, and thresholds are unchanged. Terrain height fallback remains.
`catch_aim_offset` remains a conditional-on-strike placement estimate: the actual
reticle suppresses its percentage and displays `NOT ON TARGET` while unlocked
(`capture_reticle.gd::_draw_readout`), so a blocked aim no longer displays a
misleading capture percentage. No visual appearance redesign or rendered visual
acceptance is claimed by this behavior test.

Validation used an isolated APPDATA profile under
`.artifacts/throw-preview-occlusion-profile`, no campaign world, no imports,
no save loading, and no production gameplay mutations beyond the code above.

- Initial fixture failed: `.artifacts/throw-preview-occlusion.log` and
  `throw-preview-occlusion-engine.log`, 20 assertions, 4 failed. Instantiating
  the orb script directly omitted its required Mesh node and caused native
  script errors. The fixture was corrected to instantiate the same packed
  orb scene as production release; no production null guard was added.
- Corrected `tests/smoke_throw_preview_occlusion.gd`: terminal exit 0, 2.67s,
  **24 assertions, 0 failed**, no ERROR/SCRIPT ERROR or warnings in
  `.artifacts/throw-preview-occlusion-v2.log` and its unique `-v2-engine.log`.
  An elevated camera remains eligible in all three flight cases. The real
  orb hits the neighbor and preview/HUD reject it in the obstructed case;
  the clear and excluded-own-ally controls both physically strike the target
  and retain the HUD lock. Two additional real-physics preview controls put
  a blocker before/after target entry inside the same one-metre sample.
- Existing focused tests `test_orb_passes_your_own_creature.gd` and
  `test_throw_reach_and_miss_message.gd`: terminal exit 0, 1.70s,
  **10 tests, 32 assertions, 0 failed**, clean
  `.artifacts/throw-preview-focused.log` and `throw-preview-focused-engine.log`.
- Native loading parsed the production preview, aim, manager and orb scene.
  `git diff --check` passed. Root is registering the native smoke in combat CI.

This is a current-geometry prediction, not a promise about a moving blocker
later in flight. Sampling retains the existing 32 segments and ballistic
parameters; actual orb integration remains unchanged. Full campaign evidence
and exact-head CI are root-owned and were pending at this report's completion.
