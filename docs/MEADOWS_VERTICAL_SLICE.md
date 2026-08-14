# TETHERBOUND — MEADOWS VERTICAL SLICE IMPLEMENTATION SPEC

**Scope extended by `docs/MEADOWS_PROGRESSION_SPEC.md` (`docs/decisions/D23`).**
The owner played the published build and turned the Meadows from a slice into
the game's first chapter: 4–7 hours, five progression bands, two material
tiers, physical gates, a dungeon, a mini-stronghold and a rescue. M0–M6 and
M8–M11 are unchanged and the spec assumes them; **M7, M12, M13, M14 and the
slice exit gate are amended in place below.** Do not read this document as the
ceiling any more.

## Goal

Build the smallest complete version of Tetherbound that proves the actual game is fun.

This is **not** “build every feature eventually needed by the full game.”

The slice should demonstrate:
- movement
- authored wilderness exploration
- creature encounters
- real-time combat
- aimed capture
- party of five
- creature management
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

### M2 — One creature encounter
Use placeholder trainer + two placeholder creature models if necessary.
- peaceful roaming creature
- targeting/interact
- enter Combat Mode
- choose/send creature
- Quick Attack
- energy
- Charged Attack
- Run
- Switch architecture even if only one creature initially

**Amended by `docs/decisions/D07-combat-is-piloted-not-commanded.md`.** Combat is
piloted rather than commanded: on entering Combat Mode the player takes over the
deployed creature, both fighters move freely inside a bounded arena, and attacks are
aimed. Add to the list above:
- camera and control transfer from trainer to creature
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

**Extended by `docs/decisions/D08-catching-costs-you-your-creature.md`.** Throwing
hands camera and control back to the trainer for a real-time over-the-shoulder
aim, and leaves your creature undefended for the duration. That cost is what makes
throwing a decision rather than a free extra button.

**Also in this milestone, from `GAME_DESIGN.md` pillar 3 and §14:**
- an `aggressive` flag on a species
- a wild creature that closes on the trainer and starts the fight itself
- peaceful creatures still never initiate

**Acceptance:** landing a good throw feels satisfying.

### M4 — Party
- Catch creature
- persistent party data
- levels
- HP/ATK/DEF
- appraisal
- trait
- nickname
- up to five creatures
- switching
- simple party menu

### M5 — Release ceremony
- Capture while full.
- Present six.
- Inspect meaningful info.
- Keep one / release one.
- Released creature leaves permanently.

Do not settle for a generic “delete” dialog.

### M6 — Fainting and home recovery
- creature faint
- unavailable state
- revival item stub
- creature bed
- home recovery
- visible creature rest behavior

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

**Amended by `docs/decisions/D23`.** The area list grows with the chapter
(`MEADOWS_PROGRESSION_SPEC.md` §3): an Old Quarry, the Burrow Warrens, a major
river and the Old Mill Crossing, a Tether Relay Station, the Upper Meadows with
a wind ridge and ruined watchtower, and seven severed perimeter spokes. The
512 m playground cannot hold that — `ralph/BACKLOG.md`'s `R7.3` owns the growth
and the rebake.

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
- creature bed
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
- at least one nocturnal creature
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
- compatible rideable creature
- generic Riding Saddle
- mount/dismount
- riding stamina if needed
- clear advantage over running
- no species-specific saddle clutter

**Amended by `docs/decisions/D23`.** Riding is a Band 3 / early Band 4 unlock,
not a free-standing milestone: Meadowhart is the rideable creature and the
generic saddle is priced in Rootstone and Ironwood components
(`MEADOWS_PROGRESSION_SPEC.md` §3). Its value is measured on how much better it
makes *revisiting* known ground.

### M13 — Team Tether slice
- world encounter/trainer
- trainer team combat
- cannot catch trainer creatures
- simple authored stronghold route
- visual language: sacred/natural site industrialized by Tether

**Amended by `docs/decisions/D23`.** One world encounter becomes a chapter's
worth: three local trainers in Band 1, a Tether Relay Station with two or three
trainers and a relay captain, three regional captains in Band 4, and two to
four in the stronghold — roughly 12–17 battles across meaningful locations
(`MEADOWS_PROGRESSION_SPEC.md` §12). The industrialised-sacred-site language is
used twice: first at the relay, then at full scale.

### M14 — Warden + legendary
- first regional trainer boss
- meaningful difficulty
- free tethered Ground legendary
- legendary offers to join
- triggers release ceremony when full
- superior ride ability

**Amended by `docs/decisions/D23`.** The Warden knows what freeing the
legendary will do and warns rather than gloats; the reveal is that the
legendary is powering the Meadows Tether Rift
(`MEADOWS_PROGRESSION_SPEC.md` §28, §33). After the release, the machinery
fails and the first Rift collapses — the next biome visibly reconnects as a
**distant, non-enterable view**. `CLAUDE.md`'s Biome 2 rule still governs; D23
names that carve-out explicitly.

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
- rooting pig → armoured boar evolution
- canine
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

**Amended by `docs/decisions/D23`.** `MEADOWS_PROGRESSION_SPEC.md` §39 adds a
second, chapter-level gate alongside `GAME_DESIGN.md` §33. §33's twelve
criteria are deliberately **not** renumbered — several backlog items cite them
by number.
