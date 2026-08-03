# D04. Choose the creature pack first, then name the roster

Kind: conflict

`docs/GAME_DESIGN.md` §26 names twelve wild species by ecological role — rabbit,
boar, canine into wolf, rideable deer, badger, frog, turtle, otter, waterfowl,
small bird, owl, hawk — and then says "final names and exact models should be
chosen around the best cohesive asset set available."

Those two sentences are in the wrong order, and the second one loses.

## Why this is worth a record

The abandoned prototype did exactly this. It specified fifteen species by role,
then sourced models per role from whatever pack had something close. The result
was Kenney kit foliage standing next to Quaternius creatures next to Quaternius
buildings, and a blind visual critic's summary was that the world looked like
three art styles in one frame. Considerable time then went into tinting
individual models to hide a cohesion problem that no tint can reach.

§26 already hedges toward the right answer. This makes it binding.

## The rule

Before any creature is named or any stat block written:

1. Find packs containing **16+ rigged, animated creatures by one artist**.
2. Check each against the silhouette row on
   `docs/reference/tetherbound-meadows-keyart.png`: rabbit, boar, deer, raptor,
   turtle, canine. That row is the owner's own art direction and is the
   acceptance test.
3. Confirm every candidate carries the animations its role needs — idle, walk,
   run, attack, hit, faint — before judging how it looks. A creature that looks
   right and cannot faint is not usable.
4. Import three into the engine under one directional light at real scale
   before committing to the pack. Store pages are lit to flatter.
5. Then name the roster from what the pack actually holds, and update §26 to
   match rather than forcing the pack to match §26.

## Cost

The roster in §26 is a good ecological spread and some of it will not survive
contact with a real pack. That is the trade: species names are cheap to change
and visual cohesion is not.
