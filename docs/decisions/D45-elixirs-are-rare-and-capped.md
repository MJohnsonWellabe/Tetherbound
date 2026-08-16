# D45 — Permanent stat elixirs exist, and they are rare and capped

**Date:** 2026-08-16 · **Decided by:** the owner, asked directly during the
playtest-repair session, against the potions board from their reference pack.

Kind: design

## The question that had to be asked

The owner's board shows six potions, and three of them are marked
**permanent**: Level Up, Attack Elixir, Defense Elixir. Nothing permanent
existed in the game — every consumable healed, fed or revived — and adding one
runs straight into `D37`:

> individuality rolls are real stat variance; **traits stay flavour, not
> balance**

`D37`'s whole point was that the player cannot farm a perfect creature. Stat
variance is rolled at catch time and is not something you can grind toward. A
permanent stat booster is, on its face, exactly the grind that decision
refused, which is why this was put to the owner rather than built quietly.

Asked with the trade-off stated, the owner chose **"both, permanent stays
rare"**: temporary tonics *and* a small number of permanent elixirs, scarce
enough to read as a prize.

## The decision

1. **A `kind: "elixir"` item permanently raises one stat on one creature.**
   `elixir_stat` is `hp`/`attack`/`defence` and `elixir_points` is raw stat
   points. Three ship: Elixir of Might (+6 attack), Elixir of Guard (+6
   defence), Elixir of Vigour (+12 max hp).

2. **Capped per creature, per stat.** `data/config/progression.json`'s
   `elixirs.cap_per_stat` (24, tunable) is the whole reason this does not
   reopen `D37`. Uncapped, coins plus patience convert straight into an
   arbitrarily strong creature. Capped, an elixir is worth hunting for and is
   never a substitute for levelling. `drink_elixir()` returns how many points
   were actually taken, so a creature at the cap refuses instead of silently
   eating the item.

3. **Flat points, added after the level curve.** Not a multiplier, and not
   folded into `stat_at_level`. A multiplier would compound with every
   subsequent level, making an early elixir worth more than a late one — which
   is precisely the "drink it as soon as possible, then grind" incentive the
   cap exists to remove. A flat +N is worth the same whenever it is drunk.

4. **Never sold.** They are deliberately absent from `data/config/trade.json`.
   The owner asked for permanent boosters to stay rare, and anything
   purchasable is only as rare as the player's coin pile. Elixirs belong to the
   world — a dungeon, a captain, the stronghold.

5. **They reuse the target picker.** "Which of yours drinks this?" is the same
   question `OF2` built for potions and `D44`/`OF29` reused for TMs. A fourth
   panel would have been a fourth thing to keep consistent.

## What this does NOT do

It does not touch individuality rolls, traits, or the level curve. `D37` stands
exactly as written: what a creature is *born* with is still not something the
player can farm. This adds a bounded, findable amount on top of that, and the
bound is the decision.

## What is still open

The board's **temporary** tonics (Swift, Stoneguard, Clarity) are not built.
The existing buff system (`scripts/player/player_vitals.gd`) is player-only —
it understands `stamina_regen_scale` and `move_speed_scale` and applies to the
trainer, not to a creature in a fight. Temporary *combat* buffs need a timed
modifier on `creature_instance` that `combat_math` reads, and that is a real
system rather than a data entry. It is the other half of the owner's "both",
and it is not done.

The three elixirs also share the potion icon rather than blocking on new art
(`D24`: no new asset family for three items). `tools/gen_item_icons.py` is
where bespoke ones would go.
