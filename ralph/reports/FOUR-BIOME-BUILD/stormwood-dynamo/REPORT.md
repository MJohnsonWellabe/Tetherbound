# Stormwood Dynamo controller — 2026-09-07

## Outcome

The Stormheart Dynamo now mounts as a separate host-owned climax controller
over the production Stormwood trainer transport. Captain Marrow is not awarded
when the last roster creature falls: that opens the directly piloted conduit
run. The victory transaction occurs only after four distinct, host-validated
conduit strikes complete inside one four-bank cycle.

## Player-facing sequence

1. The existing chapter gates Kestrel and the climb to the core. Marrow's prompt
   refuses before both durable flags are present.
2. Marrow's authored five-creature roster fights while the four capacitor banks
   telegraph and discharge in order. Three grounded plates override every lane.
3. At two of five creatures remaining, Overload shortens the charge/recovery
   windows. Exposed companions take bounded damage and their trainer receives
   the existing Stormwood Static stamina-regeneration penalty.
4. Defeating the fifth creature switches to Break the Core. Human locomotion is
   suspended and the deployed companion is piloted directly between conduits.
5. A strike is accepted only for a current participant in Stormwood, using the
   host's current companion body, current move id, action sequence, cooldown,
   range and facing. Four distinct conduits within one bank cycle commit the
   Marrow reward and chapter event.
6. A loss resets only the encounter attempt and returns contributors to Ember
   Bivouac. Chapter approach flags remain intact and trainer/player reward
   ledgers remain the duplicate-payment guard.

## Persistence and reconnect

The Dynamo's phase, elapsed bank clock, conduit set, attempt, participants and
contributors live under `realm_environment.stormwood.dynamo`. The loader also
accepts the earlier direct-rules development shape. A persisted fourth-conduit
state without the corresponding Marrow flag completes the idempotent reward on
the host after mount rather than leaving the climax permanently unavailable.
The same Marrow prompt admits additional peers to a live roster fight and lets a
reconnecting participant resume a persisted Break-the-Core phase.

## Integration seams

- `stormwood_world.gd` mounts the controller after the existing combat runtime,
  so its encounter hub, director, manager and trainer cast already exist.
- `stormwood_encounter_hub.gd` routes Dynamo intents/snapshots through the
  established reliable Session channel and maps Varga/Kestrel hosted victories
  to their missing chapter events.
- The controller delegates roster combat and all payouts to the existing hosted
  trainer/director code. It does not accept client damage or client positions.
- Marrow's data now contains the five creatures assumed by the existing Dynamo
  rules test, making the half-team Overload threshold reachable at two remaining.

## Validation

After BUILD-SIZE released the exclusive Godot lock:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_dynamo.gd,test_stormwood_trainers_data.gd,test_stormwood_encounter_catalogue.gd,test_stormwood_encounters_data.gd,test_stormwood_named_crown.gd
godot --headless --path . --script tests/smoke_stormwood_crown_heartstone.gd
godot --headless --path . --script tests/smoke_stormwood_chapter_prefix.gd
```

- Integrated focused matrix (also including the two CI contract repairs, full
  roster population and Water runtime translation): **36 tests / 8,923
  assertions / 0 failed**, with no script or parse errors after correcting two
  initial inferred-type parse errors in the new controller.
- Crown heartstone production fixture: **12 assertions / 0 failures**.
- Stormwood production chapter-prefix smoke: **PASS**; the real world mounted
  the controller, four capacitor banks and three safe plates before completing
  Ashfoot -> Hesk -> Tamsin.

The mounted production smoke now requires the controller, all four named bank
nodes and all three grounded plate nodes. A dedicated two-peer Marrow/Dynamo
end-to-end run remains required before the chapter can be called complete.
