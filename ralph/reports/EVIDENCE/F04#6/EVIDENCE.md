# F04#6 — distinct aftermath per Meadows named fight

Branch `tb/ev-fights-c2c3`, base commit `00d4a639` (origin/tb/ev-coordinator). Times CT, Sun 11 Oct 2026.

## Non-visual half (run 10:50 AM CT)
`godot --headless --path . --script tests/run_tests.gd -- --only=test_named_fight_profiles.gd`
→ 8 tests, 80 assertions, 0 failed (`unit_test_named_fight_profiles.log`). This proves only that every profiled fight sets a defeat flag; it does not prove a visible, distinct aftermath.

## Visible half: capture item (not judged by this lane)
What each win visibly changes on current source (code read, file:line):

| Fight | Visible aftermath | Where to frame |
|---|---|---|
| Warrens guardian | `VaultDoorBody` slab + emissive seam sink over 1.4 s, collider off (`scripts/world/burrow_warrens.gd` `_sync_vault_door`, `burrow_warrens.json` open_seconds). Animates on the live transition only. | Den floor facing the den→vault door, warrens ≈(-357, 2610) |
| Relay officer Dell | Stand-down only (1.8 m aside, 120° turn; `trainer_aftermath.json`). No standard, no tokens, no world change from `defeated_relay_dell`. | Relay gate opening |
| Relay captain (Vance) | Oxblood standard struck (cloth fades over 1.6 s) + stand-down 2.4 m/150°. Relay drain-skin 12 s fade and `heal_stations` come from the later `relay_disabled` console press (`tether_relay.gd` ≈1896–1910), Old Mill Crossing from `mill_crossing_restored` (`mill_crossing.gd`). | Relay yard ≈(353, 3764.5); console press; crossing ≈(-152, 4203) |
| Captains Oreth / Halder / Vess (`captain_riverwatch`, `captain_field`, `captain_ridge`) | All three: standard strike + stand-down + a floating sigil token for 9 s (river / field / ridge sigil). The Hall `SigilGate` opens when used holding all three sigils, not on a win. | ≈(-100, 4350), (170, 5590), (-280, 6460) |
| Keeper Hald (`stronghold_elite`) | `BlastShutter_defeated_stronghold_elite` hidden + collider off, instant (`stronghold.gd` `_sync_doors`). No standard/stand-down entry. | tether_approach side ≈(8, 7557) |
| Warden Aldis | `BlastShutter_defeated_warden` (arena→legendary chamber) instant hide; heart + key tokens for 14 s. Veridian/healing follow the separate `legendary_freed` climax. | Warden arena facing the chamber shutter |

**Risk for the judge, disclosed:** the three captains share one aftermath form (strike + stand-down + sigil token that differs only by sigil), and Hald's and the Warden's shutters use the same instant hide. Whether that reads as "distinct per fight" is the code-blind judge's call, not this lane's.

Status: CAPTURE-READY sent to the coordinator; criterion stays open pending capture and judge.

## Code-blind r3, 12:23 PM CT 12 Oct (captures f14c6e39, 4 of 6, same camera)
SET WEAK (2 PASS, 2 WEAK, 0 FAIL); the four changes are distinct object types. Vance cage PASS (captive not visible; the tipped cage looks unsupported). Oreth barrier PASS (the fence lies beside the path, not across it). Halder watch-fire WEAK (before/after terrain render state differs; fallen torches indistinct). Vess rope line WEAK (reads as a wreath, not a strung line; a metal bar clips under the marker stone; render state differs). Fixes sent to captures (Aldis plus the four refits) and visual-claude (Dell).
