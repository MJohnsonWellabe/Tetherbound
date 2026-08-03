# TETHERBOUND — GODOT TECHNICAL START

## Engine

**Godot 4.x stable**.

Use GDScript unless a concrete technical reason justifies C# later. GDScript keeps iteration fast and project setup simple.

## Project Architecture

Recommended top-level structure:

```text
res://
  autoload/
  data/
    pals/
    moves/
    traits/
    items/
    recipes/
    spawns/
  scenes/
    player/
    pals/
    combat/
    world/
    building/
    ui/
    props/
  scripts/
  resources/
  assets/
    characters/
    pals/
    environment/
    buildings/
    animations/
    audio/
  shaders/
  tests/
  docs/
```

Use Godot Resources or external JSON where appropriate, but do not hardcode species stats throughout gameplay scripts.

## Core Systems

Prefer separated systems:
- InputRouter
- PlayerController
- PlayerStats
- Inventory
- Equipment
- SaveManager
- WorldState
- PalDatabase
- PartyManager
- PalInstance
- CombatManager
- CatchManager
- BondSystem
- BuildingSystem
- SpawnManager
- DayNightManager
- WeatherManager
- MapDiscovery
- DeathSatchelManager
- AssetRegistry

Names are recommendations, not API contracts.

## Pal Data vs Pal Instance

Species data should define:
- species id
- display name
- type(s)
- base HP/ATK/DEF
- compatible moves
- wild habitat
- catch parameters
- traversal aptitude
- evolution definition
- favorite food
- Best Pal ability id
- model/animation references

Individual pal instance should store:
- unique id
- species id
- nickname
- level/xp
- appraisal rolls
- trait 1
- trait 2 if earned
- bond
- current HP
- known Quick moves
- known Charged moves
- equipped Quick
- equipped Charged
- history/time-together data
- evolution state

## Combat Architecture

Combat Mode should be a state transition, not a separate unrelated game.

Exploration:
- player controls trainer
- pals generally stored/not summoned
- world simulation active

Combat:
- player locomotion restricted/managed
- combat camera takes over
- selected pal instanced/deployed
- opposing pal positioned
- action UI enabled
- CombatManager owns attack/energy/switch/capture state

On exit:
- restore exploration camera/input
- persist pal HP/xp/state
- clean temporary combat actors safely

## Save Requirements

Use versioned save data from the start.

Save:
- player transform/home
- inventory/equipment
- world discovery
- map markers
- party and all individual pal state
- released pal identities if needed for persistence semantics
- structures placed
- death satchels
- defeated story encounters
- Team Tether progression
- TM unlocks
- recipes/discoveries
- time/day/weather as appropriate

Include a save schema version so migration is possible.

## Input

Use Godot Input Map actions, never raw device checks scattered through gameplay.

Suggested actions:
- move_left/right/forward/back
- camera_look
- jump
- sprint
- interact
- inventory
- map
- tool_1..tool_4 or tool_cycle
- combat_quick
- combat_charged
- combat_throw
- combat_run
- combat_switch_left
- combat_switch_right
- menu_confirm
- menu_cancel

Controller mappings should be tuned on an Xbox-layout controller / ROG Ally.

## Asset Provenance

Maintain a file such as:

`docs/ASSET_LEDGER.md`

For every non-original asset:
- asset name
- creator
- source
- license
- paid/free
- purchase status
- usage restrictions
- local path
- modifications

## Build / Export

Create a Windows export preset early, not at the end.

Development should continuously prove:
- project opens from clean checkout
- game runs
- controller works
- debug Windows export succeeds

## Do Not Prematurely Build

Avoid:
- network stack
- multiplayer architecture
- procedural-seed framework
- phone touch abstraction
- eight-biome generalization where simple data-driven content is enough
- advanced ECS rewrite
- custom engine systems Godot already supplies adequately

Build architecture that is clean enough to expand, but optimize for finishing the Meadows vertical slice.
