# F47#0 agent half — route estimate, v2 (systems-b, Sun 11 Oct 2026, 5:10 PM CT)

Raw agent sim time; no human-pace multiplier. Labels: **M** measured sim (60 Hz), **W** wall÷2.9 (Cloudreach's wall/sim ratio) as low with raw wall as high, **D** derived, **S** scaled from Cloudreach per-piece sim (304–435 s/piece), **B** design budget.

| Chapter (required path) | Low–high h | Basis |
|---|---|---|
| Meadows | 1.06–1.38 | opening piece 1,074 s world clock (M, meadows-route receipt) + 9 unmeasured pieces (S) |
| Tidewake | 0.29–0.70 | pieces 01–05, 08: 2,097 s wall (W; its fights alone are 607 s M) + piece 07 (S) |
| Cloudreach | 0.51–0.84 | pieces 01–07: 1,825 s passing … 3,042 s incl. the failed 05 attempt (M) |
| Stormwood | 0.68–0.97 | no completed piece; 8 pieces (S) |
| **Required path** | **2.5–3.9** | |
| 5 Master cycles | 0.35–0.37 | duel 464–1,242 frames = 8–21 s each (M, F28-4 master_t1); detour nearest waystone → Master and back, 2·d·1.3 ÷ 8.6 m/s sprint = 1,219 s total (D); chest/cook/feed not measured: `smoke_net_f28_feast` failed twice on this host (production_host heartbeat silence), so it was stopped |
| Gear (4 tiers × 5 × Harness+Charm) | ≈0.04 | ~100 refines × 1.53 s channel (M, `smoke_f32_forge_plates`, 494 frames for 4 units); materials come from the route/grind rows |
| Optional activities 24–40 (6–10/chapter) | 1.9–4.2 | on-site: Warrens walk 4,802 frames = 80 s (M, `smoke_warrens`); optional Aquaryn fight 37.8 s (M, tidewake receipt); approach 250–300 s each (D, as Masters). `smoke_cloudreach_activity_rewards` = 79 frames (state-only, not representative) |
| Optional loop | 4.0 | f27 ledger GRIND_HOURS = 1 per band (B) |
| **Total** | **8.8–12.5 h** | |

Measurement commands: smokes run with `godot --headless --fixed-fps 60 --print-fps` (frames summed); the network check counts come from the evidence `net-checks.txt`. No new harness, no test edits.

Gaps: Meadows, Tidewake and Stormwood have no sim-time route receipts. Master chest/cook/feed time is not measured. Only one optional activity type (world/route) was walked; the care type (crops, Den) is unmeasured. The agent pilots without exploration, reading, deaths or menus.

Verdict: NOT CONFIRMED. Raw agent sim time is 8.8–12.5 h, below 15–25 h, even with the Master and gear loops counted. The Master and gear loops add under 0.5 h of agent time. Per PROGRESSION §4, the lever is deeper preparation choices, not padding; the coordinator decides. The owner's playtest is the final check.
