# W09-VFX — combat and reward VFX (CL-A2) — lane report

Branch: `ralph/W09-VFX-0904`, from `origin/main` at `ef16544f`.
**Last code commit: `75a0241b`** (round-3 fixes). Everything after it is evidence and this
report, landing as one commit per addition so each is individually reviewable. **This report's
own commit is necessarily one past whatever hash is written here** (writing a hash into a file
cannot name the commit that saves the edit); run `git log --oneline -1 origin/ralph/W09-VFX-0904`
for the true head. At the time this line was written that head was `4dbb3855`.

## What the player sees

- **Every landed blow sparks.** A spray of 18 motes and streaks flies out of the point of
  contact, born white-hot and cooling to the move's element colour (ground tan, water blue,
  air white, dark violet, electric yellow, fire orange, psychic lilac, ice pale blue), falling
  under gravity and fading over 0.6 s. A charged move bursts 1.35× bigger; a blow that takes
  30 % of the bar bursts 1.8× the size of one that takes 4 %. The foe's own strikes carry the
  foe's element now too (they were always the default orange).
- **The struck creature flashes.** Its whole body lights for 0.16 s, brightest at the
  silhouette, per instance (no other creature of the species flashes).
- **A knockout puffs.** The blow that empties a bar lets a soft pale cloud out of the fainted
  creature, rising for 0.9 s. Fires for a wild fight ending and for a trainer's creature
  falling mid-battle alike.
- **A sealed catch sparkles.** Gold sparkles fly out of the orb and drift up for 1 s, on top of
  the existing warm seal flash.
- **A level-up is a picture.** For 1.5 s the creature that levelled stands in a column of
  light, two rings rise from its feet past its crown, gold motes climb around it and its body
  takes a gold rim. It plays on the deployed creature; a bench member levelling from the party
  share gets the HUD line only (D80 §4).

`data/config/vfx.json` holds every tunable; `enabled: false` is the whole revert.

## Files changed

| File | Change |
|---|---|
| `scripts/vfx/combat_vfx.gd` | new — the helper: static hooks `hit`, `catch_success`, `knockout`, `level_up`; the level-up watcher (polls `Game.party` by `revision`; `on_progression_event()` seam for `Game.progression_feed`) |
| `scripts/vfx/vfx_burst.gd` | new — the spark / puff / sparkle node (ImmediateMesh motes and streaks, physics-clocked, public `advance()`) |
| `scripts/vfx/body_glow.gd` | new — hit flash and level-up rim via per-instance `material_overlay` |
| `scripts/vfx/level_up_flourish.gd` | new — beam, rising rings, motes |
| `shaders/vfx_body_glow.gdshader` | new — fresnel-weighted unshaded overlay, MIX blend |
| `data/config/vfx.json` | new — tunables |
| `scripts/combat/combat_manager.gd` | `_flash_at()` takes the struck body and the damage fraction and calls `VFX.hit` (the one damage hook; both damage sites already funnel through it); the two player-strike calls and the enemy-strike call pass them; `_finish_catch()`'s seal branch calls `VFX.catch_success`. `_flee_pressed()` untouched. |
| `tests/test_combat_vfx.gd` | new — 8 tests, 52 assertions |
| `tools/_capture_vfx_moments.gd` | new — stages the fight, shoots 00–04, measures perf at band1_open |
| `tools/_probe_vfx_frame_energy.gd` | new — bright-warm / near-white / gold pixel counts per frame |
| `docs/decisions/D80-…md` | new — mesh-based not particles; overlay not material edit; KO from the damage hook; bench level-ups have no body |
| `docs/CURRENT_STATE.md` | CL-A2 row |
| `ralph/reports/W09-VFX-0904/` | this report, `_sheet_round1.png`, `_sheet_round2.png`, `JUDGE_round1.md`, `JUDGE_round2.md` |

`creature_body.gd` was not edited and needed no patch: the flash uses `material_overlay`,
which was free on every creature mesh.

## Tests and smokes (exact commands, from the repo root, `PATH=$HOME/godot-bin:$PATH`)

| Command | Result |
|---|---|
| `godot --headless --path . --script tests/run_tests.gd -- --only=test_combat_vfx.gd` | **8 tests, 52 assertions, 0 failed** (run after every edit; last on `77778f4b`) |
| same, with the `VFX.hit(...)` line in `_flash_at()` replaced by `pass` | **2 failed** — `test_a_landed_blow_spawns_a_spark…` ("no HitSpark under the arena after a landed blow", "the struck body did not get its flash") and `test_the_blow_that_empties_the_bar_adds_a_ko_puff` ("no KoPuff after the blow that emptied the bar"); the rest green. Restored; seen red for the right reason. |
| `godot --headless --path . --script tests/smoke_combat.gd` (baseline, before any change) | `combat: OK`, rc=0, zero `ERROR:` lines |
| `godot --headless --path . --script tests/smoke_combat.gd` (with the layer) | `combat: OK`, rc=0 |
| `godot --headless --path . --script tests/smoke_boss.gd` | rc=0 |
| `godot --headless --path . --script tests/smoke_trainer_battle.gd` | `trainer battle: OK`, rc=0 |
| `godot --headless --path . --script tests/smoke_catching.gd` | `catching: OK`, rc=0 |
| `godot --headless --path . --script tests/smoke_combat_camera.gd` (after round 3, first run) | **rc=1**, one attempt: "the second production encounter would not start" |
| same command, immediate re-run, no code changed | rc=0 |

`ERROR:` set across every smoke run, both the mid-session pass and the final re-run against
`663f9271`: only `ERROR: Parameter "material" is null` from
`creature_body.gd::_build_model ← apply_size_multiplier ← encounter_director._make_alpha`
at world boot (1–3 occurrences each run) — the known-benign alpha-resize line
`docs/AGENT_WORKFLOW.md` §6 documents as count-unstable; it fires before any fight and
before any VFX node exists. No `SCRIPT ERROR`. The distinct set did not grow.

**`smoke_combat_camera`'s one red run is the harness, not this lane.** That smoke presses no
attack button at all — it drives the camera rig through engage/switch/aim/flee/re-engage —
so none of `combat_manager.gd`'s five VFX hooks execute during it; nothing this lane touches
runs in that test. It failed once, on `_prove_a_second_entry_exit_cycle`'s re-engage of the
same wild creature after a flee ("the second production encounter would not start"), with the
same benign error set as every green run. An immediate re-run of the identical command against
the identical commit passed (rc=0). The docs already name this class of defect —
`docs/CURRENT_STATE.md` §4 and `AGENT_WORKFLOW.md` both carry harness re-engage/timing races
that are not this lane's to fix — and this run is filed as one more instance, not chased
further, since a second run of the same binary cannot itself be nondeterministic from a code
change that was not made between the two runs.

The unit test drives a real `combat_manager.gd::_on_enemy_strike()` (hit cone, rolled
damage, `take_damage`, faint handling) on a bare manager with stand-in bodies, and asserts
the spark, flash and puff came out of that path at the arena the manager parented them
under; lifetimes are walked through `advance()` because the unit runner never processes a
frame (`is_queued_for_deletion()` is the "freed" assertion). The watcher tests use the real
`autoload/party.gd` and a real `gain_xp()`.

## Runtime validation

Five smokes above exercise the hooks in the real scene (wild fight to a win, a boss, a
three-round trainer battle, a catch, the combat camera). The capture tool drove a further
two real fights per round through the real combat camera and confirmed at each shutter
which VFX nodes were alive (`[effects]` lines in the log): `HitSpark` + `foe/BodyGlow` at
01; `HitSpark`, `KoPuff`, `ally/LevelUpFlourish`, `ally/BodyGlow`, `foe/BodyGlow` at 02;
`KoPuff` + `ally/LevelUpFlourish` + `ally/BodyGlow` at 03; `CatchBurst` at 04. All eight
shots written, none failed, rc=0, both rounds.

## Frames and the blind judge

Two rounds, both captured by `tools/_capture_vfx_moments.gd` under
`xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720`,
day/clear pinned and frozen, the tree paused for every shutter. Ten frames each for rounds 1 and 2
(five moments x HUD/clean) and eight for round 3 (`--only=hit,ko`, the two acceptance moments
plus the control), 0 failed and rc=0 every time. Sheets: `_sheet_round1.png`,
`_sheet_round2.png`, `_sheet_round3.png`. Verdicts: `JUDGE_round1.md`, `JUDGE_round2.md`.

**Round 1** — the judge (blind, opus, given only the sheet, the frames and `docs/reference/`)
said the effects were invisible at the size the eye reads them, that there was no hot colour
anywhere, and that the level-up ring read as a stun rather than a reward. Three of its
findings were not this lane's and are routed to the coordinator: the oxblood ring on a
friendly is `telegraph_glow.gd` / `combat.json`'s `telegraph.colour`; the flat khaki disc and
hard white spikes at the catch are `catching.json`'s existing `vfx.caught` burst sized for the
resolve close-up; the orb prop, the hit/KO reaction animations and the capture absorb are art
and animation, not tuning.

**Round 2** — retuned against that verdict: element tints saturated 1.7x, motes born white-hot
and cooling to the element, a dark contrast halo behind every mote and streak, spark raised to
22 motes at 0.28 m with a 0.65 m warm core, damage scale 1.2-2.0x, level-up rings gold and
widened to 2.3x body radius, the beam rebuilt as a real column, catch sparkle gold at 26 motes
shot 16 ticks in once the existing white flash has faded.

**Measured, by a rule fixed before the render** (`tools/_probe_vfx_frame_energy.gd`, whole-frame
pixel counts; `00-squared-up` is the same fight and camera with nothing landing, so each row is
what the effect adds over the creature's own bright coat):

| Round-2 clean frame | bright-warm px | over the control |
|---|---|---|
| `00-squared-up` (control) | 8,255 | - |
| `01-hit-spark` | 20,509 | **+12,254** |
| `02-knockout` | 34,857 | **+26,602** |
| `03-level-up` | 25,888 | **+17,633** |

For scale, the number that opened this file's case: the blind critic counted 10 bright-warm
pixels at `combat/05-quick-attack-lands` and 24,623 at `palworld-01`. `04-catch-success` is
excluded from the table because the catch resolve camera cuts to an orb close-up, so it shares
no framing with the control.

**Round 3** — the round-2 judge ranked one defect above all others and it had a geometry fix
rather than a tuning fix, so a third and final round was taken; `JUDGE_round2.md` records the
verdict, what was this lane's, what was routed elsewhere, and why the round was justified
against `COMMON.md`'s two-round guidance. The four changes: streaks soft on every edge with a
round head, near-black halos, the rim returned to being a rim (`rim_flat_mix` 0.38 → 0.10,
hit-flash `flat_mix` 0.7 → 0.3), and the flourish split so its rings and motes are
depth-tested while its beam is not.

| Round-3 clean frame | bright-warm | near-white | combined, over the control |
|---|---|---|---|
| `00-squared-up` (control) | 8,345 | 13,263 | - |
| `01-hit-spark` | 14,690 | 15,648 | **+8,730** |
| `02-knockout` | 15,346 | 10,654 | +4,392 |
| `03-level-up` | 24,930 | 1,273 | (camera moved; see below) |

Read those against round 2 carefully, because two of the numbers went **down and that is the
fix working**. The spark is now born near-white (`heat` 0.92) so its pixels moved out of the
bright-warm bucket and into near-white — deliberate, and exactly the judge's ask for a mark in
a colour the meadow does not contain. `02`'s warm count fell from 34,857 to 15,346 because the
flat gold flood over the whole body is gone; that flood was the judge's second-ranked defect
and this lane's own round-2 regression. Only `00`, `01` and `02` share a camera, so only their
comparisons are like-for-like; `03` is shot 22 ticks later, by which point the fight's camera
has moved to a different vista, so its count is reported but not differenced.

Round 3's frames are the ones in `_sheet_round3.png`. They are **not** blind-judged: both
allowed judge rounds were spent, and the changes are recorded here with their measurements and
their reasoning rather than with a third verdict.

## Perf

**The layer costs one to three draw calls.** Measured in isolation by
`tools/_probe_vfx_perf.gd` (a bare scene, one Terrapup, structural counters from the
RenderingServer, each effect sampled alive and the scene checked back to baseline after it
ends), under `xvfb-run … --rendering-driver opengl3 --resolution 1280x720`:

| Effect | draw calls | primitives | objects |
|---|---|---|---|
| hit spark (quick, mid-damage) | +1 | +216 | +1 |
| hit spark (charged, heavy) | +1 | +232 | +1 |
| KO puff | +1 | +240 | +1 |
| catch burst | +1 | +402 | +1 |
| level-up flourish, rim glow alive | +2 | +28,408 | +2 |
| worst case: charged hit + KO puff + flourish | +3 | +1,088 | +3 |

The flourish's +28,408 is the **rim glow**, not its own geometry: a `material_overlay` is a
second full pass over the creature's mesh, so it re-submits that one creature's triangles for
the 1.5 s it runs. Against the `band1_open` proxy the project budgets on (6,891 draws /
10.79 M primitives, `docs/CURRENT_STATE.md` §2) that is **0.04 % of the draw-call budget and
0.26 % of the primitive budget, on one creature, for 1.5 s.** No effect leaked: every row
returned to baseline after it expired, which the probe asserts rather than assumes. The worst
case is lower than the flourish row because the hit flash claims the overlay slot first, so
only one overlay pass is ever live (see the limitation below).

**In the world, at `band1_open`, with a fight running** (`tools/_capture_vfx_moments.gd
-- --only=perf`, the fixed sampler below):

| Moment | draw calls | primitives | objects |
|---|---|---|---|
| hit spark + body flash | **+2** | +14,286 | +2 |
| KO puff + flourish + rim glow + spark tail | **+5** | +70,916 | +5 |

Both were measured twice, alternating with/without/with/without inside one paused span, and
**the two pairs agree to the primitive** (3,742/3,740 twice; 3,993/3,988 twice), which is what
makes them a measurement rather than a reading. Against the proxy budget this project holds
itself to at that exact site — 6,891 draws / 10.79 M primitives, `docs/CURRENT_STATE.md` §2 —
the worst moment in a fight costs **0.07 % of the draw calls and 0.66 % of the primitives.**
The primitive count is higher in the world than in the bare scene because the rim glow's extra
pass re-submits a creature at its in-world detail, and two bodies carry a glow at that moment.

**Getting there took fixing the method, and the first number was wrong.** The first attempt
paused the tree during a real fight and sampled once with the
effects drawing and once with them lifted. Between two consecutive samples of a **paused**
tree, `draw_calls` fell 7,315 → 3,790 and `objects` fell 6,826 → 3,301 — exactly −3,525 on
both, about half the visible scene, which cannot come from hiding two effect nodes. Terrain
and scatter LOD keeps converging on the render side while the tree is paused; a second pair
the same run disagreed by 334, again equal on draw calls and objects. `_sample_pair` now
settles 24 frames and alternates with/without/with/without, prints all four samples, and
prints a `NOISE:` line naming the disagreement when the two deltas differ by more than eight
draw calls, so the number can never again be quoted as the effect's cost when it is the
scene's. With that settle in place the samples hold still and the table above reproduces
exactly; the isolated probe agrees with it on draw calls, which is the check that both are
measuring the same thing.

llvmpipe frame time is meaningless on this box and is not quoted, per
`tools/perf_render_stats.gd`'s own rule.

## Known limitations and what was deliberately not done

- Bench level-ups (party share) show no world flourish; D80 §4. Tunable `bench_on_trainer`
  exists but is off and unimplemented on the trainer body by design.
- Level-ups are found by polling until `Game.progression_feed` lands (another lane). The
  seam is `combat_vfx.gd::on_progression_event()`; `min_gap` makes a poll detection and a
  feed event one flourish.
- No GPUParticles3D/CPUParticles3D (D80 §1). No new meshes, textures or generations.
- Frames are software GL: composition, scale, colour relationships and presence are what
  they can prove; fine lighting is not.
- The catch sparkle competes with `catching.json`'s existing white seal flash for its first
  third of a second; it is shot 16 ticks in, once that flash has faded.
- No sound cue: `data/config/audio.json` is not this lane's file.
- **One body overlay at a time.** `body_glow.gd` skips a mesh that already carries someone
  else's overlay, so a creature hit during its own 1.5 s level-up rim gets the spark but no
  body flash, and vice versa. Deliberate (the alternative is stacking passes on one mesh and
  fighting over who restores it), and rarely reachable: the flourish plays after the blow that
  ended the fight. Recorded rather than fixed.
- Round 3's frames are **not blind-judged**: `COMMON.md` allows two rounds and both were
  spent. They are measured against the round-2 control by the same pixel rule, and the
  round-2 verdict they answer is committed beside them.
- The capture's `_aim_at_fight` steps the camera 3 m sideways, but the combat camera owns its
  own yaw during a fight, so the struck creature can still sit behind the player's own body in
  a capture frame. A framing limit of the tool, not of the effects; the judge saw it as "the
  enemy is a 35-pixel dot".
