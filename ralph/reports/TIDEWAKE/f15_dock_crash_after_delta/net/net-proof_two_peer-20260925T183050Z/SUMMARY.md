# Net smoke run net-20260925T183050Z-8546

Scene: title
Peers: 2
Net conditions: clean (no proxy)

- peer 0 (host) pid=8567 exited=true unexpected_exit=false
- peer 1 (client) pid=8568 exited=true unexpected_exit=false

FAILURES:
- #26 peer 1 water_dock_state (ASSERT: crash + rejoin + retry: repair done once, the guest paid exactly once (6+4), in memory and on disk) -> PASS; data did not match {"bag":{"driftwood":2.0,"reed_fiber":2.0},"disk":{"driftwood":2.0,"reed_fiber":2.0},"done":{"reedhaven_repair":true}} -- { "character_id": "character-ddcc8093266572e16313dd55eea52321", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "dr
- #30 peer 1 water_dock_state (ASSERT final: guest paid exactly once) -> PASS; data did not match {"bag":{"driftwood":2.0,"reed_fiber":2.0},"disk":{"driftwood":2.0,"reed_fiber":2.0},"done":{"reedhaven_repair":true}} -- { "character_id": "character-ddcc8093266572e16313dd55eea52321", "done": { "reedhaven_repair": true, "shellwatch_release": false, "shellwatch_pump": false, "salt_crown_chart": false, "sluice_west_control": false, "sluice_east_control": false, "deep_watch_chart": false }, "bag": { "reed_fiber": 8, "dr
