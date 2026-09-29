# F04#2 and F04#7 C3: serial-lane pass bar (written before any render, not changed after)

Rubric: `ralph/reports/TIDEWAKE/phase1/C3_RUBRIC.md`, **unchanged**, handed to each judge before any frame. This file supersedes the one-judge wording in `ralph/reports/MEADOWS/f04/final_F04_2/BAR.md` (that bar named a single judge; the serial lane uses two, per the rubric). The Q1-Q3 content checks in that bar and in `final_F04_7/BAR.md` / `final_F04_1/BAR.md` remain informative but are not part of this pass line.

## Criteria covered
| Row | Criterion text (ACCEPTANCE §6.1 F04, board) | Open half | Fights |
|---|---|---|---|
| F04#2 | Three captains: named tactical question visible at normal distance (board status partial; gap "captures plus blind verdict per captain") | C3 camera/framing round on the ordinary (lateral-seat, contact-spaced) camera | Oreth, Halder, Vess |
| F04#7 | Varied-size framing and C2/C3 results pass (C2 half MET, ruling 12; not re-judged) | C3 framing at every body size | Warden Aldis, Vance, Dell, Oreth, Halder, Vess |

Trainer ids and named members (from the earlier BARs and captures):
| Fight | `--trainer=` | Named member (`--live-member`) | Note |
|---|---|---|---|
| Oreth | `captain_riverwatch` | `:0` Mosshell WALL | |
| Halder | `captain_field` | `:1` Tuskroot CHARGER | |
| Vess | `captain_ridge` | `:4` Galecrest DIVER | DIVER tell is 0.4 s; harness exemption (CLAUDE_START_HERE §4 row 8) |
| Vance | `relay_captain` | `:4` Tuskroot | |
| Dell | `relay_officer_dell` | none (opener Mosshell) | members 1 and 2 (Burrowback, Galecrest) are F04#1's; not required here |
| Warden | `warden_aldis` | none (default) | Tuskroot HEAVY is the frame source in the r3 captures |

## Frame lists
Every capture is judged on the full folder: all `tNN-{stand,dodge}-{start,mid,strike}` frames and in-fight frames `01`-`24` (the `--tell-frames` set is up to 4 tells x 3 frames, so up to 12 t-frames). Aftermath `aNN`, `rNN`, `-00-before` and `-99-after` frames are exploration/dialogue cameras and are **not scored** (as in JUDGE_C3_small_257839f5). A tell-start frame is every `tNN-*-start`.
- **F04#2 set (3 captures, Terrapup):** oreth, halder, vess.
- **F04#7 set (12 captures):** the six fights x {Terrapup, one small starter}. Small pairing (same as JUDGE_C3_small_257839f5): Galewisp for Warden, Halder, Vance; Ripplet for Vess, Oreth, Dell. Terrapup captures of Oreth, Halder and Vess are the F04#2 captures, reused if rendered on the same main SHA (the same folders count for both criteria).

## Per-frame rules and pass line (identical to the rubric)
EXCLUDED (a fighter downed/0 HP/absent); FAIL on clause 1 mostly off-screen, 2 camera in/behind geometry (a see-through player-creature close-up counts here), 3 the other fighter, a human or scenery over a combatant's head (a person standing in the fight, such as the Vance-arena NPC, counts), 4 HUD panel over a head, 5 tell-start with no visible ground marking; PASS otherwise. A creature's own pose hiding its own head passes if orientation reads.
- Two independent code-blind judges per capture folder: judge A on sonnet, judge B on the default model. Verbatim prompt: `ralph/reports/TIDEWAKE/phase1/f14_0/tess_final/JUDGE_PROMPT.md` with `<FOLDER>` set to the capture folder and the frame list taken from the folder's JPGs (Meadows folders have no `frames.json`; give the judge the JPG list of the fight frames excluding `a*`, `r*`, `-00-before`, `-99-after`). Judges may read `fight_log.txt` (allowed in the earlier Meadows rounds) but no source, config or reports. Convert PNG to JPG into the folder as renders finish.
- Archive `JUDGE_A.md` and `JUDGE_B.md` per capture folder (e.g. `ralph/reports/CLOSER/f04_2_7/<fight>_<ally>/`).
- **A capture passes only if both judges are at 90% or more PASS among non-excluded frames AND every tell-start frame is marked for both judges.**
- **F04#2 passes** if all three captain captures pass. **F04#7 C3 passes** if all 12 captures pass. Then one strict re-check by an independent agent (rubric read fresh, told of any placement or harness disclosure), as F14#0 did. No strict re-check on a failed round.
- Stills cannot test the 0.25 s clause: reported as unverified.
- Conservative reading of aggregation: pass is per capture, not pooled (matches earlier F04 BARs and the rubric). Pooling is not used.

## Render commands (render.yml, `workflow_dispatch` from main)
Common inputs: `checkout_ref` = the current `main` SHA (record it; the frames must be from main after #442/#444/#448 and any merged closer fix, not from tb/closer), `script` = `tools/art_pipeline/capture_named_fight.gd`, `mode` = `render`, `resolution` = `1280x720`. `--out=res://shots/closer/<label>` is required by the script (passes the args regex). Args pattern allows `= , . / : @ + -` and `_`; all below conform. `--frames` and `--interval` left at defaults (24, 0.5 s). `--resolve=won` is NOT used (no aftermath needed).

Arg stem: `--trainer=<id> [--live-member=<id>:<n>] [--ally=<starter>] --attack --dodge --tell-frames --keep-alive --out=res://shots/closer/<label>`

| label | timeout_minutes | args |
|---|---|---|
| f04c_oreth_terrapup | 60 | `--trainer=captain_riverwatch --live-member=captain_riverwatch:0 --attack --dodge --tell-frames --keep-alive --out=res://shots/closer/oreth_terrapup` |
| f04c_halder_terrapup | 60 | `--trainer=captain_field --live-member=captain_field:1 --attack --dodge --tell-frames --keep-alive --out=res://shots/closer/halder_terrapup` |
| f04c_vess_terrapup | 60 | `--trainer=captain_ridge --live-member=captain_ridge:4 --attack --dodge --tell-frames --keep-alive --out=res://shots/closer/vess_terrapup` |
| f04c_warden_terrapup | 60 | `--trainer=warden_aldis --attack --dodge --tell-frames --keep-alive --out=res://shots/closer/warden_terrapup` |
| f04c_vance_terrapup | 60 | `--trainer=relay_captain --live-member=relay_captain:4 --attack --dodge --tell-frames --keep-alive --out=res://shots/closer/vance_terrapup` |
| f04c_dell_terrapup | 60 | `--trainer=relay_officer_dell --attack --dodge --tell-frames --keep-alive --out=res://shots/closer/dell_terrapup` |
| f04c_warden_galewisp | 60 | as above `--ally=galewisp`, out `warden_galewisp` |
| f04c_halder_galewisp | 60 | Halder args + `--ally=galewisp`, out `halder_galewisp` |
| f04c_vance_galewisp | 60 | Vance args + `--ally=galewisp`, out `vance_galewisp` |
| f04c_vess_ripplet | 60 | Vess args + `--ally=ripplet`, out `vess_ripplet` |
| f04c_oreth_ripplet | 60 | Oreth args + `--ally=ripplet`, out `oreth_ripplet` |
| f04c_dell_ripplet | 60 | Dell args + `--ally=ripplet`, out `dell_ripplet` |

Order: run the three captain Terrapup captures first (this is all F04#2 needs), then the other nine for F04#7. One job per capture (the script also accepts `--trainer=a,b` to share one ~15 min world boot per run, but `--live-member` and `--ally` apply to the whole run, and earlier rounds used one run per fight, so one job per capture is the conservative reading). Each job is about the ~15 min world boot plus roughly 5-15 min of fight and frame saves on a GitHub runner (STATE's figure for two named fights on llvmpipe is about 30 min); 60 min cap each, raise to 90 if a job times out once (one confirming rerun only). Total 12 jobs; keep at most 2 in flight (coordinator's rule).

## Known defects to expect (from earlier rounds; not excused)
From `ralph/reports/MEADOWS/f04/JUDGE_C3_small_257839f5.md` (commit 257839f5, before contact spacing #442):
1. Player's creature covers the opponent's face at melee range, worst with small Galewisp (ears): vance_galewisp FAIL (t03-stand-strike, -08, -10, -11, -13); also halder_galewisp, warden_galewisp, vess_ripplet.
2. Vance arena: a dark-clad human NPC stands inside the Tuskroot's silhouette (t01-stand-strike, t02-dodge-start, t04-dodge-start, -11, -13, -24) and the Tuskroot is pinned against the stone arch. Counts under clause 3.
3. Hit VFX over the opponent's head at impact (halder t04-dodge-strike, -18; vess -18; warden t01-stand-strike).
4. Dell: red banner over the Mosshell's flank (-22, -24, t04-dodge-mid), head still readable (marginal).
5. Danger-lane far edge under the HUD panel and off-frame (Halder, Vance). A lane going off-screen is not a FAIL clause by itself, but tell-start marking visibility (clause 5) is judged on the marking's visible extent.
6. Coverage limits: small-ally Warden run ended after two tells when the Galewisp was knocked out (fewer tell frames; note keep-alive was on); Vess strikes log before resolving.
From `JUDGE_r3_3b6f965a.md`: Vance t04-dodge-* were all wall texture (camera against the arch); Vance a01 back-of-head close-up (aftermath, not scored).
Also known: Vess's 0.4 s tell is exempt from the 0.8 s minimum but its marking must still show; Vance and other lateral-seat fights depend on `arena.trainer_ally_lateral_ranks` (officer/captain/warden seat aside, bridge guardian in line); the Tidewake residue (F14#1 rounds) shows judge variance of about 10 points on near-identical fights, so a marginal capture may swing either way.

## Ambiguities and conservative readings
- The F04 board text of #2 and #7 does not list frames; the lists above follow final_F04_2/BAR.md and final_F04_7/BAR.md and the 257839f5 six-fight, two-size set.
- Warden `--live-member`: the F04 BARs give none for the Warden; the r3 captures used the default and the Tuskroot HEAVY appeared. Conservative: no `--live-member` (if the first capture shows a non-Tuskroot opener with no HEAVY tell, that is a capture defect to record, and `--live-member=warden_aldis:4` is the one permitted variant, decided before judging and disclosed).
- Dell: opener only (F04#7 BAR); his second and third members belong to F04#1.
- The final-round rule "one round, a fail records defects and ends the criterion's rounds" (coordinator 22:04) now sits with the serial closer lane; two attempts maximum per root cause (CLAUDE.md), so if round 1 fails, record exact defects and stop unless a single root-cause fix is in scope.
- Judge frame lists: Meadows captures write JPG without `frames.json`; the folder listing filtered as above is the frame list.
- Renders come from main; if the round must use `tb/closer` (unmerged fixes), disclose the SHA and re-render on main after merge before marking anything met.
