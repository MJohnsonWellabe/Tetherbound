# Preserve the angular tolerance under float32 arithmetic

Independent review held `f7c467b635` because Quaternion.angle_to computes
`acos(2*d*d-1)`. At float32 precision, the dot product can round to one for
rotation differences larger than the required 0.0001 radians. The previous
double-precision witness did not cover that effective-tolerance failure. ROOT
has not integrated that held assertion; its previous native run remains FAIL.

The replacement normalizes the expected and actual rotation quaternions, forms
and normalizes `inverse(expected) * actual`, then compares
`2 * atan2(length(relative.xyz), abs(relative.w))` with zero at an explicit
0.0001-radian tolerance. Small deviations remain in the relative quaternion's
vector part even when its scalar part rounds to one. Taking the scalar's
absolute value preserves equivalent quaternion signs. The comparison covers
the full rotation and axis; scale and position retain their separate exact
checks. All introduced variables have explicit types.

The implementation uses the [pinned quaternion inverse and normalization](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/math/quaternion.cpp#L69)
and [quaternion product](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/math/quaternion.h#L220).
The [basis extraction](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/math/basis.cpp#L370)
already removes scale before returning its rotation quaternion. The existing
uniform-scale assertion remains intact.

`float32_rotation_witness.py` is a reproducible source-math audit, not a native
test. It rounds quaternion operands, operations, normalization, and vector
length to IEEE float32, then applies atan2 to those inputs. Its 31 controls
include positive and negative PI, opposite quaternion signs, both signs of
0.00005/0.0002/0.0003-radian yaw differences, zero, quarter-turn, wrong X/Z axes,
and small relative X/Z tilts at the same boundaries. Every expected outcome
matches. The maximum accepted error is 0.000050067902 radians and the minimum
rejected error is 0.000199794769 radians. Sixteen out-of-tolerance controls
demonstrate false acceptance by the superseded acos-dot calculation. This audit
does not execute Godot's basis extraction, parser, or regression test.

Reversing the comparison block reproduces the entire previous test file
exactly. Both original cases, every regression assertion call site, production
cache, lifetime/material checks, geometry and pose checks remain unchanged.
Source and whitespace checks passed. Since ROOT has not integrated f7, the
packet pins a cumulative one-file diff from reviewed `2360b9d664` to this
successor; read-only application against current integration passed. The
immutable successor supersedes the held f7 comparison and must be reviewed as
the final source, rather than treating f7 alone as an approved integration.

Existing F29 narrow review and ROOT native rerun remain pending. No push,
native/parser/import/render/GPU/export/CI execution, new session/agent, or ROOT
checkout write occurred here. Previous native 3-case/188-assertion/one-yaw-failure
evidence remains FAIL. No smoke, speedup, local timeout resolution, campaign or
acceptance success is inferred.
