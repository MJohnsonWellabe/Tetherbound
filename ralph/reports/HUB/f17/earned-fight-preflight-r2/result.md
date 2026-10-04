# Modified observer compile/load and preflight

[Run37092531110](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/37092531110), job111115710179, artifact11263481494, exact executed source `1ef75431e366689314a1bee9a5c1f24f488d631c`. Capture source SHA256 is `4ee6cbb8889b3c4cbf1a957ca14023cc914827ef15de7ba5f305e66b07144f7a`, identical to the independently reviewed successor.

The actual Godot4.7 script compiled/loaded and deliberately refused the headless setup before gameplay. Its sole failure is the required native1920/preset/renderer/exact-source/fresh-output preflight. The result stays at title, has no scratch profile, prefix success or resumed input. Elapsed5.978s; zero script and engine errors. The GitHub wrapper exited1 and the workflow is correctly red. No native exit_code file was retained; result.json preserves that distinction.

The original1506byte ZIP, native/job logs, request, original artifact listing and workflow metadata are unchanged and hashed in result.json. This check exercises compile/load and preflight only. It does not exercise per-frame callbacks or write-failure handling, produce footage, pass a visual bar or close F17#6. Actual capture runtime remains dependent on the held graphics slot. The prior six scoped criteria passes are reused within their existing source boundaries.
