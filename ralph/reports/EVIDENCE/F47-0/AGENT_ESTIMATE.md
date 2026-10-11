# F47#0 agent half — route estimate (systems-b, Sun 11 Oct 2026, 4:55 PM CT)

Sources: route receipts on tb/ev-{meadows,tidewake,cloudreach,stormwood}-route (`tests/fixtures/earned_saves/*/receipt.json`, `simulated_seconds` at 1x/60 Hz); home-key `F47-0-estimate.md`; `tools/f27_route_ledger.mjs`; PROGRESSION §4. No new runs; arithmetic only.

| Part | Hours | Basis |
|---|---|---|
| Cloudreach required path (measured) | 0.85 | pieces 01–07 = 3,042 s sim (1,825 s passing pieces + 1,217 s failed 05 attempt); 06–07 from a generated L40 boundary |
| Other three chapters' required path (scaled) | 2.9 | not measured in sim time; Cloudreach × PROGRESSION weights 5 : 3.5 : 3.5 (Meadows : Tidewake : Stormwood vs Cloudreach 3.5) |
| Required path, four chapters | **≈3.8** | 0.85 × 15.5/3.5 |
| Optional loop budget | 4.0 | f27 ledger GRIND_HOURS = 1 per band (wild refights, alphas, catch/release, crops, bounties) |
| Optional activities (6–10 per chapter) | ≈5.3 | UNMEASURED; assumed 10 min each × 8 × 4 (f27 bounty minute rate) |
| **Honest total** | **≈7.8 measured + budget; ≈13 with assumed activity time** | |

Cross-checks: Tidewake headless wall time 2,097 s for 01–05 + 08 (host speed, not play time); Meadows opening piece world clock 1,074 s (one piece of ~10). Stormwood has no completed piece.

Gaps: Meadows/Tidewake/Stormwood have no simulated-time route receipts; no optional activity, Master loop (duel → chest → cook → feed) or home-visit time is measured; the agent pilots at fixed speed with no exploration, reading, deaths or menus.

Verdict: NOT CONFIRMED on the agent half. The agent estimate is ≈8–13 h, below the 15–25 h target. Human play would need 1.2–3× the agent pace to land in range. The owner's playtest decides; if it also runs short, PROGRESSION §4 says deepen preparation choices rather than pad.
