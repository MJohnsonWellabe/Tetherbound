# PW2 — Alpha / elder wild variants across Meadows regions

## Goal
Add occasional memorable **alpha/elder versions of existing Meadows wild species** as regional encounters. They must feel behaviorally different, not merely like the same creature scaled up with more HP.

## Hard constraints
- **No new Meadows creature meshes or Meshy generations.** Use installed species meshes.
- Alpha/elder is an individual/world variant, not a new species in the roster.
- Preserve catching rules: wild creatures remain catchable unless a specific existing rule says otherwise.
- Do not make shiny and alpha synonymous; shiny remains cosmetic rarity.

## Placement
Coordinate with MQ3 as Bands 3–5 are authored. Target at least one memorable alpha/elder encounter per major region where it makes ecological/progression sense, while keeping early Band 1 encounters appropriately approachable.

Avoid identical circles of "boss creature" every fixed distance. Use habitat and world context.

## Required differentiation
Every alpha/elder must have at least one **behavioral or encounter distinction** beyond stats/scale, selected from systems that fit the species and existing combat architecture:
- more aggressive engagement radius/temperament;
- different attack cadence or move selection using existing moves;
- pack/nest/group behavior;
- unusual habitat positioning/environmental advantage;
- time/weather appearance;
- territorial patrol/arena behavior;
- a legal move variant appropriate to the species.

A modest visual scale increase and higher level/stats may reinforce the encounter but cannot be the only distinction.

## Data model
Prefer a data-driven per-spawn/per-variant descriptor layered on existing species/wild spawn machinery. Reuse `creature_instance` individuality and encounter director rather than creating an AlphaSpecies database.

Variant fields should be explicit and tunable: level band/bonus, scale, behavior overrides, spawn/time gate, optional move override, reward/XP modifier if current systems support it.

Do not alter hitboxes merely because visual scale changes unless current creature collision already derives safely from scale and is verified. Cosmetic scale should not create invisible reach discrepancies.

## Readability
A player should recognize that this is an unusual individual before or very early in combat. Use restrained existing tools: size, nameplate prefix/title, posture/VFX/palette treatment if supported, habitat and behavior. Do not use shiny palette as the alpha marker.

## Rewards
The encounter should be worth seeking through normal systems: higher XP, a strong catch opportunity, regional resource drop only if existing wild reward plumbing supports it. Do not invent a separate loot economy.

## Preserve
- real-time piloted combat;
- existing species moves/types/evolution links;
- five-creature cap;
- wild catchability;
- seeded/reproducible spawn behavior where current spawns are deterministic;
- Ally performance.

## Acceptance criteria
1. Multiple regions contain deliberately sited alpha/elder encounters using existing species.
2. Each differs behaviorally from ordinary wilds, not only in HP/size.
3. Variant data is tunable and does not fork species definitions.
4. Alpha/elder and shiny are independent states.
5. Encounters are level-appropriate and do not ambush the opening tutorial unfairly.
6. Catching an alpha/elder yields an ordinary owned instance of that individual without violating the five-cap.
7. Save/reload/spawn determinism behaves consistently with existing world rules.
8. No new creature mesh/generation is introduced.

## Testing / verification
Extend spawn/encounter tests for variant application, shiny independence, behavior override, catch path and deterministic spawning. Capture representative encounters at normal gameplay distance and run visual review. Verify performance with several variants present, not only one isolated body.

## Definition of done
The Meadows contains rare, memorable older/alpha individuals that make exploration feel less uniform because **where they live and how they behave is different**, while remaining part of the existing roster and systems.