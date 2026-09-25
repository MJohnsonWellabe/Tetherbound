# Meadows finale (F05) evidence

Lane: Meadows finale. Row: ROADMAP F05 / ACCEPTANCE §6.1 F05, governed by card
M4. **Every witness here uses disclosed focused fixtures.** The Meadows core
lane's F01–F04 earned route does not exist yet, so the continuous-path part of
M4 stays open (ROADMAP §3, ACCEPTANCE §6). Nothing here accepts F05 or M4.

## Physical crossing carries the same five (WO3)

Criterion: "The opened physical gate carries the same five into Cloudreach".
"Gate opens exactly once" is **not** proven here. See "Not claimed".

Witness: `tests/smoke_rift_crossing_same_five.gd`

    godot --headless --path . --script tests/smoke_rift_crossing_same_five.gd

The test builds a full five, including a Veridian, and records each creature
by stable uid, species, nickname and level, in belt order. A real
CharacterBody3D then walks the real `rift_crossing.gd` span into the far
trigger. It checks that:

- the realm changed once, to Cloudreach, and did not roll back;
- `realm_gate_cloudreach_unlocked` is set;
- the production Cloudreach scene becomes current with the identical five;
- a real mid-session `save_game` / `load_game` in Cloudreach returns the
  identical five, still in Cloudreach, with the finale flags intact. The party,
  the flags and `current_realm` are blanked before the load, so these values
  come from the file.

| Commit | Result |
|---|---|
| `49ef712f` (main, unmodified) | PASS, 3m28s. After the review fixes, PASS again. Log: `crossing-same-five.txt` |
| `49ef712f` + injected defect (`rift_crossing.gd` removes belt slot 4 on crossing) | FAIL on both the arrival and the reload checks. The defect was reverted and was never committed. |

Fixtures, disclosed:

- The durable finale facts (`legendary_freed`, `legendary_joined`,
  `legendary_settled`, `realm_key_cloudreach`) are set directly.
- The five are built with `Game.make_creature`.
- The Meadows side is `smoke_cloudreach_transition.gd`'s flat stand-in terrain
  with the real span on it. The Cloudreach side is the production scene reached
  through the production realm router.

Not claimed:

- **that the gate opens exactly once.** A duplicate trigger fire would not show
  in this test: the realm router refuses a second `enter_realm` without
  changing `current_realm`, and the scene change frees the walker. The
  crossing's own `_entered` latch therefore still needs its own witness.
- a cold-boot "Continue" reload. The reload here is mid-session;
- the earned walk to the span;
- two peers crossing (Cloudreach lane C3);
- that the crossing is reached from an earned Warden save.
