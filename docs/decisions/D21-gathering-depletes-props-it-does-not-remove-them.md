# D21 — Gathering depletes props; it does not remove them

**Status:** accepted, M8
**Supersedes nothing. Related: D09 (never raycast for ground), D12 (the build grid), D17 (items and stations).**

## The question

The meadow is drawn as ~73,000 MultiMesh instances across ~700 batches. M8 asks
for gathering. What happens to a tree when you chop it?

Three answers were available and two of them are wrong:

- **Infinite.** A tree you can chop forever is a tree you never walk away from,
  and the whole point of a gathering loop is that it moves you through the world.
- **Vanishing.** A forest that thins out over a session and never recovers is a
  world that gets worse the longer you play it, on a map GAME_DESIGN.md §30 sizes
  for a 4–8 hour arc that the player is expected to re-cross.

## The decision

**A prop DEPLETES and REGROWS.** Each harvestable has a number of swings in it
and a regrow timer, both in `data/config/gathering.json` and both tunable. A tree
is four swings and seven minutes; a berry bush is one pass and three. Nothing is
ever removed from the world and nothing is ever added to it.

**A spent prop is HIDDEN only when hiding it is safe.** MultiMesh gives no
per-instance identity, but it does allow a single instance's transform to be
rewritten in O(1) — deleting an instance is what would rewrite the array, and
nothing here deletes one. So a spent prop can be sunk out of sight and put back.
That is only honest for props with no collision: hiding the mesh of something
that still has a collider leaves an INVISIBLE WALL, which is a worse bug than a
tree that is visibly still standing.

Which props those are is **observed from the world, not configured**: the indexer
looks for a `CollisionShape3D` at the prop's XZ and hides only what has none. In
the current scatter that works out as *bushes, berry bushes and fallen timber
disappear and come back; trees and boulders stay up and are simply spent for a
while*. If the scatter's collision layers change, this follows them with no edit.

## How a MultiMesh instance gets an identity

`scripts/world/harvestable.gd` builds a spatial hash once, from the batches:

1. Walk the scatter's `MultiMeshInstance3D` children. A batch is classified by the
   **longest model name its node name begins with** — the scatter names batches
   after their model, plus a `_x_y` cell suffix. Longest-first is load-bearing:
   `Bush_Common` is a prefix of `Bush_Common_Flowers`, and shortest-first would
   silently turn every berry bush in the meadow into a fiber bush.
2. Read each batch's positions from `multimesh.buffer` — **one** RenderingServer
   round trip per batch rather than one per instance.
3. Keep a record only for instances whose model is a harvestable kind: about
   2,500 of the 73,000. Grass alone is over 60,000 and is not a resource.
4. Bucket the records by 4m cell. "What is in front of the trainer" is nine bucket
   lookups.

**What it costs:** ~2,500 records for the life of the world, one pass over the
batches when the index is built, and a per-frame tick over only the props that are
currently spent. Nothing per prop per frame, and no node per prop.

**What it assumes about a file this milestone does not own:** that the scatter
draws with `MultiMeshInstance3D` nodes named after their model, and that solid
layers get `CollisionShape3D` children. Both are observed rather than read from
`vegetation.json`, so a rewrite that keeps drawing MultiMeshes keeps working.

## The headless trap, which cost an afternoon

Under `--headless` Godot runs the **dummy renderer**. It accepts
`set_instance_transform()` and discards it, returns the identity from
`get_instance_transform()`, and leaves `buffer` empty. The first version of the
indexer trusted those reads and produced 2,500 harvestable props all stacked on
the world origin — which, in a headless smoke, looks exactly like a working meadow
with infinite wood at the spawn point.

So: **a batch that will not give up its buffer is indexed as nothing, and says
so.** `transforms_readable()` reports it and `reindex()` pushes a warning.

The consequence is that **prop positions are a rendered-session question**. Every
smoke in this project is headless (`tools/run_smokes.sh` records why: one of them
went from 191s to over 2400s under a renderer). `tests/test_gathering.gd` covers
everything that does not need a renderer — classification, the tool rules, the
deplete/regrow cycle, the save round trip, the collider rule — and says plainly
which assertion is the rendered-only one.

## Save

Only what the player changed. The scatter is deterministic from a seed and comes
back identical every boot, so writing 2,500 untouched trees into every save would
be 2,500 lines saying "still a tree". Worked and spent props are written, keyed by
**quantised world position** rather than by batch index: an index is meaningless
the moment the scatter's batching changes, and a save that came back pointing at
the wrong trees would be invisible until somebody noticed the wrong bush was
empty. A saved entry that finds no prop is dropped, so a changed seed gives a
fully grown meadow rather than an uncleanable bookkeeping entry.

## Consequences

- Tools have a real cost: 2 durability a swing on a tree, 15 trees to an axe.
- Bare hands are a real option, and deliberately: fallen timber, loose stones and
  berry bushes need no tool, which is what lets an empty-handed trainer reach a
  workbench. A bush gives 1 fiber to a hand and 6 to a knife, so the knife is an
  upgrade rather than a key — gating fiber behind a knife that costs fiber would
  deadlock the recipe chain.
- **Punching a tree is not a thing.** Trees and boulders have no hand fallback.
- Nothing yields anything that came off a creature, and two tests assert it.
