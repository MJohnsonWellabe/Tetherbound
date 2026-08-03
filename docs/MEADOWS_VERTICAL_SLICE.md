# TETHERBOUND — MEADOWS VERTICAL SLICE IMPLEMENTATION SPEC

## Goal

Build the smallest complete version of Tetherbound that proves the actual game is fun.

This is **not** “build every feature eventually needed by the full game.”

The slice should demonstrate:
- movement
- authored wilderness exploration
- pal encounters
- real-time combat
- aimed capture
- party of five
- pal management
- traits/levels/basic bond
- fainting/recovery
- gathering
- minimal crafting
- minimal building
- bed/campfire/home loop
- simple food
- berry farming
- fishing
- riding
- Team Tether encounter
- first Warden battle
- release ceremony
- first legendary reward

## Suggested Milestone Sequence

### M0 — Godot boot
- Project opens cleanly.
- Test scene runs.
- Controller detected.
- Windows debug build exports.

### M1 — Movement playground
- Third-person controller.
- Camera orbit.
- Walk/sprint/jump.
- Stamina.
- Fall damage.
- Rolling terrain.
- Basic collision.
- ROG Ally-friendly HUD scale.

**Acceptance:** moving around an empty test meadow already feels pleasant.

### M2 — One pal encounter
Use placeholder trainer + two placeholder pal models if necessary.
- peaceful roaming pal
- targeting/interact
- enter Combat Mode
- choose/send pal
- Quick Attack
- energy
- Charged Attack
- Run
- Switch architecture even if only one pal initially

**Amended by `docs/decisions/D07-combat-is-piloted-not-commanded.md`.** Combat is
piloted rather than commanded: on entering Combat Mode the player takes over the
deployed pal, both fighters move freely inside a bounded arena, and attacks are
aimed. Add to the list above:
- camera and control transfer from trainer to pal
- a bounded arena with a visible soft boundary
- directional melee with a forgiving cone
- an opponent that closes, commits and backs off
- movement is the dodge; no dodge button

**Acceptance:** repeat the fight 10 times without obvious frustration.
The real bar is higher and is the owner's: *you want an eleventh fight.*

### M3 — Catching
- Throw Orb command
- aimed projectile
- target feedback
- catch success/failure
- HP affects chance
- full-health throws allowed
- faint removes catch opportunity

**Acceptance:** landing a good throw feels satisfying.

### M4 — Party
- Catch pal
- persistent party data
- levels
- HP/ATK/DEF
- appraisal
- trait
- nickname
- up to five pals
- switching
- simple party menu

### M5 — Release ceremony
- Capture while full.
- Present six.
- Inspect meaningful info.
- Keep one / release one.
- Released pal leaves permanently.

Do not settle for a generic “delete” dialog.

### M6 — Fainting and home recovery
- pal faint
- unavailable state
- revival item stub
- pal bed
- home recovery
- visible pal rest behavior

### M7 — First real Meadows exploration space
Build a dense authored test region:
- Grandpa home
- small settlement
- hills
- oak grove
- stream/pond
- trail
- rock outcrop
- distant stronghold landmark

Use scatter rules for dressing.

### M8 — Gathering/building
Minimal materials only.
Suggested starting set:
- Wood
- Stone
- Fiber
- Berries
- one special crafting mineral/material if actually needed

Tools:
- Axe
- Pickaxe
- Hammer
- Knife
- Fishing Rod

No hunting economy.

Initial build pieces:
- floor
- wall
- doorway/door
- roof
- campfire
- bed
- pal bed
- workbench
- storage
- fence
- berry plot

### M9 — Survival loop
- stamina
- food buffs
- simple player HP
- armor slots architecture
- tool durability
- free repair
- inventory slots/stacks
- player death
- persistent satchels
- map/minimap markers

### M10 — Weather/day-night
- day/night
- rain
- fog/cloud variants
- spawn conditions
- at least one nocturnal pal
- at least one weather-conditioned spawn

### M11 — Meadows roster pass
Do not require all final assets before systems work.

Target finished biome:
- 3 starters
- 12 wild species
- 1 evolved form
- 1 legendary

Before final art lock:
- validate asset style cohesion
- validate animations
- validate scale
- validate combat readability

### M12 — Riding
- compatible rideable pal
- generic Riding Saddle
- mount/dismount
- riding stamina if needed
- clear advantage over running
- no species-specific saddle clutter

### M13 — Team Tether slice
- world encounter/trainer
- trainer team combat
- cannot catch trainer pals
- simple authored stronghold route
- visual language: sacred/natural site industrialized by Tether

### M14 — Warden + legendary
- first regional trainer boss
- meaningful difficulty
- free tethered Ground legendary
- legendary offers to join
- triggers release ceremony when full
- superior ride ability

### M15 — Polish gate
Focus only on:
- input feel
- combat cadence
- catch feel
- camera
- UI readability
- performance
- visual cohesion
- bugs
- pacing

Do not start Biome 2.

## Meadows Content Direction

### Starter trio
Ground / Water / Air.
Final species/assets are not yet locked.

Roles:
- Ground: forgiving/tanky
- Water: balanced
- Air: offense/energy

### Wild roster skeleton
Ground:
- rabbit
- boar-like
- canine → wolf evolution
- rideable deer/horse
- badger-like

Water:
- frog/newt
- turtle
- otter/beaver
- Water/Air waterfowl

Air:
- small bird
- owl
- hawk/eagle

Final names and exact models should be chosen around the best cohesive asset set available.

## Art Direction Rule

Do not make the Meadows look like a random asset-pack demo.

Desired feeling:
- cozy stylized natural world
- rolling terrain
- vibrant but not childish
- creatures visually belong in the same game
- strong silhouettes
- readable materials
- attractive lighting
- restrained effects

If an asset is technically convenient but visually wrong, replace it.

## Performance

Target real Windows hardware early.

Prefer:
- sensible LOD
- instancing/multimesh for repeated vegetation
- modest shader complexity
- reasonable shadow distances
- disciplined texture sizes
- occlusion/culling where useful

Do not destroy visual quality to chase arbitrary desktop benchmark numbers, but ROG Ally must remain a first-class target.

## Slice Exit Gate

Biome 2 is forbidden until all master design exit criteria are met.
