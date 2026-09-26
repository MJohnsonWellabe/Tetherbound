extends "res://tests/test_case.gd"

## water_veilfall_rock.gd installs its block only into a generated Terrain3D
## shader that has both insertion anchors and every symbol the block reads.

const ROCK := preload("res://scripts/world/water_veilfall_rock.gd")

const GENERATED := """
varying vec3 v_vertex;
uniform vec3 _camera_pos;
void fragment() {
	vec3 w_normal = vec3(0.0, 1.0, 0.0);
	SPECULAR = 1. - mat.normal_rough.a;
}
"""


func test_complete_generated_shader_has_no_missing_anchor() -> void:
	assert_eq(ROCK.missing_anchors(GENERATED), [])


func test_each_missing_symbol_or_anchor_is_named() -> void:
	assert_eq(ROCK.missing_anchors(GENERATED.replace("w_normal", "world_normal")), ["w_normal"])
	assert_eq(ROCK.missing_anchors(GENERATED.replace("_camera_pos", "camera_position")), ["_camera_pos"])
	assert_eq(ROCK.missing_anchors(GENERATED.replace("v_vertex", "v_world")), ["v_vertex"])
	assert_eq(ROCK.missing_anchors(GENERATED.replace(ROCK.TAIL_ANCHOR, "")), [ROCK.TAIL_ANCHOR])


func test_symbols_match_whole_identifiers_only() -> void:
	assert_eq(ROCK.missing_anchors(GENERATED.replace("v_vertex;", "v_vertex_2;")), ["v_vertex"])
