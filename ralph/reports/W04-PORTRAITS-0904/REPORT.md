# W04-PORTRAITS-0904 — every NPC speaks with its own face (Phase 1.1 / CL-G11)

Branch `ralph/W04-PORTRAITS-0904`, from `origin/main` @ `ef16544f`.
Owner directive 2026-09-04 item 8b: *"fix the picture during dialogue always being the
main character."*

## Outcome

Before: `assets/ui/portraits/` held `trainer.png` and `grandpa.png`; 119 authored
`portrait` fields outside `stronghold.json` named `trainer.png`, so every villager, trainer
and Team Tether rank was drawn with the player's face.

After: 34 rendered plates beside the two painted ones, every conversation outside
`stronghold.json` re-pointed to its speaker's plate, and a test that walks every line
through the real runner and refuses the player's face on anyone else. A played
conversation with Halda and with Oskar shows their own face in the box beside their body
(`_sheet_ingame_conversations.png`).

## Files changed

| File | What |
|---|---|
| `assets/ui/portraits/*.png` (+`.import`), 34 new | Rendered plates. Eight-name contract: `villager_male`, `villager_female`, `grunt`, `officer`, `captain`, `warden` (+ existing `trainer`, `grandpa`). Named cast: `mira`, `tam`, `halda`, `rae`, `doss`, `villager_ranger`, `bryn`, `wandering_trainer`, `juno`, `wilhelm`, `nessa`, `corin`, `ada`, `fenn`, `garrick`, `old_perrin`, `tobin`, `maren`, `sorrel`, `lark`, `ren`. Team Tether individuals: `grunt_a/b/c`, `officer_a/b`, `captain_a/b`. `trainer.png` and `grandpa.png` untouched. |
| `tools/_capture_portraits.gd` (new) | Renders every plate from the installed rig through `village_npcs.gd::model_config()` (the world's own dressing call: rank palette, `base` override, hair) in a transparent 512² SubViewport downscaled to 256², framed from the measured hair top. `-- --ingame` boots the Meadows and photographs two real conversations at 1280×800. |
| `data/dialogue/village.json`, `trainers.json`, `relay.json`, `meadows_freed.json`, `bands/band1..5*.json` | 119 `portrait` fields re-pointed (`ralph/reports/W04-PORTRAITS-0904/repoint_portraits.py` is the exact, re-runnable edit). `stronghold.json` untouched (other lane). `band1_lower_meadows.json`'s stale `_comment_portraits` rewritten. `opening.json` unchanged (Grandpa already correct). |
| `tests/test_dialogue_portraits.gd` (new) | Five tests, see below. |
| `docs/decisions/D81-…md` (new) | The three bodiless speakers and the female-rig hair finding. |
| `docs/CURRENT_STATE.md` | One new §3 row (P2, struck through, fixed on this branch). |
| `ralph/reports/W04-PORTRAITS-0904/` | `_sheet_portraits.png` (34 plates, 1536×1536), `_sheet_ingame_conversations.png` (two 1280×800 frames), three judge verdicts, `repoint_portraits.py`, this report. |

Not touched: `scripts/ui/dialogue_panel.gd` (draws what the line names; every plate shows),
`data/dialogue/stronghold.json`, `docs/GATE2_GATE3_CLOSURE_PLAN.md` (CL-G11 row still reads
"proven failing (owner)" — coordinator to flip on landing), `docs/owner/*`.

## Speaker → portrait table

| Speaker(s) | Body the world uses | Plate |
|---|---|---|
| Grandpa Elias | `grandpa` | `grandpa.png` (existing, painted) |
| Mira | `villager_farmer` (female rig, chestnut ponytail) | `mira.png` |
| Tam | `villager_smith` (female rig, silver ponytail) | `tam.png` |
| Halda | `villager_ranger` + iron-grey hair (`village_npcs.json`) | `halda.png` |
| Rae | `villager_farmer` + `#7a4a2c` hair | `rae.png` |
| Doss | `villager_ranger` + `#4a5c3d` hair (`river_nest_clear.gd`) | `doss.png` |
| Sela, "Rescued Ranger", Dara, Nan | `villager_ranger` | `villager_ranger.png` |
| Oskar, Bram, Kell, Quarry Foreman | `villager_keeper` / `villager_quarryman` (male rig, no hair part) | `villager_male.png` |
| Coll (Broken Cart; no body placed) | — | `villager_male.png` (D81) |
| "Trainer" (generic refusals in `trainers.json`; any trainer) | — | `villager_male.png` (D81) |
| "Team Tether Notice" (hall-approach board) | — | `grunt.png` (faction plate, D81) |
| Bryn | `young_trainer` | `bryn.png` |
| Gil, Old Bram | `wandering_trainer` | `wandering_trainer.png` |
| Juno | `rival_trainer` | `juno.png` |
| Wilhelm / Nessa / Corin / Ada / Fenn / Garrick / Old Perrin / Tobin / Maren / Sorrel / Lark / Ren | `innkeeper` / `inn_helper` / `trader` / `craftsperson` / `creature_caretaker` / `farmer` / `local_historian` / `lost_traveler` / `field_researcher` / `alpha_tracker` / `courier` / `former_tether_member` | one plate each, same name as the speaker |
| Tether Grunt (South Bridge), Kest, Watchman Corr | rank `grunt`, base `grunt_a` | `grunt_a.png` |
| Dorn, Hess, Tether Patrol (ridgeline) | rank `grunt`, base `grunt_b` | `grunt_b.png` |
| Pell, Orrin | rank `grunt`, base `grunt_c` | `grunt_c.png` |
| Tether Grunt (night watch), Tether Patrol (lost creature), Patrolman Verrick | rank `grunt`, default base | `grunt.png` |
| Officer Dell | rank `officer`, base `officer_a` | `officer_a.png` |
| Warder Ness | rank `officer`, base `officer_b` | `officer_b.png` |
| Warder Solene | rank `officer`, default base | `officer.png` |
| Captain Vance, Captain Halder | rank `captain`, base `captain_a` | `captain_a.png` |
| Captain Oreth, Captain Vess | rank `captain`, base `captain_b` | `captain_b.png` |
| Keeper Hald | rank `captain`, default base | `captain.png` |
| Warden Aldis, Chamber Five, Tether Readout, Tether Duty Board | `stronghold.json` — other lane | `warden.png` rendered and waiting; file not edited here |

The player speaks no authored line today, so `trainer.png` is now used by nothing outside
`stronghold.json` (8 fields there, pending that lane).

## Tests

All commands from the repo root with Godot 4.7-stable on `PATH`.

**Seen red first** — the new test on the unmodified data (commit `ef16544f` data, before any
plate or re-point):

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_dialogue_portraits.gd
5 tests, 1929 assertions, 3 failed
  FAIL test_no_line_spoken_by_someone_other_than_the_player_wears_the_players_face
  FAIL test_ranked_and_family_speakers_wear_their_own_plate_family
  FAIL test_the_eight_contract_plates_exist_and_load
```
(156 failed assertions: six missing contract plates, and every villager / Team Tether line
wearing `trainer.png`.)

**Green after**, same command: `5 tests, 1935 assertions, 0 failed`.

The five tests: every line's portrait loads as a `Texture2D` ≥128 px from the portrait
folder; no non-player line (speaker ≠ the runner's `$name` substitution) resolves to
`trainer.png`; the eight contract plates exist, load and are square; speakers whose name
starts `Grandpa`/`Captain `/`Officer `/`Warder `/`Watchman `/`Patrolman `/`Tether Grunt`/
`Tether Patrol`/`Warden ` wear that family's plate; and the table has >100 lines (so an
empty table cannot pass). Lines are produced by `dialogue_runner.gd` `start/line/advance`,
never by reading JSON text.

Carve-out: `stronghold.json`'s conversation ids are exempt from the not-the-player rule
only (they still must load), because that file is re-pointed by its own lane. **Delete
`STRONGHOLD_PATH` and the two `_is_exempt` calls once that lane lands.**

Named suites, all green:

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_dialogue_runner.gd
66 tests, 1013 assertions, 0 failed
godot --headless --path . --script tests/run_tests.gd -- --only=test_band_dialogue.gd
3 tests, 63 assertions, 0 failed
godot --headless --path . --script tests/smoke_dialogue_clears_the_world_hud.gd
PASS: nothing the world HUD draws composites through the dialogue box   (exit 0)
  grep '^ERROR:'      -> 0 lines
  grep 'SCRIPT ERROR' -> 0 lines
```

## Runtime validation

- `xvfb-run -a -s "-screen 0 640x640x24" godot --path . --rendering-driver opengl3 --resolution 640x640 --script tools/_capture_portraits.gd` → `34 plates written, 0 failures`; each plate's opaque-pixel share printed and guarded to 15–95 %.
- `godot --headless --path . --import` after the render (the `.import` files are committed).
- `xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/_capture_portraits.gd -- --ingame` → real Meadows boot, player stood in front of Halda (`tournament_halda`) and Oskar (`village_oskar`), the world's own `DialoguePanel` opened through `start()`, two frames, `0 failures`. Boot log `^ERROR:` set: one line, `Condition "status < 0" … ERR_CANT_OPEN` from ALSA (no sound card in the container) — known-benign, no growth.

## Visual evidence and blind judge

Three code-blind rounds, each given only the sheets, the two shipping painted
plates, `docs/reference/` and the visual-judge skill. Verdicts committed as
`JUDGE_VERDICT_round1.md`, `JUDGE_VERDICT_round2.md`, `JUDGE_VERDICT.md`.

**The acceptance criterion passed in every round.** Round 3, unprompted: Oskar
*"yes, unambiguously"*; Halda *"yes ... she is clearly not the player"*.

**Round 1** found an evidence defect, not an art defect. The contact sheet
committed in `97b5c459` was a stale 6-cell partial from an earlier framing
round, because `_write_sheet()` only sheets what the current run rendered. The
judge was looking at 4 plates believing it was 34, and said so as its headline.
Fixed by re-rendering every plate in one pass so plates and sheet come from the
same run. Its other actionable finding, that the player model dominated both
in-game frames, was fixed by widening the evidence camera.

**Round 2** measured the plates against the two shipping ones and found three
real defects, all mine, all fixed:

| Finding | Measured before | After |
|---|---|---|
| Ground mismatch: shipping plates are opaque on (242,242,242), mine were transparent cut-outs, so villagers floated on the dark panel while Grandpa drew as a white card | alpha 100% opaque vs ~50% clear | every plate composited onto the exact shipping ground. Round 3: *"exact match, no complaint ... Nothing to fix here."* |
| Wrong lens: the window was scaled by body height, so short bodies got a tighter crop | coverage 46–69% (shipping: 51%, 55%) | one fixed window, camera auto-steps back when a subject will not fit. Coverage 41–60% |
| Blown-out skin | worst plate clipped 10.5% of itself to flat white (shipping: 0.2%, 0.6%) | worst 0.9%, via per-character exposure that scales the whole rig at once |

Also fixed in that round: framing centred on the head rather than the body's
bounding box, so a carried prop no longer enters the frame edge-on; and the
render now measures what the judge measured and fails the run on it (coverage
band, clipped-to-white fraction, content reaching the top or upper sides).
Final render: **34 plates, 0 failures.**

**Round 3** confirmed the ground and the identity, and found one thing I could
still fix and did not get to ship — see the ceiling below.

## The ceiling, measured

The heads are smaller than the two shipping plates. Skull width at 256 px,
my own measurement (the judge measured the same gap independently):

| Plate | Skull width |
|---|---|
| `trainer.png` (shipping) | 140 px |
| `grandpa.png` (shipping) | 160 px |
| `halda.png` | 113 px |
| `villager_male.png` | 119 px |
| `warden.png` | 79 px |

So a typical villager reads ~20% narrower, and the Warden half — his crown
raises the measured top the window hangs from, so his face sits low and small.
The judge called it *"a low-grade irritation, visible only when a villager plate
follows trainer/grandpa in the same conversation"*, with the outliers worse.

The fix is one constant: `WINDOW_HEIGHT` 0.66 → ~0.51, which is safe only
because the auto-fit steps back for the bodies that then would not fit. **That
render was started and interrupted partway (19 of 34 plates), so the branch
ships the round-3 plates rather than a half-rendered mix.** The tool is
unchanged at 0.66 so it still reproduces exactly what is committed. The next
lane to touch this changes that one number, re-runs the render, and re-measures
skull width against 140/160.

## Known limitations and what was deliberately not done

1. **Head size, above.** One constant, one render, not shipped.
2. **Female-rig villagers share one face** (Mira, Tam, Halda, Rae, Doss, Sela,
   Dara, Nan). Probed in-engine: the tint applies only to `hair_ponytail`, which
   sits at the nape behind the head and is invisible from the front, in the
   world as well as the plate. Two judges counted the repeats unprompted. D81; a
   rig/texture task. The per-NPC file names are kept so a fix there re-renders
   into the right names with no dialogue edit.
3. **A texture artefact on the shared rigs** — a pale wedge on the right cheek,
   dark lines on the neck. It is in the body texture, not the plate: round 3
   found it on the standing NPC, on the player, and on the plate, and used the
   match as proof of identity. Not introduced here, not fixable here.
4. **Engine renders next to paintings.** The plates now match the shipping ones
   on ground, framing band and exposure, but a render is not a painting: no
   catchlight in the eye, softer hair edges. Closing that means repainting, which
   is owner-gated art. Running the tool with `-- trainer grandpa` writes rig
   versions of those two into `shots/` for comparison, never over the files.
5. **The generic trainer refusals** wear `villager_male.png` because
   `trainer_npc.gd` does not pass the speaker's portrait through. Passing it is a
   small code change outside this lane's ownership. D81.
6. `data/dialogue/stronghold.json` (8 fields) still names `trainer.png` — other
   lane, by design. Note for the coordinator: **main has since added a ninth**
   (commit `04d844d0` added a conversation naming `trainer.png`), so that lane's
   job grew. My test carves stronghold ids out of the not-the-player rule until
   it lands; delete `STRONGHOLD_PATH` and the two `_is_exempt` calls then.
7. `docs/GATE2_GATE3_CLOSURE_PLAN.md`'s CL-G11 row still reads "proven failing
   (owner)" — outside this lane's ownership, coordinator to flip on landing.
8. Everything the judges raised about the world around the box — the hero tree's
   canopy, floating grey blocks, the quest tracker covering a signboard, grass
   scatter, the conversation camera never framing both speakers — is other lanes'
   and is recorded here only so it is not lost.

## CI

`ralph/W04-PORTRAITS-0904` run 33920901460 (head `5a8b2d7f`): the four red jobs
are all inherited from `main`, none from this lane. `verify-unit-tests (1)` is
the known candy/mushroom icon failure another lane owns plus the scatter-bake
freshness assertion; `verify-unit-tests (2)`, `verify-terrain-bake-freshness`
and `verify-scatter-bake-freshness` are the terrain/scatter bake staleness.
Confirmed not mine two ways: `git diff origin/main -- data/config data/terrain
data/scatter scripts/world` is empty, and both freshness tests fail identically
on a clean checkout of my branch and on `main`'s own run 33932088359.

## Commits

| Commit | What |
|---|---|
| `97b5c459` | The plates, the re-point, the test, the capture tool |
| `5a8b2d7f` | In-game evidence mode, D81, the `CURRENT_STATE` row |
| `f26681ec` | Re-render all 34 in one pass, fix the stale contact sheet |
| `f26681ec`+ | One lens, the shipping ground, clean framing (judge round 2) |

| `5ea816e6` | This report, the round-3 verdict, the D81 findings |

**Branch:** `ralph/W04-PORTRAITS-0904`, pushed to `origin`.
**Final commit:** `5ea816e6`.
