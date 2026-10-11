# F46#1 — at every gate a new player can state the next goal — PASS (observed gates)

systems-a, Sun 11 Oct 2026. Observations on 4f0c3ce6 (12:47–1:08 PM CT) and after the fix on 4e9be6c6 (1:12–1:16 PM CT); final verdict 1:17 PM CT.

Method (disclosed): `tests/smoke_f46_next_goal_boundaries.gd -- --profile=<p>` loads a disclosed generated boundary profile and plays the ordinary gate (Home Key, Shrine Room hang, arch). `f20_portal_travel.observe_next_goal` records journal/HUD/hint text (`observations*.jsonl`). An independent code-blind judge (subagent, text only) gives each verdict.

| Gate | On-screen goal | Judge |
|---|---|---|
| Upper Meadows | "Defeat the Upper Meadows captains. 0/3" + full hint naming Oreth/Halder/Vess and the sigils | PASS |
| Meadows→Tidewake (L20-capped team, Tidewake key held): arrival / after Home Key / after hang | "Challenge Mira Emberlane at Ironwood Ridge for the L20 feast recipe." + "Then: Use your Tidewake key at its signed arch in the Crossing Hall." | PASS (minor: at home it doesn't say "return to the Meadows") |
| Tidewake→Cloudreach (arrival/home/hang/arch) | "Use your Cloudreach key at its signed arch…" → "Enter Cloudreach and find the waycamp." | PASS |
| Cloudreach→Stormwood (arrival/home/hang/arch) | "Use your Stormwood key at its signed arch…" → "Find Ashfoot Waycamp." | PASS |

Fix (coordinator-approved UX guidance, 4e9be6c6). `lesson_rules.guidance` keeps its order, but:
- the capped-Master line names the place (from the Master's `author_reference` site id);
- a held next-realm key rides as the hint/journal "how" line.

Before the fix the gate showed only "Challenge Mira Emberlane for the L20 feast recipe." and the judge FAILED it. Units: `test_onboarding_lesson_triggers` + `test_quest_log` 49 tests / 1153 assertions, 0 failed.
Correction: the "truncated" Upper Meadows hint in the first pass was my own 70-character clipping; the game's hint is complete.

Not observed: early Meadows gates (the relay profile fails its own fixture pose guard); the Meadows→Tidewake arch entry itself (helper provider contention); mid-chapter gates in Tidewake/Cloudreach/Stormwood; the ending gate; co-op views; device readability.

Verdict: PASS for the observed gates (scope above)
