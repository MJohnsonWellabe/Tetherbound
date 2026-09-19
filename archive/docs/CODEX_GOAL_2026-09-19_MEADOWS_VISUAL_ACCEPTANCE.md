# Codex goal — Meadows visual acceptance criteria and lane, 2026-09-19

**Replaces the previous Meadows lane's goal.** That lane was pointed at the
Gate F automated campaign-proof as its primary objective; this replaces it.
Gate F work is now opportunistic only (finish anything already mid-flight,
don't start a fresh full attempt) — see
`docs/owner/OWNER_DIRECTIVE_2026-09-19_LANE_RESTRUCTURE_CONTENT_AND_COMBAT_SPLIT.md`.
Content density (off-trail discoveries, roster temptation, detour payoffs) is
now a **separate lane** — see
`docs/CODEX_GOAL_2026-09-19_CONTENT_DENSITY_ACCEPTANCE.md`. This lane is
visuals only.

## What "Meadows should look like" means, concretely

Don't re-derive this — it already exists in three places, read all three:

1. **`docs/owner/OWNER_DIRECTIVE_2026-09-10_VISUAL_ACCEPTANCE_CRITERIA_BY_DOMAIN.md`**
   — 14 domains (creatures, terrain, vegetation, water, storm/ground, cliff/
   sky/clouds, swimming, riding, flying, strongholds, locations, items,
   gatherables, tools, characters), ordered by impact on the player's
   experience, each with a named reference game and the specific lesson to
   take from it (Pokémon, BOTW/TOTK, Grounded, Genshin, Subnautica, Stardew,
   Animal Crossing, Monster Hunter). This is the primary acceptance criteria
   document for this lane.
2. **`docs/VISUAL_BIBLE.md`** and **`.claude/skills/visual-judge/SKILL.md`**
   — the judging rubric and the two bar questions (does it belong beside
   `tetherbound-meadows-keyart.png`; beside Palworld reference frames, does it
   read as the same kind of game).
3. **`docs/acceptance/MEADOWS_EXIT_CRITERION.md`** categories B (creatures),
   C (NPCs/human cast), D (terrain/world), E (locations), J (one deliberate
   game) — the specific sub-criteria and open items already tracked there,
   several still marked open as of this doc's last edit (creature Aspect
   variants reading as one hue-swapped decal, ground-contact-on-slope,
   guardian silhouette at gameplay distance, river reading like a canal,
   campsite kit coherence, Meadows Hall's authored-structure quality).

## Order of work

1. **Re-verify current status against these three documents first.** A lot
   of visual work has landed since any of these were last checked end to end
   (Ironwood, Old Quarry, Old Mill Crossing, Burrow Warrens, Stonewater Reach
   were all named as accepted in the 2026-09-19 exit handoff) — confirm what's
   actually still open rather than re-fixing something already done.
2. **Work the highest-impact open domain first**, per the 09-10 doc's own
   ordering, unless a specific still-open item in the exit criterion (the
   ones listed above) is cheaper and clearly still broken.
3. **Every claim needs the same evidence discipline already established**:
   real shipping-build captures (day and night where relevant), independent
   code-blind review against the named reference (key art, Palworld frames,
   or the specific named reference game for that domain), no promotion on a
   self-report.

## What is explicitly out of scope

- Content density, off-trail discoverables, roster-temptation authoring —
  separate lane (`docs/CODEX_GOAL_2026-09-19_CONTENT_DENSITY_ACCEPTANCE.md`).
  If a visual fix and a content addition are tangled together (e.g., a
  location needs both better terrain *and* a reason to visit), fix the visual
  half here and flag the content half to that lane rather than doing both.
- Combat systems, Cloudreach, Stormwood, Water.
- Starting a fresh Gate F full-campaign attempt. If one is already mid-flight
  and about to answer a real question, finish that specific check — don't
  start a new one, and don't treat automated campaign proof as blocking this
  lane's visual work.

## Process

Write your plan to `ralph/reports/MEADOWS-VISUAL-0919/PLAN.md` before
starting, naming which domain(s) from the 09-10 doc you're tackling first and
why. Hold for `ralph/reports/MEADOWS-VISUAL-0919/PLAN-APPROVED.md`. Write
results to `ralph/reports/MEADOWS-VISUAL-0919/RESULTS.md`, in the same
evidence format already established (captures, independent verdicts, ledger
deltas).
