# BUILD-SIZE — runtime texture import policy

Status: import policy, focused checks and Windows PCK measurement complete.
Independent visual comparison remains an integration gate before landing.

## Scope and baseline

- Baseline commit: `bdc274fc70a0fd822ffbfd6a6895535b70abada5`.
- Reproducible tracked inventory before the change: **610 texture `.import`
  sidecars: 497 Lossless (`compress/mode=0`), 113 VRAM Compressed
  (`compress/mode=2`)**. The owner's 497-file finding reproduces exactly; the
  denominator is two higher than the PR comment's earlier snapshot because this
  head has two additional already-compressed textures.
- Windows-preset pack command:

  ```powershell
  Godot_v4.7-stable_win64_console.exe --headless --path . `
    --export-pack "Windows Desktop" `
    ralph/reports/FOUR-BIOME-BUILD/build-size/baseline/Tetherbound.pck `
    --log-file ralph/reports/FOUR-BIOME-BUILD/build-size/baseline/export-pack.log
  ```

- Baseline PCK: **1,133,890,456 bytes** (1,081.36 MiB), SHA-256
  `52C5A9E23D4317E9F936B3309397F214F1D801583A34BD8176D104DB5B33034A`.
  The export-pack log contains zero `^ERROR:` lines.
- A preceding full `--export-debug "Windows Desktop"` attempt could not create
  the EXE because this machine lacks Godot 4.7's Windows export templates.
  `--export-pack` uses the same Windows preset and produces the exact PCK whose
  size this lane is measuring; the executable template is not part of that
  byte count.

## Selection rule

The 497 Lossless sidecars are not all interchangeable. UI portraits, icons and
controller glyphs need crisp 2D sampling, and generator crops under
`reference/` are not runtime assets. The durable policy therefore selects
texture sidecars below `assets/` while excluding `assets/ui/**` and
`**/reference/**`. Eight unsuffixed
`*_extracted_{base_color,emissive}.png` generator inputs are excluded too:
Godot 4.7 proved that they contain JPEG bytes despite their extension, and
each is byte-identical to its correctly named `creature_*_lod0_*.jpg` sibling.
Runtime suffix variants remain in the policy.

- **255** formerly-Lossless runtime 3D sidecars selected, representing
  **490,426,328 source-image bytes**.
- **368** runtime 3D texture sidecars use mode 2 after applying the policy (255
  changed + 113 already correct).
- **242** Lossless sidecars remain intentionally: UI, reference art and the
  eight generator inputs.
- Exact changed set: `intentional-runtime-sidecars.txt`, 255 paths, Git blob
  hash `36d4a7b902c87bd3b7545d25d0fbb28c82e2c38f`.

Before Godot reimport, every selected sidecar has a two-line-only policy
diff (`compress/mode=0` to `2` and the now-unneeded
`detect_3d/compress_to=1` to `0`); no excluded UI/reference path or unsuffixed
generator input is changed. Reimport is expected to update the selected files'
generated
`path.s3tc`, `dest_files`, `metadata.vram_texture` and `detect_3d` fields; any
tracked `.import` outside the manifest is import churn and must be restored.

## Reference-folder hygiene

The 44 missing markers were inspected before adding them:

- 44 folders, 159 files, all PNG generator inputs;
- **15,562,232 exact source bytes** excluded;
- no GLB, scene, code, data or other non-image file in the folders;
- no runtime source reference to any of the 44 `reference/` paths.

Each now carries `.gdignore`. This prevents both import work and player-build
packing, matching the 64 older creature/character reference folders.

## Durable guard

`tools/art_pipeline/texture_import_policy.py` owns the path classification,
`--apply` migration and `--check` guard. `finish.py install` applies the same
policy to textures beside newly installed creature or humanoid art, and the
README makes the required headless reimport explicit. Five isolated Python
tests cover selection, exclusions, mutation, malformed sidecars, idempotence
and the generated fields required after reimport. A default-suite GDScript
test walks the real asset tree and also requires `.gdignore` on every
creature/character reference directory.

Static evidence so far:

```text
python -m unittest discover -s tools/art_pipeline/tests -p test_*.py -v
Ran 5 tests in 0.043s — OK

python tools/art_pipeline/texture_import_policy.py --check
FAIL: 263 runtime 3D texture import sidecar(s) are not fully reimported for mode 2
```

That pre-import failure is intentional evidence: changing only the importer
policy parameters is not accepted as done. The check also requires Godot's
generated VRAM metadata and platform-specific compressed path, so it turns
green only after the imported payloads have actually been rebuilt. The 113
pre-existing mode-2 sidecars already meet that stronger condition. The later
eight-file exclusion is why the final runtime count is 255 changed, not the
263 shown by this deliberately pre-import diagnostic.

## Measured exit

The cleared Godot 4.7 import regenerated every selected payload. Its 1,064
tracked-sidecar normalization changes were reduced to the exact 255-path
manifest, and all 117 generated untracked `.uid` files were removed. The only
24 `^ERROR:` lines are three diagnostics apiece for the eight mislabeled
generator copies above; no other source failed. Those copies are byte-identical
to valid `.jpg` siblings, excluded from the runtime policy, and were not
renamed or otherwise changed in this lane.

```text
python tools/art_pipeline/texture_import_policy.py --check
PASS: 368 runtime 3D texture import sidecar(s) use mode 2

python -m unittest discover -s tools/art_pipeline/tests -p test_*.py -v
Ran 5 tests in 0.043s — OK

Godot --headless --path . --script tests/run_tests.gd -- \
  --only=test_texture_import_policy.gd
2 tests, 552 assertions, 0 failed
SCRIPT ERROR: 0; ^ERROR: 0
```

The post-change Windows-preset pack completed through `[ DONE ] savepack`:

- After PCK: **948,965,872 bytes** (905.00 MiB), SHA-256
  `1FF847CB993DC647EF270152C381603CAAE44CC9844D691A19536001A2FA2ABB`.
- Exact reduction: **184,924,584 bytes** (176.36 MiB), or **16.31%** of the
  1,133,890,456-byte baseline.
- The after export log repeats only the same 24 generator-copy diagnostics and
  contains no `SCRIPT ERROR`; `savepack` completes.

That delta is material, so the lane does not take the small-delta stop. Before
landing, the coordinator still must schedule one real Compatibility capture of
the creature stands and character select and give those before/after frames to
a separate code-blind judge. Any texture the judge identifies as visibly
damaged must return to Lossless; this report does not substitute self-judgment
for that gate.
