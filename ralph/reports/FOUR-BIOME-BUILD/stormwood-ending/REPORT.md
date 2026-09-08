# Stormwood ending slice — 2026-09-07

## Outcome

The production Stormwood world now continues from the host-owned Dynamo into a
playable chapter ending: the containment opens, the captive Stormheart steps
out, one trainer may accept its voluntary offer through the shipped five-slot
ceremony, the Spark appears at a physical Lantern Hollow shrine, and the high
Dynamo platform reveals a non-enterable Waterward horizon and grants the Water
key through the authored chapter event.

This slice does not add a Water realm gate. Prompt 78 assigns that ordinary
transition to Water after Stormwood supplies `aftermath:waterward_view`, and the
view here deliberately has no collision or travel action.

## Authority and persistence

- The existing Stormwood reliable encounter channel carries `ending_*`
  snapshots and intents. `session.gd` is unchanged.
- Only the host accepts a nearby offer interaction, chooses the first valid
  recipient, settles the shared offer, or accepts a nearby Waterward view.
- The unique recipient is a stable character id, not a socket id. The
  unresolved creature payload is written under
  `realm_environment.stormwood.ending` and saved before it is delivered.
- The recipient uses `Game.pending_catch`, the one existing five-creature
  choice. A player-owned `stormwood:legendary_ceremony_settled` receipt and the
  saved party make all crash points recoverable: an unresolved claim is
  re-delivered, while a saved answer is acknowledged without duplicating the
  creature or replaying a farewell.
- Shared release, Spark placement, offer settlement, Long Storm and Waterward
  flags flow through `StormwoodChapter.emit_event` and the host ledger. The
  matching simulation-shell authority added in `d42dc14e3` means a host playing
  another realm still commits these Stormwood facts itself; no client relay or
  direct shared progression write remains.

## Player-facing sequence

1. Marrow's fourth-conduit victory commits its chapter flag. The ending emits
   `dynamo:release`, hides the containment arcs, moves the 1.8-scale alpha
   Fulgocobra placeholder out of the pillar and presents the release dialogue.
2. The freed creature offers rather than being fought or caught. The first
   nearby trainer to interact reserves the one claim. With room it joins
   directly; with five companions it enters the mandatory existing
   keep-or-release ceremony. Declining does not block the ending.
3. Release awards the Spark through the authored objective. The physical
   Lantern Hollow shrine uses the common Realm Heart implementation and its
   single-active replacement explanation. Placement advances the Stormwood
   chapter through `shrine:stormwood_placed`.
4. Returning to the high Dynamo platform enables `Look beyond the broken
   storm`. The host validates proximity, emits `aftermath:waterward_view`, and
   the chapter grants `realm_key_water`, `waterward_route_revealed` and
   `stormwood:chapter_complete`. The newly visible sea is a distant horizon,
   not an unowned Water transition.

## Validation

Focused headless command:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=test_stormwood_ending.gd,test_flag_scopes.gd,test_realm_chapter_progression.gd,test_stormwood_dynamo.gd
```

Result: **35 tests / 507 assertions / 0 failed**, with clean output and no
script, parse, resource or leak errors.

Production mount command:

```text
godot --headless --path . --script tests/smoke_stormwood_chapter_prefix.gd
```

Result: process exit 0 and
`STORMWOOD CHAPTER PREFIX OK: Ashfoot -> Hesk -> Tamsin objective`. The smoke
proved the real scene mounted `StormwoodEnding`, `CaptiveStormheart`,
`StormheartContainment`, `StormheartOffer`, `WaterwardView`, the Lantern Hollow
Spark shrine and the distant Waterward sea alongside the Dynamo.

The smoke log is **not clean**. After the concurrent texture-import rewrite it
reported widespread missing `.s3tc.ctex` cache resources and dependent resource
parse failures across existing Meadows terrain, building textures and numerous
creature models. None named `stormwood_ending.gd`, and the ending nodes mounted,
but this run cannot be promoted to clean production evidence until the import
lane repairs/regenerates the cache.

## Remaining proof and known gap

- The complete release/choice/shrine/view path still needs continuous solo and
  two-peer gameplay proof after the shared import cache is healthy.
- `realm_hearts.json` already declares Livewire's `cooldown_multiplier: 0.75`
  and the common shrine can place/activate/swap it. Static review found no combat
  consumer for that field. A local-only application would conflict with the raw
  cooldown enforced by the host validators in `stormwood_hosted_trainer.gd` and
  `stormwood_dynamo.gd`; therefore this slice does **not** claim Livewire's
  cooldown effect works. Root recorded it as a separate multiplayer design
  repair rather than weakening host authority here.
