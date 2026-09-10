# HUD freed interaction winner lifecycle

Status: **retained; focused lifecycle and existing legend smokes are clean.**

## Cause and correction

`InteractionArbiter` caches its last `_winning_provider` until the next
recompute. A realm interaction provider can be freed while the longer-lived
arbiter and `PlaygroundHUD` still run. The available-action legend polls prompt
ownership every frame, so it can read that cached provider during this narrow
teardown window.

`PlaygroundHUD._prompt_belongs_to_combat()` assigned the return value of
`winning_provider()` directly to a typed `Object`. When the returned reference
was stale, Godot rejected the assignment before a following null check could
run: `Trying to assign invalid previously freed instance`. The correction
keeps the return value as `Variant`, gates it with `is_instance_valid()`, and
casts to `Object` only after validity is established. Valid
`EncounterDirector` ownership still suppresses the duplicate Call Out/Put Away
legend entry; a freed winner is treated as absent.

## Runtime evidence

The green CI AD9 workflow was not runtime-error clean. Two Gate A UI sequences
and one core-verb sequence logged the same uncaught error at
`playground_hud.gd:3603`, through `_prompt_belongs_to_combat()`,
`_recall_prompt_is_already_present()`, and
`_update_exploration_legend()`. The later fresh through-bridge fourth run
reproduced the same error 21 times before this correction.

The focused smoke uses the production HUD and `InteractionArbiter`, plus the
real `EncounterDirector` provider methods bound to an actual `Game.party`
creature and ally body. It publishes the real Put-away offer, verifies director
ownership and legend de-duplication, frees the winning director without first
unregistering or recomputing, and then verifies the stale read is safe. It also
checks that Call Out returns while the unavailable Change Creature action stays
absent.

The first guarded run,
`.artifacts/broad-visual-0910/runs/hud-freed-winner-first`, ran from
2026-09-10 10:51:17 to 10:51:22 UTC. Its behavior checks passed, but it was not
clean: the fixture had constructed the director outside the tree, so the real
provider's `BUILD_HOLD` query logged `Parameter "data.tree" is null`. That
failed receipt is preserved. The fixture was corrected to give the real
provider a live tree without mounting encounter population.

The corrected run,
`.artifacts/broad-visual-0910/runs/hud-freed-winner-second`, ran from
10:54:44 to 10:54:49 UTC. All focused checks passed, Godot exited 0, the error
list was empty, and the process census was empty. The existing exploration
legend smoke then ran independently at
`.artifacts/broad-visual-0910/runs/hud-legend-after-lifetime-first` from
10:52:53 to 10:52:58 UTC, also exiting 0 with no errors.

The focused smoke deliberately constructs the stale cache interval; it does
not claim every realm teardown path was replayed. The repeated CI and fresh-run
stack traces establish that this interval occurs in production integration,
while the clean focused and existing-legend runs establish the bounded caller
guard and preserved availability/de-duplication behavior.
