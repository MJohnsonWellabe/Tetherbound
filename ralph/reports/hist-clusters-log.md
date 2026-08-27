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
