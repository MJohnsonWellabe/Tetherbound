# Meadows 87104 failed native focused proof

Source `87104cbbd443e5f01b0904d2fb6a43f1d84ab57d`. Original receipt remains **FAILED**, unchanged SHA256 `4118d9697c84e1423f7ad21b5bc0c9c6b994c3a8d68a5071418c6c737e266f36`. Native process exited1; the failure was not a resource or timeout stop.

Independent raw review confirms **15 tests / 209 assertions / 1 failure**. `test_runtime_instance_buffer_keeps_its_streaming_writer_reference` expected the later placement transform at(128,3,-64), but read identity at(0,0,0). Separately, stderr records `!is_inside_tree()` at `test_deferred_surface_batch_uses_late_materials_and_skips_departed_nodes:333`; that test prints ok, but its off-tree Node3D reparent requests a global transform and still fails the clean-diagnostics contract. These are distinct blockers.

Verified exact argv, packet/admission/supervisor/engine/raw-log hashes, 37 exact source tree/blob/SHA/byte bindings, all15 method identities and recorded resource floors. Min physical3536887808 bytes; commit4108394496; C15820161024; D23400083456.

`raw-bundle.json` embeds the original receipt/stdout/stderr once and binds the original job, admission, supervisor and requests by path/hash. No separate copied logs or images. No acceptance or visual score. Repair source/test execution semantics without weakening the assertions, then request a new exact-source run under the unchanged180s cap. No engine, stage write or commit occurred during this audit.
