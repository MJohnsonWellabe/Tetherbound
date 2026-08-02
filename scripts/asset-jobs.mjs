// WHAT becomes what: every shipped asset, declared.
//
// optimize-assets.mjs is the machinery; this file is the decisions. A row
// here answers "which raw file(s), which transform, which output" so a
// re-run reproduces public/ exactly and the manifest writes itself.
//
// Groups let `npm run assets -- props` rebuild one slice.
//
// Sources are relative to assets_raw/. Kenney Nature Kit lives under
// "nature-kit/Models/GLTF format/", the GLB kits under ".../Models/GLB
// format/", poly.pizza models under "pizza/".

const NK = 'nature-kit/Models/GLTF format';

/** Prop families. Multiple variants per family become separate outputs the
 *  prototype resolver picks between; each is one merged vertex-coloured mesh. */
const props = [
  // Oaks: broad leafy silhouettes. Plain + detailed for in-family variety.
  { file: `${NK}/tree_oak.glb`, out: 'oak_a' },
  { file: `${NK}/tree_default.glb`, out: 'oak_b' },
  { file: `${NK}/tree_detailed.glb`, out: 'oak_c' },
  // Pines: the default silhouettes read better than the tall ones at scale.
  { file: `${NK}/tree_pineDefaultA.glb`, out: 'pine_a' },
  { file: `${NK}/tree_pineDefaultB.glb`, out: 'pine_b' },
  // Rocks: chunky boulders. D has the strongest height for outcrops.
  { file: `${NK}/rock_largeA.glb`, out: 'rock_a' },
  { file: `${NK}/rock_largeC.glb`, out: 'rock_b' },
  { file: `${NK}/rock_largeD.glb`, out: 'rock_c' },
  // Bushes.
  { file: `${NK}/plant_bush.glb`, out: 'bush_a' },
  { file: `${NK}/plant_bushDetailed.glb`, out: 'bush_b' },
  // Ground cover. Bamboo stalks are the kit's only real reed silhouette.
  { file: `${NK}/grass_large.glb`, out: 'grass_a' },
  { file: `${NK}/grass.glb`, out: 'grass_b' },
  { file: `${NK}/crops_bambooStageA.glb`, out: 'reed_a' },
  { file: `${NK}/flower_purpleA.glb`, out: 'flower_a' },
  { file: `${NK}/flower_redA.glb`, out: 'flower_b' },
  { file: `${NK}/flower_yellowA.glb`, out: 'flower_c' },
  // Landmark and dressing pieces (consumed from Phase 4 on).
  { file: `${NK}/stone_tallA.glb`, out: 'stone_tall_a' },
  { file: `${NK}/stone_tallB.glb`, out: 'stone_tall_b' },
  { file: `${NK}/stone_tallG.glb`, out: 'stone_tall_c' },
  { file: `${NK}/log_large.glb`, out: 'log' },
  { file: `${NK}/stump_round.glb`, out: 'stump' }
].map(({ file, out }) => ({
  group: 'props',
  transform: 'prop',
  sources: [{ file }],
  out: `models/props/${out}.glb`,
  provenance: { source: 'https://kenney.nl/assets/nature-kit', author: 'Kenney', license: 'CC0' }
}));

/** Terrain detail textures. Desaturated so vertex biome colour stays boss. */
const textures = [
  {
    group: 'textures',
    transform: 'texture',
    desaturate: true,
    size: 512,
    sources: [{ file: 'tex-grass/Grass004_1K-JPG_Color.jpg' }],
    out: 'textures/detail_grass.webp',
    provenance: { source: 'https://ambientcg.com/view?id=Grass004', author: 'ambientCG', license: 'CC0' }
  },
  {
    group: 'textures',
    transform: 'texture',
    desaturate: true,
    size: 512,
    sources: [{ file: 'tex-rock/Rock030_1K-JPG_Color.jpg' }],
    out: 'textures/detail_rock.webp',
    provenance: { source: 'https://ambientcg.com/view?id=Rock030', author: 'ambientCG', license: 'CC0' }
  }
];

/**
 * Buildings, stations, creatures and characters are appended by the curation
 * passes (see git history for the session that filled each). They use the
 * 'composite', 'model' and 'rigged' transforms.
 */
const buildings = [];
const stations = [];
const creatures = [];
const characters = [];

export const JOBS = [...props, ...textures, ...buildings, ...stations, ...creatures, ...characters];
