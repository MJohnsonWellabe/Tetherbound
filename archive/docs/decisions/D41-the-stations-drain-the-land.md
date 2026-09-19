# D41 — The stations drain the land, and beating the Warden frees the whole meadow

**Date:** 2026-08-15 · **Decided by:** the owner, in the same message that set
the chapter length (`D42`) — "I think part of the story is that team tethers
stations that are all along the road are pulling power out of the ground and
killing the area slowly. Then when we shut them down in the final battle in the
meadow stronghold it frees the whole meadow of that tether."

## The decision

Most of this is already canon. `MEADOWS_PROGRESSION_SPEC.md` §23 already has
Team Tether siphoning a legendary's energy to hold Tether Rifts apart, §29
already puts severed roads and ruined trade infrastructure on the seven spokes,
§32 already walks the player up a reveal ladder from "conduits in the quarry"
to "the legendary is the power source," and §27/§28 already collapse the Rift
when the Warden falls. This decision records the **three things the owner's
sentence adds on top of that**, and nothing else — it is an extension, not a
rewrite.

### 1. The drain is locally visible on the ground

The siphon stops being an abstraction the player is *told* about in dialogue
and becomes something they *see* underfoot. Ground and vegetation in a radius
around every Tether station, pylon and conduit run are visibly dying:
discolored, desaturated ground; suppressed, sparse or withered vegetation;
ground cover thinning out toward the machine and healthy meadow resuming
beyond it. "Killing the area slowly" is the owner's phrase and it is literal —
the land near the hardware is worse than the land away from it, and the player
can read that difference at a glance without a single line of dialogue.

This is **new vegetation and terrain work**, not a story flag. It needs a
drained-ground grammar — a terrain material treatment plus a vegetation
suppression rule around an authored point — reusable at every station rather
than hand-placed once. It lands with the Phase 8 content items that build the
stations themselves (`SD16` the quarry, `SE23` the relay, the Upper Meadows
pylons), first appearance at the quarry, strongest at the relay. It is
explicitly downstream of `D24`'s asset rules: this is material, texture and
scatter-density work on families that already exist, not new props.

### 2. The stations line the traveled roads, as an active network

§29 put Team Tether's fingerprints at the *edges* of the region — seven severed
spokes ending at Rifts, ruined gates, abandoned trade infrastructure, all of it
past evidence of an old severing. The owner's stations are the opposite: they
sit "all along the road," on the routes the player actually walks, every day,
from the first hour. They are present-tense machinery doing present-tense harm,
not ruins.

So the drain network is a thing the player travels *through*, not a thing they
find at the perimeter. This also explains, in-fiction, why Team Tether cares
about controlling the roads at all (§24's monopoly on movement gains a second,
concrete reason: the roads are where their hardware is), and it gives §32's
reveal ladder a physical spine — the same road, more stations, worse ground,
the closer the player gets to the stronghold.

The seven spokes are unchanged. This is additive: severed spokes at the
boundary, *and* a live drain network along the interior roads.

### 3. Killing the machinery frees the whole meadow, and the land heals

§28 already fails the Tether machinery after the Warden and triggers the
exterior reconnection event. The owner's addition is that the payoff is not
only the distant, non-enterable view of the next region (`SG44`) — it is
**local**. Shutting the stronghold down frees "the whole meadow of that
tether": the drained ground the player has been walking past for the entire
chapter visibly recovers. Color returns, suppressed vegetation comes back, the
dead radius around each station closes.

This is a beat inside §9's world-state change and belongs to `SG46`, alongside
the barriers deactivating and the villagers acknowledging the victory. It is
also the strongest single answer §9's "do not leave the region visually
identical" has: the player's own route home from the stronghold passes the
stations they walked past in hour one, and they are different.

The carve-out from `D23` and `CLAUDE.md` is untouched by this and is worth
restating, because "the whole meadow is freed" is exactly the kind of sentence
that could be misread as a licence: the healing is **inside the Meadows**. The
reconnection event remains a distant, non-enterable view. No Biome 2 terrain,
spawns or species.

## Why this is worth writing down rather than just building

Because the temptation is to treat it as flavour text and satisfy it with a
line of villager dialogue about "the machines poisoning the ground." That would
be cheap and it would miss the point. The owner described a **visual**
mechanism — something is being pulled out of the ground and the ground shows
it — with a **visual** payoff when it stops. If it never appears in the terrain
and the vegetation, the ending has nothing to heal and `SG46` loses its best
beat.

It is also worth writing down because it retroactively strengthens material
that already exists. §32's reveal ladder currently escalates through
*information* the player is handed at each site. With the drain visible, each
rung also escalates through *landscape*: the quarry's ground is a little wrong,
the relay's is badly wrong, the Upper Meadows pylon field is worst. The story
and the terrain say the same thing at the same time, which is the strongest
form the reveal can take and costs no new dialogue.

## What changes on disk

- `docs/specs/MEADOWS_PROGRESSION_SPEC.md` — pointers at §9, §23, §29 and §32. The
  prose is not rewritten; this doc is the extension.
- `docs/CURRENT_STATE.md` — implementation notes spliced into `SD16` (the quarry
  debuts the drained-ground grammar), `SE23` (the drain is strongest at the
  relay), `SG44` (the collapse frees the meadow, not only the far view) and
  `SG46` (the healing is part of the region's answer).
- Later, in code: a drained-ground treatment in the terrain material path and a
  suppression rule in `vegetation.gd`'s scatter, driven from the same authored
  station positions the props use. Not built by this decision.

## What it does not decide

The exact visual vocabulary — how far the dead radius reaches, whether the
ground discoloration is a texture blend or a vertex/material tint, whether
withered vegetation is a separate mesh variant or the existing meshes retinted
and shrunk. Those are `Phase 8` implementation calls, and `D24`'s one-nature-
family rule plus the no-new-generations directive already bound the answers.
Nor does it decide whether the healing is instantaneous at the moment the
machinery fails or resolves over the walk home; that is `SG46`'s call to make
once the effect exists and can be judged.
