# Autosave refusal diagnostic source packet

The original fresh seed-4 run at source
`8f29e7b3a1d19795d66892a3986dc47e6b2f5a2d` failed independently at a movement
refusal. Its native log also contains one strict redesign autosave refusal
around the third natural Bramblebun catch. The original log SHA256 and runtime
closure are pinned in `source-cut.json`. Its party observations show a Terrapup
and three caught Bramblebuns with live HP changes and negative Godot instance IDs.
Those observations do not identify the rejecting validator or prove corruption.

The log contains neither the validator's returned error array nor its rejected
snapshot. The retained isolated user profile contains cache/log directories but
no scratch save directory. The exact rejecting state is therefore unavailable
from the retained artifacts. No corrective mutation is proposed.

At the coordinator's explicit follow-up allocation, this packet retains the
existing `_redesign_errors(initial_data, portal_character)` return once and
checks the same `is_empty()` result. On refusal it keeps the original native
error, prints one structured `SAVE_SNAPSHOT_REFUSAL` line, then returns the same
empty request. The line contains the exact error array, call context, and JSON
serialization of the exact pre-identity snapshot already passed to validation.
The serialized string's UTF-8 SHA256 establishes extraction provenance. Logging
the string avoids reliance on a scratch save surviving process cleanup.

There are no diagnostic disk writes, extra validation calls, live-state writes,
identity generation, worker changes, new grants, retries, resume, fixtures,
assertion changes, error suppression, or budget changes. Successful saves do
not serialize or log additional data. Validators and transaction/async behavior
are unchanged. The extracted snapshot represents JSON serialization of the
rejected candidate; the validator's actual returned errors remain primary evidence.

For the next coordinator-owned original fresh run, locate the log line beginning
`SAVE_SNAPSHOT_REFUSAL ` and parse the remaining text as JSON. Verify
`sha256(record["snapshot_json"].encode("utf-8")).hexdigest()` equals
`record["snapshot_sha256"]` before extracting those exact bytes to an ignored
review artifact. Parse the snapshot separately and use the recorded character
ID when tracing the listed validation errors. Keep the original failed run and
its error as failed evidence. Do not count this diagnostic as a repair.

Source comparison proves removing this logging and replacing the retained-result
expression reproduces the entire pinned original saver. `git apply --check`
passed read-only against the coordinator checkout. No native/import/parser/render
or agent work ran here. Existing affected regression cases include
`test_the_fallback_autosave_carries_the_real_game_state` in
`tests/test_autosave_fallback.gd`, immutable-request tests in
`tests/test_fallback_save_worker.gd`, and the refusal/no-mutation cases in
`tests/test_save_redesign.gd`. They remain unchanged and unrun for this source-only
packet. Independent source review and the next original fresh run belong to
the coordinator. Diagnosis, fix, and criterion acceptance remain OPEN.
