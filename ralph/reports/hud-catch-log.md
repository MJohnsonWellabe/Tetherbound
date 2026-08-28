# HUD and catching lane — log

Branch `ralph/HUD-CATCH`. Two items from the 2026-08-28 owner playtest
(`ralph/OWNER_PLAYTEST_2026-08-28.md`, branch `ralph/OWNER-PLAYTEST-0828`).
Owner-play evidence is CLAUDE.md precedence category 1.

---

## 1. "the hud on screen is way too big" — second report

### The measurement first

`tools/_measure_hud_footprint.gd` (new) walks the live HUD scene, collects
every visible Control that puts ink on screen — leaf widgets plus Panels and
PanelContainers, which fill a stylebox behind their children — and unions their
rects on a sample grid. Transients are reported separately, because the
complaint is about what is on screen while you walk around.

| | before | after |
|---|---|---|
| persistent HUD | **27.37%** of the canvas | **14.20%** |
| with the roster reveal up | 34.38% | 20.11% |

The five largest persistent widgets before, as a share of the screen:

| widget | rect | % screen |
|---|---|---|
| ExplorationLegend | 1700x112 | 9.18% |
| HotbarPanel | 676x232 | 7.56% |
| ObjectiveBlock panel | 420x170 | 3.44% |
| Minimap | 240x240 | 2.78% |
| VitalsCluster plate | 348x138 | 2.32% |

### The diagnosis

Every HUD size in this project was justified against a **render pixel** count
at 1280x800: "36 authored px x the Ally's 0.667 canvas_items scale = 24
physical px, the legibility floor." Both halves of that are wrong.

**There is no 0.667 scale.** `project.godot`'s own `[display]` comment states
the ROG Ally is 1920x1080 at 7 inches, and that is why this project authors at
1920x1080. Authored canvas / device resolution is 1.0. 1280x800 is the Steam
Deck's panel, and it was used for months as though it were the Ally's.

**It would not matter if it were.** `window/stretch/mode="canvas_items"` maps
the whole authored canvas onto the whole panel, so an authored pixel is a fixed
FRACTION OF THE PANEL at any render resolution. Rendering at 1280x800 makes a
glyph blurrier; it does not make it smaller. Verified rather than asserted:
`_measure_hud_footprint.gd` run at 1920x1080 and at 1280x800 returns
byte-identical authored rects (1700x112 legend, 240x240 minimap, 112x180
quick-bar slot) and the same 26% occupancy at both.

So every legibility pass since OP21 multiplied its target by 1/0.667 = 1.5x to
clear a floor that was already met, and the quantity it was protecting — can a
human eye resolve this at arm's length — is not a function of render
resolution at all. It is a function of **angular size**.

The consequence, at 450mm handheld viewing distance on a 155mm-wide panel
(1 authored px = 0.0807 mm):

| element | authored | subtends |
|---|---|---|
| legend button glyph | 66 px | **40.7 arcmin** |
| quick-bar item icon | 64 px | 39.5 arcmin |
| quick-bar binding badge | 36 px | 22.2 arcmin |
| every HUD micro-label ("Lv 1", "x12") | font 38 | 16.4 arcmin cap height |

For reference: a 20/20 eye resolves detail at 1 arcmin and recognises an
isolated letter at about 5; continuous reading is comfortable from about 16,
which is roughly where newspaper body text lands at reading distance. The HUD
was setting the string "Lv 1" at newspaper-body size.

### Resolving the tension rather than picking a side

"Too big" and "must stay legible on a 7-inch panel" are both owner
requirements, and the brief was right that a fix which drops text under the
legibility floor trades one complaint for another. It does not have to: the
floor was being **overshot by 1.5x**, not approached. Restating it in angular
terms lets the HUD get materially smaller while every element stays above a
floor that is now derived from panel geometry instead of from a resolution the
device never renders at.

`scripts/ui/hud_scale.gd` (new) is that model — panel geometry, a stated
450mm viewing distance, and three floors:

- `GLANCE_CAP_ARCMIN` 11.0 — labels, counts, badges: recognised, not read. -> font **26**
- `SENTENCE_CAP_ARCMIN` 13.5 — the objective line, the contextual prompt. -> font **32**
- `GLYPH_ARCMIN` 16.0 — a button badge with lettering baked into the art. -> **26 px**

The glyph floor is the one that is about rasterisation rather than the eye, so
it is **measured, not assumed**. `tools/_probe_glyph_ladder.gd` (new) renders
the real pad glyphs at 1:1 authored pixels across a ladder;
`shots/hud_scale/glyph_ladder_zoom.png` is that render at 4x nearest-neighbour.
The Kenney badges' two-letter art is mush at 20px, marginal at 22, cleanly
resolved at 24, comfortable at 26. Not 36.

`input_glyph.gd::icon()`'s own 36px default is **not** wrong and is untouched
(that file is `ralph/DPAD-COLLISION`'s anyway): it was measured against
`cancel`'s keyboard glyph, which bakes THREE letters ("ESC") into the same
badge and genuinely needs more. The defect was applying a three-letter glyph's
floor to every glyph on the HUD.

### The half the tests never had

Every check in `smoke_hud_handheld_legibility.gd` was a FLOOR. That is how the
HUD reached 27.4% with 40-arcmin glyphs on it: each legibility pass could only
push a number up and nothing could push back. A floor-only suite does not
encode a size requirement, it encodes a direction.

So the suite now also carries ceilings — `OVERSIZE_FACTOR` 1.6x on each floor,
and `MAX_HUD_OCCUPANCY` 20% measured off the live scene. That last one is the
owner's "way too big" as a build failure.

### What changed

`scripts/ui/hud_scale.gd` new; `playground_hud.gd`, `party_strip.gd` and
`scenes/ui/playground_hud.tscn` re-derived against it; the legibility suite
re-pointed at the new model with the overlap/containment checks untouched.

Two things fell out that are worth naming:

- The minimap did not shrink when `MINIMAP_SIZE` did, because `minimap.gd`
  carries its own 240x240 `custom_minimum_size` — `MINIMAP_SIZE` had only ever
  driven the widget's POSITION. Caught by the footprint tool still reporting
  240x240 after the constant was already 184.
- A first cut of the roster row to 304 (the naive 26/36 scaling of the width
  alongside the font) reopened the name-elision defect GF-B-006 had fixed:
  "Galew" where 420 had held "Galewi...". Most of a row is not text — rail,
  chip, HP bar, separations are fixed furniture — so scaling the row with the
  font takes far more than its share out of the name column. At 336 with the
  bar cut to 44, the roster now shows **"Galewisp" in full**, which the
  1.5x-inflated HUD never did. See `shots/hud_scale/roster_compare.png`.

### Evidence

- `shots/hud_scale/before.png`, `shots/hud_scale/after.png` — the HUD through
  the real render path at 1920x1080, opengl3 under xvfb.
- `shots/hud_scale/roster_compare.png` — the roster column, before over after.
- `shots/hud_scale/glyph_ladder.png`, `glyph_ladder_zoom.png` — the render the
  glyph floor is derived from.

### What I did not prove

- **How any of this feels in the hand.** [OWNER-ONLY]. I measured geometry and
  counted pixels; I did not hold the device.
- **The 450mm viewing distance is an assumption**, and it is the one assumption
  every arcminute figure above rests on. Held closer, the HUD could go smaller
  still; held further, these sizes are near the floor rather than above it. It
  is a named constant in `hud_scale.gd` so it can be re-argued by changing one
  number.
- **Whether the exploration legend needs to be permanent at all.** It is four
  button reminders and was the single largest widget on the HUD; it is now
  2.90% of the screen rather than 9.18%, but it is still always there. Retiring
  it once the player has demonstrably used those buttons would save that too.
  That is a design decision about how much teaching the HUD owes a returning
  player, not a scale fix, so it is flagged rather than taken.

---

## 2. "catching still sucks"

There was no evidence file to reconcile against — Gate F's X03 catching lab has
never run — so this starts from measurement rather than from a document.

### What "sucks" turns out to mean, specifically

**The number on the reticle is not the number the throw uses.**

`combat_manager.gd::catch_chance_now()` passed `offset = 0.0` unconditionally.
That is the DEAD-CENTRE case. `catching.json`'s `accuracy_bonus` spans
`centre_bonus` 1.45 to `edge_bonus` 0.80 — a **1.81x spread** that the config
itself calls *"the ONLY reason the aiming skill exists"*. So the ring showed:

| species | HP | reticle showed | an edge hit resolved at | gap |
|---|---|---|---|---|
| bramblebun | sliver | 73.1% | 40.3% | 32.8 pts |
| bramblebun | half | 42.8% | 23.6% | 19.2 pts |
| terrapup | half | 21.4% | 11.8% | 9.6 pts |

And it drew that ring, with that number, at the creature's screen position
**whether or not the player was lined up at all**. There was no visual
difference between an assist-eligible line-up, where the number is true, and a
reticle pointing into the grass beside the target, where it is fiction.

**This is not an edge case — in a real fight it was every throw.**
`smoke_catching.gd` drives an actual fight, and its `catch launch:` log across
four commits reads:

```
commit eligible=false reticle=0.415/0.312 first_hit=AllyCreature       los=false reason=reticle_outside_body
commit eligible=false reticle=0.517/0.312 first_hit=Wild_bramblebun_0_1 los=true  reason=reticle_outside_body
commit eligible=false reticle=0.305/0.312 first_hit=AllyCreature       los=false reason=line_of_sight_blocked
commit eligible=false reticle=0.442/0.312 first_hit=Wild_bramblebun_0_1 los=true  reason=reticle_outside_body
strike  offset=0.312          <- exactly body_radius: the full edge penalty
strike  offset=0.312
```

**Zero of four throws earned the assist.** Both throws that landed struck at
offset 0.312, which is exactly `body_radius` — the maximum penalty
`accuracy_bonus()` can apply. So the advertised number was wrong on 100% of the
throws in that run, and wrong by the whole 1.81x factor. Note also that one of
the four was blocked by the player's **own creature** standing in the line of
sight.

`catch_math.gd`'s own header states this project's rule: the outcome is decided
once, and *"dramatising a lie is exactly what makes catch animations feel
cheap."* Advertising odds the roll will not use is the same lie one step
earlier, before the orb has left the hand.

**OF19 made it worse without meaning to.** Widening the orb's collision radius
0.42 -> 0.60 to answer "too hard to know where the ball is going to go" is pure
forgiveness on the miss/no-miss line — which means it *grew* the set of throws
that land while being scored at the edge multiplier. More landed throws, a
larger share of them scored far below the advertised number.

### The bigger one, found while proving the first: aiming did nothing at all

Fixing the readout meant checking what the throw actually resolved at — and the
throw was not using the aim either.

`orb.gd::_check_target()` fires when the orb's centre comes within
`body_radius + orb_radius`. For a Bramblebun that is 0.312 + 0.60 = **0.912 m**,
because the orb is a deliberately forgiving 0.60 m sphere. The strike offset
handed to `accuracy_bonus()` was the distance **at that same sample**, clamped
to `body_radius` (0.312). Two things then guaranteed the clamp always saturated:

1. Only the orb's **endpoint** was sampled, and at `speed` 17 on a 60 Hz tick it
   moves 0.283 m per step — so the first sample inside 0.912 m was never inside
   0.312 m.
2. Even measuring the whole swept step, the step that *triggers* the hit enters
   the forgiveness sphere and stops. It never reaches the body.

Simulated across the aim range, a dead-centre throw and one 0.30 m wide both
reported **exactly 0.312** and both scored at `edge_bonus` 0.80:

```
aim error       true distance reported offset  scored as
0.00                    0.826          0.312       0.80x EDGE
0.10                    0.832          0.312       0.80x EDGE
0.30                    0.878          0.312       0.80x EDGE
```

Confirmed in real fights, not just in simulation: **every** `catch launch:
strike` line in this repo's own logs reads `offset=0.312` — including throws
where the launch assist led the orb to the body centre. An `assist=true` throw
aimed dead at the creature logged `closest=0.821`.

So `centre_bonus` (1.45) was **unreachable**, `accuracy_bonus()` was a constant,
and **aiming changed the catch chance by exactly nothing** — while
`catching.json` calls that term *"the ONLY reason the aiming skill exists"*,
`test_catch_math.gd` asserts the two bonuses differ, and the HUD drew a reticle,
a launch assist, a preview arc and a percentage all promising the player their
placement mattered.

That is what "catching still sucks" is. The skill was decoration.

The old code's own comment shows it anticipated the *opposite* failure —
*"Widening `radius` to forgive the input must not silently make every throw
count as dead centre"* — and guarded against it. The guard was right to exist
and it overshot: it stopped every throw counting as dead centre by making every
throw count as dead edge. OF19's radius widening (0.42 -> 0.60) pushed the
trigger boundary further out and made it worse.

**The fix** separates two questions the one measurement was conflating:

- **Did it hit** is about the collision sphere, and is now answered over the
  segment actually travelled — which also fixes tunnelling, where a fast orb
  could step over a small creature between two samples.
- **How well was it aimed** is about the trajectory, and is answered by the
  closest approach of the orb's forward heading to the body centre.

Live, after the fix: an assisted throw scores `closest=0.158` (was saturated at
0.312); an unassisted one scores 0.357 and is still correctly penalised to the
edge.

**This does change effective difficulty, and the owner should know by how
much.** A well-aimed throw gains, a badly-aimed one does not:

| species | HP | before (always edge) | well-aimed now | badly-aimed now |
|---|---|---|---|---|
| bramblebun | sliver | 40.3% | **56.5%** | 40.3% |
| bramblebun | half | 23.6% | **33.1%** | 23.6% |
| terrapup | half | 11.8% | **16.5%** | 11.8% |
| terrapup | full | 2.4% | **3.4%** | 2.4% |

A uniform **1.40x** for a throw placed as well as the launch assist places one;
the ceiling is 1.81x for a dead-centre trajectory. If the owner wants the old
effective difficulty back, `centre_bonus` is the single knob — but the old
numbers were the *floor* of the design applied to every throw, not a chosen
difficulty.

### What I fixed

The readout and the placement measurement. Nothing in `catching.json` changed.

- `catch_chance_now()` now uses the aim's real offset. When the launch assist
  is eligible the orb is genuinely led to the body centre, so the dead-centre
  number *is* honest and nothing changes; when it is not, the number is the one
  the unassisted throw would actually resolve at. The percentage now **moves as
  you line up**, which is the first time the accuracy bonus has been visible at
  all.
- New `catch_aim_is_locked()`, and the capture reticle draws an unlocked aim as
  a distinct state — ring standing off wider, quieted, and the readout replaced
  by `-- / NOT ON TARGET` rather than a number. A percentage on screen is read
  as an answer, and off the body there is no honest answer to give: the throw
  does not have a low catch chance, it has a miss chance the widget cannot
  compute.
- The contract animation — the ring collapsing onto the resting orb — now shows
  the chance the roll **actually used** (`last_catch_chance()`), not the one the
  aim last advertised. That closes the loop: you see whether you were on target,
  then you see what the throw was worth, then you see the shakes.
- `smoke_catching.gd` gains the regression guard.

Together these answer the specific question a player could not previously ask:
**was I unlucky, or was I sloppy?** A skill mechanic you cannot learn from is a
slot machine, and that is what the accuracy system was.

### What I did NOT fix, and why

These are real, measured, and are the owner's call — they are about how hard
catching should be, which is a design decision, not a defect.

**1. The odds themselves.** At full health the multiplier is 0.10, so a
terrapup reads 4.3% and a tuskroot 4.1%. That is `GAME_DESIGN.md` §15 working
as specified ("powerful/full-health creatures should be extremely difficult").

**2. The wall-clock cost of a failure.** A failed attempt costs **7.0–8.6
seconds**, of which **4.9–6.5 s is non-interactive** — wind-up 0.18, flight
~0.4, resolve 3.0–4.7, breakout pop 0.35, re-throw cooldown 0.9. Expected time
to a catch, animation only:

| target | chance | attempts | ~time to catch |
|---|---|---|---|
| terrapup, full HP | 4.3% | 23.0 | **164 s** |
| terrapup, half HP | 21.4% | 4.7 | 37 s |
| bramblebun, sliver | 73.1% | 1.4 | 13 s |

**3. The shake count carries almost no information at the odds players actually
play at.** It is designed as the "how close were you" channel, but:

- terrapup at full HP (4.3%): **95% of failures shake once** — the channel says
  "hopeless" nearly every time.
- bramblebun at a sliver (73.1%): **91% of failures shake three times** — and
  `shakes_on_success` is *also* 3, so at high odds the failure animation is
  indistinguishable in length from the success animation right up to the
  verdict.

The channel only carries signal in the middle band. Making
`max_shakes_on_failure` differ from `shakes_on_success` is a one-line config
change, but it is a change to the drama of the sequence and belongs to whoever
owns that.

**4. The lock target is small and the player's own creature blocks it.**
`launch_assist_reticle_fraction` is 1.0 against a `body_radius` of 0.312 m at a
throwing range of ~7.5 m — about **2.4 degrees** of arc, with
`aim.sensitivity_scale` at 0.55. That is the "aiming is fiddly" half, and
widening it is a forgiveness knob, i.e. a difficulty decision. Separately, the
ally creature intercepting the line of sight (1 of 4 throws in the logged run)
may be worth treating as a bug rather than a tuning value — the trainer is
aiming past their own companion — but which of the two it is depends on whether
"reposition to get a clean line" is meant to be part of the skill.

### Evidence

Rendered through the real path (`xvfb-run`, `opengl3`, never `--headless` with
a real driver):

- `shots/catch/01-aiming-full-health.png` — the new **NOT ON TARGET** state in a
  live fight. The ring marks the wild creature; the caption says the screen-centre
  ray is not on it. Before this pass that same frame showed a confident
  percentage.
- `shots/catch/07-aiming-weakened.png` — the locked state, ring and number.
  (The 100% is `capture_catch_sequence.gd` pinning `chance.min` to 0.999 so the
  dice reliably produce a catch for the frame; the live cap is `chance.max`
  0.95.)
- `shots/catch_aim/reticle_states.png` — the three states side by side: locked
  dead-centre, locked but clipping, and not on target.
- `tests/test_catch_math.gd` — six new assertions pinning the placement
  arithmetic; `tests/smoke_catching.gd` — the advertised-chance guard, driven
  through a real fight.

### Two things noticed in the frames, for whoever owns them

Neither is this lane's to change, and neither is asserted as a defect.

- **The wild creature is hard to see in the grass.** In
  `01-aiming-full-health.png` the target is most of the way hidden by the grass
  field at throwing range. That is the field the owner has called *awesome* and
  said must not change, and `scripts/world/grass_field.gd` belongs to another
  lane — noting it only because "I can't see what I'm aiming at" would be a
  plausible independent contributor to "catching sucks", and it is visible in
  this lane's own frames.
- **The unlocked caption is deliberately quiet** (`TEXT_MUTED` over a bright
  outdoor scene). The reasoning is that the loud state — teal or amber ring, big
  number — is the GOOD state and its absence is the signal, rather than a red
  warning flashing through every aim adjustment. If the owner reads it as too
  easy to miss, it is one colour constant.

### A controller-first defect on the catching path, found in this lane's frames

`shots/hud_scale/after.png` is captured with the device pinned to GAMEPAD. Every
glyph on it is a pad glyph — Y, RB, LB, B. And the objective hint card in the
centre of it reads:

> *"Wear it down in the fight first, then pick an orb on the hotbar and press
> **F**."*

That is the hint for **the first catch in the game**, telling a ROG Ally player
to press a key their device does not have.

The content is not at fault. `data/progression/objectives.json` writes the token
properly:

```
"how": "... pick an orb on the hotbar and press {combat_throw}."
```

The binding is. In `project.godot`, `combat_throw` has exactly one event — the
keyboard `F` — and **no joypad event at all**:

```
combat_throw={ "deadzone": 0.5, "events": [Object(InputEventKey, ... 70 ...)] }
```

`throw_aim.gd` says why, and says it was deliberate: *"CONTROLLER-MAP: interact
(X) is the pad's throw button now — `combat_throw` kept its keyboard F and lost
its pad binding when the orb became a hotbar item."* The code accepts
`combat_throw`, `interact` or `combat_quick`, so a pad player really does throw
with X. Nothing resolving `{combat_throw}` can know that, so it correctly falls
back to naming the keyboard key.

**Not fixed here, on purpose.** The fix is a one-token decision that lands
across three lanes' files — the objective content, `input_glyph.gd`'s resolver
(`ralph/DPAD-COLLISION` owns it), and the input map — and picking `{interact}`
instead just inverts the problem, because on a keyboard `interact` is E while the
throw is F. What it actually needs is a device-aware alias: the token should
name whichever action is bound for the device in hand. Flagged rather than
taken, because CLAUDE.md makes "Controller first" a hard rule and this is the
tutorial line for the mechanic the owner says still sucks.

### A red test on `main`, fixed here

`smoke_controller_catching.gd` fails on clean `origin/main` with *"intentional
physical throw never resolved"*. Verified by checking out `origin/main`'s tree
and running it. The cause is a stale assertion, not a product bug: the test
counted a miss by matching the string `"the orb went wide"`, and `orb.gd`
stopped emitting that when miss messages became per-cause — the exact change
`throw_aim.gd`'s own `orb_missed` signal documents (*"Carries the sentence to
show the player, because 'the orb went wide' was printed for every miss
regardless of what happened"*). It now counts the signal that means miss.
Passing here. Worth the coordinator knowing it was red on `main` and for how
long.

### What I did not prove

- **How catching feels.** [OWNER-ONLY]. I measured the arithmetic, the wiring
  and the wall clock; I did not play it on the device.
- **That the fix improves the feel.** It makes the game stop lying, which is a
  precondition for the skill being learnable, not a demonstration that the skill
  is now satisfying.
- **The four items above are diagnoses, not proposals.** Each has a number
  attached so the owner can decide against evidence rather than against
  adjectives — but if the answer is "catching should be probability-based and
  the wait is the drama", then items 2 and 3 are working as intended and only
  the readout was ever broken.


---

## Verification run

All five tests the brief named as strict-on-purpose, plus the full unit suite,
on the final tree:

| check | result |
|---|---|
| `tests/run_tests.gd` (whole unit suite) | **1478 tests, 0 failed** |
| `smoke_hud_handheld_legibility.gd` | PASS |
| `smoke_prompt_hotbar_dock.gd` | OK |
| `test_hud_widgets.gd` | 28 tests, 0 failed |
| `smoke_exploration_legend.gd` | PASS |
| `smoke_hud_no_sixth_slot.gd` | PASS |
| `smoke_combat_hud_left_column.gd` | PASS (roster fits 308 against a deepest child of 308) |
| `smoke_catching.gd` | OK, with the new advertised-chance guard |
| `smoke_controller_catching.gd` | OK — **was failing on clean `origin/main`** |

Nothing in `smoke_hud_handheld_legibility.gd` was relaxed. Every removed line is
a render-pixel size computation replaced by its angular equivalent; no overlap,
containment or structural check was touched, and the file gained three checks it
never had (two size ceilings and a live-scene occupancy ceiling). The one
behavioural change is the legend/prompt overlap check now requiring the prompt to
be visible, because a `VBoxContainer` does not lay out hidden children — and
`smoke_prompt_hotbar_dock.gd` covers the visible case in four states with real
prompt text.

## Summary of the two items

**HUD scale.** The cause was a content scale the device does not have, applied
as a 1.5x multiplier to every size on the HUD for months. Persistent occupancy
**27.37% -> 14.75%** of the canvas. The floor it was protecting is now derived
from panel geometry in `scripts/ui/hud_scale.gd`, every element still clears it,
and the suite gained the ceilings that would have caught this the first time.

**Catching.** Two defects, both about the game telling the player the truth. The
reticle advertised a dead-centre chance regardless of aim — and the throw did not
use the aim either, because the strike offset saturated its clamp on every
throw, making `centre_bonus` unreachable and the entire aiming skill decorative.
Both fixed; the difficulty consequence is measured and stated. The odds curve,
the wall-clock cost of a failure, the shake channel and the lock-target size are
diagnosed with numbers and left for the owner, because they are all answers to
"how hard should catching be" rather than defects.

---

# Owner correction, 2026-08-28 §2a / §2b

The owner localised "catching sucks" and **corrected this lane's theory**. My
press-F finding is a real defect and a "Controller first" violation, but it is
not why catching feels bad. The cause is **aiming**, in three parts, plus
creatures that vanish in the grass.

## §2b first, because it is measurable and it gates §2a

You cannot aim at what you cannot see, so this got measured before anything was
changed.

**The field.** `data/config/grass_field.json`: `height_near` 0.40,
`height_far` 0.62, `height_jitter` 0.38 — so a tuft stands **0.25–0.86 m**.

**The roster against it.** Two creatures are shorter than their own tall grass:

| species | height | vs 0.86 m tall grass |
|---|---|---|
| pipwing | 0.60 m | **shorter** |
| bramblebun | 0.78 m | **shorter** |
| mudsnout | 0.95 m | clears |
| everything else | ≥ 1.05 m | clears |

The owner guessed bramblebun was "both". **It is**, and here is the frame
arithmetic from `shots/catch/01-aiming-full-health.png` — a real bramblebun at
throwing range in real grass:

- Inside the creature's own bounding box, only **35%** of the pixels are
  creature. The other **65% is grass in front of it.**
- Whole-box luminance against the surrounding field: **1.02 : 1**. This repo's
  own `vegetation.json` quotes a blind critic calling **1.00:1 "invisible"**.
- Where the creature *is* visible: hue separation is actually fine
  (**47°** — tan 39° against grass 85°), but luminance contrast is
  **1.15 : 1**. So the problem is **value, not hue**. Hue discrimination falls
  off with angular size far faster than value does, which is why 47° of hue is
  not rescuing it on a 7-inch panel at throwing range.

### What I changed on the creature side (the grass is untouched)

**Size, measured rather than eyeballed.** `bramblebun` 0.78 → **0.96 m**,
`pipwing` 0.60 → **0.76 m**. 0.96 clears the tallest tuft by 0.10 m. Both are
deliberately modest — the smallest step that puts the silhouette above the
field, not a size that makes a rabbit read as a mid-tier creature.

This moves gameplay as well as art, and that is correct rather than a side
effect: `creature_body.gd`'s own header says `height`/`radius` drive the
capsule, the hit cone's reach and — through `body_radius()` — the catch
accuracy bonus, and that scaling the art alone is the invisible discrepancy
`PW2` forbids. A bigger creature is genuinely easier to hit and the odds say so.

### What I did NOT change, and the specific reason

**The value/material separation — the half the measurement says matters most.**

`creature_body.gd` carries an explicit warning against exactly the fix I was
about to make: these creature assets ship `emission_enabled = true` with the
same painted texture as both `albedo_texture` and `emission_texture` at a full
white multiplier — a self-lit painted look. Emission is additive and reads
independently of lighting, so *"an albedo-only tint here would compile, pass a
material-only unit test, and still be invisible in a render."*

A rim/fresnel term is a **lighting response**, so it is at risk of being swamped
the same way. Shipping one without a render to prove it lands would be exactly
the failure that file warns about. That needs a render iteration, which is the
next thing to do here — not a guess dressed as a fix.

## §2a — the aiming, all three requirements

### 1. "The cone of visibility of where the ball is going needs to be way more obvious"

Four compounding causes, all in `throw_preview.gd`:

1. The arc was drawn with `PRIMITIVE_LINES` — **one pixel wide**. At the 1920
   authored canvas that is 0.05% of screen width, over a field measured at 65%
   blade coverage.
2. It faded to `FADE_FAR_ALPHA` **0.25** along its length, so it was at its
   *least* visible **at the landing point** — the one part being read.
3. `no_depth_test = false`, so grass blades drew over it. The same blades hiding
   the creature were hiding the aim.
4. The landing marker was a 0.34 m ring lying **flat** in grass standing up to
   0.86 m — the indicator was inside the thing obscuring it.

Rebuilt as a **camera-facing ribbon** with real world-space width that widens
from 0.045 m at the hand to 0.16 m at the landing point (which is what makes it
read as a *cone* rather than a wire, and is honest — the far end is where the
real spread is), a **dark casing** under it so it separates from both sunlit
tips (luminance 0.46) and shadowed bases (0.24), an alpha ramp **inverted** to
be strongest at the landing end, drawn **over** the grass, and a landing marker
that **stands up** out of the field: a 1.15 m stalk (clearing the 0.86 m tallest
tuft) with a bead on top, plus a bigger ring.

The ribbon is camera-facing so it keeps its apparent width edge-on — which is
the throw the player makes most often.

### 2. "When you go into throwing, it needs to aim you onto the creature"

`try_begin_aim()` now **acquires**. The rig's yaw and pitch snap to the target's
centre of mass from the eye the aim camera is about to use.

**Which target, since the directive asked me to say:** the one the fight is
already about. `arm()` is handed exactly one `_target` by `combat_manager.gd`
when the fight opens, and catching is only available inside a fight — so there
is no nearest-creature search to get wrong and **no ambiguity when several
creatures are in range**. The encounter already chose. That is deliberately
narrower than a free-roam lock-on would need, and it is the right rule here: it
can never acquire a creature the player is not fighting.

**Snapped, not glided**, because the camera is already cutting to a different
profile on that frame and a glide on top of a cut reads as drift.

### 3. "Aim assist needs to be stronger"

Two separate mechanisms, both widened:

- **Hard launch assist**: `launch_assist_reticle_fraction` 1.0 → **1.7**. At 1.0
  the player had to put the screen-centre ray inside the creature's own collider
  — 0.312 m at ~7.5 m, about **2.4 degrees of arc**, with the stick already
  slowed to 0.55. In a real fight the launch log shows four consecutive commits
  missing that window at offsets 0.415, 0.517, 0.305, 0.442. **Three of the four
  are inside 1.7×.**
- **Soft aim magnet**: the pull band in `_aim_direction()` widened from
  (0.5, 1.0) body-widths to **(1.0, 2.5)** — full pull out to a whole body-width,
  tapering to nothing at two and a half.

**On the caution about it playing itself.** The assist window is deliberately
*not* pushed further, and the reason is structural rather than taste: that same
fraction is what `catch_aim_is_locked()` reports to the HUD, so widening it past
the creature's visible silhouette would start telling the player they are on
target when they can plainly see they are not — which is the defect this lane
spent the morning fixing one layer up. The soft magnet stays a **smoothstep**,
never a snap, for the reason the existing code already records: the binary
version made the aim jump as the reticle swept past, the "grabbed the stick"
feel from an earlier playtest. The result should be *easier to aim*, not
*impossible to miss*: a throw pointed away from the creature still misses, and
`accuracy_bonus` still pays more for a centred trajectory than a clipped one now
that it actually functions.

## Render verdict — what the frames actually show

Two render iterations, because the first was wrong and the frames said so.

**Iteration 1 was a regression.** The ribbon's width was specified in metres, and
the near end of the arc leaves the hand less than a metre from the aim camera —
so a 0.09 m band subtended about ten degrees and drew a teal **slab** across the
middle of the screen, over the player's own creature. Fixed by making the width
a constant **angle** from the eye (~1.2° across), clamped at both ends, flared
2.4× toward the landing point, with the first 1.6 m from the eye not drawn.

**Iteration 1 also exposed a contradiction I had introduced.** The cone visibly
ended *on* the Bramblebun under a caption reading **NOT ON TARGET** — because
the arc asks "does the predicted flight reach the body" while the reticle asked
"is the screen-centre ray inside k × body_radius". The player reads the picture,
so the words now follow it: `catch_aim_is_locked()` reports on-target when the
assist is eligible **or** the previewed flight lands, and such a throw is scored
on where that flight passes rather than on a reticle offset it will not resolve
at. The assist gate itself is unchanged.

**Iteration 2** (`shots/catch/01-aiming-full-health.png`) shows all three §2a
requirements landing: the cone is a clear band instead of a one-pixel wire, the
camera has acquired the creature (it is centred, where the pre-change frame had
it off to the side and unlocked), and the reticle reads CAPTURE CHANCE at an aim
that previously read NOT ON TARGET. *(The 0% is `capture_catch_sequence.gd`
pinning `chance.max` to 0.001 to force a breakout for that frame, not a product
value.)*

### What the frames do NOT prove

**The creature-height change is not verified on screen.** I measured the after
frame the same way as the before frame and got 24% creature / 76% grass against
the before frame's 35% / 65% — i.e. apparently *worse*. **That comparison is not
valid and I am not reporting it as a result either way:** target acquisition
changed the camera, so the two frames have different angle, distance and
framing, and a hand-placed measurement box across two different framings
measures the box as much as the creature.

The height change rests on geometry that is solid on its own terms — the field
stands 0.25–0.86 m and Bramblebun moved from 0.78 m (inside that range) to
0.96 m (above it) — but **the on-screen gain is unproven**. The controlled test
is the next step: the same creature, the same camera pose, rendered at 0.78 and
at 0.96, which is the only way to separate the height change from the camera
change. That is the honest state of it.

### One cost worth naming

The cone draws over the world (`no_depth_test`), which is what stops grass
swallowing it — and it therefore also draws over **creatures**. At ~1.2° wide
that is a stripe across the player's own creature rather than the slab iteration
1 produced, and it is visible in the frame. The alternative is the original
defect, since the grass is frozen by owner directive. Flagging it as a
deliberate trade rather than an oversight.
