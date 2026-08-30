# T5-FEEL handover — 2026-08-30

Lane: `ralph/T5-FEEL`, branched from `origin/main` at `1d7fc8e7`.

Two owner-playtest items, both from `ralph/OWNER_PLAYTEST_2026-08-30.md`, which
under `CLAUDE.md`'s precedence rules outranks every other document in this repo
for what it covers:

| Item | Owner's words | State |
|---|---|---|
| **OP-0830-3** | *"all items in the grass like tms, potions, orbs whatever should glow so they're visible."* | **Landed.** One shared treatment, six pickup paths, verified on rendered frames with grass confirmed present. |
| **OP-0830-5** | *"catching is way too hard."* | **Diagnosed and fixed.** Root cause was measured, not guessed; before/after success rates below. |

---

## OP-0830-5 — catching. The measurement first.

The lane order was explicit that this had to be diagnosed rather than tuned, so
nothing in `catching.json`'s odds was touched until there was a number.

### The instrument

`tools/_probe_catch_rate.gd` (new) drives the **real** loop — real input actions,
real aim camera, real orb, real `catch_math.resolve()` — at a representative
early-game encounter, and records where each throw actually died: refused,
physically missed, landed-and-lost, or caught. It re-acquires a fresh encounter
after each catch or faint (trimming the party back to the starter, since the
five-creature cap is a hard rule and would otherwise start refusing throws), so
the sample is many throws rather than many throws at one lucky creature.

It does **not** aim the way `tests/smoke_catching.gd` does. That test sets the
camera *rig's* yaw at the creature, and its own docstring records that this does
not put the reticle on the body — the aim profile carries a 1.45 m
`shoulder_offset`. Measuring through that would have measured the harness. The
probe closes the loop on the camera's actual forward instead, which converges the
screen-centre ray onto the body the way a player does with a thumbstick, and
`--jitter=<deg>` then adds a fixed angular error so the report brackets "a player
who lined it up" against "a player who nearly lined it up".

**Encounter:** `bramblebun`, the practice cluster's own species, `catch_rate`
**0.60** — the most catchable creature in the Meadows. That is deliberate: if the
easiest early catch is a chore, OP-0830-5 is not about rare species.

### BEFORE — measured on `main` at `1d7fc8e7`

| Tier | Real throws | Orb landed | Caught | **Catches per throw** |
|---|---|---|---|---|
| 50% health, aim converged on the body | 17 | 16 | 3 | **17.6%** |
| 50% health, 2.5° aim error | 16 | 14 | 4 | **25.0%** |
| Full health, 2.5° aim error | 18 | 17 | 2 | **11.1%** |

### What the numbers ruled out

Four of the five candidate causes the order named are **not** the problem, and
the data says so:

- **The orb's flight and collision are fine.** 47 of 51 real throws (92%)
  physically reached the body. Both recorded misses were sub-decimetre grazes
  (`closest=0.93 needed=0.93`), not wild throws.
- **The timing window is fine.** No attempt failed for the wind-up, the
  cooldown or the resolution.
- **The aim/throw feel is broadly fine.** The launch assist was eligible on 47
  of 51 throws (92%), and `predict_launch_point` committed and led the orb on
  every one of them.
- **The HP precondition is doing what it was designed to do.** Full health is
  brutal (11%) and `GAME_DESIGN.md` §15 asks for exactly that. Untouched.

### The actual cause

`catch_math.accuracy_bonus()` divided the strike's offset by **`body_radius`**,
and `orb.gd` clamped the reported offset at the same number before emitting it.
A Bramblebun's `body_radius` is **0.325 m**. Across the 47 landed throws:

| | |
|---|---|
| Median real placement | **0.375 m** — already off the end of the scale |
| Throws saturating the clamp | **36 / 47 = 77%** |
| Mean accuracy multiplier | **0.845** |
| `centre_bonus` the config advertises | **1.45** |

So the term `catching.json` itself calls *"the ONLY reason the aiming skill
exists"* was a near-constant, stuck within 6% of its worst possible value, on
throws that were assisted, on target, and aimed at the predicted body centre.
Every landed throw silently lost about 40% of the odds the HUD was showing it —
the reticle advertised 0.428 while the resolution rolled at 0.236.

The residual 0.375 m is **not player error**. It is the target moving during the
orb's flight; the launch prediction leads it but cannot cancel it. No amount of
aiming removes it, which is why the scale was unreachable rather than merely
demanding.

This is the same 1.81× discrepancy `tests/smoke_catching.gd`'s own comments
describe. A previous lane fixed *where* the offset is measured
(`closest_approach_ahead`, so a perfect trajectory reports 0 rather than a
graze). It did not fix *what it is measured against*, so in live play against a
moving creature the clamp went straight back to saturating.

### The fix

**Placement is now judged over the envelope that defines a hit** —
`body_radius + orb radius`, which is exactly the distance
`orb.gd::_check_target()` already tests against — rather than over the creature's
own collider.

Nothing moved at either end. A dead-centre throw is worth `centre_bonus` 1.45
exactly as before; a throw at the very edge of the collision sphere is worth
`edge_bonus` 0.80 exactly as before. `tests/test_catch_math.gd::test_the_ceiling_did_not_move`
pins both. What changed is that everything in between now grades, which is what
the term was written to do. **No species rate, HP factor, orb multiplier or
clamp bound was raised.**

Three smaller defects found in the same measurement and fixed with it:

1. **Your own creature blocked the assist.** `throw_aim.gd`'s eligibility
   raycast treated the player's creature as an occluder and reported
   `line_of_sight_blocked` — while `_release()` hands the orb an ignore list
   containing that same creature, so the orb flies straight through it. The ray
   and the orb now agree about what is solid. This does not widen the assist: a
   reticle genuinely off the body is still ineligible. It is a real geometry,
   not a corner case — combat is piloted, so your creature is *supposed* to be
   in the opponent's face, which is exactly where it occluded it.
2. **The HUD clamped its advertised offset at `body_radius` too**
   (`combat_manager.gd::catch_aim_offset`), so the reticle reported the worst
   possible placement for any aim more than 0.325 m off a small creature's
   centre. Clamped at the placement scale now, so the number the player reads
   and the number the throw resolves at are on the same ruler.
3. **`"so close — 0.0m wide"`.** A miss by less than the message could express
   printed a zero and read as a bug. It now says so in words.

### AFTER

Same probe, same species, same stands, same seeds.

| Tier | Real throws | Orb landed | Caught | **Catches per throw** |
|---|---|---|---|---|
| 50% health, aim converged on the body | 14 | 12 | 6 | **42.9%** (was 17.6%) |
| 50% health, 2.5° aim error | 15 | 15 | 5 | **33.3%** (was 25.0%) |
| Full health, 2.5° aim error | 19 | 14 | 1 | **5.3%** (was 11.1%) |

**Pooled at 50% health — the tier a player actually throws from — 21.2% → 37.9%
catches per throw, a 1.79× improvement.** That number is worth a second look:
the discrepancy the clamp was creating was 1.81× (0.428 advertised against 0.236
resolved). Recovering almost exactly that factor is the strongest evidence that
the diagnosis was right — the fix did not *add* odds, it stopped throwing away
the odds the HUD had been promising all along.

**Full health did not meaningfully move, and should not have.** 2/18 before and
1/19 after are both samples of a ~7% event; they are statistically
indistinguishable, and `GAME_DESIGN.md` §15 asks for full-health throws to be
extremely difficult. Nothing in this change was aimed at them.

### The same result without the dice

Per-tier samples of 14–19 throws are small, so the sample rates above carry real
noise. The placement data does not, and it says the same thing far more tightly.
The orb's own `catch launch: placement` logging, across every run:

| | BEFORE | AFTER |
|---|---|---|
| Landed throws measured | 47 | 29 |
| Median real placement | 0.375 m | 0.357 m |
| **Throws saturating the accuracy clamp** | **36/47 = 77%** | **0/29 = 0%** |
| Mean accuracy multiplier | 0.845 | 1.195 |
| Expected chance per landed throw, bramblebun at 50% | 0.249 | 0.353 |

The median placement barely moved (0.375 → 0.357), which is exactly right: the
fix does not change how the orb flies, only how a throw that already landed is
scored. What changed is that no throw is pinned at the floor any more.

---

## OP-0830-3 — nothing in the grass glows

### What was actually there

Five separate pickup props, each with its own idea of how to be noticed, which
is why the answer to "does it glow" depended on which object you were standing
in front of:

| Path | What it had |
|---|---|
| `key_pickup.gd` | four blind rounds of shape, scale, metallic and emission work — each round still judged "an anonymous yellow speck" at range |
| `tm_pickup.gd` | a plinth, a slow spin and an `OmniLight3D` |
| `item_cache_pickup.gd` | a different `OmniLight3D` |
| `harvest_node.gd` | nothing |
| `felled_resource.gd` | nothing |
| `death_satchel.gd` | nothing |

The key's four rounds are the tell. Every one of them tried to make an 18 cm
object legible in a meadow *using the object itself*, and every one was judged to
have failed.

### The treatment

One shared system, registered from all six paths:

- `scripts/world/pickup_glow.gd` — the field and the register/unregister API
- `shaders/pickup_glow.gdshader` — the draw
- `data/config/pickup_glow.json` — every number, with `enabled: false` as the
  whole revert
- `tests/test_pickup_glow.gd` — the regressions

Adding a seventh pickup path is one call: `PICKUP_GLOW.attach(self, colour)`.

### The shape, and the two owner directives that produced it

The first version put a soft mote **1.15 m above** each pickup, clear of the
grass canopy, on the reasoning that blades are opaque geometry and no amount of
emission gets you through one. The reasoning about grass is correct. The answer
was not, and the owner said so on sight:

> **"glow on the actual item, not floating in the air above it"**

A light hanging in the air over an object is a waypoint marker. It is precisely
the loot-beam register this treatment was supposed to avoid, and it does not tell
the player *what* is there — only roughly where.

So the halo is centred on the **prop's own measured body**
(`pickup_glow.gd::prop_glow_height`): a 20 cm TM orb glows through its middle, a
felled log glows through its trunk. Grass is beaten by **radius** instead of
altitude — a halo centred at 0.28 m with a 0.70 m radius still reaches well above
the 0.86 m canopy `grass_field.json`'s own numbers produce, but it reaches *up out
of the object* rather than hovering over it.

The second directive shaped the draw:

> **"don't make it take over the items actual geometry or design. just add the
> glow to them"**

A camera-facing quad centred on a small prop paints straight over it, so the
player sees a bright disc where the object used to be — the item stops being
visible at exactly the moment it is meant to be noticed. The halo is therefore
pushed **behind** the prop along the view axis, by half that prop's own crown
(per-instance, through MultiMesh custom data). The item is opaque and writes
depth, so it occludes the middle of its own glow and only the halo escapes around
its silhouette. **The item is drawn whole, with light coming out from behind it.**
Nothing about any pickup's mesh, material, scale or animation was changed.

### The grass coupling, kept mechanical

`tests/test_pickup_glow.gd` asserts the glow's **reach** (centre + radius) against
`grass_field.json`'s own blade numbers, and separately forbids the centre from
rising above the canopy. So if the ground lane raises blade height or jitter, the
test fails and names the right knob — `mote.radius`, explicitly *not*
`mote.height`, because raising the height is how the rejected version worked.

### Two bugs that were quietly falsifying the evidence

Both were found by rendering, and both are worth recording because each one made
a frame lie:

1. **`pickup_glow.json` was malformed** (a missing comma), so `config()` fell
   through to `{}` and every lookup returned a **code default**. The world
   rendered the glow at pre-tuning size and brightness, the AFTER capture came
   out identical to BEFORE, and the obvious reading — "the shader is not
   drawing" — was wrong. `config()` now `push_error`s with the line number
   rather than silently running on defaults.
2. **`QuadMesh.size` defaults to 1×1**, putting corners at ±0.5, so every
   authored `radius` rendered at **half** the size the config said. That is most
   of why an early tuning round kept concluding "too faint" and reaching for
   `strength`. The quad is 2×2 now and a radius is a radius.

`tools/_probe_pickup_glow_isolated.gd` is what caught both: one prop per frame at
three distances against a bright meadow ground, about a minute a pass against the
full-world capture's twenty-plus. It renders a **real prop** at every stand — an
earlier version registered empty markers and was therefore structurally incapable
of showing whether the glow covers the item, which is the exact question the
owner asked.

### Perf

**No per-pickup light.** The `OmniLight3D` that `tm_pickup.gd` and
`item_cache_pickup.gd` each carried is gone. The world holds well over a hundred
pickups (114 harvest nodes across the five bands, five TMs, the caches, the key,
plus every death satchel the player has left behind), OP-0830-6 is an open ROG
performance defect, and the order rules a light-each out by name.

Every pickup glow in the game is **two MultiMeshes and two draw calls**. The
vertex shader collapses an out-of-band instance to zero size, so a far or
already-taken pickup costs no fill either. Additive blending is
order-independent, which is what makes one MultiMesh for the whole world
possible at all. `tests/test_pickup_glow.gd::test_no_pickup_keeps_a_light_of_its_own`
stops the next pickup reaching for a light again.

I cannot claim a frame-time number for this. Nothing in this container measures
GPU cost, and `PERF-ROG-GPU` is already on record that no container here can. The
honest claim is the draw-call count and the absence of lights, not a frame rate.

### Evidence

`tools/capture_pickup_glow.gd` (new) shoots through the **gameplay camera**, not
a free one. That is the fix for the capture defect the lane order warned about:
`grass_field.gd` is *bound* to one camera (`bind(terrain, camera)`), so a tool
that builds its own `Camera3D` photographs ground the field is not dressing and
gets a bare frame. This tool moves the player, lets the rig follow, and shoots
through the camera the field is actually following — which is also the only
camera a player ever looks through.

Every frame is verified twice before the shutter: `tools/capture_check.gd`
(the ground lane's own shared check, merged from `main`) refuses a frame that
would not show the build, and this tool's `_grass_verdict()` writes the tuft
count and the ring's distance from the lens into the contact log, so the
evidence carries the number rather than a pass/fail to be taken on trust.
Weather is pinned and frozen, so a multi-stand pass cannot photograph the same
pickup under two different skies.

`ralph/reports/T5-FEEL/shots/`, matched BEFORE/AFTER pairs at six authored
pickups. **Every frame reports `grass ok: 315232 tufts`** — the real tuft ring,
following the capture camera. No frame in this set was taken on undressed
ground.

| Stand | What it is for |
|---|---|
| `01-gate-key-far` | the key at 14 m — the range a player on the road decides whether to detour |
| `02-gate-key-near` | the same key at 4 m — the glow must step *down* here, not wash the key out |
| `03-tm-stone-rush` | a TM orb: the owner's own example, and a 20 cm object |
| `04-harvest-fiber` | a gathering node in open meadow — the case that must not read as loot spam |
| `05-harvest-stone` | a low rock deposit, the prop most easily lost in a thickening carpet |
| `06-deadwood` | a tall prop: the halo sits in its body, not over its head |

`01-gate-key-far-BEFORE.png` is the defect in one picture: dense real grass, the
key 14 m ahead, and nothing whatsoever telling the player it is there.

**One frame in this set is weaker than the others and it is worth saying which.**
`05-harvest-stone`'s committed frame has the trainer's backpack across its
foreground: the default south-east approach puts the *camera* hard against the
village fence, and the `SpringArm3D` correctly collapses into the player's back.
That is a real camera behaviour producing an unusable photograph, not a glow
failure — the distant pickups in the same frame read fine. The stand now carries
an open-meadow `bearing` override so a future pass frames it properly; the
committed frame predates that fix.

Also committed: `_isolated-glow-{near,mid,far}.png` from
`tools/_probe_pickup_glow_isolated.gd` — one prop per frame at 3 m, 11 m and
24 m, which is where the "item still readable inside its own halo" claim is
easiest to check.

### Honest limits on the look

- **Brightness is the owner's dial, and it is one file.** The pass that shipped
  errs toward restraint: at 16 m+ the glow is a soft warm patch rather than a
  beacon, and a reasonable person could want it stronger. `mote.strength` and
  `mote.radius` in `data/config/pickup_glow.json` are the two numbers; the
  regression test constrains the radius from below (grass reach) and nothing
  constrains the strength, so it can be raised freely. The version *before* this
  one blew out to solid white and swallowed several metres of grass around each
  pickup, which is the failure mode to watch for going the other way.
- **Software rendering.** These frames are `--rendering-driver opengl3` under
  `xvfb`, so composition, silhouette and readability are trustworthy and
  lighting quality is not. That cuts the right way for this question but it is
  not a device screenshot.
- **No frame-time number.** See the perf note above.

---

## For the `ralph/T5-OPENING` lane (OP-0830-2, the key)

The shared treatment exists and is pushed. `key_pickup.gd` already calls it, so
**the key glows on this branch with no work on your side** — take the merge and
delete any bespoke key-glow you were about to write.

If you need to tune it for the key specifically, `PICKUP_GLOW.attach()` takes a
colour, a height override and a scale multiplier; everything else is in
`data/config/pickup_glow.json`. Please do not add a light to the key: the
`OmniLight3D` ban is asserted by `tests/test_pickup_glow.gd` and the reasoning is
in this report's perf section.

I could not message that lane directly — no sibling session was reachable from
this one while it ran.

---

## Files

| File | Change |
|---|---|
| `scripts/world/pickup_glow.gd` | **new** — the shared highlight field, register/unregister, prop-clearance rule |
| `shaders/pickup_glow.gdshader` | **new** — billboard mote + flat aura, distance compensation, per-instance tint and phase |
| `data/config/pickup_glow.json` | **new** — every tunable, `enabled` false is the revert |
| `tests/test_pickup_glow.gd` | **new** — coverage, the grass-clearance rule, the no-lights rule, restraint |
| `tools/capture_pickup_glow.gd` | **new** — evidence frames through the *gameplay* camera, with a per-frame grass verdict and `capture_check` at every shutter |
| `tools/_probe_pickup_glow_isolated.gd` | **new** — one prop per frame at three ranges; the fast loop the look was tuned in |
| `tools/_probe_pickup_glow_coverage.gd` | **new** — proves every pickup the world *builds* is registered, not just every pickup script |
| `tools/_probe_catch_rate.gd` | **new** — the OP-0830-5 measurement harness |
| `scripts/world/key_pickup.gd` | attaches/detaches the shared highlight |
| `scripts/world/tm_pickup.gd` | `OmniLight3D` → shared highlight |
| `scripts/world/item_cache_pickup.gd` | `OmniLight3D` → shared highlight; `_item_colour()` helper |
| `scripts/world/harvest_node.gd` | attaches on `_visual`, so the glow follows the respawn timer |
| `scripts/world/felled_resource.gd` | attaches/detaches; `_pile_colour()` helper |
| `scripts/world/death_satchel.gd` | attaches |
| `scripts/combat/catch_math.gd` | `accuracy_scale()`; `accuracy_bonus()` grades over the hit envelope |
| `scripts/combat/orb.gd` | strike offset clamped at the envelope, not at `body_radius` |
| `scripts/combat/combat_manager.gd` | `catch_aim_offset()` clamped at the same scale |
| `scripts/combat/throw_aim.gd` | LOS ray excludes the orb's own pass-through bodies; miss wording |
| `data/config/catching.json` | `chance.accuracy_span`, with the measurement written into its comment |
| `tests/test_catch_math.gd` | the placement-scale regressions; the old body-radius assertion re-anchored with its reasoning |

## What I did not do, and why

- **Did not touch the five-creature limit, add storage, or make trainer-owned
  creatures catchable.** All three are hard rules in `CLAUDE.md`.
- **Did not raise `hp_factor_full`, any species `catch_rate`, or any orb
  multiplier.** The measurement says the odds were not the defect; the accuracy
  term being a constant was. Raising rates on top of the real fix would
  double-count it and hide the next regression.
- **Did not touch the ground lane's terrain, grass or scatter configs, or their
  capture tools**, per the file-ownership split. The glow consumes their numbers
  (`grass_field.json`) and asserts against them; it does not edit them.
- **Did not edit `stronghold.gd`/`landmark.gd`, `species.json`, spawn tables,
  `objectives.json`, camp files, `performance.json`, or the opening/item-gate
  files.**
- **Did not claim a device frame-time.** See the perf note above.

## Also answered this session

The coordinator routed a separate, higher-priority question mid-session: two
instrumented Gate F segments (S02, X04) logged **zero** combat and catch events
between them, and the question was whether the first fight stages at all for a
real player.

**It does.** Full write-up in `ralph/reports/T5-FEEL-COMBAT-ENGAGES-2026-08-30.md`
— 99 orb throws, 88 strikes and 21 wild catches through the real input path
across the six measurement runs above, plus `smoke_gate_a_opening_segment`
passing *"title through natural catch ... continuously with parsed controller
input"*. It is a rig defect. The report is explicit about what it does **not**
prove (the probe bypasses the opening) and recommends the engage step assert
`CombatManager.is_fighting()` rather than that input was injected — which is the
defect S02's own finding already names.

## Verification

All run locally on this branch, on the merge of `origin/main` at `5d171130`:

| | |
|---|---|
| Unit suite | **1620 tests, 3,568,676 assertions, 0 failed** |
| `smoke_catching` | OK |
| `smoke_controller_catching` | OK |
| `smoke_combat` | OK |
| `smoke_aggression` | OK |
| `smoke_boss` | OK |
| `smoke_gate_a_opening_segment` | OK |

## Next

1. **Owner play is the real verdict on both.** The glow's brightness, size and
   pulse are one config file; catching's feel after the fix is a number the owner
   should feel rather than read.
2. **Re-check the glow after the ground lane's density lands.** The regression
   test will fail loudly if their blades outgrow the mote, but the *visual*
   density question (does an aura read through a thicker carpet) wants a fresh
   frame.
3. **`combat_manager.gd::catch_aim_offset()` still returns 0 for an eligible
   assist**, i.e. it advertises a dead-centre placement the assist does not
   quite deliver. The residual is now small — see the AFTER table — but it is
   not zero, and it is the honest remaining gap between what the reticle
   promises and what the roll uses.
