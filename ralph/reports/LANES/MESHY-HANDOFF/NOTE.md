# LANE-MESHY handoff (11 Nov 2026): context is long; start a fresh session from here

## State
- Landed or landing: giant_trees_1110 + timber_1110 (batch 51, PR #897); Hollows +1.09.
- READY now: tb/item-skyroad-stand a66d2bd8. The arch stand is moved onto the crown (357, 1933), requires_traversal false,
  test updated (21 tests, 0 failed). This unblocks the 32 F40#0 arch frames.
- Open arm, proof pending: tb/item-nerissa-room e03c8bf5, F39#21 `victory_light_1110` (OFF): a key light and an aqua rim
  light over Nerissa's ring, plus the crystal `ice_fresnel` (heart_crystal.gdshader). The branch is merged with main
  (the plinth is ON). It still needs the 720p CPU before/after win capture; see ITEM-NERISSA-LIGHT/NOTE.md.
- Ride-alongs, not started (ITEM-SKYROAD-STAND/NOTE.md on tb/item-hollows-trunk):
  - Stormraven is configured at height 3.4 m (species.json placeholder), about 1.9x the trainer; the "trainer height"
    read is likely perspective. Measure in-engine; grow it only if it is short.
  - The camp_tent/camp_bed frames show no "CAMP" sign; the dark red is a small bush or berry prop by the fire. Identify it
    and check its config for an owner note before recolouring.

## Queue (coordinator 11 Nov 18:31), in order
1. New art for rows still below 6:
   - F41#8: the Stormwood trio (Maud, Hesk, Bryn) all share local_historian (frames: gpu-frames-1108/G-f41-8-hesk-cap;
     tiny stooped figures). First lever: a distinct installed body each (assets/characters has 40: innkeeper, inn_helper,
     craftsperson, field_researcher, warden, villager_female, ...). That honours "reuse installed humanoid cast".
     Wired through character_appearance_variants.json / character_body_flags.json.
   - F40#3 Cloudreach landmark art (no aviary dome, arcades or bridges).
   - F41#1 Stormheart crown and glowing core.
   - F40#1 a real landform at the Realm Gate Crag approach.
   - F36#29 innkeeper body.
2. An authored faint pose for Aquaryn (the raised forelimb lies on the sand, no clipping): closes F39#6.
3. A real Trail Camp campfire (logs, embers, layered flame, smoke, light pool): F38#32.
Rules: drafted reference, scale check, provenance, flag-off until GPU-judged, red only for Team Tether, creatures
taller than the trainer. Each goes out as ARM.md + CAPTURE.json under ralph/reports/LANES/MESHY-<NAME>/, at most two on the GPU.

## Runbook (what worked)
- Messages to the coordinator always fail (untrusted device); status lives in committed READY/ARM/NOTE files.
- One Godot process at a time. Overlay arms with $S/apply_overlay.py (deep merge) and restore from a snapshot taken
  AFTER your edits. Never commit an overlaid config; stage from a clean snapshot (git hash-object + update-index) if needed.
- Fights: --fixed-fps 20, which makes them deterministic. Long CPU sims: set RenderingServer.render_loop_enabled=false (as the
  named-fight tool does); this sped the Fly probe up about 50x.
- Fresh capture output folder every run (the tools refuse reused ones). Never commit per-frame PNGs; one _sheet*.jpg under 1.5 MB.
- Diagnose with runtime probes (temporary subclasses under tools/_probe/, excluded in .git/info/exclude); do not commit them.
- Lookdev/F38/F40 tools need --low-resolution=1280x720 and --source-commit=<40-hex sha> on CPU.
- Disk is tight (about 2 GB free). A second git worktree does not fit; switch branches in place. Do not sweep /tmp (refused).
- Tests: godot --headless --path . --script tests/run_tests.gd -- --only=<substr,...>; run with arms ON as shipped,
  and write tests that check enabled and disabled copies.
