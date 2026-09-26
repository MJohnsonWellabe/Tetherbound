# Coordinator tooling: the Acceptance Board and lane scans

This is what the integration coordinator used to track ACCEPTANCE §6.1, so a later session can pick it up and keep building. It is evidence and tooling, not a status document. `docs/STATE.md` stays the handoff; this folder is what regenerates the board.

## Acceptance Board

The board is published as a private claude.ai artifact: https://claude.ai/artifact/XYqEQ3ifDhZJUmNdbYrDem (owner account).

| File | Role |
|---|---|
| `dashboard/criteria.json` | Scoring data. The key is `rows[]`, one per F-row (F01 to F15). Each row has `criteria[]` holding `text`, `status` (`met` / `partial` / `in_progress` / `not_started` / `failing` / `blocked`), `evidence`, `gap`, and an optional `note`. Criteria are numbered from zero within a row: `F04#7` is `rows[F04].criteria[7]`. |
| `dashboard/status.json` | The coordinator's notes: `headline[]` (the first line reads "Criteria met: N of 107 …"), `batches[]`, `lanes[]`, `decisions`, `owner_needs[]`. |
| `dashboard/build_dashboard.py` | Renders both JSON files into `dashboard/tetherbound_dashboard.html` (a self-contained page; paths are relative to the script). |
| `dashboard/tetherbound_dashboard.html` | The last rendered page (2026-09-26 18:25 UTC). |

To rebuild and republish:
1. Edit `criteria.json` only for criteria that actually moved. The scoring rule:
   - a criterion is MET when the batch holding its evidence merged to main after a green full CI run on that PR, with only docs or workflow-only files landing on main in between;
   - verify the lane's evidence at its SHA yourself before counting it.
2. Update `status.json` (headline, batches, lanes, owner needs).
3. Run `python3 ralph/reports/COORDINATOR/dashboard/build_dashboard.py`.
4. Republish the HTML with the Artifact tool, passing `url: https://claude.ai/artifact/XYqEQ3ifDhZJUmNdbYrDem` so the link stays the same. A new session must pass the URL; publishing without it creates a separate artifact.
5. Commit the updated JSON and HTML back here in the next docs batch, so the data never lives only in a container.

## Lane scans

- **`ready.py`:** lists every `READY FOR INTEGRATION: <branch> <sha>` line posted in PR comments since yesterday 12:00 UTC, and reports whether each SHA is on main (PENDING or MISSING otherwise). It uses `$GITHUB_TOKEN`; run it from the repository root.
- **`lanes.py <saved list_sessions output>`:** summarizes each lane's status, last update and status detail.

## State at wind-down (2026-09-26)

- **Met:** 44 of 107.
- **Batch 25 (#283):** the final combined batch of every lane's READY work.
- **Lane handoffs:** each lane's `## HANDOFF (final)` comment on its PR, as follows:

  | Lane | PR |
  |---|---|
  | Meadows core | #270 |
  | F05 | #257 |
  | Cloudreach | #253 |
  | Stormwood | #250 |
  | Tidewake | #226 |
  | Art X04 | #248 |
  | X05 | #282 |
  | X03 | #262 |
  | VIS | #279 |
