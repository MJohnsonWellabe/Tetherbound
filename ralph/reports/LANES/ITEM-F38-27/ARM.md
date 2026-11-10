ROW: F38#27 settings and binding instructions ("dense gray-on-navy control instructions and literal key labels make settings and quick binding text hard to scan")
BRANCH: tb/item-f38-27-glyphs
HEAD: 750c292a9ffb07da2efb6b71280bf8c651096afe (code change; no overlay; base is origin/main)
FRAMES: CAPTURE.json (meadows__settings_controls, meadows__quick_bindings)
Change: the scenic menu footer drew its keyboard tab keys as literal text
("[Q]", "[Tab]") beside image glyphs for every other action.
- input_glyph.gd gains key_glyph_for_action(action, px). It draws the action's
  first key as its keycap image when keyboard_<name>.png is installed, and
  falls back to the bracketed name otherwise.
- game_menu.gd _scenic_refresh_footer uses it for previous and next tab.
- New keycap: assets/ui/input_prompts/keyboard_tab.png, drawn by
  draw_tab_key.py from the vendored Kenney escape keycap with a Tab arrow-to-bar
  symbol. No external source.
Tests: tests/test_menu_footer_key_glyphs.gd, plus all input_glyph and
game_menu tests: 176 tests, 0 failed.
Not done here: the "dense gray-on-navy" contrast and spacing of the binding
list. My notes did not pin down the layout ask, so it stays for a judged round
on these frames.


## Round 2 (10 Nov): readability arm, CPU-judged (menu only)

On the coordinator's direction, the glyph fix is folded into a bigger swing on the same branch. This is not on the GPU queue.

**Base CPU frames** (this branch with the arm OFF, Compatibility 1920x1080):
- the binding cells are dark navy on navy;
- the list panel is translucent, so the room shows through behind the rows;
- the groups run together.

**Arm:** `menu.json` `controls_scan.readability_1110` (OFF; `overlay_readability.json` turns it on), in `tab_settings.gd`:
- **Rows:** every row sits on an opaque band (#22363e / #1a2a30, alternating), with 5 px padding. The scenery no longer shows through the list.
- **Binding cells:** filled, bordered buttons (#24404a, 1 px #4e7480 border), 60 px tall, with near-white 30 px text (TEXT_PRIMARY in place of #dee3d6). A changed binding keeps its amber colour.
- **Headers and notes:** column headers #d9e3e2 and group notes #d6e0df, in place of the grey secondary.
- **Groups:** an 18 px gap above each group, a 34 px group name, and an amber rule under it.
- **Kept:** the keycap glyphs from round 1.

**Trade-off visible in the frames:** the controls frame shows two full rows above the bottom fade where the base shows three.

**Checks:**
- `test_settings_controls_readability.gd`: 2/2.
- `test_controls.gd`: 30/30.
- `test_menu_footer_key_glyphs.gd` (round 1).

**Sheet:** `_sheet_readability.jpg`, left A, right B, for `settings_controls` and `quick_bindings`. For the judge, A is the base and B is the arm (the frames stay local).

**READY for judge (LANE-SCOUT, CPU).** If it gains, it ships ON by flipping `enabled`.
