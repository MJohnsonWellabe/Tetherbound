# D23 — The Meadows is the first game

> Vocabulary note: written when the game called its creatures "pals"; R1.1 (2026-08-14) renamed the term to "creature" throughout the codebase without rewriting this historical record.
**Date:** 2026-08-11 · **Decided by:** the owner, in a supplied specification,
after playing the published Windows build.
**Source:** `docs/specs/MEADOWS_PROGRESSION_SPEC.md`, stored verbatim. This record is
the integration of that document, not a summary of it — read the spec for what
to build and this for what it changes.

## The decision

Three things arrived at once, and they are worth separating because they have
very different blast radii.

1. **P0 fixes from a real playtest.** Mouse capture, a Grandpa the player can
   walk straight past, a world you can fall off, seven dead-end edges, and two
   creature families that read as palette swaps.
2. **The Meadows becomes a 4–7 hour chapter.** Five progression bands, two
   material tiers, physical gates, 12–17 trainer battles, a dungeon, a
   mini-stronghold and a rescue — not a tutorial followed by a walk to the gym.
   *Amended by `D42` (2026-08-15): 3–4 hours; footprint unchanged. Everything
   else in this line stands.*
3. **Team Tether's macro-story is settled.** The eight legendaries are living
   anchors for natural forces; Team Tether binds them to hold **Tether Rifts**
   apart; freeing one physically reconnects a region to the world.

The spec's own closing line is the decision: *the Meadows is not the tutorial
before the game, the Meadows is the first game.*

## What it supersedes in `MEADOWS_VERTICAL_SLICE.md`

- **M7** — the exploration space grows: quarry, warrens, a major river, the
  mill crossing, a relay station, upper meadows, wind ridge, ruined watchtower,
  and seven perimeter spokes.
- **M12** — riding becomes a Band 3 / early Band 4 unlock gated on a saddle
  with Rootstone/Ironwood components, not a free-standing milestone.
- **M13** — one world encounter becomes a trainer circuit, a mini-stronghold
  and three regional captains.
- **M14** — gains the Rift reveal and the reconnection event.
- **The slice exit gate** now also cites the spec's §39.
- **Not superseded:** M0–M6, M8–M11, M15. The spec assumes all of them.

## What it supersedes or extends in `GAME_DESIGN.md`

- **§3 Story Frame** — extended, and one sentence in it becomes false. "The
  exact endgame motive remains intentionally open" is no longer true; the
  motive is §23–§26. Leaving that line standing beside the new canon is exactly
  the stale-doc contradiction `HANDOFF.md` §7 is a list of.
- **§9 Biome Spine** — the eight biomes are severed pieces of one landmass, not
  eight islands. The concepts are unchanged; the reason they are apart is now
  canon.
- **§28 Stronghold** — gains the five-space interior (Outer Works → Courtyard →
  Tether Chamber Approach → Warden Arena → Legendary Chamber) and a 30–60
  minute first-clear target.
- **§29's 24-step arc** — superseded in *ordering and detail* by the spec's
  Acts I–VI and Bands 0–4. Every §29 beat still happens; §29 stops being the
  authority on their sequence. The 4–7 hour target sits inside §29's own 4–8
  hour band, so this is a refinement, not a conflict. *Amended by `D42`: 3–4
  hours, now below §29's band rather than inside it.*
- **§27 Difficulty** — unchanged and reinforced. Recommended team levels (5–8,
  10–16) are guidance, never a lock; the spec's own §19 bans "arbitrary
  level-lock UI".
- **§26 Pal Scope** — unchanged. Three starters, twelve wild, one evolution,
  one legendary is exactly the roster §20 freezes.
- **§33 Exit Criteria** — deliberately **not** edited. See the carve-outs.

## The new hard constraints

**§20 — no new creature Meshy generations for the Meadows.** The installed
meshes are the meshes. Differentiation is material, texture, roughness/value,
modest scale, animation, VFX, habitat, behaviour, combat role and spawn context
— and nothing else. This is a budget the owner holds, not an art opinion, which
is why it is restated in `CLAUDE.md` and `docs/AGENT_WORKFLOW.md` rather than
living only here. The lever it leaves is
`tools/art_pipeline/blender/grade.py`'s repair path, which needs neither
Blender nor credits.

**§21 — human NPCs reuse the three existing rigs.** Trainer, Grandpa and Warden
are base bodies for the whole cast, differentiated by **per-material** variants.
The spec is explicit that a single global tint is not acceptable where it
destroys material separation — which is precisely what `art.json`'s current
`tint` key does (`character_model.gd::_apply_tint` multiplies every surface).
R7.2's three villagers are fine as far as they go; a cast of a dozen cannot be
built on that mechanism.

**§22 — at most one or two additional human generations**, owner-supplied only,
and only for reusable archetypes: first a neutral adult civilian/trainer base,
second a Team Tether grunt base. §37 is explicit that no task may create a
dependency on them. Note the arithmetic: `BLOCKED.md` records **175 credits**
at roughly 90 per species, so "one or two" is *one comfortably, two only if a
human generation is cheaper than a creature*. Do not plan around two, and do
not spend the balance on a grunt base while the Warden's face is still painted
rather than modelled.

## The new story canon (§23–§34)

The world was one connected ecosystem. Each of the eight legendaries is a
living conduit for one natural force. Team Tether learned to bind them into
Tether systems and siphon that energy to hold **Tether Rifts** open —
impossible ravines, widened rivers, unnatural mountain walls, severed plateaus.
A divided world is easier to control: Team Tether's real power is not strong
trainers but a monopoly on the movement of resources, creatures, people and
trade between isolated regions.

Their doctrine is that the connected world was unstable and the barriers made
peace, and **some of that may be historically true** — §31 requires that
reconnection carry real costs as well as benefits. The Wardens can be sincere
while the system is oppressive. The Meadows Warden believes freeing the
legendary is reckless, not that the player cannot be stopped.

The player's answer is the game's thesis and the reason the five-creature rule
exists: Team Tether believes control creates stability; the player proves
cooperation does.

Working terms, renameable, and to be held in data rather than hardcoded per
`CLAUDE.md`'s tunable-values rule: **Tether Rift**, **Rootstone**, **Ironwood**,
**Heartstone**, and the three Sigil names.

## Carve-outs — where an older rule still wins

**`CLAUDE.md`'s Biome 2 rule stands over §38 step 45.** "The next biome
physically joins the Meadows" is delivered as a **distant, non-enterable view**
— silhouette, skybox, terrain seam, changed dialogue — behind a believable
barrier. No second biome's terrain, spawns, species or playable space. The
spec's own §19 non-goals ("all seven future biomes") support that reading. If
the owner wants a walkable slice of Biome 2 as the payoff, that is a question
for `BLOCKED.md`, not a licence a firing may take.

**`GAME_DESIGN.md` §33's twelve criteria are not renumbered.** `R9.5`, `R0.11`,
`R2.9`, `R4.12` and `R6.3` all cite them by number. The spec's §39 gate is
added as an additional, Meadows-chapter gate that §33 points at.

**D17 is untouched** — an evolution is always larger, still enforced by
`tests/test_evolution_links.gd`. **D12/D19 creature scale is untouched.** §20
forbids regeneration; it says nothing about heights, and its "modest scale
variation" is a differentiation lever, not a licence to reopen a table the
owner has now answered three times, always upward.

**Implementing this story is not inventing it.** `CLAUDE.md`'s flag list names
"major story rewrite" and `GAME_DESIGN.md` §34 names "major story changes" —
both are prohibitions on a firing *deciding*, not on a firing *building* what
the owner decided. This spec is owner-supplied, exactly like the wild-canon
pack that produced D13. The failure mode this paragraph exists to prevent is a
correct, rule-following firing reading the flag list and parking the entire
chapter in `BLOCKED.md`.

## The honest trade-off

**What it buys.** The loop stops measuring "is the Meadows done?" against a
fifteen-minute tutorial. Every unbuilt system already on the backlog —
evolution, riding, the release ceremony, the map, food, trainer battles —
acquires a place in a real arc, which is what turns a feature list into a game.
It also answers two questions the visual pass left open: `R7.1-remainder-2`
asked outright whether a water feature would do more for depth than more
vegetation tuning, and the spec's Band 3 river is that feature.

**What it costs.** The backlog roughly doubles — about two dozen new items and
a dozen amendments. And the world does not fit: `terrain_playground.json` says
in its own first line that it is *a test area, not the Meadows*, and 512 m on a
side cannot hold a 4–7 hour arc. Growing it costs a terrain rebake, more
Terrain3D regions and a real performance question on the Ally. That is the
single largest unpriced item in this integration and it belongs to `R7.3`.
*Amended by `D42` (3–4 hours; footprint unchanged): this paragraph is the
argument D42 explicitly refuses to run backwards. A shorter arc does not shrink
the map or revert `R7.3` — the answer is `SH47`'s density/XP/travel tuning.*

**What it forecloses.** Any Meadows plan that needs a new creature model. In
particular **`R4.5`'s "fresh generation from the sheet" fallback is now
illegal** — Tuskroot is verify-the-installed-model, or graft off Mudsnout, or a
blocked question for the owner. And the three off-style creatures in
`BLOCKED.md` (Paddlenewt, Pipwing, Ripplet) can only be regraded, never
replaced.

**What it does not resolve.** The human half of the art-cohesion question in
`BLOCKED.md`. §20 says *creature*; it does not touch the flat-shaded trainer
and Grandpa against the Warden's painted finish — and §21 makes that worse by
promoting those two rigs to base bodies for the entire cast. The creature half
is settled (rework, never replace). The human half is open and now more urgent.
Note that `R3.0` — re-running the three humanoid GLBs through the fixed
`animate_humanoid.py` — is a pipeline re-run, not a generation, and costs no
credits.

## Where it is wired

`docs/specs/MEADOWS_PROGRESSION_SPEC.md` (the spec itself), `CLAUDE.md` (hard rules
and the flag-list clarification), `docs/AGENT_WORKFLOW.md` (restated for a
memoryless firing), `docs/AGENT_WORKFLOW.md` (read-first list), `docs/CURRENT_STATE.md`
(Phase -0.75, Phase 3.5, Phase 8 restructured, Phase 8.5),
`ralph/BLOCKED.md` (the art question narrowed to its human half),
`archive/docs/HANDOFF.md` (state), `docs/specs/MEADOWS_VERTICAL_SLICE.md` and
`docs/specs/GAME_DESIGN.md` (amended in place), `docs/specs/OPENING_SEQUENCE.md` (the door
gate), and one-line forward references on `docs/decisions/D13` and `D20`.
