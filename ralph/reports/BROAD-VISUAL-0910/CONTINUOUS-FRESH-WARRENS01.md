# Final fresh run: bridge completed, quarry approach blocked

Runtime revision: `dbb229436b473cf5d53eb585331893ab54e3b4fa`.
Run `continuous-through-warrens-first` used the canonical continuous composition
through the read-only aim-lifecycle observer:

`godot --headless --path . --script tools/probe_continuous_aim_lifecycle.gd -- --through-warrens`

It ran 2026-09-10 11:56:39.721–12:21:55.726 UTC, with 1,505.385 engine seconds.
The final exit is 1 because the requested Warrens prefix failed; engine errors
are empty and the process/memory/deadline guard did not stop it. The existing
Terrain3D interpolation deprecation warning remains. All 2,052 snapshotted
source/configuration files have identical before/after SHA-256 values. Only
documentation/main-doc integration and CI wiring changed outside that inventory.
The earlier stale HUD-provider error did not recur.

## Earned path completed before the blocker

- Actual title, waking, Grandpa briefing/starter, first live capture and village
  key/gate. No seeded campaign progress or HP pinning.
- Five owned creatures, then nine real training victories brought all five to
  at least level 5. This selected party was Ripplet, Mudsnout and three Bramblebun;
  it is not evidence of broad roster diversity or an ideal player team.
- Real gathering reached wood 19, fiber 18 and stone 8, paying the authored camp
  costs. A stone at `(69.0,76.2)` repeatedly lost the interaction offer and a
  second approach stopped short; the helper recovered using another actual
  same-resource node. This slow route remains a usability/driver finding.
- Paid campsite/creature-bed placement and all five real bed assignments/rests
  completed through day 6.
- All three tournament rounds were won: two, two and three opposing creatures;
  the cumulative landed-attack count reached 51.
- Physical southern-road travel reached the real bridge guardian. One battle
  offer was refused before admission. The admitted encounter produced two wins
  and 29 hits; the earned key changed from 1 to 0. Bridge depth changed from
  `-11.58251953125` to `9.472900390625` with the same five creature instance IDs.
- The Warrens continuation used actual carried care items, then physically mined
  four quarry nodes at `(394,1797)`, `(399,1792)`, `(406,1800)` and `(401,1809)`.
  Each yielded two rootstone; the live total reached eight.

This is now clean-source, no-engine-error evidence of the earned bridge prefix
inside a longer failed run. It is not a passed Warrens test or campaign completion.
The depleted-stock pilot branch was not exercised by this seed.

## Exact stopping point

`Ordinary quarry/Warrens movement did not reach (393.0, -0.497714, 1802.0); player=(395.1783, -0.499202, 1804.407)`

The player stopped about 3.25 horizontal metres from the requested next quarry
approach. This establishes a failed automated physical approach, not yet whether
the cause is authored collision/footing, the target location or the navigator.
No cave entry, Warrens guardian victory or exit was reached. Per the owner's
handoff/pause request, no further repair cycle was started.

The next session should reproduce that short approach with contact/target
telemetry and native visual inspection, distinguish a world defect from the
driver's approach, then repair the confirmed cause. Do not bypass it by granting
rootstone, teleporting past it or claiming the cave cleared.

## Retained evidence and save caveat

Logs, wrapper receipt and resource samples:
`.artifacts/broad-visual-0910/runs/continuous-through-warrens-first/`.

Source inventory and zero-drift receipt:
`.artifacts/broad-visual-0910/continuous-through-warrens-first-source-hashes.json`
and `continuous-through-warrens-first-source-drift.json`.

The retained save is under the run directory at
`profile/Godot/app_userdata/Tetherbound/four_biome_fresh_20712_2766/slot_0.json`.
It was last written at 12:19:39.676 UTC, day 7, at
`(124.9395,5.6861,1491.0294)`, after the bridge and care but before quarry mining.
It is a useful nearby earned checkpoint, **not a save at the failure position**
and not a saved inventory containing the subsequently mined eight rootstone.
Party levels in that save are 6/8/7/7/8. Preserve it when making a diagnostic copy.

The 197,022,545-byte coverage payload is
`four_biome_coverage_20712_2766.jsonl` in the same user-data directory. It records
4,800.154 m, 458 samples, 320 with fewer than two visible creatures, and one
undersampled interval. Existing camera-versus-travel-direction caveats apply;
these numbers are not a whole-road density verdict. The payload remains local,
not committed as a large report attachment.
