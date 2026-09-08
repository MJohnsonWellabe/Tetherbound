# Earned material approach and felled wood teardown — 2026-09-08

The preserved `.artifacts/wave3-fresh-cycle-campaign.log` ends at 624.73s after
the earned five-member team and ten ordinary training wins. Materials reached
wood 31/42, then the vegetation target at `(45.44735,-0.188587,-62.50097)` failed
to yield. The final diagnostic shows the player 5.29m away, target stock still3,
axe equipped, no swing, and EncounterDirector's non-actionable priority-2
`Put Bramblebun away` status. That distance is after inherited repositioning
attempts; it does not establish the initial walk's endpoint or a false walk
success. No unchanged campaign rerun was used.

## Approach defect and bounded fix

Inherited `gate_a_material_route.gd::_stand_where_it_wins` first waits for the
target prompt, then calls `_clear_a_statement_off_the_button`. That method
treated every non-actionable director offer as a lockout, recalled and continued
without taking its planned physical approach step. Production's ordinary
`Put away` (-2) / `Call out` (-1) offers are explicitly fallbacks below all
ordinary actionable offers. They do not suppress a nearby valid harvest prompt;
their presence means the desired prompt is unavailable, including by distance
or obstruction. Recalling cannot repair that distance or line of sight.

The earned material helper now overrides only that policy: priority0 or lower
does not trigger recall, allowing the existing approach step to execute. The
priority100 fainted-creature lockout still uses the inherited recall behavior.
No prompt radii, walk/attempt budgets, harvest yields, retry counts, skip policy
or inventory/progression were changed.

`tests/smoke_material_prompt_priority.gd` uses the actual Player, navigator,
controller movement bindings, Interactable and InteractionArbiter. Only the
status provider and observation of recall are test doubles. From a 5.29m
fixture distance, the old helper uses all ten approach attempts recalling and
does not move at all. The fixed helper walks to `(1.149866,-0.001167,0.221007)`,
offers the exact Chop prompt and issues zero recalls. A priority100 control
still dispatches exactly one recall. **10 assertions passed, terminal exit0**,
no errors or warnings in `.artifacts/material-prompt-priority.log` or its unique
`material-prompt-priority-engine.log`. The original vegetation terrain/collider
layout is not reconstructed by this focused test; its full campaign acceptance
remains root-owned.

## Two material errors: independent actual lifecycle reproduction

The earlier successful scatter harvest at `(45.07986,-3.781128,-12.3723)` paid
wood +3 but emitted two `material_get_instance_shader_parameters` errors from
Godot's dummy renderer. A tiny real-tree diagnostic,
`tools/_probe_felled_material_lifecycle.gd`, reproduced exactly those two errors
by creating the actual felled-resource wood pile, waiting five process frames,
then freeing it. Setup was clean; both errors occurred during destruction.
No Terrain3D or vegetation instancer was involved.

Original log: `.artifacts/felled-material-lifecycle.log` and `-engine.log`,
exit0 but **two engine errors, not a clean pass**. Separate controls retained
source/override Material references until after node destruction, or detached
meshes before destruction. Both controls removed the errors:
`.artifacts/felled-material-hold{,-engine}.log` and
`.artifacts/felled-material-detach{,-engine}.log`.

Root authorized the minimal production lifetime fix in `felled_resource.gd`:
on `NOTIFICATION_PREDELETE`, detach descendant meshes while their material
resources are still alive, before normal child/resource destruction. This is
not an `_exit_tree` cleanup and is not conditional on headless rendering.
Live appearance, harvesting and payout behavior are unchanged. It does not
erase meshes when a live pile is temporarily removed/re-added.

One changed actual wood-pile lifecycle run: **terminal exit0, 1.46s**, all
**three mesh identities preserved** across remove/re-add, then destruction
without ERROR/SCRIPT ERROR or WARNING. Logs:
`.artifacts/felled-material-fixed.log` and `felled-material-fixed-engine.log`.
This is lifecycle validation, not a rendered visual acceptance claim.

## Focused checks and remaining limits

Existing `test_meadows_earned_material_segment.gd` plus
`test_harvest_permanence.gd`: **23 tests, 221832 assertions, zero failed**,
terminal exit0. The output is not clean: it contains **24 engine errors** from
off-tree fixture setup (`_pile_colour` / `_pile_kind` absolute `get_node` and
`pickup_glow::_field_for` calling `get_tree`), and **three scatter-placement
warnings**. None is the material-lifetime error; none points to the new
destruction callback. These fixture anomalies were disclosed to root, not
suppressed or expanded into another production repair. Logs:
`.artifacts/earned-material-focused.log` and `earned-material-focused-engine.log`.

`git diff --check` passed. All native invocations used separate isolated
APPDATA profiles and unique engine logs; no campaign save was reused, no
full-world run or imports performed, and no commit/push by this lane. Source
is frozen for root's changed campaign run and CI integration.
