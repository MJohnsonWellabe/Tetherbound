# G3-READS-AS-CREATURE-GAME — lane report

**Lane:** design contract only (read-only on code, data, assets, tests).
**Branch:** `ralph/G3-READS-AS-CREATURE-GAME-0904` from `ralph/G3-LAND-0904` (`44f06cf9`).
**Deliverable:** `docs/specs/GATE3_CREATURE_PRESENCE.md` — five contracts (CP-1…CP-5), ranked,
each with the lane it routes to and a *fails if* for the next blind judge.
**Touched:** that file and this directory. No PR.

## What the judge's five absences actually are

Checked in the scripts, the scene and the config, not the comments.

| Absence | Verdict | Evidence |
|---|---|---|
| Companion beside the trainer | **Built, invisible** | `follower_creature.gd` is a complete following body, summoned by `adopt_starter()` and the recall press. It is never summoned after a load (`summon_active_creature()` has three callers, none on load; harness notes RIG-11/RIG-13 in `S06.json`/`S03C.json` work around this by pressing recall). Its heel point is 3–8 m *behind* the trainer at 3.8 m/s walk against the trainer's 5.0, with the camera 5.2 m behind — so on a walk it oscillates across the lens, and at a sprint (8.6 vs its 7.2 run) it is shed. When it faints, it is hidden and nothing replaces it until a `party_cycle` press. Its summon spot and leash re-place use `_player.global_basis`, which never turns (`player_controller.gd` yaws only the model child), so "behind the right shoulder" is a fixed world offset. **All sixteen judged frames show `Call Out` in the legend: it was not out in any of them.** |
| Creature at readable size | **Partly built** | Contact shadow, `field_emission`/`field_rim`, alpha aura, elder title, shrub-clear siting all exist. There is no rule tying cluster placement to where the player walks; the practice cluster's 15 m radius is pinned by a test. Distance, not height, is the open lever (height is closed by OD-0901-1). |
| Combat VFX | **Built, never photographed** | `impact_flash.gd`, `telegraph_glow.gd`, `move_projectile.gd`, `target_marker.gd`, the arena band and a 4.6 m/62° fight camera all exist. The capture lane stood where a fight *had* happened with none running (2.8 §8.2). Genuine gap: the level-up is a HUD text pulse (`combat_hud.gd:1242`) with no world beat, and the enemy panel shows no level. |
| Catch affordance | **Built in-fight; nothing outside** | Reticle with explicit %, arc preview, orb, Throw/"No orbs" cell, target slow-down while aiming. Outside a fight: orbs are `kind: gear`, the hotbar refuses that kind, so the count is never on screen; the engage prompt gives no catch cue. |
| Nameplates / level tags | **Does not exist** | No plate or `Label3D` over any creature anywhere. Name appears only in the engage prompt (≤ 6 m), the combat panels, and party rows. Argued both ways in §6; recommendation is a range-gated plate (B), escalated. |

## Ranking

1. **CP-1 companion** — 1a summon on load; 1b flank heel point and hold-station speeds; 1c next healthy creature out on faint. Changes 14 of 16 frames. Routes: 1a/1c → G3-OPENING-FIX (`encounter_director.gd`, beside its 2.11); 1b → `follower_creature.gd` + `opening.json` `follower` (file-owner G3-CREATURE-COLOUR; recommend the coordinator hands that one file to G3-OPENING-FIX).
2. **CP-2 road herd** — 2a a cluster within 12 m (small species) / 25 m (tall species) of the spine every ~250 m, tall commons preferred; 2b per-instance scale/facing/idle variance; 2d first ambient creature in the first outdoor minute. Routes: band `spawns.json` → G3-BAND1-FINISH (band lanes for 2–5); 2b → spawn path in `encounter_director.gd`; 2c colour already G3-CREATURE-COLOUR.
3. CP-3 combat picture — 3a stage the fight/aim/level-up frames (G3-HARNESS, 2.15's row); 3b level-up world burst + world message (G3-OPENING-FIX / G3-HUD); 3c foe level on the fight plate (G3-HUD).
4. CP-4 catch read — 4a orb glyph+count on the wild engage prompt; 4b aim frame in every set; 4c orb count in the active-creature block (G3-HUD).
5. CP-5 nameplates — owner decision.

**With time for two: CP-1 and CP-2.** CP-3a should ride along in G3-HARNESS regardless — it is what lets the next judge see the other two.

## Escalated to the owner, not answered

1. Nameplates: none / range-gated (recommended) / Palworld-style always-on. A look decision against the board's naturalism.
2. CP-1c auto-swap to the next healthy creature on faint: recommended, small, announced; confirm or veto.
3. Which flank (right recommended; noted only so it is recorded).
4. Where the orb count lives in exploration (active-creature block recommended, or a hotbar exception for `gear`).

## Method note

The distinction this lane was asked for — exists-but-invisible vs missing — came from reading call sites, not headers. The companion's header, config comment and smoke test all describe a working feature, and they are right; none of them says where it stands relative to the camera, and no test asserts it. The Warren Guardian lesson (`GATE3_ENCOUNTER_CONTRACTS.md` §1.2) applied in reverse: the documentation was accurate and the player still never sees the thing. Every *fails if* in the contract is a screen-space or event-time measurement for that reason.
