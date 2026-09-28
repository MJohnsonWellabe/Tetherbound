# Combat contact spacing (shared combat, Phase 1)

**Problem.** Tidewake F14#0 (Tess) and F14#1 (Nerissa) failed C3 on one defect only: at contact range (4.7–6.6 m) the rendered ally and opponent overlapped, the ally stood in front of the opponent's head, and no camera could separate them. Meadows F04#2/#7 and Stormwood F10#2 hit related framing failures.

**Rule** (`scripts/combat/contact_spacing.gd`, applied in `creature_body.gd::_hold_contact_spacing`, tunables in `combat.json` `contact_spacing` with `_why`):
- Minimum separation = the two **directional rendered half-extents** (the fitted art's footprint as an ellipse, so a long body met head-on stands further out than broadside) + **0.6 m** (COMBAT §5).
- Floored at the colliders' sum. Capped at the opponent's existing spacing floor `(r_a + r_b) × enemy.body_clearance`. Every reach is floored 0.5 m beyond that, so a hold-apart cannot carry a body out of a strike that would have reached it. The push is along the line between centres, so cones and facing are unchanged.
- **The ally yields** (soft, swept with `move_and_collide`, 6 m/s plus any closing speed, so walking into the opponent stops rather than creeps). **The opponent holds** its host-authoritative position. It yields only when a deficit outlives 0.35 s, meaning the ally is pinned by a wall or the ring.
- Exempt while either body is in a combat burst: the ally's dash, or a CHARGER/DIVER travelling lunge. The lane still decides the hit.
- Runs before the arena hold. A correction whose centre line passes through geometry is undone.
- Multiplayer: the guest's proxy opponent and the host's remote puppets never run the rule. A guest corrects only its own piloted ally against the host's proxy. Host, guest and solo use the same distances.
- Hard rules kept: nothing is held, blocked or shielded, and no creature is scaled.

## Proof

| Check | Result |
|---|---|
| Unit: `tests/test_combat_contact_spacing.gd` (smallest to largest body, head-on/broadside, cap vs reach for every roster size, share rules, soft step, live physics: pairs separate, burst exempt, pinned ally, walk-in stops) | 7 tests, 49 assertions, 0 failed |
| Full unit suite, 4 shards (`UNIT_SUITE.txt`) | 5,258 tests, 0 failed |
| Net smokes `shared_wild_fight`, `cloudreach_riding` (`net/`) | ALL CHECKS PASSED (both) |
| Independent code review (read-only agent) | PASS; low-severity notes only (one fixed: stale partner reference cleared) |

## C2 before/after

"Before" is the same code with `contact_spacing.enabled=false`, which is exactly main's path. The Capacitor Alpha "before" reproduces the Balance lane's published numbers exactly (0.42 / 0.50 / 0.41).

**Capacitor Alpha** (`tests/smoke_stormwood_b_named_c2c3.gd --seeds=24`, bar reader/masher ≤ 0.55):

| starter | ratio before | ratio after | reader win | max hit | masher incoming hits before → after |
|---|---|---|---|---|---|
| terrapup | 0.42 | **0.22** | 1.00 / 1.00 | 0.034 | 175 → 263 |
| ripplet | 0.50 | **0.28** | 1.00 / 1.00 | 0.059 | 144 → 255 |
| galewisp | 0.41 | **0.21** | 1.00 / 1.00 | 0.063 | 242 → 245 |

The reader's cost is flat or lower. The masher now takes more hits: its lunges used to carry it inside the Alpha's body, where the Alpha's strikes missed. **The spacing closes an accidental overlap dodge; it does not open one.**

**Oreth, Meadows captain** (`tests/smoke_meadows_named_c2c3.gd --case=captain_riverwatch --seeds=24`): every row PASS before and after. Reader win is 1.00 in both. Reader cost is 0.00 for ripplet and galewisp in both, and a little higher for terrapup (lead 0.41 → 0.54, party 0.10 → 0.13, against the masher's 1.00). **Masher win rose:** ripplet 0.04 → 0.46 and galewisp 0.17 → 0.67, with about 8% fewer incoming hits (596 → 549, 605 → 557). Terrapup is unchanged (0.00).
- That is a real shift in how often a masher beats Oreth, disclosed here.
- The F04#7 bar is judged per chapter (ruling 12), so all seven Meadows fights were re-run for ripplet (`RUN_meadows_all_ripplet_after.txt`). Every row passes.
- `masher_loses_a_named_fight` is **0.68**, down from 0.97 (bar ≥ 0.25): **PASS**.
- Galewisp's masher still loses the Warrens guardian every run, so its chapter value stays at 1.00.

**Nerissa, in-world** (`tests/batch_tidewake_named_inworld_c2.gd`, render.yml headless, 12 seeds per cell, 144 fights; before at main `13800d03`, after at `9b3d0cca`; `c2/nerissa_inworld/`):

| starter | reader win | masher wipe | reader party cost before → after | max hit |
|---|---|---|---|---|
| galewisp | 1.00 / 1.00 | 1.00 / 1.00 | 0.176 → 0.158 | 0.149 |
| ripplet | 1.00 / 1.00 | 1.00 / 1.00 | 0.262 → 0.174 | 0.132 |
| terrapup | 1.00 / 1.00 | 1.00 / 1.00 | 0.241 → 0.252 | 0.134 |

No material change. C2 passes. Tells are 0.8 s and the heavy is 1.1 s.

## C3 re-capture under `TIDEWAKE/phase1/C3_RUBRIC.md` (two code-blind judges)

Captures were taken at `9b3d0cca` (render.yml, opengl3, 1280×720), with the same commands as the failing rounds.

**Contact-range frames.** Gap in the 4.7–7 m band, before → after:
- Tess: 23 of 37 (r5) → 3 of 38 (r6).
- Nerissa: 18 of 53 (r17) → 9 of 47 (r18).

JUDGES_PLACEHOLDER

## Not done here
- No biome criterion is marked met. The Tidewake, Meadows and Stormwood lanes re-judge their own C3 rows on main.
