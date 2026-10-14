# F10 isolated Compatibility diagnostic: FAILED

Exact source `1bc0de59c81d653cd11da39273b93b79338ec262`, original three-file payload, locked Godot 4.7. Actual renderer: OpenGL 3.3 NVIDIA 560.94, GTX 1060 3GB, Compatibility. The probe called nonexistent `StandardMaterial3D.get_shader_rid` at line 21; the committed production helper contains the same API at line 85. Script failure prevented the pixel oracle and quit from being reached; the supervisor stopped the owned process at its unchanged 60-second cap. No pixel/count/completion marker or shader-raster PASS exists.

Independent reviewer `state_consistency` verified source/log/receipt hashes and classified `VERIFIED_FAILED_SCRIPT_API_AND_WALL_CAP`. Sampled disk, physical and commit stop floors remained satisfied; this was not a physical-memory stop. Cleanup was verified: owned process drained, no Godot processes, root lease idle. Forward+ was not admitted or run. Do not retry this unchanged source or increase its cap.

The earlier r1 reserved-variable prelaunch failure is retained separately in the sibling `f10-los-prelaunch-r1` bundle. This r2 receipt is the actual engine/API failure. Diagnostic only: no gameplay, full-world wiring, visual or criterion acceptance.

[raw-bundle.json](raw-bundle.json) preserves 14 byte-exact base64 payloads; all decoded bytes matched originals. [hash-manifest.json](hash-manifest.json) records lengths and SHA256. Canonical UTF-8/LF bundle SHA256 `53cddc084edb9011e324774efc525fa5ab562c2e0e8455ef414007b1f5e40117`. Homes, caches and generated `.godot` data are excluded.
