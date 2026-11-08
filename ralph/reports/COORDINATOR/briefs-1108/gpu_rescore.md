# GPU re-score, 8 Nov 2026 (owner's GPU machine)

Tree: origin/main at be95950b9 or later. Method: TECHNICAL §8.1 "GPU form": the same capture tool and arguments as each row's repro in `ralph/reports/VISUAL/item-scores/job.json`, plus `--rendering-method forward_plus --resolution 1920x1080 --preset=<High|Medium>`. Judge with `tools/visual_judge/` (standard JUDGE_PROMPT, three code-blind judges, at least 3 anchor pairs, calibrate.py mapping). Owner rule (31 Oct): High first; add Medium only for a row whose High mapped score is 7.5 or above. A row closes only at mapped 7.5 or above on both. A GPU score below the row's CPU score reopens it. Commit verdicts and at most one sheet under 1.5 MB per batch to `ralph/reports/GPU-PASS/1108/`; push branch `tb/gpu-rescore-1108`, never main.

## A. Live re-baseline (no arm; the live game changed after the last GPU score)
| Row | Why | Note |
|---|---|---|
| F40#14 P2-048 map label | High 7.52 on 1 Nov | Medium only: may close |
| F41#15 P2-083 dialogue obstruction | speaker now visible, banner gone | last 3.19 |
| F38#19 P2-004 exploration HUD | old GPU frames were shot under the opening fade | settled stand |
| F39#7 P2-089 fight composition | stacking gone | |
| F39#19 P2-088 roster contrast | roster no longer fades | |
| F39#20 P2-090 background ground contact | buried blob gone | |
| F39#23 P2-114 catch chance HUD | chip now plated | |
| F38#30 / F38#24 Warrens | walk_03 stand was inside solid collision; now re-seated (capture_stands.json inside_collision_reseat) | |
| F41#16 P2-110 Hollows loss | job.json now shoots a real loss (party 42, idle) | first real loss frames |

## B. Confirm today's CPU gains (landed 7-8 Nov, never GPU-judged)
F38#41 quarry boulders, F38#5 creature scale, F38#32 camp, F39#3 Drowned Garden (terrace and flood), F38#36 speaker occlusion, F39#8 Aquaryn mounted pose, F38#26 Mosshell faint, F38#17 Solene/Hald, F41#8 Bryn/Maud, F39#10 water depth, F41#14 candy tiers, F41#9 harvest nodes.

## C. Arm (judge against live)
- F41#21 P2-111 Hollows victory: `hud.json` victory_focus ON vs OFF (CPU needs 6-8 h; GPU minutes).

## D. Hold (do not judge yet)
- F39#9 / F38#14 catch frames: a stale "broke free" card shows over new throws (a real HUD bug; the fix `hud.json catch_card.clear_on_release_1107` is being confirmed). Judge after it lands.
- F39#21 victory hierarchy: its capture flags are on `tb/item-f39-21`, not main yet.

## E. Check
- F41#12 lantern_hollow night frame renders fully daylit on CPU (records hour 23). Is it daylit on GPU too?
- F39#9 absorb timing on GPU (after D clears).
