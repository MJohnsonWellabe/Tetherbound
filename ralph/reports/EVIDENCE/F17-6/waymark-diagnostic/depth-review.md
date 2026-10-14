# Waymark Forward+ depth resolution

Decision: SOURCE_REVIEW_RESOLVED_NATIVE_PIXELS_PENDING. Preserve source 74b6d583a40209315af64cf08ae80e946acb5cad; no successor shader change is justified by the equal-depth concern.

Godot tag 4.7-stable resolves through GitHub's Git reference API to commit 5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88. The three downloaded files are pinned to that commit in pinned-sources.json with byte sizes and SHA-256. Both CPP downloads exactly match the earlier tag-URL downloads. Earlier web-rendered line numbers differed; this report uses the downloaded immutable files exclusively.

## Relevant branch

- scene_shader_forward_clustered.cpp:108 maps depth_draw_never to disabled depth writes; lines 189-195 retain enabled depth testing without an explicit disabled or inverted mode. Line 124 tracks ALPHA use. The waymark writes ALPHA and does not set alpha scissor/hash modes.
- scene_shader_forward_clustered.h:281-288 classifies this shader into the alpha pass. Disabled depth drawing independently also selects that pass. Ordinary fragment discard does not turn it into alpha-scissor mode.
- render_forward_clustered.cpp:4299-4310 adds next-pass materials using their own shader data and the same surface. Lines 4191-4195 classify the overlay as FLAG_PASS_ALPHA; lines 1148-1150 enqueue the transparent list; lines 451-452 propagate the transparent pipeline flag.
- scene_shader_forward_clustered.cpp:353-360 enables depth testing, disables writes for this mode, and selects GREATER_OR_EQUAL. Lines 432-445 preserve that comparison in the transparent color branch. The opaque prepass branch at 446-455 is separate.

Therefore equal depth passes the comparison in this transparent branch. depth_draw_never alone is not the reason: the comparison operator is. Foreground geometry still participates in depth rejection; no depth-test-disable workaround is required. The broad stable shader-documentation statement about Forward+ equal fragments is insufficient to infer rejection for this exact branch.

## Limits and next verification

This is source evidence, not a native pixel observation or proof that the installed executable was reproducibly built from this commit. No engine, native stage, import, parser, or shader compilation was run. Geometry equality in source does not prove bit-identical GPU depth across generated shader variants. Root's existing bounded Hall diagnostic must still verify SVG import, shader compilation, visible ink, cloth contact, occlusion, and lighting/normal-map appearance. Keep production OFF and do not spend a full acceptance matrix before diagnostic evidence warrants it.

The frozen scoped-request.json remains unmodified and unadmitted, with staging_base null. Root must select the actual stage base and regenerate the materialization/admission contract before execution. This report does not authorize staging or native work by this lane.

Aftermath source preparation remains separate: no demonstrated new placement defect warrants changing its frozen source. The current-source proposal remains unadmitted pending root's source choice and full-world memory admission; real-terrain before/after proof is still required.
