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
  // Ground cover. This is the whole triangle budget: it renders by the
  // thousand through thin instances, so the SOURCE choice matters more than
  // any simplifier pass. The kit's leaf-tuft and flat-plant models carry the
  // same silhouette at 40m as the detailed tufts for a sixth of the
  // triangles, which is what buys the draw distance that makes a meadow read
  // as a meadow instead of a golf course (D51).
  { file: `${NK}/grass_leafs.glb`, out: 'grass_a' },
  { file: `${NK}/plant_flatTall.glb`, out: 'grass_b' },
  { file: `${NK}/plant_flatShort.glb`, out: 'reed_a' },
  { file: `${NK}/flower_purpleA.glb`, out: 'flower_a', simplify: 0.45 },
  { file: `${NK}/flower_redA.glb`, out: 'flower_b', simplify: 0.45 },
  { file: `${NK}/flower_yellowA.glb`, out: 'flower_c', simplify: 0.45 },
  // Landmark and dressing pieces (consumed from Phase 4 on).
  { file: `${NK}/stone_tallA.glb`, out: 'stone_tall_a' },
  { file: `${NK}/stone_tallB.glb`, out: 'stone_tall_b' },
  { file: `${NK}/stone_tallG.glb`, out: 'stone_tall_c' },
  { file: `${NK}/log_large.glb`, out: 'log' },
  { file: `${NK}/stump_round.glb`, out: 'stump' }
].map(({ file, out, simplify }) => ({
  group: 'props',
  transform: 'prop',
  simplify: simplify ?? null,
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
 * Rigged models from poly.pizza (fetched by the PIZZA list in
 * fetch-assets.mjs). Slimmed, textures crunched, animations kept. Creatures
 * are small; the shared-rig humanoids carry more texture and clip data, so
 * they get their own budget ceiling.
 *
 * All fifteen species come from the poly.pizza originals again. Six were
 * recast to Kenney Cube Pets under D56's "explodes even loaded raw" verdict,
 * but that probe (tools/_oracle.mjs) read pipeline output from public/, not
 * the raw files, and the pipeline it tested predates slim() sparing skinned
 * models their geometry passes. Re-tested through the current pipeline and
 * the owner rejected the blocky look, so the originals are back; see the
 * decision record superseding D56.
 */
const SPECIES = [
  'bramblit', 'cindercub', 'dewdrake', 'tuftmoth', 'pebblit',
  'sparrowick', 'grazehorn', 'rillnewt', 'emberhop', 'thistleback',
  'cragpup', 'voltvole', 'mirefin', 'ashmane', 'loamking'
];
const creatures = SPECIES.map((id) => ({
  group: 'creatures',
  transform: 'rigged',
  textureSize: 256,
  budgetKB: 1000,
  sources: [{ file: `pizza/creatures/${id}.glb` }],
  out: `models/creatures/${id}.glb`,
  provenance: { source: 'https://poly.pizza/u/Quaternius', author: 'Quaternius', license: 'CC0 1.0' }
}));

const ROLES = ['player', 'villager_m', 'villager_f', 'tether', 'warden'];
const characters = ROLES.map((id) => ({
  group: 'characters',
  transform: 'rigged',
  textureSize: 256,
  budgetKB: 1900,
  sources: [{ file: `pizza/characters/${id}.glb` }],
  out: `models/characters/${id}.glb`,
  provenance: { source: 'https://poly.pizza/u/Quaternius', author: 'Quaternius', license: 'CC0 1.0' }
}));

// Buildings: Kenney Fantasy Town Kit compositions. One tile = 1 unit, walls
// are 0.1-thick plates on the +x edge of their tile, one storey = 1 unit.
// rotY (radians): 0 puts the plate on the tile's +x edge, 1.5708 on -z,
// 3.1416 on -x, 4.7124 on +z. roof/roof-high are shed slopes rising toward
// +x at rotY 0 (rise 0.63 / 1.14); roof-corner rises toward (+x,-z) at rotY
// 0, so the corner rotY per building corner is: (minX,maxZ)=0,
// (minX,minZ)=4.7124, (maxX,minZ)=3.1416, (maxX,maxZ)=1.5708.
const FT = 'fantasy-town-kit/Models/GLB format';
const SK = 'survival-kit/Models/GLB format';
const FK = 'furniture-kit/Models/GLTF format';

const R90 = 1.5708;
const R180 = 3.1416;
const R270 = 4.7124;

const piece = (name, x, y, z, rotY = 0) => ({ file: `${FT}/${name}.glb`, pos: [x, y, z], rotY });

/** The four hip corners of a square roof ring at height y, spanning ±e. */
const roofRing4 = (name, e, y) => [
  piece(name, -e, y, e, 0),
  piece(name, -e, y, -e, R270),
  piece(name, e, y, -e, R180),
  piece(name, e, y, e, R90)
];

// houseA: 2x2 one-storey cottage, pyramid hip of four roof corners.
// The front tile uses wall-doorway-square rather than wall-door: wall-door is
// a solid panel with a door carved in relief and no opening, so nothing was
// walkable there. wall-doorway-square cuts a real 0.4x0.75-tile hole (Door.ts
// on the runtime side hangs a procedural leaf in it via models.json).
const houseA = [
  piece('wall-doorway-square', -0.5, 0, -0.5, R90),
  piece('wall-window-shutters', 0.5, 0, -0.5, R90),
  piece('wall', -0.5, 0, 0.5, R270),
  piece('wall', 0.5, 0, 0.5, R270),
  piece('wall-window-small', 0.5, 0, -0.5, 0),
  piece('wall', 0.5, 0, 0.5, 0),
  piece('wall', -0.5, 0, -0.5, R180),
  piece('wall', -0.5, 0, 0.5, R180),
  ...roofRing4('roof-corner', 0.5, 1)
];

// houseB: 3x3, hip roof with a pyramid cap over the centre tile.
const houseB = [
  piece('wall-doorway-square', 0, 0, -1, R90),
  piece('wall-window-shutters', -1, 0, -1, R90),
  piece('wall-window-shutters', 1, 0, -1, R90),
  piece('wall', -1, 0, 1, R270),
  piece('wall-detail-cross', 0, 0, 1, R270),
  piece('wall', 1, 0, 1, R270),
  piece('wall', 1, 0, -1, 0),
  piece('wall-window-small', 1, 0, 0, 0),
  piece('wall', 1, 0, 1, 0),
  piece('wall', -1, 0, -1, R180),
  piece('wall-window-small', -1, 0, 0, R180),
  piece('wall', -1, 0, 1, R180),
  ...roofRing4('roof-corner', 1, 1),
  piece('roof', 0, 1, -1, R270),
  piece('roof', 0, 1, 1, R90),
  piece('roof', -1, 1, 0, 0),
  piece('roof', 1, 1, 0, R180),
  piece('roof-point', 0, 1.55, 0)
];

// houseC: 4x4 two-storey. Stone ground floor, timbered upper, two-level hip.
const ringC = (names, y) => {
  // names: [minX-front..maxX-front] per side in reading order.
  const at = [-1.5, -0.5, 0.5, 1.5];
  return [
    ...names.front.map((n, i) => piece(n, at[i], y, -1.5, R90)),
    ...names.back.map((n, i) => piece(n, at[i], y, 1.5, R270)),
    ...names.east.map((n, i) => piece(n, 1.5, y, at[i], 0)),
    ...names.west.map((n, i) => piece(n, -1.5, y, at[i], R180))
  ];
};
const houseC = [
  ...ringC(
    {
      front: ['wall', 'wall-doorway-square', 'wall-window-stone', 'wall'],
      back: ['wall', 'wall', 'wall-window-stone', 'wall'],
      east: ['wall', 'wall-window-stone', 'wall', 'wall'],
      west: ['wall', 'wall-window-stone', 'wall', 'wall']
    },
    0
  ),
  ...ringC(
    {
      front: ['wall-wood-window-shutters', 'wall-wood-detail-cross', 'wall-wood-window-shutters', 'wall-wood'],
      back: ['wall-wood', 'wall-wood-detail-cross', 'wall-wood-window-shutters', 'wall-wood'],
      east: ['wall-wood', 'wall-wood-window-shutters', 'wall-wood', 'wall-wood'],
      west: ['wall-wood', 'wall-wood-window-shutters', 'wall-wood', 'wall-wood']
    },
    1
  ),
  ...roofRing4('roof-corner', 1.5, 2),
  piece('roof', -0.5, 2, -1.5, R270),
  piece('roof', 0.5, 2, -1.5, R270),
  piece('roof', -0.5, 2, 1.5, R90),
  piece('roof', 0.5, 2, 1.5, R90),
  piece('roof', -1.5, 2, -0.5, 0),
  piece('roof', -1.5, 2, 0.5, 0),
  piece('roof', 1.5, 2, -0.5, R180),
  piece('roof', 1.5, 2, 0.5, R180),
  ...roofRing4('roof-corner', 0.5, 2.5)
];

// The Meadows Hall: 7x11 tiles, two storeys, scale 4 = 28x44m at 8m walls,
// which matches landmarks.json's 26x44 footprint to within the collider
// tolerance. Stone below, timber above. The front row (-z) omits its centre
// tile at level 0 so the door gap stays where Hall.ts anchors and colliders
// say it is, with wall-arch-top above as the lintel.
const hallWallRow = (side, y, mk) => {
  // side: 'front'|'back'|'east'|'west'; mk(index) -> piece name or null.
  const out = [];
  if (side === 'front' || side === 'back') {
    for (let x = -3; x <= 3; x++) {
      const name = mk(x);
      if (name) out.push(piece(name, x, y, side === 'front' ? -5 : 5, side === 'front' ? R90 : R270));
    }
  } else {
    for (let z = -5; z <= 5; z++) {
      const name = mk(z);
      if (name) out.push(piece(name, side === 'east' ? 3 : -3, y, z, side === 'east' ? 0 : R180));
    }
  }
  return out;
};
/** One inset rectangular eave ring of the roof-high family at height y. */
const hallRoofRing = (ex, ez, y) => [
  piece('roof-high-corner', -ex, y, ez, 0),
  piece('roof-high-corner', -ex, y, -ez, R270),
  piece('roof-high-corner', ex, y, -ez, R180),
  piece('roof-high-corner', ex, y, ez, R90),
  ...Array.from({ length: ez * 2 - 1 }, (_, i) => piece('roof-high', -ex, y, i - ez + 1, 0)),
  ...Array.from({ length: ez * 2 - 1 }, (_, i) => piece('roof-high', ex, y, i - ez + 1, R180)),
  ...Array.from({ length: ex * 2 - 1 }, (_, i) => piece('roof-high', i - ex + 1, y, -ez, R270)),
  ...Array.from({ length: ex * 2 - 1 }, (_, i) => piece('roof-high', i - ex + 1, y, ez, R90))
];
const hall = [
  // Ground floor, stone.
  ...hallWallRow('front', 0, (x) =>
    x === 0 ? null : Math.abs(x) === 2 ? 'wall-window-stone' : 'wall'
  ),
  ...hallWallRow('back', 0, (x) =>
    x === 0 ? 'wall-detail-cross' : Math.abs(x) === 2 ? 'wall-window-stone' : 'wall'
  ),
  ...hallWallRow('east', 0, (z) => (Math.abs(z) === 3 || z === 0 ? 'wall-window-stone' : 'wall')),
  ...hallWallRow('west', 0, (z) => (Math.abs(z) === 3 || z === 0 ? 'wall-window-stone' : 'wall')),
  // Upper storey, timber, arch lintel over the door gap.
  ...hallWallRow('front', 1, (x) =>
    x === 0 ? 'wall-arch-top' : Math.abs(x) === 2 ? 'wall-wood-window-shutters' : 'wall-wood'
  ),
  ...hallWallRow('back', 1, (x) =>
    x === 0 ? 'wall-wood-detail-cross' : Math.abs(x) === 2 ? 'wall-wood-window-shutters' : 'wall-wood'
  ),
  ...hallWallRow('east', 1, (z) =>
    Math.abs(z) === 3 || z === 0 ? 'wall-wood-window-shutters' : 'wall-wood'
  ),
  ...hallWallRow('west', 1, (z) =>
    Math.abs(z) === 3 || z === 0 ? 'wall-wood-window-shutters' : 'wall-wood'
  ),
  // Three stepped eave rings, then gable caps along the ridge.
  ...hallRoofRing(3, 5, 2),
  ...hallRoofRing(2, 4, 3),
  ...hallRoofRing(1, 3, 4),
  ...Array.from({ length: 7 }, (_, i) => piece('roof-high-gable-top', 0, 5, i - 3, R90))
];

const KENNEY = (kit) => ({ source: `https://kenney.nl/assets/${kit}`, author: 'Kenney', license: 'CC0' });
const QUATERNIUS = { source: 'https://poly.pizza/u/Quaternius', author: 'Quaternius', license: 'CC0 1.0' };
const PZ = 'pizza/village';

// Composites ship quantized: float32 attributes alone put the 150-piece hall
// over the 420 KB gate, and quantization is exact at kit precision. The
// dequantization scale lives on the GLB's node, so the runtime loader must
// keep the node transform when instancing (StructureModels.ts does).
const buildings = [
  { sources: houseA, out: 'house_a', scale: 3.0 },
  { sources: houseB, out: 'house_b', scale: 2.6 },
  { sources: houseC, out: 'house_c', scale: 2.2 },
  { sources: hall, out: 'hall', scale: 4.0 }
].map(({ sources, out, scale }) => ({
  group: 'buildings',
  transform: 'composite',
  scale,
  quantize: true,
  sources,
  out: `models/buildings/${out}.glb`,
  provenance: KENNEY('fantasy-town-kit')
})).concat(
  // Whole prebuilt village buildings, Quaternius Medieval Village Pack. Every
  // village house used to be Fantasy Town Kit wall/roof tiles stacked by
  // roofRing4 above, and the roof alone ran 36-51% of total building height
  // (the Hall's own hip rings excepted, this file's houseA/B/C). These are
  // single already-composed GLBs, so the 'prop' transform (bake to vertex
  // colours, merge to one mesh, seat at y=0) is the right path: same
  // contract PropModels.ts already uses, no composite positioning needed.
  // Scale targets a plausible real-world cottage/landmark height per model
  // (measured from the raw GLB, docs/decisions/D62); the player's own home
  // stays the Kenney house_a composite above because only it has a doorway
  // aperture and the furnishHome() numbers below are tuned to its footprint.
  [
    { file: `${PZ}/house_b.glb`, out: 'village_house_b', scale: 1.35 },
    { file: `${PZ}/house_c.glb`, out: 'village_house_c', scale: 1.5 },
    { file: `${PZ}/inn.glb`, out: 'village_inn', scale: 1.6 },
    { file: `${PZ}/blacksmith.glb`, out: 'village_blacksmith', scale: 1.45 }
  ].map(({ file, out, scale }) => ({
    group: 'buildings',
    transform: 'prop',
    scale,
    // Measured (docs/decisions/D62): these raw models run 5.7k-7.8k tris
    // apiece against 0.8k-2.8k for the Kenney composites they sit beside on
    // the same ring, and every one of them is also a shadow caster, so four
    // of them nearly quadrupled the village's shadow-pass vertex count and
    // took the square from ~4ms to ~13-15ms a frame under SwiftShader.
    // Simplified before the merge, same lever ground cover already uses,
    // because a building is read as a silhouette across a village square,
    // not inspected close up the way its texture-mapped source was designed
    // to be.
    simplify: 0.4,
    // Whole prebuilt buildings carry far more geometry than a Kenney kit
    // tile even simplified, so float32 attributes put every one of these
    // over the 420 KB gate the same way the Hall composite did. Same fix:
    // quantize (D47's 16-bit positions/8-bit colours are exact well past
    // kit precision at building scale, tested at ~0.1mm).
    quantize: true,
    sources: [{ file }],
    out: `models/buildings/${out}.glb`,
    provenance: QUATERNIUS
  }))
).concat(
  // Single-piece village dressing and the Hall banner. The 'prop' transform
  // recentres XZ and seats y=0, so placement code needs no per-model fixups.
  // well/cart/fence keep their Fantasy Town Kit output names but now come
  // from the Quaternius pack, dressing the square in the same family as the
  // buildings above; 'stall' is retired in favour of the two market stands.
  [
    { file: `${FT}/banner-red.glb`, out: 'banner', scale: 4.0, provenance: KENNEY('fantasy-town-kit') },
    { file: `${PZ}/well.glb`, out: 'well', scale: 1.4, provenance: QUATERNIUS },
    { file: `${PZ}/cart.glb`, out: 'cart', scale: 1.4, provenance: QUATERNIUS },
    { file: `${PZ}/fence.glb`, out: 'fence', scale: 3.3, provenance: QUATERNIUS },
    { file: `${PZ}/bonfire.glb`, out: 'bonfire', scale: 2.6, provenance: QUATERNIUS },
    { file: `${PZ}/market_stand.glb`, out: 'market_stand', scale: 2.1, provenance: QUATERNIUS },
    { file: `${PZ}/market_stand_2.glb`, out: 'market_stand_2', scale: 2.1, provenance: QUATERNIUS },
    { file: `${PZ}/bench.glb`, out: 'bench', scale: 1.55, provenance: QUATERNIUS },
    { file: `${PZ}/bench_2.glb`, out: 'bench_2', scale: 2.4, provenance: QUATERNIUS },
    { file: `${PZ}/barrel.glb`, out: 'barrel', scale: 3.75, provenance: QUATERNIUS },
    { file: `${PZ}/crate.glb`, out: 'crate', scale: 3.1, provenance: QUATERNIUS },
    { file: `${FT}/lantern.glb`, out: 'lantern', scale: 2.0, provenance: KENNEY('fantasy-town-kit') }
  ].map(({ file, out, scale, provenance }) => ({
    group: 'buildings',
    transform: 'prop',
    scale,
    sources: [{ file }],
    out: `models/buildings/${out}.glb`,
    provenance
  }))
);

// The player's home furniture: furniture-kit pieces to replace the
// unsupported floating lamp and give the one furnished house a lived-in
// read. Scale follows the same bedSingle convention already shipped
// (models/stations/bed.glb): the kit's raw units come out close to real
// metres once multiplied, measured per model below.
const furniture = [
  { file: `${FK}/sideTable.glb`, out: 'side_table', scale: 1.3 },
  { file: `${FK}/chair.glb`, out: 'chair', scale: 1.6 },
  { file: `${FK}/bookcaseOpen.glb`, out: 'bookcase', scale: 1.5 },
  { file: `${FK}/rugRound.glb`, out: 'rug', scale: 1.6 },
  { file: `${FK}/lampRoundTable.glb`, out: 'lamp', scale: 1.35 }
].map(({ file, out, scale }) => ({
  group: 'furniture',
  transform: 'prop',
  scale,
  sources: [{ file }],
  out: `models/furniture/${out}.glb`,
  provenance: KENNEY('furniture-kit')
}));

// Stations: scale baked so the shipped mesh is world-sized; models.json keeps
// a runtime scale knob at 1 for retuning without a pipeline re-run.
const stations = [
  { file: `${SK}/campfire-pit.glb`, out: 'campfire', scale: 4.0, kit: 'survival-kit' },
  { file: `${SK}/workbench.glb`, out: 'workbench', scale: 4.2, kit: 'survival-kit' },
  { file: `${FK}/bedSingle.glb`, out: 'bed', scale: 1.75, kit: 'furniture-kit' },
  { file: `${SK}/fence-fortified.glb`, out: 'tanning_rack', scale: 3.0, kit: 'survival-kit' },
  { file: `${SK}/workbench-anvil.glb`, out: 'orb_bench', scale: 4.0, kit: 'survival-kit' }
].map(({ file, out, scale, kit }) => ({
  group: 'stations',
  transform: 'prop',
  scale,
  sources: [{ file }],
  out: `models/stations/${out}.glb`,
  provenance: KENNEY(kit)
}));

export const JOBS = [
  ...props,
  ...textures,
  ...buildings,
  ...stations,
  ...furniture,
  ...creatures,
  ...characters
];
