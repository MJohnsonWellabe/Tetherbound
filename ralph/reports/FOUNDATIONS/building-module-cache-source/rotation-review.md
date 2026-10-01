# Compare authored rotation rather than Euler representation

ROOT's original named test file at
`b42e92f90f224e1d499f26cf8dec2035bb6fdfc0` executed three cases and 188 assertions.
One assertion failed: the 180-degree module's Euler yaw was `-PI`, while the
test expected `PI` within 0.0001 radians. All other assertions executed and
passed, including cache lifetime, release, geometry and material isolation.
The actual native run remains a failure, with its raw log pinned separately.

The successor replaces only that raw Euler comparison. It compares angular
distance between the actual module basis's rotation quaternion and the
quaternion for `Basis(Vector3.UP, PI)`, requiring zero within the existing
0.0001-radian tolerance. This verifies the full authored rotation, including
its axis, rather than accepting an Euler sign or dropping the obligation.
The separate exact scale and position checks remain unchanged.

The [exact engine basis implementation](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/math/basis.cpp#L370)
orthonormalizes the basis before extracting rotation, so the authored uniform
0.5 scale is handled independently. The [quaternion angular distance](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/math/quaternion.cpp)
uses the squared quaternion dot product, preserving equivalent rotations under
opposite quaternion signs. A standard-math witness in the packet confirms
equivalence of positive and negative PI while rejecting zero, a quarter turn,
and a 0.001-radian deviation. That witness is not Godot execution.

Reversing the one assertion replacement reproduces the entire prior test file
exactly. Both original cases, all 20 regression assertion call sites, and the
production cache remain intact. Source comparisons, whitespace checks, and
read-only integration patch application passed. Existing F29 narrow review and
ROOT native rerun remain pending; no push, native/parser/import execution, CI,
new session/agent, or coordinator checkout write occurred here. No smoke,
performance, timeout-resolution or acceptance success is inferred.
