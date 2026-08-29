# Tetherbound — Meadows Creature Expansion Implementation Brief

**Status:** Owner-authored direction, supplied 2026-08-30, reproduced verbatim.
**Reference art:** `docs/art/reference/creature-expansion-2026-08-30/` — one master
sheet plus nine per-creature sheets, all owner-supplied with this brief.

Under `CLAUDE.md`'s precedence rules this is a newer owner directive.

## Two standing rules this directive explicitly changes

`CLAUDE.md` says **"No new creature meshes or Meshy generations for Meadows"** and
**"Never spend a Meshy generation without owner-supplied reference art."**

- The first is **superseded for the nine creatures named here, and only for
  those.** The owner has directed new Meshy creatures by name, with a build path
  per creature. It is not a general licence to add creatures.
- The second is **satisfied, not waived.** Reference art now exists, vendored
  beside this file. It still binds for anything else.

Every other hard rule in `CLAUDE.md` stands unchanged — five creatures total, no
storage or sixth slot, the human never fights, trainer creatures uncatchable,
established starters and Team Tether canon, no Biome 2.

---

## Purpose

Expand the Meadows creature population beyond its current Ground-heavy roster by introducing a small number of rare elemental wanderers and special variants.

The Meadows remains the **Ground-dominant biome**. These additions should make the world feel connected to the future Fire, Electric, Ice, Psychic, and Dark regions without diluting the Meadows identity.

These creatures should feel like discoveries.

Do not make them common ambient wildlife.

The player should be able to spend significant time in the Meadows without seeing most of them.

---

# Core Rarity Structure

Use roughly these population expectations:

### Common
Normal Meadows roster. These make up the overwhelming majority of wild encounters.

### Uncommon
Noticeably rarer than normal creatures, but a player exploring thoroughly will eventually encounter them.
Approximate target: 5–10% of eligible habitat encounters.

### Rare
Something the player remembers finding.
Approximate target: 1–3% of eligible habitat encounters. Usually habitat, weather, time, or progression constrained.

### Exceptional / Alpha
Extremely noticeable encounters.
Approximate target: Well below 1% of ordinary wildlife opportunities. Prefer authored or semi-authored spawn logic over random saturation. Do not allow several elemental Alphas to be visible simultaneously in one area.

These numbers are directional rather than locked balance values.

---

# 1. NIGHTBURROW

**Nightburrow — Alpha Burrowback.** Type: **Ground / Dark**.
Build path: **Existing Burrowback model + recolor + modest resize + emissive materials + VFX**. Do NOT attempt a complete Meshy redesign.

## Role
Nightburrow should be one of the most visually dramatic wild creatures available during the Meadows chapter. It is not simply "large Burrowback." It should immediately communicate that the player has encountered something abnormal.

## Visual requirements
Use existing Burrowback as the base. Changes:
* approximately 15–25% larger than standard Burrowback
* charcoal / nearly black body
* darker stone armor
* strong purple emissive cracks through armor
* bright glowing purple eyes
* purple flame / shadow-flame VFX rising from back and armor seams
* subtle purple particles around paws
* optionally slightly enlarged stone plates if technically inexpensive

The purple flame effect is important. Without emissive/VFX treatment, this variant is not successful.

## Location
Primary habitat: **Burrow Warrens / cave-mouth country**. Potential locations: deeper Burrow Warrens sections, cave entrances, rocky ravines, abandoned dens, old ruined areas near the Warrens route.

It should NOT roam openly through Grandpa's starting fields.

## Time
Primarily **night**. Optional: dusk, overcast/storm conditions at much lower probability.

## Rarity
**Exceptional Alpha.** Recommended structure:
* one active Nightburrow maximum in the Meadows at a time
* respawn after a meaningful interval rather than immediately
* rare enough that many players will hear about or notice evidence of it before actually finding one

Approximate encounter rarity: **0.25–0.75% of qualifying Burrowback-area spawn opportunities**. Alternatively, use a semi-authored roaming Alpha spawn system rather than pure percentage RNG.

## Level / danger
Should substantially outlevel normal Burrowback encounters for the same area. It should be dangerous when first encountered. Do not level-scale it to the player.

## Behavior
Territorial; prowls rather than grazing; becomes aggressive at a larger detection radius than normal Burrowback; should feel like an apex cave/warren encounter.

---

# 2. STORMTRAIL

**Stormtrail — Alpha Trailpup.** Type: **Ground / Electric**.
Build path: **Existing Trailpup model + recolor + modest resize + emissive markings + electrical VFX**.

## Visual requirements
Preserve Trailpup silhouette. Changes:
* roughly 10–15% larger
* darker storm-gray / brown coat
* bright yellow-gold lightning markings
* electric-blue eye glow
* sparks around paws
* occasional electricity moving over coat/tail
* slightly raised/spiked fur silhouette if achievable through materials or simple geometry

Do not overbuild this asset. Most of its identity should come from **color + emissive + electricity**.

## Location
Open-country creature. Eligible: exposed trails, ridgelines, meadow clearings, old Tether machinery, damaged pylons or structures, lightning-struck trees. Should not spawn deep inside forests.

## Weather
Strongly tied to **storms / thunderstorms**. Ideal rule: extremely rare normally, considerably more likely during storms.

The player should learn: **storms are worth exploring.**

## Rarity
**Rare Alpha.** Approximate: 0.5–1% under normal qualifying conditions; 3–5% during qualifying storm conditions. Only one Stormtrail should normally occupy a local spawn cluster.

## Behavior
Fast; restless; patrols a larger radius than normal Trailpup; more likely to challenge/flee dynamically rather than stand idle.

---

# 3. SPARKIT

**Sparkit.** Type: **Electric**. Build path: **NEW MESHY CREATURE**.

## Role
Sparkit is the first normal species that gives the player a meaningful taste of the Electric region. It is a **wanderer**, not a native dominant Meadows species. Noticeably smaller than large combat creatures but NOT tiny or difficult to see. Target size: roughly large fox / small coyote scale.

## Visual identity
Cream + yellow-gold + graphite; oversized readable ears; strong tail silhouette; lightning-shaped tail tip; bright blue eyes; small electrical VFX when excited; simple broad forms suitable for Meshy. Avoid tiny fur details.

## Location
Open Meadows and disturbed technological areas: grasslands, trails, old power/Tether infrastructure, ruined equipment, exposed hilltops.

## Weather
Spawn bias toward storms, immediately after storms, cloudy weather. Can appear rarely in ordinary weather.

## Rarity
**Uncommon-to-Rare Wanderer.** Suggested: ~2% ordinary eligible spawn chance; 5–8% during storms. Substantially rarer than Bramblebun, Trailpup, Mudsnout.

## Social behavior
Solo or pairs. Avoid large packs.

## Gameplay niche
Fast Electric attacker. Noticeably quicker and more aggressive than most early Ground creatures.

---

# 4. CINDERCUB

**Cindercub.** Type: **Fire / Ground**. Build path: **NEW MESHY CREATURE**.

## Role
A young Fire-region creature that occasionally wanders or follows warm geological corridors into the Meadows. Gives Fire representation without turning Meadows wildlife into Fire-biome wildlife.

## Visual identity
Terracotta / rust coat; dark soot-colored paws; orange eyes; subtle ember cracks; glowing tail tip; occasional tiny embers; compact sturdy mammalian silhouette.

Do not cover the entire creature in flame. The fire treatment should feel contained and believable.

## Location
Only around sources of warmth: scorched clearings, burned trees, warm rock formations, old fire pits, geothermal-looking terrain if present, later-game Team Tether industrial areas. Avoid normal wetland/pond spawning.

## Time
No strict restriction. Possible minor bias toward late afternoon and evening.

## Rarity
**Rare Wanderer.** Approximate: **1–2% of qualifying warm-area wildlife spawns.** Much rarer than native Meadows creatures.

## Behavior
Curious; moderately territorial; not automatically hyper-aggressive; sometimes resting/sleeping near warm objects. This creature should have personality rather than simply functioning as an enemy.

---

# 5. SHADELET

**Shadelet.** Type: **Dark**. Build path: **NEW MESHY CREATURE**.

## Size
Important: Shadelet should NOT be tiny. Target: roughly monitor-lizard / medium dog length. It must read clearly from normal gameplay camera distance.

## Visual identity
Midnight-black/navy scales; subtle violet sheen; oversized amber/gold eyes; curling tail; broad readable head; some raised ridge/spine forms; minimal subtle shadow VFX if needed. Avoid making it look like a generic tiny gecko.

## Location
Dark sheltered areas: cave mouths, large fallen logs, shaded rock fields, ruins, dense forest edges, Burrow Warrens perimeter.

## Time
Strong preference: **dusk and night.** Significantly reduced chance during full daylight.

## Rarity
**Uncommon nocturnal wanderer.** At night: roughly **3–5% of qualifying dark-habitat spawns.** During daylight: close to zero except inside caves or deeply shaded locations.

## Behavior
Cautious; stalks around cover; may freeze and watch player; moderate aggression rather than charging immediately.

---

# 6. BRAMBLEBUN — FULL REDESIGN

**Bramblebun.** Type: **Ground**. Build path: **REDO AS NEW MESHY CREATURE**.

Do not simply recolor or resize the existing Bramblebun. The existing implementation is visually too small and too generic. This is a replacement asset for the same canonical species.

## Design goals
Bramblebun should become a signature Meadows creature, recognizable from a distance. Increase its size substantially. Target: approximately large hare / small-medium dog body mass in-game. It should remain one of the smaller Meadows creatures, but not feel miniature.

## Visual identity
Oversized dramatic ears; visible plant/bramble growth; thorny vines; leafy cheek/shoulder forms; bramble tail or large plant-like tail tuft; sturdy paws; earth-brown, cream, muted green; small reddish thorn accents.

Avoid making the whole creature an unreadable pile of foliage. Silhouette comes first.

## Location
Native Meadows species. Very common in fields, brush, forest edges, berry patches, trails, Grandpa-region wilderness.

## Rarity
**Common.** One of the creatures players should encounter frequently. Because it is common, its redesign needs to be especially strong. It helps define the visual identity of the Meadows.

## Behavior
Cautious; hops/runs between vegetation; social in loose groups; may flee unless challenged.

---

# 7. PADDLENEWT PSYCHIC VARIANT

Working variant name: **Riftfrill.** Base species: **Paddlenewt.** Type: **Water / Psychic**.
Build path: **Existing Paddlenewt + recolor + emissive + VFX**.

This is NOT a new species unless later decided otherwise. Internally it may remain a Paddlenewt variant.

## Visual treatment
Preserve Paddlenewt's main silhouette. Changes: deeper teal/blue body; lilac/translucent frills; glowing pale eyes; cyan/violet body markings; subtle floating motes; gentle psychic/rift distortion effect. Avoid major geometry changes.

## Location
Very specific water environments: secluded ponds, still pools, strange springs, water near ancient ruins, water near Rift/Tether phenomena. Do not spawn in every ordinary stream.

## Time
Bias toward **dusk / night**.

## Rarity
**Rare Variant.** Approximate: **1% or less of qualifying Paddlenewt spawns.** Potentially higher around specifically authored mysterious pools.

## Behavior
Different from ordinary Paddlenewt: less skittish; watches player; occasionally pauses completely; may produce a subtle visual pulse. This should feel uncanny.

---

# 8. TUSKROOT FIRE VARIANT

Working variant name: **Ashtusk.** Base species: **Tuskroot.** Type: **Ground / Fire**.
Build path: **Existing Tuskroot + recolor + emissive + modest VFX**. Do not make another full creature asset unless the current Tuskroot model fundamentally cannot support the look.

## Visual treatment
Dark brown / soot-black body; basalt-like armor; orange glowing cracks; ember-glowing tusks; orange eyes; light smoke/ash particles; small embers.

The body should NOT be engulfed in flames. It should feel like a creature that has spent years around volcanic heat.

## Location
Very restricted: scorched terrain, warm stone, burned clearings, Team Tether industrial sites, possibly one authored location associated with a damaged Fire-region route.

## Rarity
**Rare Variant / mini-Alpha tier.** Approximate: **0.5–1% of qualifying Tuskroot opportunities.** Could also be handled as one or two semi-authored roaming individuals instead of ordinary RNG.

## Level
Higher than normal Tuskroot found in the Meadows. This should be a serious fight.

## Behavior
Highly territorial; slow patrol; strong warning behavior before charge; visually imposing.

---

# 9. FROSTCLAW

**Frostclaw.** Type: **Ice**. Build path: **NEW MESHY CREATURE**.

## Creature concept
Cold-weather feline based loosely on lynx, bobcat, snow leopard, panther. Do not make it an ordinary real-world cat with blue fur. It must read as a Tetherbound creature.

## Size
Medium-large predator. Target: roughly large lynx / small panther. Larger than Bramblebun and Sparkit. Smaller than the largest Alpha predators.

## Visual identity
Pale gray/white coat; slate markings; tufted ears; oversized paws; icy blue eyes; a few broad ice-crystal accents around shoulders/cheeks/paws; frosted whisker shapes; subtle visible cold mist; optional frost trail beneath paws.

Avoid covering it with hundreds of small crystals. Use a few large readable icy forms.

## Location
Frostclaw is NOT native to the central Meadows. It enters from the direction of the future Frozen Mountains / severed cold-region road. Spawn zone should be geographically constrained to that portion of the Meadows.

Potential places: colder highlands, rocky northern/elevated edge, near the severed road toward the Ice region, shaded higher-altitude terrain.

This is important because its presence should make ecological/story sense.

## Weather
Higher probability during rain, cold-looking weather, fog, unusual Rift/weather events if supported.

## Rarity
**Rare Wanderer.** Approximate: **1–2% of eligible cold-edge spawns.** Potentially one active Frostclaw in the broader Meadows region at a time.

## Behavior
Predator. Solitary; stalks prey; observes player from distance; territorial if approached; fast burst movement. Finding one should feel consequential.

---

# Meadows Population Philosophy

These nine additions should NOT replace the current Meadows roster.

The Meadows should still visually read as: **Ground biome with ponds, waterways and flying wildlife.**

Fire, Electric, Ice, Psychic and Dark creatures should be unusual enough that seeing one makes the player stop.

A normal traversal through the Meadows should mostly show Ground creatures, Water creatures near water, and Air creatures overhead.

The exotic elemental creatures should appear through geography, time of day, weather, specific habitats, rare spawn probability, and Alpha events — rather than being sprinkled randomly everywhere.

---

# Important Worldbuilding Principle

These creatures quietly foreshadow the larger world. The player should be able to encounter:
* Sparkit before reaching the Stormlands
* Cindercub before reaching the volcanic region
* Frostclaw before reaching the Frozen Mountains
* Shadelet before reaching the Dark region
* psychic Paddlenewt before reaching the Psychic region

Their presence helps communicate that these biomes used to be part of one connected landmass.

Do not explain that through UI text every time. Let ecology communicate it.

---

# Shiny vs Alpha vs Elemental Variant

Keep these concepts separate.

## Shiny
Same species. Same typing. Rare cosmetic coloration. Do not use shiny status to change typing.

## Alpha
Exceptional individual of a species. Generally larger, stronger, higher level, better combat/stat potential, visually distinguishable.

## Elemental / Aspect Variant
Rare individual whose environmental exposure changes its typing and appearance. Examples: Trailpup → Stormtrail; Burrowback → Nightburrow; Paddlenewt → Riftfrill; Tuskroot → Ashtusk.

Some Aspect variants may also be Alpha. Nightburrow and Stormtrail specifically should be treated as Alpha variants.

---

# Spawn Protection Rules

Do not allow rare creature saturation. Implement safeguards such as:
* one major Alpha within a local region at a time
* cooldowns after rare variant spawns
* habitat requirements
* weather requirements where appropriate
* time-of-day restrictions
* geographic restrictions
* weighted spawn tables rather than uniform random selection

Avoid a situation where the player walks through one clearing and sees Sparkit + Cindercub + Shadelet + Frostclaw + Nightburrow. That would destroy the rarity.

---

# Initial Priority

Implement in this order if work needs to be staged:

1. Bramblebun replacement
2. Nightburrow
3. Stormtrail
4. Sparkit
5. Cindercub
6. Shadelet
7. Frostclaw
8. Riftfrill/Paddlenewt variant
9. Ashtusk/Tuskroot variant

Bramblebun is first because it is a common species and therefore affects the visual quality of the entire Meadows.

Nightburrow and Stormtrail are next because they establish what an exciting Alpha can be.

The remaining creatures broaden elemental diversity and foreshadow later regions.
