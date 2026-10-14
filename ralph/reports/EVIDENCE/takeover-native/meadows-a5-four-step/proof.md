# Meadows a5 four-step native batch: overall FAILED

Exact validation source `a5e6b656c153eb48e398d29d00b4d4517fc476f9` combines repaired Meadows with the reviewed HUD/config bytes. Receipt interval `2026-10-14T04:36:51.7012807Z` to `2026-10-14T04:37:52.3823837Z`.

| Step | Result | Evidence |
|---|---|---|
| Headless focused | PASS |15 exact methods,209 assertions,0 failures;13.452s |
| Actual Compatibility | PASS |OpenGL NVIDIA GTX1060; original transform assertion,4 assertions/0 failures;14.821s |
| Actual Forward+ | PASS |Vulkan NVIDIA GTX1060; same original transform assertion,4 assertions/0 failures;18.846s |
| Unchanged objective smoke | FAILED diagnostic guard |Natural exit0 and original1920x1080/28-title/PASS witnesses, but nonempty stderr warning |

The objective warning is `HUD has no player; readout will stay empty`, at `playground_hud.gd:1083`, called by `smoke_objective_hint_card.gd:71`. It was not exempted or suppressed. Three passing steps do not turn this mandatory four-step batch green. Geometry witnesses alone do not satisfy its strict diagnostics contract.

Independent verification checked45 raw source SHA-256/Git blob bindings, exact source/clean stage, engine and admitted packet hashes, all four observed argv and natural zero exits, serial chronology, log hashes and recorded resource/time floors. First three stderr streams are empty. Original failed receipt/logs remain untouched.

[raw-bundle.json](raw-bundle.json) embeds the raw receipt/logs, admitted packet, source composition and independent review byte-exact as base64. Canonical LF container SHA-256: `32070e1ee400655430a61d63c7f5cd44a0cf15f41adf7cb531cce0a14811421d`. All16 entries independently round-trip to declared lengths/hashes. No visual acceptance, full-world proof, integrated coordinator CI acceptance or criterion closure is claimed.
