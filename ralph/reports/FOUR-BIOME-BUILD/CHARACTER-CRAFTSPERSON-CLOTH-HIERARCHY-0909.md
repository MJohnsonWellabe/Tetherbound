# Craftsperson garment value cleanup — 2026-09-09

Status: the texture-only candidate was held after independent review; one distinct,
pipeline-backed emission correction is runtime-bound and awaiting independent image
review.

## Finding and scope

The prior audited character frame described the craftsperson as painterly, grimy and high-frequency beside the cleaner trainer. The installed GLB has one fused material. Its base colour and emissive texture records both resolve to the same installed image, and the runtime material reports emission enabled at energy `1.0`, roughness `1.0`, metallic `0.0`. An albedo-only edit would therefore fail to control the visible authored surface consistently.

The diagnostic false-colour fixture attributed one source-HSV selector (`H 65–165`, `S >= .14`, `.07 <= V <= .55`) to waistcoat facings/side panels, outer trouser/knee panels and small garment/tool-edge areas. It covers `347,369 / 4,194,304` UV pixels (`8.2819%`). The rendered mask excluded the face, beard, warm shirt, gloves, belt/leather and blue goggle lens. This is atlas-area attribution, not a claim about on-screen area.

## Candidate

`tools/repaint_craftsperson_cloth.py` hash-locks the installed source and changes only that proven selector. It preserves per-pixel hue and saturation, applies a 9-pixel median to value, blends a restrained seven-band value quantisation at 35%, blends the total cleanup at 65%, then offsets the selected region to preserve its mean value. The same derivative is assigned to the duplicated body material's albedo and emission texture; emission state/energy and global finish are untouched.

- source: `craftsperson_lod0_texture_0.png`, SHA-256 `A260159B4FFAB4DED76497E4BD7E85FF5838DC43E1BFA044489E816712578E70`
- derivative: `craftsperson_cloth_clean.png`, SHA-256 `09C77C4B97FF47D11E0E50A19F7BC40976CA90703D012F54B49080CD88D8D404`
- changed outside selector: `0` pixels
- selected mean hue: `103.126536° -> 103.126536°`
- selected mean saturation: `.22702209 -> .22702209`
- selected mean value: `.17352987 -> .17352987`
- within-selector neighbour value delta: `.00298828 -> .00232079` (`-22.34%`)

`character_model.gd` includes the optional emission override path in its material cache key, loads it only on body materials, and keeps the existing Arlo albedo-only override behavior. The craftsperson config alone declares the paired overrides.

The first real editor import assigned UID `uid://bsoj8pph1ky80` and produced the explicit mode-2/detect-0 S3TC target. Its source MD5 is `57c13a49dcc414eca6bc4aa9580cde62`, destination MD5 is `4eb87549b304283ed18f6405539602ac`, and S3TC SHA-256 is `D7734B4D53B165D1D256463D7B5CA0F09F702898615CE07268A2C406B861B99C`. The source MD5 matches the checked-in derivative bytes.

The exact-path policy check reports `PASS: 1 runtime 3D texture import sidecar(s) use mode 2`. A fixed `1280x800` Compatibility fixture then exited `0` with 11/11 checks. It proved the installed source uses its companion image for both albedo and emission, while the production candidate uses the derivative for both; their duplicated materials and textures are distinct. Both retain emission enabled, energy `1.0`, roughness `1.0`, and metallic `0.0`.

- labelled fixture: `shots/character-craftsperson-cleanup/paired-1280x800.png`, SHA-256 `7F45B18634ACE409CB535502F60F76EE93866E335DEDEE2A127ABF8A4092EA82`
- neutral review copy (only the empty-backdrop headers removed): `shots/character-craftsperson-cleanup/neutral-paired-1280x800.png`, SHA-256 `9924B744411AC4C46F331BB60CB668F731AA7F0FC13C2BE64C5174CB1E1E68EA`
- runtime stdout: `.artifacts/craftsperson-cleanup-0909/fixture/stdout.log`, SHA-256 `E086CE7940FD2E31CE0DBDC43593CEC60C5A174668F8C7B189DE5CF41517651F`
- fixture receipt: `.artifacts/craftsperson-cleanup-0909/fixture/receipt.json`, SHA-256 `13BE0DF5E9FC88DDCB7744E7FC887F3A54E1842C5C8AC73B98EF0154EA5B8DDA`

## Evidence limits

The existing false-colour image and ten successful engine checks establish garment attribution only. Its wrapper failed after launch due a malformed sleep parameter, so it has no valid resource receipt and was not rerun. The later production fixture supplies the clean runtime binding proof. Independent review in `VISUAL-WAVE4-IMAGE-REVIEW-0909.md` found neither side meaningfully stronger at displayed size. Both provisionally fit the character reference bars, but the candidate adds no demonstrated player-visible improvement; root holds it from shipping. Differing cast shadows also limit fine lighting attribution. No near-identical second garment tuning is authorized.

The editor import itself exited after 26 seconds with Windows access violation `-1073741819`, despite completing the target texture import. Its stdout also detected the unrelated WoodTrim normal/roughness mapping, and the filesystem scan rewrote `project.godot`, that one protected sidecar, three previously clean Bark sidecars, and generated 154 untracked UID files. Root restored those exact files and removed the generated UIDs. All 287 pre-existing dirty sidecar hashes match their byte backup; the one intentional new craftsperson sidecar remains. This is not recorded as a clean import process.

## Distinct correction: reject exporter-artifact full-body emission

Wave 4's review held the texture-only cleanup because it did not make a meaningful
displayed-size improvement. A separate source audit then found that the installed
craftsperson GLB uses embedded image 0 for both `baseColorTexture` and
`emissiveTexture`, with `emissiveFactor [1, 1, 1]`. This is the exact signature that
`tools/art_pipeline/strip_character_emissive.py` classifies as a Meshy exporter
artifact. Commit `5262e025b` stripped that signature from the original six humanoids;
the later 22-body cast installation in `a96c0874f` added the craftsperson afterward.
A read-only current-tree dry run reports that 25 of 31 rigs still carry the signature.
That count establishes provenance only: this candidate changes the craftsperson body
alone and does not establish a cast-wide policy.

The GLB remains byte-identical at SHA-256
`0BAB2DF02CD1DF0A6A504430E1806F9EB2469DF0DDC4707C2545854765E5F73D`.
`character_model.gd` now accepts an optional body-only `body_emission_enabled` flag,
includes its tri-state value in the duplicated-material cache key, and preserves the
imported source behavior when the field is absent. The craftsperson config alone sets
it to `false` while retaining `craftsperson_cloth_clean.png` as albedo. The held
derivative, height, rig, clips, source texture, roughness `1.0`, and metallic `0.0`
are unchanged. The imported emission texture remains referenced internally, but the
production material disables the emission channel.

The focused production-node contract test ran in Godot 4.7 and passed `2 tests / 11
assertions / 0 failed`. It proves the craftsperson's held derivative and disabled
emission, the unchanged GLB hash, source craft emission, and absent-key preservation
on another generated-cast control. Its raw log contains no `ERROR`, `SCRIPT ERROR`,
or `WARNING` lines.

- focused run: `2026-09-09T14:33:43.656Z` to `14:33:45.804Z`, exit `0`
- focused raw log: `.artifacts/craftsperson-emission-test-0909/raw.log`, SHA-256 `4943CAEE78256B232EA364D456FF9753255966A969EAF159FC4B914EE22AC516`
- focused test: `tests/test_craftsperson_material_contract.gd`, SHA-256 `5B514B779FD5FDB5D8A5C43D040C2989FAED4C24E49964321C6FEC7463C26BA6`

The single fixed-camera Compatibility capture passed all `9/9` material and source
checks. The left body retains the installed self-lit atlas; the right production body
responds to the same scene light and shows substantially stronger light-to-shadow
separation across the face, beard, gloves, apron and boots. This is an observation of
the fixture, not an independent acceptance result.

- pair: `shots/character-craftsperson-emission/craftsperson-source-vs-pbr-1280x800.png`, SHA-256 `111A03BEA42447539ADD096145C45B19FAD8624325766A5D894C1EDC3B877982`
- neutral review copy (only the empty-backdrop header band cleared; every pixel outside that band is bit-identical): `shots/character-craftsperson-emission/neutral-paired-1280x800.png`, SHA-256 `3A721A19CACEF2E601E0CA1E5EB5583AA69C87A03898727962A8814F2F354DC2`
- run: `2026-09-09T14:34:49.029Z` to `14:34:56.017Z`, PID `15600`, exit `0`
- guard: not triggered; 8 samples; peak system commit `57.81%`; peak process count `255`
- capture raw log: `.artifacts/craftsperson-emission-capture-0909/raw.log`, SHA-256 `3404AA5A2E8A84F4858B48042DF7F81290332BE134113BF82E422F76A228F9B6`
- receipt: `.artifacts/craftsperson-emission-capture-0909/receipt.json`, SHA-256 `740592C8BCC408FB9FD9D3682E061A20C8DB4F63CB9F9DB84024C3F718661752`

The pair does not prove true cloth/leather/metal regional roughness: the craftsperson
is still a single fused surface with one imported material. It proves only that the
production body no longer emits its complete colour atlas and can respond to authored
scene lighting. No second emission or finish round is authorized before independent
review.
