# Coordinator tooling: the Acceptance Board and lane scans

This is what the integration coordinator used to track ACCEPTANCE §6.1, so a later session can pick it up and keep building. It is evidence and tooling, not a status document. `docs/STATE.md` stays the handoff; this folder is what regenerates the board.

## Acceptance Board

The board is published as a private claude.ai artifact: https://claude.ai/artifact/XYqEQ3ifDhZJUmNdbYrDem (owner account).

| File | Role |
|---|---|
| `dashboard/criteria.json` | Scoring data. The key is `rows[]`, one per F-row (F01 to F15, plus the redesign rows F16 to F49 added 2026-09-29, whose `chapter` field holds the wave name and `lane` the owning lane). Each row has `criteria[]` holding `text`, `status` (`met` / `partial` / `in_progress` / `not_started` / `failing` / `blocked`), `evidence`, `gap`, and an optional `note`. Criteria are numbered from zero within a row: `F04#7` is `rows[F04].criteria[7]`. |
| `dashboard/status.json` | The coordinator's notes: `headline[]` (a line reads "Criteria met: N of 280 …"), `batches[]`, `lanes[]`, `decisions`, `owner_needs[]` and `wip[]`, the pickup list for unfinished work. |
| `dashboard/build_dashboard.py` | Renders both JSON files into `dashboard/tetherbound_dashboard.html` (a self-contained page; paths are relative to the script). |
| `dashboard/tetherbound_dashboard.html` | The last rendered page (2026-09-26 18:25 UTC). |

To rebuild and republish:
1. Edit `criteria.json` only for criteria that actually moved. The scoring rule:
   - a criterion is MET when the batch holding its evidence merges to main with a passing independent strict re-check (owner, 2026-09-27). The full CI run after each batch is a safety net: if it goes red, that batch's criteria return to landing until the fix lands (WORKFLOW §8);
   - verify the lane's evidence at its SHA yourself before counting it.
2. Update `status.json` (headline, batches, lanes, owner needs).
3. Run `python3 ralph/reports/COORDINATOR/dashboard/build_dashboard.py`.
4. Republish the HTML with the Artifact tool, passing `url: https://claude.ai/artifact/XYqEQ3ifDhZJUmNdbYrDem` so the link stays the same. A new session must pass the URL; publishing without it creates a separate artifact.
5. Commit the updated JSON and HTML back here in the next docs batch, so the data never lives only in a container.

## Lane scans

- **`ready.py`:** lists every `READY FOR INTEGRATION: <branch> <sha>` line posted in issue/PR comments since its hard-coded start time, and reports whether each SHA is on main (PENDING or MISSING otherwise). Lanes now post READY/FINAL on Lane channel issue #356; update the start time before use. It uses `$GITHUB_TOKEN`; run it from the repository root.
- **`lanes.py <saved list_sessions output>`:** summarizes each lane's status, last update and status detail.

## Hourly rebuild (redesign)

The owner asked for the board to be rebuilt every hour during the redesign build. Whichever lane holds board duty (CODEX_START_HERE §4, §7.3) refreshes `status.json`, runs the builder, and lands JSON plus HTML through a small docs PR. It also republishes to the URL above when the Artifact tool is available. The builder groups every row outside F01–F15 by its wave.

## Current state

STATE §0 holds the current counts, card results and open owner decisions; `dashboard/status.json` `wip[]` is the pickup list. The 2026-09-26 wind-down snapshot that stood here (44 of 107, per-lane PR handoffs) is superseded and lives in Git history.
