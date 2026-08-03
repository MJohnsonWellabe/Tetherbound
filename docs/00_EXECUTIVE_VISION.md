# TETHERBOUND — Executive Vision

*Five pals. No box. No take-backs.*

A mobile-first, browser-based open-world survival-craft creature-collector in
the spirit of Valheim's building and gathering, Palworld's living world of
creatures, Pokémon GO's throw-to-catch combat feel, and Pokémon's eight-badge
spine. Built in Babylon.js, deployed to GitHub Pages, playable on a phone in
one hand.

You wake up in your family's house in Hollowbrook. Your grandfather can't
walk the Sacred Halls anymore, so you will. You're handed his axe, three
newborn pals to choose from, and a backpack of Pact Orbs from your mother on
the way out the door. From there the game is yours: gather, build, explore,
catch, and eventually free eight Halls' worth of chained pals from Team
Tether, one biome at a time.

This document is the pitch. The rest of `docs/` is the how.

---

## The one rule everything else serves

**You may hold five pals. Never six.** There is no storage box, no bank, no
second team waiting in reserve. Wanting a sixth pal means releasing one of
your five, permanently, in the field, with a screen designed to make that
decision feel exactly as heavy as it is. Every other system in this game
exists to make that rule matter: leveling makes a pal worth keeping,
affinity makes a pal worth keeping, and the open world keeps handing you
things worth catching so the choice never goes away.

If a proposed feature would soften this rule, it doesn't ship. This has
already ruled out storage boxes, breeding, and pal banking, permanently, and
that list is closed.

## The three promises

1. **The throw is always available.** From the first frame of any fight,
   against anything, you can throw an orb. No grinding an enemy to a sliver
   first. The tension is real-time: fight for position, or take the risk now.
2. **You never hold a weapon.** Tools chop, mine, and build. They cannot
   touch a living thing. Combat is something your pals do, not something you
   do to them.
3. **The world is the difficulty, not a damage sponge.** Hunger, distance
   from your bed, terrain, and night all cost you as much as any fight does.
   Survival and collection are the same game, not two games bolted together.

## Why this combination, and not just "Palworld but smaller"

Palworld gives you a living map and combat you initiate on foot, but pals do
labor and you carry guns. Pokémon gives you the eight-badge spine and a
starter choice that means something, but the world is a corridor and combat
is turn-based menus. Valheim gives you building and gathering with real
weight, but nothing to befriend. Pokémon GO gives you the single best
translation of "catching" into a physical, readable action anyone has built,
but it isn't attached to a world worth walking through.

Tetherbound takes the piece each of those does best and refuses the parts
that don't serve the five-pal rule. That's the whole design thesis.

## Scope discipline

Ship the Meadows first, completely, at the quality bar this document
describes, before any other biome is touched. Within the Meadows itself, the
same rule applies one level down: **quality wins over pace.** If a system
can't clear the critic loop in `docs/02_ART_BIBLE.md` in the time available,
the answer is to cut a different system, not to ship that one at a lower
bar. A vertical slice with fewer features that all look and feel like the
reference standard is worth more than a full feature list that looks like a
tech demo. See `docs/05_ROADMAP.md` for the milestone order and the full
eight-biome plan once Meadows is proven, and for how milestones are gated by
critic sign-off rather than a fixed schedule.

## The eight Sacred Halls, at a glance

Only the first row ships in v0.1. The rest is the roadmap, not a promise.

| # | Biome | Feel | New mechanic layered in | Warden | Sigil |
|---|---|---|---|---|---|
| 1 | **The Meadows** | Open grassland, oak groves, a river | *(the base game)* | Bracken Holt | Meadow Sigil |
| 2 | The Thicket | Dense dark woodland | Light radius matters, night predators | Marla Vess | Thorn Sigil |
| 3 | The Shoals | Coast, tidepools, sea stacks | Swimming and stamina drowning | Corin Bray | Salt Sigil |
| 4 | The Mire | Bog, fog, sunken ruins | Sinking terrain, poison status | Odalys Fen | Fen Sigil |
| 5 | Frostcrown | Alpine, snow, wind | Cold meter, insulated gear | Sten Aurr | Rime Sigil |
| 6 | The Dunes | Desert, canyons, night cold | Heat meter, water carrying | Nasrin Coale | Glass Sigil |
| 7 | Emberfell | Volcanic ash flats | Ash storms, heat damage zones | Roque Tallow | Cinder Sigil |
| 8 | Skyreach | Floating stone, high winds | Vertical traversal, updrafts | The Steward | Crown Sigil |

## Who this is for

Someone who wants the calm, physical satisfaction of chopping a tree and
building a shack, layered with the real emotional stakes of "do I keep this
pal or that one," played in short sessions on a phone, with enough of an arc
(eight badges) to know when they've finished something.

## What "done" looks like for v0.1

A stranger picks up a phone, plays cold with no explanation beyond the
opening scene, and: wakes up, meets Grandpa, picks a starter, walks into the
Meadows, chops a tree, builds a camp, catches a wild pal, loses one to a
sixth-catch decision at some point without hating the game for it, and beats
Bracken Holt at the Meadows Hall. If a stranger can do all of that without
being told how, and every system they touched along the way has cleared its
critic loop against `docs/reference/`, the vertical slice is done. Functional
but ugly does not count. If the two can't both be true on schedule, cut a
system, don't lower the bar on the ones that remain.
