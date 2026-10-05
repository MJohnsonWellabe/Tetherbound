# cloudreach-1 exact-command handoff

Source: `tb/visual-cloudreach` at
`d7c8618eef377e1b448635e8fe31a68f0b203c11`.
Request: [#525 cloudreach-1](https://github.com/MJohnsonWellabe/Tetherbound/pull/525#issuecomment-5986303272).
GPU: NVIDIA GeForce GTX 1060 3GB. Engine: Godot 4.7 stable,
`5b4e0cb0f`. Isolated device preferences selected through production
`graphics_prefs.choose`; fresh profile per command. Import and all six
requested commands ran serially under the render lock. No timing overlap,
source workaround, branch write or frame judgement.

| Preset / pass | Requested frames written | Sheets | Runtime qualification |
|---|---:|---:|---|
| Medium high-perch | 0 / 12 | 0 | FAIL: EncounterDirector never appeared |
| Medium day | 0 / 37 | 0 | FAIL: EncounterDirector never appeared; refusing partial-scene evidence |
| Medium night | 0 / 37 | 0 | FAIL: same boot failure |
| Low high-perch | 12 / 12 | 1 | FAIL: unscoped chapter flag: fly_tutorial_completed |
| Low day | 37 / 37 | 5 | FAIL: same progression-flag ERROR; zero rows skipped |
| Low night | 37 / 37 | 5 | FAIL: same progression-flag ERROR; zero rows skipped |

All 86 Low frames plus 11 sheets are retained at full resolution. Medium
commands produced no frames. No SKIP or SEAT-FAIL lines were emitted.

Per pass: `native.log` retains full stdout/stderr;
`native.receipt.json` and `service_manifest.json` record command, exact source
SHA, preset, GPU header, return code, elapsed wall time, errors and file
hashes. Wall elapsed here includes setup/capture work and is not FPS evidence.
Original high-perch JSON and matrix text manifests are preserved as
`frames/manifest.native.json` or `.txt`. Delivered manifests add render-service
provenance without changing native completion/record fields. Native completion
lines and manifests do not override the service's runtime-error FAIL.

Low matrices printed `# frame matrix: 37 frames written, 0 rows skipped`;
Low high-perch printed `HIGH PERCH LIVE OK: 12/12`. Each still logged the
progression-flag ERROR. The requesting lane owns code-blind judgement of
these images and any fixes. This delivery closes execution/reporting of the
request, not its visual criteria or runtime acceptance.
