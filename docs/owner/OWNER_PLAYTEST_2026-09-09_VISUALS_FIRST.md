# Owner playtest and work allocation — 2026-09-09

Direct owner report in the active Codex conversation; supersedes earlier work
allocation. Visual quality is the immediate priority before other goal work.

> The creatures take up the whole space and combat becomes Impossible
>
> The teleporting should tell you what biome each location is in.
>
> When the game is loading between realms or at the beginning of game to say loading instead of just looking frozen
> Why can't I build a saddle anymore?
>
> Creatures mostly don't have faces. Some of the colors are still too much but some look really good
>
> There's no terrain in the last two biomes. So they look terrible. There is no grass, no trees, no bushes, etc. looks nothing like the reference art.
>
> The tree finale and water fall finale both look terrible and nothing like the reference art.
>
> I want 30% focused effort on fixing creatures especially faces and colors. Look at the reference art. 30% focus on fixing the storm biome. 30% on fixing the water biome. 10% on anything else.
>
> We have to get these things looking good first. Then we can move on to other things.

Execution: maintain three substantive visual implementation lanes: creatures,
Stormwood, and Water. Split focused effort 30/30/30, with at most 10% on other
work, including loading feedback, teleport biome labels and saddle crafting.
Pause the fresh-route replay work and avoid allowing CI administration or
diagnostic tooling to consume the visual lanes. Preserve prior evidence and
unfinished work. Do not reduce creature scale contrary to the standing owner
directive; address combat space/readability with suitable camera, spacing and
presentation changes. Use actual production scenes and reference art for visual
verification; do not credit code presence or empty-scene fixtures as completion.

These observations reopen the affected player-facing issues even where older
tests or reports passed. The four-biome goal remains active, with this priority.

## Follow-up after the first visual captures

> From those pictures, the pink spider and the axolotl have color schemes i don't like. Some houses are in the ground. The vigil places where you put the legendary pieces look awful. We're still missing grass in some but it's definitely improved overall. Keep going.

The pink spider and axolotl palettes are explicitly rejected. Current capture
attribution identifies these as the Glass Field Voltarach alpha and Water Mirejaw;
verify their actual active colourway/materials when correcting them. Buried houses
and legendary-piece shrine presentation are explicit open defects. Preserve the
improved vegetation while fixing remaining coverage gaps. Continue the existing
30/30/30/10 effort allocation; this feedback does not grant a whole-biome pass.
