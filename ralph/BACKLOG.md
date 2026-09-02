# Backlog

**Rewritten from scratch, 2026-09-01, on owner directive: "all these backlogs
are wrong... the Ralph ones should be gone. they're not relevant anymore."**
**Reordered 2026-09-02 after a fresh owner playtest reopened three same-day
"landed" fixes and added new findings.**

The previous `BACKLOG.md` (4,069 lines back to 2026-08-15) and `BLOCKED.md`
(1,228 lines of parked decisions) are deleted, not archived elsewhere — their
substance either shipped, was superseded, or wasn't worth carrying forward.
`ralph/DONE.md` still holds the shipped-work archive if a specific old item's
history is ever needed; git history holds the rest.

**What belongs in this file:** the most recent owner playtests, Gate F's
current state, and the small number of visual-review items an independent
check actually confirmed matter — not a re-derivation of the 168-item visual
census, which stays a historical report
(`ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md`) rather than a backlog.

---

## 1. Owner playtest, 2026-09-02 — the current priority

`ralph/OWNER_PLAYTEST_2026-09-02.md` is the full verbatim record. Real,
current, and — per `CLAUDE.md`'s precedence rules — outranks everything else
in this file. Not yet triaged into fix sessions.

**Three same-day "landed" fixes from the 09-01 playtest are now confirmed
still broken by direct play** — treat these as the standing lesson that
"landed" and "confirmed" are different states, not as three isolated misses:

| finding | landed as | now |
|---|---|---|
| Village gate on every exit | `OWNER-0901-VILLAGE-GATE-ROADS-V2` (`5b934766`) | **reopened** — still missing on at least one exit |
| Village population too high | `OWNER-0901-VILLAGE-POPULATION` | **reopened** |
| Day/night cycle | `OWNER-0901-DAYNIGHT-CYCLE` | **reopened, and worse** — dark no longer reaches real night (stays dusk), and the day counter now cycles Day 2 → Day 2 instead of Day 2 → Day 3 |

**New findings, roughly by severity:**

- **Likely one coupled root cause, investigate together, don't fix in isolation:** the day/night regression above, "can't place the tent and campfire," and "creatures never get out of bed / never appear rested" — the owner explicitly doesn't know which of the first two is causing the third. Check whether a broken day-advance is why rest never completes, or whether it's blocked on the camp build failing, before writing three separate fixes.
- **Catching**: not "too hard" in the abstract (the 08-30 playtest's version of this was investigated and found to be a measurement artifact — real throws worked fine) — the owner now says specifically that **aiming at the creature is the hard part**, and asks for creatures to move less, or in slow motion, once catch mode opens. This is a concrete feature request, not a rebalance.
- **Load time** — "the game took forever to load."
- **Grass didn't render** — possibly `OWNER-0901-PERFORMANCE-LAG-V2`'s grass-disable working as designed rather than a new defect; needs a call on whether that tradeoff is acceptable or a cheaper grass path is needed.
- **Village layout**: characters read too small now; shape still doesn't make sense especially around Grandpa's house; Mira is hidden inside a house instead of being findable.
- **UI**: team menu overruns the food bar (move food bar down by the health bar); team menu sometimes renders twice after a fight, and the duplicate doesn't always show the full team.
- **No rest-progress indicator** — nothing tells the player how long a resting creature has left.

---

## 2. Owner playtest, 2026-09-01 — remaining items, still unconfirmed

`ralph/OWNER_PLAYTEST_2026-09-01.md` is the full record. Of twelve dispatched
same-day fixes, three are now confirmed broken again (§1 above). The other
nine have not been re-checked by real play either — treat all of them as
"believed fixed," not fixed, same as the three that already failed that test:

| # | finding | landed as |
|---|---|---|
| 1 | Knife not visible in hand | `OWNER-0901-KNIFE-VISIBILITY-V2` |
| 2 | Severe lag, ~10 FPS — **game breaker** | `OWNER-0901-PERFORMANCE-LAG-V2` |
| 3 | Interact works ~half the time — **game breaker** | `OWNER-0901-INTERACT-RELIABILITY-V2` |
| 4 | No way for the player to sleep | `OWNER-0901-PLAYER-SLEEP` |
| 7 | Unclear how to train a team | `OWNER-0901-TRAIN-CLARITY` |
| 8 | Bond system illegible, wants discrete milestones | `OWNER-0901-BOND-MILESTONES` |
| 9 | Creatures don't lie in bed except galecrest | `OWNER-0901-CREATURE-BED-POSE` (bed roster-fit landed separately, §3) |
| 12 | Tournament `min_level` 6→5, Halda's guidance made concrete | `OWNER-0901-TOURNAMENT-LEVEL5` |
| — | Small creatures disappear into grass | `OWNER-0901-CREATURE-GRASS-VISIBILITY` |

**The village-gate lesson stands as recorded history:** the first dispatch on
that finding claimed "nothing to fix" from a config read with no pushed
branch or run probe — wrong, as the owner found by playing, and as §1 above
now shows again from a second angle. A "nothing to fix" conclusion needs
evidence behind it every time, not just once.

---

## 3. Gate F — the chapter's own measure of done

The standing protocol chain (`ralph/GATE_F_PROTOCOL.md` →
`ralph/GATE_F_MASTER_PROTOCOL.md` → `ralph/GATE_F_INSTRUMENTATION_REQUEST.md`)
governs how a full capstone run works. Current state:

- **CAP-1/CAP-2** — confirmed fixed across independent fresh runs. Do not
  reopen without new evidence.
- **S03's catch-retry harness loop** — root-caused and fixed across several
  real sub-bugs (wait-budget, a team-cap lockout, a revive/cycle ordering
  bug), each found by actually re-running the segment, not guessed. In
  progress: full verification, then S04 through S10 one segment at a time —
  run, fix every real failure, reconverge that segment alone, advance, never
  skip ahead. Only after all ten pass individually does one continuous
  S01-S10 run happen. This is a many-hour, unattended effort; frequent
  "still running" status with real new commits is expected, not a problem.
- Bands 1-5, the tournament semi-final, the finale, and real pacing are all
  still unverified by this project's own evidence process.

---

## 4. Visual — six items an independent check confirmed matter

The 2026-08-31 whole-game visual census produced 168 numbered findings. An
Opus review against the actual images found most of the list wasn't worth
acting on. **The census stays a historical report, not a backlog.** Six items
were confirmed real:

| item | status |
|---|---|
| Boss nameplate shown for a creature not on screen | **landed** |
| Combat camera never frames both combatants readably | **landed** |
| Controller glyphs — corrected: the live game already renders them correctly, the census's evidence was a capture-tool artifact | **closed, no game defect** |
| Creature roster generally too small next to the player | **landed** — see `ralph/OWNER_DIRECTIVES_2026-09-01.md` |
| Creature bed too small for the (now bigger) roster | **landed** — bed grown, real lying poses for terrapup/trailpup; bramblebun (broken idle animation, filed separately) and veridian (any roll worsens footprint) knowingly still imperfect |
| One world site renders almost totally black | not started |
| Signpost text is an unreadable smear | not started |

---

## Sources

- `ralph/OWNER_PLAYTEST_2026-09-02.md`, `ralph/OWNER_PLAYTEST_2026-09-01.md` — playtest records
- `ralph/OWNER_DIRECTIVES_2026-09-01.md` — same-day owner corrections (creature scale)
- `ralph/reports/gate-f-capstone-3/CAPSTONE_3_REPORT.md`, `ralph/reports/FINDING-CAPSTONE3-S03-CATCH-LOOP-STALL-2026-09-01.md`
- `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md` (historical, not a backlog)
