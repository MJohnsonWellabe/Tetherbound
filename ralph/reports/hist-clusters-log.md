# Historical backlog lane — cluster log

One entry per item touched, with what was measured and what is now claimed.
The lane's rule is the repo's: **verify before fixing**, and an evidence-backed
"already fixed" is a valid outcome that costs no diff.

Frames in this log come from software rasterisation on llvmpipe. Composition,
colour and silhouette are judged from them; **frame times are not**, and device
frame rate, GPU, VRAM, thermals, controller feel and audio are **[OWNER-ONLY]**
and are never claimed here.

---

## 2026-08-27 — RC-5c, the HUD's permanent chrome

Phase B's first cluster. `GF-B-005`/`GF-B-006` landed earlier the same day
(quickbar leads with the item; roster off the play space), which the register
names as the unblock for `HIST-036`.

### `HIST-036` — OBJECTIVE-HINT-ON-HUD — **CLOSED**

**What it was.** `quest_log.gd::tracked_hint()` has been written, tested and
drawn by nothing since OP23-04. The opening's guidance — "`{interact}` to take
the key, then `{interact}` at the gate" — existed only inside the quest-log tab,
so a player who never opened the menu was told the objective and not the button.
Sequenced behind OP23-09 (`HIST-136`, owner-reported: "the HUD takes up far too
much screen") with one instruction to whoever took it: **measure the wrapped
height first**.

**Measured.** `tools/_probe_objective_hint_height.gd` (new) resolves all 13
authored `how` strings through `hint_text()` — real bound buttons, not raw
`{action}` braces — and measures them wrapped, in-engine:

| inner width | font | worst hint |
|---|---|---|
| 380 (the objective block today) | 38 | **318 px, 6 lines** |
| 380 | 35 (the legibility floor) | 294 px |
| 544 (widened to the central third's edge) | 38 | 265 px |
| 544 | 35 (both levers at once) | 196 px |
| 800 | 38 | 159 px |
| **1100** | **38** | **106 px — every hint, 2 lines** |

The backlog's estimate was "170px to nearly 300" for the whole block. The hint
**alone** is 318, and the tracked line it would stack under is itself up to 159.
The block's band is fixed: its top edge sits under the minimap at y 310 and the
bottom dock begins at y 620 — 310 px total. **No version of "a second line under
the objective" fits**, at any width or font size this HUD allows, including both
levers pulled at once. That is the measurement the item asked for, and it
changes the answer rather than confirming it.

**Shipped.** The hint gets width instead of height: a centred timed card
(`ObjectiveHintCard`), revealed when the tracked objective changes, held for a
per-hint window (2.5 s of glance + 0.3 s per word — a fixed window long enough
for the opening's 21-word key-and-gate hint would leave a 9-word one on screen
well after it was read), then gone. Nothing is shortened; the backlog names
shortening the hints as explicitly not the fix.

Permanent HUD chrome added: **zero**. That is what makes this shippable against
OP23-09 at all, and it is the reason the card is not a panel.

**Width is the centre gutter, and a first render got this wrong.** The card
went out at 1140 px — the width the hint measurements alone wanted — and the
first frame through the real render path put its corner straight over the
objective block's plate. Both HUD columns run the full height of the screen:
the left is the party strip (rows 420 wide from x 56) or the creature panel
standing in for it (real width 435), the right is the objective block whose
left edge is `1920 - HUD_INSET - OBJECTIVE_MAX_WIDTH` = x 1444. A centred card
clears both only up to **900 px**, and in that gutter the worst hint wraps to
four lines rather than two. The legibility floor buys nothing here — 860 px at
font 35 is also four lines — so the font does not drop.

**Where the card sits vertically.** Bounded above by the region banner's own
bottom edge — read from the banner's offsets, not a hand-tuned y — and below by
the bottom dock. The dock's y 620 anchor is *not* its top: it is a
bottom-aligned VBox that grows upward, and `smoke_prompt_hotbar_dock.gd`'s
worst case (hotbar message row showing AND a wrapped two-line prompt) puts the
hotbar's top edge at **y 388**. Measured against that state, not the quiet one:
tallest card **197 px into a 213 px band, 16 px spare**.

**16 px is thin, and that is stated rather than dressed up.** It is measured
against an adversarial dock state that real play may never reach, and the guard
below fails loudly rather than letting a longer hint land on the hotbar in
someone's playtest — but a future lane authoring a longer `how` for the opening
ladder should expect to move this card, not nudge it.

`smoke_prompt_hotbar_dock.gd`'s own rule is what makes a centred position legal
at all — "persistent inventory shortcuts may frame that lane, but must not
cover it; contextual prompts intentionally remain centred" — and this is
contextual and transient, the same standing the region banner has.

The card drops the tracked line and carries the hint alone: adding it costs
another 63 px, which does not fit in the band at any width. Every authored hint
is a self-contained sentence naming its own subject, and the tracked line is in
the objective block at the same moment, having just changed.

**A second defect the measurement turned up, and fixed.** `OBJECTIVE_BLOCK_HEIGHT`
is a fixed 170 px, leaving 94 px of interior for the tracked line. Four authored
lines wrap past that. A `Label` does not clip by default, so the overflow drew
**out through the bottom of the block's own backing plate and onto the terrain**
— precisely the "floating on sky and terrain, one lighting change from
vanishing" failure HUD-POPUP added that plate to fix. Reproduced on `main`'s
layout before fixing: on "Build a Creature Bed for each of your entrants. 0/3"
the text ends at y 531 against a plate ending at y 480, a **51 px** spill. The
plate is now sized to its own text. This adds no occupied pixels — the text was
already drawn there; only the plate behind it was missing.

**Coverage.** `tests/smoke_objective_hint_card.gd` (new) drives the real HUD
over a real `Game` at 1920×1080 and measures `get_global_rect()`:

- all 13 authored hints fit the band, against the dock in its **tallest** state,
  and clear of every *visible* HUD widget's live rect — read off the tree, not
  listed by hand, so a widget added later is covered without anyone remembering
  to add it, and with the party strip deliberately revealed because a catch
  changes the party and the objective in the same instant;
- `Game.objective_hint` actually reaches the card's label (the band checks alone
  would pass against a card drawing an empty string);
- a rung with no authored `how` draws nothing, never a blank line —
  `tracked_hint()`'s own stated contract;
- the card stands down on its own deadline;
- the objective plate holds its longest authored line.

Verified non-vacuous three ways: narrowing the card to 500 px fails the band
check with the real dock overlap printed; restoring it to 1140 px fails the
neighbour check naming `PartyStrip` and its rect; suppressing the new plate
layout fails the plate check with `main`'s real 51 px spill printed. The
neighbour check reports what it measured against — `BottomDock, PartyStrip,
VitalsCluster, Minimap, ObjectiveBlock` — so a future run can see at a glance
whether it is still measuring a populated HUD.

CI ran none of this: `smoke_objective_hint_card` and (below)
`smoke_station_panels_hide_world_hud` are added to the UI smoke matrix in
`.github/workflows/ci.yml`. A guard CI never runs is not a guard.

**Frames.** `docs/evidence/hist-036/`, 1920×1080 through the real render path,
five-creature roster, stocked bar:

- `01-before-plate-fixed-170.png` — the block held at `main`'s fixed 170 px with
  the longest authored line in it. "your entrants. 0/3" is drawn below the
  plate, on the world, carried by its outline alone.
- `02-after-plate-fits-text.png` — the same line, same camera, plate sized to
  its own text. One thing differs between the two frames.
- `03-after-hint-card.png` — the card up, centred, clear of the objective block
  and the dock.

The backdrop in all three is a low-detail fogged view near the authored spawn.
These frames are evidence about **HUD composition**; nothing about the world's
own presentation should be read out of them.

**Not claimed.** Whether the card's dwell time feels right in hand, and whether
it reads at arm's length on a 7" panel, are [OWNER-ONLY].

### Two things the capture cost, worth writing down

**A red cast that was not a lighting defect.** The first capture came back with
the entire frame — world *and* HUD — under a heavy red wash, which reads
exactly like the sun-azimuth family of defects `RC-5` is about. It is not. The
tool placed the player at a hand-picked `(-15, -1)`, the world's water level is
`y -17`, and `water.gd::is_fully_submerged()` is a **plain global-plane test**
with no footprint check — so the player drowned for the whole capture and every
frame carried `water.gd`'s damage-phase submersion tint, `Color(0.75, 0.12,
0.12)` at up to 0.55 alpha, on a `CanvasLayer` at layer 11 **above the HUD**.
The fix was to leave the player at the world's own authored spawn. Recorded
because the next lane to photograph this world from a hand-picked coordinate
will see the same thing and reach for the lighting.

Whether a global-plane submersion test is *correct* is not something this lane
can say from one capture: the water surface may be a global plane clipped to
wherever terrain is lower, in which case being under `y -17` really does mean
being under water. **Not investigated further, and not filed as a defect** —
`scripts/world/water.gd` belongs to the stall lane, and nothing here was
touched.

**A timed reveal photographed after its own deadline.** The dwell window is
real wall-clock time; a settle-plus-shutter under llvmpipe is a dozen frames at
seconds each. The first re-shoot photographed an empty band with the
visibility check just before it still passing. The capture tool now holds the
deadline open across the shutter — the window is not changed, only held still
while it is photographed.

---

### `HIST-153` — the exploration HUD draws over every station panel — **CLOSED (already fixed; guard added)**

**What it was.** Opening a bench, chest, shop, bed or swap panel left the world
HUD drawing straight over it — creature block, roster, vitals, hotbar and
minimap all painting across the panel's own rows. It survived an entire visual
sweep because those panels had only ever been photographed with **no world
behind them**, so there was no HUD in the frame to collide with. The register
records it as *found*, never as fixed, and it does not appear in that round's
own "what round 3 fixed" list.

**Verified before writing a line of fix, per CLAUDE.md.** Current `main`
already satisfies it. All five station panels — `craft_panel.gd`,
`storage_panel.gd`, `shop_panel.gd`, `swap_panel.gd`, `creature_bed_panel.gd` —
call `input_owner.gd::set_world_hud_visible()` on open, and restore it inside
the same `current(tree) == null` branch that releases pause. That is the
correct shape rather than merely a call in the right place: restoring on *any*
close would put the HUD back over a panel still open underneath it.

**When it landed is not claimed.** This container has a shallow clone (212
commits), so `git log -S` cannot see past the horizon and the one commit it
does name is a documentation sweep that happens to sit at the boundary. The
code is right on current `main`; who made it right is not established here.

**What was actually missing, and is now there.** `set_world_hud_visible` had
**zero** references anywhere under `tests/`. For a defect that already hid from
a full visual sweep once, the untested contract is the thing worth closing, not
the code. `tests/smoke_station_panels_hide_world_hud.gd` (new) drives all five
panels plus the helper itself:

- each panel hides **both** layers on open and gives both back on close —
  `PlaygroundHUD` and `CombatHUD`, because `combat_hud.gd` draws the encounter
  director's prompt line fight or no fight, so hiding only the exploration HUD
  still leaves "Call out Biscuit" printing through;
- the helper's own reach is asserted directly, so a regression that stopped it
  finding the second layer cannot hide behind the first;
- every panel is checked for non-vacuity first — if the layers were already
  hidden before `open()`, the check says so instead of passing.

A smoke test rather than a `test_*.gd` unit because `tests/test_case.gd`'s own
header limits that suite to pure logic, "not scenes, not rendering", and this
needs a `current_scene` for the helper to resolve against. It does **not** stand
up the Meadows: five panels over a two-node stand-in, seconds rather than the
four minutes a world boot costs.

Verified non-vacuous: deleting the `set_world_hud_visible(false)` call from
`craft_panel.gd::open()` fails the run naming that panel, with the other four
still passing.

---

## Gaps found while working, not fixed here

- **Three HUD smoke tests are in no CI job at all.**
  `smoke_hud_handheld_legibility.gd`, `smoke_prompt_hotbar_dock.gd` and
  `smoke_exploration_legend.gd` appear nowhere in `.github/workflows/ci.yml` —
  grepped by name across `.github/`. All three pass locally today, and both of
  this lane's HUD items lean on numbers those files assert
  (`MIN_PHYSICAL_TEXT_PX`, the 440 px focus lane, the dock's worst-case top
  edge). The two guards this lane added *were* wired into the matrix; wiring
  the three pre-existing ones is a CI-cost decision for whoever owns the
  pipeline, and is left as a finding rather than taken unilaterally.

---

### `HIST-013` — the combat HUD overlaps itself — **CLOSED**

**What it was.** In a fight, the active creature's name and level print on top
of another team member's, its HP bar runs under the mini-bar, and an "Energy"
label floats loose under the pile — *"the player cannot read their own team
during combat."* Located precisely by a blind pass (frames 10 and 11,
bottom-left). The register's note on what was left is exact: *"the remaining
overlap is the plate's own height or the strip's row count."*

It is both, and a third thing besides. `tests/smoke_combat_hud_left_column.gd`
(new) mounts `combat_hud.tscn` and measures. On `main` it fails three ways:

1. **`AllyPanel` grows 41 px above its own offsets.** Authored top y 874 on a
   1080 canvas, real top **y 833**. It is a bottom-anchored `PanelContainer`
   with `grow_vertical = 0` whose content needs more than the 150 px the scene
   gives it, and a Control forced past its minimum size grows its cached rect
   without writing that growth back to its offsets.
   `_party_strip_position()` computed from `offset_top`, so the roster was
   placed against an edge the plate is not at. The arithmetic was right about
   the wrong edge, which is why correcting it downstream could never have
   found this.
2. **The roster therefore overlapped the plate** — strip ending y 852.5 against
   a plate top of y 833.
3. **`party_strip.gd::HEADER_HEIGHT` was 24 px short.** Declared 30, real
   **54**: the header is a `PanelContainer` holding one label at
   `STRIP_READABLE_FONT_SIZE` (36) with 2 px margins, and a `PanelContainer`
   grows past its `custom_minimum_size`. This is precisely the trap `GF-B-006`
   recorded paying for on the *rows* earlier today — *"a declared row height
   under the real one makes every bound derived from it wrong"* — surviving one
   widget up, in the header, unmeasured.

**And (3) was live in the exploration HUD too, not only in combat.** With the
strip's real content at 394 px against a declared 370, the strip's fifth row was
drawing **10 px into the vitals plate — at both supported canvas heights**
(1080: real bottom 460 vs plate top 450; 1200: 580 vs 570). The same 10 px
`GF-B-006`'s own commit message describes catching in a first render and
fixing. `docs/evidence/hist-013/party-strip-before.png` shows it: the plate's
top edge cuts across the bottom of the Tuskroot row.

**Fixed.**

- `combat_hud.gd::_party_strip_position()` measures from `AllyPanel`'s **real
  rect**, keeping the authored offset only as the fallback for the one call
  from `_ready()` that runs before the panel has been laid out.
- `party_strip.gd::HEADER_HEIGHT` 30 → **54**, the measured height.
- `ROW_SEPARATION` 6 → 2 and `HEADER_GAP` 6 → 4 pay for those 24 px. Taken from
  the separations rather than from `ROW_SIZE.y` or `HEADER_HEIGHT`, because
  those two are measured heights and shaving either just re-tells the same lie
  one layer down. Every row is a plated `PanelContainer` with its own border
  and `ROW_MARGIN`, so five rows still read as five —
  `docs/evidence/hist-013/party-strip-after.png`, same seeded five-creature
  roster, same crop, one thing different.

**For the owner.** At the 1080 canvas the roster at its five-creature cap now
uses essentially the whole left column between the top safe inset and the
vitals plate. There is no room there for a taller row, a second header line, or
any sixth entry without moving the widget. That is a constraint discovered by
measuring, not a preference.

**Coverage.** `smoke_combat_hud_left_column.gd`, wired into the CI matrix,
asserts four things on the live scene: that `_party_strip_position()` measures
from the plate's **real** top (so putting the offset arithmetic back fails,
whatever the drift is that day), that the roster clears the plate, that the
strip's live stack fits `TOTAL_HEIGHT` — naming the child that grew when it
does not — and that no child of the plate escapes it. The 41 px offset drift is
**printed, not asserted**: the panel is allowed to grow, and the scene is free
to change; what must not change is which edge the code reads.

**Not claimed.** How the denser roster reads in hand on a 7" panel is
[OWNER-ONLY]. The `AllyPanel`'s authored offsets in `combat_hud.tscn` still
disagree with its real size by 41 px; nothing reads them any more, and they
were left alone rather than re-tuned by hand.

---

### `HIST-014` — the world HUD ghosts under the dialogue panel — **CLOSED (symptom already gone; guard added, design question left open)**

**What it was.** While Grandpa is talking, *"RB — Call out Terrapup"* shows
through the top edge of his dialogue box. The register names the root cause as
the five station panels being wired to `input_owner.gd::set_world_hud_visible()`
while the dialogue panel was not — and flags an open design question ahead of
any fix: **a conversation is not a menu, so hiding the whole HUD may not be
wanted.**

**Verified on current `main`: the reported symptom is gone, by a different
route than the register expected.** `dialogue_panel.gd` still does not call
`set_world_hud_visible()`, and does not need to for this symptom.
`playground_hud.gd::_yield_bottom_to_build_menu()` hides the hotbar **and** the
contextual prompt on `INPUT_OWNER.current(tree) != null`, and
`_exploration_legend_should_show()` stands the legend down on the same
predicate — and `dialogue_panel.gd` joins `INPUT_OWNER.GROUP`. So all three
bottom-dock widgets leave while a conversation owns input, the prompt among
them. Nothing else the HUD draws reaches the box's band (x 211–1709, y 772–1024
at 1080).

Measured rather than reasoned: with a five-creature roster revealed, a stocked
hotbar and a real "Call out Terrapup" prompt, **46** visible painting widgets
are on screen during `grandpa_house` and none intersects the box.

**The design question is deliberately not answered here.** `set_world_hud_visible`
is still not wired to the dialogue panel, and whether it should be is a
preference about what a conversation ought to look like, not a defect — the
item says so itself. Nothing was invented in either direction.

**Coverage.** `tests/smoke_dialogue_clears_the_world_hud.gd` (new, in the CI
matrix) guards the **outcome**, not the mechanism: no visible world-HUD widget
may composite through the dialogue box, and whatever stands down must come
back. A later lane can answer the design question either way and this file has
no opinion about how.

Two things it had to get right to mean anything, both paid for:

- **Container rects are not drawn content.** A first run failed on
  `Root/BottomDock` — a full-width `VBoxContainer` that spans the box's whole
  band and paints nothing, while all three of its children were correctly stood
  down. The check now walks the tree and skips the pure layout/grouping classes
  by name, which is also stricter: a single label left drawing inside a
  container whose own rect sits elsewhere would be caught.
- **Non-vacuity.** Removing the `INPUT_OWNER.current(...)` term from
  `_yield_bottom_to_build_menu()` fails the run naming ten widgets through the
  box — `Prompt (RichTextLabel)` among them, which is the reported symptom
  itself.

---

## 2026-08-28 — RC-5b, named landmarks have no landmark geometry

The coordinator's instruction was to check `HIST-008`/`HIST-119` for owner-art
blocks **before** starting, and to say so and move on rather than generating
anything. Checked, and then checked against the installed kit itself rather
than against the register's word for it.

### What the installed village kit actually contains

`assets/buildings/quaternius_medieval/` holds **64 modules**. The 18 prefabs in
`building_prefabs.json` use a subset, and **nine modules are used by no prefab
at all**: `Roof_Dormer_RoundTile`, every `Overhang_Plaster_*` and
`Overhang_Roof*` piece, `Roof_FrontSupports`, `Roof_Support2` and
`Prop_Support`. `tools/_probe_village_kit_modules.gd` (new) reports each
candidate's AABB relative to its own origin, because the recipe format is a
bare `at`/`yaw_deg` with **no offset or facing convention written down
anywhere**, and `tools/_capture_kit_module_card.gd` (new) renders one module at
four yaws so an author can see which way it points before writing a placement.
Both exist because the first cost of reaching for an unused module is finding
out how it is oriented, and guessing costs the same render and then another.

There is **no well, no mill machinery and no gate module** in the kit. That
confirms what the register says about `HIST-163` and `HIST-165` from a
different direction, and it is the same ground the defects lane refused
`GF-B-007` on today.

### Per item

- **`HIST-163` — the mill has no mill in it: BLOCKED, not started.** No wheel,
  sails, hopper, race or axle exists in any installed kit. A new mesh needs
  owner-supplied reference art and Meshy is reserved for Team Tether hero
  objects; a mill wheel is neither. Nothing generated.
- **`HIST-165` — the well has no well: BLOCKED for the shaft, partly not.**
  Same absence for the winch and shaft. Worth recording for whoever picks it
  up, since it is not in the register: `Bucket_Wooden_1` and `Rope_1` **are**
  installed (`assets/props/quaternius_fantasy/`), so the bucket-and-rope half
  needs no new art. The shaft mouth and water are primitives, not assets. Not
  attempted here — a bucket on a well that still has no hole is dressing.
- **`HIST-166` — bridges and gates are overlapped fence panels: BLOCKED.** The
  kit has `Wall_Arch` and fence pieces and nothing gate-like. Not started.
- **`HIST-164` — three named landmarks are two kits used twice: PARTIAL, and
  shipped.** Below.

### `HIST-164` — the inn — **PARTIAL**

**Re-derived before touching anything.** The inn and `farmhouse_shell` have
**identical module histograms** — 74 modules against 75, and the one extra is a
door leaf, which is not visible from outside. `docs/evidence/hist-164/
twins-*-before.png` is the frame the critic described: the two standing side by
side, differing only in the inn's one extra roof-tile retint.

**Shipped, with no new art:**

- A **second chimney** at the opposite end of the ridge — `Prop_Chimney`, a
  different module from the `Prop_Chimney2` already there, so the two do not
  read as one stack duplicated. It is 3.18 tall against 3.00, and it is the
  only silhouette difference this building has at the distance the square sees
  it from.
- **Per-material differentiation**: `MI_WoodTrim` to dark stained oak and
  `MI_Plaster` to a warm limewash. Half-timbering is the dominant texture on
  both buildings, so those two named surfaces change how the whole facade
  reads, where the roof alone changes one band of it. Named surfaces, not
  `art.json`'s single multiply over every surface, which spec §21 names as the
  failure. The prefab's existing `_why_retint` — which claimed the roof tint
  "is the whole of how it reads as its own building rather than a second copy
  of the farmhouse shell" — is amended in place with the finding that
  contradicts it, rather than replaced.

**A process note worth carrying.** The first pass at this edit round-tripped
`building_prefabs.json` through `json.dumps(indent=2)`, which reformatted every
hand-compacted collider row and `at` array in the file — a 426-line diff over
seventeen prefabs this lane never looked at, for a 5-line change. Caught before
push and redone as a targeted text patch: **18 lines**. A data file in this repo
is hand-formatted and a formatter is not a neutral tool on it.

`docs/evidence/hist-164/twins-*-after.png`, same camera, same lighting, same
neighbour.

**What was tried and rejected, with the measurement.** Four dormers —
`Roof_Dormer_RoundTile`, in the kit, used by nothing, and the single clearest
"rooms upstairs to let" signal available. Three trial renders established the
facing (yaw 0 faces +x; the module card alone was not enough) and the seat
(y ≈ 7.2 at x 2.6 — the roof's AABB is misleading, its local max y is 4.89 but
the visible ridge is nearer y 9.1, and a first trial at y 8.0–9.2 floated every
dormer above the ridge). Then the front elevation showed why it cannot work:
**the module is sized for a bigger roof than the inn has.** It is 1.90 m deep
against a slope run of about 4.1 m and 2.67 m tall against a total eave-to-ridge
rise of about 2.8 m, so at any seat it either overhangs the eave — visibly
detached in `twins-front-*` — or tops the ridge.

`scale` **is** supported per module and 0.65 would fit. It was **not** taken:
`HIST-038` (`STRONGHOLD-MERLONS`) is an open item about exactly that — a
uniform per-module scale producing "three merlon sizes in one castle
silhouette" — and a dormer whose roof tiles are two-thirds the size of the tiles
they sit on is the same defect on a smaller building.

**Why this is partial and not closed.** The massing is unchanged. The inn is
still the same footprint, the same roof module and the same window pattern as
the farmhouse, and that is half of what "the same kit used the same way twice"
means. Changing it needs a different roof/footprint combination — the kit does
carry `Roof_RoundTiles_4x4/4x6/4x8/6x4/6x6/6x8/6x10`, so an L-plan or a wider
inn is possible without new art — but that is a re-authoring of a 75-module
recipe with its own door, room and collider specs, and it wants owner sight
before someone spends it. **The ranger station half of the item is untouched.**

---

## CI on this branch

Four runs, one per push. Runs 2610 (`HIST-036`/`HIST-153`) and 2616
(`HIST-014`, carrying `HIST-013`) concluded **success**. Run 2619 (RC-5b)
concluded **failure** on two jobs out of 55, and **neither is this branch's**.

**The four guards this lane added all passed** on run 2619:
`objective_hint_card`, `station_panels_hide_world_hud`,
`combat_hud_left_column`, `dialogue_clears_the_world_hud`.

### `verify-continuous-core-known-red` — expected

The job is named KNOWN RED, its step is labelled `(KNOWN RED)`, and it carries
`continue-on-error: true`. It failed identically on run 2616, which GitHub
still concluded as success — the run-level conclusion is inconsistent for
`continue-on-error` jobs, not a change in what is red.

### `verify-owner-regressions-shard (party_count_after_catches)` — not this branch's

Failed on run 2619 having passed on run 2616. Four things say it is not the
diff:

1. **It passes locally on the exact failing SHA.** Three real catches through
   the real minigame, `TEAM 3 / 5` on screen, three occupied portrait rows
   agreeing with the counter, surviving a save/reload.
2. **The reported symptom is upstream of everything this lane touched**: *"could
   not catch Wild_bramblebun_0_1 in 25 throws"* and *"the winning prompt is
   EncounterDirector, not the target"*. The party was genuinely empty; the HUD
   assertions after it read 0 because there was nothing to read.
3. **The HUD assertions it printed cannot be broken by the `HIST-013` change.**
   They read `_hp_bars[i].visible` and `_slot_labels[i].visible` — per-row
   fields, untouched by `ROW_SEPARATION` or `HEADER_HEIGHT`, which are
   geometry.
4. **The same arbiter symptom failed the known-red job in the same run**, which
   points at that runner's world/interaction timing rather than at two
   different regressions landing at once.

The only delta between the passing run 2616 and the failing 2619 is one inn
recipe entry, two capture tools and this log — none of which is in a wild
creature's path.

**Re-run: 0 failed jobs.** Both went green on the re-run, which is the
confirmation the drive-to-green rule allows for a failure that is not the
diff's. (The first re-run request was cancelled by this lane's own next push —
`concurrency: cancel-in-progress` applies to non-`main` refs — so it produced
no signal and was re-requested; that is one confirmation obtained, not two
spent.)

**Local corroboration on the same head:** the full unit suite, **1472 tests,
3,353,109 assertions, 0 failed**.
