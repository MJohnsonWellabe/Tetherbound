// Shared GLB machinery for the asset pipeline.
//
// Everything here operates OFFLINE, at build time, so the runtime contract
// stays trivial: the game loads finished GLBs and asks no questions. The
// interesting work is `bakeToVertexColors` and `mergeSeated`, which together
// turn any pile of Kenney kit pieces into the exact shape the game's prop
// batcher expects: one mesh, one material, vertex-coloured, base at y=0.
import { NodeIO } from '@gltf-transform/core';
import { KHRONOS_EXTENSIONS } from '@gltf-transform/extensions';
import {
  dedup,
  draco,
  flatten,
  joinPrimitives,
  prune,
  quantize,
  resample,
  simplify,
  textureCompress,
  transformMesh,
  weld
} from '@gltf-transform/functions';
import { MeshoptSimplifier } from 'meshoptimizer';
import { fromTranslation, fromScaling, multiply } from 'gl-matrix/esm/mat4.js';
import sharp from 'sharp';

let io = null;

/** One IO for the whole run. Draco/meshopt codecs are attached lazily. */
export async function getIO() {
  if (io) return io;
  io = new NodeIO().registerExtensions(KHRONOS_EXTENSIONS);
  const draco3d = await import('draco3dgltf');
  io.registerDependencies({
    'draco3d.decoder': await draco3d.createDecoderModule(),
    'draco3d.encoder': await draco3d.createEncoderModule()
  });
  return io;
}

/**
 * Bake a document's textures into per-vertex colours, then strip the
 * textures and UVs.
 *
 * Kenney palette textures are flat colour swatches addressed by UV island, so
 * point-sampling at each vertex UV reproduces the model's colours exactly.
 * The output matches the game's prop contract (white material + COLOR_0), it
 * keeps the existing per-instance tint multiplying correctly, and props cost
 * zero texture memory at runtime. Recorded as D43.
 */
export async function bakeToVertexColors(document) {
  const root = document.getRoot();

  // Decode every texture once up front.
  const decoded = new Map();
  for (const texture of root.listTextures()) {
    const image = texture.getImage();
    if (!image) continue;
    const { data, info } = await sharp(Buffer.from(image))
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });
    decoded.set(texture, { data, width: info.width, height: info.height });
  }

  for (const mesh of root.listMeshes()) {
    for (const prim of mesh.listPrimitives()) {
      const position = prim.getAttribute('POSITION');
      if (!position) continue;
      const count = position.getCount();
      const uv = prim.getAttribute('TEXCOORD_0');
      const material = prim.getMaterial();
      const baseTexture = material?.getBaseColorTexture();
      const baseColor = material?.getBaseColorFactor() ?? [1, 1, 1, 1];
      const image = baseTexture ? decoded.get(baseTexture) : null;

      const colors = new Float32Array(count * 4);
      for (let i = 0; i < count; i++) {
        let r = baseColor[0];
        let g = baseColor[1];
        let b = baseColor[2];
        if (image && uv) {
          const u = uv.getElement(i, [])[0];
          const v = uv.getElement(i, [])[1];
          // Wrap, then point-sample. Kenney palettes are flat per island, so
          // filtering would only bleed neighbouring swatches into each other.
          const x = Math.min(image.width - 1, Math.max(0, Math.floor(((u % 1) + 1) % 1 * image.width)));
          const y = Math.min(image.height - 1, Math.max(0, Math.floor(((v % 1) + 1) % 1 * image.height)));
          const at = (y * image.width + x) * 4;
          r = (image.data[at] / 255) * baseColor[0];
          g = (image.data[at + 1] / 255) * baseColor[1];
          b = (image.data[at + 2] / 255) * baseColor[2];
        }
        colors[i * 4] = r;
        colors[i * 4 + 1] = g;
        colors[i * 4 + 2] = b;
        colors[i * 4 + 3] = 1;
      }

      const buffer = root.listBuffers()[0] ?? document.createBuffer();
      const accessor = document
        .createAccessor()
        .setType('VEC4')
        .setArray(colors)
        .setBuffer(buffer);
      prim.setAttribute('COLOR_0', accessor);
      if (uv) prim.setAttribute('TEXCOORD_0', null);
      prim.setMaterial(null);
    }
  }

  // Prune drops the now-orphaned materials, textures and UV accessors.
  await document.transform(prune());
  return document;
}

/**
 * Collapse a document to ONE primitive under one node, recentred on XZ with
 * its base at y=0, optionally pre-scaled.
 *
 * Base-at-origin is what lets the prop batcher place instances from terrain
 * height alone, and matches the `seat()` semantics of the primitive
 * prototypes. Scale is baked so the runtime never compensates.
 */
export async function mergeSeated(document, { scale = 1, simplifyRatio = null } = {}) {
  await document.transform(flatten(), dedup());
  // Ground cover renders by the thousand through thin instances, so a 200-tri
  // grass tuft is a triangle budget problem, not a detail win. Simplify BEFORE
  // the merge so the weld cannot fuse what the simplifier needs separate.
  if (simplifyRatio) {
    await document.transform(weld(), simplify({ simplifier: MeshoptSimplifier, ratio: simplifyRatio, error: 0.01 }));
  }

  const root = document.getRoot();
  const scene = root.getDefaultScene() ?? root.listScenes()[0];

  // Join every primitive into one. joinPrimitives needs compatible vertex
  // layouts, which bakeToVertexColors guarantees (POSITION/NORMAL/COLOR_0).
  const prims = [];
  for (const mesh of root.listMeshes()) for (const p of mesh.listPrimitives()) prims.push(p);
  if (prims.length === 0) throw new Error('no primitives to merge');

  let joined;
  if (prims.length === 1) {
    joined = prims[0];
  } else {
    joined = joinPrimitives(prims);
    for (const mesh of root.listMeshes()) mesh.dispose();
  }

  const mesh = document.createMesh('merged').addPrimitive(joined);
  for (const node of [...scene.listChildren()]) node.dispose();
  const node = document.createNode('merged').setMesh(mesh);
  scene.addChild(node);

  // Measure, then bake recentre+seat+scale into the vertices.
  const position = joined.getAttribute('POSITION');
  const el = [];
  let minX = Infinity, minY = Infinity, minZ = Infinity;
  let maxX = -Infinity, maxZ = -Infinity;
  for (let i = 0; i < position.getCount(); i++) {
    position.getElement(i, el);
    if (el[0] < minX) minX = el[0];
    if (el[0] > maxX) maxX = el[0];
    if (el[1] < minY) minY = el[1];
    if (el[2] < minZ) minZ = el[2];
    if (el[2] > maxZ) maxZ = el[2];
  }
  const cx = (minX + maxX) / 2;
  const cz = (minZ + maxZ) / 2;

  const matrix = multiply(
    [],
    fromScaling([], [scale, scale, scale]),
    fromTranslation([], [-cx, -minY, -cz])
  );
  transformMesh(mesh, matrix);

  await document.transform(weld(), prune());
  return document;
}

/** Standard slimming pass for models that keep their textures/rigs. */
export async function slim(document, { textureSize = 512, keepAnimations = true, keepClips = null } = {}) {
  // The source packs ship every animation twice (bare and armature-prefixed
  // names) and carry clips the game never plays. Dropping everything outside
  // the verb map halves most rigged files.
  if (keepClips) {
    const keep = new Set(keepClips);
    for (const anim of document.getRoot().listAnimations()) {
      if (!keep.has(anim.getName())) anim.dispose();
    }
  }
  const transforms = [dedup(), prune(), weld()];
  if (keepAnimations) transforms.push(resample());
  // 16-bit attributes via KHR_mesh_quantization, which the runtime loader
  // registers. Roughly halves rigged geometry.
  transforms.push(quantize());
  transforms.push(
    textureCompress({ encoder: sharp, targetFormat: 'webp', resize: [textureSize, textureSize] })
  );
  await document.transform(...transforms);
  return document;
}

/** Draco-compress. Only for un-rigged geometry (draco skips skinned prims). */
export async function compress(document) {
  await document.transform(draco());
  return document;
}

/** Quick stats for budgets and the manifest. */
export function stats(document) {
  const root = document.getRoot();
  let tris = 0;
  for (const mesh of root.listMeshes()) {
    for (const prim of mesh.listPrimitives()) {
      const indices = prim.getIndices();
      const position = prim.getAttribute('POSITION');
      tris += Math.floor((indices ? indices.getCount() : position?.getCount() ?? 0) / 3);
    }
  }
  return {
    tris,
    meshes: root.listMeshes().length,
    materials: root.listMaterials().length,
    textures: root.listTextures().length,
    animations: root.listAnimations().map((a) => a.getName()),
    skins: root.listSkins().length
  };
}
