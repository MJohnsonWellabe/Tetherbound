# Code-fix lane: Fix 2, menu text floors and clipping (GPU UI-R2)

Branch `tb/world-fix-menu-text`, from main 9996fa4a. Everything is behind one flag-off key: `data/config/menu.json` → `menu_text_floors.enabled` (default `false`). With the flag off, every tab draws exactly as before.

## What the flag turns on

**Shared helper:** `scripts/ui/menu_text_floors.gd`.

**Secondary text onto the UITokens floors** (larger authored sizes are kept):
- `tab_settings.gd`:
  - Notes, hints and column headers go to `FONT_READ` in `TEXT_SECONDARY`.
  - Row names go to `FONT_READ`.
  - Reset buttons go to `FONT_PROMPT`.
  - The gamepad legend drops the literal "(or F10)".
- `tab_skills.gd`:
  - The intro line goes to `FONT_READ` in `TEXT_SECONDARY`.
  - Skill rows go to `FONT_PROMPT`.
  - Candy buttons go to `FONT_READ`.
- `tab_backpack.gd`: the target and confirm headers go to `FONT_READ`.

**Satchel worn equipment:**
- The rows live in their own focus-following `ScrollContainer`, which takes the preview column's remaining height.
- The column is top-aligned and the preview icon is 88 px.
- All five rows show; "Backpack: Empty" is no longer cut.

**Quick-bindings "Fighting" cut:**
- Fighting carries a short `note_compact`, used instead of its five-line paragraph.
- A "More below ▼" row sits under the settings scroll. It shows only while more content remains.
- A 96 px fade over the scroll's bottom edge means a group the viewport cuts reads as continuing below, not as sliced text.
- The capture framing is unchanged. The capture still scrolls the "Quick items" heading to the top.

## Proof

**Tests:** `tests/test_menu_text_floors.gd` covers four things:
- the flag ships off;
- off keeps the authored sizes and colour;
- on lifts text to the floors in `TEXT_SECONDARY` and never shrinks larger text;
- Fighting's compact note is under half of the full one.

Run with `test_menu_data.gd` and `test_controls.gd`: **46 tests, 1227 assertions, 0 failed**.

**CPU probe:**
- Command: `phase2_capture_ui.gd --biome=water --gamepad --tabs=backpack,skills,settings`, Compatibility, 1280x720, flag off vs on.
- `_sheet_fix2.jpg` layout: top row is the Satchel (off left, on right); bottom row is quick bindings (off left, on right).
- With the flag on, all five worn rows are visible.
- Quick bindings end in the fade plus "More below ▼", with no sliced text.
- The Skills tab text is visibly larger with nothing clipped.

**Not done:** GPU judging (High first) is needed before the flag can be turned on.
