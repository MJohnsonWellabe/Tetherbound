# D50 — The hoe gates tilling, and nothing else

**R7.6, 2026-08-16.** Owner-requested: a berry farm beside Grandpa's house,
and a hoe that preps ground for berry seeds.

## The question

`data/items/items.json`'s own header records that berries are **the one
resource with no `gathered_with`** — the only thing in the game that is never
tool-gated. Giving berries a farm puts a tool next to them for the first time,
and the backlog item flagged the consequence rather than letting it happen by
accident: a hoe would be the first tool gating a **planting** verb rather than
a gathering one.

Three answers were available, and they are not the same game:

1. **The hoe gates picking.** Berries gain `gathered_with: hoe`. Wild bushes
   and farm beds both stop paying out bare-handed.
2. **The hoe gates sowing.** Seeds refuse to go into the ground without it.
3. **The hoe gates tilling only.** It turns unworked sod into a seedbed and is
   never asked about again.

## The decision

**Three.** The hoe prepares ground. It gates nothing else, appears in no
item's `gathered_with`, and is named in exactly one place in code —
`scripts/world/farm_logic.gd::TILL_TOOL`.

Berries keep no `gathered_with` entry. Farmed berries are picked bare-handed,
exactly like wild ones, and items.json's line about them stays true.

## Why

**One is a nerf wearing a feature's clothes.** `GAME_DESIGN.md` §21 gives
Meadows farming four lines — "plant, wait, harvest", "no watering chores" —
and berries are the first food a player ever picks, before Grandpa has given
them anything. Requiring a crafted tool to eat off a bush makes the opening
worse to pay for a farm the player has not seen yet. It would also have
rewritten a rule the codebase states in its own data file, which is the kind
of quiet reversal that leaves two documents disagreeing.

**Two is a rule the player cannot see.** Sowing is not a physical struggle
against the ground the way breaking sod is; a hoe you must hold to drop a seed
into soil you already turned reads as an inventory check, not a tool. It also
gates the same door twice — the ground is already tilled, and only the hoe
could have tilled it.

**Three is what a hoe is for**, and it costs the player exactly one decision
per bed, once.

## The corollary that makes it work

**Harvesting returns a bed to `TILLED`, not to `FALLOW`.** The soil stays
worked; only the crop is gone.

This is load-bearing, not a detail. If a picked bed went back to fallow, the
hoe would be a durability tax paid on every crop forever — six beds × 40
charges means a hoe breaks every seven harvests, and repairing it is a walk to
a workbench. That is a chore, and §21 says this system does not have chores.
With the bed staying tilled, the hoe is a one-off cost per plot: six charges
out of forty, once, and then farming is seeds and sleeping.

## What this forecloses

Nothing in the spec. There is no crop that needs a different tool, because
§21 says "Meadows only needs berries initially" and §32 excludes *deep*
farming. If a later biome wants a tool-gated crop, `farm_plot.gd::_harvest`
already routes through `harvest_logic.gather()` — the shared body every other
gather in the game uses — so the yield, wrong-tool and durability rules would
apply the moment a crop item gained a `gathered_with`, with no new code. The
seam is left open; it is simply not used here.

## What it does not decide

Whether the equipped tool matters. It does not, anywhere in this game: R2.1's
gating has always asked what you **own**, not what is in your hand, and the
farm follows that. Swinging an axe at a fallow bed tills it if a working hoe
is in the satchel. Making the farm the one place where the held item matters
would be a new rule for every gather in the game, not a smaller one — see
`scripts/world/farm_plot.gd`'s header.
