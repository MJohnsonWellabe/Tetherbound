extends RefCounted
## Shared inventory preview for owned death containers. Tool metadata travels
## with its stack; retrieving a broken tool must never repair it accidentally.
const INVENTORY := preload("res://autoload/inventory.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
static var _db: RefCounted
static func db() -> RefCounted:
	if _db == null:
		_db = ITEM_DB.new()
	return _db
static func slots(inventory: RefCounted) -> Array:
	var result: Array = []
	for i in inventory.slot_count():
		var stack: Dictionary = inventory.stack_at(i)
		result.append(null if stack.is_empty() else stack)
	return result
static func valid_slots(raw: Variant) -> bool:
	if not raw is Array or raw.size() > INVENTORY.SLOT_COUNT:
		return false
	for stack: Variant in raw:
		if stack == null:
			continue
		if not stack is Dictionary or not stack.get("id") is String or str(stack.id).is_empty():
			return false
		for key: String in ["n", "durability", "durability_bonus"]:
			if not stack.has(key) and key != "n":
				continue
			var value: Variant = stack.get(key)
			if not (value is float or value is int) or not is_finite(float(value)) or float(value) != floorf(float(value)) or float(value) < 0 or float(value) > 2147483647:
				return false
		if int(stack.n) < 1 or int(stack.n) > db().stack_size(stack.id):
			return false
	return true
static func inventory_from(raw: Array) -> RefCounted:
	var inventory := INVENTORY.new(db())
	for i in mini(raw.size(), inventory.slot_count()):
		inventory.set_slot(i, raw[i])
	return inventory
static func give_stack(inventory: RefCounted, stack: Dictionary) -> bool:
	if not inventory.has_room_for(str(stack.id), int(stack.n)):
		return false
	if stack.has("durability") or stack.has("durability_bonus"):
		for i in inventory.slot_count():
			if inventory.is_slot_empty(i):
				inventory.set_slot(i, stack)
				return true
		return false
	return int(inventory.add(str(stack.id), int(stack.n))) == 0
static func preview(container: Array, personal: Array, direction: String, item: String, count: int) -> Dictionary:
	if not valid_slots(container) or not valid_slots(personal) or count <= 0 or direction not in ["deposit", "withdraw"]:
		return {}
	var bag := inventory_from(container)
	var player := inventory_from(personal)
	var source: RefCounted = player if direction == "deposit" else bag
	var target: RefCounted = bag if direction == "deposit" else player
	if source.count(item) < count:
		return {}
	var remaining := count
	var moved_stacks: Array = []
	for i in source.slot_count():
		var stack: Dictionary = source.stack_at(i)
		if stack.is_empty() or str(stack.id) != item or remaining <= 0:
			continue
		var portion := stack.duplicate(true)
		portion.n = mini(remaining, int(stack.n))
		if not give_stack(target, portion):
			return {}
		remaining -= int(portion.n)
		stack.n = int(stack.n) - int(portion.n)
		source.set_slot(i, null if int(stack.n) == 0 else stack)
		moved_stacks.append(portion)
	return {"state": slots(bag), "personal": slots(player), "stacks": moved_stacks, "moved": count}
