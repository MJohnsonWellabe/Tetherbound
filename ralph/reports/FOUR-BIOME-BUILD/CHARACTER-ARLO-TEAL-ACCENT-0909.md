# Arlo teal cloth accent — 2026-09-09

Status: bounded production candidate, runtime-attributed and visible in a fixed
1280x800 body fixture. Ordinary-world and independent visual acceptance remain
pending. No broad cast claim is made.

## Evidence and change

The retained road frames at
`shots/road-heading/20260909T034351Z/blind/frame-a.png` and `frame-b.png` keep Arlo
recognizable, but his muted teal and brown outfit merges with the orange-brown road
at ordinary player size. The brown hair, trousers, boots, and pack already form a
coherent leather/earth family; the smallest useful change is to clarify the existing
teal cloth rather than retint the whole body.

The installed trainer GLB has one opaque body material. Its JSON declares the image
as embedded data in `bufferView: 6` with MIME type `image/png` and no external URI.
At runtime, the baseline material nevertheless reports its albedo resource path as
`res://assets/characters/trainer/trainer_lod0_texture_0.png`. That companion PNG is
byte-identical to the embedded image. These facts do not distinguish Godot reading
the external companion from the importer assigning that path to embedded image
data, so the baseline's byte source is not claimed here. The source material has no
emission, and the production character wrapper reports metallic `0.000` and
roughness `1.000`.

The candidate adds an optional `body_albedo_override` route to
`scripts/characters/character_model.gd` and wires it only for Arlo in
`data/config/art.json`. The override path is part of the shared material cache key,
then the code duplicates the source material before replacing its albedo texture.
This prevents an override material from being reused by another character config.
Accessories pass through the existing non-body path and do not receive the override.
All other material parameters remain sourced from the duplicated material.

`tools/repaint_trainer_texture.py` creates the external derivative from the exact
installed companion texture, whose bytes match the GLB-embedded image. It selects
only chromatic teal/cyan source pixels
(HSV hue 175–220, saturation at least 0.20, value at least 0.10), fixes their hue at
195, raises saturation to at least 0.55, and raises value by 18% with clamping. It
refuses to run if the source hash differs from the audited installed asset.

## Pixel attribution

The repaint changes 265,028 of 4,194,304 texture pixels (6.32% of UV texture area).
That percentage is not an estimate of on-screen cloth coverage. Broad exclusion
masks counted 1,486,348 skin pixels, 3,519,502 brown hair/leather pixels, and 89,659
neutral/white/charcoal pixels. Each mask has zero overlap with the teal selector.
The fixed fixture also shows the same face, hair, leather, white shirt, trousers,
boots, pose, and shadow on both bodies.

Exact source and candidate hashes:

- installed companion PNG SHA-256:
  `49814EE0259B54EF93E435E0B2BE37214B8F2A05C511E27FAC6428E4D683E447`
- generated teal accent PNG SHA-256:
  `093CD6BBF1AC46FA07179A5D5A72BF09099009BC984D7ACEE15A140DFC48F32E`
- intentional new `.import` sidecar SHA-256:
  `D7A5C9202BEE69A3941A872223498457072B1C184C23A3398D5CB5D13E7745E0`
- imported S3TC cache SHA-256:
  `7562B235040F6A240013AA1EC115BF092DC4591C1894FEC57BAF613B9590C516`
- imported cache source MD5: `0fff43e7282f75a518a0578a994c7a67`
- imported cache destination MD5: `f783901944c676569fd9113f851323aa`

## Import and runtime validation

The first integrated Water run happened after the art config was wired but before
Godot had imported the new PNG. It correctly exposed
`No loader found for res://assets/characters/trainer/trainer_teal_accent.png`.
That run is retained as an integration failure and is not clean Water evidence.

The subsequent exclusive Godot 4.7 Compatibility editor import completed with exit
0 in 14.6 seconds. Before it ran, all 287 pre-existing dirty `.import` files were
copied byte-for-byte to
`C:/Users/mattj/AppData/Local/Temp/tetherbound-character-import-backup-20260909`.
Their post-import hashes matched the backup. Editor-created UID files were removed
after exact-path verification; zero remain. Root restored the three clean-before
Bark sidecars rewritten by the editor. Final status is the original 287 modified
sidecars plus the one intentional new trainer texture sidecar.

`tools/probe_character_teal_accent.gd` then instantiated baseline and production
candidate bodies in one fixed 1280x800 frame. Its runtime assertions reported:

- baseline reported albedo resource path:
  `res://assets/characters/trainer/trainer_lod0_texture_0.png`
- candidate albedo path:
  `res://assets/characters/trainer/trainer_teal_accent.png`
- distinct albedo texture instances and cache entries: pass
- metallic, roughness, and emission state preserved: pass
- body material resolution and production override binding: pass
- process exit: 0; Godot count after exit: 0

The baseline path assertion establishes Godot's runtime resource naming, not which
of the identical embedded/companion byte stores supplied its pixels. The candidate
assertion is stronger: the explicit override loads the new derivative path, whose
pixels differ from both identical baseline sources.

The fixture is
`shots/character-teal-accent/paired-1280x800.png`, SHA-256
`BBBA19265DEDEF614FF13D5324575750C13557D6D55F6A5B14682D78147763D1`.
The right-hand production candidate has clearer cyan-teal sleeves and vest edges
against the orange-brown ground. This establishes material attribution and a visible
body-surface difference; it does not establish ordinary-world acceptance.

## Independent review and integrated context

The reused implementation-independent reviewer answered A **Yes** / B **Yes**
for the neutral paired image (frame 08), with a modest clearer blue jacket and
no evident regression in body, coverage or pose. See
`VISUAL-WAVE-IMAGE-REVIEW-0909.md` for the full verdict and reuse disclosure.
This accepts the narrow cloth contrast change; it does not establish that the
character or all ordinary-world lighting meets the visual target.

The corrected integrated Water run at 12:40:02–12:40:58 UTC completed the real
return-gate interaction with the imported character texture, exit 0 and no native
errors. Its isolated prerequisite flags make this a synthetic interaction proof,
not earned campaign credit. The canonical Meadows Ridgeline day/night capture at
12:42–12:43 UTC also includes the active character. The independent scene verdict
still finds poor night separation, so no general night readability claim follows.

The same production fixture now supports `--validate-only` for CI. It builds both
real character models and checks texture selection, separate cache materials,
separate texture instances, and unchanged metallic/roughness/emission. It exits
before viewport capture and reports seven checks. The CI wrapper preserves the
entire first-attempt log and rejects native errors as well as missing checks.

Local `--validate-only` first invocation passed all seven checks on Godot
4.7.stable.official.5b4e0cb0f at 13:02:28–13:02:37 UTC, exit 0, no guard,
with the complete stdout/stderr/engine logs clean. Receipt directory:
`.artifacts/water-gate-finish-mechanics-arlo-validation-0909/`.
The CI wrapper also passes GNU Bash 5.2 syntax validation; the initially guessed
`bash.exe` path was unavailable, so the bundled Bash-compatible `sh.exe` was used.

## PR96 compression correction

The first PR96 head `39917123258dfa32216aecb95264eccd7747d66a` failed
`test_texture_import_policy.gd` in CI34354734726 attempt1: the new sidecar was
still lossless mode0/detect1. The earlier S3TC hash above identified an existing
cache artifact, not proof that the sidecar selected it. The initial seven binding
checks did not cover compression policy; that gap is retained explicitly.

The exact-target policy tool set mode2/detect0, followed by a real headless import
at 13:11:10–13:11:19 UTC, exit0. No native ERROR/SCRIPT ERROR occurred; missing-UID
regeneration warnings were retained. The policy checker now passes and the
generated sidecar selects `path.s3tc` with VRAM metadata. Current sidecar SHA256:
`522AEF89AA50C67123F74D348DAAD7E5B0223315920AFA4F40B2E6EDBFD05FB2`;
selected S3TC payload SHA256:
`62BE8208EE9166E80D9CC53A56B4D8ED31009D579E6322F6FBCA50D469C44C43`.

A real 1280x800 redraw at 13:12:11–13:12:19 UTC passed all seven checks and saved
`shots/character-teal-accent/paired-mode2-1280x800.png`, exit0, clean raw logs.
The headless CI mode then independently passed seven checks at13:12:31–34,
exit0, clean logs. Receipts are under `.artifacts/water-gate-finish-` with suffixes
`mechanics-arlo-mode2-import-0909`, `lineup-arlo-mode2-render-0909` and
`mechanics-arlo-mode2-validate-0909`.

The independently reviewed compressed redraw (neutral frame05 in
`VISUAL-WAVE2-IMAGE-REVIEW-0909.md`) again received A Yes/B Yes for the modest
cloth contrast, with no visible face, body coverage, silhouette or grounding
regression. Fine cloth noise and the limits of a neutral stage remain. The full
existing policy checker also passed all401 runtime 3D sidecars locally.

All287 original dirty imports still match their retained pre-import byte backups;
the three clean Bark normal sidecars were restored and150 generated untracked
UIDs removed by exact path. Project settings remained unchanged. Root's new
backup command selected only textual diffs and therefore copied just project
settings plus the new sidecar; comparison correctly used the earlier complete
287-file backup rather than claiming that incomplete new copy protected them.

## Owned files

- `scripts/characters/character_model.gd`
- `data/config/art.json`
- `assets/characters/trainer/trainer_teal_accent.png`
- `assets/characters/trainer/trainer_teal_accent.png.import`
- `tools/repaint_trainer_texture.py`
- `tools/probe_character_teal_accent.gd`
- this report

The candidate does not alter the GLB, rig, scale, collider, animation, metal/emission
policy, Warden work, badges, or accessories. No other playable or NPC config changed.
