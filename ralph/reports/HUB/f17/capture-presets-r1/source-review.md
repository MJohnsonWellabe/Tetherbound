# F17 capture preset selector: independent source review

Reviewed 2026-10-02, read-only; no Godot, import, world or render launched. Base HEAD `d652595bb411dde4f076270fe443598bfbecb454`; this is the uncommitted bounded capture/test candidate, separate from the ongoing M1 r5 source.

- `tools/capture_f17_visual.gd` SHA256: `4B8F5699A2FC578E1F39EE4D99E30E2B3D0AB851D904E329649F04F72BC27BB9`.
- `tests/test_f17_capture_presets.gd` SHA256: `D9FFA2E74C1167A431FE3157762799BC2855F6115D509EC8E696DD9EF9B95439`.

Source verdict: suitable bounded repair for native execution. `_capture_presets()` delegates to the actual static `capture_presets(preset, paired_high)` selector. The selector creates `Array[String]` first and appends strings, so all paths return that typed array rather than assigning the old conditional expression's untyped array to it. Low yields Low, Medium yields Medium, and paired capture yields Medium then High. The camera, route, weather, diagnostic labels, manifest completion and acceptance checks are unchanged by this diff.

The regression calls the same production selector directly for all three branches, assigning each result to `Array[String]` and checking seven size/name assertions. It does not construct the capture's inherited `SceneTree`, call `_run`, await frames or create a world. This avoids the former test candidate's deferred `_run` side effect. Source inspection found no blocker in the final static-selector version.

Native evidence remains required: execute only `test_f17_capture_presets.gd` with the repository test runner and retain exact revision, native output, exit code, one test/seven assertions and zero script errors. A parser-only success would not replace this runtime test. The previously reported actual Low run `37075566898` failed at the old typed-array assignment and timed out with exit 124; it remains failed evidence. Then run the bounded actual capture to establish that production reaches saved frames on this repaired source. A partial farm diagnostic still writes `complete=false` and cannot establish the full visual witness. Full Medium/High still/motion captures and independent Bars A/B verdict remain open. No new visual or M1 acceptance is granted here.

## Native targeted regression receipt

Parent supplied remote run `37081572825` on exact source `ec40283309`. Independently read retained `.tmp/f17-proof-r1/preset-r1-artifact/run.log`, `exit_code` and manifest: Godot 4.7 native selected `test_f17_capture_presets.gd`, executed one test/seven assertions with zero failures, exit 0, duration 4s. The retained run log contains no SCRIPT ERROR. `git show` confirms that exact commit contains the reviewed static production selector and direct-call three-branch regression. Current capture/test hashes still match the snapshot above. This resolves the named typed-selector runtime check only; actual world capture, full visual witness and independent Bars A/B acceptance remain open.
