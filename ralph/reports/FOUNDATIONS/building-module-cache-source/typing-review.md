# Explicit WeakRef annotation after native parser failure

ROOT's named test run on combined source
`c2371fcd24a0cde93d8bf00834032a540edf402f` failed to parse
`tests/test_wall_foliage_normals.gd:37`. Godot reported that inference from
`weakref(load(VINE))` produced a Variant, with that warning treated as an error.
The run exited 1 with one harness failure and zero assertions. The lifetime
regression was unexecuted; the earlier static checks did not prove compilation.

This successor changes only `var module_ref := weakref(load(VINE))` to
`var module_ref: WeakRef = weakref(load(VINE))`. It preserves the weak reference
and creates no strong PackedScene test reference. Reversing that single
annotation reproduces the entire prior test file exactly, including both
original test bodies and all 20 new assertion call sites. The production cache
file is unchanged. The failed native log and source hashes are pinned in
`typing-source-cut.json`; the earlier packet remains historical evidence.

Static byte comparisons, whitespace checks, and read-only application against
the coordinator checkout passed. Existing F29 review and ROOT native rerun
remain pending. No engine/parser/import/render/GPU/export/CI execution, branch
push, new session/agent, or coordinator checkout write occurred here.

The coordinator separately reports successful gate-evidence CI6169 on
`aba5268a53`, including opening, house building, two beds, rest/torch, and
post-modal controls. That baseline evidence does not validate this cache
regression, measure a speedup, explain the retained local 240-second timeouts,
or establish whole earned/title-to-tournament acceptance.
