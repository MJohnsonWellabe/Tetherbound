F32 criterion #1 - "The Forge refines Rootiron, Tidesteel, Skyglass and Stormglass plate."
Proof: tests/smoke_f32_forge_plates.gd (engine smoke, SceneTree)
Engine: Godot 4.7.stable.official.5b4e0cb0f, headless, project already imported.
Date: 2026-10-04

Command
  godot --headless --path . --script tests/smoke_f32_forge_plates.gd
  -> exit 0

Path exercised (production code, no direct rule calls)
  paid Forge placement via build_place input (homestead_building_delivery journal)
  -> StationPiece mounts ManualForge (scripts/build/station_forge.gd)
  -> Forge panel "Refine <name>" button (scripts/ui/craft_panel.gd _start_refining)
  -> Session.homestead_start_refining -> _foundation_send/_foundation_handle "refine_start"
  -> ForgeHost.start (scripts/net/foundation_forge.gd) -> station_forge.start_refining
  -> physics-time present channel (1.5 s/unit) -> ForgeHost.commit_unit
  -> FoundationActions.commit "station_craft" -> station_actions.stage_craft with
     homestead_refining.transaction_recipe -> owner journal, save and ACK.
  Note: scripts/world/f32_source_actions.gd `_refine` (op "refine") is NOT on this
  path; no production caller stages op "refine" (foundation_actions only routes
  "node"/"farm" via resource_plan and "groom"). The Forge path uses station_craft.

Fixtures (disclosed in the test header)
  isolated user:// save root; new game, one Terrapup, opening:beat:free_play flag,
  fixed character/world ids; trainer placed at the F31 smoke's homestead yard
  stance and then 1.2 m from the Forge interaction origin; Forge build price and
  each recipe's inputs (cost + 1 spare per input) added to the local inventory;
  one pre-refine owner/world save per recipe as the disk baseline. No recipe
  eligibility or flags are granted beyond that.

Assertions per recipe (all read from decoded on-disk saves, save_document.parse)
  exact input debit (and exactly 1 spare left), exact +1 output, world journal row
  action station_craft status accepted with receipt craft:<character>:<craft_id>,
  saved character has exactly one new matching receipt, unit took >= the
  configured 1.5 s channel, unit_completed fired exactly once for that recipe.

Trimmed output
  F32 FORGE PASS: production Game autoload exists
  F32 FORGE PASS: request actual Meadows scene
  F32 FORGE PASS: Meadows build completed
  F32 FORGE PASS: player and BuildPlacer exist
  F32 FORGE PASS: paid Forge placed through build_place (b1)
  F32 FORGE PASS: StationPiece mounted the production ManualForge actor
  F32 FORGE PASS: rootiron_ingot pre-refine fixture saved to isolated disk
  F32 FORGE PASS: rootiron_ingot Forge panel offers its Refine button
  F32 FORGE PASS: rootiron_ingot tap started one present channel (stops: [])
  F32 FORGE PASS: rootiron_ingot channel completed one canonical unit after 1.52s (completed [["rootiron_ingot", 1]], stops [])
  F32 FORGE PASS: rootiron_ingot unit waited the configured present-channel time
  F32 FORGE PASS: rootiron_ingot debited exactly 2 rootstone on disk (delta -2, left 1)
  F32 FORGE PASS: rootiron_ingot debited exactly 1 ironwood on disk (delta -1, left 1)
  F32 FORGE PASS: rootiron_ingot yielded exactly 1 rootiron_ingot on disk (delta 1)
  F32 FORGE PASS: rootiron_ingot saved world journal row accepted with receipt craft:f32-forge-owner:c467ff2de4487286fbc92819715522b7
  F32 FORGE PASS: rootiron_ingot saved character holds exactly one new receipt
  F32 FORGE UNIT rootiron_ingot: debits { "rootstone": -2, "ironwood": -1 }, +1 rootiron_ingot, receipt craft:f32-forge-owner:c467ff2de4487286fbc92819715522b7
  F32 FORGE PASS: tidesteel_ingot pre-refine fixture saved to isolated disk
  F32 FORGE PASS: tidesteel_ingot Forge panel offers its Refine button
  F32 FORGE PASS: tidesteel_ingot tap started one present channel (stops: [])
  F32 FORGE PASS: tidesteel_ingot channel completed one canonical unit after 1.53s (completed [["tidesteel_ingot", 1]], stops [])
  F32 FORGE PASS: tidesteel_ingot unit waited the configured present-channel time
  F32 FORGE PASS: tidesteel_ingot debited exactly 2 sluice_metal on disk (delta -2, left 1)
  F32 FORGE PASS: tidesteel_ingot debited exactly 1 reef_stone on disk (delta -1, left 1)
  F32 FORGE PASS: tidesteel_ingot yielded exactly 1 tidesteel_ingot on disk (delta 1)
  F32 FORGE PASS: tidesteel_ingot saved world journal row accepted with receipt craft:f32-forge-owner:acebc2570fe271896b4144100de59a86
  F32 FORGE PASS: tidesteel_ingot saved character holds exactly one new receipt
  F32 FORGE UNIT tidesteel_ingot: debits { "sluice_metal": -2, "reef_stone": -1 }, +1 tidesteel_ingot, receipt craft:f32-forge-owner:acebc2570fe271896b4144100de59a86
  F32 FORGE PASS: skyglass_ingot pre-refine fixture saved to isolated disk
  F32 FORGE PASS: skyglass_ingot Forge panel offers its Refine button
  F32 FORGE PASS: skyglass_ingot tap started one present channel (stops: [])
  F32 FORGE PASS: skyglass_ingot channel completed one canonical unit after 1.53s (completed [["skyglass_ingot", 1]], stops [])
  F32 FORGE PASS: skyglass_ingot unit waited the configured present-channel time
  F32 FORGE PASS: skyglass_ingot debited exactly 2 cliffglass_ore on disk (delta -2, left 1)
  F32 FORGE PASS: skyglass_ingot debited exactly 1 windworn_heartwood on disk (delta -1, left 1)
  F32 FORGE PASS: skyglass_ingot yielded exactly 1 skyglass_ingot on disk (delta 1)
  F32 FORGE PASS: skyglass_ingot saved world journal row accepted with receipt craft:f32-forge-owner:a1a51f1dba620170f9a1750cb791292e
  F32 FORGE PASS: skyglass_ingot saved character holds exactly one new receipt
  F32 FORGE UNIT skyglass_ingot: debits { "cliffglass_ore": -2, "windworn_heartwood": -1 }, +1 skyglass_ingot, receipt craft:f32-forge-owner:a1a51f1dba620170f9a1750cb791292e
  F32 FORGE PASS: stormglass_plate pre-refine fixture saved to isolated disk
  F32 FORGE PASS: stormglass_plate Forge panel offers its Refine button
  F32 FORGE PASS: stormglass_plate tap started one present channel (stops: [])
  F32 FORGE PASS: stormglass_plate channel completed one canonical unit after 1.53s (completed [["stormglass_plate", 1]], stops [])
  F32 FORGE PASS: stormglass_plate unit waited the configured present-channel time
  F32 FORGE PASS: stormglass_plate debited exactly 2 stormglass on disk (delta -2, left 1)
  F32 FORGE PASS: stormglass_plate debited exactly 1 thunderwood on disk (delta -1, left 1)
  F32 FORGE PASS: stormglass_plate yielded exactly 1 stormglass_plate on disk (delta 1)
  F32 FORGE PASS: stormglass_plate saved world journal row accepted with receipt craft:f32-forge-owner:de89088d8c94adafd60e8c36bfc4bd87
  F32 FORGE PASS: stormglass_plate saved character holds exactly one new receipt
  F32 FORGE UNIT stormglass_plate: debits { "stormglass": -2, "thunderwood": -1 }, +1 stormglass_plate, receipt craft:f32-forge-owner:de89088d8c94adafd60e8c36bfc4bd87
  F32 forge plates smoke passed

Verdict: PASS. All four refined outputs (rootiron_ingot, tidesteel_ingot,
skyglass_ingot, stormglass_plate) are produced by the actual mounted host Forge
with exact debits/yields and an accepted, saved receipt. Scope limits: local host
only (no ENet guest), single unit per recipe (multi-unit channels not exercised),
not an earned-campaign route (inputs are seeded).
