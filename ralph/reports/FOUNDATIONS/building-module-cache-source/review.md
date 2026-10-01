# Retain building module resources for prefab reuse

The original rest-and-torch smoke at `2fb3a0f2423ab25a78d3ec04a54395b856de0726`
exhausted the coordinator's 240-second bound before a fixture assertion or
verdict. Its raw log records 670 medieval glTF format-loader entries after
`[playground] spawned`, across 33 paths, with 669 completed loads. The same wall
scene appears 92 times. The earlier observational wrapper records 908 entries
across 34 paths, 907 completions, and 118 loads of that wall scene. Original
raw logs and exact source hashes are pinned in `source-cut.json`.

Two source paths explain repeated actual loading. Template assembly loads each
module into a local PackedScene, then retains its instantiated nodes rather
than the scene resource. Placement calls `duplicate()` with unchanged default
flags. The exact engine source also loads a child's scene file when duplicating
an imported scene instance. Godot removes a resource from its global cache when
its final reference is released; cache hits return before the verbose loader
entry printed in these logs. See [the resource lifetime contract](https://docs.godotengine.org/en/stable/classes/class_resource.html),
[Node duplication](https://github.com/godotengine/godot/blob/5b4e0cb0f/scene/main/node.cpp#L2612),
and [ResourceLoader cache reuse](https://github.com/godotengine/godot/blob/5b4e0cb0f/core/io/resource_loader.cpp#L738).

The repair retains successfully loaded module resources in a dictionary owned
by each composer, keyed by the full existing glTF or OBJ path. Only the two
existing module load sites use the helper. Resources are released after cached
template nodes in PREDELETE. A local farmhouse composer still ends with its
existing scope; a village composer retains resources for its existing lifetime.
There is no static or global cache, and null loads are not cached.

Every other byte of the runtime source remains unchanged after removing this
cache addition and restoring the two load expressions. This preserves default
duplication flags, scene instantiation, resource lookup priority, missing-module
behavior, transforms, retints, foliage correction, template visibility and
ownership, slices, startup order, assets, layout, and guards. Retaining scenes
adds references for the composer's lifetime; it does not preload unused recipes.

One bounded regression is added to the existing wall-foliage composer test
file. It places a two-module recipe three times, uses a WeakRef to check scene
retention without a strong test reference, and checks distinct node trees,
authored positions/yaw/scale, imported vertices and bounds, sibling/template
and source-material isolation under retint, and surviving placed meshes and
retints after composer release. Its final WeakRef check verifies release while
placed nodes remain alive. The original implementation fails the initial
retention assertion. Existing tests are preserved byte-for-byte.

Static source comparison and read-only patch application against the combined
checkout passed. The coordinator must run the existing test file, original
`tests/smoke_gate_a_rest_torch.gd`, and independent review. No parser, import,
engine, render, GPU, export, CI job, or coordinator checkout write occurred here.
The local commit is held from feature-branch pushes for consolidated CI.

These observations establish repeated loader work. They do not establish a
deadlock, attribute the entire timeout, measure a speedup, pass the smoke, or
close an acceptance criterion. The separate autosave refusal still has no new
rejecting snapshot; its cause remains unproved.
