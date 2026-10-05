# F32 flag parse cache — independent source review

PASS for bounded source correctness. No implementation blocker found. This is not runtime, save/co-op regression, or performance acceptance.

Reviewed commit `bd761aaa24babd5c537abf6e6f85bdf663702385` against its exact parent `2ce7f10cf9875952967a017b37b8c21ae2099035` in `D:/tetherbound/codex-perf-cpu`. The committed diff changes only `scripts/world/f32_source_service.gd` (17 additions, 2 deletions): three static cache fields and `_enabled()`. Read-only Git confirmed the parent and one-file scope. No engine, runtime tests, benchmarks, imports, exports, game edits or Git mutations were performed by this review.

`_enabled()` at lines 39–53 still calls `FileAccess.get_file_as_string("res://data/config/f32_runtime.json")` on every query before considering the cache. Its reuse condition is a previously valid dictionary parse plus equality of the entire freshly read String with the stored String. There is no timestamp, byte-size, frame-counter or elapsed-time gate. A changed decoded text therefore forces parsing on the next query that reads that text, even within the same second/frame or with equal file size. This does not strengthen the underlying file-read atomicity; a concurrent change after a read is observed by a subsequent read, as before.

| Input/state | Source behavior |
|---|---|
| First valid dictionary | Parse; cache complete text and the original `cfg.get("runtime_enabled") == true` predicate. |
| Identical text after a valid dictionary | Return that cached boolean. |
| Different text, including whitespace-only changes | Parse again; replace cache only after a valid dictionary. |
| Invalid JSON or valid non-dictionary JSON | Invalidate reuse and return false. |
| Repeated identical invalid/non-dictionary input | Parse on every query; no invalid-input result is cached. |
| Valid text restored after invalid input | Parse again because the validity bit is false, even if the text equals the older cached text. |
| Missing/read-failed file returning empty text | Read still occurs; empty text cannot establish a valid dictionary cache and remains fail-closed. |

The gate predicate is unchanged, including existing Variant equality semantics and missing-key behavior; this patch does not introduce stricter flag typing. The cache stores only a String and boolean, not a mutable parsed dictionary exposed to callers. Static reuse is local to the process and the same fixed resource path; no durable/save field or default configuration changes.

`submit()` (lines 18–22), `stock()` (24–27), `plot()` (29–32), and `notify_settled()` (36–37) are unchanged. The first three still consult `_enabled()` and validate their injected Callables, with the same refusal shapes and deep copies. Settlement notification still duplicates and emits the existing owner's verdict after its save/ACK path; the cache adds no submission, transaction, save, acknowledgement, RPC or journal operation.

Validation was source comparison and state-transition reasoning only. Godot parsing, actual runtime flag edits, file-read failure diagnostics, saves/co-op behavior and any speed benefit remain unproved by this review. The earlier `29237b38efd3c011b88a5588e92e319b05b90c98` release runs predate this flag-cache commit and cannot establish its performance effect.
