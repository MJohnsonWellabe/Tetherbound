# Creature preview framing and exposure (X03-WO2; unblocks F14 Guardian-offer visual verdict)

`tools/capture_creature_preview.gd`, 1280x720, opengl3 under xvfb. The production
`creature_viewport.gd` widget inside the real pause-menu Creatures tab.

- `before/`: main fe07d0d2's widget. `after/`: ralph/ui-creature-preview.
  `<species>.jpg` is the widget cropped 1:1; `tab_<species>.jpg` is the whole window.
- `before_after_sheet.jpg`: before (black) / after (slate) pairs for the five
  starters/companions shown (Terrapup, Ripplet, Galewisp, Bramblebun, Mudsnout,
  Mosshell) plus the Abyssal Guardian, Solmane, Fulgocobra and Tidecoil (the
  largest bodies by bounds).
- `spin/` + `spin_sheet_after_*.jpg`: the idle turntable sampled at 1 fps for
  32 s on the Abyssal Guardian and Mosshell; `spin_sheet_before_*` the same
  on main.

Staging (from the tool header): no world scene; the party is cleared and
refilled with one creature of the species under test; the widget's own
`_process` is off so the angle is deterministic, and the spin sequence
advances the turntable by IDLE_SPIN_SPEED x 1 s per frame.

Known trade-off: the fit reserves the full spin radius inside a narrow
portrait widget, so long bodies (Guardian, Solmane, Tidecoil) sit small.
