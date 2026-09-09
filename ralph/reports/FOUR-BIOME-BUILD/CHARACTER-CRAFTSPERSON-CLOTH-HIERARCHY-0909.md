# Craftsperson garment value cleanup — 2026-09-09

Status: one production candidate prepared and runtime-bound; independent image review pending.

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
