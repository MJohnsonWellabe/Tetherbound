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

Framing (after): the camera fits the posed silhouette at the current turntable
angle (instant zoom-out, eased zoom-in; reduced motion keeps the whole-turn
fit). The tool steps the widget's 3 s settle before stills (header).

Remaining limit, measured: the Abyssal Guardian's geometry is 9.8 x 7.2 x
16.5 m (no stray vertices; 1st-99th percentile 15 m long), so in this
280x401 portrait widget it fills the width while its head stays small.
Readable faces for very long bodies need a wider preview in the offer layout,
not tighter fitting (next work order).
