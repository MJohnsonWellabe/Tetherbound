# Tidewake viewport/shutdown diagnostic: FAILED

Exact source `e006388448964301fb538209d132ff721bab1db3`, original stock Terrain3D DLL, Medium Forward+, one OFF shore-day frame. Receipt `2026-10-14T05:31:35.9968345Z` to `2026-10-14T05:34:58.6855712Z`. Parser passed in 14.682 seconds. Original terminal status remains FAILED.

The JPEG decodes to exactly1920x1080 and its hash matches metadata. Capture completion and shutdown markers are present through world/game tree exit. Natural capture exit zero: **False**. Capture exit code `-1`, stop reason `wall-clock cap reached`; creation-to-terminal interval 180.873 seconds. Failed-step receipt does not provide wall_seconds; this interval is not relabeled as that absent metric. Tree-exit/quit-request markers alone cannot prove process shutdown.

Strict diagnostics also fail: stderr contains both deprecated `instance_reset_physics_interpolation()` and grass_field rendering-camera mismatch warnings. The latter describes its capture context as expected, but the unchanged warning gate does not exempt it. No warning was suppressed and exit0 alone would not pass this run.

Independent review verified44 source/infrastructure SHA256 and Git blob bindings, clean exact staged source, pinned stock DLL and engine, admitted packet/supervisor hashes, exact observed argv, raw log/image hashes and recorded resource floors. Recorded PIDs are absent, no Godot/Blender remains and root lease is idle. No engine rerun or stage change occurred during review.

This establishes the produced image resolution for one diagnostic frame, not full OFF/ON matrix, quality acceptance or general shutdown reliability. Earlier failed6b receipts remain unchanged. [raw-bundle.json](raw-bundle.json) preserves 12 byte-exact base64 entries with verified lengths/hashes, including the JPEG and original receipt. Canonical LF container SHA256 `248e0267aa854740b8f376cfe4dfd4a62daa2787e35fe0bb03d85b53d95745de`.
