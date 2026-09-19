# Cloudreach 0919 — preapproval checkpoint results

Status: plan submitted; approval pending. This checkpoint does not complete visual production.

- Base: c05c724740b1111b693fb87da72b182934a5232d. Plan initially committed and pushed as 8b437e5ef3d6b8cb33018a19ade98d0afeb3a0a2 on ralph/cloudreach-visual-production-0919. Draft PR: https://github.com/MJohnsonWellabe/Tetherbound/pull/129.
- Isolated worktree: D:\tetherbound\cloudreach-0919. Existing Meadows/source worktrees unchanged. Checkout inherited sparse rules; report files require exact staging with git add --sparse.
- Investigation found existing coverage-mask shaders, trail endpoint fades, 96 clustered banks, and spatially varied cliff strata. The plan now explicitly calls for validating retained work before residual repairs.
- Evidence discrepancy: committed BROAD-VISUAL-0911/CLOUDREACH-NAMED-LOCATION-LEDGER.md has 0/5/7, but the full-game handoff has 0/10/2. Neither is promoted to a newly verified count. Later per-location receipts still require reconciliation.
- Candidate validation seams: tests/test_cloudreach_atmosphere.gd, test_cloudreach_environment.gd, test_cloudreach_cliff_strata_contract.gd, test_cloudreach_route_verges.gd, affected named-location tests, and smoke_cloudreach_look/ground_truth/fall_recovery. The strata test is source-string based and cannot prove visual quality; production review remains mandatory.
- Validation performed: read-only Git/source inspection and git diff --cached --check on the initial plan. No Godot imports, tests, exports, screenshots, played path, or independent visual review were run. No shipping-build parity or visual improvement is claimed.
- Ledger delta: none. Gameplay/source changes: none. Generation spend: none.
- Render lock was absent when inspected; it was not acquired or changed because no capture was attempted. Every future capture must freshly check and acquire it, with Meadows priority.
- PLAN-APPROVED.md was absent from fetched main and lane refs at the last check. Substantive implementation remains held under the owner's September 19 directive. Continue low-risk evidence/consumer investigation and resume dependent work only after reading the approval.

## Approval-path check and read-only continuation

The next owner message pointed to MEADOWS-0919/PLAN-APPROVED.md. A fast-forward pull of this Cloudreach branch reported already up to date at 9dd79413. The referenced approval exists on codex/all-branches-integration-0913 at d3fd668b, and explicitly authorizes the Meadows village-passage harness repair with "No Cloudreach, Stormwood, or Water work." Neither lane approval file exists on this Cloudreach branch. Clarification requested because the named receipt does not approve this plan; no substantive implementation started.

Read-only findings for continuation:

- `_path_ribbon` lowers both mesh ends regardless of `fade_start`/`fade_end`; route sections end at landing-cap edges. Test actual generated geometry and production visibility before deciding whether this breaks the intended continuous wear surface.
- `cloudreach_ground_cover.gd` overrides proportional grass width with an independent 1.6–2.3 scale. Trace shared tuft dimensions before replacing this with the required low/medium/sparse-tall role system.
- Cloud banks already use deterministic related lobes and a lit shaded-base shader. Night exposure and bank/sheet continuity still need production evidence, not another presumed rebuild.
- Read-only delegated evidence audit found explicit later POLISH reports for Flight Aerie (PR121), Sky Shrine (PR122), High Perches (PR123), and Old Wind Observatory (PR124). Starting from the committed 0/5/7 ledger, those four rows would yield 0/9/3. The full-game handoff's 0/10/2 still requires locating a later independent Broken Skyroad Arch promotion; retained ledger evidence for that row ends at FAIL. This remains a provisional evidence crosswalk, not a ledger edit.
- PR124's cliff-strata blind PASS applies to that bounded shared candidate only, not named locations or biome acceptance.

No game files, collision, gameplay, screenshots, tests, or grade claims changed during this continuation. Git/documentation inspection only.
