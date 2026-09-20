# Multiplayer

**Status:** Product, authority and persistence contract. Rules marked **current** describe main at `b8eda885`; rules marked **target** are implementation work. Archived specifications are recovery evidence, not proof that every lane still matches current code.

**Product:** Tetherbound is a finite, authored four-chapter creature expedition action RPG for **one to four players**, with no mandatory duration floor; eight good hours are acceptable. Solo is the one-peer form of the same world/authority model. Co-op is required, not a cut option. It supports a shared expedition; it does not add PvP, matchmaking or an endless service layer. Four biomes are this pass; the eventual eight-biome direction adds no work to this pass.

## 1. Session shape and hard limits

| Contract | Status and evidence |
|---|---|
| 1–4 stable characters in a listen-server session: host plus up to three joiners. | **Current foundation.** `data/config/multiplayer.json::session.max_peers=4`, `scripts/net/session.gd`; D95-session-transport-direct-ip-lan-enet-and-four-peer-cap. |
| ENet direct IP and LAN discovery; two application channels separate transactions/encounters from snapshots. | **Current.** `session.gd`, config; D95. No Steam or relay is integrated. This remains the built fallback while the launch invite transport is target work. |
| Each character owns up to five creatures. At four players the session can therefore carry **20 owned creatures**, but only one per character is deployed: **4 active player creatures maximum**. | **Current party limit and multiplayer contract.** `autoload/party.gd`, creature ownership/replication; D02/D03/D90, D100-character-persistence-portable-character-world-state-split-and-join-reconciliation. |
| Solo starts a local host and keeps solo combat/save behavior. | **Current architecture intent with regression coverage.** Stage B plan; D95/D97. |
| Host exit saves the host-owned world, tells peers and returns everyone to title. There is no host migration. | **Current contract.** Session/Stage B owner kit; D95/D97. |

Out of scope: PvP, friendly-fire damage, public matchmaking, dedicated servers, host migration, console relay, voice chat, peer-to-peer creature trading, a creature trade market and more than four concurrent characters. The authored NPC one-for-one creature swap remains; co-op host-transaction integration is target work in §8.

**Owner decision:** minimum launch co-op must support joining a friend by invite without typing an IP address or configuring a router. The preferred implementation candidate for this Windows Steam product is a friends-only Steam lobby for discovery/invites plus Steam networking for the peer connection and relay. Valve documents lobby invite/join callbacks and says its newer peer networking relays traffic through Valve when appropriate; GodotSteam documents a `SteamMultiplayerPeer` that connects a lobby owner and joiner by Steam ID under Godot's high-level multiplayer API. This is a **target direction, not a built claim**: the repository currently has only ENet, and the exact GodotSteam version/build, channel behavior and compatibility with Godot 4.7 must be proven before selection is final. Sources: [Valve Steam Networking](https://partner.steamgames.com/doc/features/multiplayer/networking), [Valve lobbies and invite callbacks](https://partner.steamgames.com/doc/api/ISteamMatchmaking), [GodotSteam MultiplayerPeer](https://godotsteam.com/tutorials/multiplayer_peer/).

This direction assumes no new paid relay, account or matchmaking service. It uses the release platform's existing friend/lobby/networking facilities and an open-source Godot integration candidate; it does not authorize a service purchase or other spending. A real Tetherbound Steam AppID, partner access/credentials, test entitlements for separate Steam accounts, and compatible Windows editor/export artifacts are unresolved platform dependencies. Do not put credentials or private partner data in the repository. If those prerequisites are unavailable, raise the dependency for owner resolution rather than silently downgrading launch co-op to port forwarding.

### 1.1 Target host, invite and join flow

All steps must be controller operable on Windows and ROG Ally. Keyboard/mouse may remain an alternate input, and the Steam overlay must not be the only place the game explains current session state.

1. **Solo:** `Play Solo` selects a local world and portable character, starts the existing one-peer local host, and requires neither Steam networking nor network setup.
2. **Host Co-op:** select the host-owned world and the host's portable character, then `Host for Friends`. The game creates a friends-only lobby capped at four total members, starts the listen host, and shows `1/4`, lobby readiness, `Invite Friends`, and `Start/Continue`. Opening and closing the Steam invite overlay must preserve controller focus and the selected world/character.
3. **Invite:** the host chooses friends through the Steam invite dialog. There is no public lobby browser, quick play or skill/level matching. A private invite/join-friend path may be added if the selected Steam lobby API requires it, but it remains friend-directed rather than public matchmaking.
4. **Join:** accepting an invite while the game is running handles Steam's lobby-join callback; accepting while it is closed handles Steam's launch parameter. Both routes open the same controller-first `Join Friend` flow, show the host/session identity, then require the joiner to choose one existing portable character (or deliberately create one) before connecting. Never transmit an IP address to the player or ask for router/firewall configuration.
5. **Handshake:** lobby membership is discovery, not admission. The host still enforces four peers, build/protocol/content compatibility, stable `character_id`, and the authoritative snapshot before interaction. Preserve the current two logical traffic purposes—transactions/encounters and snapshots—even if the chosen Steam peer maps channels differently. Preserve the current **20s connection** and **60s handshake/snapshot** targets unless transport measurements justify a configured change.
6. **Ready:** show each admitted character and connection state. Joining or rejoining never overwrites the host world, imports the host's personal state, or creates a silent replacement character/save.

LAN discovery and explicit IP+port over the current ENet transport remain an advanced fallback and development/recovery path. Default UDP **27015** remains its current default. Direct-IP internet play may still need firewall/router setup, so it cannot satisfy or be marketed as the required launch invite experience.

Failures return to the same Join/Host screen with controller focus intact, the selected portable character preserved and no world/character mutation from an incomplete handshake. Distinguish at minimum: Steam unavailable/not signed in; Steam lobby or invite overlay unavailable; lobby no longer exists/host left; session full; incompatible game/protocol/content version; connection timeout; host refusal; snapshot/handshake timeout; and lost connection. `Retry` repeats only the safe connection path; `Back` leaves the lobby/peer cleanly. A full or incompatible session must never sit until the generic 60s timeout.

Rejoin uses the same invite or Steam `Join Game` route and rebinds the same stable `character_id` to the new peer before reconciling the host snapshot. The configured **120s** reconnect value is still unproven because current registry eviction does not implement that guarantee; do not show a countdown or promise a grace window until code and tests agree. On orderly host exit, save the host-owned world and committed portable characters, close the lobby and return peers to title with a host-ended reason. On a host crash or abrupt connection loss, preserve the last durable acknowledged state; do not promise a final host save, acknowledgement or lobby-close callback from a dead process. Clients time out safely, discard uncommitted predictions and reconcile on rejoin. There is no host migration.

## 2. Authority and trust boundary

The listen host is the authority for shared outcomes. A client is authoritative only for local input and immediate presentation; it never declares that a consequential action succeeded.

| Domain | Authority contract | Current implementation evidence |
|---|---|---|
| World state | Host commits flags, time/day, gates, pickups, harvest, placed buildings and their contents, storage, satchels, spawn/defeat state and legendary offer state. | `WorldState`, `WorldLedger`, `ledger_rpc.gd`; D99/D103. |
| Portable character | Stable character owns party/creature instances, inventory, equipment/hotbar, satiety, personal flags, personal map/fog, pose and relic state. Host holds a session proxy; only that character file persists it. | `PlayerState`, `character_save.gd`, peer registry; D100-character-persistence-portable-character-world-state-split-and-join-reconciliation. |
| Trainer/deployed creature motion | Peer supplies its trainer and active creature motion; host keeps replicated state and validates speed, realm, encounter membership and legal transitions. | movement validator, rig/creature replication; D97/D101. |
| Non-player bodies | Host owns wild, trainer-creature and boss decisions and encounter state. | `encounter_host.gd`, encounter director integration; D96/D104. |
| Combat | Client sends intent with encounter/action identity. Host checks phase, owner, cooldown/resources and geometry against host-held state, rolls RNG, applies HP/status and broadcasts one sequenced result. | `encounter_host.gd`, `combat_manager.gd`; D104. |
| Catching | Client sends launch parameters and committed Orb. Host validates inventory/capacity/target, re-derives closest approach, clamps the thrower's replicated Catching level to its legal0–30 range, rolls once and grants one durable creature to the winning character. Catching level is the only skill input to replicate for this roll; the client never submits odds or success. First committed valid claim wins; losers receive a reason. | `scripts/net/catch_arbiter.gd`, `scripts/net/water_capture_claims.gd`, ledger transaction; D103/D104 and WATER-20260906-personal-skill-replication. |
| Shared inventory verbs | Pickup, harvest, storage, building, dismantle, satchel, drop and item trade are versioned host transactions. A stale revision or losing claim is refused explicitly. | `world_ledger.gd`, `ledger_rpc.gd`; D103. |
| Presentation | Clients interpolate remote bodies, play VFX/audio/UI and may predict non-consequential motion. Presentation cannot award, damage, catch, open a gate or write a world flag. | replication/UI boundary; D96/D103. |

Every intent carries explicit stable ids, realm and a monotonic sequence or expected revision. Validate sender against the registered peer→character mapping; validate ownership of creature/item; validate current realm, phase, distance and resource; make the commit idempotent; then broadcast the authoritative delta. Duplicate packets must neither spend twice nor replay a reward.

**Recovered mechanism correction:** archived D96 and the encounter protocol describe host non-player bodies using a kinematic heightfield route. That remains the authority rationale, not a reliable description of current terrain collision. Current `scripts/world/playground_world.gd::_apply_dynamic_collision()` requests Terrain3D Dynamic/Game collision and `scripts/net/realm_shells.gd` moves simulation focus around occupants; its comments say FULL_GAME was a four-region lifecycle fix and is unsuitable for the 64-region corridor. Any implementation work starts from current Dynamic/Game behavior and re-verifies bodies, rather than restoring the archived mechanism by prose. Recovery: FINDINGS MP03/MP04; D96-encounter-host-owns-non-player-bodies-and-outcomes and D97-realm-shells-simulation-focus-and-cross-realm-session-residency.

Out of scope: trusting client hit/catch results, client world-file writes, client-authored enemy positions, rollback netcode, deterministic lockstep and anti-cheat claims beyond this authority boundary.

## 3. World state and portable character state

**Current split:** one `world_id` addresses `user://worlds/<world_id>/world.json`; one `character_id` addresses `user://characters/<character_id>/character.json`. The host alone saves the world. Every peer saves its own character. A legacy v22 slot splits on first load; the original remains untouched. Recovery: D100-character-persistence-portable-character-world-state-split-and-join-reconciliation, `MP_STATE_SEAM.md`.

| World-owned, host saved | Character-owned, portable |
|---|---|
| Day and clock; world seed; world progression flags; boss/trainer defeat; gates, relays and crossings; realm-key spend/open state; legendary freed/settled/claimed world facts; pickup/cache/harvest/once-only state; placed buildings including container state; farm plots; storage state/revision; death satchels; felled/harvested vegetation. | Stable identity/name/appearance; five-creature party and full creature instances; inventory; equipment/hotbar; satiety; personal tutorial/readiness/payoff flags; personal quest/map/fog and alpha-pin discovery; saddle fits; personal relics/hearts and selection; current realm and safe pose. Transient pending catch/build and active combat are never portable save facts. |

A behind-progress character may join an ahead world and act immediately against that world's state. Personal onboarding or rewards cannot relock a bridge the world has opened. Taking the same character to a second world carries the right column only and changes none of the new world's left column. World-scoped rewards happen once; mandatory personal rewards pay once per eligible participant through a per-source, per-character receipt and are never divided by party size.

**Current portable-state contract:** skill saves contain the actual five skill values/progress records. Migration from a save that predates a skill starts it at zero; no distance, catches or menu history may be invented. Host consumers clamp values and accept only authority-derived increments. Water capture replicates Catching alone for its probability input; Running, Riding, Swimming and Flying cannot alter a catch roll.

The host's merged view may expose both scopes to old consumers, but an undeclared flag is an error. A client cannot turn a personal write into a world write by choosing an id. Shared-camp readiness flags may be granted to every connected character when the host commits the required world pieces; they remain personal receipts, not ownership of the structure.

The chapter legendary follows the split precisely: `freed/offer settled/world recipient id` are one world fact; the resulting creature instance belongs to exactly one stable character. Reconnect or joining another world must not duplicate it. With five creatures, the recipient completes the permanent release/refusal ceremony; it never becomes a sixth slot. Recovery: D84, D96, D100-character-persistence-portable-character-world-state-split-and-join-reconciliation, FINDINGS MP08/MP16.

**Current Aquaryn transaction seam, acceptance open:** its catch-or-defeat handover uses the stricter capture journal. Before confirmation, persist stable catcher character id, stable creature id, committed Orb/claim and the pending portable-party receipt. Commit the creature once only when capacity remains; replay finishes or rolls back the same journal and can never create a sixth/storage overflow. `scripts/save/water_capture_transaction.gd` and `scripts/net/water_capture_claims.gd` are the baseline seam; D-water-capture-handover-journal remains the acceptance contract.

Out of scope: shared character files, importing world gates into another world, cloud account sync, character cloning, restoring a released creature from a second world and client authority over world saves.

## 4. Presence, realms, interiors and residency

Players may occupy different locations and, when supported, different realms in the same session. Every record and intent names its realm; code must not infer remote state from the local process's `Game.current_realm`. The host maintains a simulation shell for each occupied realm and tears it down only after its last occupant and live authoritative work leave. Replication, spawners and snapshots are realm-scoped. Current foundation: `realm_shells.gd`, `realm_transition.gd`, `realm_replication_scope.gd`; D97-realm-shells-simulation-focus-and-cross-realm-session-residency.

Residency uses the union of peer positions in a realm. A wild, pickup, harvest node, structure or encounter needed by any occupant remains authoritative even when outside the host player's visible streaming radius. Presentation nodes may stream out; ledger records and encounter state do not disappear. A peer disconnecting or changing realm mid-fight withdraws that participant; the opponent and other participants continue. If the last participant leaves, apply the encounter's authored reset/despawn rule once.

Interiors within a realm are per-player physical presence, not a party teleport. A doorway, cave transfer or stronghold transition moves only the entering character and owned deployed creature. Interior gates and encounter barriers are world-owned host facts; the host validates the same prerequisites and safe entry/exit for every peer. An interior cannot be a client-only copy where pickups, bosses or doors resolve twice. Enter/exit and reconnect save a safe pose; if that pose is no longer legal, seat the character at the authored safe entrance without rewinding gates or rewards.

Menus, dialogue, inventory, crafting, beds and storage are local overlays in co-op. They never pause the scene tree or another peer. Dialogue effects and purchases commit through authority; closing a local panel cannot cancel another player's transaction.

Realm/gate target checks:

- Gate keys and opened crossings are world facts committed once; personal relic abilities remain with the character.
- Admission is atomic: validate destination readiness, close/commit any pending transaction, despawn the old realm representation, load/seat the destination, then publish registry residency.
- A joining peer receives the host snapshot before world interaction is enabled; no pickup, combat or gate intent is accepted while snapshot/realm seating is incomplete.
- Sleep advances time only when every connected, non-downed character is in a valid bed; the host applies one night and grants personal sleeper effects. Current basis: D105 clock authority and Stage B sleep vote.

Out of scope: forced party tethering, host-only realm travel, pausing the world for one menu, separate copies of a shared dungeon and teleporting late joiners directly through unopened physical gates.

## 5. Join, late join, disconnect and reconnect

The handshake binds one peer id to one stable `character_id`, validates version/content/session capacity, uploads the character summary and returns the host world snapshot on the snapshot channel. Only then does the host seat the character in a supported realm and expose interaction.

**Current:** `peer_registry.gd` rebinds a known character id from a dead peer row to the new peer id. `multiplayer.json` declares a **120s** reconnect window, but its own comment says timed eviction is intent while the current registry row lasts for process lifetime. Document and test the actual eviction behavior before advertising a guaranteed 120-second grace period. Reconnect loads the character's own durable file, reconciles it with current host world deltas, restores the owned deployed creature at a safe pose and never replays claims/rewards already receipted.

Disconnect rules:

- Withdraw that peer from active encounters and votes; do not reset fights other players are continuing.
- Persist their portable character without granting uncommitted local predictions.
- Keep world-built structures, storage commits, harvested resources and gates because the world owns them.
- Drop or retain carried/transient items only through one declared host rule; never duplicate between character inventory and a world satchel.
- On host exit, save world once and character files independently, notify, then return peers to title. No election or migration.

Late joining the **world** always receives current gates, structures including chest contents, clock, defeated enemies and legendary disposition. It receives none of the host's personal fog, inventory or party. Recovery: D97, D100-character-persistence-portable-character-world-state-split-and-join-reconciliation, D103, D105; `MP_STATE_SEAM.md`, `STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md`.

## 6. Shared encounters and rewards

One host-owned encounter record contains id, realm, opponent identity/instance, authoritative HP/status/phase, participants with stable character and creature ids, RNG and commit sequence. A participant controls only their own deployed creature. Friendly strikes are refused. The host chooses enemy targets among admitted living participants and keeps one authoritative opponent outcome.

World consequences commit once. Every eligible participant receives authored XP, items and personal flags in full, guarded by a per-source/per-character receipt. XP and required items are not divided. A catch is different: one wild becomes one creature owned by the single winning catcher; everyone else receives the identity of the winner and the encounter resolution. Full party still refuses the catch.

### 6.1 Scaling: current baseline and target replacement

**Current source baseline:** `data/config/multiplayer.json` applies the following opponent attack/defence stat multiplier and attack-cooldown multiplier. It deliberately has no HP multiplier.

| Participants | Current ATK/DEF | Current cooldown |
|---:|---:|---:|
| 1 | 1.00 | 1.00 |
| 2 | 1.10 | 0.85 |
| 3 | 1.15 | 0.75 |
| 4 | 1.20 | 0.70 |

**Target design decision:** replace that table for ordinary shared opponents with:

`HP_multiplier(n) = 1 + 0.65 × (n − 1)`

`enemy_attack_power_multiplier(n) = 1.00`

`attack_cooldown_multiplier(n) = max(0.85, 1 − 0.05 × (n − 1))`

| Admitted participants | Target HP | Target attack/defence | Target cooldown |
|---:|---:|---:|---:|
| 1 | 1.00 | 1.00 / 1.00 | 1.00 |
| 2 | 1.65 | 1.00 / 1.00 | 0.95 |
| 3 | 2.30 | 1.00 / 1.00 | 0.90 |
| 4 | 2.95 | 1.00 / 1.00 | 0.85 |

Lock the participant count when each enemy starts. A player arriving during that enemy observes and may join at the **next enemy** in a trainer/boss sequence; a single-wild encounter has no next enemy, so the arrival waits for its resolution and is not paid for it. A departure removes its target immediately but does not shrink the current enemy's maximum or current HP. This prevents join/leave manipulation and makes one scaling value explain the whole enemy.

This target intentionally supersedes archived D106/encounter-protocol rules that forbid HP scaling and immediately admitted/rewarded late joiners. The change is explicit because the old rationale remains material: HP inflation can lengthen rather than improve a fight. The proposed +65% per additional player is below HP×players and removes the current attack/defence escalation, but it must not ship from arithmetic alone. Measure time-to-defeat, per-player incoming damage, target spread, tell frequency and boredom at 1/2/4 players across ordinary wilds, multi-creature trainers and bosses. Boss phases/add roles remain authored and take precedence over blindly multiplying a bar. Recovery: D106-encounter-participant-scaling-composition-first-no-hp-inflation-and-per-participant-rewards, `MP_ENCOUNTER_PROTOCOL.md` §§6/10, FINDINGS MP12.

Out of scope: scaling by player level, dynamic difficulty based on wins, spawning un-authored species, dividing rewards, mid-enemy late-join scaling and using HP alone as a boss phase.

## 7. Downed and revive

**Current:** multiplayer downed window **45s**; a teammate must **hold** interact for **3s** within **2.5m**; success restores 35% health and 35% stamina. Solo has no downed window. Evidence: `data/config/multiplayer.json::downed`, `scripts/player/downed_state.gd`; archived D-MP19. The held input conflicts with the standing no-held-button interaction rule.

**Target:** one interact tap starts a visible **3s** proximity revive. The reviver must remain within 2.5m and stationary. Damage to the reviver, movement beyond the allowed deadzone/radius, the downed target becoming invalid, realm/encounter exit, or pressing interact again cancels it. No button is held. Only the host advances and completes the revive clock; duplicate starts are idempotent and two revivers cannot grant twice. Retain the 45s window and 35% health/stamina until balance evidence changes them. A downed peer remains in connected-player counts for encounter targeting only when targetable by the encounter's declared rule, but is excluded from sleep readiness.

Out of scope: self-revive, revive items bypassing proximity, full-health revive, pausing the encounter, hold-to-revive and reviving across realms/interior boundaries.

## 8. Shared world verbs

| Verb | Current/target contract |
|---|---|
| Pickups/harvest | Host validates world availability and range; one claim/depletion; broadcast removal and inventory grant atomically. Current ledger foundation. |
| Building | Host validates recipe, inventory, collision and realm; debits and spawns one world record atomically. Client-built structures survive host save/reload and late join. Current foundation requiring end-to-end acceptance. |
| Storage | Host-owned container contents with monotonically increasing revision; expected-revision transaction; stale clients refresh. Building record carries its state through save. Current; D103 and recovered storage correction. |
| Item trade | Host transfers a declared item/count directly between registered characters or refuses; no drop-copy intermediate. Current Stage B scope. |
| Authored NPC creature swap | Existing `scripts/trade/creature_trade.gd` exchanges one outgoing creature for one deterministic NPC offer atomically, records one use per rotation and refuses the last owned creature. **Target co-op integration:** host validates ownership, offer/period and receipt, then commits the portable party delta once. **Target identity gap:** refuse starter and legendary-recipient outgoing creatures before mutation. Party size stays unchanged; peer-to-peer swaps and a trade market remain out of scope. D39/D103. |
| Satchel/death | Host creates one owner-tagged world satchel after final death, not on downed entry; recovery transaction cannot duplicate inventory. Current foundation. |
| Gates/story | Host commits one world flag and every peer restores presentation from it. Dialogue remains local; consequential effects use ledger intents. Current architecture. |
| Map/fog | Personal and portable; shared world changes may clear a shared threat but never reveal another player's unexplored map. Current contract. |
| Mount/Fly/Teleport | Owner controls its legal creature traversal; host validates state/speed/gates and remotes reconstruct rider/creature. Target acceptance remains required for each chapter promise. |

**Current Water reconstruction contract, end-to-end acceptance open:** validate saved slot, stable creature id/species, living and non-resting state, one of the five compatible swimmer ids, earned personal Swim Stone flag, owned swim saddle and a supported same-realm pose before restoring mounted state. Any failed field falls back to human-water state at the saved safe approach while preserving the exact trainer stamina and creature swim stamina; load/dismount/reconnect never refills either resource. Veilfall interior is a separate residency inside the same Water realm: entering it does not unload or mutate the exterior simulation used by another peer, and reconnect restores the correct interior/exterior identity before enabling input.

## 9. Validation and shipping evidence

Unit tests prove pure authority decisions; multi-process smokes prove transport and reconstruction; human LAN and Steam-invite sessions prove the game is understandable and playable. Keep mechanics checks brief and focused; transport work does not reopen a broad combat or progression test programme. Required evidence:

- Two-peer PR coverage for boot/join/leave, movement, world-ledger races, deploy/fight/catch, reward, save and reconnect. Three- and four-peer runs in the owner kit/nightly.
- Deterministic race tests: simultaneous pickup, harvest, storage withdrawal, building spend, catch and reward replay produce one commit.
- Host-position strike and catch tests include a client lying about origin/target and a stale/duplicate action sequence.
- Late join diffs its world snapshot against the host, then proves personal inventory/map/party remain its own.
- Reconnect during exploration, encounter, downed window, realm transition and interior occupancy; no duplicated body, creature, reward or legendary.
- Four characters with five creatures each reconstruct 20 durable instances and at most four active bodies; no hidden sixth and no cross-owner switching.
- Scaling target measured at 1/2/4 participants and each encounter shape. Record time-to-defeat, damage taken, tells per minute, reward eligibility and participant-lock behavior before replacing current data.
- Revive target verified under tap start, move, damage, re-press, timeout, two simultaneous revivers and packet duplication.
- Shared building/storage survives host save/reload and a late join. Client `user://worlds/` remains empty.
- Split-realm and same-realm-interior sessions keep realm-scoped spawns, gates and fights authoritative while another peer gathers or fights elsewhere.
- 150ms delay/30ms jitter encounter and catch runs; orphan-process cleanup; desync hashes; host exit under load.
- An outside tester hosts, three peers join over LAN, and the group fights, catches, gathers, builds, uses storage, advances a gate, saves and reconnects without developer help.
- On two ordinary Windows Steam clients with separate entitled accounts and networks, a friend accepts an invite with the game closed and again while it is running; both join without entering an address or changing router settings. Repeat with host plus three joiners, controller-only host/join/rejoin, full-session refusal, version/content mismatch, relay/direct-path changes where observable, host exit and invite/rejoin after a transient disconnect.
- Package evidence identifies the pinned Steamworks/GodotSteam versions, compatible Godot 4.7 Windows editor/export path, AppID test configuration outside source control, overlay behavior on ROG Ally and whether the chosen peer preserves the two logical channel purposes. No Steam store or effortless-internet claim precedes this proof.

No test result upgrades a target to current unless the implementation landed and the relevant human acceptance passed. Recovery coverage: D90, D95–D106 inclusive by full slug where duplicated numbers exist; `MP_ASSUMPTION_INVENTORY.md`, `SMOKE_SWEEP_PLAN.md`, `MP_ENCOUNTER_PROTOCOL.md`, `MP_NET_HARNESS_CONTRACT.md`, `MP_STATE_SEAM.md`, `MULTIPLAYER_CONVERSION_MAP.md`, `STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md`; FINDINGS MP01–MP21.

Out of scope for minimum release remains PvP, public matchmaking/lobby browsing, dedicated servers, host migration, a Tetherbound account service, voice, peer-to-peer creature trading or a trade market, cross-save service, more than four players and any world rule whose outcome depends on trusting a client's claimed success.

**External source status (checked 2026-09-19):** Valve's live Steamworks documentation supports lobby invites and newer peer networking with relay when appropriate. GodotSteam documents a MultiplayerPeer integration; this makes the direction plausible, not certified for this Godot 4.7 project. Recheck the pinned release, license, Steamworks SDK compatibility and export artifacts during implementation. Sources: [Valve multiplayer overview](https://partner.steamgames.com/doc/features/multiplayer), [Valve Steam Networking](https://partner.steamgames.com/doc/features/multiplayer/networking), [Valve Friends invite/join callbacks](https://partner.steamgames.com/doc/api/ISteamFriends), [GodotSteam MultiplayerPeer tutorial](https://godotsteam.com/tutorials/multiplayer_peer/), [GodotSteam build/status guidance](https://godotsteam.com/howto/multiplayer_peer/).
