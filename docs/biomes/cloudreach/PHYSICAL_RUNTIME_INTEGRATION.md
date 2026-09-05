# Cloudreach physical runtime integration

The new `scripts/world/cloudreach_physical_runtime.gd` implements the physical chapter events against the existing Game progression, inventory, Fly, rest, pickup and NPC systems. It does not consume the dialogue queue or decide when a creature battle is won. Creature content remains deferred.

## Install once in CloudreachChapter

This integration is now installed in `scripts/world/cloudreach_chapter.gd`. The public `physical_runtime()` and `events_adapter()` accessors expose the two adapters. `npc_bodies()` returns canonical NPC IDs mapped to their current body nodes; refresh that snapshot after relocation or scene reload.

Keep CloudreachChapter's arrival detection, two lower inspection anchors, existing event adapter, dialogue modal/input handling, and one dialogue queue consumer. Replace its opening-only People, pickup and rest construction with one `CloudreachPhysicalRuntime` node; otherwise Aila, two caches and Galefoot rest will be duplicated.

After adding the node to the tree, call:

```gdscript
physical.configure(
    player, player.fly_controller, Callable(events, "emit_event"),
    func(at: Vector3) -> Vector3:
        var height := float(world.ground_height_near(at))
        return Vector3.INF if is_nan(height) or absf(height - at.y) > 8.0 else Vector3(at.x, height, at.z)
)
```

The ground callback must resolve the intended elevation. It must not sample the highest XZ surface or invent a floor. The runtime emits `placement_failed(id, at)` for invalid geometry. Authored overrides in `data/config/cloudreach_physical_runtime.json` place draft pickups on current route/landmark surfaces without changing permanent cache IDs. Production placement smoke checks these overrides; final composition/accessibility still requires rendered and continuous evidence.

When the existing chapter drains a Cloudreach dialogue effect, call `physical.consume_dialogue_effect(effect)` instead of unconditionally prefixing `dialogue:`. This enforces the five dialogue guards, including three physical shrine vanes. Neri's report dispatches the canonical `side:packs_on_the_wrong_side:report_to_neri` event directly. An unrecognized or premature effect returns false. Do not fall back to unguarded dispatch after rejection.

## Traversal and physical progress

The real launch marker is available after Maela's readiness conversation. It grants only temporary, bounded flight-trial authorization. Three wind rings must be crossed in order while the production Fly controller is airborne; a real floor-contact landing back at the perch completes the trial and unlocks Fly. A ground walk, out-of-order ring, arbitrary landing signal, failed attempt, recovery or save reload cannot complete it. Trial progress itself is intentionally transient.

An owned, healthy active Fly-capable creature remains the preferred carrier. A valid
five-creature Meadows team is not required to have caught one, however, so Maela lends
the installed Galecrest presentation during the trial and subsequent Cloudreach travel
when no owned carrier is eligible. This transient story carrier is never added to the
party, never saved or caught, cannot cross realms, and earns no bond credit for an
unrelated active creature. It is the explicit no-sixth-slot fallback, not storage.

The runtime registers bounded currents and three volumetric restrictions on Fly. It observes verified safe ground and uses Fly's existing ray-validated recovery when an ordinary walking fall passes below the last safe anchor. The world must retain collision on actual cliff/route geometry and its grounded progression gates. The runtime cannot make a visual-only rock collidable.

High Roost arrival requires observed Fly followed by a real landing inside its position and height bounds. The three physical vane interactions set only their named durable flags. Sora can then interpret the record; a separate windlass interaction releases the grounded route. Entering that route on foot completes Act II. Each upper anchor requires a real nearby interaction; the summit feed also requires Voss's genuine defeat.

Each aerial side survey requires visiting its marked air approach during the same flight before landing at the relevant perch. The three bells and courier pack/delivery are separate physical prompts. Neri's later conversation reports a delivery already recorded by the shelter prompt.

## NPCs, camps and findables

All 11 canonical NPCs use the installed body profiles and authored stateful conversations. The runtime honors Aila/Neri relocation after dialogue closes. Kelm's resource advice and Rusk's defense advice have separate guarded prompts. Aila uses the clean dedicated portrait; other portrait frames remain explicitly hidden.

All 19 chapter pickups retain realm + placement persistence and their canonical counts/items. Their unlock flags control spawning. All five camps reuse the production RestPoint/night-rest/autosave/crafting path and installed bed prop. Loading an earlier save reconstructs previously collected caches and removes later unlocked placements.

The runtime does not create a second inventory, restore resources, grant a creature, assign an extra party slot, or fabricate an encounter result. Resource nodes remain owned by `cloudreach_resource_patch.gd`/the world.

## Encounter handoff

The encounter owner calls `physical.encounter_won(id)` only after a genuine victory. It covers all seven IDs in `trainer_ladder`: Ila, Orrin, Senn, Maela, Tavi, Voss and Veyra. IDs and prerequisites are validated; the canonical defeat flag is idempotent. The Veyra callback uses the shared chapter encounter event and does not break relays or restore the world. The finale controller continues to own those physical steps.

An optional `reward_callback(id) -> bool` argument handles the encounter system's existing durable payout. Returning true records `cloudreach_payout:<id>` once; failure leaves payout pending for a later retry. No reward quantities or replacement combat economy are invented here. The callback must complete inventory/XP rewards synchronously and the caller should save after `encounter_won` returns.

The approved circuit mapping is lower = Ila + Orrin; Windscar = Senn + Maela's actual mentor battle. The physical flight-gate trial is separate and never substitutes for either battle. Progression reconciliation advances side steps once their existing reveal/prerequisite conditions hold.

## Verification and remaining evidence

- `tests/test_cloudreach_physical_runtime.gd`: guards, data completeness, ordered airborne gates, stacked-elevation landing rejection, dialogue/physical separation, all encounter IDs, circuit requirements, all 19 cache identities, five camp contracts and bounded currents.
- `tests/smoke_cloudreach_physical_runtime.gd`: isolated production Player, Fly, collision floor, Interactable arbiter and synthetic real input. Walks to repair, spends fiber once, launches and flies three gates, lands to unlock Fly, makes another legitimate flight/landing, aligns vanes, reads truth, turns windlass, enters ground route, reloads flags and rejects dialogue boss completion. It uses scaled fixture coordinates and repositions between later stations; it is not a continuous-world acceptance run.
- `tests/smoke_cloudreach_physical_placements.gd`: instantiates the production Cloudreach scene and checks intended ground under 56 physical/NPC/camp/pickup/trigger placements.

Completed package validation: focused unit suite passed 6 tests / 248 assertions; the isolated real-input smoke passed 33 assertions; the production geometry probe passed all 56 placements after correcting one bell and five NPC draft positions through the new data overrides. The combined cast and physical unit selection passed 13 tests / 1,034 assertions. `git diff --check` is clean for this package.

Integrated validation additionally passes 33 unit tests / 1,143 assertions across Act I, cast, physical runtime and pickup-glow behavior, plus the production Act I gate/camp/Aila/anchors/candy/rest/disk-reload smoke. That smoke verifies one Aila, one lower candy placement and one Galefoot camp before and after reload. Integration exposed a freed-cache loop and stale glow emitters after resource regrowth; both are fixed. `smoke_pickup_glow_lifecycle.gd` passes 11 live assertions covering cache collection, freed/detached emitters, Cloudberry day regrowth and scene replacement while preserving hidden-live-emitter behavior. A blank-model TM cache warning remains a presentation task; it does not block the item/persistence path.

The continuous arrival walk also passes after integration: the production controller follows every authored arrival-road waypoint without position writes and reaches Aila's sole offered interaction at approximately `(-275.14, 180.00, 517.50)`.

Remaining integration evidence: full authored flight through the large mountain currents; collision-safe continuous camp/bridge/perch travel; rest/save/load and all-cache coverage in the full production scene; rendered marker/material and NPC presentation; frame time/draw calls; actual encounter callbacks; final visual review. Passing isolated tests does not establish these outcomes.
