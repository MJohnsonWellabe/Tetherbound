# Fights lane close-1022 (tb/fights)

## TO COORDINATOR
- 2026-10-22 08:40 CT QUESTION Ownership split taken as your default: Fights edits enemy_pattern_telegraph.gd, lunge_lane.gd, tell_style.gd, telegraph_glow.gd, impact_flash.gd, hit_feedback.gd, data/config/vfx.json and the Stormwood named attack rows' cue keys in combat.json (patterns.attacks.*: telegraph_colour, cue_*); Stormwood owns lighting/grade. Please relay to the Stormwood lane.
- 2026-10-22 08:40 CT INFO Yardstick merged (45d5d7535). Round T1 (Stormwood named tell look) mapped Tanglevolt 4.33 -> 4.97, Voltarach 4.68 -> 5.37; open, OFF (`F22-4-T1.md`). All three judges rank the Stormwood grade (purple storm sky, key/rim on fighters, lifted ground) as the largest gap: that is the Stormwood lane's.
- 2026-10-22 08:40 CT QUESTION F10#2's `line_of_sight_fade.pilot_min_screen_fraction` (0.07, Camera/coordinator) governs pilot size in Stormwood fights; all judges call the pilot "a tiny speck". May Fights raise it as part of a fights round, or will you?

- 2026-10-22 09:20 CT INFO F21#5 judge half: matched before (main) vs after (T2 storm hits, arc impact burst) on "hits feel weighty and readable": 3/3 judges prefer after, mapped 4.83 -> 5.43 (`F22-4-T2.md`, set Eh). The after side is a candidate, OFF; it is Stormwood-named-row data plus the OFF code hooks in 547463d6e. Tell me whether to cut a land branch for it now (F21#5 asks for preference, not 7.5) or wait for a bigger impact round first. Its Medium GPU frame can use capacitor_alpha/old_rodfolk with the T2 overlay (`cand_t2.py.txt` in this folder, run `python3 ralph/reports/FIGHTS/close-1022/cand_t2.py.txt` from the repo root = T1 + cue_crackle/cue_lane_crackle 0.85 + cue_burst_arcs 7).

- 2026-10-22 10:15 CT INFO Batch r3 (`F22-4-T3.md`): Riverwatch r9 (rigged Meshy captain at 2.3x, water cues, river dressing, 14 m cap, Meadows fade) mapped **7.09** vs control 5.56. That's at least 6.7 CPU-provisional but above_top_anchor (top 7.03); a confirming batch with --include f36_0_npc:C1 is running next. Stormwood T3 5.82 / 6.13; F21#5 T3 6.17 vs main 4.79 (3/3 prefer after).

- 2026-10-22 10:40 CT INFO Riverwatch r9 confirming batch (C1 included, r 0.93, RMSE 0.45): mapped **6.62** (control 4.83). The r3 7.09 was extrapolation and does not confirm. Next: r10 (thinner spray/fan sheets, droplet water burst).

- 2026-10-22 11:10 CT INFO F25#4 ask: the new tell/strike shaders (pulled cue, arc burst, lane) are now compiled once per process and shared (static cache). Per strike there is one ShaderMaterial and one StandardMaterial for the scorch; no per-hit Shader is built.

- 2026-10-22 11:40 CT READY-FOR-GPU Riverwatch r10 (captain_riverwatch named fight) mapped **6.74** in a confirming batch (top anchor 7.53, r 0.90, no warnings), control 5.22: CPU-provisional (>= 6.7), below 7.5 (`F22-4-R5.md`). Please queue its GPU confirmation (Low/Compatibility and Medium). Recipe: clean tree at tb/fights head, `python3 ralph/reports/FIGHTS/close-1022/cand_rw10.py.txt`, then `tools/art_pipeline/capture_named_fight.gd --trainer=captain_riverwatch --live-member=captain_riverwatch:4 --ally=ripplet --frames=12 --interval=0.5 --tell-frames --keep-alive`. Control is the same command on a clean tree. It includes `body_scale` 2.3 on the captain's Brooktail, which needs a C2 re-run before landing ON. I'll keep improving it (r11 screen tilt, boss scale) unless you say to land r10 now.
- 2026-10-22 11:40 CT INFO Stormwood named wilds T4 5.77 / 5.73 (first round gaining under 0.5). Those fights are now limited mainly by the Stormwood grade. I'm moving to the F22#4 named-trainer fights (Halder, Vance, then the rest) after Riverwatch.

- 2026-10-22 13:30 CT READY-FOR-GPU Riverwatch **r13** mapped **7.03** in a confirming batch (`F22-4-R6.md`; top anchor 7.53, r 0.80, no warnings), control 5.81. CPU-provisional (>= 6.7), below 7.5, parked on CPU after two rounds under +0.5. It supersedes the r10 request. Recipe: clean tree at tb/fights head, `python3 ralph/reports/FIGHTS/close-1022/cand_rw13.py.txt`, then the capture command in `F22-4-R6.md`.
- 2026-10-22 13:30 CT QUESTION r13 grows the captain's Brooktail to `body_scale` 2.9 (grow-only; collider and reach follow). The r9 notes say a C2 re-run is needed before a body_scale change goes ON. Which C2 proof should I run from this container, or will you run it? And do you want a `tb/fights-land` branch with r13 ON now as CPU-provisional (pending GPU), or after GPU?

- 2026-10-22 12:55 CT INFO F25#4 pin: the arc, pulled-cue and lane Shaders are static per process, so they never recompile. The only per-strike BaseMaterial3D is the scorch StandardMaterial in `enemy_pattern_telegraph._add_scorch`. Once tb/vfx-launch is on main I'll merge and route it through `material_variant_pin`; until then those effects stay OFF anyway.

- 2026-10-22 15:40 CT READY tb/fights-land a0ccdac0a F22#4 Riverwatch r13 ON (CPU-provisional 7.03 mapped, confirming batch, `F22-4-R6.md`; GPU confirmation pending). Built from origin/main 2aee07e08. Contents:
  - Branch-only hooks: member `body_scale` and member-row `camera_boss_side_view` (encounter_director); the side-view preference (fight_camera); the Meadows lens band for the sight-line fade (foliage_camera_visibility); Riverwatch fight dressing (trainer_aftermath.gd/.json); the Fights tell/strike hooks (enemy_pattern_telegraph, lunge_lane, tell_style, wild_creature, all OFF unless a row opts in; shaders cached once per process).
  - Assets: the rigged Meshy captain Brooktail plus the Riverwatch dock and mooring posts, with provenance folders.
  - Data ON: captain Brooktail body_scale 2.9 with the hero model; Oreth water tells in #4aa9c7 with thinner sheets and droplet strikes; per-trainer 14 m camera cap; Meadows sight-line fade; river dressing.
  - Proofs on this commit:
    - C2 named-fight hit/avoid witness PASS against the grown Brooktail: `tests/smoke_named_fight_hit_avoid.gd -- --trainer=captain_riverwatch --live-member=captain_riverwatch:4`; player_hits 3, stand_strikes_landed 3, dodges_avoided 3/4, reach 10.28. Also PASS on the default member (Mosshell).
    - Tests 0 failed: test_f22_riverwatch_presentation (new, 16 assertions), enemy_pattern_telegraph, lunge_lane, telegraph, creature_scale_ladder, fight_camera, named_fight (20 tests, including test_named_fight_profiles), trainer_aftermath.
    - A fresh CPU capture on the land commit matches the judged r13 frames.
  - Fix found while proving: r13's `camera_boss_side_view` sat in the CURRENT profile's combat block and broke test_named_fight_profiles. It moved to the member row (same behaviour, test untouched).
- 2026-10-22 15:40 CT INFO Vance v1 (`cand_v1.py.txt`, Tuskroot body_scale 2.2) refused combat admission: the grown body overlaps the relay Gate collider, `clear_seat_search_exhausted` after 395 attempts. It's a candidate only (OFF), so there is no shipped softlock. Vance needs a smaller grow (about 1.6) or a different seat; next round.

- 2026-10-22 15:05 CT INFO Re: Riverwatch r13 Medium "ghost/hologram" Brooktail. Checked the captain GLB: alphaMode is absent (OPAQUE), and the metallicRoughness texture's metal channel is ~0.01 (not metallic), so the material itself is not the cause. The prime suspect is `cue_boss_aura: true` on `oreth_overflow` and `oreth_flood`, inherited from the r9 data. During those tells `enemy_pattern_telegraph._add_boss_aura` puts an additive, unshaded rim shader (`blend_add`, `depth_draw_never`, strength 0.6-1.0 pulsing) as `material_overlay` on every mesh of the double-sided captain model, plus a cyan OmniLight (energy 3). On Forward+, glow and tonemapping can wash that rim into a grey-white veil over the whole body; on Compatibility it reads as a faint rim. Quick split for the GPU lane: on tb/fights-land, set `"cue_boss_aura": false` on both Oreth rows (combat.json, the two `cue_boss_aura` keys inside oreth_overflow / oreth_flood) and recapture Medium. If that clears it, I'll land the aura OFF for Riverwatch (CPU frames barely show it). Second suspect: the water wall/fan sheet (`cue_water_wall_opacity` 0.5, `cue_water_fan_fill_alpha` 0.4) drawn in front of the boss.
- 2026-10-22 15:05 CT INFO Next for Riverwatch on CPU (row stays open): pull the camera back from r13's close crop, and flatter telegraphs -> water-surface tells. Halder h7 and Vance v2 are judging next.

## Rounds
| Round | Item | Mapped control | Mapped candidate | Note |
|---|---|---|---|---|
| T1 | Stormwood named tell look (Tanglevolt / Voltarach) | 4.33 / 4.68 | 4.97 / 5.37 | `F22-4-T1.md` |
| T2 | + storm crackle + arc impact | 4.65 / 4.65 | 5.29 / 5.29 | `F22-4-T2.md`; vs T1 best +0.32/-0.08 (1st round <0.5) |
| F21#5 | hits weighty/readable, main vs T2 | 4.83 | 5.43 | 3/3 prefer after |
| T3 | + electric strike style, bluer tells, pilot floor 0.11 | 4.87 / 4.75 | 5.82 / 6.13 | `F22-4-T3.md`; gain >= 0.5 |
| RW r9 | Riverwatch captain (r9 data) | 5.56 / 4.83 | 7.09 extrapolated / **6.62 confirmed** | confirm batch with C1 |
| F21#5 | main vs T3 | 4.79 | 6.17 | 3/3 prefer after |
| RW r10 | r9 + thinner water sheets + droplets | 5.22 | **6.74** (confirming batch) | CPU-provisional; GPU requested |
| T4 | + leap-lane colour | 4.71 / 4.67 | 5.77 / 5.73 | first round < 0.5 |
| RW r11-13 | tilt / boss 2.9x / no tilt | 5.81 | 7.00 / 6.97 / **7.03** | parked on CPU at 7.03 (2nd round < 0.5) |
| Halder h4 | earth strike, amber crackle lane | 5.89 | 5.98 | 3rd round < 0.5; new approach next |
