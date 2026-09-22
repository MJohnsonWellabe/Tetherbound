extends RefCounted

## A save slot is only a local file locator. This durable random namespace is
## the identity of the world stored there, including when another host also
## calls its world "slot-0".

const RANDOM_BYTES := 16


static func ensure(world: Object) -> String:
	if world == null:
		return ""
	var has_namespace := false
	for raw_property: Variant in world.get_property_list():
		if raw_property is Dictionary \
				and str((raw_property as Dictionary).get("name", "")) == "reward_delivery_namespace":
			has_namespace = true
			break
	if not has_namespace:
		return ""
	var raw_existing: Variant = world.get("reward_delivery_namespace")
	if typeof(raw_existing) == TYPE_STRING and not (raw_existing as String).is_empty():
		return raw_existing as String
	var random := Crypto.new().generate_random_bytes(RANDOM_BYTES)
	if random.size() != RANDOM_BYTES:
		return ""
	var identity := random.hex_encode()
	world.set("reward_delivery_namespace", identity)
	return identity
