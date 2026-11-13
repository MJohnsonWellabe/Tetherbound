"""Capture harness (local, never committed): keep the game's prompts on controller glyphs for the whole run.
Usage: pad_glyphs.py <worktree root>
autoload/game_state.gd picks prompt glyphs from the last real input. The fight pilots press synthetic pad buttons, so captures
normally show pad glyphs, but a mouse move or key press on this PC during a run flips them to keyboard (G-pilot-mark arm r1, 9 Nov).
This starts the flag on gamepad and stops keyboard and mouse from clearing it: the same state tools set with --gamepad.
Applied to every side of a run after CleanCrA; exits 1 if the file no longer has the expected lines."""
import os, sys

path = os.path.join(sys.argv[1], "autoload", "game_state.gd")
src = open(path, encoding="utf-8", newline="").read()
swaps = [
    ("var _last_input_was_gamepad: bool = not Input.get_connected_joypads().is_empty()",
     "var _last_input_was_gamepad: bool = true"),
    ("\t\t\t_last_input_was_gamepad = event is InputEventJoypadButton",
     "\t\t\t_last_input_was_gamepad = _last_input_was_gamepad or event is InputEventJoypadButton"),
    ("\t\tif not (event as InputEventMouseMotion).relative.is_zero_approx():\n\t\t\t_last_input_was_gamepad = false",
     "\t\tpass"),
]
for old, new in swaps:
    if old not in src and "\n" in old:
        old = old.replace("\n", "\r\n")
    n = src.count(old)
    if n != 1:
        sys.exit("PAD GLYPHS FAILED: expected 1 of %r, found %d" % (old[:60], n))
    src = src.replace(old, new)
open(path, "w", encoding="utf-8", newline="").write(src)
print("pad glyphs: game_state.gd starts on gamepad, keyboard and mouse no longer switch prompts")
