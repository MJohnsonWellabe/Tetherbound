# VIS-STORMWOOD: READY

**Landing-ready flags: none.**

## BLOCKED: disk (4 Nov 2026)

- **Problem:** the disk allowance was used up at session start: 39 GB used, about 100 MB free.
  - The clone carries a 21.9 GB history pack (`.git/objects/pack`) and a 9.1 GB tree.
  - That leaves no room for `godot --headless --import` (the `.godot` cache) or for captures.
- **What I tried:** twice, deleting that pack and re-fetching `origin/main` at depth 1. Before trying, I checked that HEAD == `origin/main` 98879e2e1, the tree was clean, and there were no local-only branches or stashes. The session's auto-mode safety check refused both attempts as irreversible local deletion, so I did not retry.
- **Coordinator message:** a `send_message` to the coordinator was refused (`elevated_session_untrusted_device`).
- **Fix for future lanes:** start them with `create_session` `clone_depth: 1` (or `blob_limit_kb`), or the owner approves the pack refetch in this session.

## Existing flag-OFF arms per item (found on main, waiting on a CPU capture and judges)

| Item | Arm (data/config) |
|---|---|
| F41#16 P2-110 loss result | `hud.json loss_card` (ON since 12 Oct); remaining note: no loss state in the `hollows_long ... -99-after` frame |
| F41#21 P2-111 victory tiles | `hud.json victory_focus` (OFF) |
| F41#15 P2-083 dialogue obstruction | `camera.json` require_speaker_sight / speaker_sight_meshes, speaker_light_candidate, `occlusion_fade` (ON) |
| F41#3 P2-092 actor spacing | `combat.json named_overrides.hollows_alpha` (OFF); `stormwood_encounters.json hollows_alpha camera_presentation_enabled` (false) |
| F41#10 P2-070 Glass Sink | `stormwood_glass_sink.json`, `hero_landmarks_1101.json` |
| F41#19 P2-043 Glass Field | `stormwood_glass_field.json` |
| F41#9 P2-046 harvest | `stormwood_harvests.json`, `stormwood_harvest_hero2.json`, `stormwood_voltcap_finish.json` |
| F41#4 P2-038 destinations | `stormwood_lantern_pools.json` |
| F41#1 P2-037 Stormheart | `stormheart_presentation.json` (stand note: the approach stand renders from inside the trunk, CREATURES-RALPH READY) |
| F41#8 P2-055 silhouettes | `character_appearance_variants.json`, `npc_role_accessories.json` |
| F41#18 P2-056 uniforms | `stormwood_character_rim.json` (r1 ON in #808, CPU 5.58 -> 5.98; r2 OFF on tb/creatures-ralph) |
| F41#2 / F41#5 | storm-light set in #808 (CPU 5.80 / 5.84) |
| F41#22, F41#24, F22#4 | unscored; `capture_stormwood_f10_matrix.gd --phases=calm,break`, `capture_named_fights_f10_6.gd` |
