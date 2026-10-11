# F46#1 — at every gate a new player can state the next goal — FAIL (Meadows→Tidewake gate)

systems-a, Sun 11 Oct 2026, observations 12:47–1:08 PM CT on 4f0c3ce6; verdict 1:10 PM CT.

Method (disclosed; a full agent-piloted fresh run is out of reach on this host): `tests/smoke_f46_next_goal_boundaries.gd -- --profile=<p>` loads a disclosed generated boundary profile. At chapter exits it plays the ordinary gate (Home Key, Shrine Room hang, arch). `f20_portal_travel.observe_next_goal` records the journal, HUD and hint after each step (`observations.jsonl`). An independent code-blind judge (subagent, text only) then gave the verdict.

| Gate | On-screen goal | Judge |
|---|---|---|
| Upper Meadows (sigils) | "Defeat the Upper Meadows captains. 0/3"; hint names Oreth/riverwatch (hint truncated) | PASS (fix truncation) |
| Meadows→Tidewake (team at L20 cap, holding the Tidewake key): arrival, after Home Key, after relic hang | "Challenge Mira Emberlane for the L20 feast recipe." in all three; hint repeats it | **FAIL**: no where, never updates, the held key is never mentioned |
| Tidewake→Cloudreach: arrival/home/hang | "Use your Cloudreach key at its signed arch in the Crossing Hall." | PASS |
| into Cloudreach | "Enter Cloudreach and find the waycamp." / "Follow the rising road…" | PASS |
| Cloudreach→Stormwood: arrival/home/hang | "Use your Stormwood key at its signed arch…" | PASS |
| into Stormwood | "Find Ashfoot Waycamp." / "Follow the Struck Sentinel north…" | PASS |

Cause: `scripts/onboarding/lesson_rules.gd::guidance()` ranks a capped Master ahead of an unused portal key. The Master line carries goal_realm/goal_at for the beacon but no place name in the text. Proposal (a design call, not changed here): track the key with Mira as a secondary line, or keep Mira and name her place in the text.

Not observed: early Meadows gates; the relay profile failed its own fixture pose guard; the Meadows→Tidewake arch entry (an interaction-provider contention in the helper); Tidewake/Cloudreach/Stormwood mid-chapter gates; the ending gate; co-op views; device readability.

Verdict: FAIL
