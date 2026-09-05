# N06-MAP-UI — the map screen's eight legibility defects

Branch: `ralph/N06-MAP-UI-0905`, based on `origin/main` at `f8a47ee4`.
Source: W11-ALPHA-PINS-0904's report, its own round-3 blind judge verdict.
Owns: `scripts/ui/tab_map.gd` and `scripts/ui/minimap.gd`.

---

## 0. Two things about the starting state, before anything else

**(a) W11-ALPHA-PINS-0904 has NOT landed on `main`.** `ralph/briefs/0905-followup/COMMON.md`
says "all 24 base lanes have landed; you are working on top of finished, merged work." That
is not true for W11. On `origin/main` at `f8a47ee4` — re-fetched at the start of this lane and
again before the final push, still `f8a47ee4` — there is no `scripts/world/alpha_pins.gd`, no
`data/config/map.json`, no `tests/test_alpha_pins.gd`, no `tests/smoke_alpha_pins.gd`, and no
alpha branch in `tab_map.gd::_draw_icon()`. W11's report and its `_sheet_alpha_pin.png` exist
only on `origin/ralph/W11-ALPHA-PINS-0904`, which is where this lane read them from.

The brief told me to base on `origin/main` at `f8a47ee4` or later, and I did. The consequence
is recorded here rather than worked around:

* Items 1, 3, 4, 5, 6 and 7 are about the map SCREEN and are unaffected — they are fixed and
  verified here in full.
* Items 2 and 8 name the alpha pin specifically. Both were caused by treatments **shared by
  every marker on the screen**, not by anything in the alpha path, so both are fixed at the
  shared treatment — which is where the judge itself said the fix belonged ("legend swatches
  should be the marker art at the colour and size it actually draws"; "the same underlying
  issue as item 1's fog contrast"). When W11 lands, its alpha marker and its `Alpha` legend
  row inherit the fixes without touching a line of its diff, because they go through the same
  `_draw_icon()` / `_legend_entry()` / `_draw_string_legible()` this lane changed.
* What I could NOT do is re-render a frame containing an alpha pin, so the judge in §5 was
  shown this screen without one. Said plainly rather than implied.

**(b) `tests/smoke_alpha_pins.gd` and `tests/test_alpha_pins.gd` could not be run.** The brief
requires them to still pass. They do not exist on this base. `git ls-tree origin/main
tests/test_alpha_pins.gd` is empty. This is the same fact as (a) and is the coordinator's to
resolve — the honest statement is that this lane did not change pin logic (it does not exist
here to change), and the treatments it did change are the ones W11 asked for.

---

## 1. Files changed

`git diff --name-status origin/main...HEAD`:

| Status | File | Why |
|---|---|---|
| M | `scripts/ui/tab_map.gd` | items 1–5, 7, 8 on the full map |
| M | `scripts/ui/minimap.gd` | items 1, 7, 8 on the HUD minimap — the shared halves |
| A | `tests/test_map_legibility.gd` | pins every value relationship the judge measured |
| A | `tools/_capture_map_ui_0905.gd` | the four before/after world stands, from one boot |
| A | `tools/_capture_minimap_isolated_0905.gd` | two minimap stands the world boot cannot produce (§4) |
| A | `tools/_measure_map_ui_0905.py` | measures a frame's flat fields and their contrast |
| A | `tools/_sheet_map_ui_0905.py` | assembles the one contact sheet COMMON.md allows |
| A | `ralph/reports/N06-MAP-UI-0905/` | this report and `_sheet_map_ui.png` |

Each new `.gd` carries its `.uid`, which is how every other script in `tests/` and `tools/` is
tracked on `main`.

**A diff-hygiene note, because this bites every lane that runs an import.** `godot --import`
also generated `.uid` sidecars for twelve OTHER lanes' scripts — the `cloudreach` /
`realm_heart` set, which are tracked on `main` *without* their sidecars. This is the same trap
W11-ALPHA-PINS-0904's own report recorded (an import there swept 58 unrelated files into a
feature commit). They were **deleted**, not committed and not merely left unstaged: a `.uid` is
a generated artefact that the next import recreates, `main`'s own CI runs without them, and
carrying another lane's files in this diff is exactly what COMMON.md's ownership rule forbids.
The working tree is clean and the branch diff above is the complete list.

Nothing outside `scripts/ui/tab_map.gd` and `scripts/ui/minimap.gd` is modified. The new test
and the three tools are additive files that no sibling lane in this wave owns.

**One temporary, fully-reverted excursion**, recorded because COMMON.md forbids touching files
outside the ownership list: `project.godot`'s `map_zoom_in` action had its joypad event
removed for one test run, to watch the item-6 assertion go red for the right reason (§3), then
restored. `git diff -- project.godot` is empty and the file is absent from this branch's diff.

---

## 2. The eight items

### 1. Fog is inverted — "the single largest defect on the screen"

**The judge's finding was real and its cause was not what it looked like.** It reported the
surveyed corridor at RGB(5,5,7), *darker* than an unexplored field at RGB(17,26,31), 1.16:1
apart. A capture of unmodified `main` reproduces both numbers exactly:

```
tools/_measure_map_ui_0905.py  (before, map_fresh)
  RGB(17, 26, 31)   35.82%   rel.lum 0.0096
  RGB( 5,  5,  7)    3.29%   rel.lum 0.0016
  RGB(17,26,31) vs RGB(5,5,7)   1.16:1
```

and identifies them. RGB(5,5,7) is `FOG_UNDISCOVERED`'s old `Color(0.02, 0.02, 0.03)` — the
**unexplored** corridor, not the surveyed one. RGB(17,26,31) is `UITokens.BG_DEEP` (#10191E),
the page `_draw_map()` fills the whole canvas with before it draws anything — the empty gutters
either side of a 4:1 corridor in a 16:9 panel, not unexplored ground.

So the fog was not literally inverted against the terrain. It had collapsed into the **chrome**:
unexplored ground and the empty page around the map were the same colour to within 1.16:1, the
map had no readable footprint on its own screen, and the judge — reading the corridor-shaped
black column as "the corridor the player surveyed" — described exactly what a player sees and
drew the only conclusion available from it. The before frame is unambiguous: at a realistic
early-game coverage the map body is a black rectangle. That is also the owner's own OP23-03
report, "the map is still a black rectangle," which a previous pass had answered by widening
the starting reveal rather than by making fog legible.

**The fix is a three-tier value ladder** where there were two colliding tiers. `FOG_UNDISCOVERED`
moves from `Color(0.02, 0.02, 0.03)` to `Color(0.227, 0.314, 0.361)` (#3A505C) on both screens
— two rungs up the same cool `BG_PANEL_ALT` ramp the menu chrome already uses, not a warm
parchment fill (the existing header note rejected that, and that rejection stands). Measured on
the rendered after frame:

| | before | after |
|---|---|---|
| page chrome `BG_DEEP` | RGB(17,26,31) | RGB(17,26,31) |
| unexplored fog | RGB(5,5,7) | RGB(57,80,92) |
| **chrome → fog contrast** | **1.16:1, fog darker** | **2.08:1, fog lighter** |
| revealed meadow → fog | — | **3.51:1, revealed lighter** (from constants; see §3) |

The map now has an edge, unexplored ground reads as a surface rather than a hole, and explored
ground is the brighter half of the pair the judge asked about.

**It did not reopen OW3.** The fill is still fully opaque, so it hides the terrain underneath
completely whatever its colour: a player who has walked nowhere still sees zero terrain.
`test_map_fog.gd` (unchanged, still green) pins that, and `test_map_legibility.gd` asserts it a
second time specifically against this change.

### 2. Legend swatches are indistinguishable

The before frame shows the cause plainly: three legend rows —
`♠ Grandpa's House   ⊳ The Village   ▣ Road Gate` — as three near-identical pale glyphs.
`_legend_entry()` built a bare 24×24 `TextureRect`. On the map the same icons are drawn by
`_draw_icon()` at their category size ON a dark backing disc; several of the vendored icons in
`assets/ui/icons/map/` are pale, low-contrast line art that only becomes a mark once it has
that disc under it. So the one place on the screen whose job is to teach the symbol set was
showing symbols that did not match the map's, as pale smudges, at one flat size.

The swatch is now drawn through the **same** `draw_marker_knockback()` and `_marker_size()` the
canvas uses, carrying the real backing, the real category size class, and any tint the marker
carries. It is a closure bound to those functions rather than an inner `Control` subclass,
deliberately: an inner class cannot see this script's consts or statics, so a subclass would
have to re-declare the marker geometry and could then drift from `_draw_icon()` — which is the
defect being fixed. The after frame's `MAP KEY` row is a white house glyph on its dark disc,
identical to the marker on the map.

### 3. Two typefaces on one screen

Confirmed in the before frame and glaring once looked for: `Map` / `Satchel` / `THE MEADOWS` /
`[Minus] Zoom Out` are `Label` nodes in the theme's humanist sans; `DISCOVERED REGIONS` /
`GRANDPA'S VILLAGE` / `DESTINATIONS` / `GRANDPA'S HOUSE` are `draw_string` calls in
`UITokens.FONT_PATH` (`kenney_future.ttf`), a condensed geometric techno face. Nothing chose
the pairing — a `draw_string` has to name a font and a `Label` does not, so the two halves of
one screen drifted apart.

Resolved toward the **chrome**, via a new `_canvas_font()` that returns
`get_theme_default_font()` — literally the same lookup the Labels on this tab resolve, so the
two cannot diverge again even if the project later sets a theme font. That is the map joining
the house style (every Label in the game) rather than a third opinion. `ThemeDB.fallback_font`
is the fallback for measuring text before the tab is in a tree, which the headless label-layout
path does.

`minimap.gd` draws its own text in the same techno face and was left alone: it is a different
screen, sitting among HUD Labels rather than this tab's, and changing it is beyond an item
scoped to "the map screen". Flagged rather than silently widened.

### 4. Text boxes are drawn with no container

The judge's reasoning was right and its prediction needs one correction, which is worth
recording so nobody re-derives it. The columns sit in the side **gutters** — `map_rect` at
whole-world fit is a ~96px strip in a ~1112px canvas — and the gutters are page, not map. So
"at 40% surveyed they will overlap revealed terrain" cannot happen at fit today; and at any
zoom above fit `_draw_overview_callouts()` is not called at all. The 1.42%-surveyed after frame
confirms it.

But the protection is incidental, not structural: `_draw_callout_heading`'s own rect ends at
`map_rect.position.x - 42`, i.e. it is defined BY the map edge rather than clear of it by
construction, and `map_rect` grows with zoom and with panel aspect. And the columns were, as
the judge said, held up by nothing but a text outline over whatever was behind them.

Both columns now get a real container (`_draw_callout_backing()`), sized from the callouts
actually placed that frame so an empty column draws nothing. The surface is `BG_PANEL_ALT`, not
`BG_DEEP`, for a reason worth stating because the obvious choice is wrong: `_draw_map()` fills
the entire canvas with `BG_DEEP` first, so a `BG_DEEP` container would be invisible against the
exact surface it is meant to lift its contents off.

### 5. No north indicator, no scale bar; the legend reads as a third keybind row

All three confirmed in the before frame, all three addressed:

* **North indicator** (`_draw_north_indicator`), top right of the canvas: a split white/teal
  needle on a chrome disc with an `N` under it. It is a fixed mark because this map is
  north-up and never rotates — which is exactly why a reader needs it, since the minimap
  beside it in play DOES rotate, and without a compass the two screens silently disagree
  about what "up" means. The destination column's label width now reserves the compass's
  corner so a long place name cannot grow into it.
* **Scale bar** (`_draw_scale_bar`), bottom left: a ruler with end ticks and a metre label,
  derived from `map_rect` rather than from `_zoom`, so it stays true at any zoom, any panel
  aspect, and if the world extent changes under this screen. The step is chosen as the widest
  round number that fits 150px — at whole-Meadows fit that is **2000 m**, visible in the after
  frame.
* **The legend** is no longer a bare `HBox` between two rows of glyph-and-text pairs. It sits
  in its own bordered panel, captioned `MAP KEY`, with a rule between the caption and the
  rows. It now reads as the key to the map's symbols, which is what it is, rather than as a
  third row of keybinds.

### 6. Map zoom has no controller binding — **already true on `main`; verified, not changed**

The binding exists. `project.godot` gives `map_zoom_in` `InputEventJoypadMotion` axis 5 (RT)
and `map_zoom_out` axis 4 (LT), and `scripts/ui/input_glyph.gd` maps both to `xbox_rt.png` /
`xbox_lt.png`. `_refresh_controls_label()` re-reads the live device every `poll()`, so the
footer shows pad glyphs on a pad and keyboard glyphs on a keyboard.

The judge read `[Minus]`/`[Equal]` off a frame captured in a container with no pad attached —
correct about the frame, and the frame was correct too. This is an evidence-backed "already
fixed", so per CLAUDE.md it is verified and reconciled rather than rewritten:

* `tests/smoke_gate_a_map_cycle.gd` drives a **real pad** and already reports
  `physical Map/Back, RT/LT zoom, right-stick pan/clamp, and world recovery all work`. Run on
  this branch: pass (§3).
* `test_map_legibility.gd::test_map_zoom_is_reachable_from_a_controller` pins both actions'
  pad events so the judge's reading cannot become true later. Watched go red by deleting the
  joypad event from `project.godot` and restored (§3).

Nothing was changed for this item. Changing a binding that works to answer a misreading of a
frame would have been the wrong move.

### 7. Shared label treatment loses danger labels in greyscale

Fixed in the shared function, as the brief asked — `_draw_string_legible()`, which every canvas
label on the map goes through, not the alpha path. The judge measured `ALPHA TRAILPUP`
collapsing to L≈136 while `GRANDPA'S HOUSE` and `THE VILLAGE` sat at L=255: the one label that
means DANGER was the dimmest text on the screen, because a coloured label was drawn at its
token colour and nothing else, so its whole claim on attention was hue — the one channel that
does not survive greyscale, a colour-blind player, or a handheld panel in daylight.

Labels now take their weight from **value** first. `label_core_colour()` lifts a fill toward
white by exactly the amount that brings its Rec. 709 luma to `CANVAS_LABEL_MIN_LUMA` (0.90) and
no further — a closed form, `t = (target - luma) / (1 - luma)`, not a search — and the dark
outline behind it is drawn at `CANVAS_OUTLINE_SIZE` (10) rather than the shared
`UITokens.OUTLINE_SIZE` (6), which is authored for Labels a third of this screen's font size.
Hue survives: a lifted `DANGER` label is still red-dominant, and a label already over the bar
(`TEXT_PRIMARY`, luma 0.958) is returned untouched.

The greyscale spread the judge actually measured:

| | before | after |
|---|---|---|
| `TEXT_PRIMARY` place name | L 244 | L 244 |
| `TEXT_SECONDARY` region name | L 194 | L 230 |
| `DANGER` label | L 124 | L 229 |
| **spread, brightest to dimmest** | **120 of 255** | **15 of 255** |

After this the labels on the map differ by hue and barely at all by value, so no label can be
"the dimmest text on the screen". `minimap.gd` gets the same rule for its own drawn text
(`TEXT_MUTED` "?" silhouettes at luma 0.56 against `TEXT_PRIMARY` distance labels at 0.96 — the
same shape of defect one screen over), and a test asserts the two screens ink an identical
colour identically.

### 8. A threat pin's silhouette is contaminated by the terrain under it

Fixed at the shared marker backing, which is where the judge said it belonged ("the same
underlying issue as item 1's fog contrast"). The old plate was
`Color(0.02, 0.03, 0.04, 0.72)` — **28% of whatever terrain was underneath still came
through**, and around a spiked or notched glyph that show-through lands precisely in the
notches, which is the contamination measured. Tinting is not knocking back.

`draw_marker_knockback()` now draws an opaque core (`MARKER_KNOCKBACK`, alpha 1.0) with a
translucent skirt one step wider, so the disc still reads as a shadow under the glyph rather
than as a hard coin, and the terrain under a marker ends outright. Applied to every marker on
both screens — `tab_map.gd::_draw_icon()`, the legend swatch, and `minimap.gd`'s landmark
icons, camp dots and `?` silhouettes, which previously drew bare white shapes straight onto the
bake and are a near value match on the pale high ground at the top of its height ramp. The
backing measures 7.97:1 against meadow green and 9.67:1 against that pale high ground.

---

## 3. Tests, smokes and runtime validation

Godot 4.7-stable, installed per COMMON.md. Every command below was run in this container on
this branch's tree.

### The lane's own test

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_map_legibility.gd
→ 13 tests, 28 assertions, 0 failed
```

**Seen red, four times, each for the right reason, each restored and re-run green.**

| Broken | Result |
|---|---|
| `FOG_UNDISCOVERED` reverted to `Color(0.02, 0.02, 0.03)` | **2 failed** — `test_unexplored_ground_is_distinguishable_from_the_page_it_sits_on`, `test_the_two_screens_fog_the_same_ground_the_same_way` |
| `label_core_colour()` made a no-op (`return colour` first line) | **3 failed** — `test_a_danger_label_is_no_longer_the_dimmest_text_on_the_map`, `test_every_label_colour_the_map_uses_clears_the_value_floor`, `test_the_minimap_lifts_its_labels_by_the_same_rule` |
| `MARKER_KNOCKBACK` reverted to `Color(0.02, 0.03, 0.04, 0.72)` | **1 failed** — `test_a_marker_knocks_the_terrain_under_it_all_the_way_back` |
| `project.godot`'s `map_zoom_in` joypad event deleted | **1 failed** — `test_map_zoom_is_reachable_from_a_controller`, message: "map_zoom_in has no controller binding; this is a controller-first project and the map cannot be zoomed without a keyboard" |

The first red is worth reading, because it is the finding: reverting the fog did **not** fail
`test_explored_ground_reads_lighter_than_the_fog` — near-black fog is still far darker than
meadow green, so the "explored vs fog" direction was never the broken one. What was broken is
fog against the page, which is the test that went red. That is the same conclusion §2 item 1
reaches from the measured frame, arrived at independently.

### The named and neighbouring tests

```
godot --headless --path . --script tests/run_tests.gd -- --only=test_map_fog.gd,
  test_map_icons.gd,test_map_zoom_persistence.gd,test_map_baker.gd,test_map_state.gd,
  test_map_landmarks.gd,test_ui_tokens.gd
→ 74 tests, 478 assertions, 0 failed
```

`test_map_fog.gd` is the one that could have been broken by item 1 and was not: it pins
`FOG_UNDISCOVERED.a == 1.0` and `FOG_DISCOVERED.a == 0.0` on both screens, and the new colour
keeps both.

### Smokes — the live map screen

```
godot --headless --path . --script tests/smoke_menu.gd
→ "menu smoke test passed"; exit 0

godot --headless --path . --script tests/smoke_gate_a_map_cycle.gd
→ ok  real pad LB cycles five owned creatures, wraps, and skips resting
→ ok  resolved travel stays map-up while stationary right-stick look remains independent
→ ok  zoom keeps the view pinned to the player
→ ok  physical Map/Back, RT/LT zoom, right-stick pan/clamp, and world recovery all work
→ "Gate A map/cycle: OK"; exit 0
```

```
godot --headless --path . --script tests/smoke_menu_focus.gd
→ "menu focus smoke test passed"; exit 0

godot --headless --path . --script tests/run_tests.gd -- --only=test_menu
→ 12 tests, 160 assertions, 0 failed
```

`^ERROR:` 2, 3 and 2 respectively, `SCRIPT ERROR` 0 in all three. **The known-benign set did not
grow**: every one of those errors is `Parameter "material" is null` from the headless dummy
renderer, with backtraces in `creature_body.gd::_build_model` via
`encounter_director.gd::_make_alpha` — nothing from `tab_map.gd` or `minimap.gd`.

`smoke_gate_a_map_cycle.gd` is this lane's real runtime validation as well as item 6's: it
opens the tab, drives a physical pad through zoom and pan, and recovers to the world, which
exercises the rebuilt `build()` (the legend is now a panel with a caption and a rule, so focus
and layout could have broken) and `poll()`.

### The rendered path

`_draw()` is not reachable headlessly, so it is validated by the two 1280×800 renders in §4,
which run the full `_draw_map()` — fog texture, terrain, the icon pass, the callout columns and
their new containers, the compass, the scale bar and the player marker — on the real world
scene. Both runs logged exactly **one** `ERROR:` (the container has no ALSA audio device) and
zero `SCRIPT ERROR`, identical before and after.

### Not run, and why

The full ~28-minute suite was not run: this diff changes no save format, no data schema and no
shared token — `UITokens` is read, never written — and its blast radius is two UI scripts whose
own tests and both map smokes are green. `tests/test_alpha_pins.gd` and
`tests/smoke_alpha_pins.gd` do not exist on this base (§0b). The known red COMMON.md names on
`main` (`verify-terrain-bake-freshness` and its unit shard, from a stale
`data/terrain/playground/manifest.json`) is N10's and was not chased; nothing in this diff
touches `data/`.

**CI could not be observed from this container** — there is no `gh`, and the GitHub API returns
"GitHub access is not enabled for this session". The coordinator must check the run on
`ralph/N06-MAP-UI-0905` and confirm the code jobs actually ran (COMMON.md: a run under five
minutes verified nothing).

---

## 4. Frames

One capture tool, `tools/_capture_map_ui_0905.gd`, four stands from a single world boot, run
exactly as COMMON.md prescribes — under `xvfb`, with a rendering driver, and never
`--headless` alongside it:

```
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_map_ui_0905.gd -- --out=<dir>
```

Run twice, on identical stands: once on unmodified `main`, once on this branch.

| stand | what it is for |
|---|---|
| `map_fresh` | a brand new save, 0.42% surveyed — the "black rectangle" worst case |
| `map_day1` | the day-1 footprint `tools/capture_map_tab.gd` already seeds |
| `map_surveyed` | 1.42% surveyed |
| `hud_minimap` | the menu closed, so the HUD minimap is on screen |

**A finding about the existing harness, recorded because it made a stand useless.**
`tools/capture_map_tab.gd`'s two frames — `map_tab_fresh` and `map_tab_day1` — are the same
picture. Its day-1 reveal (`reveal_circle` at `(-6, -13)` r=55, plus three `mark_visited`)
falls entirely inside the village area the starting seed already reveals, so
`discovered_fraction` is **0.42% before and 0.42% after**, printed by this lane's own capture at
both stands. Anyone comparing those two frames is comparing a frame with itself. My
`map_surveyed` stand exists to be a genuinely different coverage and reaches 1.42%.

**A limitation, stated rather than glossed.** `map_surveyed` is 1.42%, not the 40% the judge's
item-4 prediction is about. The corridor is 2048 × 8192 m and a sweep of 96 overlapping 34 m
reveals covers ~1.3% of it; reaching 40% needs a reveal an order of magnitude wider, and each
of these stands costs a ~45-minute world boot under software GL. I did not spend two more boots
on it because §2 item 4 settles the question structurally instead: the callout columns are in
the gutters, and at any zoom above fit they are not drawn at all — so terrain cannot reach them
today whatever the coverage. The container was added anyway, for the reason the judge gave.

### Two more stands, because the world boot could not show the minimap at all

`hud_minimap` renders the widget **byte-identically before and after**. Diffed: the top eight
colours in a 128×132 crop of the widget match to the pixel. The reason is the stand, not the
change — the player wakes in the village at a 90 m span, where the starting reveal has already
lifted every cell inside the widget and no landmark marker falls in it, so there is no fog and
no marker for either change to touch.

`tools/_capture_minimap_isolated_0905.gd` fixes that without a third world boot.
`minimap.gd::configure()` takes a `MapState` and a `Texture2D` directly, so the real widget can
be stood up against a real `MapState` in **seconds**, at two stands the world spawn cannot
produce:

* `minimap_fog` — standing at the far edge of the starting reveal, **408 cells revealed / 217
  fogged** inside the widget. Nothing extra is revealed; this is a real fresh save's own fog.
* `minimap_markers` — standing among discovered landmarks, two markers inside the widget.

Run on this branch and, with `scripts/ui/*.gd` restored to `origin/main`, on `main`. The ground
is a synthesised meadow-green ramp rather than `map_baker.gd`'s bake, which needs a live world —
built from the baker's own colour expression, so it is the right stand-in for judging a fog
value and a marker silhouette against ground, and the wrong one for judging the bake itself.

```
minimap_fog        before                       after
  fog              RGB(5, 5, 7)                 RGB(57, 80, 92)
  revealed ground  RGB(170, 182, 141)           RGB(170, 182, 141)
  ground vs fog    9.49:1, ground lighter       3.95:1, ground lighter
```

**This is the honest shape of the trade and it belongs in the report.** Explored-versus-fog was
never the broken relationship — at 9.49:1 with ground lighter it was already correct and
generous, which is exactly what the red-check in §3 showed from the other direction. Lifting the
fog spends some of that headroom (9.49 → 3.95, still well over the 2.5:1 floor the test asserts)
to buy the relationship that WAS broken: fog against the page chrome, 1.16 → 2.08. The screen
was carrying one strong contrast and one collapsed one; it now carries two good ones.

`minimap_markers` is where item 8 shows: before, two bare white diamonds sit directly on the
pale-green ground with no separation of their own; after, each sits on an opaque knock-back disc
with a soft skirt, and the silhouette is unambiguous in greyscale. The `?` silhouette label in
`minimap_fog` is item 7's minimap half, visibly lifted.

Contact sheet: `_sheet_map_ui.png` — six **after** stands at half scale (the four world stands
plus the two isolated minimap stands), one sheet, as COMMON.md allows. No per-frame PNGs are
committed.

### One finding this lane did not fix

**At whole-Meadows fit the player marker is wider than everything a day-1 player has explored.**
The marker's own legibility halo (OP21-15) is `PLAYER_MARKER_RADIUS + PLAYER_FACING_BASE +
PLAYER_FACING_LENGTH + 4` = 36 px radius; the corridor is 8192 m tall drawn into ~385 px, so that
halo covers ~1530 m of world. The entire starting reveal plus this lane's 1.42% sweep is ~460 m
across — about 21 px. So in `map_surveyed` every revealed cell in the world is underneath the
player marker, and the map cannot show an early player where they have been at fit zoom. Not
this lane's to fix: shrinking that halo reverses OP21-15's own blind-pass fix, and the real
answer is probably that the map should open at a zoom level fitted to the explored region rather
than to the whole chapter. Routed rather than attempted.

### Measurements

`tools/_measure_map_ui_0905.py`, on the frames themselves. The thresholds were decided from the
constants before the render and are asserted in `test_map_legibility.gd`; these are the
rendered frames agreeing with them.

```
BEFORE  map_fresh
  RGB(17, 26, 31)  35.82%  rel.lum 0.0096   <- UITokens.BG_DEEP, the page
  RGB( 5,  5,  7)   3.29%  rel.lum 0.0016   <- FOG_UNDISCOVERED, unexplored ground
  contrast 1.16:1, the page is the LIGHTER of the two

AFTER   map_fresh
  RGB(17, 26, 31)  28.68%  rel.lum 0.0096   <- the page, unchanged
  RGB(57, 80, 92)   3.12%  rel.lum 0.0738   <- FOG_UNDISCOVERED, unexplored ground
  RGB(29, 47, 54)   6.01%  rel.lum 0.0256   <- the new callout containers (item 4)
  contrast 2.08:1, unexplored ground is now the LIGHTER of the two
```

Predicted 2.10:1 from the constants; measured 2.08:1 on the frame — the ~0.02 gap is the frame's own 8-bit quantisation of #3A505C to RGB(57,80,92).

---

## 5. The blind judge

<!-- JUDGE -->

---

## 6. Final state

| | |
|---|---|
| Branch | `ralph/N06-MAP-UI-0905`, based on `origin/main` at `f8a47ee4` |
| Files in the diff | 11, all this lane's (see §1); `scripts/ui/tab_map.gd` and `scripts/ui/minimap.gd` are the only files modified |
| Lane test | `test_map_legibility.gd` — 13 tests, 28 assertions, 0 failed; watched red four times, each for the right reason |
| Named tests | `test_map_fog` / `test_map_icons` / `test_map_zoom_persistence` / `test_map_baker` / `test_map_state` / `test_map_landmarks` / `test_ui_tokens` — 74 tests, 478 assertions, 0 failed |
| Menu tests | `--only=test_menu` — 12 tests, 160 assertions, 0 failed |
| Smokes | `smoke_menu`, `smoke_gate_a_map_cycle`, `smoke_menu_focus` — all pass, exit 0, 0 `SCRIPT ERROR`, known-benign `^ERROR:` set unchanged |
| Frames | 4 world stands × before/after + 2 isolated minimap stands × before/after, all 1280×800 or the widget's real 240px |
| Contact sheet | `_sheet_map_ui.png`, six after stands, one sheet |
| Items | 8 of 8 addressed; item 6 verified already correct on `main` and pinned rather than changed |

### The eight items, one line each

| # | Item | Outcome |
|---|---|---|
| 1 | fog inverted | **Fixed.** Root-caused to fog colliding with the page chrome, not with terrain. Measured on frames: 1.16:1 → 2.08:1, and the direction reversed. |
| 2 | legend swatches indistinguishable | **Fixed.** Swatches now go through the map's own marker pass — real backing, real size class, real tint. |
| 3 | two typefaces | **Fixed.** The canvas draws in `get_theme_default_font()`, the same lookup this screen's Labels resolve. |
| 4 | callout text with no container | **Fixed.** Both columns get a real container. The judge's 40%-coverage prediction is corrected in §2: it cannot happen at fit today, for a reason that is incidental rather than structural. |
| 5 | no north, no scale, legend reads as keybinds | **Fixed.** North indicator, scale bar (2000 m at fit), and the legend in its own captioned panel. |
| 6 | no controller zoom binding | **Already correct on `main`.** RT/LT are bound; the judge read keyboard glyphs off a padless capture. Verified, pinned by a test, not changed. |
| 7 | danger labels lost in greyscale | **Fixed** in the shared function. Greyscale spread between brightest and dimmest label: 120 → 15 of 255. |
| 8 | marker silhouette contaminated by terrain | **Fixed** at the shared backing: a 72%-opacity tint became an opaque knock-back, on both screens. Visible in the isolated minimap pair. |

### Known limitations and what was deliberately not done

1. **W11 has not landed** (§0), so items 2 and 8 are fixed at the shared treatment they belong
   in but were not verified against a rendered alpha pin, and `test_alpha_pins.gd` /
   `smoke_alpha_pins.gd` could not be run because they do not exist on this base.
2. **No 40%-coverage stand.** The highest coverage rendered is 1.42%; reaching 40% of a
   2048 × 8192 m corridor needs a reveal an order of magnitude wider and each stand costs a
   ~45-minute world boot. §2 item 4 settles the question the stand would have asked,
   structurally rather than by picture.
3. **`minimap.gd` still draws its own text in `kenney_future.ttf`.** Item 3 is scoped to the map
   screen; the minimap is a HUD widget among different neighbours, and widening the typeface
   change to it is a separate call. Flagged, not taken.
4. **The player marker swallows the early-game map** at whole-Meadows fit (§4). Routed: the fix
   is a zoom-to-explored-region behaviour or a smaller halo, and the smaller halo reverses
   OP21-15's own blind-pass fix.
5. **The full ~28-minute suite was not run** (§3), and **CI could not be observed from this
   container** — no `gh`, and the GitHub API is not enabled for this session. The coordinator
   must confirm the run on this branch actually executed its code jobs.
6. **`docs/CURRENT_STATE.md` was not edited.** COMMON.md asks for findings to be recorded there;
   that file is a single shared status document and several lanes in this wave are running
   concurrently, so a rewrite of its map row from here would collide. The map row's update is
   this report, and the coordinator can fold it in when landing. Recorded rather than silently
   skipped.

**Final commit:** the tip of `ralph/N06-MAP-UI-0905` at the time this line was written —
`git log -1 origin/ralph/N06-MAP-UI-0905` names it. A report cannot contain its own hash; the
commit carrying this report's final state is the one immediately after `c075081f`.
