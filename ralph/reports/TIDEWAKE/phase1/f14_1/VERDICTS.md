# F14#1 Veilfall and Guardian (Nerissa) C2/C3 (Phase 1)

"Guardian C2/C3" in the Tidewake BOSSES means the Nerissa fight (owner, 2026-09-26).
Veilfall interior readability was judged with F13#5's frames (`../f13_5/interior_r3`,
`interior_r4`). Captures run locally under xvfb with opengl3 (Mesa llvmpipe) at
1280x720, in the production Heart Chamber with the production CameraRig and HUD.

## C2: the regression and its cause
The in-world C2 passed at 4398c59e (`../../full/f14_1_nerissa_inworld_c2/`, 144 fights,
READER median party cost 0.12-0.24 of the masher's). At 811c3244 and 652f2b5e it failed,
with READER cost 0.68-0.83 (`c2_811c3244/`, `c2_652f2b5e/`).

- **Bisect** (`c2_bisect/`, render.yml, ripplet READER seeds 1-4 on seven heads): cost was
  0.04-0.22 at 4398c59e and 0.6-0.9 on every head from 84b0f479. The only combat change in
  that range is dbe43195, which gave Nerissa's Riptusk the travelling CHARGER lane
  (BOSSES 4.11 Break Tether's marked lane).
- **Local trace** (instrumented copy of the smoke, not committed):
  - every incoming hit came from Riptusk;
  - the READER sidesteps the lane, and in the failing tells its velocity was 0 with the
    stick held;
  - the colliders were the Sluice Crossing's bridge box and the Heart Chamber lip.
- **Cause.** Her fights form about 8 m in front of her, between the fighters. From
  (9, 0, 91) the 11 m ring was centred 3 m inside the chamber lip and reached into the
  Sluice Crossing, whose channel beside the bridge lies 1 m below both floors. A
  sidestepping ally dropped in and was pinned.
- **Fix.** Her stand moves to (9, 0, 100), with the ring centre at about (1809, 4232).
  The ring now sits 12 m inside the lip.

**C2 at a3269be7: PASS** (`c2_a3269be7/`, 144 fights, 9 render.yml headless cells,
`SUMMARY.txt` from `../../full/f14_1_nerissa_inworld_c2/summarize.py`)

| starter | pilot | win | party wiped | median party HP lost | max single hit | tells (s) |
|---|---|---|---|---|---|---|
| galewisp | MASHER | 0.00 | 1.00 | 1.00 | 0.166 | 0.8-1.1 |
| galewisp | READER | **1.00** | 0.00 | **0.119** | 0.181 | 0.8-1.1 |
| ripplet | MASHER | 0.00 | 1.00 | 1.00 | 0.165 | 0.8-1.1 |
| ripplet | READER | **1.00** | 0.00 | **0.070** | 0.117 | 0.8-1.1 |
| terrapup | MASHER | 0.00 | 1.00 | 1.00 | 0.166 | 0.8 |
| terrapup | READER | **1.00** | 0.00 | **0.241** | 0.134 | 0.8-1.1 |

Against the C2 bars:
- reader win is at least 75% (1.00 for every starter);
- masher team wipe is at least 25% (1.00);
- the reader's median party cost is at most 55% of the masher's (the ratios are 0.12, 0.07 and 0.24);
- no neutral single hit takes 50% of entry HP (the largest is 18%);
- ordinary tells are 0.8 s and the heavy is 1.1 s.

The later heads change only the camera (liners) and presentation. The pilot maps its
stick through the camera's yaw either way.
- The earlier 652f2b5e face-lock tuning keyed the ordinary-strike lock, not the lane's,
  and measured no change. It was reverted (6ba25e5c).

**C2 at the 9 m ring (main 1e0ddd39): PASS under option (c)** (`c2_1e0ddd39/`: 144 in-world fights in 9 render.yml headless cells; `SUMMARY.txt`).
- `arena_radius` is 9.0 in every run, from `water_veilfall.gd::combat_arena_bounds_at` with the stand at x 7.

| Starter | Reader win | Masher lead-faint / wipe | Reader / masher median party cost | Max single hit |
|---|---|---|---|---|
| galewisp | 1.00 | 1.00 / 1.00 | 0.13 | 0.149 |
| ripplet | 1.00 | 1.00 / 1.00 | 0.24 | 0.135 |
| terrapup | 1.00 | 1.00 / 1.00 | 0.24 | 0.128 |

- **Tells:** declared 0.8 s and 1.1 s. Observed from tell start to strike: 0.80-1.58 s, where 1.58 s is the 1.1 s heavy plus Riptusk's 7 m travel.

## C3 rounds at the new stand
| Round | Stand and change | Framing | Tells | Heavy distinct |
|---|---|---|---|---|
| r5 (old stand) | (9, 0, 91) | 38/41 PASS | landing spot 0/7 (the heavy was not reached) | not reached |
| r6 | (3, 0, 100) | 41/53 (77%): the central crystal hides the opponent (8) | 12/12 | YES |
| r7 | (9, 0, 100) | 45/53 (85%): the camera on the east ledge walkway and in the vines after the Riptusk heavy | 12/12 | YES |
| r8 | + camera-only side liners (x 18.2-21, y 3-12) | 46/53 (87%): collapses inside the ally and banner after the heavy lunge; the ally hides the opponent (2) | 11/12 | YES |
| r9 | + Riptusk opt-in `body_clear.ignore_lunging_foe` | 45/55 (82%): the camera swings into the east heart banner | 11/12 | YES |
| r10 | r9's opt-in reverted; liners widened to x 17-21 over the banners | **45/53 (85%)**: 7 of 8 failures fall in the Riptusk lane-lunge moments (259-262 s, 288 s) | 12/12 | YES |
| r11 | + a side-on "lane view" while Riptusk winds up its lane (reverted) | worse than r10 on the same failures | | |
| r12 | lane view reverted; the shared head-occlusion test (the camera swings when the ally hides the opponent's head, no dither) | **45/53 (85%)**: 6 consecutive failures 253.97-256.08 s through the heavy lunge (camera inside the ally, then facing walls and banners), plus t-288 (a crate) | 11/12 | YES |
| r13 | + a camera hold through Riptusk's travelling lunge, then a cut (reverted) | 37/47 (79%): the READER steps out of the lane to the east wall and the lens stands in the banner cloth | 10/12 | YES |
| r14 | lunge hold reverted. The Heart Chamber answers CombatManager's arena contract (`water_veilfall.gd::combat_arena_bounds_at`, `arena_bounds`): the ring stops 5 m inside the side walls, 1 m inside the liners, giving 7 m at x 9 | judge A 62/62, judge B 40/62; **adjudicated 50/61 (82%)**. No wall or banner frames. Failures: Bramblebun under Mirejaw's jaw (5); Riptusk at contact range, swinging and under the skill HUD (6) | 12/12 | YES |
| r15 | fixed rubric from here (`../C3_RUBRIC.md`, two judges, both must reach 90%); stand x 7 (9 m ring); `tell_camera_swing` on her four | A 49/51 (96%), B 44/53 (83%): the opponent past the right edge while the tell swing runs at a 10 m gap; crates over Mirejaw | 12/12 | YES |
| r16 | tell swing only within 7 m | A 48/53 (90.6%), B 43/53 (81%): Riptusk after its heavy lunge (lost, stacked behind the ally), the camera inside the ally at t-288 | 12/12 | YES |
| r17 | + Riptusk `camera_ignore_lunge` (body_clear ignores its travelling lunge) | A 51/52 (98%), B 43/52 (83%): contact-range head stacking (5), Riptusk after the heavy (3), a crystal (1). No camera-inside-ally frames | 12/12 | YES |

**C3 is still open; blocked after r17** (two-strike rule: r15-r17 all fail judge B at 81-83%).
- The ring bound, the tell swing and the lunge opt-in each removed their own failure mode: the banner wall, the far-gap edge crop, and the camera in the ally.
- What is left is contact-range occlusion. After a strike the two bodies overlap, and the ally stands in front of the opponent's head. The camera cannot separate touching bodies.
- The same residue fails Tess.
- It needs a shared combat rule for contact spacing (bodies interpenetrate today). That rule changes C2 balance and is shared with the other lanes' named fights.

Earlier notes: Framing sits at 82-87% across six rounds at the new stand (bar
90%, COMBAT.md camera: both combatants' facing and the actionable tell in 90% of active
combat samples). Tells pass (12/12, heavy distinct). The remaining failures cluster where
Riptusk's 7 m travelling lunge runs through the ally: the fight camera clips into the
ally or loses a fighter. That is the shared CHARGER-lunge camera behaviour:
- Meadows' F04#1 `body_clear.ignore_lunging_foe` (1179a331) was switched off in batch 67
  until judged;
- enabling it for this body alone (r9) swung the camera into the banner.

Next: a combat-camera rule for a charge through the ally, shared with F04#1.
Recorded as blocked on it.

Every round reads the heavy tell as distinct: an orange "!! HEAVY — get clear" banner,
plus a lane with chevrons running from Riptusk through the ally.

## Recorded, not fixed (outside this row, or Phase 2)
- The ability panel drops out while "it missed you" or "it's open" shows (every round).
  It is a HUD defect shared by all fights.
- The ordinary tell ring is centred on the attacker and shows no reach toward the ally.
- The ally hides the opponent's head at close range, with the camera directly behind
  the ally.
- The Veilfall interior route is readable in every frame. Room identity is WEAK
  (interior_r4: 1 READS / 5 WEAK / 0 NO) and goes to the Phase 2 catalog.
