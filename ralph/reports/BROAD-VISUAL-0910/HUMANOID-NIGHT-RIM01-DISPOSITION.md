# Humanoid night readability — rim01 disposition

## Result

Retain. The player-only StandardMaterial3D rim produces a meaningful night
readability gain on the production trainer at Gull Rest while its explicit
daylight endpoint is a material no-op. The accepted value is `strength 0.55`,
`rim_tint 0.15`, weighted by `environment.player_character_rim_scale` from
`0.0` in the base/day look to `1.0` at night. This is selective lit surface
response, not emission and not a global exposure, contrast or ambient change.

The visual acceptance is deliberately bounded. It proves the default trainer
from fixed rear cameras in Water and Meadows, not every playable model, pose,
biome or light direction. It improves one important defect but does not bring
the whole frame to the supplied commercial reference bar.

## Production binding and isolation

Only `trainer`, `kael`, `sera` and `lyra` declare `night_rim` in
`data/config/art.json`. `character_model.gd::_shared_variant_material()` writes
the authored strength and tint onto the installed body material, includes both
values in the shared material cache identity, and applies the current static
clock weight. `world_look.gd::_apply_environment()` updates that weight for
already-built cached bodies as the time look changes.

The application is restricted by material metadata. Grandpa and all ranked and
unranked NPC bodies remain outside it; the established rank emission-floor path
is unchanged. At scale zero, the player material has `rim_enabled = false` and
`rim = 0.0`, so daylight returns to the source material rather than carrying a
faint permanent edge. The candidate adds no mesh, light, camera or character
scale and does not touch the withdrawn floor01 patch.

Production-source hashes used for the guarded probe and Water capture:

- `data/config/art.json`: `A9BCC8CB69950C26EBA1FFD6FF209F6EC77535E7B1F6CAD2D295FE6E7A19EBD8`
- `scripts/characters/character_model.gd`: `0498AC3A864AA80C57EF2FD16C61C93B4123D690741D41A83F36084F5EB3AD89`
- `scripts/world/world_look.gd`: `2067A5842C8F5E2D636E664BD07CAB162D74D87EAB9F4C8EE1BD4585A08D0878`
- `tools/probe_character_night_readability.gd`: `9EBB4194670C6820DC2E5E5998CF234620187E1702CD4A9262A38D519D4AB897`

The source edit window was `2026-09-10T03:20:18.0837152Z` through
`03:24:38.3563699Z`; the static freeze check completed at
`03:25:17.5050584Z`.

## Guarded pipeline evidence

The coordinator ran `tools/probe_character_night_readability.gd` under the
exclusive engine guard. Receipt:
`.artifacts/broad-visual-0910/runs/character-night-rim-pipeline-first/result.json`
(SHA-256
`F5BEFA1B4B5192094FAE8808BA8D8CC766A8975123D36C7BFF6B661E2CCABF90`).

- started `2026-09-10T03:26:05.6623196Z`;
- ended `2026-09-10T03:26:10.7535781Z`;
- exit `0`, no receipt errors or remaining Godot census;
- console: `CHARACTER_NIGHT_RIM checks=51 failures=0`.

The probe builds all four installed playable rigs and inspects the materials
bound to their body meshes. Through the real `WorldLook`, it verifies exact
day-off, full night strength/tint and exact day return; it also verifies emission
state is untouched, Grandpa and a ranked grunt keep their original rim state,
and a synthetic `0.35` trainer variant does not alias the production `0.55`
cache entry. This is binding/isolation evidence. It is not visual proof for the
three alternate bodies.

## Production visual evidence

The guarded native Water run is
`.artifacts/broad-visual-0910/runs/water-character-rim-first/result.json`
(SHA-256
`651D3A7B3AF268E85FF4F2CC0429D2E03CFB7F8524AB000C462817B43A7166EB`):
started `2026-09-10T03:31:07.4064496Z`, ended
`03:31:47.0019971Z`, exit `0`, no receipt errors or remaining Godot census.
It captured 4/4 Gull Rest day/night catalogue frames with the production
Compatibility renderer. The completed candidate manifest is
`shots/catalogue/water/broad-character-rim01/manifest.json` (SHA-256
`34971729609B9B47CE0EE8B4A0077081344919941D761CCDB6EE6CE3801D79DC`).

The neutral pair maps as follows:

- F01: rim01 Gull Rest Beach day — SHA-256
  `4471456D1B4102D87A35D15AEE9DAE641751E4669E8532647A4AC09F8C7C63E3`
- F02: rim01 Gull Rest Beach night — SHA-256
  `5FC23F2CE7C3844F355AA044D6535CF7A78AC3CD3B0D42CFE00F608FFF74F3FE`
- F03: retained pre-rim Gull Rest Beach day — SHA-256
  `B51DCB2E827F440AAB9302750CF09061BE3848716111F858B4B9411D22C65930`
- F04: retained pre-rim Gull Rest Beach night — SHA-256
  `61E3EE5F5C89EC53B2CD2D4D79E6C8C2CDF8193E0A36A5D93E677C1035CFACF7`

The blind verdict is
`ralph/reports/BROAD-VISUAL-0910/JUDGE-GULLREST-RIM01.md` (SHA-256
`26F7B4BAD932FA8BDCA65413B3133C09F12A1FC3257F9F34774A26A219B8846E`).
It prefers F01/F02 overall. Daytime character/environment presentation is
visually equivalent between F01 and F03. At night, F02 retains distinct backpack
panels and straps, brown hair volume, sleeves and cuffs, plus knee/boot material
separation; F04 compresses the hair, pack, torso and legs into black masses. The
judge calls that night improvement substantial and more useful than F04's closer
tonal integration with the dark scene.

The second guarded trainer run is
`.artifacts/broad-visual-0910/runs/meadows-character-rim-first/result.json`
(SHA-256
`C983EE52559F1752E1B241E9B43125500722FA21A35ED82883FA25786FEF90FE`):
started `2026-09-10T03:38:51.5785788Z`, ended
`03:40:17.9055425Z`, exit `0`, no receipt errors or remaining Godot census.
It captured the production Grandpa's Village day/night pair; its completed
manifest is `shots/catalogue/meadows/broad-character-rim01/manifest.json`
(SHA-256
`24F983947CDD60051CDFB45510B0F9A5ED12B900D99B0570A2FAB2796BE35C26`).
The neutral F01/F02 candidate hashes are
`C64534EC6CE25390D208AAFF4AD1767B6A22F601DCBC3DA8DCF2168FFD7B7169`
and `75D8E57152F7046AF62F6E4DFE0BD107EEEE058DC86573EE92A3EAB917643174`;
the retained F03/F04 comparison hashes are
`06BD7255055504EBCA9AAAF6D5C456823A1349F3E62BA718DF176871F629071B`
and `49407B32EE17A5BE21324661EA534168DADE6A55E604A80F6FE34ACDD997B6DF`.

`JUDGE-MEADOWS-RIM01.md` (SHA-256
`D2E6700CB8D56BC7583E763A9C4AAF0505DE9C5AC540103873E89A7E1ED3B2C0`)
also prefers F01/F02: day is effectively tied, while the candidate night keeps
the trainer's hair, collar, sleeves, backpack, arms and boots separated from
the lawn. The comparison night loses the head/pack to near-black and makes the
legs hard to distinguish from grass. The judge explicitly limits this to the
player; nearby NPCs remain difficult in both frames. This independent biome
confirmation is why rim01 is retained despite the Rodline view below.

The Rodline workshop comparison is supportive only as a limit: it found no
meaningful overall pair preference, and the foreground humanoid was partly
obscured by another character and interface. That run also carried a concurrent
timber candidate which is being withdrawn, so it cannot isolate rim01. It does
not override the cleanly visible Gull Rest trainer result and does not establish
a broad Stormwood gain.

## Caveats and remaining bar

The retained pre-rim Water comparison was captured earlier from the same
catalogue coordinates, camera geometry and day/night requests, with the grass02
state that remains retained. It was not a byte-identical source checkout: the
compact HUD differs, and dynamic creature populations differ between manifests.
The judge therefore assessed the humanoid directly rather than treating the
whole frames as a pixel-isolated shader test. The near-identical day composition
and the probe's exact zero day state make a daylight regression unlikely, while
the material-detail change on the night trainer is visibly specific.

The bar remains view-dependent and below commercial quality. Gull Rest is
**No / Yes / No** for key-art world / same broad kind of game as Palworld /
commercial visual quality. Grandpa's Village is **Yes / Yes / No**. Rim01 does
not solve either scene's environment composition, weak creature focal presence,
surface repetition, interface hierarchy or lack of inviting depth, and the
distant rear views do not establish face quality.

The production alternate capture is
`.artifacts/broad-visual-0910/runs/water-lyra-night-rim-first/result.json`
(SHA-256
`13C32B3EBDCA77362EEDB81A261F37603EBAC416F41C22D99D5397954F1A9AA4`):
started `2026-09-10T03:47:12.9497906Z`, ended
`03:47:50.8366555Z`, exit `0`, no receipt errors or remaining Godot census.
The manifest (SHA-256
`D9C11E1E9C078127BF2124F459884DDBEFF51BE6F792209FA1F728A257E726A9`)
records `player_character: lyra` and `bound_player_character: lyra`, and 2/2
Gull Rest Beach day/night frames. Their hashes are
`CEE2516B3F13FB0BBFD2F1E29638508D0CF0D498BDB774A5FDCAD93666CD313B`
(day) and
`6D19CA95A4CBB7E044F27A2BF2C0BB99867858E05E522F2052491BAEFC628D8D`
(night). This proves the real selection route and actual alternate body, with
no synthetic model or scene.

Lyra is very bright relative to the night ground, but this pair cannot assign
that brightness to rim01. Static inspection of the retained source GLB (SHA-256
`3C82ADD7CCABC297900E0D2D6977FB729D132D1293D9AB41C17064D6CABF6380`)
shows its single `Material_1` already declares `emissiveFactor [1,1,1]` and an
`emissiveTexture`; both emissive and base-colour texture slots point at the same
embedded `texture_0`. `character_model.gd` preserves an imported emission
channel, while rim01 does not write emission, and the guarded probe verified
emission state is unchanged across day/night rim application. Thus the full-body
self-lit component is pre-existing source material behavior; rim01 can add edge
response on top, but its share of this bright night image is unmeasured without
a pre-rim Lyra frame. Do not use the Lyra image as evidence for a successful
rim gain or retune her source material within this disposition.
