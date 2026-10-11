# F04#1 Relay officers: evidence (lane meadows-fights)

Run 2026-10-11 CT, Godot 4.7-stable headless.

## Result: PASS (smoke). Visual read is pending the coordinator's capture and judge.

**Code check.** `combat.json` patterns give each officer a distinct named sequence:
- `named_relay_officer_dell`: "Two anchored checks then an aerial landing answer": wall_check→wall_slam, wall_check→wall_quake, diver_leap→diver_retreat.
- `named_relay_captain` (Vance): "Air spacing, flank reset, three-type team and charge lane": diver leap/retreat, current zone, two wall send-outs, then charger_rush→charger_double_rush.

The HUD names CHARGE/DIVE (`combat.json telegraph.charge_text/dive_text`), and pattern cues draw the cone, ring, marker or lane shape.

**Bug found and fixed (d885d383).** At ea3a1ebb, Vance's lead Galecrest `diver_leap` never landed on a player who stood still: 0 of 4 stand strikes landed (`before_leap_fix_relay_captain.log`). The marker is placed on the target, so the collision-aware leap stops at body contact, and `_finish_pattern_leap` flagged every such arrival `blocked`. A leap is now blocked only when the body stops outside the marked circle (body radius + `marker_radius_m`).

| Check | Commit | Command | Result |
|---|---|---|---|
| Hit/avoid witness | d885d383 tree | `godot --headless --path . --script tests/smoke_named_fight_hit_avoid.gd -- --trainer=relay_officer_dell,relay_captain` | PASS: Dell 11 hits / 4 stand landed / 1 of 4 dodged; Vance 9 / 4 / 2 of 4 |
| F22 live mount (DIVER arrival) | d885d383 tree | `tests/smoke_f22_live_pattern_mount.gd` | pass, 47 checks |

**Limitations.** The smoke's default list is the captains and the Warden, so the relay trainers were passed through `--trainer`. The harness help it discloses still applies: a fixture Terrapup healed after every strike, and a teleport to the stand spot.
