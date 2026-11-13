# LANE-CIFIX NOTE (branch `tb/cifix`)

## Handoff, 12 Nov 2026
- **State:** done. Landed in #933 (main `1c81cdb45`). That PR's full CI was green for suite 2 (smoke_art), shard 9 (Livewire), shard 14 (shared wild fight) and every other engine job. The coordinator dispatched a full run on main to confirm the Tidewake relay, which is skipped on PRs. Causes, fixes and before/after evidence are in `READY.md` in this folder.
- **Open candidates:**
  - The Livewire smoke's 180–350 ms arrival window passed on CI. On a 4-core cloud container it passes about 2 runs in 5. If it reddens on CI, first measure the host-side delay that follows a landed charged hit: the host processed the next move_start 500–700 ms later than the client spacing implied. Do that before widening the window.
  - A visual-lane follow-up, not CI work: most creature remakes (terrapup, paddlenewt, burrowback and others) have no authored shiny or alpha repaint. Shinies use the P2-030 hue shift; alphas use rim, aura and size only.
- **What worked:**
  - Reproduce every red job locally first, then read the refusal codes in peer logs (`[encounter] … refused: <code>`), not the assertion text.
  - Each net failure had a single code underneath: `insufficient_energy` for Livewire, `pending_vitals` for shared wild fight.
  - #878 (move_start authority, charged Energy cost) is behind most of the net-smoke timing assumptions that broke.

## Runbook
- Setup: `bash tools/cloud_setup.sh`, which installs `godot` 4.7 on PATH.
- Art smoke: `godot --headless --path . --script tests/smoke_art.gd`.
- Tidewake shortcuts, the CI step: `godot --headless --path . --script tests/smoke_water_loops_shortcuts.gd -- --case=reedhaven_maintenance_ramp,shellwatch_pump_return_channel,deep_watch_current_cut` (about 5 minutes).
- Net smokes: `bash tools/net/run_net_smoke.sh <name-without-smoke_net_-prefix>`. The run directory is `/tmp/net-<name>-<stamp>/` and holds `peer-0.log` (host) and `peer-1.log`.
- CI job logs: `curl -sSL https://api.github.com/repos/MJohnsonWellabe/Tetherbound/actions/jobs/<id>/logs` works through the proxy.
- Material diagnosis: a throwaway `tests/_tmp_*.gd` SceneTree script can instance `scenes/creatures/creature.tscn` with `creature_body.gd`, call `setup(species, shiny)`, `set_alpha` or `set_tier`, and print the first surface's albedo, emission, rim and next_pass. Delete it afterwards.
- Harness additions from this lane:
  - `stormwood_hosted_fixture_energy`: a host-only step that banks Energy and refills Wind.
  - The `stormwood_hosted_trainer` probe reports `deadline_ms` as the later of the lock and the per-slot cooldown, plus `last_started_action`.
  - The `encounter` probe reports `actor_vitals_pending`.
