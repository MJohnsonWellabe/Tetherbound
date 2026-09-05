# Cloudreach chapter event integration

`scripts/world/realm_chapter_progression.gd` interprets the existing
`cloudreach_chapter.json` against `Game.progression`. It has no second save store.
The canonical flags therefore use the current save format, revision polling,
realm return, and reload behavior.

Status: logic tested; physical interactions and continuous chapter play require
the world integration below. These tests are not chapter completion evidence.

## Runtime hooks

Create one `realm_chapter_events.gd` child under the Cloudreach world, assigning
`chapter` from `cloudreach_chapter.json` and `realm_id = "cloudreach"` before
adding it. The adapter joins `realm_chapter_events` and `progression_restore`,
reconciles after load and progression revisions, and rejects calls while
`Game.current_realm` is a different realm.

Call `emit_event(event)` after a successful world action. Its result contains:

- `accepted`: the named event matched an eligible authored objective or step;
- `changed`: at least one durable flag changed;
- `completed_ids`: objectives/side steps newly completed;
- `granted_flags`: newly granted reward entitlements.

Connect `chapter_changed(result)` to completion feedback and refresh world
presentation. Replayed events do not emit duplicate completion/reward signals.
Use `cloudreach_winds_restored` for anchor/audio/NPC aftermath changes, and
`waterward_route_revealed` for the future-realm view. Water remains non-enterable.
The Cloudreach Heart power is intentionally undefined; this grants only its
earned entitlement.

The existing `cloudreach_chapter.gd` static `apply_event` can delegate to
`realm_chapter_progression.gd.dispatch(progression, chapter, event)["changed"]`.
Route its dialogue effects to this same adapter instead of maintaining a second
event implementation. Only the existing chapter node should drain the dialogue
panel queue; the new scene adapter deliberately does not drain it.

Use `side_entries(Game.progression, chapter)` for the current side-chain steps in
the existing quest log. It returns the familiar `label`, `done`, `how` plus `id`.
`count_progress(progression, chapter, objective_id)` returns completed/total as
`Vector2i`. The existing task-feed count rendering already reads canonical flags.

## Events the world must produce

Main events retain their exact authored `completion_event` values. Gate flags
cannot substitute for physically completing the interaction.

| Physical action | Event |
|---|---|
| Both lower sites inspected | Individually emit `count:storm_anchor_lower_west_mapped` and `count:storm_anchor_lower_east_mapped` |
| Picket cleared and Three Bells safe signal rung | `three_bells_safe_route_signaled` |
| Aerie fiber delivered, threat cleared, perch restored | `windscar_aerie_restored` |
| Maela explains the prepared trial | `dialogue:cloudreach_maela_flight_trial_ready` |
| Actual flight trial completed | `flight_trial_completed` |
| Legitimate Fly arrival/landing at High Roost | `landmark:sky_shrine_heartstone_reached` |
| Three shrine vanes restored and Sora's record heard | `dialogue:cloudreach_sora_storm_engine_truth` |
| Shrine windlass operated | `sky_shrine_counterweight_released` |
| Player enters newly lowered grounded road | `counterweight_road_entered` |
| Upper sites disabled | Individually emit `count:storm_anchor_upper_west_disabled`, `count:storm_anchor_upper_east_disabled`, `count:storm_anchor_summit_feed_disabled` |
| Player crosses arena threshold | `summit_arena_threshold_crossed` |
| Production captain encounter won | `encounter:captain_veyra_storm_anchor_won` |
| Three exposed engine relays disabled | `summit_engine_relays_disabled` |
| Player witnesses the summit delegation/aftermath | `aftermath:cloudreach_winds_restored` |
| Final Aila reward conversation ends | `dialogue:cloudreach_aila_final_reward_complete` |

The service checks act-entry flags as well as each objective's prerequisites.
It automatically aggregates completed count flags. Sending
`all_count_flags_set` cannot manufacture missing sites. Unknown count IDs or
arbitrary `flag:` effects cannot write progression through this adapter.

Side interactions use `side:<chain id>:<step id>` with the IDs already in the
chapter JSON. Emit them after the concrete action (bell, pack, delivery, survey,
or trainer group victory). Each chain's reveal flag and each step's prerequisites
are required. The two Aeries surveys may complete in either order as authored.
For trainer steps, the combat adapter must verify each required trainer win;
the chapter service does not fabricate combat outcomes or trainer rosters.

## Validation

`godot --headless --path . --script tests/run_tests.gd -- --only=test_realm_chapter_progression.gd`

2026-09-04: **8 tests, 114 assertions, 0 failed**, first run. Covers unknown and
premature event rejection, act entry, Fly/shrine/ground-road sequencing, unique
upper anchor counts and partial-save aggregate recovery, separate finale beats,
reward replay and entitlement repair, side-chain order/Fly gates/save persistence,
all four authored chains, and the production `Game.current_realm` adapter field.
