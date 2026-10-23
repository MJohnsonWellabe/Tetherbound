# Fights lane RESUME (paused 21 Oct 2026 ~15:05Z by owner: "pause on all that visual until I start remote")

All candidates are OFF on `tb/fights`. No Godot render is running. Zero criteria closed this session.

## F22#4 best scores so far (CPU llvmpipe Compatibility/Low, three code-blind judges, Bar A)
| Fight | Best | Where | Matched control |
|---|---|---|---|
| Captain Oreth (Riverwatch) | **6.40** | r5, proof SHA `13c64245a` (`F22-4-r5.md`) | 5.50 |
| Riverwatch + rigged Meshy captain | 5.73 | r8, proof SHA `e4b8a20f7` (`F22-4-r8.md`) | 4.83 |
| Captain Halder | **5.77** | r1, proof SHA `1a8472273` (`F22-4-halder-r1.md`) | 5.27 |
| Captain Vance | 4.63 | baseline, no candidate (`F22-4-others-baseline.md`) | — |
CPU-provisional bar is 6.7; nothing is parked (CPU-only evidence).

## Riverwatch r9 (set up, not captured)
- Branch carries the Camera lane's per-trainer pull-back cap and two-fighter sight-line fade (tb/camera d945c4d37 files plus its `combat_arena.gd` and `vegetation.gd`, all OFF), with this lane's side-on preference hunk kept in `combat_manager.gd`. origin/main merged at `57918b5d3`; re-import was needed after the merge (missing imports made combat admission refuse the fight: "rendered_gap required inf").
- Fresh control captured at `e2c02ef60` (local scratch only). Candidate = proof-only `699f2007a` (r8 config: r5 data flags + rigged captain `f22_hero_model_preview`, length scale 1.0, emission 0, Brooktail `body_scale` 2.3, side-on framing, current river dressing with Meshy dock/posts; plus `camera.json fight.per_trainer_enabled: true` (captain_riverwatch max_distance_m 14.0) and `foliage_camera_visibility.json line_of_sight_fade.enabled_realms: ["playground"]`). The candidate capture was stopped by the pause; restored OFF at the next commit.
- Recipe: scratchpad script logic is in the r9 commit diff (`git show 699f2007a -- data`).

## Capture-tool limits found (tools/art_pipeline/capture_named_fight.gd)
- Vess (`captain_ridge`): from the fresh fixture the dialogue completes but no fight starts (fighting=false for 900 frames); likely a road-order prerequisite.
- Dell (`relay_officer_dell`, live member 2) and Warden (`warden_aldis`, live member 4): after "fight live" the member-advance loop (`_advance_to_member`, up to 400×6 frames) ran 30+ min on CPU without output; killed both.
- Multi-trainer runs: a later trainer's frames can show the previous fight if it is still live ("signal already connected"); run one trainer per process.
- Nerissa (Tidewake), Veyra (Cloudreach), Stormwood finale: need their realm capture path, not this Meadows tool.

## Exact next steps
1. GPU pass (Medium/High) on Riverwatch: r5 (`13c64245a` data) vs control, and r9 (`699f2007a` data) vs a fresh control; three fresh judges each. r9 is the most likely to pass (captain model + camera hold + fade).
2. Halder on GPU with r1 data (`1a8472273`); keep the lane colour high-contrast (judges: soft amber vanishes on grass, solid amber at body_scale ≥1.6 reads as a stubby pad).
3. Vance r1: Vance-only copies of `charger_rush`/`charger_double_rush` carrying the cue hooks (crimson solid lane, stone-dust burst, warm aura) and Tuskroot ace `body_scale` 1.4 (planned, not run).
4. Smallest capture fixes when reached: Vess prerequisite fixture; a shorter/faster member advance for Dell/Warden.
5. F22#4 also needs C2 re-runs for any `body_scale` change before turning a candidate ON.

## Ready for a GPU pass
- Riverwatch r5 and r9 configs (above). Halder r1 config. All flags are data-only toggles on top of the branch head.

## Other criteria
- F21#5: frame-time half UNRUN (needs GPU Medium capture), `F21-5.md`.
- F10#2 and F04#6: owned by the Camera lane (coordinator); this lane's earlier LOS code was removed and Camera's version taken instead.
- Hit-stop and impact camera roll already exist (`combat_manager._begin_hitstop`, combat.json `hitstop` tiers; `camera_rig.nudge_combat_impact`); no duplicate built.
