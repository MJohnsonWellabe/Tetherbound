# C1 — The rideable roster, fly and teleport

**Status:** design contract, W19-CONTRACTS lane, 2026-09-04. Written against `main` at
`ef16544f`. Read-only on code and data; every *do* below is an instruction to an
implementation lane, not a change already made. **Source directives:**
`docs/owner/OWNER_PLAYTEST_2026-09-04.md` OP-0904-3 and OP-0904-9,
`docs/owner/OWNER_DIRECTIVES_2026-09-04-B.md` D-0904B-3. Plan rows: CL-O3, CL-O9, CL-W3
in `docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.G; `docs/FINISH_THE_MEADOWS.md` Phase 2a C1.

Precedence is `CLAUDE.md`'s: a newer owner directive beats this file; this file beats a
prompt in `docs/prompts/`. Every contract here has an id (`R1-…`), a **do** block, an
**owns** line and a **fails if** line, the shape `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md`
established.

The owner's words this is built to satisfy:

> Burrowback and the grownup mudsnout should be rideable. Terrapup too. That means the
> other starters have to get special abilities. One should get fly and one teleport. But
> you can't use them till you learn them in the game. Nothing that is rideable should come
> with a saddle on it. You have to build the saddle and put it on then it visually appears.

> the other two starters should not be able to fly or teleport until well after the
> meadows. but they will eventually have that ability to make it a fair choice between the
> three. take terrapup now and you can ride him midway through the meadows. take the others
> and get the better ability but you can't do it until the different biomes where we learn
> those things.

---

## 0. The rules this document is built inside

- **No Biome 2** (`CLAUDE.md`, D23's carve-out). Nothing below builds, names, teaches or
  grants a later-biome ability. The words "fly" and "teleport" appear in this chapter only
  as a *promise* on a UI surface and in one line of Grandpa's. There is no fly code, no
  teleport code, no ability id in `data/`, no move, no TM, no dialogue naming a biome.
- **The Meadows' gates are physical and stay physical.** The severed spokes
  (`scripts/world/severed_spokes.gd`, carve walls at a mean 65.6–72.8°, D50 §4–5, D55),
  the South Bridge (`south_bridge.gd` over `gated_crossing.gd`, opened by
  `south_bridge_key`, flag `south_bridge_open`), the Old Mill Crossing
  (`mill_crossing.gd`, `mill_bridge_gear`), and the Sigil gate on the Hall road
  (`road_gate.gd` with `item_gate.gd`, three Sigils as one lock, 2/3 is sealed) are the
  chapter's structure. **Nothing in this contract goes over, around or through any of them.**
- **Five creatures total; no storage.** A mount costs a slot exactly as it does today
  (`chapter_curve.json` `five_slot._comment_costs` already names "the traversal slot").
- **Riding is a world verb and costs no stamina** (D48). One generic saddle
  (`saddle`, `kind: gear`, stack 1, crafted from `saddle_frame` + Rootstone at the
  Rootstone tier). This contract adds mounts to that mechanism; it does not add a second.
- **No new creature meshes, no Meshy.** The three new mounts are the installed
  Terrapup, Burrowback and Tuskroot bodies. The saddle is the installed
  `assets/props/riding_saddle/riding_saddle.glb`, attached at mount time by
  `riding_controller.gd::_attach_saddle()` and never baked into a species mesh.
- **Creatures loom.** No mount offset, capsule or scale is *reduced* to seat a rider. If a
  rider clips, the fix is the offset, never the creature's size.
- **Starters are exclusive** (D72). No trainer, wild or trade ever fields Terrapup,
  Ripplet or Galewisp; the traversal promise is therefore always about *the player's own*
  starter.

---

## 1. Which starter gets which, and why

| Starter | Type | In-chapter verb | Deferred ability | Why this one |
|---|---|---|---|---|
| **Terrapup** | Ground | **Ride** — from the saddle, mid-chapter | none (riding is its ability, and it is immediate) | boar-sized (D19, 1.90–2.00 m), the one starter whose body already reads as something you sit on; the owner named it |
| **Galewisp** | Air | **Scout** (§4.2) | **Fly** — learned in a later biome | the Air starter with wings; fly is its type's own verb, and a player can see the promise on the body at the pick without being told twice |
| **Ripplet** | Water | **Still Water** (§4.3) | **Teleport** — learned in a later biome | the one starter whose type suggests no traversal verb of its own, so it takes the one ability that is not a body's verb; the name already says what it does — a ripple is somewhere, then somewhere else |

**Decision, recorded here (small, in scope, not an owner question):** Galewisp flies,
Ripplet teleports. The owner said "one should get fly and one teleport" and left the
assignment open. The alternative (Ripplet flies) is not defensible on the installed bodies:
Galewisp has wings and Ripplet does not, and a promise the player cannot read off the
creature in the orb is a promise they will forget. The reverse mapping would need the
starter picker to argue with the model.

**What "learned in a later biome" means here, exactly:** nothing. No later biome exists
in this repository and none is designed by this file. The only artefacts are a
presentation-only block in `species.json` (§3) and the words "beyond the Meadows" on three
UI surfaces (§2). If a later chapter ever ships, it reads that block and grants the verb;
this chapter reads it and prints a tag.

---

## 2. The choice must be legible at the moment it is made

This is the consequence D-0904B-3 tells us to design for rather than discover: two of the
three choices have **no traversal payoff inside this chapter**. That is the intended trade,
and it is only fair if the player knows it when they pick. Three surfaces carry it, in
the order the player meets them.

### R1-1 — The starter picker says it under each orb

*What is there:* `scripts/ui/starter_picker.gd` shows three live orbs
(`data/config/opening.json` `starters.species` = terrapup, ripplet, galewisp) with the
creature turning inside each; no text beyond the name and the confirm glyph.

*Do:* one short caption line per orb, read from the species block (§3), rendered at the
same size and token as the name (`ui_tokens.gd`, no new font), exactly one of:

- **"Rides — mid-Meadows"** (Terrapup)
- **"Flies — beyond the Meadows"** (Galewisp)
- **"Teleports — beyond the Meadows"** (Ripplet)

No paragraph, no tooltip, no second screen. The caption is on screen the whole time the
picker is open and moves with the cursor's focus so a controller player sees it without
pressing anything. The strings are data (`species.json`, §3), never literals in the
picker.

*Owns:* `scripts/ui/starter_picker.gd`, `data/creatures/species.json` (the
`future_traversal` and `rideable` blocks only), `tests/test_starter_traversal_captions.gd`
(new).

*Fails if* a player can confirm an orb without the caption having been visible, if the
caption names a biome, or if the picker contains the substrings "talk" or "choose"
anywhere a prompt could read them (`tests/smoke_opening.gd` finds Grandpa and the starters
by those substrings — `trainer_npc.gd::_prompt_for()` records the same trap).

### R1-2 — Grandpa says it once, in his own voice

*What is there:* `data/dialogue/opening.json` `grandpa_house` ends on
`beat:starter_choice`; `grandpa_first_catch` hands over the pack.

*Do:* **one** line, on `grandpa_house`, immediately before the `beat:starter_choice`
effect, in his warm-and-brief register, saying the trade without a lecture. Reference
wording, tunable by the dialogue lane:

> "The Terrapup'll carry you before the summer's out. The other two — what they can do,
> you won't learn in these fields. Your call."

One line, under 140 characters of speech, no biome named, no mechanic explained. It is
the diegetic half of R1-1: the picker shows it, Grandpa means it.

*Owns:* `data/dialogue/opening.json` (`grandpa_house` only),
`tests/test_opening_beats.gd` (extend: the line exists, precedes the beat, names no biome).

*Fails if* the line is longer than one sentence pair, if it is moved after the pick (it
must inform the choice, not explain it afterwards), or if the total character count of
`grandpa_house` grows by more than that one line (the endgame already lost a playtest to
paragraphs — CL-W7).

### R1-3 — The Team screen carries a "will learn" tag for the whole chapter

*What is there:* `scripts/ui/tab_creatures.gd` shows per-row portrait, name, level,
condition, HP, bond count; the detail column shows type, appraisal, traits and the bond
meter.

*Do:* one tag row in the detail column, under the type line, for the player's starter
only:

- Terrapup: **"Rideable"** before the saddle exists, **"Ride: saddle built"** once
  `saddle` is in the satchel (the same `_has_tack()` answer `riding_controller.gd` gives).
- Galewisp: **"Will learn: Fly (beyond the Meadows)"**.
- Ripplet: **"Will learn: Teleport (beyond the Meadows)"**.

Non-starter mounts (Meadowhart, Burrowback, Tuskroot, Veridian) show **"Rideable"** in the
same slot, so the tag is one uniform field and not a starter special case. The tag is the
in-chapter reinforcement of R1-1: a player who opens the Team screen in Band 3 wondering
what Galewisp is for reads the answer where they are already looking.

*Owns:* `scripts/ui/tab_creatures.gd`, `scripts/creatures/creature_species.gd` (one
accessor, §3), `tests/smoke_creatures_tab_controller.gd` (extend).

*Fails if* the tag is absent on any of the three starters, if it appears on a creature
with neither block, or if the tag row pushes the bond meter below the panel's existing
visible extent on the Ally's 1280×720 (measured, `smoke_hud_handheld_legibility.gd`'s
existing floor).

---

## 3. Data — the one schema change, and what reads it

*What is there:* `data/creatures/species.json` carries a per-species optional `rideable`
block (`can_carry`, `requires_item`, `mount_offset`, `ride_speed_multiplier`,
`dismount_distance`, optional `climb_max_slope_deg`), read only by
`creature_species.rideable()` / `is_rideable()` and consumed by `riding_controller.gd`.
Meadowhart and Veridian carry one today.

### R1-4 — Three new `rideable` blocks; three new mounts

*Do:* add `rideable` to `terrapup`, `burrowback` and `tuskroot`:

| species | `requires_item` | `ride_speed_multiplier` | `mount_offset` | `dismount_distance` | `climb_max_slope_deg` |
|---|---|---|---|---|---|
| terrapup | `saddle` | 1.7 | measured from the installed rig's back line (§3, method) | 1.6 | **absent** (trainer's 45°) |
| burrowback | `saddle` | 1.5 | measured | 1.6 | **absent** |
| tuskroot | `saddle` | 1.8 | measured | 1.8 | **absent** |
| meadowhart *(unchanged)* | `saddle` | 2.0 | as shipped | 1.6 | absent |
| veridian *(unchanged)* | `""` | 2.8 | as shipped | 2.0 | 60 |

Multipliers are **starting points, tunable**, ordered by what the body says: Meadowhart is
the runner, Tuskroot the big one, Terrapup the sturdy boar, Burrowback the digger that
walks. All four saddle mounts sit **below** Meadowhart so the chapter's own normal
rideable creature keeps its identity, and the legendary keeps the top of the ladder.
`mount_offset` is **measured, not guessed**: render each species with
`tools/preview_creatures.gd`, read the back line at the shoulders in the creature's own
local frame, seat the rider a little below it as `meadowhart`'s own `_comment_rideable`
describes, and put the number in the file with the measurement in a `_comment`.

**Mudsnout is not rideable.** The owner said "the grownup mudsnout". A mount you lose
when your creature evolves is a punishment; a mount you *gain* when it evolves is one more
reason to want the Heartstone (`progression.json` `evolution.mudsnout`, level 15 + bond
tier 3 + `heartstone`). D71's second branch, Ashtusk, is not rideable either — the owner
named Tuskroot, and a second rideable evolution would make the Sunstone choice a
traversal choice, which it is not meant to be.

*Owns:* `data/creatures/species.json`, `tests/test_rideable_roster.gd` (new): exactly
five species carry `rideable`; the three new ones require `saddle`; none of the three
carries `climb_max_slope_deg`; every multiplier sits in `[1.0, 2.0]`; Mudsnout and Ashtusk
carry none.

*Fails if* Mudsnout or Ashtusk becomes rideable, if any saddle mount out-runs Meadowhart, if
any of the three carries a climb limit above the trainer's own 45°, or if a `mount_offset`
is committed without its measurement.

### R1-5 — `future_traversal`: a presentation block, never a capability

*Do:* add to `galewisp` and `ripplet` only:

```json
"future_traversal": {
  "kind": "fly",
  "caption": "Flies — beyond the Meadows",
  "team_tag": "Will learn: Fly (beyond the Meadows)",
  "_comment": "C1 R1-5. PRESENTATION ONLY. No script outside scripts/ui/ may read this block. It grants nothing, and the Meadows never teaches it. A later chapter that grants the verb reads `kind`; this chapter reads the two strings."
}
```

(and `kind: "teleport"` with its two strings for Ripplet). `creature_species.gd` gains
**one** accessor, `future_traversal_presentation(id) -> Dictionary`, that returns the two
strings and nothing else — it does not return `kind`, so no runtime script can branch on
it by accident. Terrapup carries **no** `future_traversal` block; its caption ("Rides —
mid-Meadows") is derived by the picker from the presence of `rideable` +
`requires_item: saddle`, so the two promises cannot drift apart in data.

*Owns:* `data/creatures/species.json`, `scripts/creatures/creature_species.gd`,
`tests/test_rideable_roster.gd` (extend): the accessor returns strings for exactly
Galewisp and Ripplet, empty for every other species; `rideable("galewisp")` and
`rideable("ripplet")` are empty; **no** species carries both blocks.

*Fails if* any script outside `scripts/ui/` calls the accessor (enforced in the test by
instantiating `riding_controller.gd`, `player_controller.gd`, `follower_creature.gd`,
`combat_manager.gd` in isolation and asserting none exposes a method or property
whose name contains `fly`, `teleport` or `traversal` — real behaviour, not a grep), or if
a `kind` value ever reaches the picker or the Team screen (they receive strings).

---

## 4. What each starter gives INSIDE the Meadows, so no choice is punished

The chapter must be completable and satisfying with any of the three. That was already
true (no gate in the chapter needs any specific starter) and stays true. What this section
adds is that each starter has **one thing it does here that the others do not**, so the
deferred-ability players are not spending three hours holding a promissory note.

### R1-6 — Terrapup: Ride, from the saddle, mid-chapter

*What "midway" is, measured against the shipped chapter:* the saddle is
`recipes_rootstone.json`'s `saddle` (`saddle_frame` + Rootstone + wood + fiber), and the
first Rootstone the player can reach is the Old Quarry floor at (400, 1800) — the start of
Band 2, `chapter_curve.json` `band2_stone_and_root`, whose `tools` row already lists
"riding saddle". Band 2 is the middle band of five and its start sits at roughly 40% of
the critical path's clock (`tools/_probe_pacing.py`). That is "midway through the
Meadows" without a new gate, and it is the same moment a Meadowhart rider unlocks.

**The starter's payoff is not that Terrapup rides earlier than Meadowhart. It is that a
Terrapup player rides the creature they have carried since the farmhouse, in the slot
they already spent, without catching a mount.** A Galewisp or Ripplet player who wants
to ride in this chapter spends one of five slots on Meadowhart, Burrowback or Tuskroot —
`chapter_curve.json`'s "traversal slot", now a real choice rather than the only option.

*Do:* nothing beyond R1-4. The timing lever, if the evidence run finds the saddle lands
too early for "midway", is **an optional `requires_bond_tier` key on the `rideable`
block** (D70's ladder, read through `bond_milestones.gd`), defaulting to 0 and refused by
`riding_controller.gd::_riding_allowed()` with the same prompt shape as a missing saddle
("Terrapup isn't ready to carry you yet"). It is the *only* sanctioned lever: the saddle
is the owner's own "build it and it appears" rule and is not to be moved later in the
chapter to fake a midpoint.

*Owns:* `scripts/world/riding_controller.gd` (the optional bond-tier refusal only),
`tests/smoke_riding.gd` (extend: Terrapup mounts with a saddle in the satchel and refuses
without one; the saddle mesh is absent before and present after; the rider's model is
visible while mounted — CL-O3's own criterion, shared).

*Fails if* Terrapup can be ridden before a saddle exists, if a saddle is visible on any
rideable body at spawn (CL-O3's rule: `tests/smoke_riding.gd` must assert every rideable
species spawns with no node named `RidingSaddle` under it), or if the saddle recipe is
moved off the Rootstone tier to change the timing.

### R1-7 — Galewisp: Scout — the map from an overlook, never the body over a gate

Fly, foreshadowed by the one thing a flying creature can do without moving the player:
see.

*Do:* at a landmark whose `map_landmarks.json` entry carries `overlook: true` (add the key
to: the Rise crest at the pond-circuit trailhead, the quarry rim overlook at (310, 1660),
the wind ridge at (450, 5860), the ruined watchtower at (−280, 6460) — the four places
`MEADOWS_MACRO_LAYOUT.md` §3.2 already calls overlooks), a deployed Galewisp offers one
extra prompt through the ordinary arbiter: **"Send Galewisp up"**. On press: the follower
plays its existing jump/idle-flap animation for ~3 s at its own position, the camera does
not move, the player does not move, and `MapState.reveal_circle(landmark, 300)` plus
`discover_landmark()` for every configured landmark inside that radius fire. Once per
overlook per save (flag `scouted:<landmark_id>` in the existing progression store).

What it is: the map's own reveal mechanism (`map_state.gd::reveal_circle`, shipped) fired
from a place the design already calls a vista. What it is **not**: traversal. The
creature's collision body never leaves the ground; no node is moved; there is nothing to
fly over.

*Owns:* `data/config/map_landmarks.json` (`overlook` key), `scripts/creatures/follower_creature.gd`
(the offer), `autoload/map_state.gd` (no change expected — `reveal_circle` exists),
`tests/test_map_landmarks.gd` (extend: exactly four overlooks; each is a configured
landmark), `tests/smoke_scout.gd` (new: deploy Galewisp at the Rise crest, press, assert
`discovered_fraction()` rose and the player and creature positions are unchanged within
0.05 m; deploy Terrapup at the same spot and assert no such prompt is offered).

*Fails if* Scout moves the player or the creature, if it works away from an overlook, if it
works with a non-Galewisp deployed, or if the reveal radius exceeds the 300 m the alpha
pin uses (CL-W1) — the map must not become the radar `GAME_VISION.md` §5 forbids.

### R1-8 — Ripplet: Still Water — the water band is hers

Teleport has no honest preview that is not traversal, so Ripplet's in-chapter payoff is
*not* a preview. It is the band with the most catchable species (Band 3, 14 distinct —
`chapter_curve.json` `five_slot._comment_options`) belonging to the Water starter.

*Do:* a `catch_affinity` block on `ripplet` in `species.json`:
`{"type": "water", "bonus": 0.15}`. `scripts/combat/catch_math.gd` reads it through one
new term: when the player's **active** creature carries a `catch_affinity` whose `type`
matches the wild's type, the computed chance gains `bonus` (additive, after every other
term, clamped as today). Ripplet is the only species that carries one in this chapter.
The catch reticle's existing percentage (D31, an explicit percent) shows the raised number,
so the payoff is visible on every throw at the Pond, the stream, the river and the
Riverwatch nest without a line of text.

The reason this is the right shape: the five-slot pressure is the chapter's centre, and a
Water starter making Water catches easier makes the Band 3 temptation *sharper* for
exactly the player who chose the deferred ability. It is a team-building payoff for a
team-building game, and it costs no new system.

*Owns:* `data/creatures/species.json`, `scripts/combat/catch_math.gd`,
`tests/test_catch_math.gd` (extend: with Ripplet active, a Water wild's chance is +0.15
over the same throw with Terrapup active; a Ground wild's chance is unchanged; the clamp
holds).

*Fails if* the bonus applies when Ripplet is in the party but not active, if any other
species gains an affinity in this chapter, or if the bonus can push a chance above the
existing ceiling.

### R1-9 — All three: combat coverage against the chapter's authored teams, stated

Not a change — a fact the lanes must not break, recorded so the trade reads as balanced.
`data/config/type_chart.json`: Water hits Ground at 1.25; Air hits Water at 1.25; Ground
hits Air at 1.25. The authored critical-path teams:

| Gatekeeper | Team | Best starter answer |
|---|---|---|
| South Bridge grunt | Mudsnout 10, Burrowback 12 | Ripplet (Water over Ground) |
| Captain Vance | Galecrest 11, Duskhush 11, Tuskroot 12 | Terrapup on the birds; Ripplet on the ace |
| Captain Oreth (Riverwatch) | Mosshell 13, Trailpup 14, Brooktail 15 | Galewisp (Air over Water) |
| Captain Halder (Field) | Duskhush 13, Tuskroot 14, Meadowhart 15 | Terrapup / Ripplet |
| Captain Vess (Ridge) | Trailpup 14, Duskhush 15, Galecrest 16 | Terrapup (Ground over Air) |
| Warden Aldis | Burrowback 18, Galecrest 18, Brooktail 19, Meadowhart 19, Tuskroot 20 | every starter has two good matchups and one bad |

Each starter is the *best* answer to at least one gatekeeper and the *worst* to at least
one. No starter is the answer to the whole ladder. `tests/test_trainers_data.gd` gains one
assertion that this remains so (computed from the type chart and the authored teams, not
from this table).

*Fails if* a retune leaves any starter with no gatekeeper it is favoured against, or with
none it is disfavoured against.

---

## 5. The hard limits — the chapter's gates stay shut

These are the *design* of the unlock, per the owner's directive as read in
`OWNER_PLAYTEST_2026-09-04.md` OP-0904-9: "the unlock and its limits are the design, not
the ability." Every one of them is enforced by a test that watches a body fail to cross.

### R1-10 — No verb in this chapter has a vertical component

*Do / keep:* `riding_controller.gd` drives the mount through
`creature_body.request_move(direction, speed)` on the ground plane and nothing else
(D48 §2). When CL-O3 restores sprint and jump while mounted, the mounted jump uses the
**trainer's own** `movement.json` `jump` values applied to the mount's `CharacterBody3D`
and no larger — a mounted jump reaches no higher than a dismounted one.

*Test:* `tests/smoke_riding.gd` (extend) mounts each of the five rideables in turn and
measures peak height gained from a jump on flat ground; every value is within 0.1 m of
the trainer's own unmounted jump apex.

*Fails if* any mount jumps higher than the trainer, or if any script gives a creature body
a positive vertical velocity outside `move_and_slide`'s own gravity and jump path.

### R1-11 — Nothing rides over a locked spoke, the Sigil gate or the South Bridge

*What is already true and is now pinned for the new mounts:* `tests/smoke_riding.gd`
already asserts the spoke carve walls stay above the ridden legendary's 60° limit
(`SHALLOWEST_SPOKE_WALL_DEG := 65.0`); `tests/smoke_boss.gd` walks a body at the
legendary's climb limit into the storm-road seam before and after `legendary_freed` and
fails if it crosses.

*Do:* extend `smoke_riding.gd` with a **gate sweep** run on **each of the three new mounts
plus Meadowhart**: (a) ride at the South Bridge gully from the village side with no key —
the body stays on the near side (`gated_crossing.depth_past_crossing()` never goes
positive); (b) ride at the Sigil gate's wings with 0/3 and 2/3 Sigils — the body stays
north of the piers; (c) ride at each of the four prop/built spoke blockers (`mountain_trail`,
`high_pass`, `stone_gate`, `blighted_road`) and each of the three carves (`river_gorge`,
`cliff_road`, `storm_road`) — the body's distance along the spoke's axis never exceeds the
blocker's. Each case runs with sprint held and with a buffered jump, once CL-O3 lands those.

*Owns:* `tests/smoke_riding.gd`. No world file changes: if a mount gets across, **the
mount is wrong, not the gate** (a climb limit crept in, a jump was over-tuned), and the fix
is in `species.json` or `riding_controller.gd`, never in `terrain_playground.json`.

*Fails if* any mount crosses any of the nine sites in either input mode, or if the fix for
a crossing touches a gate, a carve or a fence.

### R1-12 — The Sigil gate and both crossings are indifferent to what you arrive on

*Keep:* `item_gate.gd` asks the inventory for the key and the progression store for the
flag; it never asks what the player is standing on. `gated_crossing.gd::_on_tried()` and
`road_gate.gd`'s equivalent are interact prompts through the arbiter, which
`riding_controller.gd::_riding_allowed()` already yields to. A mounted player who rides up
to a locked gate gets the same jar and the same silence as a walker.

*Test:* `tests/test_item_gate.gd` (extend) opens each gate with the key while a fake
"mounted" state is set and asserts the outcome is identical to unmounted; `smoke_riding.gd`
(extend) rides up to the South Bridge with the key and opens it from the saddle.

*Fails if* mounting changes any gate's answer in either direction.

### R1-13 — The promise never becomes a system by accident

*Do / keep:* no file under `scripts/`, `autoload/` or `data/` (outside `species.json`'s
two `future_traversal` blocks and the three UI strings they feed) contains an ability,
move, TM, recipe, dialogue effect, flag id or objective for fly or teleport.
`tests/test_moves_data.gd` (extend) asserts no move id, TM id or dialogue `effect:` string
in the shipped data begins with `fly`, `teleport`, `warp`, `blink` or `glide`. That test is
behavioural on the data it loads (it walks `moves.json`, `tm_db`, every conversation's
effects) and not a source grep.

*Fails if* any such id lands in this chapter's data, however inert.

---

## 6. The saddle — the owner's rule, shared with CL-O3

Stated here because it is part of the unlock's meaning; the code work is CL-O3's
(`docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.G, "Riding is unfinished three ways").

- **A rideable species ships with no saddle.** No species mesh, scene or material carries
  one. `tests/smoke_riding.gd` asserts every rideable species spawns with no `RidingSaddle`
  node beneath it.
- **The saddle appears on the body only once built and fitted.** Today
  `_attach_saddle()` fires on `mount()` and `_detach_saddle()` on `dismount()`. *Do (CL-O3):*
  once the `saddle` item is in the satchel, the saddle stays attached to the **deployed**
  rideable creature between rides (attach on deploy, detach on dismiss), so the built thing
  is visibly worn — the proof of the craft the unlock is built around. A rideable creature
  with no saddle in the satchel wears nothing, and the prompt reads "Terrapup needs a
  Riding Saddle." exactly as it does for Meadowhart today.
- **The rider is visible and can sprint and jump while mounted** — CL-O3, owner-reproduced
  defects, not this contract's to specify beyond R1-10's ceiling.

*Fails if* any of the three saddle rules is closed by a per-species exception.

---

## 7. What is deliberately not in this contract

- **Which biome teaches fly or teleport, when, or how.** Not designed. Not named.
- **A stamina, cooldown or distance cost on riding.** D48 §3 chose none and named the
  honest place for one if ever needed; nothing here reopens it.
- **Species-specific saddles.** One generic saddle (D48 §4). Tuskroot's larger back is a
  `mount_offset`, not a second item.
- **Riding in combat, riding into a fight, or a mounted catch.** A ride ends on the same
  modal lockout that ends it today (`sequence_director.gd::_refresh_lockout()`).
- **A second mount for the Warden's or any trainer's creature.** Trainer-owned creatures
  cannot be caught; nothing here changes that.

---

## 8. Implementation slices

Each slice ships alone, on its own `ralph/**` branch, with its tests seen to fail first.
Order matters only where stated.

| Slice | Do | Owns | Tests to pin | Size |
|---|---|---|---|---|
| **C1-S1 data** | R1-4, R1-5: five `rideable` blocks, two `future_traversal` blocks, the one accessor, measured `mount_offset`s | `data/creatures/species.json`, `scripts/creatures/creature_species.gd` | `tests/test_rideable_roster.gd` (new) | S |
| **C1-S2 legibility** | R1-1, R1-2, R1-3: picker captions, Grandpa's line, Team-screen tag | `scripts/ui/starter_picker.gd`, `scripts/ui/tab_creatures.gd`, `data/dialogue/opening.json` (`grandpa_house`) | `tests/test_starter_traversal_captions.gd` (new), `tests/test_opening_beats.gd`, `tests/smoke_opening.gd` (must stay green — the "talk"/"choose" trap), `tests/smoke_creatures_tab_controller.gd` | S–M |
| **C1-S3 mounts** | R1-6, R1-10, R1-11, R1-12: the three mounts ride, refuse without a saddle, and fail the nine-site gate sweep; shares CL-O3's rider/saddle/sprint/jump work and lands **after** it | `scripts/world/riding_controller.gd` (bond-tier refusal only) | `tests/smoke_riding.gd` (extend), `tests/test_item_gate.gd` (extend), `tests/smoke_boss.gd` (unchanged, must stay green) | M |
| **C1-S4 Scout** | R1-7 | `data/config/map_landmarks.json`, `scripts/creatures/follower_creature.gd` | `tests/test_map_landmarks.gd`, `tests/smoke_scout.gd` (new) | M |
| **C1-S5 Still Water** | R1-8 | `data/creatures/species.json` (`catch_affinity`), `scripts/combat/catch_math.gd` | `tests/test_catch_math.gd` | S |
| **C1-S6 the fence** | R1-9, R1-13: the coverage assertion and the no-such-id assertion | — (tests only) | `tests/test_trainers_data.gd`, `tests/test_moves_data.gd` | S |

**Dependency:** C1-S3 lands after CL-O3 (rider visible, sprint/jump, saddle-on-deploy),
because R1-10's jump ceiling and R1-11's jump-mode sweep have nothing to measure until a
mounted jump exists. C1-S1, S2, S4, S5 and S6 have no dependency on each other or on
CL-O3.

**Evidence the band lanes score:** a fresh player picks each starter in turn on the
`smoke_opening` path and, without reading any document, can say at the pick what their
starter will do and when. A Terrapup player rides in Band 2 without catching anything. A
Galewisp player reveals the quarry from the rim. A Ripplet player catches a Brooktail at a
higher shown percentage than a Terrapup player does. No player, on any mount, is ever on
the far side of a gate they have not opened.

---

## 9. Where this touches other contracts

- **C2** (`C2_TASK_FEED.md`): Scout's `discover_landmark()` calls feed the map pins C2
  relies on; the alphas task uses the same 300 m radius. No shared file.
- **C4** (`C4_CAMPING_NECESSARY.md`): riding halves travel time on the spine and therefore
  the *distance* lever there is stated in in-game days, not metres. Riding costs no stamina
  and does not pause satiety (D48 §3), so a rider still meets night.
- **CL-W6 / prompt 73:** bond visibility. `requires_bond_tier`, if ever set, must show its
  target on the Team screen through prompt 73's ladder, never as a hidden refusal.
- **D75** (level-gate placement): a mount does not change any `min_level` check; the
  refusal is a trainer's and is indifferent to the saddle.
