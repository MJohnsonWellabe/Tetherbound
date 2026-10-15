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

## Code-blind r10, 12:58 AM CT Tue 13 Oct (tb/ev-visual c2eb74b1; sheet r10/_sheet-r10.png, key r10/key.json)
Capture: tools/_probe_aftermath_sites.gd (Low/Compatibility, one boot, matched site camera; the after frame is trainer_aftermath.settle(), the same path a reload or rematch re-attach takes). The full fight capture (capture_f04_6_aftermaths.gd) timed out at 50 min with 0 frames on this container's software GL (1 fps). Persistence: test_trainer_aftermath*.gd 15 tests, 135 assertions, 0 failed (incl. test_a_beaten_trainer_reattaches_in_the_after_state).
Change this round: Vance's relay mast lit before / dead after (WORLD 5). Sela (captive) is placed in the cage but does not render in the Meadows build; cause not found after two diagnostics (parked).
Verdict, SET NOT PASS (1 PASS, 3 WEAK, 1 FAIL); the five changes read as distinct object types:
- Oreth barrier PASS: fence swung aside, path open.
- Dell pylon: change PASS (pylon dark), frame FAIL: flat untextured purple panels on the existing arch wall (world art, not the aftermath set) and floating cable debris.
- Halder watch-fire WEAK: toppled braziers read as grey blocks; a white upright card with a black icon in the after frame; flat flame card before.
- Vance cage + mast WEAK: mast going dark is clear; no freed captive visible, cage stays closed.
- Vess rope line WEAK: strung net reads as a floating wicker spiral, unanchored; held sword hilt intrudes bottom-right.
- Shared: the oxblood standard is removed at four sites, the most obvious change side by side.
Next: Sela render cause; open cage door; anchor Vess's line both ends; recognisable braziers, drop the white card; purple wall panels to the F39/F40 catalog.

## Scored (owner 10-point rule, 11:30 AM CT Tue 13 Oct): r10 vs r12 (Halder torches before-only, Vess straight strands; r11/r12 surface grounding reverted), probe frames, sets shuffled per site, one code-blind judge
**r10 5.0 → r12 5.0, no gain.** Halder 5.0 → 6.0 (white card gone, NPC by the ashes reads). Vess 5.5 → 4.5 (flat cut strands vanish; the old coiled pile read as a cut rope). Dell, Vance, Oreth unchanged. Top asks: Vance's rescue must read (cage open/empty, +1.5-2 on that site); stop striking the standard at every site (+0.5 avg); purple placeholder plates on Dell's wall, Oreth's rail into the waystone, the held sword in Vess's frame. r13 (keep_standards, Vess coiled pile) next.

## Scored 11:55 AM CT Tue 13 Oct: r12 vs r13 (keep_standards; Vance cage before-only with chain after; Vess coiled pile; Oreth fences clear of the waystone), one code-blind judge, sets shuffled per site
**r12 5.3 → r13 6.5 (+1.2).** Per site, r13: Dell 6.0, Vance 6.5, Oreth 6.5, Halder 6.8, Vess 6.5. Top asks: leave an open empty cage with Sela readable beside it (+0.8 to +2.5); clean-ups (Dell's purple wall plates and claw shards, the pylon clipping a post, the held sword at Vess) +0.3 to +1.0 per site; give Dell's pylon its own failure distinct from Vance's mast, show a dangling cut end at Vess's post, and vary the glyph-stone brighten (+0.5 to +1.0 each). r14 next.

## Restarted Fights lane — 14 Oct 2026, after F22 water-cue stop

- Selected **F04#6 distinct aftermath** after parking F22#4's water-cue approach under the two-round <0.5 stop rule. Player-visible target: five Meadows named fight sites show different, readable consequences at normal distance; the set reaches the 8.5 Bar A visual gate without hidden collision or save/rejoin divergence. Retained r13 score is 6.5 from one judge; r14/r15 Dell/Vance candidate is OFF and unjudged. A source configuration or flag is not acceptance.
- Game correction in `trainer_aftermath.gd`: Sela's before and after presentation NPCs were created **after** `_place_hidden` removed prop colliders, leaving an invisible `StaticBody3D` in the hidden alternate state. The new code disables and frees those NPC colliders. The captive remains a visible site figure derived from Vance's world defeat flag, with no new state, reward or network mutation. This removes a potential invisible movement snag beside the cage; no native path or visual result is claimed yet. `git diff --check` passed.
- Next GPU grant: use the existing `tools/_probe_aftermath_sites.gd` AS-IS in this checkout with committed `tools/visual_judge/camera_sets/F04-6.json`, first comparing Dell's OFF r13 and ON r15 at Medium on real Meadows terrain (not a flat substitute). Inspect raw before/after frames, actual site switch, log, pylon ground contact and wall materials. If that succeeds, capture the full five-site OFF/ON matrix at Medium and High as bounded capacity allows, using three fresh blind judges and unchanged references. Direct `settle()` is only a visual diagnostic; earned fight, reload and co-op proof remain separate. No Godot launch was authorized during this CPU block. **Zero criteria closed.**
