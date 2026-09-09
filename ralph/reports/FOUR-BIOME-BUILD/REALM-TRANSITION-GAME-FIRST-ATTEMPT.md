# Tiny Game lifecycle first attempt — failed fixture precondition

2026-09-09. `.artifacts/realm-transition-game-fixture-v1/` retains both raw logs and receipt. Exit 1 after 3.355825 seconds; zero engine/script errors. Eight assertions ran in the first client case, with three failures: entry result, readiness/admission sequence and actual target scene. No later case ran. Terminal process inspection found zero Godot processes.

Events were exactly `begin_client`, `duplicate_refused`, `clear_local`. The deliberately failing world saver was called zero times, confirming that a drained client cannot enter Game's host-only transition-save failure branch.

Static diagnosis: fixture setup called `change_scene_to_file(source)` then waited for `process_frame`, rather than the actual deferred scene-install completion. Game snapshots source identity before its permit await and refuses if that identity changes. The observed early return before announcement is consistent with the fixture installing its source during that permit wait; v1 did not capture the source identity, so this is a source-backed diagnosis rather than a directly logged identity comparison.

The changed fixture now waits for `SceneTree.scene_changed` and asserts the exact installed source path and realm before beginning each case. Its deliberate replacement-during-admission case likewise waits for actual replacement completion. No production logic changed for this failure. Another run awaits root's sequencing/approval. Pure integration tests remain 18 tests/91 assertions; no actual Game orchestration acceptance is claimed yet.
