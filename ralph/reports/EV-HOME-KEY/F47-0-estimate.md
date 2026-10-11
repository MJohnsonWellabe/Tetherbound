# F47#0 agent half: clear-time estimate from route receipts (disclosed method)

`tools/f47_capture_route.gd` only records a human playing the real title ("never a fixture, teleport or
automatic pilot"), so this lane cannot make a headless full-campaign capture. Instead, measured agent-piloted
game time is summed from receipts.

| Chapter | Source | Agent game time (simulated s) |
|---|---|---|
| Cloudreach (pieces 01–07) | tests/fixtures/earned_saves/cloudreach_0*/receipt.json, F19-5-cloudreach/05_stronghold.receipt.json | 196 + 566 + 533 + 142 + 1217 + 388 + 0 = **3,042 s (50.7 min)** |
| Cloudreach (one continuous run) | F06#0 witness run today, arrival → Warden Aila | 2,771 s (46.2 min) |
| Tidewake (01–05) | tidewake_0*/receipt.json | wall time only (2,052 s headless); no simulated time recorded |
| Meadows, Stormwood | F19-5 / F19-5-stormwood | chains incomplete; no total |

**Method.** Assume the four chapters' critical paths are comparable to the one fully measured chapter, Cloudreach:
4 × 46–51 min ≈ **3.1–3.4 h** of agent game time. The agent route skips exploration, optional
activities (ACCEPTANCE asks for 6–10 per chapter), reading dialogue, menus and homestead
management, deaths and retries, and optional grinding.

**Estimate.** A 15–25 h human clear implies human play takes 4.4–8× the agent's critical-path time. That is
plausible for a first, ordinary clear, but this lane cannot measure that ratio.
**Verdict: not confirmed by the agent half.** The measured floor is about 3.3 h of required-route play.
The owner's play pass (F47#0's second half) decides the range.
