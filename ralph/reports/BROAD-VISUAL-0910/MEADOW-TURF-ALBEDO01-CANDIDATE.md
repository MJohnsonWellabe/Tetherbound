# Shared meadow turf albedo candidate 01

Status: **WITHDRAWN**. South Bridge modestly preferred the candidate, Glass Field found no meaningful difference, and Grandpa's Village narrowly preferred the control. This mixed result does not justify replacing a shared terrain source. There is no production consumer of the candidate.

## Source diagnosis

The repeated exposed-ground complaint is present in fresh Meadows and Stormwood reviews. The shared source `meadow_grass_Color.png` visibly contains coarse dark/light clouds in addition to fine grass detail. Stormwood's terrain bake writes height only, so its broad patches do not originate in painted control or colour maps: texture asset id 0 supplies the surface everywhere that no other control data exists.

The generator specification deliberately gives the coarsest 1.2–2.5 m octave 12% amplitude. Runtime config sets `uv_scale` to 0.27, which is a 3.70 m repeat even though its nearby comment says 5 m. This makes the authored coarse clouds and tile period visible beneath sparse grass. Mipmaps are enabled; no missing-mipmap or colour-space defect was found.

Stormwood also duplicates the texture-binding path, hardcodes its tint and normal depth, and omits several authored material properties. That drift is real, but it does not explain the broad patches embedded in the source albedo, and applying the Meadows macro-variation shader would add another variation layer rather than isolate this cause.

## Candidate provenance and controlled mechanism

Root generated `meadow_grass_turf01_Color.png` as a separate bitmap from the existing meadow albedo reference. The source PNG is 1254 by 1254 and remains unmodified. Its normal Godot texture import used `size_limit=1024`, matching the production texture array's 1024 by 1024 runtime size while preserving the generated source. The bitmap, import receipt and working diagnostic probe now live under `.artifacts/broad-visual-0910/held-turf01/`; production config and binders contain no reference to them.

`tools/probe_meadow_turf_albedo.gd` extends the production catalogue. After the real world mounts, it requires Terrain3D texture id 0 to reference `meadow_grass_Color.png`, loads the candidate through Godot's ordinary importer, and requires both loaded textures to have identical dimensions. It then replaces only the live id 0 `albedo_texture` and calls `update_texture_list()`. It snapshots and compares id, name, normal texture, UV scale, normal depth, AO, roughness, detiling, and tint before and after. The manifest records source/candidate paths, loaded dimensions, instance identity and property preservation. A mismatch fails before capture.

The first GPU-readback revision failed parsing at 07:25:28–07:25:36 because `RenderingServer.texture_2d_layer_get_data` is not exposed to GDScript in the installed Godot 4.7 build. Terrain3D exposes its generated array only as a RID and the project already documents that it exposes no `Texture2DArray` wrapper. The working probe records normalized imported-source and imported-candidate hashes, obtains Terrain3DAssets' `get_albedo_array_rid()` before and after `update_texture_list()`, and requires the terrain material's `_texture_array_albedo` binding to equal that current RID. It cannot truthfully hash layer zero itself. Source inspection of the vendored Terrain3D 1.0.2 binary shows that `update_texture_list()` validates inputs, regenerates the albedo texture array, and updates `_texture_array_albedo`; this supports the binding path but is not GPU byte proof. The failed verification receipt remains evidence of that limit.

Controls use unmodified `tools/catalogue_survey.gd` at the same subsets, times and output resolution. Proposed views are Grandpa's Village and South Bridge in Meadows, and Rodline Post and Glass Field in Stormwood, each by day and night. These are catalogue presentation evidence only; they do not prove campaign traversal.

## Import and generation record

Built-in imagegen was used with the existing `meadow_grass_Color.png` as the edit target. The generated file was copied without modification from `C:/Users/mattj/.codex/generated_images/01a088dd-e144-70c0-a04e-16b0a7307f6a/exec-3fc528f8-288d-42ab-985d-41b63a2fe99f.png` to the project sibling path above. The requested 1024-square output arrived as a 1254-square source. Ordinary Godot import uses VRAM compression, mipmaps and `process/size_limit=1024`; it does not overwrite or re-author the source image. Both guarded imports were clean (06:56:58–06:57:08 and 06:58:04–06:58:14). `turf-import-dimensions-first` ran clean at 07:00:52–07:00:57: Texture2D and image both 1024x1024, mipmaps true, compressed true, format 17. Meadows candidate ran clean at 07:01:15–07:02:49 with four frames; the live id-0 resource replacement and preservation of its other settings were verified, but GPU layer bytes were not.

Exact generation prompt:

> Edit target: attached square grass-ground albedo texture for an existing stylized open-world game. Create one square seamless repeatable 1024x1024 terrain base-color texture, strictly top-down orthographic flat material swatch filling every pixel. Replace the large cloudy dark/light blotches with an even low-contrast natural olive meadow turf base while preserving the reference's average subdued yellow-olive/green earth palette. Add restrained finely resolved interwoven short grass/thatch marks and tiny irregular soil gaps at very small scale, no distinct plants or tall tufts, no stones, no flowers. The whole tile represents approximately 3.7 metres of ground; individual fine grass marks should be centimetre scale. Maintain similar average brightness to the reference, with only subtle local hue variation. Neutral diffuse albedo only: no directional lighting, no ambient-occlusion shadows, no baked highlights, no vignette, no perspective, no big patch shapes, no blurred noise clouds, no obvious repeating clusters. The grass geometry above this texture supplies long blades; this texture supplies cohesive short turf beneath them. Edges must tile seamlessly in both axes. Output just the production texture, not a preview scene or contact sheet.

This prompt is intent, not proof of exact tiling or visual acceptance; those require runtime comparison.

## Disposition

- `JUDGE-TURF-SOUTHBRIDGE01.md`: slight candidate preference in daylight, confined to local ground/foliage integration.
- `JUDGE-TURF-GLASSFIELD01.md`: no meaningful pair preference; exposed ground remains mottled and disconnected from the blades.
- `JUDGE-TURF-GRANDPA01.md`: narrow control preference because the candidate's fine curls/flecks read as a flat fibrous carpet.

The candidate is withdrawn. The probe is retained only as diagnostic history. The failed GPU-readback revision is a documented limitation, and no post-repair native proof is claimed.
