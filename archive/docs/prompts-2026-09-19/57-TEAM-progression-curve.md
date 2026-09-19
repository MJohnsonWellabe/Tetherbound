# TEAM-PROGRESSION — Make getting stronger visible, useful and naturally paced

## Goal
Create and tune one coherent Meadows progression curve for the player’s five creatures across the entire chapter.

This is not a new leveling system. Reuse current creature instances, XP, levels, moves, TMs, traits, bond, Best Creature, evolution and condition systems.

## Player-facing question
At nearly every stage, the player should be able to answer:

> **What can I do now to make my team better for the challenge ahead?**

The answer should include several legitimate options rather than repetitive weak-enemy grinding.

## Major challenge ladder
Use current canon and current data; tune exact numbers from play:
1. first wild fight;
2. local/tournament opponents;
3. South Bridge progression;
4. Warrens guardian;
5. relay trainers/Captain Vance;
6. Upper Meadows regional captains;
7. stronghold trainer/elite sequence;
8. Warden.

For each challenge, record a **natural expected team range**, not a hard UI gate:
- approximate levels;
- expected number of viable party members;
- expected access to moves/TMs/orb tier;
- likely condition/rest state;
- intended difficulty/readiness signal.

## XP economy
Measure a realistic fresh playthrough and track XP from:
- ordinary wild fights;
- catches where current systems award XP;
- local trainers;
- Team Tether trainers;
- major fights;
- optional activities where XP is appropriate.

Tune so a player engaging with a reasonable share of interesting content reaches major fights prepared without needing to farm one spawn repeatedly.

Optional exploration should create an advantage without trivializing the chapter.

## Level-up feedback
Coordinate prompt 47. A level-up must be noticed immediately and should communicate any meaningful change.

## Moves and TMs
Map when the player is likely to encounter useful TMs and how those choices affect team construction. Follow current TM item semantics and compatibility data. Avoid giving every creature the obvious perfect answer early.

## Traits / appraisal / individual quality
The player should understand that two wild creatures of one species may differ and occasionally face a real choice between an existing team member and a better/different individual.

Do not expose raw IVs if current canon uses appraisal abstraction.

## Bond / Best Creature
Make bond and Best Creature meaningful enough to support attachment/progression without requiring repetitive affection chores. Use existing species-specific Best Creature perks where implemented.

## Evolution
Mudsnout → Tuskroot is the one normal Meadows evolution. Ensure its level/bond/item/condition path lands at a meaningful time in the chapter and feels earned. Do not make it either automatic immediately or so late that normal Meadows players never see it.

## No player scaling
The world does not rescale to the player. Deeper regions and trainers have authored strength. Tune content availability around that rule.

## Anti-grind rule
Bad result:
> player knows the next fight requires five more levels and circles identical weak creatures for twenty minutes.

Good result:
> player can fight trainers, explore a special encounter, catch/use a different creature, pursue a TM, gather for a preparation upgrade or clear optional content while becoming stronger.

## Deliverable
Create/update a compact progression table in an appropriate data/design file containing, for each major beat:
- expected team level band;
- key progression tools likely available;
- XP sources since prior beat;
- important team-building temptations;
- tuning notes.

Exact numbers remain tunable.

## Verification
Run fresh progression samples through each gameplay gate. Record team levels/composition entering and exiting every region. Flag:
- under-level walls;
- over-level trivialization;
- repeated farming pressure;
- unused progression systems;
- level spikes caused by one reward;
- team members falling permanently behind because switching is inconvenient.

## Acceptance
- focused play naturally reaches the Warden in the intended 3–4 hour chapter window;
- optional content makes the player stronger but is not mandatory grind;
- level-ups are visible;
- different team-building choices remain viable;
- evolution can meaningfully occur;
- major opponents feel progressively harder;
- no hard player-scaling or arbitrary level-lock UI is introduced.

## Definition of done
Getting stronger is one of the main pleasures of Meadows and the player always understands multiple useful ways to prepare for the next challenge.