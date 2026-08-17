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

## RECONCILED 2026-08-17 (OPS1) — 35 items closed in one pass

**This file had drifted badly and this note exists so the drift is legible
rather than silently tidied.** Across 2026-08-16/17 a coordinated run landed 76
commits to `main`; almost none of them were marked here, because bookkeeping was
centralised on a coordinator that then spent the night on merges instead. That is
`OPS1`'s own failure mode, happening while `OPS1` sat open.

Closed in this pass, verified against `git log origin/main` rather than against
anyone's memory: `OW1` `OW2` `OW4` `OW7` `OW8` `OW9` `OW10` `OW11` — the whole
owner-reported ROG list — plus `PERF1` `PERF2` `WALL1` `TEST1` `EXP1` `MERGE1`
`LANE1` `UI-PAD1` `UI-PAD2` `PT-03` `PT-04` `PT-15` `PT-17` `PT-18` `PT-19`
`PT-23` `OF18` `EV10` `MQ1B` `R7.3` `R7.6` `R7.7` `R7.8` `R7.9` `OW5A-rework`.

Four more are **shipped and in flight** on `ralph/integrate-3` — `OW3`, `OW12`,
`OW1-remainder` and the collision-streaming work — each marked in place rather
than closed, because a branch that has not landed is not done no matter how
green it is.

**The rule that made the difference, and it is worth keeping:** a shipped item
is one whose content is an ancestor of `main`. Not a green branch, not a lane
saying so, not a branch ref that looks right — `UI-PAD1`'s ref had moved and an
ancestor check called it missing while its code was demonstrably in the tree.
Check the tree.

---

## Phase -1.5 — the owner played the ROG build (owner-reported, 2026-08-16)

Reported from the real handheld, which is the instrument no test in this repo
substitutes for. **Three of these have been "fixed" before** — check the current
build before rebuilding, then fix the mechanism rather than the symptom, because
the symptom has come back every time so far.

The owner also asked whether they were on an old build. Partly answered here:
`OW3`'s fog does not exist in code at all, and `OW1`'s hotbar has no separate
section *by design* — so those two are real regardless of build age.

### OW12 — The torch should be a carried item, not a thing you build
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

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

### OW3 — The whole map is revealed before you explore anything
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

`model: sonnet` · `tests: smoke_menu` · `area: ui`
Owner: *"The full map is rendered before I explore anything."*

**Confirmed in code, not just reported:** `scripts/world/map_baker.gd` contains
no fog, reveal, explored or discovery logic of any kind. Spec §16's rule — the
map reveals explored areas and landmarks and *never reveals everything
automatically* — was never built. This is the surviving half of `R7.4` and the
owner has now hit it; do that item's remainder here.

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


**A constraint `OW5C` inherits from `OF15` (added 2026-08-16).** The player's
`floor_max_angle` is 45 deg, and a confirmed wedge at (60, -106) on the rocky rise
turned out most likely to be slope rather than props — a route crossing ground the
character controller refuses to climb. **No trail segment may cross ground steeper
than `floor_max_angle`.** Assert it with a probe over the candidate route *before*
the bake, not by walking it afterwards: `height_at` is analytic and unbounded, so
the whole spine can be sampled without baking anything, and at hours per bake that
is not optional. A trail that is 12 km long has 12 km of chances to make this
mistake once.


**STATUS, 2026-08-17. The corridor is BUILT and does not yet land.**

- `OW5A` — the macro layout, measured and region-aligned. **Landed.**
- `OW5B` — the footprint and the bake. **Built.** 8192 x 2048 m, `world_bounds`
  x [-1024,1024] z [-512,7680], **64 baked region files committed** against
  main's 4. The bake was also factored to take a region set, with a bit-identity
  test, so a future edit costs ~143 s a region instead of 153 minutes.
- `OW5C` — the trail, the loops, the edges. **Built.** `trail.bands[]` is the
  spine, `trail.loops[]` the regional loops, `trail.shortcuts[]` the quarry haul
  road and the river ferry; they join the road set through
  `playground_heightfield.road_polylines()`, never as `paths.routes` entries,
  because `signpost.gd` fits four arms.
- `OW5D` — the §10 relocation. **Built**, and honest about its own gap: its
  `spawns.json` comment records that *"Ground truth at every new site was NOT
  re-probed by this pass"* and that test files were out of scope.
- `OW5E` — **OPEN, and the only thing between the corridor and `main`.** See its
  own entry below.
- **The end-to-end check is still owed** and is the thing that proves this
  worked: walk the trail in-engine with a probe measuring real path length,
  side-to-side width and elapsed in-game days, and confirm 40 minutes end to end
  and about 5 side to side **against the actual route**, not the design document.
  Filed as `OW5-walk`.


### OW5E — make the relocated world pass its own tests
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in `d4de94a3`, CI run 1349 green
on all 19 jobs — the first fully green run the corridor has ever had. All six
jobs fixed. Two of them were not the corridor's fault and are worth keeping in
mind: `verify-unit-tests` was two stale test assertions (`test_map_state.gd`
failed to PARSE on a removed `GRID` const, silently skipping all 21 map-state
tests including the save-format ones), and the duplicate `vegetation.build()`
it found came from a coordinator merge resolution, not a lane. Two further real
bugs were found by walking the re-baked ground: `world_perimeter.gd` queried
height exactly on the baked grid's EXCLUSIVE edge, so all 55 south-cap collision
segments took one flat wrong height and a player could step over the wall into
the void; and `smoke_boss.gd`'s `BARRIER_LIMIT_M` had been computed from carve
config that postdated the only bake in existence, never measured.

`model: sonnet` · `tests: the six failing jobs` · `area: terrain, tests`
**The corridor cannot reach `main` until this closes.** `ralph/integrate-3` is 24
commits ahead and 6 of 19 CI jobs fail (run 32023204240). They are not the
`verify-aggression` intermittency; they are real, and they split three ways:

**Tests still asserting the pre-corridor world.** `verify-settings`: *"The Pond
is listed at (-342.0,507.0), expected (-92.0,100.0)"*, same for River Road and
Mountain Road. The landmarks moved correctly; the test hardcodes old
coordinates. Derive the expectation from config the way `OW3` just taught
`test_map_state.gd` to, or this breaks again at `OW6`.

**The world genuinely wrong at a new site.** `verify-warrens`: *"the deepest
chamber is not under the hill (terrain y=-4.2 vs floor y=-3.8)"* — a dungeon
poking out of a hillside. `verify-relay`: *"the player climbed onto the
apparatus pad from the yard; the traversal is not the route"*. `verify-boss`:
D41's regrowth clause unpaid. `verify-traversal`: fell through the world at the
south cap; the river divides nothing at two stations; the Old Mill Crossing
cannot be crossed. **Fix the world, not the assertion** — `verify-relay`'s check
is a real design guarantee.

**Probably a test bug — check before touching either side.** `verify-traversal`
probes the river's near bank at **x=1027**, which is outside `world_bounds`
max_x of 1024. And `verify-unit-tests` exits 1 on *"31 resources still in use at
exit"* with RID leaks, which may be shutdown noise (`D06`) rather than a failed
test.

Also surfaced by the same run and worth its own commit: `verify-settings`
reports *"Map is now I — so is Open the satchel. Both will fire."*

### OW5-walk — walk the corridor and prove the forty minutes
**START HERE (OPS4, 2026-08-17).** `OW5E` has landed, so this is unblocked and
it is the corridor's exit gate: the whole 8192x2048 m world is now on `main` and
**nobody has walked it end to end.** Every number behind it is still arithmetic.
Until this runs, `OW6` (the captain onto the trail) and `MQ2B` are building on an
unverified route.

`model: sonnet` · `tests: new probe` · `area: terrain`
The owner's original ask, in his own words, and still unverified against
anything but arithmetic. Once `OW5E` lands: drive a body along the real trail
and measure **actual path length, actual side-to-side width, and elapsed
in-game days**, then compare against 40 minutes end to end and ~5 minutes across.

Do not measure the design document. `OW5A` computed an 11,594 m spine and a
27.9-degree worst slope from the config; this item exists because a route that
computes correctly can still fail to be walkable — which is exactly what the
phantom wall turned out to be, three wrong diagnoses deep.

### OW6 — The captain you can challenge is too close to the start
`model: sonnet` · `tests: none` · `area: village`
Owner: *"The captain to challenge is way too close to where you start. You need
to work to find him."* Positions are data (`data/config/trainers.json`), so this
is a placement change once `OW5` establishes the trail — sequence it after, or
it gets moved twice.

## Phase -1.45 — measured performance, and what three blind reviews found

Filed 2026-08-16 by the coordinating session. Everything here is measured, not
suspected; the numbers are in each item.

### CAP1 — a capture scene for interiors, so a room does not cost a world
`model: sonnet` · `tests: none` · `area: perf`
`PT-03` spent **24–32 minutes booting the whole Meadows** — terrain, 23,707
scatter instances, the village — to photograph the inside of one room. Every
future interior task pays that, which is the kind of cost that quietly stops
people taking frames at all. A scene that instantiates only the interior under
test plus its camera profile would boot in seconds. `grandpa_house.gd`'s
kit-owns-the-exterior/script-owns-everything-else split is what makes this
possible; `tools/capture_loft_exit.gd` is the worked example to generalise.

### PT-03-remainder — the stair affordance failed its blind pass
`model: fable` · `tests: smoke_opening` · `area: village`
`PT-03`'s root cause is correct and settled — the loft slab occludes every tread
from a standing eye, so no light could ever have worked, and `D52` records the
measured sightlines. **The affordance does not.** A blind critic given the pair
unlabelled: *"a post is not an exit — it doesn't say down, it doesn't say
through, it doesn't say walkable. 0/10 before, 2/10 after. That is not the
difference between lost and found."* A frame aimed **straight down the −51°
bearing at the stair head** still shows no treads, no descending rail and no
opening — so this is not "the player is facing the wrong way."

The evidence says the honest question is not a stronger rail but whether **the
loft slab's edge has to change shape** — a cut-back, a visible stairwell
opening, or the camera bias that was rejected. That is a decision about the
room, and it is the owner's.

Also open from the same pass, and separate: the interior camera profile spends
the bottom half of frame on empty floor with the player's head at the very
bottom edge. Predates this item.

### OW1-remainder — the backpack's remaining legibility defects
**CLOSED 2026-08-17 (OPS4).** Landed on `main` in the corridor merge `d4de94a3`. Verified in the tree, not by branch ref.

`model: sonnet` · `tests: smoke_menu` · `area: ui`
From the blind usability pass, judged at 40% scale as a seven-inch proxy. Two
are genuine defects rather than opinions: **nothing shows *what* you are
holding** (the source tile keeps its full count, no ghost, no cursor — so a
player who misses the text thinks nothing happened), and **the quick bar gives
all five chips the same cyan** while a stack is held, so "cursor is here" and
"valid target" are the same colour — `_refresh_quick_bar()`'s
`_slot_style(_bar_focused == i or _held >= 0)`, a two-line fix.

The rest: Escape silently stops meaning Close while holding; the 1–5 badges are
4–5 px and the font renders "4" like a Cyrillic Ч; "6 of 24 slots used" and
"GEAR" are unreadable at 40%; the held state is announced in four places; "6
Orb" should be "6 Orbs"; the screen is Backpack while the grid inside is
Satchel; and `Menu + View held, or F10 Reset all controls` is a leftover from a
controls screen sitting in an inventory footer.

---

## Phase -1.40 — the phantom wall, and three diagnoses that were wrong

Filed 2026-08-17. **Every item in this phase corrects an earlier confident
answer, including two of the coordinator's own.** Recorded that way on purpose:
the sequence of wrong diagnoses is the most useful thing here, because each was
plausible and each cost work.

### UI-PAD3 — `ui_accept` cannot replace a poll on a screen with no Button to press
`model: sonnet` · `tests: test_controls` · `area: ui`
**Corrects `UI-PAD1` as filed by the coordinator**, which said: add the joypad
binding, then remove each now-redundant `menu_confirm` poll in the same change.
The lane checked before deleting and found **four of the five polls must stay** —
removing them would have broken three working screens:

| screen | why |
|---|---|
| `starter_picker.gd` | 0 Buttons — the orbs are custom-drawn. The poll is the only input it has. |
| `combat_hud.gd` | 0 Buttons — the switch selector is custom-drawn. Same. |
| `name_prompt.gd` | 0 Buttons — on-screen keyboard, already device-guarded. |
| `tab_creatures.gd` | Has Buttons, but `_begin_evolution` sets `_list.visible = false`, so nothing is focusable during the ceremony. `_end_evolution` re-grabbing focus is the tell. |
| `tab_backpack.gd` | Has Buttons **and** the rows are focused. The only genuinely redundant one. Removed. |

**The rule:** `ui_accept` can only replace a poll on a screen that has a
focusable `Button` for it to press. Check for `Button.new()` before deleting
anything.

**And the double-confirm everyone braced for does not arise**, for a reason
worth keeping: **Enter has always been both `ui_accept` and `menu_confirm` on
the keyboard.** Any screen with a focused Button beside a `menu_confirm` poll
would already have been firing twice for every keyboard player — and none was.
Adding JOY:0 makes the pad behave exactly as the keyboard already did. *When
weighing whether a new pad binding will double-fire, ask what the keyboard
already does first; it is usually already the answer.*

**One trap, now pinned by a test:** listing a built-in `ui_*` action in
`project.godot` **replaces** the engine defaults rather than adding to them.
`ui_accept`'s Enter / KP-Enter / Space survive only because `UI-PAD1` restated
them by hand; dropping one would quietly take Enter away from every menu in the
game. `tests/test_controls.gd::test_ui_accept_still_answers_the_keyboard` holds
that line.

### PT-17-test — the rename flow has no test for its own trigger path
`model: sonnet` · `tests: new` · `area: ui`
Flagged by the lane that rebased `PT-17`, about work it did not write: the
original commit added no dedicated test for the `tab_creatures.gd` rename flow
itself — H-key → prefilled `name_prompt` → `set_nickname`. Existing tests cover
the nickname mechanism generically, not that trigger path. The gap predates the
rebase and was correctly judged outside "make it landable".

### OPS3 — the unit suite takes nine minutes under load, and looks hung
`model: none (note)` · `area: ops`
`tests/run_tests.gd` took **over 500 s** on a loaded container and was killed
once by a lane that believed a global input change had deadlocked it. It had
not: it completed in ~9 minutes reporting 959 tests / 80,924 assertions / 0
failed. Companion to `OPS2` (concurrent headless runs corrupting each other's
script loading). **Give the suite room before concluding it hung**, and
serialise runs.

---

## Phase -1.41 — what the UI lane found on its way out

The four owner-reported UI items shipped in one lane on 2026-08-16 (`OW11`,
`OW10`, `OW4`, `OW8`). On finishing, that lane was asked to write down what it
had learned that did not belong in a diff. **What came back was larger than the
four items it had just closed**, and none of it would have survived otherwise —
which is the whole argument for `LANE1`'s notepad. Verbatim record in
`ralph/NOTES.md` on `ralph-status`.

### TEST2 — four tests that passed while the thing they name was broken
`model: sonnet` · `tests: the ones named here` · `area: tests`
Companion to `TEST1`, which asks the same question of the smoke suite generally.
These four are specific, found the hard way, and each is a distinct shape:

1. **No test in this repo chooses a build piece through input.**
   `tests/smoke_free_build.gd` calls itself "the menu-driving shortcut of arming
   `pending_build` directly" (~:152), and `tests/smoke_build_menu_footprint.gd`
   calls `menu.call("_select_category", i)`. That is exactly why a build menu no
   controller can operate has been green this whole time.
2. **`InputEventAction` hides every binding bug.** `tests/smoke_menu.gd` drives
   the backpack target picker end to end and asserts the heal lands — and passes
   on code where a pad could not confirm at all, because `InputEventAction` names
   the action directly and never travels the `InputMap`. **Any test asserting
   "the player can do X" with an action event asserts something weaker than it
   reads.** `tests/smoke_backpack_pad_target.gd` is the pattern to copy: real
   joypad events, button indices read from the live `InputMap`.
3. **`test_controls.gd::test_no_two_menu_context_actions_share_a_keyboard_key`
   only sees keyboard.** It does `var key := event as InputEventKey` and
   `continue`s on anything else, so joypad collisions are invisible. Its own
   failure message talks about a verb being "dead" — the exact bug that then went
   unnoticed on the pad side. Widening it to joypad buttons is cheap.
4. **`OW8`'s own test is weaker than it looks, recorded by its author.**
   `tests/smoke_prompt_hotbar_dock.gd` fails on pre-`OW8` code *only* on its
   structural assertion; all four rect-intersection cases pass there, because
   `_reflow_prompt` recomputes from the hotbar's live rect on `resized` and the
   harness grants the frames. **That is why the two previous OW8 fixes tested
   green and still failed on the owner's hardware, twice.** Anyone judging that
   fix by the rect cases alone concludes there was never a bug. The shared-parent
   assertion is the load-bearing one.

### OPS2 — two concurrent headless Godot runs corrupt each other's script loading
`model: sonnet` · `tests: none` · `area: ops`
Two concurrent headless runs on a four-core container produced
`Attempt to open script ... resulted in error 'File not found'` for a file
present on disk; re-running serially passed. Every lane brief now says serialise
your runs, but that is instruction, not enforcement. **If a smoke test dies with
a missing-script error, check what else was running before believing it** — this
is a plausible source of "flaky" CI that is not flaky at all.

---

## Phase -1.42 — the tourniquets, and the questions nobody asked

Filed 2026-08-16 by the coordinating session, as a self-audit rather than as
new work discovered. Every item here exists because a fix that shipped today
was a *workaround*, and the thing it worked around is still standing. They are
filed so the workarounds cannot quietly become the design.

## Phase -1.4 — the blind playtest's open findings (2026-08-15/16)

Full record in `docs/reviews/2026-08-15-full-blind-playtest/`. The six repairs
that pass already shipped; these are §7's leftovers. `PT-03` is the one the
report calls the highest-value remaining fix for a first-time player.

## Phase 7 — the village lives, the meadow reads

### R7.4 — Map reveal rule · `model: sonnet` · `tests: smoke_menu` · §23
**CLOSED 2026-08-17 (OPS7), on this item's own terms.** Its last line says to
close it if the fog already behaves, and it does: `5cb90968` ("OW3: the map
hides what you have not walked, and walking reveals more of it") is an ancestor
of `main`.

**The check below sends you to the wrong file, which is worth keeping rather
than quietly deleting.** `map_baker.gd` still contains no fog, reveal or
explored logic — grepping it, exactly as instructed, returns nothing and would
have you conclude the feature was never built. `OW3` put the reveal in
`tab_map.gd` and `minimap.gd` instead, which is the right place: the baker
renders the world once, and what the *player* has seen is view state, not
terrain. A closing check that names a file rather than a behaviour will keep
doing this.

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

**CLOSED 2026-08-17 (OPS4).** The detector landed on `main` in `05264fda`, and
porting it taught something worth keeping: **its exclusions had to be re-derived,
not copied.** `STUCK_EXCLUDE_RADIUS` was a 200 m radius because the world was a
disc with a ring fence; the corridor has no centre. And it had no slope
exclusion at all — it never needed one on the old gentle disc, but the corridor
is built out of deliberately unclimbable rises, and ported as-is it reported
three wedges on correct terrain near (62,-105), where the ground climbs 7.1 m
over 8 m and a shape query finds no prop at all. Now excluded by edge margin and
by a slope probe sampled at **both** 4 m and 8 m — one ring is not enough.

**SOLVED 2026-08-17 — it was Captain Halder, and it took four diagnoses.**
`WALL1` found it: `spawns.json`'s seeded rng resolved Galecrest's home to 3.15 m
from a captain `trainers.json` hand-places at `[52.0,-122.0]` with a real
0.36 m capsule collider. The chase ran through his body. `is_on_wall()` was
true because there really was a wall — just not a terrain one, which is why
every terrain-side investigation came back clean. A frame-by-frame slide dump
named `Captain Halder/Body` on every residual frame.

The three wrong answers before it, kept because the sequence is the lesson:
props (a spacing filter was built and measured working, and the wedge survived
it); terrain slope (disproved — the ground reads 5-11 degrees and the wedged
body ran a MORE permissive 55-degree limit than the player's 45); collision
shape seams (a real and independent defect — `collision_shape_size` had been
silently stuck at 16 m, never the 256 the code believed, because the setter is
a no-op out of the tree — worth fixing on its own and it halved the residual,
but not the cause).

Closing this item. What survives it is a rule now in `OW5`: **a route is not
proven walkable by sampling the heightfield.** `ground_height_at()` lied to
three separate investigations. Walk a body and read what the physics engine
reports.

Superseded detail from 2026-08-16, kept for the record: A lane confirmed
the wedge at **(60, -106)** and **(65, -108)** and blamed clumped tree colliders.
A cross-layer spacing filter was built against that diagnosis, measured working
(23,707 placements to 23,650; rocks 345 to 300, trees 129 to 118) — **and the
player still wedges at (60, -106).** So the diagnosis was wrong. The evidence
points at terrain slope on the rocky rise instead: an earlier traversal run ended
that leg at exactly `(60.0, 0.2, -106.3)` after 46 m of a 190 m walk, and a review
of the same ground noted it "snags on the rocky rise". The player's
`floor_max_angle` is 45 deg, so the test may be flagging correct behaviour at a
place a route should never have crossed.

It is parked because **that ground is about to be rewritten.** `OW5B`/`OW5C`
rebake the world and lay a new trail; fixing terrain that is being replaced this
week is wasted work. The durable outcome is a constraint, not a repair, and it is
recorded on `OW5` rather than here: **no trail segment may cross ground steeper
than `floor_max_angle`, and a probe must assert it before the trail is committed.**
Re-open this item only if the wedge survives the rebake.

## Phase 6.5 — the quality plan's own items (owner's quality plan)

**Filed as backlog entries 2026-08-17 (OPS7), after a fresh coordinator found
they were missing.** `MQ1A` and `MQ1B` shipped and were closed out of this
phase, which left the header empty — and `MQ2B`, `MQ3` and `PW2` had never been
transcribed here at all. They existed only in
`ralph/planning/MEADOWS_QUALITY_REBUILD_PLAN.md`.

**That made this file wrong about the thing it claims to be.** Its first line
says it is the state of the project. A session reading it top to bottom today
would count fifteen open items, most of them small, and conclude the game is
nearly done — while the largest block of remaining work on the project sat in a
planning document with no entry anywhere in the queue. The previous
coordinator's own handover named `MQ2B` and the `MQ3` umbrella as the work after
`OW6`, citing IDs this file did not contain.

The plan stays authoritative for what these mean and what "done" is; these
entries exist so the queue stops omitting them. Do not duplicate the plan's
prose here — read §6, §7 and §8 there.

### MQ2B — prove one region at finished quality before scaling
`model: fable` · `tests: none (playtest gate)` · `area: terrain, world-layout, content`
Plan §6. **Starts with fable — it is ceiling-setting authorship.** Take the first
appropriate Meadows region and finish it to production standard: terrain
composition, vegetation structure, readable paths, a major landmark, an
exploration loop, a reconnect or shortcut, meaningful gatherable placement,
creature habitat, an optional discovery, a memorable encounter, day and night
readability, and no empty filler stretches.

This is the production recipe, not one region's decoration. The plan's expansion
rule is explicit: only after this region passes may its principles be used to
author the remaining bands, and what gets copied is the quality bar, never the
layout.

**Sequence it after `OW5-walk`.** Finishing a region to production standard
along a route whose real length nobody has measured is how content gets placed
twice — the same reason `OW6` waits.

**Done when** a blind playtest spends meaningful time exploring the region
voluntarily rather than following the critical path through it, and can say what
made it visually distinct, what made it mechanically interesting, where they
chose to leave the path, and what landmark they navigated by.

### MQ3 — the Meadows content umbrella
`model: fable` per major content beat · `tests: per unit` · `area: content, quests`
Plan §7. **This is not one task and must not be taken as one.** It is the
creative umbrella over the existing progression-sized units; break implementation
into those units and author them in unlock order, so each section can be played
and judged before later content depends on it. Build progression plumbing first
where still unbuilt — state tracking, keys and gates, quest log, objective
transitions — without over-generalising for a second biome that is forbidden
until the Meadows passes its exit gate.

**The corridor is what makes this large.** The world went from a 512 m square to
8192 x 2048 m yesterday, and `OW5D` relocated the already-approved content into
it rather than adding any. So bands beyond the first are, today, mostly empty
ground. Each region owes a clear entry, a clear purpose, recognisable geography,
one meaningful critical-path objective, an optional discovery, a memorable
encounter, working navigation, day/night usability, a real reason to explore,
and a clear transition to the next.

Side content may be authored before the XP economy exists; reward wiring can land
later, and per the plan the design must not be hardcoded around XP per hour
before `R4.1` provides levels.

### PW2 — alpha / elder wild variants
`model: fable` · `tests: per encounter` · `area: creatures, content`
Plan §8. Folds into `MQ3`'s regional content rather than running as its own pass.
Rare landmark encounters that give optional paths a reason to exist. **No new
Meadows creature meshes** (`CLAUDE.md`, D23) — and explicitly not "normal
creature, larger scale, more HP": each needs at least one real behavioural or
encounter difference, such as a different aggression pattern, altered cadence,
group behaviour, unique habitat, environmental advantage, a move variant, a
special arena, or unusual time-of-day presence.

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

- OF15 — done
- EV10 — done
- EXP1 — done
- LANE1 — done
- MERGE1 — done
- MQ1B — done
- OF18 — done
- OW1 — done
- OW10 — done
- OW11 — done
- OW2 — done
- OW4 — done
- OW5A-rework — done
- OW7 — done
- OW8 — done
- OW9 — done
- PERF1 — done
- PERF2 — done
- PT-03 — done
- PT-04 — done
- PT-15 — done
- PT-17 — done
- PT-18 — done
- PT-19 — done
- PT-23 — done
- R7.3 — done
- R7.6 — done
- R7.7 — done
- R7.8 — done
- R7.9 — done
- TEST1 — done
- UI-PAD1 — done
- UI-PAD2 — done
- WALL1 — done
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
