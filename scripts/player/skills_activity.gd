extends RefCounted

## Owner-side attribution, shared by every realm. Call after real movement,
## with voluntary movement direction before environmental current is applied.
## Paused input, teleports and passive drift cannot award travel XP.
var _skills: RefCounted
var _config: Dictionary
var _catch_tokens: Dictionary = {}


func _init(skills: RefCounted, config: Dictionary = {}) -> void:
	_skills = skills
	_config = config if not config.is_empty() else JSON.parse_string(FileAccess.get_file_as_string("res://data/config/player_skills.json"))


func record_movement(skill: String, displacement: Vector3, input_direction: Vector3,
		delta: float, maximum_speed: float, paused: bool = false) -> bool:
	if paused or not _config.skills.has(skill) or not displacement.is_finite() or not input_direction.is_finite():
		return false
	if not is_finite(delta) or not is_finite(maximum_speed) or delta <= 0.0 or maximum_speed <= 0.0:
		return false
	if input_direction.length_squared() < 0.01:
		return false
	# Reject relocation, rather than clamping a teleport into a reward.
	if displacement.length() > maximum_speed * delta * 1.25:
		return false
	var voluntary_distance := maxf(0.0, displacement.dot(input_direction.normalized()))
	return _skills.add_xp(skill, voluntary_distance * float(_config.skills[skill].get("xp_per_m", 0.0)))


## Token identifies one completed owned catch, not each wobble or RPC packet.
func record_catch(token: String, successful: bool, owned: bool) -> bool:
	if not successful or not owned or token.is_empty() or _catch_tokens.has(token):
		return false
	_catch_tokens[token] = true
	return _skills.add_xp("catching", float(_config.skills.catching.xp_per_success))


## Validation and removal happen synchronously on this character's inventory.
## No await or world-state mutation can split the award from its consumption.
func consume_candy(inventory: RefCounted, item_id: String, skill: String) -> bool:
	if inventory == null or not _skills.can_use_candy(skill, item_id):
		return false
	if not inventory.remove(item_id, 1):
		return false
	return _skills.use_candy(skill, item_id)
