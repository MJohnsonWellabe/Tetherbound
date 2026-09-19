# Codex goal — content density acceptance criteria and lane, 2026-09-19

**Replaces the Stormwood/Water survey lane.** That lane is stopped by the owner.
This lane takes its worktree/session slot instead. Scope authority:
`docs/owner/OWNER_DIRECTIVE_2026-09-19_FOUR_LANES_BY_ACCEPTANCE_CRITERIA.md`.
Render-lock priority: same tier as the other content/visual lanes — claim/release
per `D:\tetherbound\RENDER_LOCK.json` as described there.

## What "content density" means here, made concrete

Not a vague call for "more stuff." These are the actual acceptance criteria,
drawn from `docs/acceptance/MEADOWS_EXIT_CRITERION.md` category G, `docs/GAME_VISION.md`
§2/§7, and the owner's own repeated diagnosis ("lacking... content wise
especially off the trail"):

1. **G8 — optional activity density.** Spec target is 6-10 optional activities
   per major region. Last recorded count (2026-08-30) was 1 of 6, with five
   more "in flight" — that status has not been re-verified since. **First
   task: recount the actual current density per region from real game data**,
   not from this stale number.
2. **G9 — every detour pays off.** A player who leaves the main path must get
   one of: XP, bond, a catch, materials, a TM, a recipe, a consumable, coins
   with real use, a shortcut, world information, a rare individual, or a
   genuine discovery. No empty rewards — an off-path detour that pays nothing
   is worse than no detour, because it teaches the player to stop exploring.
3. **G4 — roster temptation per region.** Every major region should create a
   genuine reason to reconsider the five-creature roster. At least one real
   moment of five-slot pressure must land before the legendary.
4. **G6 — victories change something real.** Major fights/discoveries should
   change capability, access, or world state — not just XP.
5. **A6/A7 — off-path pull, no dead travel.** Players should be tempted off
   the direct route (verified by voluntary detours actually taken) and should
   not experience long stretches of running through empty scenery.
6. **The specific off-trail mechanisms already named** in
   `docs/owner/OWNER_DIRECTIVE_2026-09-12_FINISH_MEADOWS_FIRST.md` (Tier 1
   and Tier 3): a distant village glimpse, something glowing far off, a
   cluster of unseen creatures visible from the path, NPCs who tell the
   player where things are (and reveal it on the map when they do), and the
   wayfinding beacon that points at the next real objective. These are the
   *delivery mechanism* for the density above — content that exists but has
   no way to be noticed doesn't count.
7. **Long creature-free stretches** (the specific south-trail gap named in the
   2026-09-12 playtest) should be fixed as part of density work, not treated
   as a separate bug.

## Order of work

1. **Audit current density first.** Walk (or query game data for) every major
   Meadows region and count: actual optional activities, actual off-path
   discoveries, actual roster-temptation moments, actual detour payoffs.
   Compare against the targets above. This produces a real, current gap list
   — do not assume the 2026-08-30 numbers still hold.
2. **Prioritize by the gap, not by what's easiest.** A region with zero
   optional activities is a bigger problem than a region with 4 of 6.
3. **Author content to close the gap**, favoring the off-trail delivery
   mechanisms named above — a glow, a distant landmark, an NPC line that
   reveals a map location — over adding more things directly on the critical
   path.
4. **Verify each addition actually gets found.** A detour nobody notices
   doesn't move G8's density number in any way that matters. Where
   practical, verify discoverability (sightline, audio/visual cue, NPC
   pointer), not just presence in the data.

## What is explicitly out of scope

- Combat systems (separate lane).
- Cloudreach, Stormwood, or Water visual/environment work (separate lanes;
  Stormwood/Water remain fully paused for any work at all).
- Pure visual polish with no content/density angle — that's the Meadows
  visual lane's job. If you find a visual defect while doing this work,
  note it for that lane rather than fixing it yourself, unless it's trivial
  and directly blocks verifying a content addition.

## Process

Write your plan to `ralph/reports/CONTENT-DENSITY-0919/PLAN.md` before
starting, including your planned audit method and which region(s) you'll
tackle first once the gap is known. Hold for
`ralph/reports/CONTENT-DENSITY-0919/PLAN-APPROVED.md`. Write results to
`ralph/reports/CONTENT-DENSITY-0919/RESULTS.md`, including the density
recount, what was added, and verification that additions are actually
discoverable.
