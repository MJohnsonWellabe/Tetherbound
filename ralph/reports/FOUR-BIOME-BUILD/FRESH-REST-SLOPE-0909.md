# Fresh rest with slope-aware navigator — 2026-09-09

This was one fresh, isolated `--through-rest` run with the changed shared navigator. It stopped on the first scenario failure and was not retried.

The run used `.artifacts/opening-prefix-c3e-0909/fresh-through-rest-slope-1200/run.ps1` with a blank APPDATA/LOCALAPPDATA profile, the canonical headless smoke entry point, and unchanged 1,200-second, 90%-system-commit and 400-process limits. It exited 1 after 600.8 seconds without a guard stop. Terminal Godot census was zero.

Opening passed through the first earned live catch at +97.55 seconds. The village key and gate completed at +105.04 seconds. NPC dialogue, tool acquisition, Satchel assignment, and Wood/Stone/Fiber tool gathers completed. The run built the five-creature roster and recorded ten visible numbered training-win receipts before entering materials. A real physical throw miss was followed by continued combat and progression; the log does not directly record `combat.is_aiming()` at the inherited wander call, so it is not direct branch-state proof.

Materials earned Wood 19/18 and Fiber 18/18. The first Stone target then failed. The terminal receipt was:

`stone swing credited nothing (arbiter winner=EncounterDirector ... Put Bramblebun away ... actionable=false, wanted=Interactable @(90.8,95.6), 1.88m away, equipped=pickaxe, swinging=false, node stock=2)`

The requested prefix did not pass. Camp and Rest were not reached. This failure does not invalidate the focused slope physics smoke or the retained copied-state bed-direction pass; it also provides no fresh rest acceptance.

Artifacts and hashes:

- `console.log`: SHA-256 `35476b4b97d30ea9d1dfe72ad33a19af69ae4dd6b73bcc76ae7c11f28cef3fb1`
- `result.json`: SHA-256 `ddf30639c8622dc833cde33955d03246dc19220f2cd2e2c39f8dfab812ab6158`
- `stderr.log`: SHA-256 `4be629d0bba0ea057629f943d81adc7da933f5a682c9efd5ea158546f9c81432`; it contains only the existing deprecated interpolation warning from `playground_world.gd:1092`.
- Fresh slot: SHA-256 `bf96dc73cb87d7cd5602bddafabdc81583c01a8c8eb2d9e2a0b79e3ebeef57c2`
- Fresh character: SHA-256 `6548bdfa70330719e50bdc334ecab76fe78c010ff3f7de2c0f6c5bde27a05b8b`
- Fresh world: SHA-256 `dc352f3c55e319df6f6805c318e30fc2cbffeff0e38e256ecadc2d4e8aad18b2`
- Navigator: SHA-256 `e8ae08d855be2de9b020db611ddc0c419f86edb555beb5eca1cec18f50ef9345`
- Focused navigator smoke: SHA-256 `b04f530bec667feaef6a61a717c22af102de0eae56d527bf693820d1330bae69`

Maximum observed system commit was 62.4%; maximum process count was 264.

## Stone-offer diagnosis

The EncounterDirector fallback is evidence that no actionable harvest offer existed at the sampled poses, rather than evidence that it outranked one. `_creature_control_offer()` gives “Put … away” priority -2. The stone Interactable uses ordinary priority 0, so it wins whenever it returns an offer. The material helper also deliberately does not recall for a priority-at-or-below-zero fallback.

The target node stood at `(90.78217, -7.178252, 95.62292)`. Its prompt/fan-out Y was `-4.702163`, 2.476089 m above the node. This matches `vegetation.gd::_spawn_harvest_point()`: Stone uses `prompt_height = 1.0 + placement.scale`, so this placement's scale was approximately 1.47609. The prompt radius is 2.6 m and `interactable.gd::interaction_offer()` uses full three-dimensional distance.

The final fan-out supplied several successful movement arrivals, but their closest measured pose was still 2.71 m in 3D from the elevated prompt: horizontal 1.62 m, player Y -6.87. Other arrivals were farther. The final diagnostic explicitly reported clear sight, combat inactive, no input owner, pickaxe equipped and visible, and node stock 2. Therefore tool state, stock, combat lockout, line of sight, and arbiter priority do not explain the missing offer. The elevated spherical prompt and the fan-out's reachable contact positions do: every sampled 3D distance remained outside 2.6 m.

The source already documents this exact geometry for Wood and fixes Wood by using `HUMAN_PROMPT_HEIGHT`; Stone alone still scales prompt Y. The narrow production candidate is to use the same human-height prompt for standing Stone. That changes offer placement rather than navigation tolerance, walk budget, inventory, or arbitration.

Before changing production, a bounded regression can author a collision body with this run's 1.476 scale, instantiate the real vegetation harvest point and Interactable plus the real Player/arbiter, and place the player at the measured closest reachable pose. It should show the current Stone prompt returns no offer while a human-height prompt returns actionable priority 0 and beats the loose priority -2 EncounterDirector-style fallback. A negative control should keep a player genuinely outside the 2.6 m sphere ineligible. A retained-copy single-node check could then verify the real Stone prompt wins and one physical pickaxe swing reduces stock; it would not claim earned continuity. No tolerance or frame budget should change.
