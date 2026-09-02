# Owner playtest — 2026-09-02

Recorded verbatim from the owner's own play session, relayed through the coordinator. Per `CLAUDE.md`'s precedence rules, this outranks every other doc in the repo for what it covers, and a fresh owner reproduction reopens any item an old `DONE.md`/landed-branch claim says is fixed — several items below do exactly that.

## Findings, in the order given

1. **Grass didn't render.** Possibly the intended effect of `OWNER-0901-PERFORMANCE-LAG-V2` (which disabled `grass_field` to fix the ~10 FPS lag) rather than a new defect — needs a call on whether "no grass" is an acceptable tradeoff or whether the perf fix needs a cheaper grass path instead of an off switch.
2. **The game took forever to load.**
3. **Village gate still not on every exit.** `OWNER-0901-VILLAGE-GATE-ROADS-V2` landed on `main` earlier today (`5b934766`) and was believed fixed — **reopened, confirmed still broken by direct play.**
4. **Characters in the village look too small now.**
5. **Still too many characters in the village.** `OWNER-0901-VILLAGE-POPULATION` landed today, believed fixed — **reopened.** (Second time this exact complaint has reopened; see the 09-01 playtest's own note that a same-day fix for the opposite complaint, daytime emptiness, may have overshot.)
6. **Catching is hard because aiming at the creature is too hard.** More specific than the 08-30 "catching is too hard" complaint (which `T5-FEEL-COMBAT-ENGAGES-2026-08-30.md` investigated and found to be a RIG/measurement artifact, not a real defect — that investigation bypassed the aim step entirely and never tested this). **Concrete owner-requested fix: creatures should move less, or in slow motion, once the player enters catch mode.** This is a real design ask, not just a difficulty complaint.
7. **No way to tell when a creature finishes resting.** Wants an indicator — in the menu or elsewhere — showing rest progress/time remaining.
8. **Village shape still makes no sense, especially around Grandpa's house.**
9. **Mira shouldn't be hidden inside a house.**
10. **Can't place the tent and campfire.** Placement is failing for some reason. Also a UX ask: the game should communicate that these pieces go together, or — the owner's stated preference — the fire, the tent, and the bed should be distinct, individually placeable pieces rather one bundled prop. (Verbatim text was garbled here — "the bee for the character" almost certainly means "the bed for the character" — confirm with the owner if ambiguous before implementing.)
11. **Team menu overruns the food bar.** UI ask: move the food bar down, next to the health bar.
12. **Team menu sometimes appears twice after a fight.** Should only show once; the second instance also doesn't always show the full team.
13. **Dark isn't night time any more — it basically stays dusk.** `OWNER-0901-DAYNIGHT-CYCLE` landed today, believed fixed — **reopened.**
14. **The day clock often just stays on the same day** — e.g. Day 2 counts to 24:00, then restarts Day 2 at 00:00 instead of advancing to Day 3. Same `OWNER-0901-DAYNIGHT-CYCLE` regression as #13, likely one root cause behind both — this is the same family of symptom the 09-01 playtest (item 11) and the visual census's `BACKLOG-VISUAL-CLOCK-VS-SKY` finding already named, now confirmed unfixed by the same-day landed fix.
15. **Creatures never get out of bed / never appear rested.** The owner does not know whether this is because the day never advances (see #13/#14) or because the full camp can't be built (see #10). Both are plausible single root causes for this — investigate together, don't assume which.

## What this reopens from the 2026-09-01 playtest

Three of that playtest's twelve "landed, believed fixed" items are now **confirmed still broken by direct play**, same-day:
- Village gate roads (item 5) — reopened by #3 above.
- Village population (item 6) — reopened by #5 above.
- Day/night cycle (item 11) — reopened by #13/#14 above, and worse: not just "stuck on Day 1," now actively cycling wrong (Day 2 → Day 2 instead of Day 2 → Day 3).

This is worth treating as a pattern, not three isolated misses: today's same-day dispatch-and-land cycle for the 09-01 playtest shipped fixes that were not re-verified by real play before being called done, and three of them didn't hold. The lesson already recorded once today (`ralph/BACKLOG.md` §1, on the village-gate V1 "nothing to fix" claim) generalizes: **a fix is not confirmed until an owner plays it, and "landed" must keep being tracked separately from "confirmed" until that happens.**

## Not yet triaged into a fix priority

This file is the raw record. See `ralph/BACKLOG.md` for the current priority ordering built from it.
