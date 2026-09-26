# F03 lure-walk saves (gzip)

These are copies of the real ordinary-play saves under `ralph/reports/`, gzipped so that `render.yml` (whose checkout leaves out `ralph/`) can load them. The walker's receipt sha256 is of the inflated JSON, so it matches the original.

| file | source |
|---|---|
| S04-exit.json.gz | ralph/reports/gate-f-leg-s05/saves/S04-exit.json |
| S06-exit-band3.json.gz | ralph/reports/G3-BAND3-0903/gate-f-s07-v4/S06/saves/S06-exit.json |
| S07-exit-band3.json.gz | ralph/reports/G3-BAND3-0903/gate-f-s07-v4/S07/saves/S07-exit.json |
| S07-exit-band4.json.gz | ralph/reports/G3-BAND4-0903/gate-f-s08-run/saves/S07-exit.json |
| S08-exit-band4.json.gz | ralph/reports/G3-BAND4-0903/gate-f-s08-run/S08_fixed/saves/S08-exit.json |

**Derived (disclosed):** `S07-exit-band3-plus-1wood-1fiber.json.gz` is S07-exit-band3 with exactly one `wood` and one `fiber` added to the first two empty satchel slots. That is the state of a player who has gathered the materials Doss asks for. It is used only to capture Doss's repair action for F03#1; the original save has neither item, so there Doss repeats his request.
