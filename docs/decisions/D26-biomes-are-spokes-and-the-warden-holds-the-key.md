# D26 — Biomes are spokes off the Meadows, and the Warden holds the key

**Status:** accepted — owner's design, stated verbatim during the first playtest
**Decided by:** owner, 2026-08-05
**Amends:** `GAME_DESIGN.md` §7 (world structure) and §9 (biome spine)

## The owner's words

> "Beating the warden will give you a key to unlock a bridge which will take
> you to the next biome. Each biome will connect to the meadows as a spoke."

## What this settles

`GAME_DESIGN.md` §9 lists eight biomes but does not say how they connect.
§7 asks for "authored macro geography" and gates fast travel, but leaves the
topology open. This closes both:

1. **Hub and spokes.** The Meadows is the hub. Every other biome connects to
   the Meadows directly, as a spoke — not as a chain where biome 4 is reached
   through biome 3. Coming home is always one crossing, which matters for a
   game whose home, beds, and stronghold-recovery loop all live in the hub.
2. **Progression is a key, not a level check.** Beating a region's Warden
   yields a key; the key unlocks the bridge to a next biome. This is the
   anti-"UI level gate" answer §2 wanted: the gate is a fight you can see,
   against a boss who is holding the thing you need.
3. **The bridge is geography.** A locked bridge at the Meadows' edge is
   visible long before it is passable — the same grammar as the stronghold
   on its bluff: you can see where the story goes before you can walk there.

## What the slice builds, and what it must not

In scope now: the Warden drops the key on defeat; a bridge exists at the
Meadows edge, locked, with words on it; the key unlocks it; crossing it shows
a vista and a "the next region is beyond the slice" boundary.

**Not in scope, hard rule:** any Biome 2 content. CLAUDE.md forbids Biome 2
work until the Meadows passes its exit gate. The bridge is the promise, not
the place.

## Consequences worth writing down

- The key is an ITEM (`items.json`), so it lives in the inventory, survives
  the save round-trip, and — deliberately — is NOT dropped in the death
  satchel (`death.keeps` gets its first entry; a progression key behind a
  corpse run gates the whole game behind one walk).
- Eight biomes ⇒ eight Wardens ⇒ eight keys, all spoke-gated from the hub.
  Which spokes exist and in what order players take them is intentionally
  unfixed — spokes make order optional by construction, which §27's
  "geographically rising danger" must account for per spoke rather than
  globally.
- The word "bridge" is the owner's. Whether a given spoke's crossing is a
  literal bridge, a pass, or a tunnel is art direction per biome; the locked
  crossing + key + Warden grammar is the invariant.
