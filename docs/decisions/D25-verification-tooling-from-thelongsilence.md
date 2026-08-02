# D25. Verification tooling borrowed from TheLongSilence

Kind: implementation

`tools/` now holds the survey, contact sheet, hole detector and draw-cost probe,
adapted from `achimala/TheLongSilence`. That project's real contribution is not
its renderer, it is a battery of small single-purpose diagnostics that each
answer one question about the built game.

- `tools/holes.mjs` sets the clear colour to magenta and points the camera at
  the ground. Terrain is opaque, so any magenta pixel is a gap. **This is the
  check that would have caught the inside-out terrain instantly**, a bug that
  passed a typecheck, 99 unit tests and five smoke specs and was only found by a
  human squinting at a screenshot.
- `tools/sheet.mjs` tiles a survey into one labelled image. Built by rendering
  HTML and screenshotting it rather than shelling out to ffmpeg: no ffmpeg here,
  no new dependency, and the tiles get real labels and per-shot stats, which an
  ffmpeg tile filter cannot do without a freetype build.
- `--selftest` on the hole detector hides the terrain and asserts that every
  spot then reports a hole. It earned its place immediately by failing twice:
  first because `place()` streams fresh chunks in after the hide, then because
  `TimeOfDay.apply()` repaints `scene.clearColor` every tick and the frame was
  never actually magenta at capture. The detector had been passing vacuously.
- `tools/drawcost.mjs` refuses to draw a conclusion when its own data is
  incoherent. Its draw-call source (`engine._drawCalls`) accumulates instead of
  resetting per frame, so the numbers climb as resolution falls, which is
  impossible. Announcing "draw bound" from that would send the next person
  optimising the wrong half of the renderer.

Deliberately NOT borrowed: Blender MCP. Blender is not installed here, and the
skill states plainly that the addon cannot run headless, so it needs a GUI and a
human toggling a connection. It is also a hard-surface skill (lofted hulls,
greebles) and Tetherbound needs rigged organic creatures, which is a different
and harder discipline.
