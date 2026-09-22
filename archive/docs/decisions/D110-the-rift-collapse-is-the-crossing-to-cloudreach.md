# D110 — The rift collapse is the crossing to Cloudreach

**Date:** 2026-09-05 · **Decided by:** implementing owner playtest
`docs/owner/OWNER_PLAYTEST_2026-09-05.md` OP-0905-15. An owner reproduction
outranks D23's own carve-out and `BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md`'s
§7, per `CLAUDE.md`'s precedence order.

## What was decided

OP-0905-15, verbatim: "The portal to the next biome is horrible. It didn't
need to be there. When you beat the legendary the rift collapses and the
second biome is revealed and pulled into the map to connect."

1. **The Meadows-side realm arch is gone.** `playground_world.gd` no longer
   builds a `realm_gate.gd` instance at `realm_transitions.json`'s
   `meadows_cloudreach_gate`. There is no key prompt, no "Unlock the way to
   Cloudreach Cliffs" interaction, and no locked-seal visual standing in the
   Meadows. `realm_gate.gd` itself is untouched — Cloudreach still builds its
   own physical return gate from it (`cloudreach_world.gd::
   _build_return_gate`, a file this task does not own), and
   `realm_transitions.json`'s `meadows_cloudreach_gate` key stays authored
   (now read by nothing on the Meadows side) only so
   `meadows_entries.meadows_cloudreach_gate_return` next to it keeps naming
   the Meadows-side arrival point for the return trip.
2. **The crossing is the storm road's own collapsed bridge, rebuilt.** New
   file `scripts/world/rift_crossing.gd`, built in `playground_world.gd`
   immediately after `RiftCollapse` (SG44's sky event). It watches the same
   `legendary_freed` flag `rift_collapse.gd` already watches, off the same
   `data/config/rift_collapse.json` (its own new `crossing` block), and
   places its geometry off `terrain_playground.json`'s `storm_road` spoke —
   the same carve `severed_spokes.gd::_build_collapsed_bridge` already stood
   two masonry abutments on either side of, with nothing between them.
   - Before the flag: nothing changes. The carve is exactly as impassable as
     it always was, and its existing failsafe (`blocker.carve.failsafe`,
     `severed_spokes.gd::_add_carve_failsafe`) still catches a fall into it.
   - When the flag lands: `rift_crossing.gd` waits out `rift_collapse.json`'s
     own `collapse.hold_seconds + dissipate_seconds` (so the sky event and
     the ground event read as one motion), then grows a walkable deck from
     the near abutment to the far one — a masonry slab on the same
     `T_UnevenBrick` sheet the abutments wear, with low side rails, appearing
     over `crossing.appear_seconds`. A save loaded with the flag already set
     stands the span immediately, with no animation, the same contract every
     other post-flag world change in this chapter keeps.
   - Past the far abutment, well short of `far_road`'s own kerb dressing, one
     Area3D (`RiftCrossingTrigger`) is the actual realm boundary: crossing it
     calls `Game.enter_realm("cloudreach", "cloudreach_arrival_from_
     meadows")` exactly once, guarded against re-entry and against firing
     while the interaction arbiter is disabled (a fade or dialogue open).
   - A plain fingerpost reading "Cloudreach Cliffs" stands on the far rim,
     through `severed_spokes.gd`'s own sign builder — the same object every
     other severed spoke's destination sign already is.
3. **`realm_gate_cloudreach_unlocked` is now set by the crossing, not by an
   interaction.** The flag's meaning is unchanged — "the passage between the
   Meadows and Cloudreach is open" — only what sets it moves, because there
   is no interactable left to unlock. `rift_crossing.gd` sets it once, at the
   moment the trigger fires, so Cloudreach's own return gate
   (`MeadowsReturnRealmGate`, which this task does not own) keeps working
   exactly as before without that file needing to change.

## Why

D23's own carve-out reads: *"'The next biome physically joins the Meadows' is
delivered as a distant, non-enterable view ... behind a believable barrier.
No second biome's terrain, spawns, species or playable space."* That is
exactly the arrangement the owner played and rejected: a real, walkable
realm arch standing next to a permanently non-enterable painted horizon read,
to the person playing it, as two unrelated ideas bolted together — a portal
that "didn't need to be there" beside a wall that visibly can never open.
`BUILD_CLOUDREACH_CLIFFS_TO_COMPLETION.md` §7's "Key to the Next Realm"
entrance is the design this replaces; it is a fine mechanism in the abstract
and the wrong shape for a game whose whole climax is one seam changing.

The owner's own words name the fix: the rift *collapsing* is what should
*be* the crossing, not a decoration standing next to it. `rift_collapse.gd`
already had the flag, the timing, and the exact seam. This decision gives
that seam a floor.

## What this does not change

- **The pre-flag carve-out is untouched.** Nothing before `legendary_freed`
  is different: no terrain, collider, spawn, species, interactable or nav
  mesh exists past the seam until the flag lands, and `tests/smoke_boss.gd`
  still drives a body at the legendary's own climb limit into the seam
  before the flag and asserts it does not cross.
- **`rift_collapse.gd`'s own sky content is untouched.** The `StormWall` and
  `FarCountry` slabs are still unshaded, colliderless, unreachable painted
  geometry outside the boundary ring; `rift_crossing.gd` is a sibling file
  that only reads `rift_collapse.json`'s `flag` and `collapse` timings, never
  its nodes.
- **No Biome 2 terrain, spawns, species, or playable space stands in the
  Meadows.** The crossing ends at one Area3D on the Meadows side; everything
  past it is Cloudreach's own scene, loaded the ordinary way `enter_realm`
  already loads it.
- **`realm_key_cloudreach` is still granted by the Warden**, at the same beat
  as `legendary_freed` (R8.4). The router (`Game.can_enter_realm`) still
  requires it before `enter_realm` will act, so the crossing's trigger is not
  a second, weaker gate — it is the same entitlement, checked at a different
  physical location.
- **Nothing about Cloudreach's own scenes, runtime, or realm gate changes.**
  `cloudreach_world.gd`, `cloudreach_world_runtime.gd` and `realm_gate.gd`
  are untouched.
