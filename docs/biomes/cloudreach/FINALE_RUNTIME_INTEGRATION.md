# Cloudreach finale mechanics — integration contract

This bounded package implements the summit environment/state machine in
`scripts/world/cloudreach_finale_controller.gd`, with tuning and exact flag identities
in `data/config/cloudreach_finale.json`. It has no independent save store, creature
roster, combat resolution, reward dispenser, or arena mesh. It is not yet proof of a
production chapter finale.

## World and combat hooks

1. Create the controller beneath the Cloudreach world. Before adding it, call
   `setup(Game.progression, chapter.emit_event, controlled_body, creature_piloted,
   recover_to_bivouac)`. The last three arguments are Callables. The body source must
   return the actual currently controlled CharacterBody, including after a team switch.
2. Author a collision-bearing circular deck of radius 36 m behind the Summit Eyrie.
   The provisional origin is `[100, 1160, 5450]`. Verify its actual surface before
   accepting it; this package does not modify `cloudreach_world.gd`. Position production
   relay props at the three configured offsets; the controller supplies their existing
   shared `Interactable` prompts. Match physical cover and floor markings to all three
   lee circles. Do not put structures across the reachable relay lanes.
3. Call `encounter_started("captain_veyra_storm_anchor")` only when the production
   captain encounter actually starts. Call `opposition_remaining(id, remaining, initial)`
   from actual opposition state; half remaining enables arc denial. Zero remaining
   alone deliberately does not declare victory.
4. Connect the production encounter's definitive victory callback to
   `encounter_won(id)`. This dispatches the existing authored captain-win event through
   the chapter adapter and checks the resulting flag. A dialogue effect or direct flag
   assignment is not valid evidence for this seam.
5. After locomotion sets the controlled body's velocity and before its **single**
   `move_and_slide`, call `apply_hazards(body, delta)`. Supply fresh locomotion velocity
   each frame; the controller adds a bounded accumulated horizontal drift. Preserve
   this hook for deployed creature control after captain victory, so the creature can
   reach and strike all three relays. Human control cannot activate a relay. No human
   weapon or damage method is introduced.
6. On captain loss, call `encounter_lost(id, controlled_body)`. The recovery Callable
   receives `(body, "summit_bivouac", safe_position)`. It must finish combat/Fly state
   cleanly, place the body on the actual camp floor, reset velocity/camera and perform
   existing recovery/autosave behavior. The controller retains all durable flags. Its
   under-deck current lifts/inward-steers ordinary falls; a deeper fall invokes the
   same handoff once. It never guesses floor height from the highest stacked XZ surface.
7. Call `witness_restoration(controlled_body)` on physical approach to the Waterward
   overlook delegation. It verifies horizontal and vertical range and dispatches the
   existing aftermath event. Keep Aila's final reward dialogue separate: it owns the
   Heart, Water key and route reveal. Restoration alone cannot grant those rewards.

## Persistence and presentation

The three new relay flags are:

- `cloudreach_summit_relay_west_disabled`
- `cloudreach_summit_relay_crown_disabled`
- `cloudreach_summit_relay_east_disabled`

These use the existing `ProgressionState` and its existing save payload. Add their
names to the chapter's manifest during integration. Old saves default to no relay
progress. The controller reconstructs relay state, disabled network and aftermath on
load. It can repair an interrupted write after all three relays without inventing a
captain win, restoration witness or reward conversation. Active fight phase/timers and
hazard drift are transient; unfinished fights restart on re-engagement.

Subscribe to `presentation_changed(state)` to restore relay art, engine drone, natural
wind trails, reopened traveler placements, persistent safe currents and Waterward map
visibility. Also read `presentation_state()` immediately after setup: late subscribers
must not wait for a new revision. `captain_defeated`, `relay_disabled`,
`network_disabled` and `aftermath_restored` are one-time action feedback, not load
replay signals. A save-repair network transition emits presentation, not another reward.

The renderer must use the same `elapsed` clock and config as `hazard_at(position)`:
three parallel wind strips rotate at 8 degrees/second; three annular arc sectors
rotate at -14 degrees/second. Each cycle has a visible telegraph, active pressure and
recovery interval. Lee pockets override both hazards at every rotation. Render their
cover/readable safe floor, wind strips and arc warnings in real production frames
before claiming visual acceptance. The controller itself adds no particle/draw budget.

## Evidence and outstanding acceptance

`tests/test_cloudreach_finale.gd`: 4 tests / 76 assertions pass, covering gated and
idempotent production-event input, overload threshold, partial-relay save restoration,
aggregate repair, withheld rewards, rotating hazards, safe lee pockets, stacked-surface
exclusion and malformed progression refusal.

`tests/smoke_cloudreach_finale.gd`: isolated real CharacterBody/input/collision fixture
passes. It drives movement into a real wall under wind, activates each relay through
the production interaction arbiter, reloads canonical flags, visits the physical
aftermath witness point and verifies current plus bivouac recovery. Encounter victory
is an injected callback and the creature predicate is a fixture stub. This is not a
production fight, final-art review or continuous travel proof.

First validation exposed two fixture assumptions, corrected before these results:
the chosen arc sample fell inside a valid lee pocket; six physics frames were too few
for a body spawned 0.2 m above its floor to land. Neither failure justified altering
world collision or lee coverage.

Still required: production encounter wiring and switch/pressure evidence, authored
arena collision/telegraphs/relay props, real safe-camp handoff, post-fight creature
control, restored-world presentation and delegation interaction, a continuous
approach→captain→three relays→aftermath→reward→save/load path, real route captures,
blind visual judgment, and target-hardware performance measurement.
