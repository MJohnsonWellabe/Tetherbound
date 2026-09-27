# F04#4 hit/avoidance witness (three captains and the Warden)

Test: `tests/smoke_named_fight_hit_avoid.gd`, run headless:

    godot --headless --path . --script tests/smoke_named_fight_hit_avoid.gd

The fights are the production ones. The world is `meadows_playground`. Each challenge goes through the interact prompt and dialogue: the first press opened the dialogue in every fight, and the fallback (`arbiter.activate` / `_on_challenged`) never ran. The `challenge:` lines are in `witness_rows.txt`. The trainer's own AI attacks. Outcomes are combat_manager's own `hit_landed` and `attack_missed` signals from `_on_enemy_strike`. The only input injected is from the pad: `combat_quick` taps and the left stick.

Each fight takes 8 strikes, alternating two policies:
- **stand:** the stick is at rest. Attacks are thrown before these strikes.
- **dodge:** after a 0.2 s reaction, the stick backs the creature straight away from the opponent until 0.25 s after the tell. If the creature makes no progress for 12 frames, the stick turns ±60°/±120° to steer round the obstacle. No attacks are thrown before a dodge strike, because a quick roots the creature through its wind-up and recovery.

| Fight | Opponent (logged) | Player hits landed | Stand strikes landed | Dodges avoided | Result |
|---|---|---|---|---|---|
| captain_riverwatch (Oreth) | mosshell L13 | 12 | 4/4 | 2/4 | PASS |
| captain_field (Halder) | duskhush L13 | 9 | 4/4 | 2/4 | PASS |
| captain_ridge (Vess) | trailpup L14 | 10 | 4/4 | 1/4 | PASS |
| warden_aldis (Warden) | burrowback L18 | 9 | 4/4 | 2/4 | PASS |

`witness_rows.txt` logs one row per strike: trainer, opponent species and level, move, tell, policy, outcome, damage, the gap at the tell and at the strike, how far the creature moved, reach and cone, the creature's action state and its distance from the arena centre.

**Mutation check** (`mutation_check.txt`): `in_hit_cone` was changed so that out-of-reach strikes connect. The same run on captain_field then FAILs with 0/4 dodges avoided, while player hits and held-still strikes still land. The change was reverted.

**Findings for BOSSES/COMBAT owners (not changed here):**
- Every witnessed strike was the opponent's ordinary quick (0.85–0.90 s tell). Ordinary quicks track the target live and reach 6.65–7.47 m against these spaced bodies.
- Backing out of reach inside the tell escapes about half the time: 7/16 here, and 7/8 in an earlier run without steering. It fails when the creature starts deep inside reach, or when it is pinned against trees in Oreth's and Vess's forest arenas.
- In earlier runs, sideways steps escaped 1/8, because tracking follows the target.
- A creature still in a quick's wind-up or recovery when the tell starts is rooted and cannot dodge.

**Scope and disclosed shortcuts:**
- **Quicks only.** The named tactical moves (CHARGER lunge path, heavies) did not come up in the 8-strike samples. The existing lunge-miss evidence covers the relay officers; this witness does not re-witness named heavies.
- **Fixture ally.** The ally is a Terrapup from `adopt_starter` (a party of one), healed to full after every enemy strike.
- **Fixture teleport.** The stand spot in front of each trainer is a teleport reused from `capture_named_fight.gd`. It skips progression and physical gates: captain order, Sigils, and Hald and the chamber approach before the Warden.
- **One world.** All four fights run in one world, one after another. Each is ended with a forced loss (`_begin_resolve("lost")`) after its sample, so fights 2–4 start after earlier losses.
- **Headless.** No frames are produced; the visual rows stay with the capture judges.
- **Variance.** The dodge counts vary between runs. An intermediate run of this witness (before the steering fix) failed Oreth at 0/4, and one failed Halder at 0/4. The committed run is the final version's first full run.
