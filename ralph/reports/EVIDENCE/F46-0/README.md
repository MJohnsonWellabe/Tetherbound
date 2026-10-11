# F46#0 — lessons introduced as each system unlocks; each skippable

systems-a, Sun 11 Oct 2026, on bd3c20ba + the new unit test.

| Part | Proof | Result |
|---|---|---|
| Each lesson becomes due only when its own system unlocks for this character, in authored order, once | NEW `tests/test_onboarding_lesson_triggers.gd` (12:42 PM CT). The trigger is the production `lesson_rules.available/due` read of real PlayerState. | 2 tests, 150 assertions, 0 failed |
| Every lesson (all 8: home_key, homestead, altar, masters, feasts, traits, portals, shrines) skips at every line; menus refused; departure releases input | `tests/smoke_modal_stacking.gd` (12:41 PM CT) | PASS |
| In-world: Grandpa teaches the real Home Key lesson with pad input | `tests/smoke_opening.gd` (12:42–12:45 PM CT) | PASS ("read 2 lesson lines with the pad and returned to exploration") |

Teachers per `onboarding.json`: Grandpa (home_key, homestead, altar, traits), Tam (masters, feasts, portals, shrines).
The new unit test is disclosed as this criterion's work: no test covered the seven non-Home-Key triggers.

Not claimed: in-world delivery of the other seven lessons on an earned route. That belongs to the route lanes' journeys.

Verdict: PASS (trigger rules unit-proven for all 8, skip proven for all 8 in the real panel, one in-world witness)
