# External environment velocity: summit integration

The shipping ground Player, deployed Fly player, and CreatureBody expose the same
body-local registration API. The ordered callback receives the locomotion-selected
`CharacterBody3D` and physics delta, immediately before that path's existing single
`move_and_slide`. Nothing changes with no modifier registered. Riding still owns
its carried transform and bypasses the player's independent movement entirely.

## World registration and cleanup

After constructing/configuring the finale and actors:

```gdscript
player.register_environment_velocity_modifier(
    &"cloudreach_summit", finale, finale.apply_hazards, 100)

# Call for each newly instantiated controlled creature, including party swaps.
controlled_creature.register_environment_velocity_modifier(
    &"cloudreach_summit", finale, finale.apply_hazards, 100)
```

Register on the player **once**, not on its FlyController as well: Fly delegates
to that same player-owned registry. Use a stable id per body. Re-registering that
id replaces the callback instead of stacking it. Lower order executes first;
equal priorities retain registration order. The finale samples physical arena
bounds/phase, so registration does not require a second proximity poller.

The owning world should retain its registered actor list and clear its own id on
cleanup or ownership changes:

```gdscript
for actor in registered_actors:
    if is_instance_valid(actor):
        actor.clear_environment_velocity_modifier(&"cloudreach_summit")
```

Do not clear unrelated systems' ids. `clear_environment_velocity_modifiers()` is
also available for full actor teardown and is called by each body's `_exit_tree`.
The modifier owner is weakly held; its `tree_exiting` automatically removes its
registration even if the body survives. Invalid/freed callback targets are
discarded during dispatch. This provides a fallback if the world forgets explicit
cleanup, including a finale freed independently of the body. No state is saved.

## Collision and force behavior

Callbacks change velocity; they must never call `move_and_slide` or ordinary
movement themselves. The finale's exceptional safe-bivouac recovery handoff can
teleport through its injected recovery adapter; that reset invalidates prior drift.
The framework preserves the existing body as the sole collision owner.

All three locomotion paths accelerate from the previous collision velocity. The
helper therefore removes its previous surviving external contribution before the
next locomotion choice, then applies fresh forces immediately before the slide.
Collision normals project that contribution so a blocked wind does not create a
reverse kick next frame. This is necessary for the finale's independently bounded
drift: simply adding its capped 7 m/s every frame would otherwise accelerate the
body without bound. External velocity resets also invalidate stale force debt.

Fly rechecks its swept authored restrictions after a force changes velocity;
environmental wind cannot bypass a locked flight volume. A rejected contribution
does not become a reverse force on the next frame. Ground-player impact speed is
sampled after the modifier so recovery lift/reset does not retain stale fall
damage. Step/unwedge intent still uses locomotion's requested motion.

This package does **not** register the world actors or change combat ownership.
The Cloudreach world integration lane must wire the registration above whenever
the controlled creature body is replaced. No human combat is introduced.

## Verification

- `test_environment_velocity.gd`: ordered invocation/replacement, no-op identity,
  capped non-feedback integration, invalid owner/callback handling, unregister
  during dispatch, restriction cancellation, and one slide call per shipping path.
- Focused environment/finale/Fly/input-owner/player-vitals suite: **48 tests,
  189 assertions, zero failures**.
- `smoke_environment_velocity.gd`: **PASS** with real production player scenes,
  Fly tick, creature scene/body script, floor/wall collision and real input. All
  three reach but never exceed the authored wind cap, collide with the wall,
  recover within an authored lee pocket, and unregister on owner exit. A late
  physics observer compares actual horizontal displacement with one pre-slide
  velocity integration and verifies one callback per physics tick. The creature
  uses `request_move` from the actual input action. Fly starts in explicitly
  seeded deployed state with zero sink to isolate force behavior; this is not
  evidence of deployment input or finale encounter completion.
- Existing `smoke_fly_traversal.gd`: **28 assertions, zero failures**, independently
  verifies actual airborne deployment/input, installed presentation, collision,
  restricted routes, stamina/exhaustion, safe recovery and airborne save/reload
  with no modifier registered.

No full-world route evidence or external visual acceptance is claimed here.
