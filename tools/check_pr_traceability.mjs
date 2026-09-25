#!/usr/bin/env node

// A cheap PR gate for WORKFLOW §1.1. It checks that a claim has an anchor and
// named proof. Whether the proof actually exercises the criterion is the
// independent agent review, not something a Markdown parser can establish.
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const LANES = new Set(["Feature", "Bug", "Task", "Hotfix"]);
const PLACEHOLDER = /\b(?:TBD|TODO|pending|none|n\/a|fill this in|replace me)\b|<[^>]+>/i;

function section(body, title) {
  const escaped = title.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = body.match(new RegExp(`^## ${escaped}\\s*\\r?\\n([\\s\\S]*?)(?=^## |$(?![\\s\\S]))`, "mi"));
  return match?.[1]?.trim() ?? "";
}

function substantive(value) {
  return value.length > 0 && !PLACEHOLDER.test(value);
}

export function validatePullRequest(body, draft = false) {
  const errors = [];
  const lane = section(body, "Lane").split(/\r?\n/)[0]?.trim() ?? "";
  if (!LANES.has(lane)) errors.push("Lane must be Feature, Bug, Task or Hotfix.");

  const anchor = section(body, "Anchor");
  if (!substantive(anchor)) errors.push("Anchor must cite the settled spec/criterion or maintenance rule.");

  const evidence = section(body, "Evidence");
  const rows = evidence.split(/\r?\n/).filter(line => /^\|/.test(line.trim()));
  const dataRows = rows.filter(line => !/^\|\s*:?-+:?\s*\|/.test(line.trim())).slice(1);
  if (dataRows.length === 0) errors.push("Evidence needs at least one criterion-to-proof table row.");
  for (const [index, row] of dataRows.entries()) {
    const cells = row.split("|").slice(1, -1).map(cell => cell.trim());
    if (cells.length !== 4 || cells.some(cell => !substantive(cell))) {
      errors.push(`Evidence row ${index + 1} needs criterion, named proof, expected and observed result without placeholders.`);
    }
  }

  if (!draft) {
    const review = section(body, "Independent review");
    const reviewer = review.match(/^Reviewer:\s*(.+)$/mi)?.[1]?.trim() ?? "";
    if (!substantive(reviewer)) {
      errors.push("A ready PR needs a named independent reviewer.");
    }
    if (!/\bresult\s*:\s*pass\b/i.test(review)) {
      errors.push("A ready PR needs an independent review result of pass.");
    }
  }
  return errors;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const eventPath = process.env.GITHUB_EVENT_PATH;
  if (!eventPath) {
    console.error("GITHUB_EVENT_PATH is required.");
    process.exitCode = 2;
  } else {
    const event = JSON.parse(readFileSync(eventPath, "utf8"));
    const errors = validatePullRequest(event.pull_request?.body ?? "", Boolean(event.pull_request?.draft));
    for (const error of errors) console.error(error);
    if (errors.length) process.exitCode = 1;
    else console.log("PR lane, anchor, proof mapping and independent review are recorded.");
  }
}
