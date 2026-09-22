# Owner playtest — 2026-09-03

Recorded verbatim from the owner. Per `CLAUDE.md` precedence this outranks every other
document for what it covers and reopens any item a ledger says is fixed.

> Everything works well and looks good. After I have already built a camp it keeps
> telling me to gather supplies. I built in free mode so I never had to but if you've
> already bypassed it, it should move on.
>
> Starting the tournament was hard even after I had everything. I had to talk to the
> starter several times.
> I don't like the flags around the tournament area.
> The biggest thing right now is that there is nothing outside the village. Like barely
> any creatures, no trees just nothing to do and nothing to see.
> When you gather something it shouldn't come back. A bush, a tree, a stone. It should be
> gone. Same for potions and so on.
> There should be a shortcut button to map and to building.
> Tents need to be way bigger. The bed for the human should be placeable in the tent and
> not outside of it. You should have to have the tent over your head to sleep.
> The food bar and health bar need to be on stacked not next to each other.
> There should probably be some more ceremony around the tournament. Like you enter then
> you choose to be start the battle then it announces you won and announces the next
> round.
> Burrow warrens doesn't look good. I can fight multiple elders on there. After I fight
> it and catch it or kill it I shouldn't get another chance. Same for the guardian.
> No one else in the game should have the any of the starters.
> When you're in the bed at the beginning it's just a backpack not a person.

## Triage (orchestrator, same day)

| # | Finding | Class | Lane |
|---|---|---|---|
| 1 | Objective keeps saying "gather supplies" after the camp is built in free build | progression bug; matches `smoke_gate_b_continuous`'s stall | OBJECTIVE-CAMP |
| 2 | Tournament start needed several talks with the marshal; wants ceremony (enter → choose to start → win announced → next round announced) | flow + presentation | TOURNAMENT-FLOW |
| 3 | Flags around the tournament area disliked | presentation (already judged as placeholder rectangles) | TOURNAMENT-FLOW |
| 4 | Nothing outside the village: barely any creatures, no trees, nothing to do or see | **the Gate 2 problem, now owner-confirmed as the biggest thing** | WORLD-BAND1 (investigation first, then Fable composition contract) |
| 5 | Gathered bushes, trees, stones, potions must not come back | design directive: no respawn | WORLD-RULES (recorded as D72) |
| 6 | Shortcut buttons to map and to building | input | HUD-INPUT |
| 7 | Tents much bigger; bedroll placeable inside; must have the tent over your head to sleep | build/rest rule | CAMP-SHELTER |
| 8 | Food bar and health bar stacked, not side by side | HUD | HUD-INPUT |
| 9 | Warrens: can fight multiple elders; after fight/catch/kill no second chance; same for the guardian; "doesn't look good" | encounter rule + visual | WARRENS-ONCE (visual part deferred to Gate 3 band work) |
| 10 | No one else in the game should have any of the starters | design directive: starters exclusive | WORLD-RULES (D72) |
| 11 | In bed at the start it is just a backpack, not a person | opening presentation | OPENING-BED |

Confirmed by play from the 09-02 list: everything else "works well and looks good"
(village gate, population, catching slow-mo, load time, grass on, camp split, HUD team
menu, rest indicator).
