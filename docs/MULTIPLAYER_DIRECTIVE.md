# TETHERBOUND — MULTIPLAYER DIRECTIVE

**Status:** Future architectural directive. Do not implement networking until the current Meadows and Cloudreach completion work is finished and integrated to `main`.

## 1. Target

Tetherbound should eventually support **Valheim-style 1–4 player cooperative worlds**:

- one player creates/hosts a world;
- up to three friends may join;
- the host/server is authoritative for shared world state;
- each player controls their own trainer and their own team of up to five creatures;
- players explore, gather, build, fight, catch, progress, and defeat bosses together;
- the same game must remain fully playable solo.

This is **not** an MMO target, not a large public-server target, and not competitive PvP.

The design goal is small-group private co-op.

## 2. Timing

The intended sequence is:

1. finish Cloudreach Cliffs;
2. finish/close the remaining Meadows work;
3. stabilize `main`;
4. perform the multiplayer architecture split;
5. add networking and 1–4 player co-op;
6. continue later biome development on the multiplayer-compatible architecture.

Do not attempt to retrofit multiplayer piecemeal while Cloudreach or Meadows are still moving heavily.

## 3. Current architectural fact

The current game is single-player-first. A single global `Game` autoload owns player-specific and world-specific state together, including party, inventory, progression, map state, and other persistent state. This is clean for single player but is the primary seam that must be split for multiplayer.

The multiplayer conversion should **preserve working gameplay systems** rather than rewrite them for theoretical purity.

## 4. Required architectural split

Before serious networking work, separate persistent/runtime state conceptually into two domains.

### Shared WorldState

Server-authoritative state shared by everyone in the hosted world, including where appropriate:

- world seed;
- biome/world unlocks;
- day/night and weather;
- world progression;
- boss defeat state;
- chapter/realm state;
- shared NPC/world-event state;
- built structures;
- opened shortcuts;
- bridges/gates;
- harvested/felled persistent world objects;
- persistent world pickups;
- encounter/world spawn state where persistence is intended;
- shrine/realm-heart placement if that is world-level;
- shared quest/world flags;
- other state that describes **what has happened to this world**.

### PlayerState

One instance per connected player, including where appropriate:

- trainer identity/customization;
- player position/pose when saving;
- party of up to five creatures;
- creature levels;
- bond;
- traits/individuality;
- inventory/hotbar;
- personal equipment;
- personal stamina/vitals;
- active Realm Heart power;
- personal map discovery if retained as personal;
- personal quest/task UI state where appropriate;
- player-specific unlock/tutorial flags;
- other state that describes **this player's character and team**.

The multiplayer implementation must stop assuming `Game.party`, `Game.inventory`, `Game.player_position`, etc. refer to the one player in existence.

Do not necessarily rename/rewrite every API at once. Introduce clean ownership boundaries and adapters so working game logic can migrate safely.

## 5. Authority model

Use a **host/server-authoritative model**.

The server/host decides the truth for shared gameplay events, including:

- enemy/wild creature existence;
- combat outcomes;
- damage;
- catches;
- loot/pickups;
- resource depletion;
- trainer/boss defeat;
- building placement;
- world gates;
- story/world progression;
- day/night/weather;
- other shared state.

Clients send player intent/input and receive authoritative results/state.

Do not build a trust-the-client model for important state simply because it is easier initially.

## 6. Session model

Target flow:

1. Host chooses **Start World** or **Load World**.
2. Host may play alone immediately.
3. Host may invite up to three friends.
4. Joining players enter the host's currently active world.
5. The host/server owns the world save.
6. Each player retains their own persistent trainer/team save.
7. Friends may leave and rejoin later without losing their personal progression.
8. The world continues to exist as the host's world even when friends are absent.

LAN/direct-IP/Steam-style invite implementation is an engineering choice to settle during the multiplayer pass. Product intent is the experience above, not a specific matchmaking vendor yet.

## 7. Solo compatibility

Single-player must remain a first-class mode.

The networking architecture should make solo effectively a one-player hosted session or use the same authority boundaries without requiring an external server process.

Do not maintain two divergent gameplay implementations for solo and multiplayer.

## 8. Player and creature replication

Every connected player must be able to see:

- the other trainers;
- their movement;
- their currently deployed creature;
- creature movement/animation;
- attacks and combat results;
- riding;
- Fly traversal;
- building actions;
- gathering interactions;
- relevant emotes/relationship feedback;
- deaths/revives;
- other high-value visible gameplay.

Replication must prioritize responsive local control while preserving server authority.

## 9. Combat target

Multiplayer combat should preserve Tetherbound's core identity:

- each player directly pilots their active creature;
- the human trainer still does not personally fight;
- multiple players may have creatures deployed in the same encounter;
- bosses should support multiple simultaneously piloted creatures;
- encounter scaling should account for party size without simply multiplying HP excessively.

Late-game co-op should be able to create moments such as:

> four trainers + four directly controlled creatures fighting one major boss together.

The five-creature limit remains **per player**, not five creatures shared across the server.

## 10. Building

Building should be shared world content by default.

Expected behavior:

- structures placed by any permitted player exist in the host world;
- other players see them immediately;
- persistence belongs to WorldState;
- placement authority is server-side;
- collision/nav/state updates replicate;
- permissions may later limit who can modify/destroy structures.

## 11. Gathering and resources

Default direction:

- persistent world resource depletion/state belongs to the server;
- gathered items are awarded to the player who gathered them unless an authored shared reward says otherwise;
- world pickups cannot be independently collected four times unless specifically designed as per-player rewards;
- item duplication due to race conditions is a blocker.

## 12. Realm Hearts

Default direction:

- **Heart placement/shrine completion is world progression**;
- **equipped Heart power is player-specific**;
- players in the same world may equip different unlocked Heart powers;
- only one Heart power may be active per player at a time.

This preserves the Valheim-like shrine progression while allowing each trainer to choose their own active benefit.

## 13. Death and recovery

Default direction:

- each player's death state is personal;
- dropped satchel/recovery object belongs to that player unless deliberately made shareable;
- other players should be able to assist/revive where design supports it;
- one player's death should not reset or softlock the entire encounter/world.

## 14. Save architecture

Multiplayer conversion requires separating current save content into:

### World save

Owned by host/server:

- seed;
- world progression;
- biome unlocks;
- bosses;
- world pickups;
- builds;
- felled/harvested persistent state;
- shared NPC/state changes;
- shrine placement;
- shortcuts/gates;
- other shared state.

### Player save

Owned by each player:

- trainer;
- party;
- creatures;
- inventory;
- bond/levels;
- active Heart power;
- personal settings/progression where applicable;
- other player-specific state.

Old single-player saves must be migrated safely rather than discarded if practical.

## 15. Join/leave/reconnect requirements

The system must eventually support:

- host starts solo and friend joins later;
- friend leaves during ordinary exploration;
- friend disconnects unexpectedly;
- friend reconnects;
- client joins a world with already-built structures and changed world state;
- client joins while host is in a later biome;
- player state is restored correctly;
- active encounter ownership resolves safely on disconnect;
- no item duplication or progression rollback on reconnect.

## 16. World progression philosophy

Default recommendation: **major realm progression is world-level**, matching Valheim.

Examples:

- Warden defeated;
- Cloudreach unlocked;
- boss defeated;
- shrine Heart placed;
- permanent bridge opened;
- realm gate unlocked.

All players currently participating receive the experience/rewards appropriate to the event, while the world itself permanently records the change.

Player-specific creature growth, inventory, bond, etc. remain personal.

## 17. Multiplayer difficulty scaling

Do not simply multiply enemy HP by player count.

Scaling should consider a combination of:

- additional enemy count;
- encounter composition;
- enemy aggression/targeting;
- mechanics that require spatial coordination;
- modest HP/damage scaling;
- boss behavior changes where worthwhile.

A 4-player fight should be more interesting, not merely four times longer.

## 18. Networking scope for first release

The first multiplayer milestone should prove only the core loop:

1. host a Meadows world;
2. friend joins;
3. both players move reliably;
4. both deploy creatures;
5. both fight one shared wild encounter;
6. gathering/loot resolves without duplication;
7. one player places a structure and both see it;
8. save/reload world and players;
9. reconnect successfully.

Only after this vertical slice is stable should networking be expanded across all systems/biomes.

## 19. Conversion sequence

Recommended implementation order after Cloudreach + Meadows are complete:

### M0 — Audit and contract

- inventory every current assumption of one global player;
- classify state as world/player/session/transient;
- document RPC/authority boundaries;
- write multiplayer tests before broad conversion.

### M1 — State separation

- introduce PlayerState;
- separate WorldState from player-owned state;
- preserve current single-player behavior;
- migrate saves.

### M2 — Networking shell

- host/join;
- player IDs;
- spawn/despawn trainers;
- authority assignment;
- reconnect basics.

### M3 — Movement and interaction

- player movement;
- interaction;
- inventory transaction authority;
- gathering;
- building.

### M4 — Creatures and combat

- creature ownership;
- deployment;
- movement;
- attacks;
- switching;
- shared encounters;
- catches;
- defeat/revive;
- boss multiplayer.

### M5 — World progression

- objectives;
- NPCs;
- bosses;
- gates;
- Realm Hearts;
- realm transitions;
- world-state persistence.

### M6 — Complete-system conversion

- riding;
- Fly;
- camps/rest;
- trading;
- farming;
- maps;
- pickups;
- remaining systems.

### M7 — Reliability and shipping

- disconnect/reconnect;
- late join;
- host migration decision;
- save corruption protection;
- latency tests;
- target-hardware performance;
- 1/2/3/4-player end-to-end runs.

## 20. Outstanding product decisions

These are the main questions that should be decided before or during M0. Recommended defaults are included so work can proceed if the owner does not care strongly.

### Q1 — Can a player's character/team travel between different hosted worlds?

**Recommended: yes, like Valheim.** A player owns their trainer/team/inventory and can join another friend's world with them.

Alternative: world-bound characters, which is simpler for progression integrity but less convenient.

### Q2 — Is world story progression shared?

**Recommended: yes.** Bosses, realm gates, bridges, Heart placement, and major story outcomes belong to the world.

### Q3 — What happens when a player joins a world farther ahead than their personal progression?

**Recommended:** allow them to join and participate, but preserve their personal creature/team state. Avoid hard-locking the session because one friend is behind.

Whether they automatically receive world-level unlock rewards requires a specific rule.

### Q4 — Who gets a wild creature catch?

This is the most important unresolved combat rule.

Options:

A. first player to successfully catch it owns it;
B. encounter initiator has catch rights;
C. explicit claim/roll system;
D. each player receives an independent catch opportunity from the same encounter.

**Recommended starting point: A**, with clear UI and no duplication. Revisit if it creates bad friend-group behavior.

### Q5 — Are ordinary world pickups shared or personal?

**Recommended:** physical world pickups are shared/first-come; authored major quest rewards may be granted per participating player.

### Q6 — Can friends use each other's crafting stations/buildings/storage?

**Recommended:** yes by default for a private co-op world, with optional ownership/permission controls later.

Storage needs explicit shared transaction locking to prevent duplication.

### Q7 — Can players damage each other's creatures?

**Recommended: no friendly fire by default.** PvP is outside current scope.

### Q8 — How does sleeping work?

**Recommended Valheim-style rule:** advancing the night requires all currently connected non-incapacitated players to be sleeping/ready.

### Q9 — How does pausing work?

A hosted multiplayer world cannot globally pause when one client opens a menu.

**Required direction:** UI must stop local input without pausing the shared simulation. Solo may still pause if implemented through session awareness.

This is an important retrofit area because several current panels pause the scene tree.

### Q10 — Can the host play when nobody else is present?

**Yes. Non-negotiable.** A multiplayer-capable world must remain a normal solo world.

### Q11 — Dedicated servers?

**Recommended: not for first multiplayer release.** Start with player-hosted worlds. Keep architecture capable of a headless authoritative server later if practical.

### Q12 — Host migration if host quits?

**Recommended: not required initially.** If the host leaves, the session ends safely and saves. Consider host migration later only if demand justifies complexity.

### Q13 — Shared map exploration?

Options:

- personal fog-of-war;
- globally shared map discovery;
- personal by default with an explicit map-sharing mechanic.

**Recommended: personal discovery with a later sharing option**, preserving exploration.

### Q14 — Personal vs shared quests

**Recommended:** major chapter/world objectives are shared world objectives; tutorials, creature/team goals, and some side tasks may be personal.

### Q15 — Loot from bosses and major encounters

**Recommended:** world state changes once, but each participating player receives the personal progression rewards they need. Never force four friends to repeat a one-time boss four times for four copies of a mandatory personal reward.

### Q16 — Can one player enter another biome while others remain elsewhere?

**Recommended: yes**, if the world/streaming/network architecture supports it. Do not force a permanent tether radius merely for convenience.

For the first implementation milestone, temporarily constraining players to one loaded realm may be acceptable if clearly documented as a networking limitation, not the final design.

### Q17 — Trading between players?

**Recommended: yes eventually**, via explicit item transfer UI or safe drop/pickup mechanics. Not required for the first multiplayer vertical slice.

### Q18 — Creature trading?

Open design question. Because Tetherbound's five-creature rule and emotional permanence are central, creature transfer between players has larger consequences than item trading.

**Recommended: defer until after core multiplayer works.**

## 21. Important current-system risks

The multiplayer pass must explicitly inspect these current single-player assumptions:

- global `Game` state combines world and player state;
- save file currently combines world and player persistence;
- world input assumes one local controlled player;
- several UI panels pause the scene tree;
- combat systems may assume one active controlled creature;
- EncounterDirector may assume one encounter owner;
- story/SequenceDirector may assume one player trigger;
- map/progression state may assume one viewer;
- building/storage transactions currently do not need concurrency control;
- one continuous world scene was designed for one camera/player;
- terrain/scatter visibility and streaming/culling behavior must be validated with separated players;
- riding/Fly authority must be defined per player;
- autosave ownership must be divided between world and player saves.

These are conversion tasks, not reasons to abandon the existing architecture.

## 22. Performance target

Multiplayer must continue to respect the ROG Ally / target-hardware budget.

Do not assume four players means four times every expensive visual/system cost.

Profile:

- additional player models;
- additional deployed creatures;
- replicated combat VFX;
- network serialization;
- AI/encounter counts;
- separated-player world visibility;
- world streaming/culling;
- builds and persistent objects.

## 23. Testing requirements

Create automated and runtime tests for at least:

- 1-player hosted session;
- 2-player join/leave;
- 4-player connection;
- authoritative inventory changes;
- simultaneous pickup race;
- simultaneous storage access;
- building replication;
- creature deployment ownership;
- shared combat;
- catch ownership;
- boss progression;
- Heart shrine/world state;
- personal Heart power state;
- world save/reload;
- player save/reload;
- late join;
- reconnect after disconnect;
- disconnect during combat;
- disconnect while mounted/flying;
- solo save migration;
- no regression to offline solo play.

## 24. Definition of multiplayer done

Multiplayer is not done because two players can appear in the same scene.

It is done when 1–4 players can reliably:

- host/join;
- bring their own trainer/team;
- explore together;
- split up where supported;
- fight together;
- catch without duplication;
- gather;
- build;
- use camps;
- progress story/world state;
- defeat bosses;
- use Realm Hearts;
- travel between completed biomes;
- save;
- leave;
- reconnect;
- continue the world later;
- and still play the exact same world solo.

All important state must survive save/load and disconnects without duplication, rollback, corruption, or world-state disagreement.

## 25. Core principles

- **Valheim-style private co-op is the target.**
- **1–4 players.**
- **Host/server authoritative.**
- **World belongs to the host/server; trainer/team belongs to the player.**
- **Five creatures per player.**
- **Solo remains first-class.**
- **One gameplay implementation, not separate solo/multiplayer games.**
- **Preserve working systems; refactor ownership, not everything.**
- **No trust-the-client shortcuts for valuable state.**
- **No item/catch duplication.**
- **Do not begin this conversion until Cloudreach and the Meadows completion pass are finished.**
