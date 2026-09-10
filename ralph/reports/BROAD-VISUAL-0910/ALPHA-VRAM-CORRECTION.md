# Voltarach alpha texture — VRAM import correction

## Defect and correction

CI run 34432804989 failed exactly one assertion group:
`test_texture_import_policy.gd::test_every_runtime_3d_texture_uses_vram_compression`
named
`assets/creatures/tetherbound/voltarach/models/voltarach_extracted_base_color_alpha.png.import`.
The sidecar was a Lossless import (`compress/mode=0`, plain `path=`,
`vram_texture: false`, pending `detect_3d/compress_to=1`). The `_alpha` image is
an active runtime colourway, unlike the unsuffixed extracted generator input
that the policy deliberately excludes.

Only that sidecar changed. It now matches the installed Burrowback and
Galecrest alpha texture policy: `compress/mode=2`, `path.s3tc` and matching
S3TC destination, `imported_formats: ["s3tc_bptc"]`, `vram_texture: true`, and
`detect_3d/compress_to=0`. The explicitly retained creature policy
`mipmaps/generate=false` remains unchanged. Final sidecar SHA-256:
`C37050A4D6121D79533B23835ED46DCE96CF627CA5CCC3895509140AC983F521`.

## Guarded receipts

The coordinator's guarded import receipt is
`.artifacts/broad-visual-0910/runs/alpha-vram-basal-platform-import-first/result.json`
(SHA-256
`583793A2931DDACA40BF718C41710726612A4C4E3EBD9C02ADF92B9B0A11DE5A`):
started `2026-09-10T03:51:11.4453186Z`, ended
`03:51:19.2574840Z`, exit `0`, no errors or remaining Godot census. Its console
shows the Voltarach alpha image scanned and reimported, and the coordinator
confirmed the imported source sidecar hash matches the final hash above.

The subsequent focused receipt is
`.artifacts/broad-visual-0910/runs/basal-lod-alpha-import-policy-first/result.json`
(SHA-256
`52266B044564A02EC7AAD6C9AB7D3AA9149C7E2BC15633FD63E7993D1867A58B`):
started `2026-09-10T03:51:55.6849054Z`, ended
`03:52:00.6999227Z`, exit `0`, no errors or remaining Godot census. The selected
grass and texture-policy suite passed **25 tests / 88,387 assertions / 0
failed**, including both texture import policy cases and the full runtime
texture inventory.

Finally, the native six-frame Stormwood run at
`.artifacts/broad-visual-0910/runs/stormwood-platform-fixed-basal-first/result.json`
(SHA-256
`4A9B5345B3D0969C9F4F0B669E2ABE859A1AF9A4F9306A5039DCA0B94295B5BD`)
started `2026-09-10T03:52:09.2376435Z`, ended
`03:53:13.1593336Z`, exited `0`, and loaded the retained indigo alpha in the
production world without a receipt error. That capture is a load/integration
check; the focused inventory test is the policy proof.
