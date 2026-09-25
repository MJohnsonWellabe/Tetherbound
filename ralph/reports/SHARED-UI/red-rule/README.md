# Red rule: no red/coral in friendly UI (X03, ACCEPTANCE U2)

Production captures of the release ceremony, 1280x720, `tools/capture_release.gd`
(opengl3 under xvfb), run twice on the same tree with only the two changed UI
files swapped:

- `before_*.jpg`: main fe07d0d2 (`ui_tokens.gd`, `tab_creatures.gd` as on main)
- `after_*.jpg`: ralph/ui-red-rule-b (after the blind-judge fixes: equal answer widths, larger caution glyph)
- `_sheet_release_before_after.jpg`: all four beats side by side

Staging: the capture tool's own mid-game belt (spread levels, damage, bond),
as disclosed in the tool header. No other staging.

Not covered by these frames: combat HUD low-HP/"your weakness" text, craft and
build missing-ingredient rows, capture-reticle failure burst and the minimap
death pin. They use the same `UITokens.DANGER` role, which the unit tests
pin to a non-red hue (`test_no_ui_colour_token_is_red_or_coral`,
`test_no_literal_colour_in_a_ui_script_is_red_or_coral`).
