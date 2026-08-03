/**
 * glTF loading, split out of the main engine facade so it can be fetched on
 * demand rather than shipped in the first bundle.
 *
 * Measured: folding the glTF loader and its extensions into src/core/babylon.ts
 * grew the engine chunk from 1.56 MB raw / 359 KB gzipped to 2.51 MB / 566 KB.
 * That is 207 KB gzipped of parser that milestones M0 through M4 never touch,
 * because docs/02_ART_BIBLE.md puts every real model behind M5 and everything before it is
 * colored primitives.
 *
 * So AssetLoader.ts imports this module dynamically. A player who never loads a
 * model never downloads the parser, and once real assets land it arrives in
 * parallel with the first model fetch rather than ahead of the title screen.
 *
 * The extensions are registered individually rather than via the
 * '@babylonjs/loaders' barrel, which also drags in the OBJ and STL loaders plus
 * Draco and the KHR variant machinery. This list matches what our own asset
 * pipeline emits (see scripts/optimize-assets.mjs: meshopt compression,
 * quantization, WebP textures). If a downloaded model warns about a missing
 * extension, add that one line here rather than reaching for the barrel.
 */

export { LoadAssetContainerAsync } from '@babylonjs/core/Loading/sceneLoader';

import '@babylonjs/loaders/glTF/glTFFileLoader';
import '@babylonjs/loaders/glTF/2.0/glTFLoader';
import '@babylonjs/loaders/glTF/2.0/Extensions/KHR_materials_unlit';
import '@babylonjs/loaders/glTF/2.0/Extensions/KHR_mesh_quantization';
import '@babylonjs/loaders/glTF/2.0/Extensions/KHR_texture_transform';
import '@babylonjs/loaders/glTF/2.0/Extensions/EXT_meshopt_compression';
