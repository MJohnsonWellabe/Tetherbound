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
