# Combat contact spacing (shared combat, Phase 1)

**Problem.** Tidewake F14#0 (Tess) and F14#1 (Nerissa) failed C3 on one defect only: at contact range (4.7–6.6 m) the rendered ally and opponent overlapped, the ally stood in front of the opponent's head, and no camera could separate them. Meadows F04#2/#7 and Stormwood F10#2 hit related framing failures.

## The rule

Code: `scripts/combat/contact_spacing.gd`, applied in `creature_body.gd::_hold_contact_spacing`. Tunables with `_why` are in `combat.json` `contact_spacing`.

- **Separation.** The two **directional rendered half-extents** plus **0.6 m** (COMBAT §5).
  - Each body's footprint is taken as its fitted art's ellipse, so a long body met head-on stands further out than broadside.
  - Floored at the colliders' sum, with a 12 m ceiling.
- **The opponent walks to where the bodies clear.** Its `preferred_range` floors at that separation (`wild_creature.spaced_config_for`).
- **Reach cannot be escaped.** Every reach floors at the pair's **longest** separation plus 0.5 m. The longest separation uses each body's longest half-extent, so turning cannot change it. This covers the player's reach (`floor_reach_for_bodies`), the host's check of a peer's strike (`host_move_profile`, on all three host call sites) and the opponent's (`spaced_config_for`). No hold-apart and no turn can carry a target out of a strike that would have reached it. The push runs along the line between centres, so cones and facing are unchanged.
- **Who moves.**
  - The **ally yields**. The move is soft and swept with `move_and_collide`, at 6 m/s plus any closing speed, so walking into the opponent is a stop, not a creep.
  - The **opponent holds** its host-authoritative position. It yields only a deficit older than 0.35 s, meaning the ally is pinned.
- **Bursts are exempt.** While either body is in a combat burst (the ally's dash, or a CHARGER/DIVER travelling lunge), the rule does nothing; the lane still decides the hit.
- **Geometry.** The rule runs before the arena hold. A correction whose centre line passes through geometry is undone.
- **Multiplayer.** The guest's proxy opponent and the host's remote puppets never run the rule. A guest corrects only its own piloted ally. Host, guest and solo use the same distances.
- **Hard rules kept.** Nothing is held, blocked or shielded, and no creature is scaled.

**Round 1 (`9b3d0cca`) capped the separation at the 2.75× collider floor.** Judge B still failed Ripplet in front of Water Mirejaw's face. The logged gap on those frames was 7.0 m, exactly the cap. Mirejaw's half-length is 5.49 m and Ripplet's is 1.94 m, so clearing them head-on needs 8.03 m. **Round 2 (`b2ce4df6`)** replaced the cap with the floors above (`c3/ROUND1_JUDGES.md`).

## Proof

| Check | Result |
|---|---|
| Unit: `tests/test_combat_contact_spacing.gd` | 8 tests, 88 assertions, 0 failed. Covers smallest to largest body, head-on vs broadside, and the reach-vs-separation invariant for every roster size at any facing (27 pairs). Also covers the host profile matching solo, share rules and the soft step. In live physics: pairs separate, a burst is exempt, a pinned ally does not go through the wall, and walking in stops. |
| Full unit suite, 4 shards, merged head (`UNIT_SUITE.txt`) | 5,274 tests, 0 failed |
| Net smokes `shared_wild_fight`, `cloudreach_riding` (`net/`, `net/round2/`) | ALL CHECKS PASSED, both rounds |
| Independent code review (read-only agent, round 1) | PASS. Low-severity notes only; the stale partner reference is fixed. |

## C2 before and after

"Before" is the same code with `contact_spacing.enabled=false`, which is exactly main's path. The Capacitor Alpha "before" reproduces the Balance lane's published numbers exactly (0.42 / 0.50 / 0.41). The two local fixture harnesses gave identical results in rounds 1 and 2.

**Capacitor Alpha** (`smoke_stormwood_b_named_c2c3.gd --seeds=24`, bar reader/masher ≤ 0.55):

| starter | ratio before | ratio after | reader win | max hit | masher incoming hits |
|---|---|---|---|---|---|
| terrapup | 0.42 | **0.22** | 1.00 / 1.00 | 0.034 | 175 → 263 |
| ripplet | 0.50 | **0.28** | 1.00 / 1.00 | 0.059 | 144 → 255 |
| galewisp | 0.41 | **0.21** | 1.00 / 1.00 | 0.063 | 242 → 245 |

The reader's cost is flat or lower. The masher now takes more hits, because its lunges used to carry it inside the Alpha's body, where the Alpha's strikes missed. **The spacing closes an accidental overlap dodge.**

**Oreth, Meadows captain** (`smoke_meadows_named_c2c3.gd --case=captain_riverwatch --seeds=24`). Every row passes before and after. Reader win is 1.00.
- Reader cost is 0.00 for ripplet and galewisp, and a little higher for terrapup (lead 0.41 → 0.54).
- **Masher win rose:** ripplet 0.04 → 0.46 and galewisp 0.17 → 0.67, with about 8% fewer incoming hits. Terrapup is unchanged.
- **Chapter bar (F04#7, ruling 12).** All seven Meadows fights were re-run for ripplet. Every row passes. `masher_loses_a_named_fight` is **0.68**, down from 0.97 (bar ≥ 0.25): PASS.
- Galewisp's masher still loses the Warrens guardian every run, so its chapter value stays at 1.00.

**Nerissa, in-world** (`batch_tidewake_named_inworld_c2.gd`, render.yml headless, 12 seeds per cell, 216 fights; `c2/nerissa_inworld/`):

| starter | reader win | masher wipe | reader party cost: main → round 1 → round 2 | max hit |
|---|---|---|---|---|
| galewisp | 1.00 | 1.00 | 0.176 → 0.158 → 0.209 | 0.149 |
| ripplet | 1.00 | 1.00 | 0.262 → 0.174 → 0.300 | 0.135 |
| terrapup | 1.00 | 1.00 | 0.241 → 0.252 → 0.299 | 0.134 |

C2 passes in every round. Round 2 costs the reader 0.03–0.06 more party HP. The ratios to the masher (1.00) stay 0.21–0.30, against a bar of 0.55. Tells are 0.8 s and the heavy is 1.1 s.

## C3 re-capture under `TIDEWAKE/phase1/C3_RUBRIC.md` (code-blind judges)

Captures were taken on render.yml (opengl3, 1280×720) with the same commands as the failing rounds. Gaps are the logged centre-to-centre distances (`frames.json`).

| Round | Frames with gap under 7 m | Judge A (sonnet) | Judge B (default) |
|---|---|---|---|
| Tess r5 (main, before) | 23 of 37 | 36/37 (97%) | 31/37 (84%), all 6 failures contact-range head occlusion |
| Tess r6 (round 1) | 3 of 38 | 38/38 (100%) | 28/38 (73.7%), 8 contact-range head occlusions |
| **Tess r7 (round 2)** | 2 of 39 | 35/38 (92.1%)¹ | **31/38 (81.6%)**: 4 Mirejaw ally-over-head at the full 8.0 m separation, 2 trainer-over-head, 1 off-screen |
| Nerissa r17 (main, before) | 18 of 53 | 51/52 (98%) | 43/52 (83%), 5 contact-range head stacking |
| Nerissa r18 (round 1) | 9 of 47 | 41/47 (87.2%) | 31/46 (67.4%), 8 contact-range head occlusions |
| **Nerissa r19 (round 2)** | 7 of 46 | 42/46 (91.3%) | **40/46 (87.0%), 0 ally-over-opponent-head failures** |

¹ Judge A's three Tess r7 failures are rule 5 (no tell ring). In `tell-start-000.38` the ring is visible under Mirejaw, partly hidden by its own body, which the rubric passes. This is recorded, not overridden.

**What round 2 shows.**
- **Nerissa: judge B's contact-range head-occlusion failures are gone** (5–8 before, 0 now).
- **Tess: not gone for judge B.**
  - Judge A finds none, and the Riverdrake and Sirenseal segments are clean.
  - Judge B still fails 4 Mirejaw frames. Their logged gaps are 8.02–8.43 m, which is the full rendered separation.
  - The bodies are held apart; the stacking comes from the fight camera sitting behind the ally and looking along a long opponent's axis.
  - This is the second attempt on this measurement (two-strike rule), so it is recorded for the camera and Tidewake owners rather than pushed further in spacing.
- Both judges still describe a few **hit-moment contacts**: snout to snout, or Ripplet's face at Mirejaw's open mouth. That is the strike's own lunge, before the soft correction resolves (about 0.1 s).
- **The remaining failures are not spacing:**
  - Nerissa's Heart Chamber crates hide the opponent's head (4 frames, judge B);
  - Riptusk is off-screen after its heavy lane (1);
  - the player's trainer stands over Riptusk's head (1).
  - These belong to the arena and camera owners.

## Not done here
- No biome criterion is marked met. The Tidewake, Meadows and Stormwood lanes re-judge their own C3 rows on main.
- **Residue for others (not this lane's scope):**
  - Tess/Mirejaw ally-over-head at full separation: fight-camera composition against long opponents (camera owner, with Tidewake);
  - Heart Chamber crate placement relative to the fight camera (Tidewake);
  - the Riptusk post-heavy crop (camera);
  - the trainer's stand over the fight (camera or placement).
