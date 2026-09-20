# Technical architecture and implementation map

## 1. Baseline and status boundary

This map was checked against **b8eda885**. The design rewrite changes no code/config/assets. `design/*.md` labels current foundations and proposed targets; STATE tracks acceptance. Do not turn a target formula into a claim about current runtime.

The current implementation pass closes four biomes; eight biomes remain a future ambition. Eight good hours is an acceptable first clear, not a minimum to pad. Production assumes coding plus existing assets and tools, including the existing Meshy access under ART_DIRECTION's subject/reference gate. It assumes no new purchase, commission, paid composer or vendor dependency. Co-op now requires invitation joining without manual addresses/router setup. Current ENet LAN/direct-IP remains built; `ralph/invite-coop` contains an optional Steam lobby/invite/transport implementation, while internet acceptance remains open. MULTIPLAYER owns its contract. The owner also authorizes agent-drafted art references and Meshy submissions for scoped improvements; keep reference/provenance and candidate validation, without requiring owner-originated images.

**Optional Steam implementation branch:** `ralph/invite-coop` adds the lobby/invitation coordinator and native peer integration; the preceding baseline's “not built” refers to main. It remains unaccepted for internet play. Run `python tools/setup_steam_runtime.py` to install the pinned development runtime alongside stock Godot. It downloads GodotSteam4.20's `win64-g47-s164-gs420-editor.tar.xz` (SHA256 `b5bd13a3c1d6c2087b54607aad43865fa29d070d8992ef114ce17d955413149a`), source tag commit `e702a38efd8256ea2295f182f3fb3afecb096931`. Local configuration is `TETHERBOUND_STEAM_APP_ID`, then `SteamAppId`, then the local project AppID setting; no shared AppID480 default. Keep partner/private configuration outside source. `project.godot::steam/multiplayer_peer/max_channels=4` preserves logical lanes1/2 under4.20's `channel >= max_channels-1` fallback rule. Snapshot transport uses192KiB chunks with a64MiB total cap, a60s handshake/snapshot deadline and boundary delta replay after baseline admission. The optional binary is still Godot4.7 Compatibility; this is not a renderer/engine-version upgrade. `tools/net/probe_steam_host.gd` checks native initialization/socket/private lobby in an empty temporary project. `tools/net/probe_steam_session.gd` exercises the real title→Meadows→Steam host→save/leave path under isolated APPDATA. Neither sends invitations or proves a remote connection. Export templates, licensed distribution packaging, internet relay behavior and Ally overlay remain separate acceptance gates.

Godot4.7-stable, GDScript, Windows x86_64 primary, Linux x86_64 for CI/development. `project.godot` uses `GL Compatibility` / `gl_compatibility`,1920×1080 canvas-items UI. Terrain3D1.0.2 remains the installed terrain addon. Compatibility was selected after repeated owner Ally/Vulkan freezes; do not switch renderer without new device evidence.

**Correction:** ordinary directional shadows exist: `world_look.gd` enables the sun shadow and two-split mode, and `project.godot` configures the2048shadow map. Compatibility lacks SDFGI, volumetric fog and SSR, and does not support the Forward+ directional PCSS feature. See [Godot renderer documentation](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html). ART_DIRECTION specifies the attainable lighting approach and the remaining asset ceiling.

## 2. Runtime ownership and scenes

One registered autoload: `Game="*res://autoload/game_state.gd"`. Keep one. Inventory, party, map and progression are composed modules behind Game, not new global singletons. `autoload/party.gd::MAX_CREATURES=5` is enforced at add/transaction boundaries; no reserve/box. `inventory.gd` stores24slots and a legacy6-hotbar field, while five exposed bindings are the target UX. Preserve empty slot positions.

`scenes/ui/title_screen.tscn` starts the product. New Game enters Meadows; Continue restores the saved realm. Four world scenes are `meadows_playground.tscn`, `cloudreach_cliffs.tscn`, `stormwood.tscn`, `water_archipelago.tscn`. Interiors and headless multiplayer shells have distinct residency contracts; Water's Veilfall is player-local, never a whole-realm rebuild for all peers. The pinned tree has17scene files,433`test_*.gd`,265`smoke_*.gd`; these are a census, not timeless constants.

Meadows macro terrain is authored/baked, runtime scripts instantiate the world and its authored systems. Visibility ranges and collision residency are not general asynchronous content streaming. Cloudreach uses procedural stacked cliff meshes rather than Meadows Terrain3D. Stormwood and Water have actual world/finale consumers: do not recreate them from old “not built” notes.

## 3. Where behavior lives

| Concern | Current source/config/test anchors | New design work |
|---|---|---|
| Shared combat | `scripts/combat/combat_manager.gd`, `combat_ai.gd`, `combat_math.gd`, `combat_arena.gd`; `data/config/combat.json`, `type_chart.json`; `tests/test_combat_{math,ai,stagger,wind,burst}.gd` | Yskill/learnsets, normalized poise, explicit reactive AI, rendered spacing, readability and per-creature resource persistence. COMBAT. |
| Creature data/identity | `scripts/creatures/creature_instance.gd`, `progression.gd`, `bond_milestones.gd`, `evolution.gd`; `data/creatures/species.json`, `data/config/progression.json`, `bond_milestones.json` | Revised bond receipts, skill assignment, optional trait effects; no earned-node loss. CREATURES. |
| Catch/transactions | `scripts/combat/catch_math.gd`, `orb.gd`; `scripts/net/catch_arbiter.gd`, `scripts/save/water_capture_transaction.gd` | Integrate new states without bypassing capacity/host/Water codec. |
| Inputs/UI | `scripts/ui/input_owner.gd`, `game_menu.gd`, `playground_hud.gd`, `tab_creatures.gd`, `tab_backpack.gd`; `data/config/menu.json`; `project.godot` | Ycombat skill versus world Satchel; five-slot migration; strain/cooldown/readiness; tap climb. Tap revive input is implemented in `downed_state.gd` on the first-expedition branch; authority/full downed-player presentation remain open. UX. |
| Care/rest/build | `scripts/world/night_rest.gd`, `scripts/creatures/creature_condition.gd`, `scripts/ui/creature_bed_panel.gd`, `scripts/build/`, `scripts/ui/craft_panel.gd`; `data/items/buildables.json`, `data/recipes/` | Bounded injury, no potion bypass, exact refund/capacity/bed state, earned-day stock/rest receipts. SYSTEMS. |
| Region content | `scripts/data/band_content.gd`; `data/config/bands/`, `chapter_curve.json`; `cloudreach_*`, `stormwood_*`, `water_*` configs | Useful detour/reward/route integration, not a duplicate quest engine. WORLD/PROGRESSION. |
| Set pieces | `scripts/world/stronghold.gd`, `stronghold_climax.gd`, `tether_relay.gd`; later realm world/finale scripts | BOSSES target mechanics, actual-scale arena and aftermath proof. |
| Traversal | `scripts/world/riding_controller.gd`, Fly and Water controllers/configs, `stormwood_arches.json` | Galewisp/Ripplet promises; no-hold climb; safe mounting/landing/gates. |
| Time/weather | `scripts/world/day_cycle.gd`, `world_weather.gd`, `world_look.gd`; `data/config/art.json`, `weather.json` | Retain saved clock; no blanket survival penalties. |
| Audio | `scripts/audio/audio_manager.gd`, `world_audio.gd`, `data/config/audio.json` | Owner-produced final cue assets from authorized existing/generated/recorded sources, chapter state routing/mix,22music deliverables; not a new manager. AUDIO. |
| Network | `scripts/net/session.gd`, `peer_registry.gd`, `scripts/mp/join_driver.gd`, `encounter_host.gd`, `world_ledger.gd`, `realm_shells.gd`, `realm_transition.gd`, `realm_replication_scope.gd`, `ledger_rpc.gd` | Session constructs ENet peers; identity/capacity admission and readable refusal now precede snapshots on the Meadows payoff branch. One spare transport handshake slot is not a fifth admitted player. The optional Steam branch has lobby/invite/transport code and focused local evidence; remote relay, build/content compatibility and packaging remain unproved. Preserve stable characters, authority, save receipts and both logical traffic purposes; prove compatible Godot4.7 packaging. MULTIPLAYER. |
| Persistence | `scripts/save/save_game.gd`, `world_save.gd`, `character_save.gd`, `atomic_save_file.gd`, `realm_reward_migration.gd` | `fabba89e9` has bounded world-instance/per-character reward receipts and authoritative split-locator refusal; portable slot-ID rename and legacy receipt ambiguity remain open. |

Exact source file expansions matter: brace notation in this table abbreviates existing siblings. Search before adding a class. Large world/HUD scripts are integration risks, not permission for a full rewrite. No duplicate camera, inventory, build, region-loading or audio system.

## 4. Data contracts

Tunables belong in data/config or existing species/move/encounter catalogues. Presentation settings belong to the domain's existing config. Do not scatter a target timing through several scripts. Menus are data-described tabs/actions, tested by `tests/test_menu_data.gd`.

Meadows positional content lives per band: `data/config/bands/<band>/spawns.json`, trainers/harvest/pickups/props and per-band vegetation placements. `band_content.gd::BANDS` explicitly lists five IDs and merges by stable `order`, not filesystem enumeration. `order` seeds spawn scatter/level/IV/trait/shiny identity; preserve it across edits. Global vegetation rules are not positional rows. `tests/test_band_content.gd` checks merged baselines.

Pinned catalogue:57base species,12Water runtime adapters,53base model paths,52moves,18TMs,89base items,31recipes in the base recipe files plus10separately structured Water rows,12buildables. Do not sum namespaced aliases as69unique visual concepts. Water encounter/roster/crafting schemas differ from Meadows; use their adapters rather than forcing all JSON through one assumed key shape.

All story flags have declared world/personal/realm scope. A UI pin is derived state. NPC one-for-one creature trades differ from peer item trades; peer creature trading is out. No trainer-owned or alternate starter source is introduced through a new table.

## 5. Save, migration and authority

Current merged `save_game.gd::VERSION=25`; split world and character formats are independently versioned at2 and3. The bumps protect the host reward journal and portable reward escrow from older builds that would silently discard them. Prior formats load with empty/default new state, while newer files are refused. Slot0autosave, four manual slots1–4. Loading missing/corrupt/newer data must fail without mutating live state. Auto-load on boot remains opt-in so shared smoke user directories do not cross-contaminate tests.

Ordinary slot load resolves `split_locator` before applying state; older slots without that metadata require exactly one complete deterministic split pair. Physical canonical or `.previous` file presence establishes prior authority even if unreadable. Existing valid-backup fallback remains; unresolved, corrupt or ambiguous authority refuses instead of recreating stale state from the merged slot. When a character's `last_world_id` differs from the selected home world, its inventory/escrow persist, foreign pose and pending entry clear, and the slot's saved realm selects the normal authored spawn and corresponding realm map. Focused proof is at `ec9671d4c`; cross-host slot-ID renaming remains open.

**Corrections to the old Technical:** clock state is persisted/restored; placed storage contents are synchronized into placed-building records before save. Neither is an unbuilt system. Preserve party identities/traits/bond/evolution/boosts, inventory empty positions/hotbar, progression, satiety, fog/map, multiple death satchels, placed buildings/storage/beds, felled vegetation/piles, farm state, player pose/world seed, realm state and reward journals.

World files are host-owned; portable character files carry their stable character/team state. Realm-local position/buildings/bags are tagged by realm and world. Character import is a trust boundary: no stale snapshot may overwrite a committed host transaction or mint a claimed legendary. For `reward_grant` items/flags, the host atomically saves a stable delivery before publication, the addressed character atomically saves its escrow or settled inventory before ACK, and the host saves acceptance only after binding that ACK sender to the registry character. Reconnect replays pending world rows after snapshot admission; duplicate delivery is idempotent and a full bag remains pending without partial grant. Focused final proof covers merged version25, world2 and character3; legacy peer-ID receipt ambiguity and slot-based portable-ID renaming remain known limits.

**Planned schema work, not implemented in this PR:** injury fraction and recovery state; per-creature landmark credit and migrated bond completion; L4 skill/equipped skill and relevant cooldown state; three selected tournament entrant IDs with ownership validation; earned-rest/vendor receipt; no-loss sixth-hotbar-binding migration; Ripplet attuned anchor/cooldown; Tidewake regional ending/homecoming playback flags. Decide each future version increment at implementation based on then-current schema.

Every new mutation declares authority, validation, idempotency key, commit order, failure rollback, persistence and reconnect behavior in its PR. Multiple participants receive personal authored rewards once; one physical wild/legendary remains one creature. Host-authoritative combat outcomes, local presentation and affected-actor hitstop use separate clocks. New scaling uses unscaled base values and unscaled catch stats, preventing four-player captures from owning inflated stats.

## 6. Terrain, scatter and physical truth

Meadows bake entrypoints remain `scripts/world/build_playground_terrain.gd` and `scripts/world/bake_playground_scatter.gd`; output `data/terrain/playground/` and `data/scatter/playground/`. Scatter rule/global/per-band vegetation edits require affected bake output in the same coherent change. CI freshness failures are real; stale output has caused multi-minute boot recomputation.

After asset/bake change re-import before capture; a script may otherwise render the cached previous asset. Change flats/path/apron height only with the terrain bake; a moved NPC or prop alone does not justify rebaking the world. Preserve output identity and avoid unrelated bulk bake churn.

Ask `ground_height_at(x,z)` first for terrain height; raycast only for structures/surfaces terrain does not describe. Terrain3D downward-ray misses are a known failure class despite shape movement working. A paper route needs supported footprint, slope, actual body clearance, interact range, camera and ordinary traversal checks. No teleport witness closes an approach collision defect.

Collision residency uses the union of active peer regions/cells, never their mean position. Current performance config:100m collision radius,0.5s update,32m cells;8ms shell build budget,100ms client crossing slices;8m interaction grid. `scatter_lod_ranges=false`, `structure_visibility_ranges=true` at baseline. These are tunables with historical measurements, not proof of current Ally speed.

## 7. Inputs and lifecycle hazards

Every new modal joins the `input_owner` group, blocks world readers beneath it, sets/restores focus and restores mouse mode on every exit. Menus never pause a multi-peer session; input ownership is required even when solo tree pause happens. `suppress_pause_reopen()` prevents a closing B edge from reopening a shell. The old build-menu/D-pad bleed consumed hotbar items underneath a non-pausing menu; keep that regression covered.

`project.godot` holds defaults, never runtime user writes. Rebindings layer over boot defaults and prompts use current bindings/device. Combat owns Y/A and refuses world menus according to UX. Former B/Escape run/cancel clashes must be verified under the new context contract rather than immortalized as design. Required controls use taps, not hold/chord escape hatches.

Preserve provider lifetime across freed/rebuilt HUD/world/realm nodes; cached stale interactables, aim-state residue, reward queues and finalized-death withdrawal have caused real failures. Add targeted regression at the originating state transition, not only the final symptom. Full/occupied inventory, current and migrated saves, separated peers and reclaimed beds are normal test cases.

## 8. Build, tests and captures

From repo root with Godot4.7 available:

```text
godot --headless --path . --import
godot --headless --path . --script tests/run_tests.gd
godot --headless --path . --script tests/run_tests.gd -- --only=test_combat_math.gd
godot --headless --path . --script tests/run_tests.gd -- --shard=1/4
```

`tests/run_tests.gd` discovers test files and methods; `--only` filters before round-robin shard selection. A missing selector is an error, not a green empty suite. `tests/test_case.gd` is the harness; no GUT. Broader `smoke_*.gd` scene scripts use their own entrypoints; inspect each invocation and required fixture.

Tests run headless without a renderer. **Never combine `--headless` with `--rendering-driver opengl3` for capture**; this invocation has hung silently. Windows capture uses an ordinary hidden/controlled Godot render window with `--path . --rendering-driver opengl3 --resolution 1280x800 --script tools/<capture>.gd`. Linux uses:

```sh
xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/<capture>.gd
```

One import/export/render writer per machine. Independent pure read-only tests can parallelize against an already-imported cache; full Terrain3D smokes serialize if memory would contend. `tools/capture_diag_minimal.gd` is a bounded invocation check; fix capture setup before blaming scene art. Inspect stale process cwd before worktree cleanup; do not kill unrelated user processes.

## 9. CI and packaging

`.github/workflows/ci.yml` is execution truth: import, targeted grouped/sharded tests, scatter freshness and Windows export gates. CI runs PRs/main pushes. Open draft PR early; never push main directly. Review actual job/log execution, not just green status or elapsed time.

Markdown/docs/site/ralph paths may intentionally take the docs-only path. A green docs-only run is **not game validation**. Preserve unconditional change detection; do not add a markdown paths-ignore trigger that prevents workflow completion events. Branch comparison uses merge-base with main; otherwise a final docs commit could hide earlier code. Empty diff fails safe to build. `[skip ci]` is only a WIP checkpoint, not final verification.

`release.yml` publication and export are distinct. Check the actual release asset timestamp/hash before telling the owner a landed change is playable. Test the downloaded package, not only editor startup. Exclude reference docs/source archives and preserve credits/provenance for shipped assets. No auto-publication is authorized by a documentation rewrite.

## 10. Performance and technical acceptance

Use `tools/perf_render_stats.gd` for structural draw/primitive observations, not handheld FPS claims. Correct stands: `hall_approach`≤4,000draws; provisional `band1_open`≤7,500draws/12Mprimitives. ≤4outdoor shadowed Omni/Spot lights overlap, normally0; Hall12interior lights separately composed. The archived total-light cap was unspecified; do not invent one. MultiMesh batches make draw count a poor proxy for vegetation GPU cost; no universal scatter-per-hectare ceiling.

ACCEPTANCE owns the newly proposed15W1080pAlly30fps percentile/memory/transition tests. They are unproven and may require evidence-based quality/performance work; do not quietly call a lower-resolution run equivalent. Host realm-shell load, GPU throughput, long-session memory and true device frame pacing require the device.

Out of scope: engine/renderer migration, new global framework, general scene-streaming rewrite, dedicated server service, console port, replacement test harness or infrastructure work disconnected from a player-path defect.
