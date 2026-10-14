# Cut-key diagnostic: supervisor abort, no product verdict

Source `2c6b4b3d5ebd9aafbaf0d76866b474998897f069`. Receipt interval `2026-10-14T04:29:44.7628091Z` to `2026-10-14T04:30:33.1373026Z`. Parser exited naturally0 in 14.469s. The diagnostic then launched coordinator60628, host46892 and guest28816. Both original peers reported their expected isolated homes.

The supervisor aborted with **Child parent or image mismatch** while its coordinator still reported259 (running). Owned-job cleanup returned124 and confirmed a drained job. Independent post-run CIM inspection found no recorded owned PID or Godot; the root lease is idle. All recorded process argv/parent identities,11 exact source hashes, engine/admission/supervisor hashes, raw file hashes and recorded resource floors were verified. stderr was empty and logs contain no engine warning/error diagnostics.

No key-cut marker, guest restart, NET_RUN.json, transport observation or cut-key completion witness exists. This attempt provides no cut-key product verdict. The offending new member's PID/image/parent was never persisted: the guard throws before appending its record. Its identity cannot be recovered from these retained files. Do not infer a harmless process or broaden the allowlist from this failure.

This is an intermittent-failure investigation. Historical a9 CI failed; root reports actual merged29a CI38508850726 passed. No current-main-red claim, product fix or retry is established. Park this wrapper unchanged. The minimal offline follow-up is to persist the offending raw CIM row and current kernel-member list before rethrowing the same guard error; this changes evidence capture, not admission or process permissions.

[raw-bundle.json](raw-bundle.json) embeds byte-exact receipt, every runtime file, admitted packet and independent review. Canonical LF container SHA-256: `d5dad41e09e96faa803de11aafa2ff9c3d1a47e010b0530c5eb261430416ba9a`. Payloads retain original bytes and per-entry hashes.

The earlier timestamp prelaunch refusal is separate: [timestamp-prelaunch-raw-bundle.json](timestamp-prelaunch-raw-bundle.json), canonical LF SHA-256 `107dfe07af3e8d6be2d76a69839683c0b02522554af539d2f8ed4e008d4c3e3d`. It preserves the original admission/runner/job, expression-only reproduction and CPU timestamp-fix checks. No engine or runtime output belonged to that prelaunch refusal. It is not merged into the native attempt's outcome.
