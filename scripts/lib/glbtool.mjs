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
export async function mergeSeated(
  document,
  { scale = 1, simplifyRatio = null, quantizeOut = false } = {}
) {
  await document.transform(flatten());

  const root = document.getRoot();
  const scene = root.getDefaultScene() ?? root.listScenes()[0];

  // Bake node transforms into the vertex data before dedup or join can see
  // them. joinPrimitives reads raw primitives and silently drops node TRS,
  // which is exactly where a composite keeps its piece placement (and where
  // some kits keep their up-axis conversion). flatten() left the full world
  // transform on each scene-root node, so one transformMesh per node makes
  // the join safe. Identity transforms (every prop shipped before this
  // existed) are a no-op. This runs BEFORE dedup so no two nodes share a
  // mesh yet; the unshare pass covers sources that instanced their own.
  const identity = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
  const seen = new Set();
  for (const node of scene.listChildren()) {
    const mesh = node.getMesh();
    if (!mesh) continue;
    if (seen.has(mesh)) {
      const copy = document.createMesh(mesh.getName());
      for (const p of mesh.listPrimitives()) copy.addPrimitive(p.clone());
      node.setMesh(copy);
    } else {
      seen.add(mesh);
    }
  }
  for (const node of scene.listChildren()) {
    const mesh = node.getMesh();
    if (!mesh) continue;
    const matrix = node.getMatrix();
    if (matrix.every((v, i) => Math.abs(v - identity[i]) < 1e-9)) continue;
    transformMesh(mesh, matrix);
    node.setMatrix([...identity]);
  }

  await document.transform(dedup());
  // Ground cover renders by the thousand through thin instances, so a 200-tri
  // grass tuft is a triangle budget problem, not a detail win. Simplify BEFORE
  // the merge so the weld cannot fuse what the simplifier needs separate.
  if (simplifyRatio) {
    // `error` is the cap, and it is what actually decides how far the
    // simplifier goes: at the old 0.01 (1% of mesh extent) collapsing a
    // multi-blade tuft blew the bound immediately and every ratio silently
    // no-opped, so a "simplified" 224-tri grass model shipped at 224 tris.
    // Ground cover is read at 40m+, where a generous bound costs nothing
    // visible and the ratio is allowed to bite.
    await document.transform(
      weld(),
      simplify({ simplifier: MeshoptSimplifier, ratio: simplifyRatio, error: 0.5 })
    );
  }

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
  // Large composites (the Hall is ~14k vertices) blow the byte budget on
  // float32 attributes alone. 16-bit positions and 8-bit colours are exact
  // at kit precision, 8-bit normals are plenty for flat-shaded facets, and
  // the runtime facade registers KHR_mesh_quantization.
  if (quantizeOut) await document.transform(quantize({ quantizeNormal: 8 }));
  return document;
}

/**
 * Bake an armature node's uniform scale out of a skinned document, preserving
 * the world result exactly.
 *
 * Quaternius exports carry the FBX unit convention: an armature node scaled
 * 100x over centimetre-sized geometry. Babylon renders that correctly only
 * when the skeleton has a single root joint; the Animated Animals rigs park
 * their IK and pole-target bones directly under the armature as extra roots,
 * and every primitive skinned to one of those gets the 100x applied twice --
 * the screen-filling shards D56 blamed on the files themselves. The shape is
 * fixable by conjugation: with the armature scale S moved into the data
 * (descendant translations, IBM translations, translation animation tracks
 * and skinned vertex positions all multiplied by S), every joint world matrix
 * becomes W' = W * S^-1 and the skinning product W' * IBM' * v' reproduces
 * W * IBM * v bit-for-bit, with no scale left for Babylon to misapply.
 */
export function normalizeArmatureScale(document) {
  const root = document.getRoot();
  if (root.listSkins().length === 0) return document;
  const scene = root.getDefaultScene() ?? root.listScenes()[0];

  const joints = new Set();
  for (const skin of root.listSkins()) for (const j of skin.listJoints()) joints.add(j);

  const hasJointBelow = (n) => {
    for (const c of n.listChildren()) if (joints.has(c) || hasJointBelow(c)) return true;
    return false;
  };

  // Armatures: non-joint nodes with a uniform non-1 scale and joints below.
  const armatures = [];
  const findArmatures = (n) => {
    const s = n.getScale();
    const uniform = Math.abs(s[0] - s[1]) < 1e-5 && Math.abs(s[1] - s[2]) < 1e-5;
    if (!joints.has(n) && hasJointBelow(n) && uniform && Math.abs(s[0] - 1) > 1e-5) {
      armatures.push({ node: n, scale: s[0] });
      return; // nested scaled armatures are out of scope; none exist in the packs
    }
    for (const c of n.listChildren()) findArmatures(c);
  };
  for (const n of scene.listChildren()) findArmatures(n);
  if (armatures.length === 0) return document;

  const descendants = (n, out = []) => {
    for (const c of n.listChildren()) {
      out.push(c);
      descendants(c, out);
    }
    return out;
  };

  const scalePositions = (mesh, s) => {
    for (const prim of mesh.listPrimitives()) {
      const pos = prim.getAttribute('POSITION');
      pos.setArray(Float32Array.from(pos.getArray(), (v) => v * s));
    }
  };

  const scaledIbms = new Set();
  const scaledAnims = new Set();
  const scaledMeshes = new Set();
  // Which armature's scale governs a given skin, by joint membership.
  const skinScale = new Map();

  for (const { node: arm, scale: s } of armatures) {
    arm.setScale([1, 1, 1]);
    const below = new Set(descendants(arm));

    for (const skin of root.listSkins()) {
      if (skin.listJoints().some((j) => below.has(j))) skinScale.set(skin, s);
    }

    for (const d of below) {
      const t = d.getTranslation();
      d.setTranslation([t[0] * s, t[1] * s, t[2] * s]);
      // A static mesh hanging off a bone (an accessory) must grow with the
      // rig or it renders at 1/s of its old size.
      const mesh = d.getMesh();
      if (mesh && !d.getSkin() && !scaledMeshes.has(mesh)) {
        scaledMeshes.add(mesh);
        scalePositions(mesh, s);
      }
    }

    for (const anim of root.listAnimations()) {
      for (const channel of anim.listChannels()) {
        if (channel.getTargetPath() !== 'translation') continue;
        if (!below.has(channel.getTargetNode())) continue;
        const output = channel.getSampler()?.getOutput();
        if (!output || scaledAnims.has(output)) continue;
        scaledAnims.add(output);
        output.setArray(Float32Array.from(output.getArray(), (v) => v * s));
      }
    }
  }

  // Conjugate each governed skin: IBM translations and the skinned vertex
  // positions both grow by S, so W' * IBM' * v' lands exactly where
  // W * IBM * v did.
  for (const [skin, s] of skinScale) {
    const acc = skin.getInverseBindMatrices();
    if (acc && !scaledIbms.has(acc)) {
      scaledIbms.add(acc);
      const arr = Float32Array.from(acc.getArray());
      for (let o = 0; o < arr.length; o += 16) {
        arr[o + 12] *= s;
        arr[o + 13] *= s;
        arr[o + 14] *= s;
      }
      acc.setArray(arr);
    }
  }

  // Skinned vertices live in mesh space, which the conjugation grew by S. The
  // skinned mesh node's own transform is ignored by the glTF spec, so zero
  // its scale as well rather than leave a number Babylon might misread.
  const fixSkinnedNodes = (n) => {
    const skin = n.getSkin();
    if (skin && skinScale.has(skin)) {
      const mesh = n.getMesh();
      if (mesh && !scaledMeshes.has(mesh)) {
        scaledMeshes.add(mesh);
        scalePositions(mesh, skinScale.get(skin));
      }
      n.setScale([1, 1, 1]);
    }
    for (const c of n.listChildren()) fixSkinnedNodes(c);
  };
  for (const n of scene.listChildren()) fixSkinnedNodes(n);

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
  // SKINNED MODELS GET NO GEOMETRY PASSES. Measured: dedup/prune/weld/resample
  // rewrite the inverse bind matrices (raw IBM scale 1.0 -> 0.014 after the
  // pipeline), and Babylon renders the result as screen-filling shards for
  // some models - the giant wedges that were blamed on the renderer for
  // several sessions (D56). Clip pruning above plus texture compression here
  // do all the shrinking that is safe; the skin ships exactly as authored.
  const skinned = document.getRoot().listSkins().length > 0;
  const transforms = skinned ? [] : [dedup(), prune(), weld()];
  if (!skinned && keepAnimations) transforms.push(resample());
  if (!skinned) transforms.push(quantize());
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
