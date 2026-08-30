# Owner playtest — 2026-08-30 (evening, post-LAND-0830J)

Owner-play evidence, precedence level 1 under `CLAUDE.md`. Recorded verbatim by
the coordinator from the owner's report, played on the landed build
(`main@453107fb` or the build published from it). **A newer owner reproduction
reopens an item even where a test or `DONE.md` says it shipped** — several
items below do exactly that.

The full-state audit (thirteen lanes, in flight when this arrived) predates
this file; the audit INDEX must fold these items in, and where a lane's verdict
says "passes" on something listed here, the owner's reproduction wins and the
discrepancy itself is a finding (the test is measuring the wrong thing).

## The owner's items, verbatim

1. "Hitting x doesn't always advance every interaction"
2. "The keyboard at the start is awful again for performance"
3. "Not everything gatherable needs to glow. Like trees, wood, stone, etc does
   not. It just needs to be a way to make the key, tms, orbs, potions, etc
   visible. Or just don't have grass spawn over them/around them. Maybe give
   it space."
4. "There are too many villagers in the village to start. Spread the NPCs about."
5. "All NPCs talk too much, just have them be short and to the point."
6. "The town gate doesn't gate anything. It would be better if it was a wall
   around the village with a gate you could open. Right now it has holes and
   you can jump over it."
7. "Team doesn't show the right number of creatures. It's always off."
8. "There's a river near the village that starts and ends just randomly. Not
   like at a pond or anything."
9. "I should be able to take a creature out of bed"
10. "I don't understand building recipes. With free building on I can build
    some stuff and not other things. It doesn't make sense."
11. "Creatures just stand on the beds they don't lay"
12. "The game performance deteriorates over time it seems"
13. "The knife is comically large."
14. "Beds are too small for creatures"
15. "There needs to be more berries in the village"
16. "The village layout is still terrible"
17. "It's not clear enough what you need to do to train your team. Am I
    supposed to get to level five? Do I have to feed each a berry? What are
    the requirements for the tournament."
18. "I should be able to sleep in a bed myself to advance the day"
19. "There should be something that tracks what day number and time we're at"
20. "Put the player's health bar in the lower left"
21. "Move the main story or just shrink it. It takes up too much space. "
22. "The day didn't seem to advance. I played for over twenty minutes and it
    never went to day two and I could never get my creatures out of bed."
23. "Even though the creatures were resting for a long time they still say
    tired."
24. "Camping needs a place on the build menu and it's the tent for you,
    creature beds, camp fire maybe a bench, a cooking kit."

## Coordinator triage (classification only — nothing here is fixed yet)

**Reopens items that tests currently call green:**

- (7) The TEAM counter drift reopens the party-count family even though
  `smoke_party_count_after_catches` passes: that test does 3 catches from a
  fresh save and checks once. Real play shows persistent drift — the test is
  narrower than the defect. Likely the same family as save/reload or
  bed/rest state transitions.
- (6) The village barrier reopens OP-0830-1 even though `smoke_opening` passes:
  the smoke test walks straight lines; the owner **jumps**. Fence colliders are
  topped "a full panel height above the highest ground" per panel, but a
  two-course rustic fence is evidently jumpable, and gate-adjacent gaps exist
  in play. The owner's stated preferred direction: a real wall around the
  village with an openable gate, not a knee fence.
- (1) "X doesn't always advance every interaction" is the owner reproducing the
  **arbiter prompt-press family** (trail_camp measured 1-in-4 locally the same
  day; GAME-F3 found it in the teaching fight). This is now owner-confirmed and
  should be treated as one high-priority defect, not scattered sightings.

**Likely one root cause each, needs diagnosis:**

- (22) + (9) + (23) + (18): the day/clock did not advance in ~20 minutes of
  play, creatures could not be taken out of bed, and rest never cleared
  "tired". These look like one clock/rest-state defect wearing four symptoms.
  (18) is also a feature ask: player sleeping advances the day.
- (2) + (12): startup naming-keyboard performance regression ("again") plus
  performance degradation over a session (leak / accumulating work). Two
  separate performance investigations.

**Direct design directives (owner precedence, to plan and implement):**

- (3) Glow only pickups/key items (key, TMs, orbs, potions), not bulk nodes
  (trees, wood, stone); and/or clear grass in a small radius around ground
  pickups.
- (4) (5) (16) Village: fewer NPCs clustered at start, spread them; all NPC
  dialogue much shorter; layout still fails the owner.
- (8) The river near the village needs a real source/terminus (pond, lake,
  or flowing off-map through terrain that explains it).
- (10) Building recipes are illegible in free-build; rules must be
  understandable in-game.
- (13) Knife scale down. (14) Creature beds scale up. (11) Creatures should
  lie on beds, not stand on them.
- (15) More berries in the village.
- (17) Training/tournament requirements must be explicit in-game (what level,
  what care, what qualifies for the tournament).
- (19) On-screen day counter + time-of-day indicator. (20) Player health bar
  to lower-left. (21) Main-story tracker smaller / relocated.
- (24) A "Camping" category on the build menu: player tent, creature beds,
  campfire, bench, cooking kit.

## Handling

Per the audit directive, these are recorded, not fixed, until the audit INDEX
and the completion plan sequence them. Exceptions a coordinator may take early
are the two possible regressions with reproduction value: the stuck
clock/rest-state (22/9/23) and the counter drift (7) deserve diagnosis lanes
promptly since every other lane's played evidence runs through those systems.
