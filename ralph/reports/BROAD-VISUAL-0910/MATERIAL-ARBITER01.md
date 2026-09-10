# Earned material arbiter diagnostic 01

Status: three focused attempts failed and are preserved. Provider diagnostics establish that the five rejected neighbouring `Chop` offers were stone while the route needed wood. The narrower refused-supply policy in the Meadows earned-material segment passed copied-save physical gathering and paid camp placement at 07:24 UTC. A fresh continuous run now passes gathering, camp, rest, and all tournament rounds, reaches the South Bridge guardian, and fails its generic guardian outcome assertion; focused replay is pending and no full continuity claim is made.

## Original continuous failure

`continuous-through-bridge-first` stopped during the earned material stage after 688.294 seconds, at `reached=earned_team`. The player held the axe and was not swinging. The route wanted the wood prompt at approximately `(79.0, -44.1)`, while the production arbiter correctly offered another actionable `Chop` prompt at approximately `(79.5, -45.4)`, 1.54m from the player. The selected node retained stock 3. This is evidence that the physical input did not target the fixture's preselected node; it is not evidence that harvesting or axe input was broken.

## Focused failures

The first copied-save run, `retained-material-arbiter-first` (05:59:51–06:02:43), adopted one compatible neighbouring wood source and earned 3 wood, reaching stock 13/18. It then returned to the contested `(79.0, -44.1)` route target, exhausted 39 approach legs and failed with the nonactionable `Call out Bramblebun` statement holding the line 5.38m away. That partial progress disproved the first correction as sufficient.

The second copied-save attempt also failed after the same 39-leg pattern from 06:17:08 to 06:20:05. During the exact target's wait, `Chop` prompts at approximately `(79.7, -42.8)` and `(79.5, -45.4)` became the production winner. They were initially inferred to be compatible wood offers missed by the helper's timing. That inference was wrong: later identity instrumentation proved they were stone. The earlier interpretation is preserved here as a rejected hypothesis, not the diagnosed cause.

The third copied-save attempt failed from 06:42:31 to 06:45:29 with no engine errors. It again earned 3 wood from one adopted neighbour, reached stock 13/18, then exhausted 39 approach legs. This disproves the per-frame sampling change as a complete correction. A compatible-looking `Chop` winner was visible in the production transcript, but `_compatible_offered_supply` rejected it. The remaining question is which approval/resource/provider predicate differs for that live node; changing stance or wait timing again before logging those predicates would be guesswork.

The subsequent `retained-material-provider-diagnostic` run (06:48:43–06:51:39, exit 1, no engine errors) resolved that question: all five nearby `Chop` providers rejected by the compatibility filter reported `stone`, not `wood`. The filter was correct. This was neither a missed compatible prompt nor evidence that production wood input was broken. Root preserved and withdrew the compatibility-hook experiment, then restored both shared helpers to HEAD before the correction below. The diagnostic hook patch is preserved at `.artifacts/broad-visual-0910/material-provider-diagnostic-tool.patch`, and the failed helper patch at `material-compatible-provider-03-withdrawn.patch` in that directory. The original diagnostic tool is restored because it no longer has that withdrawn hook to override.

## Withdrawn compatibility experiment

The generic Gate A helper retains its former exact-target stance behavior by default. Only `meadows_earned_material_segment.gd` opts into equivalent-provider selection. Its wait now reads the production arbiter every physics frame and accepts only one live, approved harvest provider whose `resource_item()` matches the requested item for eight consecutive frames, the existing stable-prompt threshold. It returns that actual node to the unchanged physical press, tool swing, felled-pile lookup, physical pickup and inventory-receipt path. Wildlife, statements, wrong resources, stale nodes and unapproved scripts remain refusals.

`earned-material-contracts-second` exercised 26 tests / 221,851 assertions with zero assertion failures and no new helper parse errors from 06:10:18 to 06:10:42. The wrapper was not clean: 24 pre-existing off-tree errors arose in the harvest-permanence fixture through `felled_resource._pile_colour/_spawn_felled`. This run is source/contract coverage, not clean runtime evidence.

## Current bounded correction

The shared `gate_a_material_route.gd` remains unchanged. `meadows_earned_material_segment.gd` now adopts the base route's established refused-stand policy within its existing 64-stop loop: after a real walk and unchanged physical harvest attempt exhaust against one live target, it records that target's instance id and exact failure reason, removes the tolerated failure from the run verdict, and selects another live supply of the same requested resource. Only actual inventory gain resets the consecutive-refusal counter. More than the existing `REFUSALS_ALLOWED` five consecutive refusals remains a hard failure. The physical press, eight-frame stable-prompt rule, LOS, equipment, felled-pile pickup, inventory receipt, campsite cost and stop bound are unchanged; there is no resource grant.

`test_meadows_earned_material_segment.gd` adds a selection assertion showing that a refused nearer scatter target yields to the remaining authored wood target. Its actual caller, `smoke_earned_material_selection.gd`, passed five assertions cleanly at 07:08:38–07:08:43. The original 688-second failure and all three focused failures remain part of the evidence.

## Focused physical success and its limits

`retained-material-refused-stand-first` ran clean at 07:18:31–07:24:37 UTC, exit 0, no engine errors. It started from a separately copied original failed save (source/copy slot SHA256 `03483257F6CC6630C79E048B0AD523CE45FB2CFF7A693BCE6CB21F849CAD5DA2`). The route earned wood to 19/18, fiber to 18/18 and stone to 8/8 through actual walking, tool actions and pickups, then returned to the campsite. It recorded one refused wood stand and two refused stone stands, retaining their reasons. The highest consecutive refusal streak was two, below the existing five-refusal allowance. No cost or resource identity was relaxed.

The following camp diagnostic built a paid campsite and one creature bed through real build placement. It did not run all creature-care rests, a tournament or bridge opening. This is copied-save material/camp evidence, not fresh continuity. A new canonical opening-through-bridge prefix remains required before calling the original failing path repaired.

## Fresh continuous-through-bridge-second checkpoint

`continuous-through-bridge-second` ran from a fresh campaign for 1,207.545
seconds and exited 1 at `tournament_won`. The actual production path passed the
Gate A dialogue/tool leg and three physical gathers (axe +4 Wood, pickaxe +4
Stone, knife +4 Fiber), then passed paid camp placement. Rest passed for five
creatures across days 2–6 with `fed`, `happy`, `ready`, and `rested` true and no
reasons. The quarter, semi, and final tournament rounds passed through real
opponent defeats and landed attacks: 2/15, 2/28, and 3/47 respectively.

The bridge helper reached and admitted the exact `south_bridge_grunt` at depth
`-11.51806640625`, but the run ended with the generic assertion
`Guardian did not yield the exact real team victories, hits and durable defeat`.
The terminal result is `campaign_complete=false`, `reached=tournament_won`, and
`requested_prefix_passed=false`. The current receipt does not identify which
guardian subcondition failed; the retained slot is suitable for the focused
bridge replay described in `CONTINUOUS-BRIDGE-DIAGNOSTIC01.md`. Until that replay
isolates the guardian result, this is evidence of the passed prefix and a
bounded guardian failure, not a full continuity pass.
