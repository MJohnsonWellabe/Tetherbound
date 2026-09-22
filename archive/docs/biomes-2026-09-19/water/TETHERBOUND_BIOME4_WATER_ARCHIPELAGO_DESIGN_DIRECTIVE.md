> **Roadmap note, 2026-09-06:** this document is reproduced verbatim as
> supplied by the owner. Its own "Implementation" line below and its §1
> "Repo Alignment" describe the sequence in effect when it was written
> (Meadows → Cloudreach → Stormwood → a three-biome playtest/repair cycle →
> Water). The 2026-09-06 roadmap revision in `docs/DEVELOPMENT_ROADMAP.md`
> simplifies that sequence: Biome 4 (Stage B there) is built directly after
> Stormwood (Stage A), and the two-biome and three-biome audit/repair cycles
> are replaced by a single four-biome product audit and repair pass (Stages C
> and D) after Water is built. Everything else in this directive — the
> creative/gameplay contract itself — stands unchanged. Do not edit the body
> below to match the new sequence; treat this note as the authority on
> *when* Water is built, and the body as the authority on *what* Water is.

# TETHERBOUND --- BIOME 4: WATER ARCHIPELAGO DESIGN DIRECTIVE

**Status:** Future-biome owner direction\
**Biome:** 4 --- Water\
**Implementation:** Design only. Build only when the canonical roadmap
reaches Biome 4 (see the roadmap note above for the current sequence).

# Executive Summary

Biome 4 is an inhabited island-chain Water biome where the sea becomes
traversal, habitat, hazard, combat space, and progression.

The first half is built around **human swimming**. Swimming drains
stamina; at zero stamina, health begins draining. Swimming skill
improves through use and increases practical endurance. Early islands
are close enough for a low-skill swimmer. Progress is organized around
**NPC-controlled docks**: arrive, explore, meet/fight NPCs, complete the
local requirement, open the next meaningful departure point, and cross.

At the midpoint, the player fights a large original **amphibious Water
Dragon Alpha**. Its broad fantasy direction is an elegant, long-bodied
magical water dragon in the category of the imagery from *Raya and the
Last Dragon*, but it must not copy Sisu. It fights naturally on land and
in water, swims with its head and upper back exposed, and has a broad
back suitable for riding.

The Alpha guards a **Swim Stone**. Defeating it unlocks a **Swim
Saddle** recipe regardless of whether the Alpha is caught. The Alpha is
itself catchable and becomes the obvious premium first swim mount, but
it is not the only viable swimmer.

After the midpoint, island spacing expands. Human-only swimming becomes
impractical for intended progression and the player rides a compatible
swimming creature. The mount uses swim stamina and begins losing health
at zero stamina, mirroring the human rule.

Hostile amphibious creatures can attack during crossings. Active combat
**pauses swim-stamina drain**. The player dismounts, directly pilots a
creature under normal Tetherbound combat rules, then remounts afterward.

The global Skills system is introduced at the **start of Biome 2**, not
Water. Skills have accumulated through use since Meadows. The initial
skills are **Running, Catching, Riding, Swimming, Flying**. The player
may notice sprinting becoming easier during Meadows, then discovers why
when Biome 2 reveals the Skills menu. Swimming will likely still be
Level 0, foreshadowing Water.

Water introduces **black glowing Skill Candy I/II/III**, granting
+1/+2/+3 levels to a player-selected skill. All tiers remain black and
are distinguished through size, markings, shape, or glow intensity.

The finale requires the hardest mounted crossing to a large mountainous
island. The player lands, hikes upward, discovers a huge waterfall, and
finds Team Tether's Water stronghold **behind the waterfall and inside
the mountain**.

The biome preserves Tetherbound's loop:

> **Explore → encounter → fight/catch → choose → train → gather → care →
> prepare → overcome → push farther.**

Water adds:

> **Can my trainer and my five survive the crossing ahead?**

# 1. Repo Alignment

Current repo direction places the game at **Meadows → Cloudreach →
Stormwood → Water**. Water is intentionally downstream of a three-biome
owner playtest and systemic repair pass.

Preserve existing rules: the human never fights; creature combat is
directly piloted; only five creatures may be owned; traversal creatures
must justify permanent team slots; geography must be authored/readable;
exploration must reward detours; and a region is only complete when its
continuous player journey works.

Water must be built on the multiplayer-capable architecture when
implementation eventually begins.

# 2. World Fantasy

Water is an **archipelago adventure**, not an empty ocean. Use
settlement islands, beaches, coves, marshes, rocky islands, ruins,
reefs, waterfalls, cliffs, optional islands, Team Tether sites, an Alpha
island, remote post-saddle islands, and the mountainous final island.

The player should frequently look across the water and think: **What's
over there?**

Early water feels manageable. Mid-biome water feels consequential. Late
water feels like an expedition.

# 3. Water Creature Philosophy

Most Water creatures should plausibly work on land and in water. Avoid a
roster dominated by literal fish/sharks that look ridiculous on land.

Good categories include amphibious dragons, salamanders/newts,
turtle-dragons, crocodilians, frogs, crustaceans, otter/seal-like
fantasy mammals, water-buffalo forms, lake monsters with credible land
movement, and semi-aquatic reptiles.

Target roughly the established 10--12-creature biome scale later.
Several should be viable swim mounts.

Use the silhouette test: **remove color/VFX---does it still look like a
genuinely different species?**

# 4. Global Skills

Skills accumulate naturally through use from the beginning of the game
but are revealed at the start of Biome 2.

Locked initial skills: - **Running** --- sprint stamina
efficiency/endurance. - **Catching** --- restrained improvements to
physical catching. - **Riding** --- mounted stamina
efficiency/handling. - **Swimming** --- swim stamina
efficiency/endurance. - **Flying** --- flight stamina
efficiency/handling.

No Building or Gathering skill. Avoid a giant skill tree.

The Skills menu shows level, progress, how the skill improves, current
benefit, and next-level benefit. It must be controller-first and
handheld-readable.

# 5. Skill Candy

Water introduces: - **Skill Candy I:** +1 chosen skill level. - **Skill
Candy II:** +2. - **Skill Candy III:** +3.

All are black and glowing. Tiers differ through size, markings, aura
intensity, or shape complexity---not different colors.

They are rare exploration rewards for optional islands, secrets, hard
trainers, dangerous-current routes, hidden coves and memorable
encounters. Never silently waste levels at a cap.

# 6. Human Swimming and Drowning

Human swimming is available when Water begins.

1.  Enter water.
2.  Swim while stamina remains.
3.  At zero stamina, health begins draining.
4.  Reaching safe land ends immediate drowning pressure.

Zero stamina is not instant death. The transition to health loss needs
obvious feedback.

Higher Swimming skill improves endurance. Early gaps must be possible at
low skill.

Do not allow indefinite deep-water floating that fully restores stamina.

# 7. Creature and Mounted Swimming

Swimming compatibility is explicit species data, not inferred only from
Water typing.

Compatible creatures should swim with most of the body submerged,
head/face above water, and upper back visible where anatomy allows. A
saddled trainer remains visibly above the waterline.

Mounted swimming uses the creature's stamina. At zero stamina the mount
begins losing health. Mounted swimming is not infinite.

Recommended direction: trainer Swimming skill modestly benefits both
human and mounted swimming, while species traits/stats create meaningful
mount differences.

# 8. Water Combat

Hostile amphibious creatures may intercept crossings.

When combat starts: - traversal pauses; - player dismounts as
appropriate; - **swimming stamina drain pauses**; - player directly
pilots the active creature; - normal switching/catching rules apply; -
human never fights; - travel/remounting resumes afterward.

Use believable shallows, sandbars, exposed rocks, surface-water arenas,
or another readable aquatic presentation.

# 9. Currents

Currents are the secondary environmental hazard. They can push swimmers,
increase effective crossing distance, make return routes harder, create
protected channels, and enable risky shortcuts.

They must be visually readable through surface motion, foam, debris,
color/value, particles, sound, or shoreline effects. Avoid invisible
penalties.

Desired decision: **The direct route is shorter, but the sheltered route
is safer.**

# 10. Dock-Gated Progression

Major progression uses **controlled docks**.

NPCs, trainers, local leaders, or Team Tether control key departure
points.

Loop: **arrive → explore → meet locals/trainers → complete challenge →
open/earn next dock → cross**.

Do not use invisible swim walls. Reinforce gates through distance,
currents, cliffs, unsafe landing zones, Team Tether barriers, and
believable geography.

Vary dock objectives so every gate is not simply "beat one trainer."

# 11. First Half

Opening islands teach swimming, stamina, drowning, distance judgment and
safe landings using calm water and short gaps.

Early-middle adds longer crossings, mild currents, water encounters,
optional islands, stronger creatures and better detour rewards.

Before the Alpha, human crossings become uncomfortable enough that the
player naturally thinks: **There has to be a better way.**

# 12. Midpoint Alpha --- Water Dragon

The Alpha is locked as a **large amphibious Water Dragon**.

Broad inspiration: elegant long-bodied magical water-dragon fantasy
associated with *Raya and the Last Dragon*. The final creature must be
original Tetherbound art---not Sisu, Gyarados, a generic blue European
dragon, a fish, or a shark with legs.

Required qualities: - long elegant body; - memorable expressive head; -
credible amphibious land movement; - powerful swimming tail; -
fins/frills/crest; - broad rideable upper back; - four functional limbs
or another convincing land solution; - fast beautiful swimming; -
head/back visible above water; - strong combat identity.

The encounter occurs at a memorable land/water interface and
demonstrates both movement modes.

Defeating it grants the **Swim Stone regardless of catch outcome**. The
Alpha becomes a major catch opportunity and obvious premium mount, but
catching it cannot gate progression.

# 13. Swim Saddle and Second Half

The Swim Stone unlocks the **Swim Saddle** recipe through established
crafting.

Rideable creatures do not spawn permanently wearing saddles; the
equipped saddle appears visually.

After the unlock: - islands become farther apart; - currents
strengthen; - crossings become more exposed; - encounters become more
meaningful; - human-only swimming becomes impractical for intended
progression.

Add remote secrets, isolated trainers, high-value Skill Candy, stronger
predators, deep-water habitats and increased Team Tether presence.

# 14. NPCs, Preparation and Rewards

Use believable island roles: dock keeper, fisher, trader, swimmer,
trainer, researcher, resident, settlement leader, stranded traveler,
Team Tether grunt/officer.

NPCs teach currents/geography, identify habitats, point toward optional
islands, gate docks and advance story.

Crossings should make existing preparation matter: stamina, food buffs,
healing, revives, creature condition, camps/rest and team composition.

Optional islands should generally reward exploration better than holding
the critical path. Rewards can include Skill Candy, creature candy,
healing, resources, TMs, recipes, rare creatures, shortcuts and world
information.

# 15. Team Tether Escalation

Team Tether increasingly controls the water network through occupied
docks, pumps, sluices, pipes, patrol platforms, cages, flooded ruins and
current-control machinery.

Do not industrialize every island. Escalation should grow toward the
final island.

# 16. Final Island and Stronghold

The final fortress is not a castle visible from sea.

The player completes the hardest mounted crossing to a large mountainous
island, lands low, receives a final preparation opportunity, travels
inland, climbs the mountain, encounters stronger Team Tether resistance,
hears/sees a major waterfall, reaches it, and discovers a passage behind
it.

The Team Tether stronghold is **inside the mountain behind the
waterfall**.

Its identity should use wet cave/ruin architecture, channels, pumps,
sluices, dripping stone, elevated walkways, partially flooded spaces and
machinery manipulating water flow. Keep it compact enough to preserve
pacing.

# 17. Legendary and Water Blessing

The Water legendary remains open for later creature design.

After victory, Team Tether's local tether is disabled, the legendary is
freed, the region visibly responds, and the legendary/talisman
progression follows the established regional monument philosophy.

Recommended Water blessing:

## Tidal Guard

**Reduce incoming damage by approximately 10% while active.**

Defense fits Water's resilience theme and is less likely than a global
damage boost to become the automatic best blessing. Exact tuning remains
open.

# 18. Multiplayer Requirements

Future implementation must support 1--4 players from the start,
including replicated swimming, drowning state, mounted swimmers,
rider/mount sync, water combat transitions, players taking different
routes, dock/world authority, Alpha state, Swim Stone unlocks, Skill
Candy ownership, final-island progression, and save/reconnect across
different islands.

Do not build a single-player swimming architecture that later requires
replacement.

# 19. Visual Direction

Target the established achievable stylized quality: colorful, readable,
cohesive, Palworld/Fortnite-adjacent---not ultra-dense fantasy concept
art.

Use turquoise/deep-blue water variation, readable currents, shoreline
vegetation, wet rock, reeds, beaches, waterfalls, distant mountains and
strong island silhouettes.

Avoid making every Water asset blue or glowing.

The final mountain should be a memorable distant landmark long before it
becomes reachable.

# 20. Do Not Add

Do not automatically add: - player boats as core traversal; - oxygen
meter; - underwater survival simulation; - required diving; - underwater
base building; - thirst; - universal wetness punishment; - grappling
hooks; - fishing minigame unless separately approved.

Water already introduces enough: swimming, drowning, currents, mounted
swimming, water combat and Skill Candy payoff.

# 21. Future Tuning Questions

Leave for implementation/playtesting: - swim stamina/health drain
rates; - Swimming XP curve/caps; - Skill Candy frequency; - current
strength; - exact island count/distances; - mount stamina formulas; -
exact Tidal Guard value; - Water Dragon name/stats/moves/catch rate; -
legendary design; - Warden/captain roster.

# 22. Completion Bar

Water is not finished because swimming code exists.

A complete biome must prove a continuous player journey in which: -
early human swimming is understandable and fair; - Swimming skill
visibly improves; - drowning creates pressure without cheap deaths; -
currents are readable; - docks create believable progression; - optional
islands reward curiosity; - the Alpha is memorable and desirable; - Swim
Saddle changes traversal dramatically; - swimming creatures create
genuine five-slot roster pressure; - water encounters work without
stamina punishment during combat; - late crossings feel like
expeditions; - the final island is a recognizable destination; - the
waterfall reveal lands; - the hidden stronghold feels specific to
Water; - the legendary climax pays off the chapter; - multiplayer,
save/load and target-hardware performance work.

# 23. Later Design Deliverables

Before implementation, create separate approved documents/art for: 1.
Water world/island map and dock progression. 2. Full Water creature
roster. 3. Water Dragon Alpha production board with full Meshy
orthographic views. 4. Swim Saddle production board. 5. Skill Candy
I/II/III board. 6. Water NPC/Team Tether visual additions. 7.
Final-island/waterfall stronghold concept board. 8. Water legendary and
Warden/finale design. 9. Numeric swimming/skills/currents tuning spec.
10. Multiplayer swimming authority/state spec.

This document is the high-level creative/gameplay contract those later
deliverables must implement.
