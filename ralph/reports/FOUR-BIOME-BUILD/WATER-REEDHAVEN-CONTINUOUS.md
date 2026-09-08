# Water Reedhaven continuous segment

Status: production-world controller traversal passed through the paid
Reedhaven repair.

## Scope

`tests/helpers/water_reedhaven_segment.gd` is a composable controller-only
segment. Its caller must supply the already-running production Water tree,
world, player and camera at the physically earned east lesson landing. The
caller must also carry the campaign-earned knife and axe. The helper does not reset the
game, select a realm, move an actor directly, add a party member, grant a tool,
add resources or write a progression fact.

The driven sequence is:

1. fail closed unless the lesson is earned, the departure is unrepaired and a
   real knife and axe are present on controller hotbar actions;
2. walk from the east lesson landing to First Shore's departure;
3. swim the authored 82.272m
   `first_shore_to_reedhaven_sheltered` route and land dry;
4. walk the production Reedhaven spine and gather these exact disposable
   production nodes through `InteractionArbiter` and controller input:
   - `water:reedhaven:harvest:019`: 3 reed fiber, visible knife swing;
   - `water:reedhaven:harvest:017`: 3 driftwood, visible axe swing;
   - `water:reedhaven:harvest:003`: 3 driftwood, visible axe swing;
   - `water:reedhaven:harvest:001`: 3 reed fiber, visible knife swing;
5. activate the production `reedhaven_repair` prompt and require the world
   flag plus the exact 6-reed/4-drift charge.

The selected nodes are not substitutes invented by the harness. Their authored
main-route distances are 24.677m, 45.424m, 15.696m and 19.106m respectively;
their analytic sampled slopes are 5.234, 5.720, 3.335 and 6.115 degrees.

## Evidence so far

- Godot 4.7 `--check-only` on
  `tests/helpers/water_reedhaven_segment.gd` and its focused test: exit 0.
- `tests/test_water_reedhaven_segment.gd`: 2 tests, 16 assertions, 0 failures.
  It proves an unrun or failed segment cannot report a vacuous successful
  result; success requires the explicit terminal completion bit and no errors.
  It also checks every selected node and helper tool through the real
  `ItemDB.gathered_with()` API.
- `tests/test_water_dock_rules.gd`: 2 tests, 0 failures.
- `tests/test_water_harvest_density.gd`: 1 test, 0 failures.
- `git diff --check`: clean.

The first composed production attempt reached Water arrival, Pell, 64.488m of
observed lesson swimming, Reedhaven and the first node through ordinary controls,
then correctly received no yield from reed `:019`. The cause was an exposed data
contract mismatch: its placement metadata said `hand`, while the live ItemDB
requires `knife` for `reed_fiber`. The helper now requires/equips the inherited
knife, both selected reed rows say `knife`, and the focused test prevents either
copy drifting from the ItemDB again. No production tool gate was relaxed. Log:
`%TEMP%/water-opening-reedhaven-first.log`.

The corrected composed production run then passed the complete bounded segment:
ordinary human crossing, all four named controller-driven harvests, exact
six-reed/six-drift gathering, exact six-reed/four-drift repair payment, and the
production repair flag. The helper returned `ok: true` with `failures: []`.
The log scan found no `ERROR` or `SCRIPT ERROR`:
`%TEMP%/water-opening-reedhaven-corrected.log`.

This proves the bounded Water-arrival-through-Reedhaven route with the disclosed
pre-arrival knife/axe fixture. It does not prove the preceding Stormwood party
transfer or the later Water chapter path.
