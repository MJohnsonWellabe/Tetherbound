# TETHERBOUND — MULTIPLAYER DIRECTIVE

**Status:** Canonical future implementation directive. **Do not start this work until Cloudreach Cliffs and the remaining Meadows completion work are finished, integrated, and `main` is stable.** Once this pass begins, however, it does **not** stop at architecture. The pass must end with playable 1–4 player co-op.

## 1. Product target

Tetherbound will support **Valheim-style private 1–4 player cooperative worlds**:

- one player creates or loads and hosts a world;
- up to three friends may join;
- the host/server is authoritative for shared world state;
- each player brings and owns their own trainer, inventory, Heart power choice, and team of up to five creatures;
- players explore, gather, build, fight, catch, progress, travel between biomes, and defeat bosses together;
- the same world remains fully playable solo when no friends are connected;
- this is not an MMO, public-server game, competitive PvP game, or large-session target.

**Networking is part of the first multiplayer pass.** The architecture split is only the first phase of that pass.

## 2. Timing

Execution order:

1. finish Cloudreach Cliffs;
2. finish/close remaining Meadows work;
3. stabilize and verify `main`;
4. execute this multiplayer directive from start to finish;
5. do not resume later biome expansion until 1–4 player co-op is playable and proven.

## 3. Non-negotiable architecture

The current game is single-player-first and mixes player-specific and world-specific state through the global `Game` singleton. Multiplayer must preserve working systems while separating ownership into two domains.

### WorldState — host/server authoritative

Includes, where applicable:

- world seed;
- biome/world unlocks;
- day/night and weather;
- story/world progression;
- boss defeat state;
- chapter/realm state;
- shared NPC/world-event state;
- built structures;
- opened shortcuts, bridges, gates;
- harvested/felled persistent world objects;
- persistent world pickups;
- encounter/world spawn state where persistence is intended;
- shrine / Realm Heart placement;
- shared main quest/world flags;
- other state describing **what has happened to this world**.

### PlayerState — one per player

Includes, where applicable:

- trainer identity/customization;
- player position/pose;
- party of up to five creatures;
- creature levels, bond, traits, individuality;
- inventory/hotbar/equipment;
- personal stamina/vitals;
- active Realm Heart power;
- personal map discovery;
- personal tutorial and creature/team task state;
- other state describing **this player's trainer and team**.

The final multiplayer implementation must no longer assume `Game.party`, `Game.inventory`, player position, active creature, etc. refer to the only player in existence.

Use adapters/migration layers where useful. Do not rewrite working systems only for theoretical purity.

## 4. Authority model

Use a **host/server-authoritative model**.

The server decides truth for:

- enemies and wild-creature existence;
- damage and combat outcomes;
- catches;
- loot and pickups;
- resource depletion;
- trainer/boss defeat;
- building placement;
- world gates and story progression;
- day/night/weather;
- shared saves;
- other consequential shared state.

Clients send intent/input and receive authoritative results/state. Do not trust clients for important game state simply because it is easier.

## 5. Settled product rules — owner decisions 2026-09-04

All questions are resolved. These are implementation requirements, not defaults.

1. **Portable trainers/teams: YES.** A player may bring their trainer, five-creature team, inventory, and personal progression into different hosted worlds, Valheim-style.
2. **World story progression is shared.** Bosses, realm gates, bridges, Heart placement, major chapter state, and realm unlocks belong to the world.
3. **A player may join a world that is farther ahead.** They may participate immediately; do not hard-lock the session because their personal progress is behind.
4. **Wild catch ownership: first successful catch wins.** The first player who successfully catches the wild creature owns it. UI/state must make this clear and race-safe.
5. **Ordinary physical world pickups are shared/first-come.** A candy, potion, revive, etc. disappears for everyone when collected unless explicitly authored as a per-player reward.
6. **Boss and mandatory personal rewards are per participating player.** The world changes once, but each participating player receives mandatory personal progression rewards. Do not require repeating one-time bosses for every friend.
7. **Friends may use each other's crafting stations, buildings, and storage by default.** Shared transactions must be concurrency-safe and duplication-proof.
8. **Friendly fire is OFF.** Players cannot damage each other's trainers or creatures in normal co-op.
9. **Sleep/night skip is Valheim-style.** All currently connected, non-incapacitated players must be sleeping/ready before night advances.
10. **Solo host play is always allowed.** A world works normally with only the host present.
11. **Dedicated servers are NOT required for the first multiplayer release.** Player-hosted worlds first; keep the architecture capable of headless hosting later where practical.
12. **No host migration initially.** If the host leaves, the session ends safely, saves, and returns clients cleanly. Host migration can be reconsidered later.
13. **Map discovery is personal.** Fog-of-war belongs to each player. A map-sharing mechanic may be added later, but discovery is not globally automatic.
14. **Main world/chapter quests are shared.** Tutorials, creature/team goals, and appropriate side tasks may remain personal.
15. **Major encounter loot rule:** world state changes once; every participating player receives required personal progression rewards.
16. **Players may be in different biomes at the same time.** The final multiplayer architecture must support this. A temporary same-realm limitation is acceptable only during intermediate development, never as the final pass result.
17. **Item trading is allowed.** Provide a safe transfer/drop mechanism without duplication exploits.
18. **Creature trading is NOT part of the initial multiplayer implementation.** Do not add it during this pass.
19. **Friends can revive downed players.** Add a co-op revive window/interaction before the existing full death/recovery flow where practical. One player's death must never softlock/reset the entire shared world.
20. **Difficulty scaling uses encounter composition/mechanics plus modest stat scaling.** Do not merely multiply HP by player count.

## 6. Session model

Required player flow:

1. Host chooses Start World or Load World.
2. Host may immediately play solo.
3. Host can invite/connect up to three friends.
4. Joining players enter the host's active persistent world with their own portable trainer/team save.
5. Host owns the world save.
6. Each player owns their own player save.
7. Friends may leave and rejoin later without losing personal progression.
8. Client late-join must reconstruct the authoritative world state correctly.
9. If the host exits, world and player state save safely and the session ends cleanly.

Initial transport/invite implementation may be LAN/direct-IP or another practical Godot-compatible player-hosted solution. The pass must provide a usable host/join flow, not merely low-level networking APIs.

## 7. Solo compatibility

Do not maintain separate multiplayer and single-player gameplay implementations.

Solo should use the same authority/state boundaries as a one-player hosted session wherever practical. Single-player menus may pause locally if the session truly contains one player, but multiplayer clients opening UI must **not pause the shared simulation**.

Current scene-tree-pausing panels are an explicit conversion target.

## 8. Player and creature replication

Every player must reliably see other players'

- trainer movement;
- orientation and important animations;
- deployed active creature;
- creature movement/animation;
- attacks and combat results;
- catching attempts/results;
- riding;
- Fly traversal;
- gathering actions;
- building actions;
- relevant bond/relationship reactions;
- downed/revive/death states.

Favor responsive local input while preserving server authority.

## 9. Multiplayer combat

Tetherbound's identity remains:

- trainers do not personally fight;
- each player directly pilots their active creature;
- multiple players may deploy one active creature each into the same fight;
- the five-creature limit remains **per player**;
- bosses must support multiple simultaneously piloted creatures;
- target late-game experience includes **four trainers + four directly controlled creatures fighting one major boss together**.

Scale encounters through additional enemies, better composition, targeting/aggression, coordination mechanics, and modest HP/damage scaling. Four-player fights should be more interesting, not four times longer.

### Wild catches

The server arbitrates catch attempts. First successful catch owns the creature. Later simultaneous attempts must resolve consistently with no duplicate creature creation and clear feedback to all players.

## 10. Shared world interactions

### Building

- structures are WorldState;
- server approves placement/destruction;
- everyone sees changes immediately;
- collision/nav consequences replicate;
- friends can use each other's buildings/crafting stations/storage by default.

### Storage

Shared storage needs server-authoritative transaction locking/versioning so two players cannot withdraw the same item.

### Gathering

- world depletion is authoritative shared state;
- gathered item goes to the player who successfully gathered it;
- race conditions must never duplicate yields.

### Pickups

- ordinary physical pickups are shared/first-come;
- persistent collection state belongs to the world;
- explicitly authored mandatory personal rewards can grant to each eligible player.

### Item trading

Implement safe player-to-player item transfer/drop behavior with authoritative transactions.

Creature trading is excluded.

## 11. Realm Hearts

- Heart placement/shrine completion = shared WorldState;
- unlocked Heart powers become available to eligible players according to world progression;
- equipped Heart power = PlayerState;
- players in the same world may equip different unlocked powers;
- one active Heart power per player at a time.

## 12. Death and revive

Implement a co-op downed/revive flow:

- a player can become downed;
- another connected player can revive them within the allowed window/interaction;
- if not revived, the existing full death/recovery consequences occur;
- each player's dropped recovery state remains personal;
- one player's death cannot reset or softlock shared encounters/world progression.

## 13. Sleep and pause

### Sleep

Night advances only when every currently connected non-incapacitated player is sleeping/ready.

### Pause

Multiplayer menus cannot pause the shared world. Convert existing global scene-tree pause assumptions so each client can open menus without freezing other players. Solo may retain true pause when only one player is connected.

## 14. Save architecture

Split persistence into:

### World save — host owned

- seed;
- story/world progression;
- biome unlocks;
- bosses;
- world pickups;
- structures/storage/world-object state;
- felled/harvested persistent state;
- shared NPC/state changes;
- shrine/Heart placement;
- shortcuts/gates;
- shared quest state.

### Player save — portable

- trainer identity;
- party/creatures;
- inventory/hotbar/equipment;
- bond/levels/traits;
- active Heart power;
- personal map discovery;
- personal tutorial/team state.

Migrate existing single-player saves safely where practical. Never silently destroy an old save.

Autosave responsibility must be explicit so world and player files cannot partially overwrite each other into inconsistent state.

## 15. Different-biome concurrency

The final pass must permit players to occupy different biomes/realms simultaneously.

This affects:

- world scene ownership/streaming;
- simulation/culling;
- per-player cameras;
- encounter ownership;
- realm transitions;
- replication interest management;
- performance.

Do not solve multiplayer permanently by tethering all players to one camera or requiring one realm.

## 16. Map and quests

### Map

Fog/discovery is personal PlayerState. Do not reveal the host's whole discovered map to joining players automatically.

### Quests

- main chapter/world objectives = shared WorldState;
- tutorials, creature/team objectives, and selected side goals = personal PlayerState;
- joining a world farther ahead does not prevent participation.

## 17. First multiplayer pass must end playable

The first multiplayer pass is complete only when the game is genuinely playable with **1, 2, 3, and 4 players**.

The architecture vertical slice is a checkpoint, not the finish line.

### Minimum playable multiplayer experience

At minimum, prove in a hosted real-game world that players can:

1. host/load a world;
2. join with up to three friends/clients;
3. move independently and see one another reliably;
4. deploy and directly control their own creatures;
5. fight shared wild encounters;
6. catch using the first-successful-catch rule;
7. fight at least one trainer encounter together;
8. fight at least one major/boss encounter together;
9. gather without duplication;
10. collect shared pickups correctly;
11. build and use shared structures;
12. use shared storage safely;
13. trade items;
14. down/revive another player;
15. sleep and advance night correctly;
16. open menus without freezing other players;
17. ride and use Fly while other players remain active;
18. transition independently between Meadows and Cloudreach;
19. remain in different biomes simultaneously;
20. save world and each player's portable character/team;
21. disconnect and reconnect;
22. late-join an already-modified world;
23. host plays solo when nobody else is connected;
24. host exits and session saves/ends safely.

Do not call the pass complete after only a two-player movement demo.

## 18. Implementation sequence

### M0 — Audit and tests

- inventory every single-player assumption;
- classify all persistent/runtime state as world/player/session/transient;
- define RPC/authority boundaries;
- write core multiplayer regression tests;
- produce a conversion map, not another speculative rewrite plan.

### M1 — State/save separation

- introduce PlayerState;
- isolate WorldState;
- migrate current `Game.*` call sites safely;
- split saves;
- preserve solo behavior;
- migrate old saves.

### M2 — Networking shell

- host/join UI;
- peer/player IDs;
- trainer spawn/despawn;
- authority assignment;
- join/leave/reconnect foundation;
- one-player hosted mode.

### M3 — Player/world verbs

- movement replication;
- interaction authority;
- gathering;
- pickups;
- inventory transactions;
- building;
- shared storage;
- item transfer;
- local-only UI ownership/no global multiplayer pause.

### M4 — Creatures and combat

- creature ownership;
- deploy/recall/switch;
- piloted movement;
- attacks/damage;
- wild encounters;
- first-successful catches;
- trainer encounters;
- boss encounters;
- defeat/down/revive;
- multiplayer scaling.

### M5 — Shared progression

- NPC/story triggers;
- shared objectives;
- bosses/gates;
- Realm Hearts;
- world-state changes;
- mandatory per-player rewards;
- personal quest/tutorial separation.

### M6 — Travel/full-system coverage

- riding;
- Fly;
- camps/rest/sleep voting;
- map/fog;
- trading;
- farming;
- biome transitions;
- simultaneous multi-biome occupancy;
- remaining gameplay systems.

### M7 — Reliability and shipping

- 1/2/3/4-player end-to-end runs;
- late join;
- disconnect/reconnect;
- host exit;
- save consistency;
- race/duplication testing;
- latency/jitter testing;
- separated-biome testing;
- target-hardware performance;
- regression of solo Meadows + Cloudreach.

The orchestrator must continue through M7 in the same multiplayer goal unless blocked by a genuinely external dependency.

## 19. Current-system risks that must be addressed

Explicitly inspect and convert:

- global `Game` combines world and player state;
- current save combines world/player persistence;
- player/world input assumes one local player;
- several UI panels pause the scene tree;
- combat managers may assume one active controlled creature;
- EncounterDirector may assume one encounter owner;
- SequenceDirector/story triggers may assume one triggering player;
- map/progression assumes one viewer;
- building/storage do not currently need concurrency controls;
- the world/visibility architecture was designed around one camera;
- riding/Fly authority is currently single-player;
- autosave ownership is currently singular;
- terrain/scatter/culling must cope with separated players in different locations/biomes.

These are conversion tasks, not reasons to discard the existing architecture.

## 20. Performance

Multiplayer must still respect the target hardware, including the ROG Ally.

Profile:

- 4 trainer models;
- 4 active creatures;
- additional combat AI/enemies;
- VFX replication;
- network serialization;
- structures/world persistence;
- multiple widely separated player interest zones;
- separate-biome simulation;
- host CPU cost.

Use interest management and server simulation discipline. Do not simply simulate/render the entire game world at full fidelity for every peer.

## 21. Testing and acceptance

Create automated and runtime coverage for at least:

- 1-player host mode;
- 2-player join/leave/reconnect;
- 3-player session;
- 4-player session;
- portable player save joining a different world;
- shared world progression;
- first-successful catch race;
- pickup race;
- storage concurrency;
- item trading;
- friendly-fire rejection;
- all-player sleep requirement;
- non-pausing multiplayer UI;
- down/revive/full death;
- shared trainer encounter;
- shared boss encounter;
- mandatory per-player boss rewards;
- building replication/persistence;
- riding/Fly replication;
- simultaneous different-biome play;
- host exit save safety;
- solo regression after multiplayer conversion.

A multiplayer feature is not done because two local windows visually move. Prove authoritative state and persistence.

## 22. Branch / orchestration model

This is a large conversion. Use the repo's established orchestration rules:

- senior orchestrator owns architecture, authority boundaries, integration, sequencing, and final acceptance;
- lower-tier agents handle bounded investigations, migrations, tests, individual system conversions, race-condition probes, and documentation;
- independent file/system ownership may run in parallel;
- tightly coupled central state/network files must serialize;
- branch from current `main`;
- land verified PRs continuously;
- re-verify integrated `main` after each major multiplayer wave;
- never accumulate a giant unmerged networking branch for the whole project.

## 23. Definition of done

The multiplayer conversion is DONE only when:

- normal solo play still works;
- a player can host a persistent world;
- up to three friends can join;
- portable trainers/teams work across hosted worlds;
- players can move independently;
- each can deploy/control their own creature;
- shared combat works;
- first-successful wild catch ownership works;
- gathering/pickups are authoritative and duplication-safe;
- shared building/storage works;
- item trading works;
- friendly fire is off;
- co-op revive works;
- all-player sleep works;
- menus do not pause multiplayer simulation;
- shared main progression works;
- personal map discovery works;
- Realm Heart shared/personal split works;
- boss rewards are granted correctly per participating player;
- riding and Fly replicate;
- players can occupy different biomes simultaneously;
- world save and portable player saves work;
- late join/reconnect works;
- host exit saves and terminates safely;
- 1/2/3/4-player evidence exists;
- Meadows and Cloudreach remain playable end to end;
- completed work is integrated on `main`.

**Do not stop at multiplayer-ready architecture. Build playable multiplayer.**
