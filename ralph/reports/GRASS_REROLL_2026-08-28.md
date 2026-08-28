# GRASS-REROLL — the field stops re-rendering as you walk

**Branch** `ralph/GRASS-REROLL`. **Answers** `ralph/OWNER_PLAYTEST_2026-08-28.md`
§1, the owner's main complaint after playing the shipped build on real
hardware.

> *"the grass rerenders like every step. it's very alive feeling which I think
> hurts performance."*

and, separately and unprompted:

> *"don't change the look of my grass. it's awesome"*

Those two halves want opposite responses, so this lane treated them as two
separate requirements: **kill the popping, and leave every still frame alone.**
Both are measured below.

---

## 1. The mechanism, verified before anything was changed

`grass_field.gd::_process` moved the ring by moving the node, snapped to
`snap` = 2.0 m. Every per-item property in the three field shaders —
`grass_field`, `stone_field`, `cover_tier` — is hashed on the item's **world**
position:

    hash12(world_xz * 7.31) > keep        // does this tuft exist
    hash12(blade_seed * 3.77)             // how tall
    hash12(blade_seed * 11.13)            // which way it leans
    hash12(world_xz * 2.17)               // its shade

and the instances live in the node's **local** space, so the moment the node
moved, every item's world position moved with it and every one of those hashes
returned a fresh number. The field did not translate. It **re-rolled**.

The snap never removed that. It made it *periodic*: one whole-field re-roll
every 2 m, which at `combat.json`'s 5.0 m/s walk is one every 0.4 s. That is
what "every step" describes, and the function's own comment had recorded the
cost without anyone reading it as the defect.

**Measured, on this container, before any change was made.**
`tools/_probe_grass_walk.gd` takes twelve frames from a camera that does not
move, while the camera the *field* is bound to walks 0.5 m at a time. Wind off.
So two consecutive frames differ by exactly one thing: what the ring did. Mean
absolute pixel difference over the ground half of the frame, with the player's
own column removed:

| pair | 0-1 | 1-2 | 2-3 | 3-4 | 4-5 | 5-6 | 6-7 | 7-8 | 8-9 | 9-10 | 10-11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **before** | **46.6** | 0.09 | 0.08 | **45.9** | 0.04 | 0.10 | 0.06 | 0.08 | **44.5** | **43.6** | 0.24 |

Four re-rolls in 5.5 m of walking. Between them the field is frozen — 0.08 of
255 is nothing. Then a sixth of every pixel in the near field changes in one
frame. **The defect was never the amount of change. It was that all of it
arrived at once.**

## 2. The fix

The constraint, stated properly: *moving the ring by one snap step has to map
the set of occupied world positions onto itself.* A point set with that
property is a lattice.

So an instance's stored translation is no longer where it stands. It is the
world **lattice cell** it belongs to (cells of `snap` metres) plus a tag saying
which of that cell's items it is and which layer it came from. The node may
only ever sit on whole cells. Where the item actually stands — with its yaw and
its fade rank — is hashed from that cell's **integer** coordinates in the
shader. Walk forward and instance 400 takes over the cell instance 617 was
drawing a moment ago, at the same offset, the same height, the same lean.
Nothing pops because nothing changed. The field is a property of the ground
now, not of the ring.

Three things fell out of that and had to be solved rather than accepted:

- **The density gradient.** `centre_bias` 0.62 is not a uniform disc: it puts
  ~78 tufts/m² at the eye against ~15 at the rim, and that is most of why the
  near field reads as thick. One uniform lattice cannot have it. So the ring is
  **nested lattices** — a base one over the whole disc plus a stack of smaller
  discs each adding the difference — fitted numerically to the same analytic
  profile the old disc law produced (`_lattice_plan`). It lands within 3% of it
  everywhere inside 40 m and within 8% at 48 m.
- **The joins between those discs** would otherwise be density rings following
  the player around, so each layer arrives as **height**, dithered against a
  stable per-cell rank: a fraction of one layer is mid-growth at any moment
  instead of all of it switching together.
- **The per-item yaw** used to live in the instance basis, and a yaw carried by
  the instance travels with the instance — every tuft would have spun on the
  spot each time the ring stepped. It is hashed from the cell now too.

Separately, `field_centre` was doing two jobs and is now one: it carries the
**unquantised eye**, written every frame, so the ring's edge fade, the
near-to-far blade height and each layer's ramp are continuous. They used to
read the snapped ring position and therefore stepped 2 m at a time.

**One bug found and fixed inside this lane, recorded because it was invisible
and expensive.** The first working build rendered a visibly thinner meadow.
The cause was not the density fit: `lattice_rand` hashed on the item tag's x
half only, so layer 0's item 5 and layer 3's item 5 in the same cell hashed to
the same spot and rendered exactly on top of each other. Every layer above the
base was invisible underneath it — a third of the meadow's grass, silently, and
it looked exactly like a bad density plan. `shaders/*.gdshader` carry the note.

## 3. Evidence — the defect

Same probe, same seat, same twelve steps, on the fixed build:

| pair | 0-1 | 1-2 | 2-3 | 3-4 | 4-5 | 5-6 | 6-7 | 7-8 | 8-9 | 9-10 | 10-11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **after** | 0.93 | 0.74 | 1.07 | 0.90 | 2.02 | 6.61 | 3.24 | 1.18 | 1.15 | 5.34 | 2.39 |

- **Worst single-frame change: 46.6 → 6.6.** That is the number the complaint is
  about, and it is a factor of seven.
- **Mean: 16.5 → 2.3, −86%.**
- **The shape changed, which matters more than the size.** Before was bimodal:
  nothing, nothing, nothing, catastrophe. After is a low continuous drift with
  no discontinuity in it. Some of that 2.3 is not even the grass — the sky's
  clouds animate and are in both sets.
- **This is an honest trade, not a free win.** Between re-rolls the old field
  changed by 0.08; the new one changes by about 1–2 every frame, because the
  layer ramps and the now-continuous eye-distance fades mean things move
  smoothly all the time instead of not at all and then all at once. That is the
  intended exchange.

`ralph/reports/shots/grass-reroll/held-diff.png` is the picture of it: the
before difference map lights up every blade and every flower across the whole
frame; the after is near-black with a scatter of individual blades growing in.
`held-pair.png` is the same two exposures before and after, and
`walk-strip.png` is four frames of the walking sequence from each build. The
full twenty-frame sequences are `shots/reroll_before` and `shots/reroll_after`,
which `.gitignore` keeps out of the repo -- re-run the probe below to
regenerate them.

## 4. Evidence — the look, which was not allowed to change

No look parameter was touched. `tuft_count`, `field_radius`, `fade_start`,
`centre_bias`, every tint, every height, `density_gain`, the clump noise, the
wind, the gust, the edge shortening and all three cover tiers are byte-identical
in `data/config/grass_field.json`. The five keys added are lattice geometry and
are documented in that file as not being look parameters.

A pixel diff cannot check this — no individual tuft is in the same place any
more, by construction — so `tools/grass_look_compare.py` measures the
statistics that *are* the look, in horizontal bands, averaged over all twelve
held frames and all eight walk frames:

| band | value | hue | edge energy (density/silhouette proxy) | dark fraction |
|---|---|---|---|---|
| sky/far | −0.1% | +0.0% | −0.3% | −0.0% |
| mid | −0.6% | −0.4% | −1.3% | +1.0% |
| near | +1.0% | −0.4% | −2.5% | −1.5% |
| foreground | −2.8% | +3.3% | +1.2% | +4.7% |

and on the walking sequence, every band within 2.4% on every measure. Palette,
density, silhouette and shading all hold to within the frame-to-frame noise of
two independently arranged fields. The residual foreground difference is real
and understood: the layer stack stops at `lattice_min_radius` 2.0 m, so inside
about 2 m of the camera the field plateaus at ~57 tufts/m² where the disc law
diverges. That ground is under and behind the player.

Item counts, which is where the fit shows up as cost:

| tier | configured | instances built | visible after the ramps |
|---|---|---|---|
| grass | 300,000 | 315,232 (+5.1%) | ~299,100 (−0.3%) |
| stones | 90,000 | 93,236 (+3.6%) | ~89,900 (−0.1%) |
| bushes | 14,800 | 15,052 (+1.7%) | ~14,260 (−3.6%) |
| flowers | 14,800 | 15,052 (+1.7%) | ~14,260 (−3.6%) |
| litter | 49,000 | 48,716 (−0.6%) | ~47,640 (−2.8%) |
| **total** | **468,600** | **487,288 (+4.0%)** | |

The nested discs overlap their growth bands, so about 4% more instances stand
up than the config asks for and roughly that many are height-ramped to nothing
at any moment. The *visible* item count is within half a per cent on the two
tiers that dominate the frame.

## 5. What was NOT measured, and will not be claimed

The owner's words were *"which I think hurts performance"* — a hypothesis from
feel. **This lane cannot test it and does not claim to have.** `PERF-ROG-GPU`
records that no container in this project can measure GPU cost; this one
rasterises in software, and device frame rate, GPU time, VRAM and thermals are
all `[OWNER-ONLY]`.

What can be said honestly:

- **The CPU side was already cheap and is now slightly less cheap.** `_process`
  wrote one `wind_time` uniform per material per frame and the centre only on a
  snap. It now also writes `field_centre` to all five materials every frame:
  five extra uniform writes per frame, against a 487,288-instance draw. This is
  not a plausible frame-rate factor in either direction.
- **The GPU side is 4% more instances.** Unmeasured on the device, and it is an
  increase, not a saving. It is the price of the fade bands that keep the
  nested discs from reading as rings.
- **Whether the re-roll itself cost GPU time is unknown.** It re-ran the same
  vertex work with different results; it did not obviously add work. The fix
  was made because the popping is a visual defect the owner named, not on a
  performance argument nobody here can support.

If the Ally says the field is too expensive, the levers are unchanged and are
still one config edit: `tuft_count`, `field_radius`, and `enabled` to switch the
whole thing off in favour of the scatter path, which is intact.

## 6. Reproducing

    # the sequence that shows the defect present or absent
    xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
      --rendering-driver opengl3 --resolution 1280x800 \
      --script tools/_probe_grass_walk.gd -- --out=shots/reroll_after

    python3 tools/grass_reroll_diff.py shots/reroll_before shots/reroll_after
    python3 tools/grass_look_compare.py \
      shots/reroll_before/held-00.png shots/reroll_after/held-00.png

Never `--headless` with a real rendering driver — it hangs with no error.

## 7. Tests

`test_grass_field` (5 tests, 31 assertions), the scatter suite (33 tests,
958,342 assertions), `smoke_art` and `smoke_playground` all pass on this branch.
The grass field still suppresses `grass`, `drygrass`, `flowers` and `groundmat`
from the scatter and `smoke_art` still checks that agreement both ways.
