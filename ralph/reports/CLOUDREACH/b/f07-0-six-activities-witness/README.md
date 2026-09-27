# F07#0 six-activity witness (Cloudreach-B)

Script: `tests/smoke_cloudreach_b_f07_0_six_activities.gd` (headless). For each of the six WORLD §11 activities listed in `ralph/reports/CLOUDREACH/f07-0-six-activities/README.md` (tb/cloudreach), it records five things in the production world:

- **lure:** the prompt is enabled before the activity;
- **action:** real Interactable + interact presses, the creature-bed controller menu, and Fly legs with held Jump/descend;
- **payoff:** what the player receives, e.g. the rain cover, potions, TM, stair deck or travelers;
- **acknowledgement:** the conversation actually opened by talking to the NPC with real input;
- **saved state:** one `save_game`/`load_game`. The completion flags are scrubbed live before the load, so only the disk slot can restore them.

| Run | Result |
|---|---|
| `default-five/run-1/` (sparkit, mudsnout, bramblebun, terrapup, brooktail) | **5/6 PASS**; Cliff Circuit FAIL. Every set completion flag survives reload. |
| `with-air-cliff_circuit/run-1/` (`--with-air --only=cliff_circuit`, pipwing in place of brooktail) | Cliff Circuit PASS: Tavi → prize TM Wind Blade +1, the other two refused, ack `cloudreach_tavi_defeated`, reload kept. |

## Finding: the Cliff Circuit prize is not useful to the retained five

All three circuit TMs are air-only (`data/moves/tms.json`: `tm_wind_blade`, `tm_heavenfall` and `tm_aerial_flash` list `compatible_types: ["air"]`). With a team that has no air creature, `tm_prize_refusal` returns "None of your companions can learn that TM." for every pad, so the circuit pays nothing. That includes the earned C1 five (ripplet water, bramblebun/mudsnout×2/veridian ground). This breaks the F07#0 "retained-five-useful payoff" rule for activity 5. The fix belongs to the Cloudreach lane (prize design/data), not the witness.

## Shortcuts (disclosed, owner ruling 06:55)

- **Fixture start.** Chapter flags through Act II are written before load. This includes the lower and Windscar circuit-pair defeats and Sora's engine-truth flag.
- **Team.** Level-30 retained five with no owned flier, so Maela's loaner carries every flight.
- **Teleports.** The trainer is teleported to each prompt, trying its four sides until the production arbiter offers that prompt. Each teleport also moves Fly's safe anchor to the new spot; otherwise the production fall rule (more than 100 m below the anchor) snaps the trainer back.
- **4 Gale Fiber granted** for the shelter.
- **Tavi** is fought through the harness's mechanics-mode lethal seam, after a real challenge input.
- **Short flights.** The High Perches bell is flown to from the adjacent perch pad (a short flight). The three aerie surveys launch beside each pad, pass the authored approach point and land.
- **Clock.** Accelerated (time_scale 8), with physics still 1/60 s.
