extends "res://tests/test_case.gd"

## training_t<N>_earn stops only when every retained level to the cap is
## payable by compatible essence or Tether Candy, priced per level.
const EARN := preload("res://tools/earned_saves/essence_earning_piece.gd")

func _price(level: int) -> int:
	return level

func test_compatible_essence_and_candy_cover_each_priced_level() -> void:
	var cards := [{"level": 8, "cap": 10, "items": ["essence_ground"]}]
	assert_eq(EARN.unfunded_levels(cards, {}, _price, "tether_candy"), 2, "nothing earned yet")
	assert_eq(EARN.unfunded_levels(cards, {"essence_ground": 17}, _price, "tether_candy"), 0, "8 + 9")
	assert_eq(EARN.unfunded_levels(cards, {"essence_ground": 16}, _price, "tether_candy"), 1, "one level short")
	assert_eq(EARN.unfunded_levels(cards, {"essence_ground": 8, "tether_candy": 1}, _price, "tether_candy"), 0, "candy pays any level")
	assert_eq(EARN.unfunded_levels(cards, {"essence_water": 99}, _price, "tether_candy"), 2, "incompatible essence never pays")

func test_one_pool_is_shared_by_companions_of_the_same_type() -> void:
	var cards := [{"level": 9, "cap": 10, "items": ["essence_ground"]}, {"level": 9, "cap": 10, "items": ["essence_ground"]}]
	assert_eq(EARN.unfunded_levels(cards, {"essence_ground": 9}, _price, "tether_candy"), 1)
	assert_eq(EARN.unfunded_levels(cards, {"essence_ground": 18}, _price, "tether_candy"), 0)
	assert_eq(EARN.unfunded_levels([{"level": 10, "cap": 10, "items": []}], {}, _price, "tether_candy"), 0, "at cap needs nothing")
