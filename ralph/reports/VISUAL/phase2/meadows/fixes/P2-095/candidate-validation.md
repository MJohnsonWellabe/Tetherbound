# P2-095 crafting list candidate

The original full-resolution `meadows__system__crafting` frame was inspected
from `7697ca02b^:ralph/reports/VISUAL/phase2/meadows/systems/meadows__system__crafting.jpg`.
It shows two Ironwood Haft recipes truncated to indistinguishable names and
material previews ending mid-item. The temporary recovered image is not tracked.

Candidate: a 480-pixel list, 128-pixel rows with up to two lines per label, and
compact requirement summaries. Owned material counts remain in the complete
selected-recipe detail panel. Four rows are visible before scrolling. The
selected recipe name can wrap in the center column.

Scope: local presentation only. Recipes, material costs, unlocks, crafting
transactions and controller bindings are unchanged. The config switch
`data/config/craft_presentation.json::readable_recipe_rows` defaults to **false**.

Validation on Godot 4.7, Windows:

- `--headless --check-only --script scripts/ui/craft_panel.gd`: exit 0.
- `--headless --check-only --script tools/phase2_capture_build_systems.gd`: exit 0.
- `--headless --script tests/smoke_craft_panel_controller.gd -- --readable-recipe-rows`:
  exit 0; physical pad navigation, crafting, retained focus and close passed.

Independent code review found that the capture fixture assumed an explicit
`/root/CraftPanel` name which the production constructor does not assign.
Both preview activation and visibility restoration now use BuildPlacer's
actual panel reference and fail explicitly if it is unavailable. The reviewer
found no other actionable issue; that review did not render or judge the UI.

Matched production captures remain pending for Meadows, Cloudreach and
Stormwood. Append `--craft-readable-preview` to the manifest reproduction to
preview the candidate without enabling the shipping config. The fixture records
that override in its engine manifest. This is **not visually judged or fixed**;
the default must stay off until the independent before/after verdict passes.
