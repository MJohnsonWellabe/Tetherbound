# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `🔒` needs Meshy credits. `model:` the cheapest tier that can do the
job. `tests:` exactly what to run.

**Owner play gates were retired 2026-08-16.** Every `▶` gate (`R2.9`, `R4.12`,
`R6.3`, `MQ1-gate`, `SH53`, and the `R9.5` exit gate) is gone by owner
directive, along with the pointer to the owner-only blind-playtest protocol.
`docs/decisions/D21` stays as history and reads as superseded, not violated.
The loop no longer parks on a gate — see `ralph/PROMPT.md` for what it does at
the end of the backlog.

**`model: fable` (owner directive, 2026-08-12) is not "the cheapest tier that
can do the job" — it is a hard floor.** These items are ceiling-setting
narrative or aesthetic authorship (world-building, story beats, dialogue, or
"does this actually look right" visual-direction judgment calls) where a
weaker first pass becomes the ceiling a later pass can't rescue. **Any firing
that reaches a `model: fable` item must not do the creative work in its own
session, regardless of which lane it is** — see `ralph/PROMPT.md`'s
"Fable-tagged items" section for the dispatch rule.

**Standing task, every visual milestone:** re-shoot the website's screenshots
after any milestone that changes how the game looks. `model: haiku` when it is
just screenshots.

---

## Phase -1.5 — the owner played the ROG build (owner-reported, 2026-08-16)

Reported from the real handheld, which is the instrument no test in this repo
substitutes for. **Three of these have been "fixed" before** — check the current
build before rebuilding, then fix the mechanism rather than the symptom, because
the symptom has come back every time so far.

The owner also asked whether they were on an old build. Partly answered here:
`OW3`'s fog does not exist in code at all, and `OW1`'s hotbar has no separate
section *by design* — so those two are real regardless of build age.

### OW10 — A menu does not own the d-pad, so navigating a menu uses a potion
`model: opus` · `tests: smoke_menu, smoke_modal_stacking, test_inventory` · `area: ui`
Owner, 2026-08-16: *"the inputs don't know how to read menus. so if I have a menu
up and hit a dpad button, it still reads the hot bar control not to the menu. it
tries to use a potion or whatever rather than move on the menu."*

**Game-breaking. The mechanism below is PARTLY WRONG and was corrected by
measurement before anyone worked it — read the correction before the claim.**

The original filing said: `playground_hud.gd::_read_hotbar_input` (1161) has
exactly two gates — a fight is running, and the interaction arbiter's `enabled`
flag is false, which covers the *story* modals only (a conversation, the naming
prompt, the starter picker, set by `sequence_director.gd::_refresh_lockout`) —
so nothing gates it on a panel being open and a d-pad press spends a hotbar slot.
`_read_world_hotkeys` (1373) has the same two gates plus `_build_menu_is_open()`.

**Those two gaps are real. The conclusion drawn from them was not.** A probe
booted the real world, opened the backpack tab, injected a real `hotbar_2` press
and watched the potion count: **5 → 5, no leak.** `game_menu.gd::open()` pauses
the tree, and `PlaygroundHUD` (`scenes/ui/playground_hud.tscn`) declares no
`process_mode`, so it inherits `PAUSABLE` and `_process` does not run at all
while the pause shell is up. **The pause shell is covered by the pause, not by
the gates.**

So the owner's bug is a panel that does **not** pause the tree. Candidates, in
the order worth probing: the build menu, an interact/dialogue panel, the naming
prompt, the starter picker, the combat HUD. **Reproduce it and name the panel
before writing a fix** — this phase's header exists because three of these
reports have been "fixed" before against a guessed mechanism.

Also struck from the original filing: the blind playtest's
"stray-confirm-picked-up-an-orb-stack" was cited as evidence of a leak. It is
not. That press is `ui_accept`, which under the pause shell is the backpack's own
move verb behaving as designed but silently — i.e. it is `OW1`'s symptom, not
this one's. `OW4` may still be related; that is untested.

`combat_hud.gd:725-737` documents the mirror of this leak and calls it "a
documented, pre-existing gap." **Half of that comment is now stale** — it claims
`playground_hud.gd` "polls its hotbar with no combat gate at all", and the combat
gate exists today. The menu half was never closed. Correct the comment as part of
this.

**Do not add a third ad-hoc gate.** Two have been added one at a time (HD2 for
combat, OF25 for story modals) and a third arrives the moment a fourth panel
exists. The mechanism is that world verbs are polled from `_process` with
`Input.is_action_just_pressed`, which is a global read with no concept of one
consumer taking a press before another. Give the game **one authoritative answer
to "who owns input right now"** and have every world-verb poll ask it.

**Likely upstream of two open items.** `OW4`'s potion picker dead end and the
blind playtest's stray-confirm-picked-up-an-orb-stack are both consistent with
world verbs firing under a panel. Check them against this before fixing either
separately.

**Done when** no press that a menu is meant to consume also reaches the world,
on a gamepad, with a regression test that fails on today's build.

### OW11 — Building happens through a menu you cannot see past
`model: opus` · `tests: smoke_free_build, test_build_grid` · `area: ui`
Owner, 2026-08-16: *"building needs to work how Valheim does. you get a piece
then the menu disappears for you to place it. right now it's asking you to build
through a menu and you can't see shit."*

**Read `scripts/build/build_placer.gd` before assuming this is unbuilt.** Its
header (145-153) records that the ghost/rotate/snap/grid system "was working the
entire time" and that `build_menu.gd::_pick()` already arms `pending_build` and
closes the menu on the same press. A `build_open` hotkey and a `torch_place`
hotkey both already hand off to the placer directly
(`playground_hud.gd:1360-1390`). So the Valheim shape may be most of the way
there and the defect is the **selector** in front of it, not the placement.

Establish what the player actually sees first: how the build menu is reached
(the pause shell's Build tab versus the direct `build_open` hotkey), how much of
the screen it covers, and whether the armed ghost is legible once it closes. The
owner's "can't see shit" is the symptom to reproduce — decide from a real frame
whether it names the selector's opacity, the ghost's readability, or the trip
through the pause shell.

Keep what works. `build_grid.gd` is pure, tested, and shared with the authored
`building_prefabs.json` grid so player-placed and author-placed walls land on the
same lines; nothing here should touch it.

**Done when** picking a piece takes the player straight to placing it in the
world with the world visible, and the ghost reads at a glance.

### OW12 — The torch should be a carried item, not a thing you build
`model: sonnet` · `tests: smoke_playground, test_inventory` · `area: ui`
Owner, 2026-08-16: *"torches need to be a carry able item not placeable one."*

**Both halves already exist, which makes this smaller than it sounds.** A carried
torch is real — `scripts/player/torch.gd` bone-attaches it, and `items.json:550`
names it as the pattern `tool_hold.gd` copied for tools. A placeable torch is
also real — `buildables.json:121-133`, free to build.

**This supersedes `OF24`, and that should be said out loud rather than quietly
undone.** `OF24` was itself an explicit owner directive — *"Torch building should
be free"* — and `buildables.json:133` records it verbatim. The newer word wins
(the same rule D23 applies to the spec), but leave the old `_comment_free` in
place with a note naming this item, so the reversal is legible to whoever reads
that file next.

Working assumption, cheap for the owner to reverse in one line: the carried torch
becomes the real one and reaches the hand from the inventory the way a tool does;
the buildable is retired rather than kept as a second path. If retiring it
strands camp lighting at night, say so instead of inventing a replacement.

**Done when** a player can take a torch out of the backpack and carry it lit,
and is not offered a torch to build.

### OW1 — Inventory items cannot be moved, and the hotbar has no home in the UI
`model: opus` · `tests: smoke_menu, test_inventory` · `area: ui`
Owner: *"I can't move things in my inventory. There's no separate hot bar
section. I can't move anything into it."*

Both halves are real and they are one problem. The move verb **does** exist —
`tab_backpack.gd:487` renders "holding slot N — choose where it goes" — so items
can be picked up and placed. The owner could not operate it. The blind playtest
hit the same wall from the other side: a stray confirm press picked up an orb
stack with no way to tell what had happened.

The hotbar has no section because slots 0–4 of the backpack **are** the hotbar
(`tab_backpack.gd:46-56`, `playground_hud.gd::_update_hotbar`). That is a
deliberate design, and the mitigation shipped for it was a badge on those five
slots. The badge is not landing: the owner looked for a hotbar, did not find
one, and concluded he could not put anything in it.

Note `d21f32ce` shipped "an assignable hotbar" after most of that reasoning was
written — establish what the current behaviour actually is before changing it.

**Done when** a player can move a stack to a chosen slot and can tell, without
being told, which slots are the hotbar and that they just changed one.

### OW2 — The opening does not advance reliably, and text entry is bad
`model: opus` · `tests: smoke_opening, smoke_name_prompt_keyboard` · `area: ui`
Owner: *"The initial scene didn't move every time I hit x. The initial keyboard
sucks."*

The unreliable advance is the more serious half and matches a defect already
root-caused during the blind playtest: `starter_picker.gd` polled its inputs in
an `elif` chain, so a confirm landing on the same physics frame as a direction
press was dropped permanently. That specific chain is fixed (`6be2ce87`), but
the owner is describing the same *class* of failure on the dialogue advance —
audit the other polled `_physics_process` input readers in the opening path for
the same shape rather than assuming the one fix covered it.

The keyboard is the naming grid. Related: `PT-04`, which is unconfirmed and
needs exactly this — a real-window check on hardware. This report may be that
confirmation; treat the two together.

### OW3 — The whole map is revealed before you explore anything
`model: sonnet` · `tests: smoke_menu` · `area: ui`
Owner: *"The full map is rendered before I explore anything."*

**Confirmed in code, not just reported:** `scripts/world/map_baker.gd` contains
no fog, reveal, explored or discovery logic of any kind. Spec §16's rule — the
map reveals explored areas and landmarks and *never reveals everything
automatically* — was never built. This is the surviving half of `R7.4` and the
owner has now hit it; do that item's remainder here.

### OW4 — Choosing which creature to use a potion on is a dead end
`model: opus` · `tests: test_inventory, smoke_menu` · `area: ui`
Owner: *"When I use a potion I get to the screen to choose the creature then you
can't choose."*

**Second report of this exact dead end.** `OF22` (`6026fc60`) shipped as "fix the
full-menu potion picker dead end and lost focus" and it is back, or never left on
hardware. The picker's focus path is `tab_backpack.gd`'s `_targeting` block
(`:115-131`, `_first_eligible_target_row`, `_on_target_row`).

Given it has already been fixed once, do not re-fix the focus placement blind:
reproduce it first, on a build, with the same inputs the owner used. If it only
fails on a gamepad, that is the finding.

### OW5 — The Meadows should be a long journey from home, not a compact square
`model: fable` · `tests: smoke_traversal` · `area: terrain`
**The owner's world-shape directive, and the largest item in this phase.**

Owner: *"The meadow needs to read as a long journey away from home ending at the
stronghold. But the whole area should be a big square. It's a long trail working
progressively further from Grandpa's house. You can go off the trail for
different tasks. It can wind and fork and whatever but this should be the
general layout. Walking end to end should take several in game days so you have
to camp along the way."*

**SUPERSEDED IN PART, 2026-08-16, by the owner in conversation. The square is
gone.** Recorded here because it existed only in a chat thread, and a decision
document was already citing it while this entry still said the opposite — the
same failure that made a sibling session paint the roster against boards it
could not see (`docs/HANDOFF_2026-08-16_colour_and_brief.md`). His words:

> *"the world should be long but can be narrow with broken land or sea off the
> path in either direction. it doesn't have to be a giant square. it should be
> long as I've stated but can be significantly less wide. like maybe it's five
> minutes of walking from side to side."*

> *"a day from midnight to midnight should take about 10 minutes. a walk from
> the end of the meadows to the other end should take 40 minutes."*

At `walk_speed` 5.0 and `day_length_seconds` 600 that is **~12,000 m of trail**
and **~1,500 m of width**. Everything else below stands.

One arithmetic caution for whoever sizes it: 40 minutes is a *walking* figure,
and a player who cycles sprint sustains about 7.0 m/s once
`stamina.regen_delay` 1.1 and `regen_per_second` 18 are both counted — roughly
28 minutes for the same trail. Size to the directive, but know the spread.

So: a long, narrow **corridor**, with a winding, forking **trail** through it
that carries the player progressively away from home and ends at the stronghold.
Off-trail is where optional work lives, and the flanks are broken land or sea.
The end-to-end walk must be long enough that camping on the way is forced rather
than optional — which is what finally gives `camp` a job beyond the first night,
and what makes the stronghold read as far away instead of nearby.

This supersedes `R7.3`'s framing. R7.3 keeps only its bake-and-capacity half
(does the terrain footprint and Terrain3D region count support this, and what
does it cost on the Ally). **The shape is this item.**

Read `ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md` §5 (`MQ2A`, the Meadows
macro-world redesign) before starting — it is the existing quality brief for
exactly this work and it says START WITH FABLE.

**Done when** walking the trail end to end takes several in-game days, the
stronghold is visibly the far end of a journey rather than a neighbour, and the
existing regions (quarry, warrens, river, relay, Ironwood) hang off a trail
rather than sitting near the start.

### OW6 — The captain you can challenge is too close to the start
`model: sonnet` · `tests: none` · `area: village`
Owner: *"The captain to challenge is way too close to where you start. You need
to work to find him."* Positions are data (`data/config/trainers.json`), so this
is a placement change once `OW5` establishes the trail — sequence it after, or
it gets moved twice.

### OW7 — Gatherable wood does not look like wood
`model: sonnet` · `tests: smoke_playground` · `area: vegetation`
Owner: *"Wood to pick up doesn't look like wood. It's just random yellow glowing
spots."*

The glow is the interact affordance reading louder than the object under it —
so either the node has no real mesh at this distance, or the highlight is
swamping it. Note `OF20` (`f868aa95`) fixed harvest nodes that were *invisible*
because of a dead `PackedScene` assignment; this may be the same area healing
badly. A player should be able to name what they are about to pick up before the
prompt tells them.

### OW8 — The "put away" prompt still sits on top of the hotbar
`model: opus` · `tests: smoke_playground` · `area: ui`
Owner: *"The put pup away text still lays over the hot bar."*

**Third report. Two fixes have already shipped** — `OF17` (`cee57f0c`, "the
recall/put-away prompt still overlapped the hotbar") and `80860c46` ("place the
context prompt from the hotbar's real edge, not a magic number") — and it is
still there on hardware.

Stop nudging offsets. Two fixes have moved numbers and it has come back both
times; the third attempt should make the collision structurally impossible (one
bottom-anchored container that owns both, so neither can be positioned into the
other) and add a test that fails when their rects intersect at a realistic
prompt length, on a handheld-width viewport rather than a desktop one.

### OW9 — Nobody tells you to gather, to craft orbs, or to build a camp
`model: fable` · `tests: test_dialogue_runner, test_progression_state` · `area: npc`
Owner: *"Someone at the beginning needs to tell you to go gather materials to
build things like orbs. Someone else will need to tell you to get wood and build
a base camp. They should probably give you a hammer and recipe."*

Two handovers, two different speakers, both in the opening band. The precedent
is `OF30` (Tam gives the axe, the pickaxe and the basic-orb recipe) — the
machinery for a one-time gift plus a recipe unlock already exists and is tested;
this is a second use of it, plus the dialogue that makes the player *want* the
materials before they are handed the means.

The hammer is the build tool and already exists as an item. Sequence the two
beats so the player is told to gather *before* they are told to build, and so
neither instruction arrives while they are still indoors.

---

## Phase -1.4 — the blind playtest's open findings (2026-08-15/16)

Full record in `docs/reviews/2026-08-15-full-blind-playtest/`. The six repairs
that pass already shipped; these are §7's leftovers. `PT-03` is the one the
report calls the highest-value remaining fix for a first-time player.

### PT-03 — Make the opening staircase readable
`model: fable` · `tests: smoke_opening` · `area: village`
Two testers (one of them the owner, twice) could not find the way out of the
opening loft. The flight is a narrow slot behind a parapet in the room's NW
corner, entered from the north, descending south; from every vantage a player
naturally occupies it reads as more parapet. `grandpa_house.gd::_build_stairs()`
(272-282) builds it; the `stairs_top`/`stairs_bottom` markers already exist
(132-133) and `_build_lights()` (438-447) puts no light near either. The loft
beam deliberately stops short of the opening (252-258), so nothing frames it.
**Owner picks the affordance** — a warm light at the stair head, geometry that
frames rather than avoids the opening, or a look-toward bias on the interior
camera profile the house already swaps to on entry (57, 464-470). Done when a
player who has never seen the room finds the stairs without being told.

### PT-15 — Unfocused starter portraits render ghost-white
`model: sonnet` · `tests: smoke_starter_picker` · `area: ui`
On `7547f386` all three portraits rendered in full colour; on `9e4a90a1` the two
unfocused ones are pale silhouettes. Suspected regression from the shiny repaint
(`OF27`/`OF28`). Verify against both builds before changing anything.

### PT-17 — No way to rename a creature
`model: sonnet` · `tests: test_party` · `area: ui`
A name is settable exactly once, in the opening. `name_prompt.gd`'s only caller
is `sequence_director.gd`; `tab_creatures.gd` only ever reads `nickname`. One
mis-navigated press in the opening names a creature forever.

### PT-23 — Autosave only ever fires at camp rest
`model: sonnet` · `tests: test_save_format` · `area: ui`
`camp.gd:184-187` is the sole caller of `autosave_slot()` in the whole codebase.
Building a camp is a mid-session action, so a new player has no autosave at all
for their entire first session. Add a fallback cadence (day rollover, or a
timer) that does not depend on having built anything.

### PT-04 — Naming field reportedly ignored typing
`model: haiku` · `tests: none` · `area: ui`
**Unconfirmed.** `name_prompt.gd:232-247` does call `grab_focus()`, and headless
verification shows the field focused. The playtest saw a caret and a focus ring
in a field that received nothing — consistent with the test container's X input
focus rather than a game bug. Needs one check in a real window; close it if it
does not reproduce.

### PT-18 — Boot cost rose sharply across the mid-test build change
`model: sonnet` · `tests: none` · `area: perf`
Scene load went from ~2 minutes to materially longer across 20 commits, measured
under software rendering (which exaggerates absolutes, not the relative jump).
Suspects include the 17 shiny colourway textures. Measure on target hardware
before optimising anything.

### PT-19 — One silent engine death at boot
`model: haiku` · `tests: none` · `area: perf`
One of two launches on `7547f386` died at boot with no error output. Insufficient
evidence to characterise. Watch for recurrence; close if it does not return.

---

## Phase 7 — the village lives, the meadow reads

### R7.6 — The berry farm beside Grandpa's house, and the hoe
`model: opus` · `tests: test_farming (new), test_inventory, smoke_playground` · `area: village`
Owner-requested, 2026-08-16: a berry farm next to Grandpa's house, and a hoe
that preps ground for berry seeds. Replaces this item's old two-line stub
(which also mentioned fishing — the rod exists as an item and gates nothing;
leave it).

In bounds, not a design invention: `GAME_DESIGN.md` lists "berry farming" and
"simple farm plots" as **expected** build categories, and §32 excludes only
*deep* farming. Keep it shallow — till, sow, wait, harvest. No irrigation,
fertiliser, soil quality or crop varieties.

Build on what exists rather than inventing:
- `scripts/world/harvest_logic.gd` is the shared tool/yield/durability body and
  gained a public `gather()` so a swing and a prompt-press run one path. A crop
  is its **fourth caller**, alongside `harvest_node.gd` and
  `vegetation_harvest_point.gd` — do not copy it.
- The hoe follows the five existing tools in `data/items/items.json`
  (axe/pickaxe/knife/hammer/fishing_rod) plus `scripts/player/tool_hold.gd`.
  Which mesh a tool uses and how it sits in the hand is **data on the item**, so
  a hoe is an items.json entry and a swing target, not new player code.
  Craftable at the workbench station, or handed over by Tam (the OF30
  precedent).
- Berries are already a real item (`items.json:59`, with `satiety` and the
  `berry_verve` buff), already harvested from two nodes in
  `data/config/harvest.json`, already sold to Mira, and
  `recipes_ironwood.json:58` already keeps them in the Ridge Tonic cost "so the
  berry plots stay worth walking to at Band 4" — a forward reference to a plot
  that does not exist yet. This item is what that line was waiting for.

One genuinely new shape, worth naming: `items.json:9` records that berries are
the one resource with no `gathered_with`, i.e. never tool-gated. A hoe would be
the first tool gating a **planting** verb rather than a gathering one — decide
that deliberately rather than by accident.

Placement: Grandpa's house is at `[-22,-16]` (`village.json:3`); the plot must
clear the square flat at `[10,-10]` r18 and the fence run at `[3,-18]`. Answers
"Found along the way"'s spec §14 bullet directly — the farmhouse should not
become a room you never re-enter.

**Done when** a player can craft or receive a hoe, till a patch beside the
farmhouse, sow berry seeds, and harvest berries from it on a later day.

### R7.8 — Doors that open on interact, and houses you can walk into
`model: opus` · `tests: smoke_traversal, test_prompt_arbiter` · `area: village`
Owner-requested, 2026-08-16: every house enterable, doors opening on interact.
**Owner-scoped: build the door verb once, plus one or two reusable interior
templates every house draws from — not a bespoke interior per building.**

No door-open mechanic exists today, and the codebase already admits the gap:
`building_prefabs.json:567` poses `cottage_a`'s leaf statically open at -100°
with the reasoning that "a visibly closed door standing in an opening the player
walks straight through would be village.gd's hologram warning from the other
side." That is exactly the tension this item resolves. Grandpa's door is not a
precedent — it is an invisible story gate (`set_door_open()`, polled by
`sequence_director.gd`), not a player verb.

Three pieces of work:
1. **The verb.** A new provider on the existing `interactable.gd` /
   `prompt_arbiter.gd` arbiter — the same route `riding_controller.gd` took.
   One door script, animating the existing leaf, reused by every prefab.
2. **The openings.** `building_prefabs.json:4`: a prefab with no `colliders`
   gets one combined-AABB brick. Only `workshop` and `cottage_a` have authored
   openings; `cottage_b`, `ranger_station`, `mill` and the rest are solid bricks
   with painted-on doors. Each needs a doorway hole and lintel — this is the
   bulk of the cost.
3. **The interiors.** One or two reusable templates following
   `grandpa_house.gd`'s documented split (the kit owns the exterior; the script
   owns floor, furniture, lights, markers and all collision).
   `scripts/world/shop_interior.gd` already states it copies that worked example
   rather than inventing, so it is the second data point for the pattern.
   Register each in `village.gd:135`'s `INTERIORS` whitelist — deliberately a
   whitelist, because "naming a res:// script is data that can load code".
   Reuse the interior camera profile seam (`grandpa_house.gd:57`, an `Area3D`
   plus `set_target`).

**Done when** every house in the village has a door that opens on interact and
a room behind it the player can stand in, and none of them is a solid brick.

### R7.9 — An inn in the village
`model: opus` · `tests: smoke_traversal` · `area: village`
Owner-requested, 2026-08-16: an inn in the main village where the villagers can
stay.

There is no inn or tavern prefab — it must be composed from the same Medieval
Village MegaKit family per D24. `village.json:3` records why the TowerWindmill
was **removed rather than replaced** ("a mismatched second-family landmark is
exactly the split-the-difference failure D24 closed"); an off-family inn repeats
that mistake. `farmhouse_shell` (two storeys) is the closest existing massing to
work from. Data goes in `data/config/village.json`'s `structures[]` with its
`_why`, built by `village.gd`, grounded via D09 ("ask the world, never
raycast"). Its interior comes from R7.8's templates.

An innkeeper follows D39's dual-role pattern (a vendor branch and a later
trainer branch coexisting through ordered `greeting_when`), with `SE30`'s
`place_when` available if presence should be conditional. If the inn carries
rest or quest-board function, reconcile against spec §6 ("6–10 optional
activities, not forty shallow quests") rather than inventing a quest list.

### R7.3 — The footprint and the bake underneath `OW5` · `model: opus` · `tests: smoke_traversal` · M7, §30
**Re-scoped twice on 2026-08-16 — the second time by the owner.** This item used
to gate on `MQ1A`/`MQ1B` and claim the areas belonged to `SD16`, `SD17`, `SE21`,
`SE23` and `SF31`; all five shipped. Then `OW5` took the world's *shape* as an
owner directive.

What remains here is only the engineering half of `OW5`: `terrain_playground.json`
still says it is *a test area, not the Meadows*, and the bake, the Terrain3D
region count and the cost on the Ally were never budgeted. Measure what a trail
long enough to need several days of camping actually requires, grow the footprint
underneath it, rebake. **Do not decide the layout here — that is `OW5`.**

### R7.4 — Map reveal rule · `model: sonnet` · `tests: smoke_menu` · §23
**Re-scoped 2026-08-16.** The old text said the `map` action was "read by
nobody" — false since the map button was wired. The map, the minimap and the
player's heading arrow all exist and work.

What survives is only spec §16's rule: the map reveals explored areas and
landmarks and **never reveals everything automatically**. Check
`scripts/world/map_baker.gd` before writing anything — if the fog already
behaves, close this item.

### OF15 — Geometry snags: player can get stuck in places
`model: sonnet` · `tests: smoke_traversal (extend)`
Owner-reported, 2026-08-15. Movement getting wedged/blocked rather than passing
through. Needs locations logged from a fresh playthrough before a fix can be
scoped.

### OF18 — Re-shoot the website's screenshots · **partly done 2026-08-16**
`model: sonnet` · `tests: none` · `area: visual`
**Done already:** all the copy (seventeen species — it said fifteen, twice;
credits corrected — two shipped kits were uncredited and a retired one was still
listed; "vertical slice" → the 3–4 hour chapter D23/D42 describe; download
instructions that no longer tell people to keep three files out of a 477 MB
folder). A wordmark set in live type per the game's own display-lettering board.
`tools/site_images.py` now owns the capture→slot mapping so `site/README.md`
cannot drift out of sync with it again — it had named a combat frame the tool
stopped writing, so the documented recipe failed outright. And the hero, village
and camp frames are current, which gets the demolished Farm Buildings village
off the page and out of the `og:image`.

**Still to do, and the reason this item stays open:**
1. `godot --headless --path . --import` **first** — a capture run before an
   import renders missing textures and the frames come out plausible and wrong.
   This cost a full run in the session that filed this note.
2. Re-shoot the rest: `tools/survey.sh` (the exploration frames and the
   `.band` parallax, which still has no stronghold on the rise) and
   `tools/survey_combat.sh` (the combat frames still show a placeholder
   blob-headed trainer, Kenney foliage, the dead names "Meadow Hopper" and
   "Bramblit", and `[A] Quick / [X] Charged` — D35 moved those to RT/LT).
3. Capture the three images the two removed sections need:
   `capture_shiny_pairs.gd` (roster), `capture_weather.gd` (rain),
   `capture_torch_night.gd` (night). Then `python3 tools/site_images.py` and
   restore the two `<section>` blocks from `site/index.html`'s git history —
   the comment where they were removed carries the recipe.
4. `capture_catch_sequence.gd` gives `aim-arc.jpg`, a slot that has fallen
   through to a frame with **no arc and no orb** since the page was built,
   under a caption promising the arc shows exactly where the orb will land.
5. Blind visual pass before shipping (`conventions.md`: visual work needs a
   pass, not a look), then close.

Do not commit `site/img/*.jpg.import` — Godot sidecars, no purpose on a website.

### R7.7 — Player HP and armour slot architecture · `model: sonnet` · `tests: test_player_hp` (new)

---

## Phase 6.5 — locomotion quality rebuild (owner's quality plan)

### MQ1B — Terrain adaptation and foot placement · `model: fable` · `tests: none` · quality plan §3
**START WITH FABLE.** `MQ1A` is closed — the base cycles are key-pose authored
on render-verified axes, with planted-skate numbers a foot-IK pass can
regression-check against. Don't build terrain IK on top of a base cycle that
hasn't passed its own blind critique.

Evaluate and implement the minimum robust solution for uphill, downhill,
cross-slope and uneven-ground walking, small terrain height variation, and idle
stance on slopes (foot planting/IK, orientation to ground normal, pelvis
compensation, stance-phase locking as needed — don't add complexity for its own
sake).

**Done when** blind rendered/play inspection on flat and sloped test terrain
shows no gross foot penetration, no obvious hovering, no sustained slope
skating, no knee inversion, no broken pelvis motion, no visible IK snapping, and
walk/run still reads as natural.

---

## Phase -0.6 remainder — the look

### EV9 — Rebuild the HUD, remainder
`model: opus` · `tests: smoke_menu` · `area: ui`
Bible §16–§18. Most of this item shipped across four slices. **Tested at
physical 7-inch scale, not on a desktop monitor** — §17 is explicit.

Genuinely still open:
- `orb_capture` icon has no mount point — there is no orb-count panel anywhere
  in the current HUD to hang it on. Needs a panel first, or the owner naming a
  different place it belongs.
- A branded display font matching the "TETHERBOUND" key-art logotype, and
  gradient/beveled bar fills. The owner supplied a style board
  (`ev9_display_lettering_style_guide.png`) but there is nowhere to apply it:
  the game boots straight into the world (D18) and renders no wordmark
  anywhere. Needs a title screen to exist first, or a different mount point.
- Compass — the bible says "if it exists"; it doesn't, and inventing one is not
  this item's job.

### EV10 — Cohesion pass
`model: fable` · `tests: none` · `area: visual`
Bible §22 Phase G and §23's metrics. Re-shoot the same viewpoints, blind-judge
against both reference sets, fix the three biggest gaps, repeat until further
improvement is asset-quality-limited rather than composition-limited. Record
plainly that EV9's remainder above is out of reach for documented reasons rather
than treating it as a failure to converge.

---

## Phase 8.5 — the chapter's own audit

### SH54 — Audit: nothing in the chapter assumed new creature credits
`model: haiku` · `tests: none`
Spec §38 step 54, §20. Walk every item shipped for this chapter and confirm none
of them installed, requested or planned a new creature mesh. Cheap, and worth
doing once at the end, because the constraint is a budget the owner holds and a
single quiet violation spends it.

---

## Phase 9 — polish

### R9.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet`
### R9.2 — Controller UI readability on the Ally · `model: sonnet`
### R9.3 — Performance on target hardware · `model: sonnet`

---

## Ops

### OPS1 — Backfill `DONE.md`, and fix what let it drift
`model: haiku` · `tests: none`
`DONE.md`'s newest entry is `SG44+SG46+R8.5+R8.6`, and it has **no entries** for
OF19–OF33, SC12–SC15, SD16–SD18, SE21–SE30, SF31/SF34, SG38/SG40, R8.1–R8.4,
SH47 or the playtest repairs — roughly 25 shipped items. The loop's
"move it to DONE.md when you ship" contract is broken, and that is the root
cause of the 2026-08-16 prune that produced this file. Backfill from `git log`,
then state in `PROMPT.md` what a firing owes when it ships.

Also record the work that shipped with **no backlog item at all**, so it is not
re-done: elixirs (D45), tonics (D47), moves becoming non-interchangeable, the
workbench becoming a real crafting station with craftable tools, and
tool-in-hand + assignable hotbar + the map button (save format 6→7).

---

## Found along the way — small, unscheduled

- **Spec §6 — 6–10 optional activities, not forty shallow quests.** Lost Pal,
  Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team
  Tether patrols, Meadowhart Herd. Each wants a home in Phase 8's bands rather
  than a list of its own; promote individually when the band it belongs to is
  built. `model: sonnet`
- **Spec §14 — home must stay relevant.** Grandpa's dialogue evolves per band,
  creature beds and recovery, storage and crafting, villagers updating what they
  know, the rescued NPC returning, story check-ins. The farmhouse should not
  become a room you never re-enter after the first twenty minutes. `R7.6`'s
  berry farm is the first answer to this. `model: sonnet`

---

## Done

Ids only. `git log` and `DONE.md` are the record; this list exists so a firing
can tell at a glance that an id is spent.

- BG1 — done
- BG2 — done
- CO1 — done
- EV1-remainder — done
- EV2 — done
- EV2-trunk-colour — done
- EV3 — done
- EV3-remainder — done
- EV3-remainder-2 — done
- EV3-remainder-3 — done
- EV3-remainder-4 — done
- EV3-remainder-5 — done
- EV4 — done
- EV4-hillside-seam — done
- EV4-hillside-seam-remainder-2 — done
- EV4-hillside-seam-remainder-3 — done
- EV4-hillside-seam-remainder-4 — done
- EV4-textures — done
- EV4-textures-lighting — done
- EV4-textures-remainder — done
- EV5 — done
- EV5-remainder-2 — done
- EV6 — done
- EV6-remainder — done
- EV6-remainder-well-rocktrim-shadow — done
- EV7 — done
- EV7-remainder — done
- EV8 — done
- EV9-double-prompt — done
- HD1 — done
- HD1-remainder — done
- HD2 — done
- HD2-remainder — done
- LP1 — done
- LP4 — done
- LP7 — done
- LP8 — done
- LP9 — done
- MQ1A — done
- NP1 — done
- NP2 — done
- NP3 — done
- NP4 — done
- NP4-rig — done
- NP4-uv-split — done
- NP6 — done
- NP7 — done
- OF1 — done
- OF2 — done
- OF3 — done
- OF4 — done
- OF4-rebuild — done
- OF4-remainder-mound — done
- OF5 — done
- OF6 — done
- OF7 — done
- OF8 — done
- OF9 — done
- OF10 — done
- OF10-remainder — done
- OF11-remainder — done
- OF12-remainder — done
- OF13 — done
- OF16 — done
- OF19 — done
- OF20 — done
- OF21 — done
- OF22 — done
- OF23 — done
- OF24 — done
- OF25 — done
- OF26 — done
- OF27 — done
- OF28 — done
- OF29 — done
- OF30 — done
- OF31 — done
- OF32 — done
- OF33 — done
- R0.11 — done
- R1.1 — done
- R2.1 — done
- R2.2 — done
- R2.3 — done
- R2.4 — done
- R2.5 — done
- R2.7 — done
- R2.8 — done
- R3.1 — done
- R3.1-remainder — done
- R3.2 — done
- R3.3 — done
- R4.1 — done
- R4.1-remainder — done
- R4.2 — done
- R4.3 — done
- R4.4 — done
- R4.5 — done
- R4.6 — done
- R4.7 — done
- R4.8 — done
- R4.9 — done
- R4.10 — done
- R4.11 — done
- R5.2 — done
- R5.3 — done
- R6-village-notification-freed-instance — done
- R6.1 — done
- R6.2 — done
- R7.5 — done
- R8.1 — done
- R8.2 — done
- R8.3 — done
- R8.4 — done
- R8.5 — done
- R8.6 — done
- R9.4-remainder-2 — done
- R9.4-remainder-6 — done
- R9.4-remainder-8-rocks-repeat — done
- R9.4-remainder-9 — done
- R9.4-remainder-9-combat — done
- RB1 — done
- SA0 — done
- SA0-orbs — done
- SA1 — done
- SA1-lod — done
- SA2 — done
- SA2-flake — done
- SA3 — done
- SA4 — done
- SA5 — done
- SA6 — done
- SA7 — done
- SA8 — done
- SB9 — done
- SB10 — done
- SB11 — done
- SC12 — done
- SC13 — done
- SC14 — done
- SC15 — done
- SD16 — done
- SD17 — done
- SD18 — done
- SE21 — done
- SE22 — done
- SE23 — done
- SE25 — done
- SE27 — done
- SE30 — done
- SF31 — done
- SF33 — done
- SF33-remainder — done
- SF34 — done
- SG38 — done
- SG40 — done
- SG44 — done
- SG46 — done
- SH47 — done
