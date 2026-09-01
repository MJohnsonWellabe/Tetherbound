# Owner playtest — 2026-09-01

Recorded verbatim from the owner's own play session, relayed through the coordinator. Per `CLAUDE.md`'s precedence rules, this outranks every other doc in the repo for what it covers, and a fresh owner reproduction reopens any item an old `DONE.md` entry claims is fixed.

Session length: roughly 30 real-world minutes.

## Findings, in the order given

1. **Knife not visible in hand.** Equipped but not rendering/attached.
2. **Severe lag — frame rate collapsed to ~10 FPS.** Owner's own hypothesis: the map (minimap?) re-rendering every step. Called a **game breaker**.
3. **Interact button works about half the time.** Called a **game breaker**.
4. **Still no way for a person to sleep.** (Distinct from creature bed rest — this is the player's own sleep action.)
5. **Village gate needs to open on every road out of the village**, not just one.
6. **Still too many people in the village.** (A repeat complaint — flag: `BACKLOG-E1-VILLAGE-DAYTIME` landed today and added a "few more idle NPCs" as part of fixing the opposite complaint, daytime emptiness. Check whether that fix overshot before just cutting NPCs blindly.)
7. **Still unclear how to train a team.** No clear guidance on what training is or how to do it.
8. **Bond system is not legible.** "It just goes up. It needs to be a task." Requested redesign: discrete milestones instead of a continuous meter, e.g. defeat 50 wild creatures together (0→1), visit \[somewhere] (1→2), travel X miles (2→3). The owner left the second milestone as "whatever" — a placeholder, not a locked spec.
9. **Creatures don't lie down in bed except galecrest.** All other species stand/pose wrong on the creature bed. (Matches an already-flagged, still-open visual-census finding: `BACKLOG-VISUAL-BED-FITS-CREATURE`, itself noted as still failing after `BACKLOG-BED-SCALE-POSE`'s earlier attempt.)
10. **Priority order, in the owner's own words:** "Interact and lag are the two game breakers right now. Then not knowing how to train or what we're supposed to do at that point."
11. **Day/night cycle is broken.** `day_length_seconds` is configured at 600 (10 real minutes). Owner played ~30 real minutes and the day counter stayed on "Day 1" the entire time, then reset back to 0. Night also falls at what reads as a random time, not tied to the configured cycle. **This is likely one root cause behind several already-open findings** — the visual census's `BACKLOG-VISUAL-CLOCK-VS-SKY` finding ("the clock reads Day 1 · 00:00 — midnight — over a bright midday sky") already flagged this exact family of symptom as "very likely the same root cause as owner playtest items 9/18/22/23" from the prior (2026-08-30) playtest. Treat as the same open defect, now confirmed by a second independent play session.
12. **Tournament entry requirement:** lower `min_level` from 6 to 5. Also: Halda's guidance dialogue must stop saying vague "train" and instead say explicitly what to do — feed your creatures, rest your creatures, get to level 5.

## Coordinator triage

Dispatched same-day as three tiers:
- **Tier 1 (game breakers + likely-systemic bug):** interact reliability, performance/lag, day-night cycle.
- **Tier 2 (bounded content/UX fixes):** knife visibility, player-sleep flow, village multi-road gate, village population thinning (checked against the E1 collision above), train-clarity guidance, tournament level+dialogue change, creature-bed lie-down pose.
- **Tier 3 (design/systems work):** bond milestone redesign.

See `ralph/reports/audit/BACKLOG-FROM-AUDIT-2026-08-31.md` and the coordinator's own dispatch log for branch names as they land.

## Correction — 2026-09-01, same-day

The first dispatch on item 5 (`OWNER-0901-VILLAGE-GATE-ROADS`) reported "all exit roads have gates; no code change needed" without pushing a branch or any evidence artifact — a config read, not a played/probed check. The owner then played again and found this wrong directly:

> "village gate should exist on every road out of the village. other than in those spots you shouldn't be able to jump the gate. I can still jump it some places and there no gate on at least one of the roads."

Two distinct defects, both confirmed by direct play, both reopening the closed item per `CLAUDE.md`'s rule that a fresh owner reproduction reopens a supposedly-fixed item:

1. **At least one road out of the village has no gate at all.** `data/config/village_boundary.json`'s `gates` block currently defines exactly two: `RoadGate` and `PondGate`. Its own comment says the intent is "a leaf wherever an authored road crosses the line, so no road in the village dead-ends at a fence" — so if more than two roads cross the boundary, this was never actually satisfied.
2. **The boundary can still be jumped/walked around in places other than the gates.** This is the same class of defect a 2026-08-30 owner playtest already found and fixed once (see `village_boundary.json`'s own `_why` note: nine of sixteen bearings were walkable clear of the village before that fix, using `tools/_probe_village_gate_escape.gd` and `tools/_probe_village_layout.gd`). Either that fix has a remaining gap, or something landed since has reopened it.

Redispatched as `OWNER-0901-VILLAGE-GATE-ROADS-V2` with a stricter brief: use the existing probe tools (proven methodology, don't reinvent), actually map every road crossing the boundary, and require pushed evidence before any "nothing to fix" conclusion is accepted again.
