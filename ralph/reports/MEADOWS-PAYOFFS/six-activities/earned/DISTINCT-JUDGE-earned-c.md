# F03#1 distinct optional action: code-blind judge, earned save, set C (all six)

Set C re-judges all six activities together, after the strict re-check found that set A's Hall row had been judged on frames from a superseded local render.

- **Judge input:** the 24 frames in `distinct-c/` plus the six ledger action lines (WORLD §11). No code, data, config, docs or other reports were opened.
- **Hall frames:** from recorded render.yml run 36289584698 at e315d4ca.
- **Other frames:** identical to sets A and B.

| activity | matches ledger | distinct from nearest | overall |
|---|---|---|---|
| herd | PASS | PASS (nearest: juno) | PASS |
| bram | PASS (weak: forest, not "eastern fields") | PASS (nearest: hall) | PASS |
| doss | **FAIL**: the repair is shown, but the wood/fiber payment is never visible, and no river is in frame | PASS (nearest: herd) | **FAIL** |
| juno | PASS (the patrol fight is shown only as its result toast) | PASS (nearest: bram) | PASS |
| hall | PASS (off-road/Hall-approach site not confirmable) | marginal PASS (nearest: vault) | PASS (weak) |
| vault | **FAIL**: the required guardian, the vault light beyond it and the branch choice are not visible | **FAIL** (nearest: hall, same wild-fight template on screen) | **FAIL** |

**Result: 4 of 6 pass. F03#1 is NOT closed on this evidence.** A stricter judge overturned the set A and B passes for vault and Doss.

## Follow-up (this lane)

- **Doss:** the walker now opens the Satchel before and after the repair (wood/fiber counts on screen). It also frames the perch from the east stand, where the river channel runs behind it. The thanks line now names the payment: "Your wood braced the boards and your fiber lashed them."
- **Vault:** the walker now frames the den looking down the branch passage to the lit vault, then the passage itself, before the Elder fight.
  - The required guardian cannot appear from `seed4_hall`. The chain's `warrens` segment beat it in play (`receipts/warrens.json`: `warrens_cleared`), and a cleared Warrens spawns no guardian.
  - The judge brief states that start-state fact.

Other judge notes, not criterion failures:
- the vault Trailpup's defeated body renders as a smear (visual; Codex queue);
- hall/vault template similarity;
- Juno's patrol not shown mid-fight;
- Bram's Lv6–7 team;
- the team panel reads as duplicated species.
