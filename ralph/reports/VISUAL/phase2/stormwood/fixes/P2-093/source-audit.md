# Danger lane and recovery cue source audit

At merged source `95f11b61b`, the catalog's three impact/strike sightings remain
unresolved. They concern the named wild fights, not the Stormheart legendary
body or its arena energy effects.

`scripts/creatures/wild_creature.gd::_begin_lunge()` calls the visible lane's
`release()` and drops its own lane reference. `scripts/combat/lunge_lane.gd`
then decrements a fixed `_fade_left` each physics tick until removal. The
configured `data/config/combat.json::charger_lunge.lane_fade` is 0.35 seconds. The lane
keeps a body reference, but its released lifetime does not consult the body's
current lunge or recovery state.

The gameplay body separately exposes `is_lunging()`. Contact, obstacle or
travel completion reaches `_finish_lunge()`, clears `_lunge_active` and emits
`strike_ready`. The production HUD shows its opening text when
`combat_manager.gd::enemy_is_rooted()` delegates to the body's `is_rooted()`;
that predicate excludes an active lunge. Therefore the source permits a lane
fade to outlast a short travelling charge while the HUD already reads recovery.
This is a plausible explanation for the captured conflicting signals, not
proof that it caused each original frame.

A bounded next measurement should correlate the original Capacitor/Hollows
strike and impact sightings with the live lane's existence/opacity, public
lunge state and HUD recovery predicate. It must preserve ordinary damage,
contact, encounter positions and camera behavior. The existing
`phase2_capture_stormwood_fights.gd` wraps the authored named-fight recorder;
its in-memory party level and other fixtures must be disclosed. No production
code, timing or configuration changed in this audit, and P2-093 remains open.
