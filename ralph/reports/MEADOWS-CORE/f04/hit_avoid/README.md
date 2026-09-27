# F04#4 hit/avoidance witness (three captains and the Warden)

Test: `tests/smoke_named_fight_hit_avoid.gd`, run headless:

    godot --headless --path . --script tests/smoke_named_fight_hit_avoid.gd

The fights are the production ones. The world is `meadows_playground`, and each challenge goes through the interact prompt and dialogue. The trainer's own AI attacks, and combat_manager decides every outcome. The test injects only pad input.

Each fight takes 8 strikes, cycling through four policies: stand, dodge (back away), stand, dodge_side.

| Fight | Player hits landed | Stand strikes landed | Dodges avoided | Result |
|---|---|---|---|---|
| captain_riverwatch (Oreth) | 13 | 4/4 | 1/4 (back-away 1/2, side 0/2) | PASS |
| captain_field (Halder) | 10 | 4/4 | 2/4 (back-away 2/2, side 0/2) | PASS |
| captain_ridge (Vess) | 11 | 4/4 | 3/4 (back-away 2/2, side 1/2) | PASS |
| warden_aldis (Warden) | 9 | 4/4 | 2/4 (back-away 2/2, side 0/2) | PASS |

`witness_rows.txt` logs one row per strike: move, tell, policy, outcome, damage, the gap at the tell and at the strike, how far the creature moved, the strike's reach and cone, the creature's action state and its distance from the arena centre.

**Mutation check.** With `combat_math.in_hit_cone` changed so that out-of-reach strikes connect, the same run on captain_ridge FAILs (0/4 dodges avoided). See `mutation_in_hit_cone_always_true.txt`; the change was reverted.

**Findings for BOSSES/COMBAT owners (not changed here):**
- Ordinary quicks track the target live and reach 6.65–7.47 m against these captains' spaced bodies. Sideways steps rarely escape (1/8). Backing out of reach inside the tell does escape (7/8).
- A player who is still in a quick's wind-up or recovery when the tell starts is rooted and cannot dodge. This is the intended COMBAT cost.

**Disclosed shortcuts:**
- The player's active creature is healed to full after every enemy strike.
- The stand spot in front of the trainer is a fixture teleport, reused from `capture_named_fight.gd`.
- Unresolved fights are ended with `_begin_resolve("lost")` after the sample.
- The run is headless (no frames). The visual rows stay with the capture judges.
