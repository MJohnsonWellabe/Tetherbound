# D45 — The drained-ground grammar: one radius, three consumers, no new shader

**Date:** 2026-08-16 · **Decided by:** the firing that built `SD16`, inside the
space `D41` explicitly left open.

`D41` decided that Team Tether's stations visibly kill the land around them,
and then said, in as many words, what it was *not* deciding:

> The exact visual vocabulary — how far the dead radius reaches, whether the
> ground discoloration is a texture blend or a vertex/material tint, whether
> withered vegetation is a separate mesh variant or the existing meshes
> retinted and shrunk. Those are `Phase 8` implementation calls.

This is that call, made once at the quarry so every later station copies it
instead of inventing a fourth version. It decides mechanism, not intensity —
the relay and the Upper Meadows pylon field get worse by turning these numbers
up, and that is the point.

## The decision

**One authored radius, read by three consumers through one function.**

`terrain_playground.json` gains a top-level `drains` block: a list of stations,
each `{centre, radius, inner, strength}`, plus global tint/weight tunables.
`playground_heightfield.drain_factor(x, z)` turns that into 0..1 — 1.0 inside
`inner`, smoothstepping to 0.0 at `radius`, zero everywhere else. Three
consumers ask that one function and weight it their own way:

1. **The colour map** (`build_playground_terrain.gd`) lerps the pixel toward
   `drains.tint` — a desaturated warm grey — *after* the wet and apron lerps,
   so drained path, drained bank and drained grass all catch the same sickness.
2. **The control map** blends the pixel toward the existing `soil` texture,
   ordered behind `worn` so a road crossing a dead radius is still a road.
3. **The scatter** (`scatter_rules.gd::_thin_by_drain`) removes placements,
   scaled by each layer's own `drain_suppression`.

The reason this is a decision and not just an implementation is the *one
function* part. The whole effect is the terrain and the vegetation agreeing
about exactly where the dead ground ends; two lists, or a flag copied into
`vegetation.json`, and they drift the first time anybody moves a pylon.

## What the vocabulary actually is, item by item

- **Discolouration is a colour-map tint plus a control-map blend, not a new
  shader and not a new texture.** The ground material path already had both
  mechanisms, doing exactly this job for building aprons and the wet pond bed.
  A drained station is one more thing that changes what a pixel is made of.
  `#bfb6a0` at 0.85, deliberately not much darker: the colour map *multiplies*
  albedo, and `terrain_playground.json`'s own comment is blunt that anything
  much below `#c0` there is "a brightness change pretending to be a colour".
  The dead read comes from the material swap; the tint carries the cast.
- **Withered vegetation is thinning, not new meshes.** No shrunken variants, no
  retinted second copies of the grass — `D24` and the no-new-generations rule
  make that the only available answer anyway, and it is also the better one.
  Green layers vanish (`drain_suppression` defaults to 1.0), `drygrass` mostly
  survives (0.35), and `rocks`/`deadfall` are exempt (0.0). The drained ground
  therefore changes *species* rather than going bald, which reads at a distance
  where an absence does not.
- **Standing dead is authored, not scattered.** One `deadfall` anchor at the
  quarry, narrowed to the three dead-tree models. Half the drained read is what
  is missing; the grey verticals are the half that says something used to grow
  here.
- **The suppression is a FILTER, never a gate.** Every other scatter rule
  rejects a candidate inside `_consider`, before its scale and yaw are drawn —
  which shifts every later instance in that layer onto different random draws.
  Adding one of those in the far south would have reshuffled the whole map's
  trees and rocks, including placements three visual passes had already tuned
  around the village. The drain filters the finished list instead: it removes
  instances and moves nothing. Which instances die is coherent position noise,
  not `rng`, for the same reason.

## What it costs, honestly

The heightfield is baked, so the drained ground's colour and material are baked
too — moving a station means re-running `build_playground_terrain.gd` (about
twelve minutes). That is already true of every path, pad and carve on this map
and is the accepted trade (`D05`: authored geography, not a runtime generator).

It also means `SG46`'s healing — `D41`'s payoff, the land recovering once the
Warden falls — **cannot** be a change to the baked maps at run time. Whatever
`SG46` does will have to work on the live scene: the vegetation can be re-built
from a `drains.strength` of zero, and the ground itself will need a material or
overlay treatment that this decision does not provide. Recording that here
rather than letting `SG46` discover it: the grammar chosen for the *damage* is
baked, so the grammar for the *repair* is a separate piece of work, and pricing
it now is cheaper than being surprised by it in Band 5.

## What it does not decide

Intensity, which is per-station data. The quarry's own head station is 0.85
with a 24m radius and the run out of it falls to 0.5 at 15m, which is `D41`'s
"mild at this rung" of §32's ladder. `SE23` makes the relay worse by widening
and strengthening its stations, not by inventing a second grammar; if a later
station genuinely needs something this cannot express, that is a new decision
and it should say so out loud.
