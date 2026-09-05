# D80 — Combat VFX are mesh-based, and the level-up flourish rides the deployed body

**Date:** 2026-09-04 · **Decided by:** lane W09-VFX, inside CL-A2 (funded by the owner
2026-09-04: *"Yes"* to combat and reward VFX). Small calls the brief left open, recorded
here rather than asked, per `docs/00_START_HERE.md`.

## 1. No GPUParticles3D / CPUParticles3D, even though the brief allowed them

The lane brief named "GPUParticles3D/CPUParticles3D with primitive quads" as the kit.
Three shipped effects in this repo (`impact_flash.gd`, `telegraph_glow.gd`,
`alpha_aura.gd`) each document, from a paid-for incident, that particle behaviour is not
trustworthy under the software OpenGL the survey and the blind judge run on, and that an
effect which cannot be judged from a rendered frame cannot ship under
`docs/AGENT_WORKFLOW.md` §7. A CPUParticles3D also runs on the render clock, and one
llvmpipe frame is ~2.4 s of delta — the same reason `move_projectile.gd` was moved onto
the physics clock. So the spark, puff, catch sparkle and flourish are camera-facing
`ImmediateMesh` geometry whose particle positions are computed from the effect's age on
the physics tick (`scripts/vfx/vfx_burst.gd`, `level_up_flourish.gd`), MIX-blended,
vertex-coloured. "Primitive quads" is satisfied: every mote is a triangle fan and every
streak a quad. Nothing new is generated or imported.

## 2. The body flash is a per-instance material overlay, not a material edit

`creature_body.gd` shares one material per species/colourway across every live body.
Brightening that material to flash one creature flashes the cluster. The hit flash and
the level-up rim therefore use `GeometryInstance3D.material_overlay` with
`shaders/vfx_body_glow.gdshader` on the struck body's own `MeshInstance3D` nodes — set for
the effect's life and cleared after, an overlay already present on a mesh left alone.
`creature_body.gd` is not edited; the brief's "write the patch in the report" clause was
not needed.

## 3. The KO puff is not a third hook

`combat_manager.gd::_flash_at()` is the one function both damage sites already funnel
through. It is now handed the struck body and the damage fraction, and `combat_vfx.hit()`
reads the struck instance's `fainted` flag there: a body that is fainted at the moment
its hit lands just took the killing blow. That covers a wild fight ending and a trainer's
second creature falling mid-battle from one place, and leaves `_flee_pressed()` and the
trainer-round path untouched for the lanes editing them.

## 4. The flourish plays on the creature that levelled only when it has a body

A level-up is shown on the deployed ally's body. A bench member that levels from the
party share of a win is in its orb; there is no body to light, and lighting the human
trainer for it reads as the wrong thing glowing. So bench level-ups get the HUD line
only (`vfx.json` `level_up.bench_on_trainer: false`, kept as a tunable so the call can be
reversed without code). Until `Game.progression_feed` (prompt 73 §2.1) lands, the watcher
polls `Game.party` by `revision`; `on_progression_event()` is the seam the feed plugs
into and `min_gap` collapses a poll detection and a feed event into one picture.

## 5. Tunables live in `data/config/vfx.json`; `enabled: false` is the whole revert

Independent of `combat.json`'s existing `impact` ring, which keeps playing either way.
