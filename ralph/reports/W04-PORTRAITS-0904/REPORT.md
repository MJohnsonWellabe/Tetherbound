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
| `docs/decisions/D74-…md` (new) | The three bodiless speakers and the female-rig hair finding. |
| `docs/CURRENT_STATE.md` | One new §3 row (P2, struck through, fixed on this branch). |
| `ralph/reports/W04-PORTRAITS-0904/` | `_sheet_portraits.png` (34 plates), `_sheet_ingame_conversations.png` (two 1280×800 frames), `JUDGE_VERDICT.md`, `repoint_portraits.py`, this report. |

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
| Coll (Broken Cart; no body placed) | — | `villager_male.png` (D74) |
| "Trainer" (generic refusals in `trainers.json`; any trainer) | — | `villager_male.png` (D74) |
| "Team Tether Notice" (hall-approach board) | — | `grunt.png` (faction plate, D74) |
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

- `_sheet_portraits.png` — all 34 rendered plates, alphabetical, 6 per row (1536x1536).
- `_sheet_ingame_conversations.png` — Halda (top) and Oskar (bottom) at 1280x800, real
  Meadows boot, the world's own `DialoguePanel`.
- `JUDGE_VERDICT_round1.md`, `JUDGE_VERDICT.md` — two code-blind judges, each given only
  the sheets, the two painted plates, `docs/reference/` and the visual-judge skill.

**Round 1 found a real evidence defect and I fixed it.** The contact sheet committed in
`97b5c459` was **not** the 34-plate sheet: it was a stale 6-cell sheet left over from an
earlier framing round, because `_write_sheet()` only sheets what the current run rendered
and the last run before that commit was a 7-plate subset. The judge caught it as its
headline finding ("the contact sheet does not show what it claims to") and was therefore
judging 4 plates while believing it was judging 34. Every plate was then re-rendered in
one deterministic pass (`34 plates written, 0 failures`) so the plates and the sheet come
from the same run; the sheet is now 1536x1536 with 34 populated cells, and all 36 plate
files hash distinctly.

Round 1's substantive findings, and what each got:

| Finding | Verdict | Action |
|---|---|---|
| Both frames: the portrait reads as the NPC actually speaking, not the player | **the acceptance criterion, passed** | none needed |
| The player model dominates both frames; the speaker is small and part-occluded | fair | evidence camera widened and pushed off the player's shoulder for round 2 |
| Rendered plates are a different style family from the two painted plates (cel-shaded vs painterly; one eye vs frontal) | fair, and structural | recorded as a limitation, not tuned. These are engine renders of the shipped bodies; matching a painting means repainting, which is owner-gated art. See limitation 2 |
| Female-rig cells are indistinguishable from one another | correct, and already independently measured | D74. The rig's only differentiator is a nape ponytail invisible from the front |
| A jagged pale mark on the female rig's right cheek and dark lines on the neck | correct, and it is in the body texture, not the plate | it shows on the standing NPC in-world too. Recorded as a `villager_female` texture defect for the lane that owns the rig; not introduced here |
| Tree canopy crowds the HUD; grass reads as even tufts | outside this lane | left for the world/vegetation lanes |

JUDGE_ROUND2_PLACEHOLDER

## Known limitations and what was deliberately not done

1. **Female-rig villagers share one face** (Mira, Tam, Halda, Rae, Doss, Sela, Dara, Nan).
   Probed in-engine: the tint is applied, but only to `hair_ponytail`, which sits at the
   nape (y 1.36–1.55 m) behind the head; nothing forward of it is tintable. Turning the
   body to 48° did not reveal it. The plates are honest to the body, and the same is true
   in the world — spec §21's hair-colour differentiation is not being delivered by that
   rig. Recorded in D74; a rig/texture task for a lane that owns the rig. The per-NPC
   files are kept so a fix there re-renders into the right names.
2. **Plates are engine renders, the two originals are paintings.** Framing, size and
   transparency match; surface style does not fully (see the verdict). Replacing the two
   painted plates with renders for consistency is a call the coordinator can make by
   running the tool with `-- trainer grandpa` (writes to `shots/`, never over the files).
3. **The generic trainer refusals** wear `villager_male.png` because `trainer_npc.gd`
   does not pass the speaker's portrait; passing it is a small code change outside this
   lane's ownership.
4. `stronghold.json` (8 fields) still names `trainer.png` — other lane, by design.
5. The Team Tether rank plates on the default `grunt` body (`grunt`, `officer`, `captain`)
   differ only by palette; the rank badge sits on the chest below the crop.
6. `docs/GATE2_GATE3_CLOSURE_PLAN.md`'s CL-G11 row not edited (outside ownership).

## Commits

COMMITS_PLACEHOLDER
