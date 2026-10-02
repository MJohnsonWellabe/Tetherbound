extends SceneTree

const PLAYER = preload("res://autoload/player_state.gd")
const ITEMS = preload("res://autoload/item_db.gd")
const SPECIES = preload("res://scripts/creatures/creature_species.gd")
const AUTHORITY = preload("res://scripts/net/character_authority.gd")

func _init() -> void:
	var player := PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = "admission_cost_probe"
	for id: String in ["terrapup", "galewisp", "ripplet", "bramblebun", "mudsnout"]:
		player.party.add(SPECIES.spawn(id))
	var authority := AUTHORITY.new()
	authority.bind_world("admission_cost_world")
	var personal := AUTHORITY.portable_projection(player.save_data())
	var failures := AUTHORITY.errors(personal, player.character_id)
	if not failures.is_empty():
		printerr(failures)
		quit(1)
		return
	print("ADMISSION_PROBE seed=", authority.seed_admitted_character(personal, player.character_id).get("ok"))
	for operation: String in ["validate", "refresh", "vitals", "portals"]:
		var start := Time.get_ticks_usec()
		for index: int in 10:
			match operation:
				"validate": AUTHORITY.errors(personal, player.character_id)
				"refresh": authority.refresh_host_local(personal, player.character_id)
				"vitals": authority.recover_durable_vitals(player.character_id, {})
				"portals": authority.recover_durable_portals(player.character_id, {})
		print("ADMISSION_PROBE %s mean_ms=%.3f" % [operation, (Time.get_ticks_usec() - start) / 10000.0])
	quit(0)
