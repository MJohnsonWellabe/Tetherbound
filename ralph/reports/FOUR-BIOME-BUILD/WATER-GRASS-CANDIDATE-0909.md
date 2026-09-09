# Water grass candidate — 2026-09-09

Status: diagnostic capture complete; candidate HELD, no art acceptance or
production asset replacement. Fresh blind judging is pending: spawning the
required new judge was rejected by the agent thread limit. Do not substitute
the implementing lane's opinion for that verdict.

At Water / Gull Rest Signal Spire / day, the actual Terrain3D grass slot was
temporarily given the generated grass candidate. Normal, scalar UV scale .27,
camera, frozen actor pose and generated shader were held fixed. The original
Texture2D object and scene were restored afterward.

Successful capture:
`.artifacts/water-grass-candidate-diagnostic-0909/run-20260909T225959410Z`.
Manifest complete=true, failures=[], all six restoration checks true. Reference
and restored PNGs are byte-identical, SHA256
`d35eca03af0d4ab04e51b82460b1e285412d24d57b5377ef35466e49de739395`.
Candidate SHA256
`b0153389a8add3b72bf4a0b3c011368d1e2d0f041bdfd6f04ee8de3ae2b63f3a`.
All three share frozen-state hash
`9f8c619e8a1d95ab928ddcdf80f44856fbe506748bb5187c58c035fe9d594eff`.

The first candidate check failed before rendering on an inherited member name
and strict inferred types, preserved in `run-20260909T225829746Z`. Corrected
source passed checks, texture-array preflight and the first actual world capture
(38.807 seconds), with no ERROR or SCRIPT ERROR. Existing Terrain3D interpolation
deprecation warning remains. No unchanged retry or discarded visual failure.

The original generated PNG is unchanged:
`.artifacts/water-grass-candidate-0909/grass-v1.png`, SHA256
`5f4c10347361d9b21112a807eaa6afc108fb72b7cffd4c1c0bb3e864babb9e50`.
Exact prompt: sibling `PROMPT.txt`, SHA256
`0b4e0ae88a1705fa8bb27108f786b031b93cc7c1cac9a217ef1f9dd78b6dcad2`.
Runtime normalized a copy from 1254-square RGB to the initialized production
1024-square DXT1 format with 10 mips; all size/format/mipmap checks passed.

The normalized tile's opposite-edge RGB discontinuity is 11.401 on X versus
4.629 for adjacent interior pixels, and 8.513 on Y versus 3.924 internally.
These elevated edge jumps leave material seam risk unresolved. The image is
not certified seamless. A static frame cannot establish motion shimmer or mip
transition behavior. Further work needs seam correction, moving-camera evidence,
and the full independent visual rubric, not a whole-biome pass from this view.
