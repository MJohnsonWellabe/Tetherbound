# Cloudreach look lane (tb/cloudreach-look): running result

## Handoff (state), 31 Oct 2026: STOPPED by coordinator (owner usage stop)

**State**
- Flag-off grounding pass: `scripts/world/cloudreach_grounding.gd` runs last in `cloudreach_look.gd::dress`, with config in `data/config/cloudreach_grounding.json` (`enabled: false`).
  - Preview it with `--cloudreach-grounding-candidate`. `--cloudreach-grounding-report` logs every upright CylinderMesh it measured.
  - It seats a floating foot with a flared skirt in the piece's own material, plus installed Rock_Medium pieces around big drums. Visual only: no collider, surface or route change.
- The probe was revised after the first report: it now starts inside the piece's body, so a sunk foot no longer reads as void. It also skips thin decals (height < 0.3 m), collars and the summit arena (GPU lane). The revision is **not yet compile-checked or run**.
- Baseline capture `base1` was stopped after 3 frames, so no frames were judged and no arm is ready. Nothing has been sent to the GPU.

**Floaters found by the first report (main, flag off)**
- RealmGateCrag `ArrivalBeaconPlinth01/02` (r 1.84 m, h 2.08 m): their bases sit **3.4 to 3.8 m above the ground**, at the arrival stand. This is the strongest match for the owner's note.
  - A data fix may beat a skirt: lower each beacon's `position` y (`cloudreach_realm_gate_crag.gd::_add_beacon`, which reads its config) to the ground. That moves the bowl, flame and light together.
- SkyShrineHeartstone `HeartstonePedestal` (r 2.9 m): gap 1.17 m.
- BattleYards `ClearBattleFloor` (r 17.8 m, h 0.8 m): a disc that overhangs a cliff edge (Senn yard: gap 1.8 m, 10 of 17 probe points over void). Look at it in a frame first.
- HighRoostPerches needles: base at 1020 with no ground found under it. This is probably a sunk foot (the old probe started below the ground); the revised probe settles it.

**Next steps**
1. Run `godot --check-only` on the revised script, re-run the report and confirm the floaters list.
2. Fix the gate beacons (data lower, or skirt) and the heartstone pedestal, then capture A/B with the identical `--subset` list: the 10 `cloudreach__landmark__*` stands, day, approach and close, with `tools/phase2_capture_locations.gd`.
3. Then the catalogue rows: P2-021/023/025 terrain, P2-105/106 cloud puffs (`_build_island_mist`, `island_roots.mist_style`), P2-053 cyan post, P2-068 NPC posts.

**Runbook:** TECHNICAL §8.1, unchanged. Godot 4.7 import took about 50 minutes in this container. To stop a capture queue, kill by PID from `ps | awk`, never `pgrep -f`/`pkill -f` with the pattern in your own command line (it kills your shell, exit 144).
