# GPU RUN request: F04#6 aftermath frames (three Sigil captains and the Warden)

This file is for the coordinator. It is not posted anywhere. It holds two render requests:

- **RUN A** covers the three captains. It is a fresh seed-15 new game through the Hall.
- **RUN B** covers the Warden. It resumes from the committed `seed4_hall` fixture and runs the M4
  finale.

A fresh-to-Cloudreach render run would need about 95 min headless before any rendering slowdown.
That is too close to render.yml's 150-minute cap, so the work is split. CI render r37 (run
36316607256) ran the same fresh seed-15 walk through the Hall in 4203 s (70 min).

## How the capture works

The capture is opt-in: `--aftermath-capture`, implemented in
`tests/helpers/meadows_earned_fight_log_segment.gd` and wired from
`tests/smoke_four_biome_continuous.gd`.

- It saves one viewport PNG 0.75 s after each target trainer battle resolves. A battle resolves when
  `EncounterDirector.trainer_battle_id()` turns empty.
- Output: `user://aftermath/<fight>-a<attempt>.png`, with a sidecar
  `user://aftermath/<fight>-a<attempt>.json`. The sidecar records the positions of the player, the
  ally creature and the defeated trainer, and for each one `visible`, `in_frustum` and camera
  distance.
- It needs a real renderer. Under `--headless` it only records `"capture": "skipped_headless"`.
- It implies `--fight-log`, so the run also prints `FIGHT LOG {json}` per fight and a
  `FIGHT LOG SUMMARY` line.

The render.yml workflow supports this: `mode: render` runs xvfb with `--rendering-driver opengl3`
at `resolution`. The run's `user://` directory (`$XDG_DATA_HOME`) is uploaded in the
`render-<label>-<run_id>` artifact. The PNGs are in that artifact under
`userdata/godot/app_userdata/Tetherbound/aftermath/`. `mode: headless` cannot produce the frames.

## RUN A: the three Sigil captains

| Input | Value |
|---|---|
| workflow | `render.yml` (workflow_dispatch from `main`) |
| checkout_ref | the `tb/meadows-route` commit SHA that holds this file (see the README) |
| script | `tests/smoke_four_biome_continuous.gd` |
| args | `--world-seed=15 --through-hall --route-ledger --fight-log --aftermath-capture` |
| mode | `render` |
| resolution | `1280x720` |
| timeout_minutes | `150` |
| label | `meadows-captains-aftermath` |

Notes:

- This is a fresh new game with no shortcut before the captains. It is the same walk as CI r37,
  plus the observer.
- The Hall stage walks the band5 spine to Oreth, Halder and Vess, then the Sigil Gate and the Hall
  gauntlet. The run then stops at `--through-hall`.
- Expected frames: `captain_riverwatch-a1.png`, `captain_field-a1.png` and `captain_ridge-a1.png`.
- If the run times out before the captains, it failed. Report it as that, not as a missing frame.
- If the relay fails with "Physical Interact activated a different provider than the exact offered
  target" and names the same path and id, that is the harness flake described in
  `SHARED-FILE-REQUEST-relay-late-activation.patch`. It is not a capture problem.

## RUN B: Warden Aldis

| Input | Value |
|---|---|
| workflow | `render.yml` |
| checkout_ref | the same SHA |
| script | `tests/smoke_four_biome_continuous.gd` |
| args | `--world-seed=4 --resume-from=seed4_hall --m4-finale --through-meadows --fight-log --aftermath-capture` |
| mode | `render` |
| resolution | `1280x720` |
| timeout_minutes | `120` |
| label | `meadows-warden-aftermath` |

Notes:

- The resume is a declared shortcut: the committed chapter-boundary fixture
  `tests/fixtures/earned_saves/checkpoints/seed4_hall` (M4 passed 19/19 from it headless in about
  17 min). `--world-seed=4` pins the fixture's seed, the same way `TB_WORLD_SEED=4` does in the M4
  README.
- Expected frame: `warden_aldis-a1.png`. The finale then continues through the Veridian branches and
  the Rift. Those are not part of this capture.

## What every frame must show

Judge each PNG against its row, and use the sidecar JSON to settle what is in frame. A frame FAILS
F04#6 if any required item is missing. That includes the black or blank frame the renderer draws
before the first real frame.

| Frame | Named fight | Arena (must be recognisable) | Bodies that must be visible | Aftermath state/VFX that must be visible |
|---|---|---|---|---|
| `captain_riverwatch-a1.png` | Captain Oreth, `captain_riverwatch` (Mosshell13 → Trailpup14 → Brooktail15). First Sigil | Oreth's junction on the Upper Meadows band5 spine road: open pasture and road, daylight or dusk. It must not be the Hall interior | The player's trainer (1.80 m human) and the player's deployed creature, which is taller than the trainer and standing, not fainted. Oreth in frame and upright | Oreth's defeated/yield read: the defeated clip, not an idle stance. No enemy creature on the field. HUD combat UI gone or closing. A Sigil award toast or dialogue if one is showing at +0.75 s. No red/oxblood except Team Tether marks |
| `captain_field-a1.png` | Captain Halder, `captain_field` (Duskhush13 → Tuskroot14 → Meadowhart15). Second Sigil | Halder's exposed field junction on the spine (BOSSES §4.3: "an exposed field"). Readably different ground or layout from Oreth's | As above: trainer, player's creature standing, Halder in frame | Halder's defeated read. No enemy creature. It must read as distinct from Oreth's frame: different place and different captain, not the same composition |
| `captain_ridge-a1.png` | Captain Vess, `captain_ridge` (Trailpup14 → Duskhush15 → Galecrest16 DIVER). Third Sigil | Vess's ridge junction: higher ground, ridge or old growth near the Sigil Gate approach | As above: trainer, player's creature standing, Vess in frame | Vess's defeated read. No enemy creature. Distinct from the other two captains' frames |
| `warden_aldis-a1.png` | Warden Aldis, `warden_aldis` (Burrowback18 → Galecrest18 → Brooktail19 → Meadowhart19 → Tuskroot20 ACE) | The Warden arena inside the Hall of Tethers: stone chamber, arena marker area, the chamber-five shutter wall in view | Trainer, player's creature standing, Aldis in frame | Aldis's defeated read. No enemy creature. The legendary-chamber blast shutter opening or open (`defeated_warden`; the M4 run saw it open within 120 frames), or the post-victory dialogue starting. It must read as a larger, final aftermath than any captain's frame |

For every frame:

- 1280x720, a rendered frame from the game camera and not the debug view, with nothing
  harness-drawn over it.
- The sidecar's `player.in_frustum`, `ally.in_frustum` and `trainer.in_frustum` should all be
  `true`. If any is `false`, the frame fails the "creature and trainer visible" line, whatever the
  image looks like.
- The creature is taller than the trainer (hard rule). A creature scaled below the human fails.

## What the coordinator should post back

- The artifact name, and the four PNG plus JSON pairs.
- For each frame, pass or fail against its row above, with the failing item named.
- The `FIGHT LOG SUMMARY` line from each run's `run.log`, as the rendered hit/avoidance counterpart
  to the headless F04#4 log in this directory.
