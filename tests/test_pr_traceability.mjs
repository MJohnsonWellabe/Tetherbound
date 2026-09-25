import assert from "node:assert/strict";
import test from "node:test";
import { validatePullRequest } from "../tools/check_pr_traceability.mjs";

const body = `## Lane
Bug

## Anchor
docs/design/WORLD.md §2.3 at abc123; A10 on current main.

## Evidence
| Criterion | Named proof | Expected | Observed |
|---|---|---|---|
| A10 | tests/smoke_legendary.gd, run 123 | each participant gets an offer | pass on abc123 |

## Independent review
Reviewer: separate review agent
Result: pass
`;

test("ready PR has a lane, spec anchor, named evidence and independent review", () => {
  assert.deepEqual(validatePullRequest(body), []);
});

test("draft PR can collect evidence before independent review", () => {
  assert.deepEqual(validatePullRequest(body.replace("Result: pass", "Result: pending"), true), []);
});

test("empty proof and self-reported pending review cannot pass", () => {
  const broken = body.replace("tests/smoke_legendary.gd, run 123", "TBD")
    .replace("Result: pass", "Result: pending");
  const errors = validatePullRequest(broken);
  assert.ok(errors.some(error => error.includes("Evidence row")));
  assert.ok(errors.some(error => error.includes("review result")));
});

test("maintenance without an anchor cannot masquerade as a feature", () => {
  const broken = body.replace("Bug\n", "Task\n").replace("docs/design/WORLD.md §2.3 at abc123; A10 on current main.", "none");
  assert.ok(validatePullRequest(broken).some(error => error.includes("Anchor")));
});
