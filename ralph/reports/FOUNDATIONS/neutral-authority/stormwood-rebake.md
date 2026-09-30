# Stormwood full bake

Executed source: `e075f81ea52365b304629ddff4a2a98c33b5cc38`.

The existing unchanged baker computed and wrote all 108 regions. Native exit was 0 after 274.250 seconds. The six input files retained their exact pre-run SHA256 values. All 108 generated resource files are byte-identical to the prior generation; only the manifest changed, from fingerprint 601121851 to 2236840266. The input change is the existing Meadows terrain configuration included in the baker's dependency contract. No fingerprint algorithm or source file was changed.

The original raw log retains three startup ERROR lines (empty resource paths and the absent headless camera), one interpolation warning, and zero SCRIPT ERROR lines. This is a successful writer receipt with verified outputs, not a clean-engine claim. No editor/import/render/export or parallel engine was used.

Exact before/output hashes, command, isolated userdata paths, start/end times and native receipt are in `runtime/stormwood-full-rebake-r1-before.json` and `runtime/stormwood-full-rebake-r1-receipt.json`; the native stream is `runtime/stormwood-full-rebake-r1.txt`. The first launcher preflight used a filename glob that omitted negative-coordinate region names and refused before launching Godot. The corrected glob covers all 108 `.res` files. No test was skipped, disabled or quarantined.

Post-generation source `cd702f8bc909eed9331931115e6685951e3cc61e` passed eight existing named methods, 86 assertions, zero failures, native exit 0 in 403.203 seconds. Its log contains zero ERROR and zero SCRIPT ERROR lines. Freshness, sampled committed heights, route centrelines, off-route exclusion, spur mouths, painted widths, spur junction flares and surface configuration all passed. All checked input/output hashes remained unchanged. Exact selectors and the command are in `runtime/stormwood-affected-r1-receipt.json`, with the native stream in `runtime/stormwood-affected-r1.txt`.

The original full-batch stale-manifest failure remains in its historical red log; this actual bake and affected witness close that failure. Other outstanding integration failures remain open. This generation adds no acceptance MET count and does not relabel the original batch green.
