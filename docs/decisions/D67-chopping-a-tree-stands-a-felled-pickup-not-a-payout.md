# D67 — chopping a standing tree/rock stands a felled pickup; it does not pay out

## Context

Owner directive, from a real ROG playtest (Phase -1.6, `RG9`), verbatim:
*"You shouldn't be able to gather a standing tree. You should have to chop
it. Then it becomes downed wood. Then you gather that. Same for stone."*

Before this, `HARVEST-ALL`/`D60` had just made every tree and rock in the
meadow harvestable and permanent: a single interact-press or tool swing on a
STANDING tree paid the resource straight into the satchel and removed the
placement for good. That single-step model is what this item changes — the
removal mechanism `D60` built (render instance + collider + node, gone
forever, tracked in a per-layer bitset) is unchanged and this decision builds
on it rather than touching it.

## Decision

A harvestable placement is now a two-stage object, exactly as the owner
described it:

**Standing → chop → felled → gather → gone.**

1. **Standing.** `vegetation_harvest_point.gd` is now ONLY the chop marker: an
   interact prompt (default label "Chop") and the group membership a tool
   swing needs to find it (`harvest_logic.gd::GROUP`). It builds no resource
   prop of its own any more — the living tree or rock, drawn by
   `vegetation.gd`'s own scatter, is the entire visual. (The woodpile OW7
   built here moved to the felled stage below; a pile of cut logs standing at
   the base of a still-living tree never made sense, and RG10 removed the
   glint marker that used to sit on it regardless — see that item's own note
   in `vegetation_harvest_point.gd`'s header.)

2. **Chop.** `vegetation_harvest_point.gd::_on_gathered()` still runs the
   exact tool-gating `harvest_logic.gd::gather()` always ran — the right tool
   pays full yield and wears down, no tool pays a reduced bare-handed amount,
   the wrong tool is refused outright and the tree stays standing. What
   changed is what a SUCCESSFUL chop does with that computed amount: instead
   of adding it to the satchel, it is handed to `vegetation.gd::fell()` as
   `actual_amount`, which:
   - calls `harvest_permanently()` unchanged — the standing placement's
     render instance, collider and this node are gone, forever, exactly as
     `D60` describes;
   - stands a `felled_resource.gd` pickup at the placement's own position
     (the same ground-sampled offset OW7 already computed for the old
     woodpile), carrying `actual_amount` — NOT the layer's configured
     default. A bare-handed chop stands a smaller pile; the chop already
     decided the amount, and the pile is just where it is held until
     collected.

   Chopping no longer checks satchel room. A full satchel used to refuse the
   chop itself, which stopped making sense the moment chopping stopped
   putting anything directly in the satchel — a player can always chop; a
   pile with nowhere to go simply waits.

3. **Felled.** `felled_resource.gd` (new) is the downed pickup: bare-handed,
   no tool gate, no durability — the tool already did its job at the chop.
   Its own `gather()` checks `has_room_for` (refused visibly, pile stays
   and keeps offering, same as every other gather point's full-satchel
   refusal), adds the item, tells `vegetation.gd::clear_felled()` the pile is
   spent, and frees itself. It joins the same `harvest_logic.gd::GROUP`, so a
   tool swing connects to a felled pile exactly the way it connects to a
   standing tree — one swing chops, a second swing (or an interact press)
   collects.

   Visually: wood gets the real woodpile (three tinted logs, moved verbatim
   from the old standing-point code). Stone has no vendored rubble/broken-
   rock mesh anywhere in the build (D24 forbids a new asset family for one
   pickup), so it gets a small cluster of primitive boulders in the stone
   layer's own tone — an honest placeholder, not a final look; `RG11`
   ("stones look like white paper") is the item that owns whether stone reads
   well, not this one.

## Persistence

This is the part `D60` flagged as a real risk if built carelessly: without
tracking the felled-but-ungathered state, a player who chops a tree, never
walks over to collect the log, and reloads would find the tree gone and
nothing where it stood — the wood the chop already earned silently lost.

`vegetation.gd::_felled: Dictionary["<layer>#<index>" -> {"item", "amount",
"position": [x,y,z]}]` tracks exactly this, sparse and bounded by the same
per-layer placement count `_harvested`'s bitset is bounded by (a placement
can be chopped at most once, so this can never exceed the world's own
harvestable total). `clear_felled()` erases the entry once the pile actually
pays out — never speculatively, the same rule `harvest_permanently()` itself
already follows.

Saved as `GameState.felled_vegetation`, VERSION 11 of
`scripts/save/save_game.gd`'s format (`_migrate_v10`: a pre-VERSION-11 save
predates chop-then-gather entirely, so every chop it remembers already paid
out immediately — migrates to `{}`).

`vegetation.gd::restore_from_game()` now does one of three things per
chopped index the save remembers: nothing new for an index this session
already agrees is chopped (the existing idempotent bit-guard); replay
`harvest_permanently()` alone for a chop the save says already paid out
(absent from `felled_vegetation`); or replay `harvest_permanently()` AND
restand the pickup, from the SAVED item/amount/position, for a chop still
owed. The saved position is used rather than re-deriving one through
`fell()`, because `_harvest_lookup` (which `fell()` reads) may already be
empty for a placement chopped earlier this same session, and because the
SAVED amount is what the chop actually earned, not necessarily the layer's
configured default.

This composes with `D60`'s own "chopped stays chopped, regardless of which
save gets loaded on top" rule without any special-casing: a placement already
chopped AND gathered this session, with an older save loaded over it, does
not resurrect a picked-up pile — `_harvest_lookup` is already empty for it
(so `fell()`-style re-derivation is moot) and the idempotent guards on both
`harvest_permanently()` and the spawn path mean nothing double-fires. Not
un-gathering follows from the same primitives that already refuse to
un-chop.

## What this does not do

- It does not touch `harvest_node.gd`'s ~10 authored tutorial spots, which
  keep their single-step gather-and-respawn behaviour unchanged — the same
  scope boundary `D60` drew for itself, for the same reason: this is
  `vegetation.gd`'s own scattered-instance harvesting, not the tutorial path.
- It does not solve stone's visual ceiling (`RG11`). The rubble mound is
  real geometry, not a placeholder box, but it is not a final asset.
- It does not decide anything about `farm_plot.gd`, which shares
  `harvest_logic.gd::GROUP` for an unrelated reason (till/sow/pick) and was
  the source of a real false-negative in this item's own smoke-test
  development — a swing search that does not filter by script can find a
  farm bed instead of a tree and conclude nothing connected. Worth noting for
  whoever next writes code against this group: it is not exclusively
  trees and rocks.

## Verification

`tests/test_gather_point_props.gd` (rewritten): a standing point of either
item builds no prop and no glint, keeps its interact prompt, and defaults to
the "Chop" label.

`tests/test_felled_resource.gd` (new): wood stands a real multi-mesh
woodpile, stone stands a real multi-mesh rubble mound (never a woodpile),
neither carries a glint, `setup()`'s own bookkeeping (`_item_id`/`_amount`/
`_felled_key`) round-trips, and `gather()` is exposed for a swing to call.
`gather()`'s own inventory-touching half needs the real `/root/Game`
autoload this runner never boots (the same limit `test_harvest.gd`'s own
header documents for `harvest_node.gd`'s `_on_gathered()`), so that half is
covered live instead — see below.

`tests/test_harvest_permanence.gd` (extended): `fell()` chops the standing
placement (reusing `harvest_permanently()`'s own already-tested mechanism)
and stands exactly one felled child with the CALLER-SUPPLIED amount, not the
layer's own default; tracks and un-tracks `_felled` correctly; an unknown key
still chops but stands nothing; `sync_state_to_game()` writes
`felled_vegetation` alongside `harvested_vegetation`; and the full save round
trip — chop, save before gathering, load into a fresh `vegetation.gd` —
restands the exact pile the save still owes, while the OTHER half (chop AND
gather, then load an older save on top) correctly does not resurrect an
already-collected pile.

`tests/test_save_format.gd` (extended): VERSION 11 round-trips
`felled_vegetation` directly, a VERSION 10 fixture migrates to nothing-felled,
and the existing `test_every_readable_save_version_actually_loads` sweep
exercises the new migration step automatically (it loops `SAVE_GAME.VERSION`,
not a hardcoded number). Two pre-existing `FakeGame` test doubles
(`test_save_format.gd`, `test_satchel.gd`) needed `felled_vegetation` added —
`scripts/save/save_game.gd::save()` casts `game.get("felled_vegetation")`
straight to `Dictionary` with no null guard (matching `harvested_vegetation`'s
own established convention on the same line), so a double that omits it
crashes `save()` outright rather than failing its own assertion. Caught by
`tests/test_save_format.gd::test_slots_are_independent_of_each_other`, an
unrelated test that happened to call `save()` on a double missing the new
field.

`tests/smoke_playground.gd` (extended, real end-to-end boot): a new check
walks the player up to a real standing tree/rock (filtered by script identity
to exclude `farm_plot.gd`, which shares the same group), chops it with a real
swing, confirms the standing point is gone and a real `felled_resource.gd`
node stands within 3m of the chop, then swings a SECOND time at that pickup
and confirms the satchel's total item count actually increases — the two-
stage flow proven live, not just at the data level. This is also the check
that incidentally re-confirmed `RG2`'s swing-facing fix (`tool_hold.gd`) end
to end, since chopping requires a connecting swing in the first place.
