# WATER-RETURN-CURRENT01

Date: 2026-09-10  
Scope: authored Water environmental return rewards

## Bounded repair

`data/config/water_world.json` already authors two `return_shortcuts` of kind
`current_reduction`, including their durable producer flags, exact route IDs and
post-unlock strengths:

| Reward | Authoritative flag | Exact current route | Base strength | Earned strength |
| --- | --- | --- | ---: | ---: |
| `shellwatch_pump_return_channel` | `water_dock_shellwatch_residents_freed_and_pump_disabled` | `brine_steps_to_shellwatch_direct` | 0.35 m/s when ungated; the existing departure gate may use its stronger closed value | 0.08 m/s |
| `deep_watch_current_cut` | `water_dock_deep_watch_current_charted` | `sluice_isle_to_deep_watch_direct` | 2.2 m/s | 0.1 m/s |

Before this repair, the real dock actions produced those flags, but
`WaterCurrentField` never consumed `return_shortcuts` or
`strength_after_unlock_m_s`. The authored environmental payoff therefore had
no runtime current effect.

`scripts/world/water_current_field.gd` now deep-copies the Water config and
binds only valid `kind == "current_reduction"` rows to a current with the exact
same `route_id`. It adds the existing unlock flag and earned strength to those
two matching current rows. It ignores the separate
`reedhaven_maintenance_ramp`, malformed rows, and all unrelated currents, and it
does not mutate the input config.

Each `sample()` reads the retained live authoritative flag store. A flag earned
after field construction changes the next sample, removing a flag restores the
base behavior, and a field reconstructed after loading a completed save begins
with the earned strength. Existing departure-gate closed strength and realm
liberation scaling still use their prior paths. Route matching is exact, so a
direct-route reward cannot modify a sheltered sibling with the same prefix.

This is the same `WaterCurrentField` reached by
`water_world.gd::current_at()`. Human swimming consumes it through
`scripts/player/swim_controller.gd`, and mounted swimming consumes it through
`scripts/world/water_mounted_swim.gd`. The patch does not change flag
authority, replication, inventory, rewards, route geometry, controllers or
movement code, and it invents no values.

## Focused unit evidence

Root's guarded `water-return-current-unit-first` run executed from
`2026-09-10T06:10:01.8742053Z` through `06:10:05.5777026Z`, exited 0 with
`errors=[]`, and passed **8 tests / 52 assertions**. The new production-config
coverage proves:

- exactly the Shellwatch and Deep Watch direct routes receive reductions;
- the flags and strengths equal the authored config values;
- Reedhaven's physical ramp and unrelated routes remain outside the binder;
- binding does not mutate the source dictionary;
- unrelated, Shellwatch and Deep Watch flags remain isolated;
- live flag gain/loss changes the existing field without reconstruction; and
- a field built over already-restored completion flags starts reduced.

The run also retained the existing edge blending, overlap priority, peer
determinism, dock-gate and realm-liberation current checks.

## First production dock smoke: failed fixture selection

The first guarded production dock smoke,
`water-return-current-dock-first`, ran from
`2026-09-10T06:11:04.7698419Z` through `06:11:41.5926768Z` and finished
**47 checks / 5 failures** with exit code 1. It must not be reported as a pass.

All five failures were in the newly added return-current assertions. The smoke's
probe asked for the prefixes `brine_steps_to_shellwatch` and
`sluice_isle_to_deep_watch`, so it could select the authored sheltered sibling
instead of the exact rewarded `*_direct` route. The failures therefore exposed
an ambiguous test sample, not evidence that the exact-route production binder
selected the wrong route. The unit test above independently exercises the
exact production route IDs and passed.

The fixture has been corrected without weakening the production contract. It
now requests `brine_steps_to_shellwatch_direct` and
`sluice_isle_to_deep_watch_direct` exactly, and accepts a probe only when the
field readback has the expected current `id` and `influence == 1`. It records
Deep Watch's actual pre-reward speed and requires that speed to exceed the
authored 0.1 m/s reward, instead of hard-coding 2.2 m/s in a fixture whose
existing gate state may legitimately affect the pre-reward sample. It still
requires exact 0.08 and 0.1 m/s earned strengths, cross-route isolation, and
pre/completed save restoration.

The failed receipt is preserved at
`.artifacts/broad-visual-0910/runs/water-return-current-dock-first/`.

## Corrected route smoke: deferred-completion fixture failure

Root's second guarded run, `water-return-current-dock-second`, executed from
`2026-09-10T06:41:38.4520376Z` through `06:42:17.6580709Z`, reported no engine
errors, and finished **47 checks / 3 failures** with exit code 1. The exact-route
repair removed both Deep Watch failures and the later completed-save reload
restored both flags and both reduced current strengths. The three remaining
failures were the immediate combined Shellwatch flag, its barrier removal and
its 0.08 m/s current readback.

Source ordering explains that cluster. Each physical Shellwatch action commits
its own flag synchronously through the production ledger. The combined
`water_dock_shellwatch_residents_freed_and_pump_disabled` flag is a separate
completion derived by `WaterDockActions._process()` after both action flags are
present. The fixture's `activate()` helper advanced only `physics_frame` before
the immediate assertions, so it could sample after the pump delta but before
the next idle process. Subsequent Deep Watch/save work allowed that idle process
to run, which is why the completed-save reload later passed.

Only the smoke was changed. After the real pump activation it now waits, for at
most 30 idle process frames, until the actual combined world flag arrives. It
does not insert a time delay, set the flag itself, bypass the ledger, or weaken
any assertion. If the production completion does not occur within that bounded
window, the existing flag, barrier and 0.08 m/s assertions still fail.

Root's third guarded run, `water-return-current-dock-third`, executed from
`2026-09-10T06:45:59.3284630Z` through `06:46:36.1006081Z`, exited 0 with
`errors=[]`, and passed **47 checks / 0 failures**. This is the first clean
production action/save smoke for the current-reduction candidate. The two
earlier failures remain preserved above because they explain the exact fixture
corrections required to reach the valid sample and event ordering.

## What the smoke does and does not prove

The dock smoke mounts the production Water scene, production dock equipment,
interaction providers, ledger/inventory, collision barriers, current field and
real SaveGame reload. For the new routes it uses the real Shellwatch resident
release and pump prompts and the real Deep Watch chart prompt, then samples the
exact production currents before and after completed and pre-reward slot loads.

It is an explicit fixture action/save smoke. It freezes the player controller,
teleports the player beside each equipment provider, and directly fixtures the
required trainer-victory flags. It does not swim either route, fight either
trainer, establish route timing or feel, exercise combat while in a current, or
validate a complete ordinary-play sequence. A clean rerun can establish
production action-to-flag-to-current and save restoration, but it cannot be
cited as real travel or combat evidence.

Although the authored current rows contain a `visual_flow` design string, the
current production surface/foam path does not consume `WaterCurrentField`.
This change makes no visible-flow implementation and supports no visual-flow
claim.

The frozen source hashes after the exact-route fixture correction were:

| File | SHA-256 |
| --- | --- |
| `scripts/world/water_current_field.gd` | `EAF7DDF34D839DC9AD06C31184CD0B2160AC59C75D8AD0A10B5E8346D8573521` |
| `tests/test_water_current_field.gd` | `C253639094B01D7165BF32D3B8D222694B7E67ACB54245BCD5304DDB0EA7B4B2` |
| `tests/smoke_water_dock_actions.gd` | `4242C1F4388586CB8DA0035CAC360DC78074868E743D50919679D59C8764B53E` |
