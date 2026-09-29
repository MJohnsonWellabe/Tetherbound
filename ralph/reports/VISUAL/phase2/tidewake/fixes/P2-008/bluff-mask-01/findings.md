# Gull Rest material-mask isolation

At source `0dbd6198056443c41411e5acabf1981f209100ba`, one native Windows
Compatibility OpenGL3 boot produced two actual 1920x1080 frames: ordinary dune
presentation, then the exact final bluff mask as unshaded grayscale. The mask
value is copied immediately after the existing steep/painted-mask maximum and
height fade. The diagnostic changes fragment output and unshaded rendering only;
terrain vertices, baked data, control sampling, LOD settings, Sun and camera
remain unchanged. It is not an art candidate or acceptance render.

Both images visibly contain the same large angular cap and foot boundaries.
The unshaded mask therefore proves the shape exists in the material-selection
signal before terrain lighting. It rules out a shadow-only or albedo-only
explanation for these boundaries. It does **not** establish whether heightfield
sampling, normal interpolation, control blending or their interaction produces
the mask shape, and does not independently prove a geometry/LOD defect.

The native manifest reports complete=true, failures=[], two saved frames and
actual terrain readbacks **mesh_size=48, mesh_lods=7, vertex_spacing=1.0** in both
frames. Player, camera position, all camera basis vectors and selected stand
coordinates/offsets match exactly. Baseline shader SHA-256 is
`47ba3113bb856300414b421ab06b164b423346767e46a8e3b83a762f77afed03`;
mask shader is `1f76f32d47372f19d4d9d62f09a599bb919d99028ef36c8da221412a560df5a4`.
Fog/tonemapping remain, so displayed gray values are not calibrated scalar data.

Session 5284 and native PID 6688 exited 0; subsequent process enumeration found
no native Godot, the render lock was released, and both production dune gates
remained false. No shader/script/parse/compile errors appeared; the existing
physics-interpolation deprecation warning is retained. Compact validation and
native dimensions/hash checks pass. Full raw images remain local under
`.artifacts/phase2/p2008-bluff-mask-01/`; the retained contact sheet is diagnostic
evidence only. Wrapper/launcher/log copies and hashes accompany the manifest;
the exact two-config ZIP is retained in `../dunes-05-pilot-repro/`.

Next material work should address mask sampling/boundary structure and the
separately rejected broad dark-gray coverage. Repeating Sun-bias or normal-map
intensity adjustments cannot remove a shape already visible in the unshaded
selection mask. The Lake Michigan sand/grass direction and remaining ecological
layering still require judged native views; this diagnostic closes no item or
regional bar.
