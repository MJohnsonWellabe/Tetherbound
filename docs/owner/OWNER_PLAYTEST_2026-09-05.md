# Owner playtest — 2026-09-05 (Meadows + Cloudreach Cliffs)

Recorded verbatim so it survives session turnover. Under `CLAUDE.md`'s precedence
this is **owner-play evidence and outranks every other document in this repo for
what it covers**, including any green test or completion claim that contradicts it.
A current owner reproduction reopens an item even if a report says it shipped.

## Verbatim

> the second biome is less far along than I thought it was and the meadows still
> needs some work. work through this list of items with an intense focus on
> finishing the second biome and getting the burrow warrens to look right.
>
> Inputs and keyboard are not working well again at the beginning.
> When you go directly to the build screen from playing rather than going through
> the menu, you can't place pieces.
> Bramblebun color is awful
> I can't find any candies, plants, shrooms, flowers.
> There are very few creatures after I leave the village and run towards bridge.
> Isn't there supposed to be an alpha at the pond? Shouldn't I be directed to go
> there?
> Gils face looks terrible
> You can't rest at the camp right by gil.
> Burrow warrens looks awful from the outside and there's too many creatures too
> close inside. There should be 2-3 to right before the guardian then the alpha.
> My alpha looked the exact same as a regular trail pup.
> I can't ride my terrapup
> At the bridge you can't open it and it doesn't tell you to go challenge the guy.
> When you try the bridge it should make you challenge him. He should walk up and
> start talking to you.
> In the strong hold, you should have to fight every npc to advance to the next.
> The portal to the next biome is horrible. It didn't need to be there. When you
> beat the legendary the rift collapses and the second biome is revealed and
> pulled into the map to connect.
> You can't see the legendary when you enter the chamber. The machine needs to be
> turned.
> The fighting camera sucks. I think it is too zoomed in.
> When and how does the pig evolve?
> The hall needs to be lit by torches
> When I press enter cloudreach cliffs the game froze for a while. It should tell
> you it's loading.
> I didn't think I can teleport to the second biome in the menu and I should be
> able to
> When you fall off the world you just fall forever
> The visuals are far from done in biome two. Some looks good but the grass is too
> sparse. The areas that have it are perfect but then a lot of the test is bare.
> You can walk through too many spots and fall.
> You walk like half way in the ground usually
> Once time I could ride my viridian stag but never got the offer again to ride it
> The map should show all the regions you've uncovered so meadows and clouds
> together.
> Candies, flowers and things feel appropriately placed in the second biome.
> Appropriate density.
>
> there is another lane working to make the game multiplayer. don't overrun any of
> its work.

## Items

| Id | Item | Kind |
|---|---|---|
| OP-0905-01 | Inputs/keyboard not working well at the beginning | defect |
| OP-0905-02 | Build screen opened directly from play cannot place pieces | defect |
| OP-0905-03 | Bramblebun colour is awful | visual |
| OP-0905-04 | Cannot find candies, plants, shrooms, flowers (band 1) | content |
| OP-0905-05 | Very few creatures between the village and the bridge | content |
| OP-0905-06 | Pond alpha: should exist and the player should be directed there | content/direction |
| OP-0905-07 | Gil's face looks terrible | visual |
| OP-0905-08 | Cannot rest at the camp by Gil | defect |
| OP-0905-09 | Burrow Warrens exterior looks awful | visual |
| OP-0905-10 | Burrow Warrens interior: too many creatures too close; want 2–3, then guardian, then alpha | encounter design |
| OP-0905-11 | Warrens alpha looked identical to a regular Trail Pup | visual |
| OP-0905-12 | Cannot ride Terrapup | defect (OP-0904-9 roster) |
| OP-0905-13 | South Bridge: cannot open; no direction to the guardian; trying the bridge should make the guardian walk up, talk, and challenge | design + defect |
| OP-0905-14 | Stronghold: must fight every NPC to advance to the next | design |
| OP-0905-15 | The portal to the next biome should not exist; beating the legendary collapses the rift and reveals Cloudreach, pulled into the map to connect | **design decision (supersedes the Cloudreach directive §7 "Key to the Next Realm" entrance)** |
| OP-0905-16 | Legendary not visible on entering the chamber; the machine needs turning | staging |
| OP-0905-17 | Combat camera too zoomed in | tuning |
| OP-0905-18 | When and how does the pig (Mudsnout) evolve? | discoverability |
| OP-0905-19 | Meadows Hall lit by torches | visual |
| OP-0905-20 | Entering Cloudreach froze; needs a loading indication | defect |
| OP-0905-21 | Teleport to the second biome from the menu should be possible | feature |
| OP-0905-22 | Falling off the world falls forever | defect |
| OP-0905-23 | Cloudreach grass too sparse / bare areas | visual |
| OP-0905-24 | Cloudreach: walk-through spots and falling | defect |
| OP-0905-25 | Cloudreach: walking half in the ground | defect |
| OP-0905-26 | Viridian Stag ride offer appeared once and never again | defect |
| OP-0905-27 | Map should show all uncovered regions, Meadows and Cloudreach together | feature |
| OP-0905-28 | Cloudreach candy/flower density is right — do not regress | constraint |

Constraint for this pass: a separate lane is converting the game to multiplayer
(`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md`). Do not restructure
`Game`/state ownership here; keep fixes local.

Nothing in this file is implemented by recording it. Closure evidence is tracked in
`docs/CURRENT_STATE.md`.
