# Solo ordinary trainer duels: no Tether Command / ultimate meter (RD-12 gap)

Found by systems-b in F42#2 r3 (12 Oct; probe on fb140af94; Meadows, `captain_riverwatch`, offline solo).

## Probe (headless `tests/smoke_named_fight_hit_avoid.gd` subclass, every 180 physics frames in the fight)
`CombatManager._encounter_link = null`, `_encounter_id = ""`, `_party_ultimate = {}`, `_tether_command_view = {}`, and the deployment identity is present (generation 1). The real snapshot is inactive, so the overlay shows the stand-in at 0.
The meters live only on the host encounter record. In solo, `encounter_director._open_encounter_if_networked` mints one only for canonical wilds, masters, rematches and chapter-boss hand-offs (`_solo_boss_handoff_record`, 34df191aa). An ordinary solo trainer duel never binds a link, so neither meter can fill.

## Attempt 1 (reverted): mint the record for solo trainer duels
Added `_solo_trainer_record(opponent_owned)` (opponent owned, trainer spec, `_local_authority()`, `tether_commands.enabled("runtime_enabled")`) to the open gate.
Result: the round ended immediately with 0 strikes. `_install_ordinary_combat_reward_owner` returned false and the round resolved 'fled'. A temporary diagnostic showed `ordinary_combat_reward_owner`: live=true, auth=true, ledger=true, **vitals_ready=false** (`ordinary_combat_vitals_ready` needs `_is_host()` and an `_ordinary_actor_binding` per participant). This is the same wall as the earlier reverted a86b733b5.

## Attempt 2 (reverted): attempt 1, plus keep the solo legacy reward path
`_install_ordinary_combat_reward_owner` returned true for a solo ordinary duel, with no durable per-round owner, as solo chapter bosses already do.
Result: the link binds (`enc=1:1 kind=trainer`, tether view present), but the **player's hits stop landing**: `player_hits=0 stand_strikes_landed=0 dodges_avoided=0/8 strikes=16`, and the meter stays at 0. The hosted move commit (`_uses_host_move_start` / `apply_host_move_start`) needs the solo actor-vitals binding that ordinary duels never set up.

## Pointer
A fix makes a solo ordinary duel a full session-of-one hosted encounter (actor-vitals bindings, move commit, round rewards), as solo wilds are via `_canonical_wild_start_state`. Nothing from either attempt was pushed.
