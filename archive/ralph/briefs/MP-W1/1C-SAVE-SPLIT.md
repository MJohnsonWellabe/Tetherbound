# Lane 1.C — Save split and legacy migration (Opus; Sonnet sub-lane for the slot UI)

**Base:** the Wave 1 branch tip after lane 1.B has landed (the orchestrator names the sha when
provisioning). **Contract:** `docs/specs/MP_STATE_SEAM.md` §4, decision D100, plan row 1.C.

**Player-visible outcome.** A world and a character are separate things: Start World / Load
World and New Character / Load Character on the title screen and the menu's Save tab, with
controller-only navigation; an old save appears under "Legacy saves", opens once into one world
and one character, and the original file is never modified.

**Files you own:** `scripts/save/save_game.gd` (becomes the legacy reader and the split
migrator), new `scripts/save/world_save.gd` and `scripts/save/character_save.gd` (`RefCounted`,
never fatal on load, each with its own `VERSION := 1`), `autoload/game_state.gd` **only** the
`save_game()`/`load_game()`/`autosave_slot()` bodies and the autosave call sites (1.B left them
producing v22; you re-point them), `scripts/ui/tab_save.gd`, `scripts/ui/title_screen.gd` (slot
UI — Sonnet sub-lane), `tests/test_world_save_format.gd`, `tests/test_character_save_format.gd`,
`tests/test_legacy_slot_split_never_touches_the_original.gd`,
`tests/test_split_key_coverage_equals_v22.gd`, and your report. Nothing else.

**Deliverables.**
1. `user://worlds/<world_id>/world.json` and `user://characters/<character_id>/character.json`
   per seam §4's partition; `world.json` adds `world_id`, `display_name`, `created_at`,
   `last_played`; `character.json` adds `character_id`, `display_name`, `last_world_id`.
2. Legacy split: loading `user://saves/slot_<n>.json` writes `worlds/legacy-slot-<n>/` and
   `characters/legacy-slot-<n>/` with `migrated_from`, leaves the original byte-identical
   (assert by hashing before and after), and the title screen lists it under "Legacy saves"
   until opened once.
3. Autosave ownership: `save_world()` only if `Session.is_host()` (a stub returning `true`
   until 2.A — create `scripts/net/session_stub.gd` or a static on `Game`, your call, named in
   the report), `save_character()` always. Rest, `enter_realm`, `complete_realm_entry` and the
   180 s tick go through the same two calls.
4. Tests: the four named above, each seen red first; `test_split_key_coverage_equals_v22`
   asserts union = the v22 key set and intersection = ∅ against `save_game.gd`'s own key list.
5. Smokes, sequential, exit 0 on first attempt: `smoke_save_persistence`, `smoke_title_new_game`,
   `smoke_title_load_game`, `smoke_finale_persistence`, `smoke_stronghold_reload`,
   `smoke_cloudreach_persistence_tail`, `smoke_clock_survives_a_reload`, `smoke_home_sleep`,
   `smoke_menu`, `smoke_playground` (ERROR set unchanged). Then the unit suite subset
   `--only=save,character,world_save,legacy,characterize`.

**Traps.** `tab_save.gd`'s header still says slot 1 is the autosave; `AUTOSAVE_SLOT := 0` is
the truth. `smoke_title_new_game` fails when an earlier smoke left `user://saves/slot_0.json`
(returning-player prompt) — private `XDG_DATA_HOME`. `enter_realm()` saves **before** the scene
swap and clears `saved_player_pose` deliberately; keep that order.
