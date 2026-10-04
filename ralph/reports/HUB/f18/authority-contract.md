# F18 authority integration proposal

Source: worktree `D:/tetherbound/feature-f18`, read baseline `5c2c964ebaa8e25f933355324725be324218bc44`. This is a bounded proposal for ROOT's single shared-file writer. No shared runtime source was edited, no Godot/import/render/export/gameplay was run, and no acceptance criterion is certified by this artifact.

Frozen proposal files:

| Artifact | SHA256 |
| --- | --- |
| `.tmp/f18-authority/portal_action_policy.gd` | `BDF9FDCF1021CC03D69D53B0758C67A31D1C15D456E51C76564FBA13170210A3` |
| `.tmp/f18-authority/portal_delivery.gd` | `9759A635E2EFD166A6EE1C959E387A051EA31444E2D1F5511506AA5F7FCA2297` |
| `.tmp/f18-authority/protected-keys-and-waystones.patch` | `5C5D3EC7C1169018152F4309FC44A80EE2C589C75CE72C217E4F04F3118AA7C4` |

`git apply --check --ignore-space-change .tmp/f18-authority/protected-keys-and-waystones.patch` passed against this checkout. Plain `git apply --check` rejected CRLF working-file context; this was corrected with the whitespace-aware read-only check. Python alias was absent, so the generator used `C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`. Neither result is an engine or gameplay proof.

## UI and authority boundary

`Game.request_portal_action(payload)` returns `{ok, request_id, reason}` for **queue acceptance** only. Game mints a local correlation identity, keeps the outstanding request map, and defers result delivery so the component sets `_pending` before the signal runs. The host independently mints the immutable action identity. Never use a client correlation id as a durable spend receipt or authenticated actor.

`Game.portal_action_result(result)` supplies `kind, request_id, ok, reason, character_id`, plus `use_id` on a successful Home Key begin. `request_id` echoes the queued local handle. `use_id` is the host's immutable begin identity; finish/cancel payloads carry `{kind, use_id}`. The policy's `prepared.use_id` must be promoted into the begin result. `HomeKey.show_remote_raise(actor, use_id)` and `end_remote_raise` are host presentation callbacks only.

`Game.portal_view(arch_id)` supplies `ready, open, has_key, destination_label, reason, recommended_level`. `ready=false` until admission and retained pending settlement are reconciled. Access is per traveler: `world.portal_unlocks OR admitted_character.portal_unlocks`, with Meadows always available. A personal unlock does not manufacture a world unlock for another host. A personally unlocked traveler with a newly earned key may deliberately use that key at the new host's still-locked arch; a world-unlocked traveler with their own earned key may establish their own portable unlock. The policy therefore refuses `portal_unlock` only when **both world and character** have unlocked it. F18's component needs a separate Use Key affordance alongside Enter for either case.

The exact allowed payloads are `{kind}` for Home Key begin; `{kind,use_id}` for finish/cancel; `{kind,arch_id}` for unlock/enter; `{kind,waystone_id}` for touch. Host rejects extras, including actor, character, world, realm, destination, time, position, item and quantity. The host resolves sender through Session's actual peer registry. Local refusal convenience is presentation only.

## Concrete policy module and required adapter facts

`portal_action_policy.gd` is a pure host-owned transient state machine. Session owns one instance, binds the actual host world namespace, and assembles `context` from its existing admitted character and body authority. Context requires `peer_id, character_id, world_instance_id, realm, position, damage_revision`, six actual booleans (`combat, dialogue, cutscene, swimming, flying, downed`), actual `home_key_owned`, `owned_portal_keys`, personal/world unlock arrays and personal waystone maps. Actual mounted targets supply `arch_positions` and `waystone_positions`; authored x/z anchors are not proof of safe seated runtime coordinates.

The policy reads current `data/config/portals.json` and `waystones.json`, validates arch/stone proximity, runs the configured host duration, cancels on combat/damage/refusal/peer disconnect, and prepares a one-use host travel permit. It never grants keys, unlocks progress or moves bodies. The host must tick `cancel_invalid` and `tick_expired(host_monotonic_msec)`; expiry uses configured Home Key response timeout so a lost begin result cannot strand a channel. Disconnect must call `disconnected`, and each async phase must check the current session/world identity again before acting.

Home Key arrival is `meadows` / `hall_home`; ROOT must register that actual Hall arrival and offset simultaneous arrivals safely. Same-realm Home Key use must seat only the requester at the Hall, rather than fail because `enter_realm` sees the same realm. For arch travel, `tidewake` maps to runtime `water`; other three live biome ids are unchanged. A saved last stone must be an activated canonical id in that same biome. With none, use the existing configured actual entry id; do not infer a coordinate or teleport before realm admission.

**Required transport change:** `scripts/net/realm_transition.gd::_request` currently accepts any client-chosen `to` whose scene exists. That cannot remain as an ordinary travel bypass. ROOT must make the existing receiver/fence mechanism consume the host permit for the exact peer/stable character/world/origin and use its host-selected realm/entry; preserve rollback and reconnect admission paths separately. F18 owned crossing retirement does not close this shared bypass. No client calls `Game.enter_realm(..., bypass_gate=true)` to implement this boundary.

## Durable portal spend and owner recovery

The existing Session/CharacterAuthority debit APIs are the correct single registry: `host_stage_portal_debit`, `host_commit_portal_debit`, `host_finish_portal_debit`. Do not clone admitted inventory or add a second mutable character authority. Existing staging removes a key from its validated snapshot by slot; it does not need `Inventory.remove`. The proposed generic `remove` guard remains unconditional for protected keys. Do not add a public allow-protected boolean escape.

`portal_delivery.gd` supplies a typed immutable v2 row and actual owner settlement implementation. New receipts use a hash of `(world_instance, biome, stable_character)` so a newly earned key can unlock a different host world. The current v1 receipt `portal_unlock:<biome>:<character>` permanently suppresses keys in later worlds. ROOT must retain existing v1 rows as v1, explicitly extend the escrow decoder/admission projection to accept typed v2 rows, and update CharacterAuthority's stage/protected-key matching to the same namespace. Do not reinterpret or discard uncertain old rows. Use only the four actual item ids in F18 data; `portal_key_*` catalogue ids are reserved placeholders, not item aliases or grants.

The world journal can use the existing `WorldState.reward_deliveries` carrier with the new `portal_unlock` discriminator. ROOT must extend its validators/save checks/delta dispatch and `LedgerRpc._settle_reward_deliveries` to route this discriminator **before** the ordinary reward processor. This codec grants no item. The bounded synchronous commit order is:

1. Flush fallback before preparing the actor snapshot; if another fallback starts, refuse. Resolve actual owned key from the admitted record and existing accepted host deliveries; reject malformed or repeated count.
2. Stage the character debit with an immutable private stage token. Prepare world unlock plus exact pending delivery row; freeze a complete rollback snapshot of world/ledger revisions and the staged character state.
3. Promote the staged admitted debit, then perform the existing real `save_world_prepared` bool save. On failure, roll back world and stage together and publish nothing. On success, finish the stage and only then publish the exact journal row/unlock to peers. A failed later owner save never refunds the host's durable commit.
4. Owner dispatch calls `settle_owner` only for a validated committed host row. It finds the actual canonical key once, removes that key, writes personal unlock plus settled receipt, and performs `save_character_prepared`. If the bool save fails, it restores only this mutation and sends no ACK/success. The world row remains pending and retries through admitted join/reload. A missing not-yet-delivered earned key stays pending; it never creates a key or unlock for free.
5. ACK identifies only the immutable receipt and authenticated sender. The host looks up its own row, verifies exact owner/namespace, marks accepted, and bool-saves that status with rollback on failure. Lost ACK resends the settled receipt without a second debit. Rejoin replays pending rows from the actual world journal. Host crash before the world save leaves no commit; crash after it retains an unacknowledged payable settlement.

`portal_delivery.valid/world_errors` and `settle_owner` are usable code, but the journal producer, serializer dispatch, versioned decoder and ACK transport are still ROOT-owned integration work. They are not activated by the lane and are not an acceptance claim.

## Key protection and waystone schema patch

The generated patch has exactly six shared paths: `autoload/inventory.gd`, `scripts/world/death_satchel_rules.gd`, `scripts/net/satchel_escrow.gd`, `scripts/net/world_ledger.gd`, `data/schema/character_state.schema.json`, `scripts/data/redesign_state.gd`. It uses authored `protected_key=true`, rejects generic remove/drop/drain and forged ledger drop/trade, prevents satchel deposit/withdraw, and ensures death escrow snapshots **and removes only nonkeys**. Inventory drain protection alone was insufficient: `SatchelEscrow.begin_drop` snapshots all slots before drain.

Waystone schema currently allows only `*_entry`; the validator additionally rejects every nonentry id. The patch enumerates actual F18 config ids per biome and validates config membership. Entry-only defaults are preserved. ROOT must mirror the same actual IDs into the F16 reserved `data/schema/waystones.json` catalogue or explicitly route schema validation to the actual runtime catalogue, retaining eight reserved slots. No invented free activation follows from a schema enum.

Each touch needs a host-retained pending absolute personal update with sequence/revision to preserve last-touch ordering through bool-save failure, ACK loss and peer rejoin. Only the owner persists the character. A stale ACK cannot clear a newer touch. ROOT should reuse the admitted CharacterAuthority record and its pending-save pattern, not let a client submit replacement `last_waystones` maps. Validating source configuration does not prove mounted stone safety, the ordinary station loop, the backpack affordance, full animation or co-op movement.

## Outstanding proof and owner defaults

No F18 criterion can close from these proposals. ROOT must run one frozen named engine ticket for actual Home Key give/use/refusal/animation, protected-item death/drop/sale/trade, canonical portal-only realm path including malicious raw realm request, three-to-five real stones in every biome, solo save loop and two-peer personal/world/portable unlock plus failed save/ACK/rejoin interleavings. Gameplay and visual evidence must identify the exact integrated source and a different strict reviewer.

Conservative settled defaults: per-traveler personal-or-world access; Home Key works inside strongholds outside the refusal list; home arch returns to the last Meadows waystone; no level gate; no free item producer; fifth arch stays sealed. F18 implements its presentation under the explicit feature ownership allocation; F20 owns ending and credits. No new owner-only product choice is resolved by this proposal. F17 required integration/proof dependency and ROOT's serialized engine/landing token remain external gates.

## Visible-session continuation: fifth arch and cancellation

The existing Hall id is `biome5`, with item `fifth_portal_key`. The proposal does not invent a `fifth` alias. Shared `portal_view("biome5")` adds `fifth_arch_stirred` (host/own presentation) and `character_stirred` (this character's settled receipt); it must always return `open=false`. The personal stir fact comes from its immutable `portal_unlock` transaction receipt, since current character schema has no fifth flag. The world fact is `redesign_world.fifth_arch_stirred`. A fifth spend never appends biome5 to portal_unlocks. `show_committed_stir` receives the host's exact durable result (`kind=portal_unlock`, `arch_id=biome5`, `ok=true`, `durable=true`, nonempty request/character/world instance ids), then presents glow, original synthesized low hum, dust and the settled one-line remark. Refresh/reload silently restores glow. No missing `rift_hum` placeholder cue is used. Audibility and visual quality are unproven until ROOT's runtime capture.

Home Key takes input while confirming its begin request. ROOT's refusal assembler must not misclassify that input owner as dialogue/cutscene. B or timeout during confirmation records an abandoned request; a delayed approved begin is cancelled by its actual host use id without replaying a local raise. An unsolicited trusted cancellation may match the current approved use id. Remote raises expire and restore their rig without taking local input. Unknown timeout outcomes tell the player to check their position rather than promise an origin that may already have committed.

F20 needs the authoritative accepted finale outcome and Home Key arrival lineage from ROOT: world/session/stable character, accepted host permit, origin and destination, departure/arrival identities, actual grounded safe Hall arrival, and durable completion. Presentation cannot produce those facts. ROOT must incorporate them in its shared `regional_ending_context` contract after real arrival.

Named `component_rules.gd` is authored for ROOT's serialized engine batch. Its host contexts are synthetic unit fixtures and cannot close runtime/save/co-op/ordinary-input criteria. `check_content.mjs` passed only authored-content integrity: 5 Meadows, 5 Tidewake, 4 Cloudreach, 5 Stormwood anchors, actual key metadata and opening effect. It does not prove mounted stones or runtime inventory protection.
