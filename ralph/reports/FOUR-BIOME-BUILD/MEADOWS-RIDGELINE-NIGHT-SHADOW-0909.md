# Meadows Ridgeline night shadow candidate — 2026-09-09

## Scope and cause

The canonical Ridgeline Watch capture was correctly pinned to clear weather and
the production `night` preset at hour 23.008. The preset describes its low
`-20` degree moon as a soft shadow direction, but omitted `shadow_opacity`.
`WorldLook._apply_sun()` therefore installed its `1.0` default. The same code
documents that angular-distance and blur softening do not reach the shipped
Compatibility renderer, while opacity does.

This candidate adds only `times.night.sun.shadow_opacity = 0.68` in
`data/config/art.json`. The value is a restrained existing scene-authored floor,
not an authored numeric requirement for night. It retains directional/contact
shadow. Exposure, ambient, palette, weather, camera, terrain, character, and
Stormwood surge values are unchanged. Explicit weather/realm deltas still layer
after time of day and win.

## Focused contract evidence

`tests/test_night_shadow_contract.gd` uses the real `WorldLook`,
`DirectionalLight3D`, and `Environment` apply path.

- First run: failed. `Engine.get_main_loop()` was null because the standard
  `TestCase` runner executes during `SceneTree._init`; night and weather remained
  at `1.0` because the fixture never attached.
- Corrected run: assertions passed, but emitted
  `ERROR: Can't use get_node() with absolute paths from outside the active scene tree.`
  Calling production `_ready()` on an unattached subtree reached its `/root/Game`
  lookup. The error is retained and this run is not the clean proof.
- Final run: `1 test(s), 0 failed`, no warnings or errors. It loads the same
  production JSON that `_ready()` loads and exercises the real synchronous apply
  methods. Verified clear night `0.68`, day `1.0`, explicit weather `0.08`, and
  Stormwood Break `1.0`.

## Matched production capture

Output:
`shots/catalogue/meadows/round-ridgeline-night-shadow-20260909T1500Z`
(the directory label was prepared before launch; actual run was
`2026-09-09T14:29:21.1871550Z` to `14:30:46.0062994Z`).

The production catalogue camera/player/rig transforms exactly match the retained
baseline for both frames. The current manifest records 1280x800, clear weather,
day hour 8.008 with live opacity `1.0`, and night hour 23.008 with live opacity
`0.68`. It completed 2/2 with no failures. The console contains no `ERROR` or
`SCRIPT ERROR`; standard interpolation-deprecation and existing Terrain3D
no-mipmap warnings remain. Guard peak: system commit 77.52%, 259 processes,
owned private 5,760,724,992 bytes, owned working set 2,402,430,976 bytes; no stop
reason and zero Godot processes afterward. The wrapper could not recover a
launcher exit code after its console child exited, but the manifest and console
both report the completed 2/2 result.

Fixed pixel-region measurements, before -> current night:

- whole frame pixels at luma <=10: 38.06% -> 34.80%
- trainer torso/legs: 71.86% -> 69.82% (mean 8.41 -> 9.03)
- near ground: 52.84% -> 50.31% (mean 12.50 -> 13.23)
- centre grove: 37.59% -> 34.29% (mean 16.80 -> 18.12)
- right tree mass: 59.46% -> 53.03% (median 6.37 -> 8.74)

The movement is measurable but narrow. The trainer remains dark and dynamic
creature placement differs between boots. This is a review candidate, not an
accepted Meadows night fix; no second lighting tune is justified before an
independent image verdict.

## Hashes

- `data/config/art.json` at capture: `DE03F852C27904E0EF6D7BE4B0AE07972AF0A24E6F9808FB0C98E3D6AA639B8E`
- `data/config/art.json` after the separately approved craftsperson-only edit landed in the shared tree: `2BBE69957C79051B9C8E9B5BAE4EB487F9DFB85BBD9C8655A060033539BEFFA3`
- `tests/test_night_shadow_contract.gd`: `F629D85329D786A89A9CD4304840DFB5EC2406C73C7FA60785E4115E2DD31435`
- `tools/_capture_meadows_ridgeline_night_shadow.gd`: `33AFEA0D9FE05D628C9FBC977659FEAD1029688FA6C083C9CB48E0F151F0BAB8`
- current day PNG: `2876213A28C684382CD9BAFA73E9A7AD237E89AA62682EB671A921E5966C32FC`
- current night PNG: `9F3F912D7C0EED74CE5BA5445330A29236BAF7FE0170D8325FBD97BA1A4AE8A1`
- current manifest: `D9D909FDE9BD5C4D376951535976CBD8747E79135C659F910A9C1083366AEBFB`
