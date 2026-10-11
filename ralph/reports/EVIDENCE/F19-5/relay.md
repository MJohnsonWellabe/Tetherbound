# F19#5 Meadows piece `relay`: PASS (meadows-route-b)

- **Run:** 2026-10-11, about 12:35–12:57 PM CT, Godot 4.7 headless. Source `f95357a2` (exact clean commit; the runner checks this).
- **Command:** `godot --headless --path . --script tools/earned_saves/earned_chain_runner.gd -- --segment=relay --generated-fixture --save-dir=<root>/relay/save --receipt=<root>/relay/receipt.json`
- **Result:** `passed: true`, no failures, wall time 1358 s.
- **Beats:**
  - Vance beaten.
  - Captive freed; Mill Gear gained.
  - Relay console disabled: lit 18 → 0.
  - Mill crossing restored: gear 1 → 0, depth 9.47.
  - The earned five are retained.

**Disclosures**
- **Input is a generated fixture**, per the owner policy in the profile. It is the `relay` profile: the post-Warrens five at L15, healed, day 5. No earned play precedes it.
- **Pose alignment** (pre-approved stale-literal alignment):
  - The profile reused the template save's pose at Warrens local (0, −6.1), which is now inside the OWNER-0912 rebuilt approach. The capsule wedged against a bank StaticBody (normal local +z), never grounded, and the runner's ground-pose guard refused.
  - An intermediate try at local (0, −12) failed the same way.
  - The pose is now `ground_xz` (−339.32, 2592.32). That is local (0, −25), the far-ruts start `tests/smoke_warrens.gd` itself uses.
  - Commits `f70ddeb9`, `f95357a2`.
- **Receipt and save** are kept outside the repo in the lane's scratch area.
