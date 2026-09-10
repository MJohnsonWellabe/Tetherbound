# Continuous South Bridge diagnostic 01

Status: **FOCUSED PASS; FRESH CONTINUOUS RECHECK PENDING**.

## Fresh run

`continuous-through-bridge-second` ran headless from a new campaign for
1,207.545 seconds and exited 1 at `tournament_won`. Materials, camp, rest, and
all three tournament rounds completed through their production paths. The bridge
helper then recorded `guardian_admitted` for exactly `south_bridge_grunt`, but
ended with `Guardian did not yield the exact real team victories, hits and durable
defeat`. Engine log contains only the pre-existing physics-interpolation deprecation.
The run's source inventory recorded 1,028 unchanged files.

The line `[village] 'south_bridge_grunt' offered a battle that could not start`
does not establish that no battle opened. The gate routes the guardian's challenge
through `trainer_npc.gd`, while the conversation's authored `battle:` effect also
queues `sequence_director.gd`. Both consume the same dialogue-finished event. One
can start the battle and the later duplicate is then correctly refused because a
trainer battle is already active. The helper's immediately following
`guardian_admitted` receipt proves the exact director battle was active at that point.

The terminal assertion combines four facts: deadline, trainer-active teardown, two
won combat exits, at least one landed hit, and the durable defeat flag. The existing
log prints none of those individual values, so it cannot identify which fact failed.

Source inspection explains why a normal loss would be reported by this combined
message. `EncounterDirector._on_trainer_round_ended()` synchronously calls
`_finish_trainer_battle(false)` on a lost combat, clearing the trainer spec. The
bridge driver loops only while `trainer_battle_active()`, so after that signal it
exits the loop before its inner non-fighting branch can observe and name
`CombatManager.outcome == "lost"`. This is a diagnostic/reporting blind spot, not
evidence that production failed to end the fight.

A real loss was subsequently reproduced by the focused trace. The
retained team has only two living neutral-type Bramblebuns. `_prepare_ally()` heals
only the highest-HP level-7 body to just over half health; the guardian fields a
level-10 Mudsnout followed by a level-12 Burrowback. The shared campaign pilot's
optional cycle occurs only for a negative matchup, so neutral Ground-versus-Ground
does not switch merely because the active body is injured. The tournament used the
same driver successfully, but it began from the rested team and its three rounds are
the reason three members are now fainted.

## Focused result

`bridge-retained-focused-first` ran from 08:27:37 through 08:29:30 and exited 1.
It used one carried small potion on the level-7 Bramblebun, raising it from 62.263
to 97.263 HP. That fighter defeated the level-10 Mudsnout in 14 recorded hits and
entered the level-12 Burrowback round with 22.950 HP. The guardian battle then ended
in a real `CombatManager.outcome == "lost"`: one enemy victory, 28 landed hits, the
second enemy still at 43.563 HP, the trainer director inactive, and the durable
defeat flag false. This explains the fresh run's combined terminal assertion.

The old trace labelled only `EncounterDirector.ally_instance()` as the ally. Its HP
reached zero while the second enemy continued taking damage for about seven sampled
seconds. Source inspection shows that trainer fights automatically select the next
usable party member inside `CombatManager`, while the director's original ally
reference can remain unchanged. The diagnostic now records both that director
reference and `CombatManager.active_creature()`, including instance id, species,
level, HP and fainted state, plus whether the references match. This will distinguish
the expected automatic switch from a stale-body defect on a future diagnostic run;
the first focused receipt alone cannot prove which body dealt the late damage.

The first focused run also emitted `Resumed function '_observe()' after await, but
class instance is gone` during diagnostic teardown. The revised tool retains the
`TraceBridge` object, requests observer shutdown after the base helper returns, and
awaits observer completion before releasing it or quitting. This was a diagnostic
lifetime bug after the already-recorded combat result, not a production engine error.

The implemented source-grounded driver correction applies the existing real Satchel
care path to every currently usable earned party member below 50% HP before selecting
the bridge fighter. In this retained state that means **two** additional
`potion_small` uses for the level-8 Bramblebun: one raises 24.087 HP to 59.087,
which is still below its 62.753 half-health threshold; the second raises it to
94.087. Together with the one potion already used on the selected level-7 body,
this spends three of the six carried potions and leaves three. The first fighter already reached
the second round and the automatically selected survivor reduced Burrowback to
43.563 HP, so preparing that survivor addresses the measured deficit without changing
combat balance, granting inventory, forcing an outcome, or altering battle input.
Reviving the other three members would be a broader preparation policy and is not
required by this evidence. `meadows_earned_bridge_segment.gd` now performs this
finite preparation before its existing highest-HP selection. Each use still passes
through `CARE.care_existing()` and fails if the retained inventory or real Satchel
interaction cannot supply it; there are no revives, grants, direct HP writes, balance
changes, or altered combat inputs. The trainer loop also reports a retained real
`lost` outcome explicitly before its unchanged aggregate victory/receipt assertion.
The combat-preparation portion still required replay evidence at this point.

That replay, `bridge-retained-prepared-second`, ran from 08:52:13 through
08:54:22 and exited 1 without engine errors. The preparation spent exactly the
expected three potions. The party then defeated both real guardian creatures in
28 landed hits, set `defeated_south_bridge_grunt=true`, and retained the level-8
Bramblebun at 74.157 HP. This validates the bounded preparation and confirms the
automatic-switch interpretation: during the second round CombatManager's active
ally was the healthy reserve while the director retained the fainted prior ally;
after battle teardown both references converged on the survivor.

The remaining failure occurred only after that valid victory. Auto-open had not
opened the bridge, the helper walked back to its existing authored near point, and
the exact gate prompt did not own the arbiter's actionable offer. The old trace did
not record player/prompt distance, gate line of sight, the competing winner, or its
offer, so this receipt does not distinguish a nearby defeated-guardian prompt from
a gate range/LOS issue or another provider. The revised diagnostic overrides only
its tracing seam around `_press_gate()`: immediately before delegating to the
unchanged base press, it prints player and prompt positions, distance/radius,
enabled/actionable/LOS state, the gate's direct offer, bridge state, arbiter state,
winner identity/offer, and all registered Node3D providers within eight metres with
their direct offers.

The prepared run's isolated `diagnostic_bridge_copy/slot_0.json` still contains the
pre-fight state (`defeated_south_bridge_grunt` absent and six potions), because the
focused diagnostic copied the original source slot and no post-victory autosave was
written before this failure. It cannot provide a shorter post-victory replay; the
same approximately two-minute focused fight must run again to capture the offer.
No post-victory timing, walk, arbiter priority, or gate behavior has been changed.

`bridge-retained-gate-offer-third` then ran cleanly from 08:58:04 through
09:00:28. Both gate presses showed the exact South Bridge Interactable as the
actionable winner. Before the post-victory press, its direct offer was actionable
at 2.571m inside the 4.0m radius with line of sight true. The run recorded two
guardian victories and 28 hits, earned one key and spent it to zero, crossed from
depth -11.532 to +9.477, and retained the same five party instance ids. The prior
post-victory ownership failure did not recur and remains unexplained; this one pass
does not establish that it was repaired.

There is a source-level publication race consistent with that intermittent shape.
`_walk()` declares arrival and returns from a physics-frame loop. The
InteractionArbiter publishes its spatial winner from `_process()`, on the idle/render
clock. The first `_press_gate()` assertion can therefore read the winner published
for the body position before the final physics movement. The successful trace even
shows a small difference between the gate's direct current distance (2.571m) and
the arbiter winner's published distance (2.544m), confirming the two observations
need not be from the same instant, although it does not prove that this caused the
earlier failure.

A held patch at
`.artifacts/broad-visual-0910/bridge-gate-offer-wait-held/bridge-gate-offer-wait.patch`
adds a bounded 30-process-frame wait inside the test helper's `_press_gate()`. Each
iteration waits for the real arbiter publisher, then accepts only the exact gate
provider with an actionable offer. The original strict assertion and physical
interact input remain. The patch applies cleanly to the current prepared helper but
was applied to the test helper at 09:16 UTC. The focused bridge contract suite
then passed cleanly: 8 tests / 67 assertions, `bridge-preparation-unit-first`,
09:16:21–09:16:28. This does not establish that the earlier intermittent offer
failure was caused by the publisher phase; the next fresh prefix remains required.

The paid camp built earlier in this same continuous run is near `(36,-40)`, while
South Bridge is near `(8,1330)`. Returning there after the tournament and then
repeating the bridge approach adds roughly 2.7 km. The authored Trail Camp is much
closer to the route at about `(344,935)` and exposes the normal `Rest until morning`
and one real creature bed, but restoring all five party members there would require
sequential bed assignments and nights because that bed has one occupant. The
existing earned-rest helper is coupled to the paid camp objects and tournament
condition lesson, so reusing it directly is not a small post-tournament bridge step.
For this measured failure, preparing both already-usable creatures through the
existing Satchel helper is the bounded natural path: it happens before the challenge,
uses earned inventory, and exercises the same UI/input care mechanism already used
for the first potion. A future design requirement that the bridge demand a fully
restored five would justify a dedicated Trail Camp stop; this failure does not.

## Retained slot suitability

The run's retained `slot_0.json` is suitable for a focused replay. It records Meadows,
day 6, position `(1.0498, -2.8907, 1317.0756)` beside the South Bridge, five party
members, `road_gate_open=true`, `tournament_won=true`, and both
`defeated_south_bridge_grunt=false` and `south_bridge_open=false`. It contains no
South Bridge Key. Two creatures remain usable: level-7 Bramblebun at 62.263/136.245
HP and level-8 Bramblebun at 24.087/125.505 HP; Ripplet and both Mudsnouts are fainted.
The revised helper's `_prepare_ally()` uses carried small potions to bring both usable
members to at least half health, then chooses the highest-HP member through its
existing selection. This is a demanding earned party state, but it meets every
bridge entry precondition without a fixture grant.

`tools/diagnose_retained_bridge_segment.gd` copies that slot into isolated `user://`,
runs the current bridge helper, and samples the exact trainer id/queue, combat
state/outcome/action, ally and enemy HP, usable-ally blocker, hit/win counters, and
durable defeat flag every 60 physics frames. It changes no input, timeout, combat
behavior, inventory, party, or assertion.

For focus, the diagnostic omits only the already-completed village-to-bridge road
prelude. Before doing so it requires the loaded player to be within 30 metres of the
authored crossing centre and still on the village side according to the production
`depth_past_crossing()` result. It does not write the pose. The base helper still owns
ally recovery, the real gate input, guardian walk and dialogue, every combat input,
reward and flag checks, gate opening, and the physical far-bank crossing. This replay
therefore cannot claim the full approach again, which the preserved fresh failure
already completed; it can isolate the expensive guardian portion without walking a
loaded player back through kilometres of route first.

## Aim trace disposition

The same fresh run recorded ten aim entries, nine ordinary release/strike sequences,
and one intentional `AIM_COMMIT_CANCEL` from `menu_cancel` at 228.388 seconds. It does
not reproduce or support a spontaneous aim-cancellation claim.

## Focused command

Run through the guarded root runner with the source slot below:

```powershell
godot --headless --path . --script tools/diagnose_retained_bridge_segment.gd -- --source-slot=C:/Projects/Tetherbound/.artifacts/broad-visual-0910/runs/continuous-through-bridge-second/profile/Godot/app_userdata/Tetherbound/four_biome_fresh_21312_2590/slot_0.json
```

This copied-save result can isolate the bridge mechanism. It cannot replace the fresh
campaign continuity result because loading begins from a retained state.
