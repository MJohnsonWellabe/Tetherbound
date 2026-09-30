# Coordinator tooling: the Acceptance Board and lane scans

This is what the integration coordinator used to track ACCEPTANCE §6.1, so a later session can pick it up and keep building. It is evidence and tooling, not a status document. `docs/STATE.md` stays the handoff; this folder is what regenerates the board.

## Acceptance Board

**Rendered remote board:** [Tetherbound Acceptance Board](https://tetherbound-acceptance-board.mattjohnson912.chatgpt.site), private to the owner's ChatGPT account. This is the viewing link; the GitHub HTML file shows source, and localhost links work only on the serving PC.

The earlier private Claude artifact, https://claude.ai/artifact/XYqEQ3ifDhZJUmNdbYrDem, is a legacy snapshot unless explicitly republished with an available Artifact tool.

| File | Role |
|---|---|
| `dashboard/criteria.json` | Scoring data. The key is `rows[]`, one per F-row (F01 to F15, plus the redesign rows F16 to F49 added 2026-09-29, whose `chapter` field holds the wave name and `lane` the owning lane). Each row has `criteria[]` holding `text`, `status` (`met` / `partial` / `in_progress` / `not_started` / `failing` / `blocked`), `evidence`, `gap`, and an optional `note`. Criteria are numbered from zero within a row: `F04#7` is `rows[F04].criteria[7]`. |
| `dashboard/status.json` | The coordinator's notes: `headline[]` (a line reads "Criteria met: N of 280 …"), `batches[]`, `lanes[]`, `decisions`, `owner_needs[]` and `wip[]`, the pickup list for unfinished work. |
| `dashboard/build_dashboard.py` | Renders both JSON files into `dashboard/tetherbound_dashboard.html` (a self-contained page; paths are relative to the script). |
| `dashboard/tetherbound_dashboard.html` | The generated self-contained page; its status timestamp comes from `status.json`. |

To rebuild and republish:
1. Edit `criteria.json` only for criteria that actually moved. The scoring rule:
   - a criterion is MET when the batch holding its evidence merges to main with a passing independent strict re-check (owner, 2026-09-27). The full CI run after each batch is a safety net: if it goes red, that batch's criteria return to landing until the fix lands (WORKFLOW §8);
   - verify the lane's evidence at its SHA yourself before counting it.
2. Update `status.json` (headline, batches, lanes, owner needs).
3. Run `python3 ralph/reports/COORDINATOR/dashboard/build_dashboard.py`.
4. Commit and land JSON plus HTML through the board-duty docs PR, so data never lives only in a container.
5. Republish the landed HTML to the same owner-private Site using the procedure below. Keep its URL and access unchanged. If an Artifact tool is available, the legacy Claude artifact may also be refreshed using its exact existing URL.

### Private Site publication

The publication checkout on the owner's PC is `D:/tetherbound/board-site`, a separate Git repository; publishing it does not push game `main`. Its `.openai/hosting.json` persists the exact Site project ID `appgprj_6abc67ef56448191a7a6bcf431405f18`. Reuse this project; never create a replacement Site or change its audience.

Copy the freshly landed `dashboard/tetherbound_dashboard.html` to `dist/index.html`. The validated hosting manifest has `project_id` above and `static: {"directory": "dist"}`; generated URL metadata is not a manifest field. Obtain a short-lived source credential for this project through Sites, commit the publication files, and push that exact commit to the returned source repository/branch. The archive comes from that pushed commit and contains `.openai/hosting.json` plus `dist`. Use `save_version_and_deploy_private`, then check `get_deployment_status` until terminal success before posting the viewing link. Do not print or persist credentials. Keep the access owner-only and the URL stable.

Initial verified publication: game main `08523b641`, publication source `2c9427ffe332cdbcb269df0ab51f055e8c8642da`, saved version `appgprj_6abc67ef56448191a7a6bcf431405f18~appgver_13fa2f0b0c088191b4177b917cc33c2f`, deployment `appgdep_6abc69de2a3481918cf9c485fd3b957f` succeeded. It publishes the same 95/280 board with RD-36; no new game criterion was accepted by publication.

## Lane scans

- **`ready.py`:** lists every `READY FOR INTEGRATION: <branch> <sha>` line posted in issue/PR comments since its hard-coded start time, and reports whether each SHA is on main (PENDING or MISSING otherwise). Lanes now post READY/FINAL on Lane channel issue #356; update the start time before use. It uses `$GITHUB_TOKEN`; run it from the repository root.
- **`lanes.py <saved list_sessions output>`:** summarizes each lane's status, last update and status detail.

## Hourly rebuild (redesign)

The owner asked for the board to be rebuilt every hour during the redesign build. Whichever lane holds board duty (CODEX_START_HERE §4, §7.3) refreshes `status.json`, runs the builder, and lands JSON plus HTML through a small docs PR. It republishes the landed page to the private Site above when Sites tools are available; the legacy artifact is optional when its tool is available. The builder groups every row outside F01–F15 by its wave.

## Current state

STATE §0 holds the current counts, card results and open owner decisions; `dashboard/status.json` `wip[]` is the pickup list. The 2026-09-26 wind-down snapshot that stood here (44 of 107, per-lane PR handoffs) is superseded and lives in Git history.
