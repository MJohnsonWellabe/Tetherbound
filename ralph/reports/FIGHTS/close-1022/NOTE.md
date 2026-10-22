# Fights lane close-1022 (tb/fights)

## TO COORDINATOR
- 2026-10-22 08:40 CT QUESTION Ownership split taken as your default: Fights edits enemy_pattern_telegraph.gd, lunge_lane.gd, tell_style.gd, telegraph_glow.gd, impact_flash.gd, hit_feedback.gd, data/config/vfx.json and the Stormwood named attack rows' cue keys in combat.json (patterns.attacks.*: telegraph_colour, cue_*); Stormwood owns lighting/grade. Please relay to the Stormwood lane.
- 2026-10-22 08:40 CT INFO Yardstick merged (45d5d7535). Round T1 (Stormwood named tell look) mapped Tanglevolt 4.33 -> 4.97, Voltarach 4.68 -> 5.37; open, OFF (`F22-4-T1.md`). All three judges rank the Stormwood grade (purple storm sky, key/rim on fighters, lifted ground) as the largest gap: that is the Stormwood lane's.
- 2026-10-22 08:40 CT QUESTION F10#2's `line_of_sight_fade.pilot_min_screen_fraction` (0.07, Camera/coordinator) governs pilot size in Stormwood fights; all judges call the pilot "a tiny speck". May Fights raise it as part of a fights round, or will you?

- 2026-10-22 09:20 CT INFO F21#5 judge half: matched before (main) vs after (T2 storm hits, arc impact burst) on "hits feel weighty and readable": 3/3 judges prefer after, mapped 4.83 -> 5.43 (`F22-4-T2.md`, set Eh). The after side is a candidate, OFF; it is Stormwood-named-row data plus the OFF code hooks in 547463d6e. Tell me whether to cut a land branch for it now (F21#5 asks for preference, not 7.5) or wait for a bigger impact round first. Its Medium GPU frame can use capacitor_alpha/old_rodfolk with the T2 overlay (`cand_t2.py.txt` in this folder, run `python3 ralph/reports/FIGHTS/close-1022/cand_t2.py.txt` from the repo root = T1 + cue_crackle/cue_lane_crackle 0.85 + cue_burst_arcs 7).

- 2026-10-22 10:15 CT INFO Batch r3 (`F22-4-T3.md`): Riverwatch r9 (rigged Meshy captain at 2.3x, water cues, river dressing, 14 m cap, Meadows fade) mapped **7.09** vs control 5.56. That's at least 6.7 CPU-provisional but above_top_anchor (top 7.03); a confirming batch with --include f36_0_npc:C1 is running next. Stormwood T3 5.82 / 6.13; F21#5 T3 6.17 vs main 4.79 (3/3 prefer after).

- 2026-10-22 10:40 CT INFO Riverwatch r9 confirming batch (C1 included, r 0.93, RMSE 0.45): mapped **6.62** (control 4.83). The r3 7.09 was extrapolation and does not confirm. Next: r10 (thinner spray/fan sheets, droplet water burst).

- 2026-10-22 11:10 CT INFO F25#4 ask: the new tell/strike shaders (pulled cue, arc burst, lane) are now compiled once per process and shared (static cache). Per strike there is one ShaderMaterial and one StandardMaterial for the scorch; no per-hit Shader is built.

## Rounds
| Round | Item | Mapped control | Mapped candidate | Note |
|---|---|---|---|---|
| T1 | Stormwood named tell look (Tanglevolt / Voltarach) | 4.33 / 4.68 | 4.97 / 5.37 | `F22-4-T1.md` |
| T2 | + storm crackle + arc impact | 4.65 / 4.65 | 5.29 / 5.29 | `F22-4-T2.md`; vs T1 best +0.32/-0.08 (1st round <0.5) |
| F21#5 | hits weighty/readable, main vs T2 | 4.83 | 5.43 | 3/3 prefer after |
| T3 | + electric strike style, bluer tells, pilot floor 0.11 | 4.87 / 4.75 | 5.82 / 6.13 | `F22-4-T3.md`; gain >= 0.5 |
| RW r9 | Riverwatch captain (r9 data) | 5.56 / 4.83 | 7.09 extrapolated / **6.62 confirmed** | confirm batch with C1 |
| F21#5 | main vs T3 | 4.79 | 6.17 | 3/3 prefer after |
