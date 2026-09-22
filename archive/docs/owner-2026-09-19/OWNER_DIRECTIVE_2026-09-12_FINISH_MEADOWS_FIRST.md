# Owner directive — finish the Meadows before any other biome, 2026-09-12

**Source:** a full owner Meadows playtest, 2026-09-12, reproduced verbatim in
`docs/owner/OWNER_PLAYTEST_2026-09-12_MEADOWS_FULL_PLAYTEST.md`. Read that file once
in full for exact wording; work from this document's priority order rather than
re-deriving one from the raw list per task.

The owner's own call: **"close to playable... 70% of the way there."** Also explicit:

> We should finish meadows before doing anything in the next biomes.

## Sequencing supersession — read this before touching any file

`docs/HANDOFF_FULL_GAME_2026-09-11.md`'s Phase 1 named a cross-biome sweep: promote
Meadows POLISH rows, repair Cloudreach's two FAIL rows, fix Stormwood's six FAIL rows,
survey all 24 Water destinations. Under `CLAUDE.md`'s precedence rule (newest owner
direction wins), **this directive narrows that scope for sequencing only**:

- **Do not start Cloudreach, Stormwood, or Water work of any kind** — no grass, no
  cloud banks, no terrain, no FAIL-row repair, no surveying — until the Tier 0 and
  Tier 1 items below are closed and Tier 2's Meadows-visual items are at least at
  the same POLISH bar the 2026-09-11 ledger already reached for the rest of Meadows.
- Everything else in that handoff is unchanged: CI discipline, evidence rules, the
  requirement for production capture + independent review before a ledger promotion,
  and the still-open cross-biome gameplay blockers it logged (underwater/ravine
  combat placement, post-fight input lockup, Cloudreach saddle remount, Pebblik
  texture). Those are Cloudreach-scoped and already recorded in
  `docs/SECOND_PASS_BACKLOG.md` under the 2026-09-11 entries. They stay queued behind
  this directive too — do not use them as a reason to open Cloudreach work early.
- This is a scope narrowing, not a reopening of settled canon. The five-creature
  limit, no-shields, human-never-fights and every other `CLAUDE.md` hard rule are
  unchanged.

## Owner decision made in this pass: the dodge / step-back verb

`docs/specs/COMBAT_DEPTH_PLAN.md` §5 and §9 have named an owner decision as blocking
COMBAT-3 and COMBAT-4 since 2026-09-07: what is the "get out of the way" verb. This
playtest answers it directly: **"There really needs to be a step back and a dodge
button in fighting."**

**Decision: Option B, the burst step (§5).** `A` on the pad becomes a short,
wind-costed dash in the current stick direction, no invulnerability frames. Held back
on the stick, it reads as the requested "step back"; in any other direction it is the
dodge. This does not require inventing a second mechanic.

This unblocks `COMBAT-3` (telegraph retune + burst step) once `COMBAT-1` (poise,
stagger, player wind-up interrupt, hitstop, flinch) and `COMBAT-2` (creature wind) are
in, per that plan's own §8 sequencing — build them in that order, not out of order.
**Not decided by this pass:** §9 items 4 (moves learned by level vs. TM-only) and 6
(type chart to 1.5/0.67). Ask before touching either; nothing here approves them.

The playtest's separate line, "the fighting camera also works poorly," is a distinct
defect from the plan's camera-nudge-on-hit feedback item (§4.5). It needs its own
diagnosis — likely framing/tracking during the fight state, not a feedback tweak —
and is listed separately in Tier 0 below.

## How to work this list

Work Tier 0 first, in any order within the tier — these are correctness bugs and
small, bounded fixes, most well under an hour of implementation each, and they are
what every future playtest will keep tripping over if left in. Tier 1 (wayfinding)
is the owner's own stated **biggest remaining problem** and the highest-leverage
system work in this pass. Tier 2 (visual) is stated **second**. Tier 3 (off-path
content pacing) is stated **third**. Tier 4 (multiplayer UX) is real but was not
named in the owner's own top three — do not let it crowd out Tiers 1–3.

Do not reopen already-exhausted rounds while working this list: Torrentoad's face/
floor-contact (3-round cap reached), the shared creature mipmap candidate, the Warden
staff candidate, Cloudreach grass tuning. Nothing in this playtest mentions any of
them; they stay exactly as `docs/SECOND_PASS_BACKLOG.md` already has them.

---

## Tier 0 — correctness bugs and small bounded fixes

| # | Item | Note |
|---|---|---|
| 1 | One of the two village key-gates doesn't open on key-turn; sinks halfway into the ground instead | Reproduce the specific gate; likely an incomplete open-animation or wrong trigger target, not a design question |
| 2 | Companion creatures walk behind the player, blocking the camera; they should walk beside | Core, constant annoyance during all exploration — highest-frequency Tier 0 item |
| 3 | HUD nags "some creatures need saddles" repeatedly/constantly | Should surface once per relevant state change (e.g. on first unsaddled creature added to party), not as a recurring toast |
| 4 | HUD says "can't throw an orb outside a fight" on every X press outside combat | Same fix shape as #3: suppress the input entirely outside combat, or show the message once, not per press |
| 5 | Team HUD reorders when entering a fight | Party order should be stable across the exploration/combat boundary |
| 6 | Combat-1/2/3 per the owner decision above: poise/stagger/wind-up interrupt, creature wind, telegraph retune + burst step | See `docs/specs/COMBAT_DEPTH_PLAN.md` §4.1–§4.2, §5, §8 steps 1–3 |
| 7 | Combat camera works poorly | Diagnose framing/tracking during the fight state specifically; distinct from COMBAT_DEPTH_PLAN's hit-feedback camera nudge |
| 8 | Wild creatures reappear immediately on returning to a cleared area | Do not remove wild respawn outright — population availability is load-bearing for catching. First move: substantially lengthen the respawn cooldown for a just-cleared cluster. Flag to the owner if a stronger "stays cleared for the session" rule is wanted instead |
| 9 | Multiplayer: the other player is not visible in your game even when co-located; only a "trainer" label shows on the world map | Real correctness bug, not a polish item — likely the remote player's body/replication is not spawning or attaching correctly at the client. Reproduce with two peers in the same cell before attempting a fix |
| 10 | Minimap and full map player-direction triangle point backwards; the tip should be the facing direction | Straightforward heading-vs-icon-rotation bug |
| 11 | No feedback when inventory is full and the player tries to pick something up | Add a clear message on the failed pickup attempt |
| 12 | Riding: the saddle doesn't sit on the creature's back and the character doesn't sit in the saddle | Attachment/rig-fit bug on a core traversal verb, not cosmetic polish — treat as Tier 0 despite the visual symptom |
| 13 | Terrapup doesn't lay down correctly | Animation/pose bug, likely related to the already-logged Torrentoad floor-contact family of issues — check whether the same root cause reaches Terrapup before treating it as a separate one-off |
| 14 | Stamina Shroom's tooltip says it gives defense; that's wrong | Check the item's actual effect against its description and fix whichever is incorrect |
| 15 | Creature menu: the bottom of a creature's power-move stats is cut off / not visible | UI layout clipping fix |
| 16 | Halda's tournament-entry dialogue needs a staged consent flow: "Do you want to enter?" → yes → "Are you ready for round one?" → yes → round starts; repeat the "ready for round N?" step before each subsequent round | Content/dialogue-tree change, bounded |
| 17 | Teleport menu should collapse by biome by default, expanding a biome's destinations only on request | Small UI change; do alongside the wayfinding UI additions in Tier 1 since both touch the same map/teleport surfaces |

## Tier 1 — wayfinding (owner's stated #1 remaining problem)

> "The biggest issue is still not knowing where to go... The whole meadows reads as
> a straight run down a path vs how valheim or palworld read as true open world."

| # | Item | Note |
|---|---|---|
| 1 | A beam/beacon that lights up the next objective, like a squadmate's map-ping in Fortnite | The owner's own proposed solution to the #1 problem. Build this first in this tier — it is the highest-leverage single addition in the whole list |
| 2 | NPCs along the road should tell the player where things are (Burrow Warrens, the pond, alphas), and telling them should reveal that location on the map | Ties the beacon system above to actual dialogue content; the map reveal is what makes the NPC line actionable rather than flavor text |
| 3 | Something should prompt the player to level up and bond with their team while running toward South Bridge | Content/pacing hook on an existing travel stretch |
| 4 | Something should prompt the player to go catch the alpha at the pond | Same shape as #3 — a nudge toward existing content that's easy to miss |
| 5 | Player-placeable map markers, like Valheim | New map feature |
| 6 | A long stretch of the south dirt trail (before the first trail camp) has no creatures for a long time; they resume right before the camp | Check the encounter density/spawn table for that specific stretch; likely a gap in the spawn schedule rather than a design choice |
| 7 | Nothing glows on the path or in the periphery to draw the player's attention off-path | Pairs with the beacon system above but is a separate, smaller signal: passive points-of-interest glow, not just objective-tracking |

## Tier 2 — visual (owner's stated #2 remaining problem)

| # | Item | Note |
|---|---|---|
| 1 | The opening village's shape doesn't read right: house locations, fence locations, and NPC placement inside the circle don't make sense | Needs an actual layout pass, not a prop-density tweak — likely the highest-effort single item in this tier |
| 2 | Mira's house sign looks terrible | Texture/prop fix |
| 3 | Bramblebun loses its color in low light | Cross-reference the shared creature material and night-exposure/fill-floor root-cause work already named in `OWNER_DIRECTIVE_2026-09-09_VISUAL_ROOTCAUSE_PARALLEL_LANES.md` items 2 and 4, and `SECOND_PASS_BACKLOG.md`'s "Shared creature material disposition" entry — this may be the same underlying defect surfacing on a new subject, not a new one |
| 4 | Red flags placed around the world look like paper cutouts | Material/geometry fix on a shared prop |
| 5 | Burrow Warrens approach looks terrible | Distinct from, but likely related to, the already-logged "Warrens interior geometry reads as hard 90° extruded prisms" entry in `SECOND_PASS_BACKLOG.md` — check whether the approach shares the same extruded-prism authoring problem before treating it as separate |
| 6 | Stonewater Reach looks lame | Already named in the Meadows POLISH queue in `docs/HANDOFF_FULL_GAME_2026-09-11.md`; this playtest confirms it independently |
| 7 | Riding doesn't look right (visual half of Tier 0 #12 — the saddle/seat fit) | Fix alongside the mechanical attachment bug; same root cause is likely |
| 8 | The Ironwood tree's color is washed out white with no texture on the approach; the owner still likes its scale but wants the color redone, and thinks a tree that large needs a story reason for being there | Already POLISH in the ledger (R20 identity retained but open on crown flecks, trapped source, night exposure, detached workyard); add the approach-specific washed-out-texture complaint and the lore gap as new, named defects against that same row |
| 9 | A massive Cloudreach silhouette is visible from the end of the Meadows, and the owner doesn't like it | `CLAUDE.md` already requires any reconnection view to be "distant and non-enterable" — that rule stands. This is a request to reduce its visual prominence/scale-in-frame or add atmospheric distance (haze, reduced contrast), not to remove the view or make it enterable |
| 10 | Trees are always dense forest; there should be thinner, more walkable stretches at times, more like Valheim's Black Forest density | Vegetation density variation, not a new asset ask |
| 11 | Sela's dialogue is too long | Trim the dialogue tree |
| 12 | The relay station looks like a toy prop | Scale/material treatment fix |

## Tier 3 — off-path content pacing (owner's stated #3 remaining problem)

> "You need reasons to go off [the path] and things you see that draw you off it."

| # | Item | Note |
|---|---|---|
| 1 | Need more pulls off the main trail: a distant village glimpse, people who give you things, something glowing far off, a cluster of creatures you haven't seen yet | This is content-authoring work layered on top of the Tier 1 beacon/glow systems — those systems are the delivery mechanism, this is what they should sometimes point at besides the critical path |
| 2 | Small potions should do more, or be far more available | Economy/tuning pass |

## Tier 4 — multiplayer UX (real, but not in the owner's stated top three)

Do not let this tier compete with Tiers 1–3 for the next session's time. The one
multiplayer item that belongs in Tier 0 (the other player not actually appearing in
your game) is listed there, not here, because it's a correctness bug rather than a
UX preference.

| # | Item | Note |
|---|---|---|
| 1 | The second player should show up on your map | |
| 2 | Player name tags are too large; each player should get to pick their own name | |
| 3 | Each player should get to pick their own character | |
| 4 | A joining player should start in Grandpa's village | |
| 5 | A joining player should start by getting a creature | |

---

## What this directive does not decide

- COMBAT_DEPTH_PLAN §9 items 4 and 6 (learnset shape, type-chart widening) remain
  open owner decisions. Ask before implementing either.
- Whether wild-creature respawn should have a harder rule than a longer cooldown
  (Tier 0 #8) is flagged for confirmation, not decided here.
- Any Cloudreach/Stormwood/Water work named in `docs/HANDOFF_FULL_GAME_2026-09-11.md`
  or `docs/SECOND_PASS_BACKLOG.md` remains queued exactly as written. This directive
  only reorders what comes first; it does not cancel that work.
