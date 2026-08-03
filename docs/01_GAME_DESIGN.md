# 01 — Game Design Document

**Version:** 0.1 (Meadows vertical slice)
**Platform:** Web, single build for phone and desktop, deployed to GitHub Pages
**Engine:** Babylon.js
**Players:** Single player, local save

See `docs/vision/00_EXECUTIVE_VISION.md` for the pitch this document
implements, `docs/02_ART_BIBLE.md` for how it should look, and
`docs/03_TECHNICAL_ARCHITECTURE.md` for how it's built.

---

## 1. Pitch

You inherit a set of Pact Orbs from your grandfather and walk out into the Meadows to cut down Team Tether. Tether has seized the eight ancient Halls scattered across the world and chained wild pals inside them as living generators. You survive off the land, build a base, befriend five pals, and take the Halls one at a time.

Valheim gives the world, the gathering, and the snap-grid building. Palworld gives the open map full of creatures you can approach on foot. Pokémon GO gives the combat feel and the throw. Pokémon gives the eight-badge spine and the starter choice.

The whole game is shaped by one rule: **you may only ever hold five pals.** There is no storage box. Taking a sixth means releasing one of the five, permanently, in the field.

---

## 2. Design Pillars

1. **Five slots, real cost.** Every capture is a decision with a casualty. No box, no bank, no take-backs.
2. **You never hold a weapon.** Tools chop, mine, and build. Pals fight. The player's only combat verb is the throw.
3. **The world is the difficulty.** Hunger, night, distance from your bed, and terrain do as much damage as any pal.
4. **Build fast, iterate.** Ship a playable loop before it is pretty. Placeholder capsules are acceptable in early milestones.

---

## 3. Story and Progression Frame

**Opening (Hollowbrook Village, Meadows).** Grandpa Orin Vale is too old to walk the Halls. He hands you a satchel, three Worn Pact Orbs, a stone axe, and a choice of three pals he has kept since his own walking days. He points east and tells you the Meadows Hall has been dark for six years.

**The loop.** Explore a biome, gather, build a base, catch and level pals, find the Hall, beat the Tether Warden holding it, cut the tethers. The freed pals scatter back into the wild, and one of them, the Warden's own chained pal, offers to join you. If your party is full you choose on the spot.

**Eight Halls, eight biomes.** Only the Meadows ships in v0.1. See `ROADMAP.md` for the rest.

**Team Tether.** Uniformed, bureaucratic, convinced they are managing a resource. Grunts wear grey and iron. They use collars, not orbs, and their pals fight at reduced affinity because of it. The Meadows Warden is **Bracken Holt**, a former ranger who took the job to keep the Halls from someone worse.

---

## 4. Player Character

- Third person, over the shoulder camera.
- Stats: **Health** (100), **Stamina** (100), **Hunger** (100).
- Carries a satchel with 24 inventory slots plus 5 pal slots.
- Cannot attack anything. Swinging an axe at a pal does nothing.

### Survival rules (middle tier)

| System | Behavior |
|---|---|
| Stamina | Drains on sprint, jump, swing, and building placement. Regenerates after 1.2s idle. Regen rate scales with hunger. |
| Hunger | Drains at 1 point per 45 seconds of real time. Eating restores hunger and applies a timed buff. |
| Starving | At hunger 0, health drains 1 per 3 seconds and stamina regen halves. |
| Fainting | At health 0 the player collapses and wakes at their last bed, or at Hollowbrook if none is set. |
| Faint penalty | All inventory items drop into a **Satchel** marker at the faint location, visible on the compass. Pals are never dropped. Equipped tools are never dropped. |
| Satchel decay | Satchels persist until collected. Only one satchel exists at a time; a new faint moves the old contents to the new marker. |

### Food buffs

Three food buff slots. Each cooked food grants one buff for a duration.

| Food | Effect | Duration |
|---|---|---|
| Berries | +8 hunger | none |
| Grilled Meat | +25 hunger, +20 max health | 10 min |
| Mushroom Skewer | +18 hunger, +15 max stamina | 10 min |
| Honey Bun | +20 hunger, +15% stamina regen | 12 min |
| Meadow Stew | +35 hunger, +30 max health, +20 max stamina | 20 min |

---

## 5. Pals

### Stats

Each pal has **HP, ATK, DEF, SPD** plus a species base stat block and a per-individual variance roll of ±10% applied at spawn and locked for life.

- Level range 1 to 50.
- `stat = floor(base * (1 + level * 0.035) * variance)`
- XP curve: `xpToNext(level) = 12 * level^1.6`
- XP awarded for a win: `18 * defeatedLevel * (typeAdvantage ? 1.1 : 1.0)`. All party pals get 40% of the active pal's award.

### Types

A five-element ring. Each type beats exactly one and loses to exactly one. Legible, easy to teach, and it makes gym counters matter without a chart.

```
Verdant → Tide → Ember → Stone → Spark → Verdant
(arrow means "is strong against")
```

- Strong: **1.6x** damage
- Weak: **0.625x** damage
- Neutral: **1.0x**

### Moves

Every pal knows exactly two moves, fixed by species. No move learning, no TMs, no swapping in v0.1.

- **Quick attack.** Available from level 1. Low power, ~0.5s cast, builds 12 charge.
- **Power attack.** Unlocks at level 8. High power, requires 100 charge, ~1.1s wind-up with a visible tell.

Move power values live in `data/species.json`. Quick attacks land in the 8 to 14 power band, power attacks in the 40 to 70 band.

### Affinity

Each pal has an affinity value from 0 to 100 that rises with wins and eating and falls when it faints. Above 75 it grants +8% damage. Below 25 it will occasionally hesitate on a power attack. This is the emotional cost of the five-slot rule.

### Party rules

- Hard cap of **five**. Enforced everywhere, no exceptions, no override.
- At a sixth capture the game pauses and presents the six-way roster. The released pal plays a short farewell and despawns into the world permanently.
- Released pals never return, even if the same species is caught later.
- A pal at 0 HP is **fainted**, not lost. It revives at a campfire or over 4 minutes of real time.
- If all five faint, the player is forced to retreat and cannot start a Hall fight.

---

## 6. Meadows Species Roster

Three starters plus twelve wild species.

### Starters (Grandpa's choice)

| Name | Type | Read |
|---|---|---|
| **Bramblit** | Verdant | Bramble-backed hare. Tanky, slow, high DEF. |
| **Cindercub** | Ember | Ash-furred fox kit. Glass cannon, high ATK. |
| **Dewdrake** | Tide | Dew-slick newt. Balanced, high SPD. |

### Wild roster

| Name | Type | Rarity | Level band | Notes |
|---|---|---|---|---|
| Tuftmoth | Verdant | Common | 2-6 | Tutorial catch. Very high catch rate. |
| Pebblit | Stone | Common | 2-7 | Slow, chunky, common near rock formations. |
| Sparrowick | Spark | Common | 3-8 | Fast, low HP, flees quickly. |
| Grazehorn | Verdant | Common | 4-9 | Herd spawner, spawns in groups of 3. |
| Rillnewt | Tide | Common | 3-8 | River banks only. |
| Emberhop | Ember | Uncommon | 5-10 | Dawn and dusk spawns only. |
| Thistleback | Verdant | Uncommon | 6-12 | Counterattacks on quick attacks. |
| Cragpup | Stone | Uncommon | 6-12 | High DEF, low SPD. |
| Voltvole | Spark | Uncommon | 7-13 | Burrows, hard to hit, low catch rate. |
| Mirefin | Tide | Uncommon | 8-14 | Night spawn near water. |
| Ashmane | Ember | Rare | 10-16 | Territorial, aggros on sight. |
| **Loamking** | Stone | Field boss | 18 | Single fixed spawn at the Meadows standing stones. Guaranteed re-spawn every 3 in-game days. |

Base stat blocks, catch rates, move assignments, and spawn weights all live in `data/species.json`. Do not hardcode any of it.

---

## 7. Encounters and Combat

### Approach

Pals roam the open world with simple state machines: wander, graze, flee, aggro. Walking within 4 meters of a pal or hitting the interact button triggers **Combat Mode**. Aggressive species trigger it themselves at 10 meters.

Combat Mode is not a separate scene. The camera pulls into an arena framing, the terrain stays live, a ring of soft fog marks the arena bounds, and the HUD swaps. This keeps loading at zero and preserves the open-world feel.

### Combat Mode

Real time. No turns.

| Input | Phone | Desktop |
|---|---|---|
| Quick attack | Tap the pal | Left click |
| Power attack | Hold to charge, release | Hold left click, release |
| Dodge | Swipe left or right | A / D or Space |
| Throw orb | Tap the orb button, then drag-and-release to arc | Right click and drag |
| Swap pal | Tap a party slot | 1-5 |
| Flee | Hold the back button 1s | Hold Esc 1s |

- Your active pal auto-faces the enemy and closes distance on its own. The player never controls pal movement.
- The enemy telegraphs its power attack with a 0.6s color flash. A correctly timed dodge negates it entirely.
- Damage: `dmg = (ATK / DEF) * movePower * typeMult * affinityMult * rand(0.9, 1.1) * (1 + 0.02 * levelDiff)`
- Swapping costs a 1.5s vulnerability window.

### The Throw

Throwing is always available, in any fight, at any moment, including the opening second. That is a core promise of the design.

- Drag-and-release arc, with a trajectory preview line.
- A catch ring pulses inward on the target. Releasing while the ring is small grants a **ring bonus**.
- Catch formula:

```
base      = species.catchRate            // 0.05 to 0.60
hpTerm    = 1 - (currentHP / maxHP) * 0.75
levelTerm = clamp(1 - (palLevel - highestPartyLevel) * 0.03, 0.35, 1.0)
ringBonus = 1.0 | 1.3 (good) | 1.7 (great)
statusMod = 1.0 | 1.25 (staggered)
chance    = clamp(base * hpTerm * levelTerm * ringBonus * ballMod * statusMod, 0.01, 0.95)
```

- Three shake animations, then break or hold.
- A failed throw costs the orb and gives the enemy one free attack window.

### Orb tiers

| Orb | ballMod | Craft cost |
|---|---|---|
| Worn Pact Orb | 1.0 | 3 fiber, 1 stone |
| Keen Pact Orb | 1.6 | 3 fiber, 1 flint, 1 leather |
| Truestone Orb | 2.4 | 2 leather, 1 amber, 3 stone |

### Flee behavior

Wild pals flee at 20% HP with a 25% per-second chance. Fleeing ends combat with no rewards. This creates real pressure to throw early instead of grinding the enemy down.

---

## 8. Gathering, Crafting, Building

### Meadows resources

Wood, Stone, Flint, Fiber, Berries, Mushrooms, Raw Meat, Leather, Feather, Amber, Honey.

### Tools

| Tool | Use | Recipe |
|---|---|---|
| Stone Axe | Trees | 4 wood, 2 stone |
| Stone Pick | Rocks, ore | 3 wood, 4 stone |
| Hammer | Building mode | 3 wood, 2 stone |
| Flint Knife | Skinning, fiber | 2 wood, 2 flint |

Tools have durability. They are never usable on pals or on people.

### Stations

- **Workbench.** Unlocks tier 1 recipes. Requires a 10m build radius and a roof for tier 2 recipes.
- **Campfire.** Cooking, warmth at night, revives fainted pals over 30 seconds each.
- **Bed.** Sets respawn point. Sleeping skips to morning if all nearby threats are clear.
- **Tanning Rack.** Leather from hide.
- **Orb Bench.** Crafts Keen and Truestone orbs.

### Building

Valheim-style snap-grid pieces. No structural integrity in v0.1, which is a deliberate scope cut. Piece sockets snap to the nearest valid connection point within 0.5m, with rotate and elevation nudge controls.

**Wood tier:** floor, wall, half wall, doorway, door, window wall, roof 26°, roof 45°, stair, pole, beam, ladder.
**Stone tier:** floor, wall, arch, pillar, stair.

Building requires the hammer equipped, which opens a radial piece menu. Placement costs stamina. Pieces can be removed for a 50% refund within 60 seconds of placement, 25% after.

---

## 9. World

**Seeded procedural.** One seed string generates the whole Meadows. Same seed always produces the same world, which makes bug reports reproducible and lets players share seeds.

- Simplex-noise heightmap, chunked at 64m, view distance 5 chunks, LOD at 3 chunks.
- Biome mask carves meadow grassland, sparse oak groves, rock outcrops, a river system, and pond basins.
- Poisson-disk scatter places trees, rocks, bushes, and flowers per chunk from a deterministic per-chunk RNG derived from the world seed and chunk coordinates.
- Spawn tables are per chunk-type and per time-of-day. Density caps at 12 active pals within view distance.

**Fixed points, seeded placement.** Hollowbrook Village always sits at world origin. The Meadows Hall is placed at a seeded angle, 900 to 1200 meters from origin, always on flat ground, always with a road stub pointing back toward the village. The standing stones with the Loamking spawn at a second seeded angle at 500 to 700m.

**Day and night.** 20 real minutes per full cycle, 14 day and 6 night. Night raises spawn levels by 2 to 4, unlocks night-only species, and drops visibility hard. Campfire light matters.

---

## 10. The Meadows Hall

The first gym. A stone longhall with four chained pals visible in alcoves and Bracken Holt waiting at the far end.

- Two Tether grunts before the Warden, each a single 2-pal fight, both beatable at party level 10.
- **Bracken Holt** fights a 3-pal team: Cragpup L14, Thistleback L15, and his collared **Loamking L17**.
- His pals hit at 1.15x but their affinity penalty means they never dodge.
- You cannot throw an orb at a collared pal. The orb bounces with a distinct sound. This teaches that Tether's pals are not catchable and reserves the throw for the wild.
- On victory: cut-tether sequence, four wild pals scatter, and the Loamking's collar breaks. It offers to join at level 17. Accept and you either have a slot or you release someone right there.
- Reward: **Meadow Sigil** (badge 1), the Orb Bench recipe, and Truestone Orb unlock.

---

## 11. UI

**HUD:** health / stamina / hunger bars top left, party of five as portrait pips bottom center, compass strip at top, hotbar of 6 items bottom right on desktop and a swipe-up drawer on phone.

**Screens:** Party, Inventory, Crafting, Build radial, Map, Pal detail, Release confirmation, Save/Export.

**Release confirmation** is deliberately heavy. It shows the pal's level, affinity, time with you, and a two-step confirm. This screen should feel bad.

**Mobile first.** Every touch target is at least 44 CSS pixels. Nothing depends on hover. Test at 390x844 before testing at 1920x1080.

---

## 12. Save

- localStorage key `tetherbound.save.v1`, JSON with a `schemaVersion` field and a migration function per version bump.
- Autosave every 60 seconds, on Hall completion, on release, and on visibility change.
- Export produces a base64 string the player can paste into another device. Import validates the schema before overwriting and keeps one rollback slot.
- Saved: seed, player transform, stats, inventory, party with full pal state, released-pal ledger, structures, discovered map, badges, world time, day count.

---

## 13. Explicitly Out of Scope for v0.1

Multiplayer. Pal breeding. Pals performing labor or automation. Player weapons. Move learning or swapping. Storage boxes or pal banks. Mounts. Biomes two through eight. Structural integrity. Weather beyond a day/night tint.
