# Meadows catalogue survey — retained attempts and handoff

Status: capture incomplete. No frame set in this report is accepted as Meadows audit
coverage and no visual judgement has been performed.

## Required coverage

`tools/catalogue_survey_validate.ps1 -Biome meadows` validates 10 Settings catalogue
destinations and enumerates 20 stable day/night frame IDs. The required bands are Lower
Meadows, Stone & Root, River Lock, Upper Meadows/Ironwood, and Stronghold Approach.

## Retained attempts

- `shots/catalogue/meadows/round-20260909-b/manifest.json`: 20 planned, zero captured.
  A concurrent unauthorized full-world Cloudreach process exhausted the roughly 8 GB
  machine while Meadows waited for Terrain3D. Windows recorded Godot `0xc0000005` and
  the Codex host also crashed. The isolated Godot log ended in the minimap rebuild and
  the boot log ended waiting for Terrain3DData. This is an external host/resource
  interruption, not evidence of a Meadows world defect.
- `shots/catalogue/meadows/round-20260909-c/manifest.json`: 20 PNGs were written after
  exclusive RAM/render access was restored, but post-run identity inspection found all
  actual player/camera X coordinates equal to zero. Authored X values include Village
  `6`, Quarry `403`, Warrens `-357`, Relay `350`, and Ironwood `-345`. The images therefore
  do not show the exact catalogue destinations and must not enter the audit/contact
  sheets. Their trainer and ordinary gameplay HUD are visible, which verifies only the
  capture composition mechanism.

The harness incorrectly treated the authored `Array[float]` position as a string. The
first attempt rejected the resulting string form; removing that validation hid the
schema mistake, and the replacement cast read the leading `[` as zero. This was a tool
defect, not an engine numeric-parsing quirk. Per prompt 78's two no-yield rule, this lane
stopped instead of starting a third capture. The harness now requires an actual
two-element numeric array, rejects non-finite values, and casts the array elements
directly. `tools/catalogue_survey_plan_check.gd` checks all 58 canonical coordinates
without loading a world. The correction has not been render-verified.

## Next exact action

After acquiring the exclusive render/RAM lease, run a new unique output directory and
verify the first manifest row's requested and actual X/Z before allowing the remaining
19 shutters. Inspect each named place; add disclosed supplemental camera views where the
trainer or authored destination is occluded. Do not use either retained attempt as
campaign/progression evidence or as blind-judge input.
