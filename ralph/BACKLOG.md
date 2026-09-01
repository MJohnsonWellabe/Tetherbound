# Backlog

**Rewritten from scratch, 2026-09-01, on owner directive: "all these backlogs
are wrong... the Ralph ones should be gone. they're not relevant anymore."**

The previous `BACKLOG.md` (4,069 lines back to 2026-08-15) and `BLOCKED.md`
(1,228 lines of parked decisions) are deleted, not archived elsewhere — their
substance either shipped, was superseded, or wasn't worth carrying forward.
`ralph/DONE.md` still holds the shipped-work archive if a specific old item's
history is ever needed; git history holds the rest.

**What belongs in this file now, per the owner's own scoping:** the most
recent owner playtests, Gate F's current blocker, and the small number of
visual-review items an independent check actually confirmed matter — not a
re-derivation of the 168-item visual census, which stays a historical report
(`ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md`) rather than a backlog.

---

## 1. Owner playtest, 2026-09-01 — landed, not yet re-confirmed

`ralph/OWNER_PLAYTEST_2026-09-01.md` is the full record. Twelve findings from
a real ~30-minute play session, dispatched same-day as twelve `OWNER-0901-*`
branches, all merged into `main` via `ralph/LAND-MEGA-0901` before this
coordination session began. **Landed is not the same as confirmed** — none of
these twelve have been checked against a fresh owner play session since they
shipped, and one of them (below) already proved a first "nothing to fix"
claim wrong once today.

**The owner's own priority order, verbatim:** *"Interact and lag are the two
game breakers right now. Then not knowing how to train or what we're supposed
to do at that point."*

| # | finding | landed as | status |
|---|---|---|---|
| 1 | Knife not visible in hand | `OWNER-0901-KNIFE-VISIBILITY-V2` | landed, unconfirmed |
| 2 | Severe lag, ~10 FPS — **game breaker** | `OWNER-0901-PERFORMANCE-LAG-V2` (grass_field disabled, 31.7M primitives root cause) | landed, unconfirmed |
| 3 | Interact works ~half the time — **game breaker** | `OWNER-0901-INTERACT-RELIABILITY-V2` | landed, unconfirmed |
| 4 | No way for the player to sleep | `OWNER-0901-PLAYER-SLEEP` | landed, unconfirmed |
| 5 | Village gate should be on every road out; boundary still jumpable | `OWNER-0901-VILLAGE-GATE-ROADS-V2` | **landed after a real correction — see below** |
| 6 | Still too many people in the village | `OWNER-0901-VILLAGE-POPULATION` | landed, unconfirmed |
| 7 | Unclear how to train a team | `OWNER-0901-TRAIN-CLARITY` | landed, unconfirmed |
| 8 | Bond system illegible, wants discrete milestones | `OWNER-0901-BOND-MILESTONES` | landed, unconfirmed |
| 9 | Creatures don't lie in bed except galecrest | `OWNER-0901-CREATURE-BED-POSE` | landed, unconfirmed — matches open visual item, see §3 |
| 11 | Day/night cycle broken — day counter stuck, night falls at random | `OWNER-0901-DAYNIGHT-CYCLE` | landed, unconfirmed |
| 12 | Tournament `min_level` 6→5, Halda's guidance made concrete | `OWNER-0901-TOURNAMENT-LEVEL5` | landed, unconfirmed |
| — | Small creatures disappear into grass | `OWNER-0901-CREATURE-GRASS-VISIBILITY` | landed, unconfirmed |

**Item 5 is the one worth reading closely, as a standing lesson.** The first
dispatch on the village-gate finding reported "all exit roads have gates, no
code change needed" — a config read, not a played check, with no branch and
no evidence pushed. The owner played again, same day, and found it wrong
directly: at least one road had no gate at all, and the boundary was still
jumpable in places. Redispatched as V2 with a stricter brief (map every road
crossing with the existing probe tools, require pushed evidence); it landed
for real (`5b934766`, padding the collision height to stop vaulting). **A
"nothing to fix" conclusion without a pushed branch or a run probe is not
trustworthy — this is not a hypothetical risk, it happened today.**

**What clears this section:** the owner playing again. Until that happens,
treat all twelve as "believed fixed," not "fixed."

---

## 2. Gate F — the chapter's own measure of done

The standing protocol chain (`ralph/GATE_F_PROTOCOL.md` →
`ralph/GATE_F_MASTER_PROTOCOL.md` → `ralph/GATE_F_INSTRUMENTATION_REQUEST.md`)
still governs how a full capstone run works and what it must prove. Current
state:

- **CAP-1** (dropped starting Revives) and **CAP-2** (unhealed damage carrying
  into the first village fight) — confirmed fixed across independent fresh
  runs. Do not reopen without new evidence.
- **CAP-3, the most recent run:** stalls inside `tools/gate_f/segments/S03.json`'s
  own catch-retry loop — a harness targeting bug (waits on stale combat state,
  walks back to an already-resolved creature instead of a new one), not a
  game defect. Team size gets stuck at 2, so tournament sign-up
  (`min_party_size: 5`) never fires and the run never reaches S05 or beyond.
  Full writeup: `ralph/reports/FINDING-CAPSTONE3-S03-CATCH-LOOP-STALL-2026-09-01.md`.
- **In flight:** a harness-only fix for the S03 loop. Once it lands, the
  chapter has never actually been played start-to-finish by this project's own
  evidence process — bands 1-5, the tournament semi-final, the finale, and a
  real 3-4 hour pacing read are all still open questions. That first real
  capstone pass is the single highest-value thing to run next.

---

## 3. Visual — six items an independent check confirmed matter

The 2026-08-31 whole-game visual census produced 168 numbered findings. An
Opus review against the actual images, cross-checked with a code-level trace
on one item, found most of that list was not worth acting on — pixel-
percentage findings nobody would notice, texture nitpicks, sub-centimetre
geometry. **The census itself is kept as a historical report, not carried
forward as a backlog.** Six items were confirmed real:

| item | status |
|---|---|
| Boss nameplate shown for a creature not on screen | **landed** |
| Combat camera never frames both combatants readably | **landed** |
| Controller glyphs — corrected: the live game already renders them correctly, the census's evidence was a capture-tool artifact (no joypad in the render container) | **closed, no game defect** |
| Creature roster generally too small next to the player | **landed** (owner correction 2026-09-01: creatures should tower over the player, not shrink to fit — see `ralph/OWNER_DIRECTIVES_2026-09-01.md`) |
| One world site renders almost totally black | not started |
| Signpost text is an unreadable smear | not started |

Also still open, matching a live owner playtest finding (§1, item 9): the
creature-bed-fit defect (hindquarters/paws outside the bed ring) — a session
was mid-render on this when this file was rewritten; check its branch
(`ralph/VISUAL-BED-FITS-CREATURE`) before restarting it.

Purple flower prop (4-6x oversized) and one other cosmetic item also landed
today alongside the six above, since they were already in flight when this
rewrite happened — not because the census as a whole is back in scope.

---

## Sources

- `ralph/OWNER_PLAYTEST_2026-09-01.md` — full playtest record
- `ralph/OWNER_DIRECTIVES_2026-09-01.md` — same-day owner corrections (creature scale)
- `ralph/reports/gate-f-capstone-3/CAPSTONE_3_REPORT.md`, `ralph/reports/FINDING-CAPSTONE3-S03-CATCH-LOOP-STALL-2026-09-01.md`
- `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md` (historical, not a backlog)
