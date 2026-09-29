# F10#6 r7 named-fight capture: plan (prepared, nothing run)

Prepared 2026-09-29. Read-only research; this is the only file written. Nothing was dispatched, rendered or pushed.

## 1. Blockers found in the r7 RENDER.txt command (fix before dispatch)

The recorded command is `capture_named_fights.gd --ids=hollows_alpha,crown_guardian --seconds=10 --fixed-fps 10 -- --out=<dir>`. It cannot be dispatched through `render.yml` as written, for four reasons.

1. **Script path.** The script lives at `ralph/reports/STORMWOOD/b/f10_2/capture_named_fights.gd`. `render.yml` only accepts `^(tests|tools)/[A-Za-z0-9_/.-]+\.gd$`, and its sparse checkout excludes `/ralph/`, `/docs/`, `/shots/`, `/assets_raw/`, `/archive/`. So the script must be committed under `tools/` (for example `tools/capture_named_fights_f10_6.gd`, a byte copy) on a pushed branch. Its `const` preloads are `res://autoload/...` and `res://scripts/...`, which are in the checkout; there is no `res://ralph` reference. Check with `grep -n "res://ralph" <copy>` before pushing (I saw none in the header or the first 200 lines, but did not read lines 200-487 in full).
2. **`checkout_ref`.** `main` does not contain that `tools/` copy. Either land the copy via a PR first, or dispatch with `checkout_ref` set to the pushed `tb/closer` branch (or its SHA). Use the game code the r7 explore frames used, or current main, and record the SHA: r7 explore is `tb/stormwood 29295e77`. The judges must see fight and explore frames from the same HUD code, so prefer a ref that contains 29295e77 (main after consolidated PR #442, if merged) and re-state the SHA in RENDER.txt.
3. **`--fixed-fps`.** It is an engine flag and must come before `--script`. `render.yml` builds `godot ... --script "$SCRIPT" -- <args>`, so everything in `args` reaches the script as a user arg and `--fixed-fps` cannot be passed. The `--` separator must not be put in `args` either (the workflow adds its own). The `--fixed-fps 10` space form would also just split into two user args, which the script ignores. Consequence: the run is real-time on llvmpipe, not lockstep. The script counts game time by physics frames (`_phys`, `_t()`), so its tell/impact triggers and the `--seconds` cap still follow game time, but frame spacing will be uneven and the run will differ from r6's fixed 10 fps. Disclose this in RENDER.txt. Alternatives if the frames look wrong: (a) add a workflow input for extra engine args (a `render.yml` edit; must land on `main` because dispatch uses main's workflow) or (b) run locally with the header command. Do not try a third variant if two fail.
4. **`--out` location.** `render.yml` uploads (a) every file created or changed under the working tree after the start marker (`tree/`), and (b) the whole `user://` dir minus `shader_cache` (`user/`), plus `run.log`, `exit_code`, `MANIFEST.txt`. The script writes PNGs with `save_png(_out/...)` and `capture_log.json`. `_out` is used as given, so an absolute runner path is unknown in advance. Use `--out=user://f10_6_fight` (allowed characters `:` and `/`, and `DirAccess.make_dir_recursive_absolute` / `save_png` both resolve `user://`); frames then land under `user/` in the artifact (`XDG_DATA_HOME=$RUNNER_TEMP/userdata`, so `user/godot/app_userdata/<project>/f10_6_fight/`). A relative working-tree path such as `--out=shots/f10_6_fight` should also land in `tree/shots/f10_6_fight/` (Godot sets cwd to `--path .`), but that is an assumption I did not verify. Pick `user://` first; use `MANIFEST.txt` to find the files.

## 2. Exact dispatch inputs

| Input | Value |
|---|---|
| workflow | `.github/workflows/render.yml`, dispatched from `main` |
| `checkout_ref` | the pushed branch or SHA that contains the `tools/` copy AND stormwood 29295e77 (see blocker 2) |
| `script` | `tools/capture_named_fights_f10_6.gd` (copy of `ralph/reports/STORMWOOD/b/f10_2/capture_named_fights.gd`) |
| `args` | `--ids=hollows_alpha,crown_guardian --seconds=10 --out=user://f10_6_fight` |
| `mode` | `render` (the script refuses headless: "needs --out= and a rendering display") |
| `resolution` | `1920x1080` |
| `timeout_minutes` | `120` (script cap is 150; r6 took about 30 min with fixed fps; world build alone was 61 s in r6; real-time mode is unmeasured, so leave headroom) |
| `label` | `f10_6_r7_fight` |

The args string uses only letters, digits, `_ = , . / :` and spaces (checked against `^[A-Za-z0-9_=,./:@+\ -]*$`). The `--interval` default is 1.0 s and `--seconds=10` is per fight; r6 used the same values, so the frame set should match r6's names.

## 3. Expected output and runtime

- Artifact `render-f10_6_r7_fight-<run_id>`, retained 7 days: `run.log`, `exit_code`, `MANIFEST.txt`, `user/.../f10_6_fight/` (or `tree/...`).
- Frames, as in `r6/fight/`: `hollows_alpha-00-before.png`, `hollows_alpha-iNN.png` (one per second), `hollows_alpha-tellN-b-mid.png`, `-tellN-e-impact.png`, `crown_guardian-iNN.png`, `crown_guardian-tellN-b-mid.png`, `-tellN-f-recovery.png`, and `capture_log.json`. Which tell numbers exist depends on the live fight, so select by role, not by exact name.
- Success check: `exit_code` is 0, `capture_log.json` has a summary row for each of the two ids, the log shows "population_ready=true", and each chosen frame line says `fighting=true` and `enemy_on_screen=true`.
- Runtime: about 30 minutes for r6 on llvmpipe at 1920x1080 with `--fixed-fps 10`. Expect the same order or longer without it.
- One confirming rerun is allowed for a suspected infrastructure failure (r7 explore needed one process per stand because a single process stalled after one frame; the fight tool is one process by design, so if it stalls, run it once per id with `--ids=hollows_alpha` then `--ids=crown_guardian`, under two labels).

## 4. Convert frames and build the 7-inch sheet

1. Download the artifact and copy the PNGs into `ralph/reports/STORMWOOD/f10_6/r7/fight/`. Convert PNG to JPG q88 (r6 did this): `Image.open(p).convert("RGB").save(out, "JPEG", quality=88)`, keeping 1920x1080. Keep `capture_log.json` beside them.
2. Choose the seven cells, matching the prompt's sheet keys: hollows_alpha `H0` (00-before), `Hi` (an interval frame with the enemy panel and tell), `H2b` (tell 2, mid), `H2e` (tell 2, impact); crown_guardian `Ci` (interval frame), `C1b` (tell 1, mid), `C2f` (tell 2, recovery). r6's picks: `hollows_alpha-00-before`, `-i01`, `-tell2-b-mid`, `-tell2-e-impact`; `crown_guardian-i05`, `-tell1-b-mid`, `-tell2-f-recovery`. Use those names if they exist; otherwise the nearest tell frame and say so in RENDER.txt.
3. Strike: reuse `ralph/reports/STORMWOOD/f10_6/r6/strike/` (`seq_t000`, `seq_t060`, `seq_t100`, `seq_t125`, 1280x720, HUD hidden). r7 RENDER.txt already states "nothing since touches the strike ring". Confirm with `git log 29295e77..<ref> -- ` on the strike ring code before relying on it (not checked here). Copy them to `r7/strike/` so the r7 folder is self-contained, and disclose the HUD-hidden 1280x720 limitation as r6 did (the strike frames cannot test HUD occlusion of the ring).
4. Sheet: the existing r7 sheet is 1758x660 (3 columns x 2 rows of 586x330, no gutters, explore only). Rebuild it as 3 columns and ceil(N/3) rows of 586x330 cells, N = 6 explore + 7 fight + 4 strike = 17 (6 rows, 1758x1980), in the order the r7 explore order `FB FC GB / GC RB RC`, then H0 Hi H2b / H2e Ci C1b / C2f, then S0 S6 S10 / S12 (strike t000, t060, t100, t125, keyed as in r6: S0 S6 S10 S12). Plain resize, no crop, LANCZOS, JPG q88, no captions inside cells (r7 RENDER.txt: "plain 586x330 cell resize"; a legend goes in the judge prompt only). Sketch:

   ```python
   from PIL import Image
   W, H, C = 586, 330, 3
   cells = [...]  # ordered paths
   rows = -(-len(cells) // C)
   sheet = Image.new("RGB", (W * C, H * rows), (20, 20, 20))
   for i, p in enumerate(cells):
       im = Image.open(p).convert("RGB").resize((W, H), Image.LANCZOS)
       sheet.paste(im, ((i % C) * W, (i // C) * H))
   sheet.save("ralph/reports/STORMWOOD/f10_6/r7/_sheet_7inch.jpg", "JPEG", quality=88)
   ```

   The 1280x720 strike frames resize to the same 16:9 cell. Overwrite the old explore-only sheet only after keeping the old one as `_sheet_7inch_explore_only.jpg` (it is the evidence both earlier judges saw).
5. Update `r7/RENDER.txt` (fight frames now captured: SHA, args, no `--fixed-fps`, PNG to JPG q88, cells chosen).

## 5. Judge protocol

Cap from the coordinator (STATE): one judge round, then a strict re-check; if it fails, record the failures in STATE and hand F10#6 to the shared HUD-legibility lane with T2's device profile.

1. Prompt: `ralph/reports/STORMWOOD/f10_6/r7/JUDGE_PROMPT.md` unchanged (paths already point at r7; sheet keys already list H0/Hi/H2b/H2e, Ci/C1b/C2f, S0/S6/S10/S12).
2. Run two code-blind judges in parallel (as r7 did as A and B), each writing its own file: `JUDGE_A.md`, `JUDGE_B.md` (the prompt says `JUDGE.md`; override the output name per judge, or the second overwrites the first). Judges may read only the files the prompt names, so the Bar A files must be present in their checkout (section 6) and `docs/reference/palworld-01..05`. Each judge answers the four device questions by frame, with Bar A and Bar B yes/no.
3. Strict re-check: a third, independent judge (or the same prompt with a strictness preamble) reads both verdicts and the sheet and re-decides only the four device questions, treating any "no" from a judge, or any contradiction, as unresolved until it re-looks at the named frame. r4's pass was withdrawn because its prompt exempted the trainer; do not reword the UX section 1.4 rule. r4-r6 showed judge variance on identical frames (r7 A vs B contradicted on Q1), so record contradictions rather than chase them.
4. Pass rule: F10#6 is met only if both the judged round and the strict re-check pass Q1-Q4. On failure, record panel, frame and what could not be read in STATE and hand off. Known open defects (do not count as new failures if the judges repeat them): legend hints 26 px vs UX 30 px, forest trunks near-black and the Break forest trainer near-invisible (Phase 2 catalog), hit-burst disc over the target face.
5. Record everything in `ralph/reports/STORMWOOD/f10_6/r7/` (JUDGE_A.md, JUDGE_B.md, RECHECK.md), update STATE in place; no new live documents.

## 6. Bar A reference files

Both r7 judges reported them missing. They are NOT absent from the repo; they are tracked in git and skipped in the working tree.

- `docs/reference/tetherbound-meadows-keyart.png` (2,953,652 bytes), `docs/reference/boards-2026-09-06/stormwood-stormheart-tree-stronghold-board-a.png` (2,965,351) and `-board-b.png` (3,070,463) are all in `HEAD` and `origin/main` (`git ls-tree` lists them; the blobs are present locally: `git cat-file -s HEAD:<path>` returns the sizes above). Added in 03e8bca0 (2026-09-22) and carried through 96c1af6a.
- `git ls-files -v` shows them (and the other five boards, `owner-board-2026-08-15-*.png`) with the `S` flag: **skip-worktree**. That is why `ls docs/reference/` and `docs/reference/boards-2026-09-06/` show only the README, jpgs and READMEs. The checkout is a partial clone (`blob:limit=1048576`, shallow) and files over 1 MB were set skip-worktree, not deleted. `git status` is clean, so it is silent about it.
- No other copy exists: searched the whole tree including `archive/`, `assets_raw/` and `ralph/reports/` for `*keyart*`, `*board*a.png`, `*board-b*`, `*stronghold-board*`, and found nothing else. `assets/environment/stormwood/stormheart_hero/reference/stormheart.png` is a single-asset reference (Meshy hero tree), not the Bar A board, and should not stand in for it. `archive/docs/future/boards/01-03_*.png` are world/region boards, unrelated. `docs/reference/README.md` and the boards README describe what each file is (keyart is the primary reference).
- Fix (needs a write, so not done here): before the judges run, in the checkout the judges use, run
  `git update-index --no-skip-worktree docs/reference/tetherbound-meadows-keyart.png docs/reference/boards-2026-09-06/*.png && git checkout -- docs/reference` (the blobs are local, so no fetch is needed; if a checkout is missing them, `git fetch origin` with the partial-clone filter will pull them). Then confirm with `ls -l` that the three files exist (sizes above) and that a judge can open them. The judges' own note that `boards-2026-09-06/` holds only a README matches the skipped state.
- If a judge is spawned in a fresh container, repeat the check there: it will hit the same partial-clone skip. `render.yml` is unaffected (it excludes `/docs/` anyway).

## 7. Order of work

1. Restore the Bar A files (section 6) and confirm they open.
2. Commit the `tools/` script copy on `tb/closer` (or via a PR to main); push.
3. Dispatch render.yml with the section 2 inputs; wait about 30 to 60 minutes; do not poll faster than a few minutes.
4. Download the artifact, convert, build the sheet, copy the strike frames, update RENDER.txt.
5. Run judges A and B, then the strict re-check; record in STATE.
