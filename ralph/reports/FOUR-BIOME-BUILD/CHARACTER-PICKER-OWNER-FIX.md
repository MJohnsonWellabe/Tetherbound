# Owner-requested character picker

The original 1280×800 production capture overflowed beyond the viewport:
long character taglines forced the horizontal container wider than the title
panel, and the original option lacked a portrait/name. Evidence retained at
`.artifacts/wave6-picker-before.png`.

The four choices now appear as compact clickable portrait/name cards:
Arlo, Lyra, Kael and Sera. Arlo names the original character; `trainer` remains
its unchanged persisted/network/body ID. All artwork is installed: trainer.png
and profile atlas crops of existing Lyra/Kael/Sera images. No generated artwork,
new meshes or import changes. No character stats or start/save behavior changed.

The picker expands the title panel to fit its cards. The duplicate character
container was removed. A gold focus outline, explicit left/right wrap and
Down-to-Back navigation support controller use; each card has an accessible
name and the stable `character_id` metadata on its actual Button. The existing
callback remains the sole selection path for solo, host and join.

Validation:
- One changed production capture: `.artifacts/wave6-picker-after.png`, 1280×800.
- Code-blind visual review PASS: all four portraits/names visible, gold focus
  clear, Back/controller hints readable; no blocking clipping or ambiguity.
- Actual UI joypad presses selected trainer/lyra/kael/sera in order; keyboard
  Right+Enter selected Lyra; controller Back restored Start New Game focus.
  Every card was inside the logical viewport. Log
  `.artifacts/wave6-picker-functional-final-console.log`, exit 0.
- Existing title/reset/save/body checks plus portrait/name contracts passed
  4 tests / 55 assertions (`.artifacts/wave6-picker-final-tests-*`).
- No engine errors in the final capture, unit or physical-input checks.

All runs used isolated APPDATA and instantiated only the lightweight title,
not terrain or a full gameplay world. The initial diagnostic layout assertion
mistook 1280 physical pixels for the 1920 logical stretched viewport; it was
corrected to inspect the viewport's actual rectangle, with the earlier log
retained. That diagnostic failure was not a production input failure.
