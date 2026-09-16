# Codex Exit Handoff — Four-Biome Production Closeout — 2026-09-15

## Resume the persistent goal

Resume this as an explicit persistent goal immediately:

> Finish Meadows gates A0–A11 from production gameplay and current evidence,
> then continue directly through Cloudreach, Stormwood, and Water until all four
> biomes are implemented, tested, visually reviewed, documented, committed, and
> pushed to `main`.

Do not stop at a status report, a focused test pass, or a failed campaign. A
failure is the next work item. Ordinary test/capture failures and unavailable
GitHub authentication are not blockers. Preserve unrelated worktree changes and
exact-stage only.

This document supersedes the operational state in
`docs/CODEX_EXIT_HANDOFF_2026-09-14_GOAL.md`; retain that file for the detailed
R27–R62 Burrow Warrens history.

## Repository state

- Repository: `D:\tetherbound\source`
- Working branch: `codex/all-branches-integration-0913`
- Current code checkpoint before this handoff commit:
  `6688933c3313415f2b0cfff51f4f9d6721490454`
- At verification time, local integration, `origin/main`,
  `origin/codex/all-branches-integration-0913`, and
  `origin/owner-run/20260915T222920Z` all pointed to that SHA.
- GitHub push access is working. Push each coherent validated checkpoint to both
  the integration branch and `main`.
- Godot:
  `C:\Users\mattj\.cache\tetherbound-tools\godot-4.7\Godot_v4.7-stable_win64_console.exe`

The source worktree contains extensive generated `.import`/`.uid` churn and an
unrelated modified `shaders/earth_bank.gdshader`. Do not blanket-add, clean,
reset, or restore these files. Exact-stage only.

## What is genuinely complete

- Burrow Warrens R62 production identity is accepted by independent pixel-only
  review. Its final evidence is
  `ralph/reports/MEADOWS-0912/final-warrens-62-desktop-01`.
- Meadows playtest ledger: **43/43**.
- Meadows named-location ledger: **23/23**.
- The Rise, Old Quarry, Old Mill Crossing, and Burrow Warrens production
  location work is complete.
- Current 64-region Meadows terrain bake, tournament consent, and Captain Halder
  cadence fixes are committed.
- Full regression result at the closeout checkpoint: **3,675 tests / 2,318,706
  assertions / 0 failures** (shard 1: 1,813 / 1,974,826; shard 2: 1,862 /
  343,880).
- Shipped Windows export verification passed in the latest campaign:
  `EXPORT-CHECK terrain=yes ground_at_spawn=0.90 player_y=2.90 props=382543`.
- Production campaign S01 and S02 both ran through the real title/new-game,
  mandatory character selection, trainer naming, opening gameplay, first combat
  and catch, road gate, and village arrival. S01C and S02C also exited 0 and
  wrote real production captures.

Important commits already on `main` include:

- `44056970` — finish Burrow Warrens interior identity
- `3a27c3bb` — reconcile complete Meadows closeout ledgers
- `2fe0b407` / `45458b12` — tournament consent and Halder fixes
- `bd1eaed3` — accepted world closeout contracts
- `1ee63f71` — production terrain provenance
- `844e1ef7` — production character entry in Gate F logic lanes
- `8568f34f` — production onboarding and capture preflight
- `5fb52c2e` / `6688933c` — player-name prompt teardown fix and typed weak ref

## Meadows is not closed

Do not report Meadows complete yet. The continuous production campaign has not
passed A0–A11, its later captures have not been independently judged, and the
canonical closeout documents have not been updated from one clean campaign.

Latest full campaign:

- Worktree: `D:\tetherbound\owner-kickoff-closeout-r5`
- Owner report:
  `D:\tetherbound\owner-kickoff-closeout-r5\ralph\reports\OWNER-KICKOFF-20260915T222920Z`
- Gate-F evidence:
  `D:\tetherbound\owner-kickoff-closeout-r5\ralph\reports\gate-f-run-20260915T222920Z-owner`
- Machine-only payload:
  `C:\Users\mattj\AppData\Local\Tetherbound\runs\20260915T222920Z`
- Timing: 2026-09-15 17:29–19:43 America/Chicago.
- Prepare, frames, perf, and export passed. Chain failed.
- S01 and S02 passed; S03–S10e cascaded. S01C and S02C passed; later capture
  lanes cascaded.

## Exact next defect: S02 save handoff

Do not launch another complete campaign before fixing and proving this seam.

S02 reached the village in real gameplay, but its final save block assumes the
old pause-menu order. `tools/gate_f/segments/S02.json` opens Map and presses RB
three times, expecting Map -> Quests -> Build -> Save. The production menu now
contains conditional Skills plus the Players tab. In the latest run:

- `S02-64`: three tab-right presses completed.
- `S02-65`: actual context was `menu_players`, expected `menu_save`.
- `S02-66`: focus remained on the Players tab.
- `S02-69`: `user://saves/slot_4.json` did not exist.
- `S03-03`: `run://S02-exit.json` consequently did not exist.
- S03 remained on the title screen, and every later segment failure was a
  downstream missing-save cascade.

The likely direct correction is to make menu navigation deterministic against
the current production menu rather than encoding a stale fixed count. At
minimum, the current visible order in `data/config/menu.json` is Map, optional
Skills, Quests, Build, Players, Save; a simple extra press may vary with whether
Skills is revealed. Prefer a harness action that selects/asserts a tab by id, or
otherwise compute the required live transitions. Apply the same correction to
every segment save block, not S02 alone, and update the authored observations
that still claim three presses.

Also correct the non-world S02 threshold `S02-59`: the run walked 139.6 m and
failed an expected minimum of 150 m even though the production journey itself
completed. Diagnose whether the route/threshold is stale; do not mask a real
route regression.

Recommended proof sequence:

1. Add focused coverage for deterministic navigation from Map to Save with the
   current tab set, including Skills hidden and revealed.
2. Run the focused Gate F tests.
3. Run S02 alone into a fresh run directory and require both `slot_4.json` and
   `saves/S02-exit.json`.
4. Run S03 against that same run directory and require a real loaded Player,
   party >= 2, village arrival, and the expected tracked objective.
5. Only then run the remaining continuous chain/capture lanes and repair each
   genuine production failure in order.

The latest S02 and S03 primary diagnostics are:

- `...\gate-f-run-20260915T222920Z-owner\S02\notes\S02.md`
- `...\gate-f-run-20260915T222920Z-owner\S03\notes\S03.md`
- `...\OWNER-KICKOFF-20260915T222920Z\RUN_SUMMARY.md`

## Separate packaging defect

The campaign claimed it pushed `owner-run/20260915T222920Z`, but Git printed
`no changes added to commit`. The remote owner-run ref points to `6688933c`, the
same code SHA, so the campaign evidence was not committed to that branch.
Repair the package/staging logic so intended report files are explicitly staged
and the owner-run branch receives a real evidence commit. Never stage generated
import churn as a workaround.

## Required closeout order

1. Fix and prove the S02 -> S03 production save seam.
2. Continue the same real production chain through all Meadows segments and
   capture lanes; repair failures rather than accepting cascades.
3. Inspect the actual production pixels and obtain fresh independent blind
   verdicts where required. Automated manifests are not visual passes.
4. Update canonical A0–A11 verdicts and ledgers immediately when evidence
   changes them.
5. Fix evidence packaging, commit coherent checkpoints, and push integration
   plus `main`.
6. Once Meadows A0–A11 is genuinely green, continue directly through
   Cloudreach, Stormwood, and Water with the same implementation, test,
   production-capture, independent-review, ledger, documentation, commit, and
   push discipline.

## Honest stop state

The last campaign finished on its own and no process is currently running. This
is a safe technical handoff boundary because all intended source changes through
`6688933c` are committed and pushed, and the next failure is isolated. It is not
a completion boundary: Meadows A0–A11 and the other three biomes remain open.
