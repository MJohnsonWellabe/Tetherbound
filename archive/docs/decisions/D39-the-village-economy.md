# D39 — The village economy: coins for goods, creatures for creatures

**Date:** 2026-08-15 · **Decided by:** this firing, implementing `OF31` against
the owner's report and the owner's own answers to the questions it raised.

> *"Make the villagers so I can trade with them. Creatures and materials... Make
> one of the villagers the merchant. He has a store in his house. He'll buy and
> sell goods from you. Make the third whatever makes sense."*
> — the owner, 2026-08-15

The owner was then asked how trading should work, and answered: a **simple coin
currency**, and creature trades are **swaps**. Everything below either records
those two answers or follows from them. Number reserved as D39 by `OF31`'s
brief; D40–D43 already existed when it was written.

## The decisions

### 1. Money is a coin, and a coin is an ordinary item

`coin` is an entry in `data/items/items.json` like wood is. It stacks (999 to a
slot), it has an icon, it shows in the backpack, it saves through the same
inventory array, and it can be lost in a death satchel with everything else.

There is **no wallet**, no `coins` field on `game_state`, and no second store.
The moment currency lives somewhere other than the satchel, every screen that
shows the player's things has to learn about it separately, and "how much do I
have" becomes a question with two answers. `kind: currency` is descriptive only
— nothing branches on it (`item_db.gd`'s single kind branch is `tool`).

Which item the village counts in is itself data: `trade.json`'s `currency` key.

### 2. Prices are data, and `sell` is always less than `buy`

`data/config/trade.json` (new, tunable) holds per-vendor, per-item `buy` (what
the player pays) and `sell` (what the player is paid). Every price in the game
is in that file; `scripts/trade/trade_db.gd` reads it and no price literal
exists anywhere in `scripts/` or `autoload/`.

`sell < buy` for every entry, enforced by `tests/test_trade.gd` rather than by
good intentions: a vendor who pays more than they charge is an infinite coin
loop, and that is the one economy bug that ruins a save instead of annoying a
player.

The spread is wide (roughly 3–4× on materials) on purpose. Selling gathered
materials should be a trickle that bootstraps a first purchase, not an
alternative to gathering.

### 3. The player starts with a small float, handed over in dialogue

`OF31`'s brief offered two options — a zero start bootstrapped by selling, or
coins from Mira's first greeting — and asked for the friendlier one. **The
float wins.** A shop that opens for the first time and can sell you nothing you
can afford is a bad first impression of a system the owner asked for by name.

Thirty coins, given by `give:coin:30` on the line that says so, in
`village_mira_shop_intro` — the same "gift and the flag that records it are the
same line" rule D43 set for Tam. `trade.json`'s `starting_coins` and that
dialogue line are checked against each other by a test, because a line that says
thirty while the config says ten is a lie the player can count.

### 4. Creature trades are SWAPS, and the five-cap is structural

The owner chose swaps. Oskar offers one of his for one of yours; **no coins are
involved in a creature trade at all.**

This is what keeps both of CLAUDE.md's hardest rules intact without either being
special-cased:

- **"Player can own only five creatures total."** `creature_trade.swap()` is
  `party.remove_at()` then `party.add()`, in that order, in one function, with
  no path between them that can return early. The party size is identical before
  and after. A full party of five stays five and cannot become six — the cap is
  never even approached, because the party is at four for the width of two
  statements. There is no second cap check anywhere, and there must not be one.
- **"Trainer-owned creatures cannot be caught."** A swap is not a catch. No orb
  is thrown, no catch math runs, `pending_catch` is never touched, and the
  release ceremony is not involved. Oskar *hands his over*. The rule is about
  capture and is left exactly as it was.

Two rules of the swap's own, both stated in code rather than assumed:

- **You cannot trade your last creature.** An empty party is a soft-lock in
  everything but name. Nothing else in the game caps the party at one, so
  `swap()` says so itself and refuses with a sentence Oskar can speak.
- **One swap per rotation period.** Without it a player could hand over all five
  of their creatures in a single conversation and walk out with five copies of
  the day's offer. Nothing about the cap breaks if they do, but replacing a
  whole team in one conversation is not what the owner asked for. Recorded as a
  flat progression flag (D43's store), keyed by period so the flag rotates with
  the offer.

The offer itself is a pure function of the in-game day: `rotation_days` and an
ordered `offers` list, wrapping forever, with the individuality/trait rolls
seeded from the trader, the species and the rotation period. Re-opening the
panel cannot re-roll a better creature, and closing it to think does not lose
the one you were shown.

### 5. Who the three villagers are — and they keep their old lines

- **Tam** — the blacksmith, unchanged from `OF30`/D43. Tools and the orb recipe.
- **Mira** — the **merchant**, per the owner's instruction, with a store in her
  house (see 6).
- **Oskar** — the **creature trader**, which is the "whatever makes sense" third
  role: the owner asked to trade "creatures and materials", Mira has materials,
  and Oskar's existing Bridgehand identity (he keeps the crossing road, where
  strays turn up) already explains where his creatures come from.

**A role is added, never substituted.** Each of them keeps `greeting` — the
ordinary line NP3 wrote — and gains `greeting_when` branches ahead of it, the
ordered lookup table `OF30` built. This matters beyond tidiness: `SC12` makes
all three of them the Meadows' Band-1 trainers, and when it does, the **battle
offer is one more branch above the vendor branch** (a one-time `unless_flag`
entry), offered once and then falling through to the shop underneath it. The
vendor branch survives becoming a trainer. Nothing is rewritten.

`SC15`'s trainer payouts should pay **coins** alongside whatever else they give,
now that there is something to spend them on. That is `SC15`'s work, not this
one's; it is recorded here so the payout table is not invented twice.

### 6. Mira's cottage becomes the village's second real interior

"He has a store in his house" means the house has an inside. Villager cottages
were solid AABB bricks with painted-on doors (`village.gd`'s fallback collider).

`cottage_a` now authors its own colliders in `building_prefabs.json` with the
front doorway left as a real gap — the same answer the workshop's arch bay
already needed — and its shut door leaf is swung open, because a visibly closed
door standing in an opening you walk straight through is `village.gd`'s own
hologram warning from the other side.

Inside is `scripts/world/shop_interior.gd`, attached by `village.gd` from an
`interior` key in `village.json`: floor, counter, crates, a shelf and one warm
lamp. One room, deliberately. It follows `grandpa_house.gd`'s split (kit owns
the exterior, script owns the interior) without following its scale — Grandpa's
house cost an entire task because the opening happens in it; a shop the player
stands in for twenty seconds does not need a second storey.

Mira moved out of the square and stands behind her own counter.

### 7. `shop:` is a fourth dialogue effect

The director knew `beat:`, `give:` and `flag:`. It now knows
`shop:<goods|creatures>:<vendor_id>`, which opens a trading screen once the
dialogue box has closed — the same wait the starter picker already needed,
because effects are drained while the line carrying them is still on screen.

Two kinds because there are two genuinely different transactions, and the owner
settled them differently: `goods` is Mira's coin store, `creatures` is Oskar's
swap. The vendor id is a key in `trade.json`, so a second merchant is a data
entry plus a dialogue line, not a code change.

## What was deliberately NOT done

- **No storage.** Nothing here holds creatures anywhere but the party, and there
  is still no box, bank or reserve. CLAUDE.md: "Never implement creature storage
  beyond five."
- **No coin HUD.** Coins are in the satchel; the shop panel shows the count
  while you are shopping. A permanent purse readout is a HUD decision nobody has
  asked for.
- **No restock clock.** `stock` is in the data and is not depleted; the number
  is there so a future task can make it mean something without moving the data.
- **cottage_b is untouched.** It is still one AABB brick. One interior was the
  brief; three would have been a building task wearing an economy task's name.
