// Turn assets_raw/ into public/models/ + ASSET_MANIFEST.md.
//
//   npm run assets            everything stale
//   npm run assets -- --force everything
//   npm run assets -- props   one group
//
// Driven entirely by scripts/asset-jobs.mjs. Each job says which raw files go
// in, which transform shapes them, and what lands in public/. This file knows
// HOW to transform; the jobs know WHAT. Adding an asset is a jobs entry, not
// a code change.
//
// Transforms:
//   prop       bake textures/materials to vertex colours, merge to one mesh,
//              seat base at y=0. Output matches the PropBatcher contract.
//   composite  same, but positions multiple source files first (buildings).
//   rigged     keep rig + animations + textures; dedup/resample/prune and
//              recompress textures to webp <=512. For creatures/characters.
//   model      static but keeps its textures (stations, dressing).
//   texture    plain image: resize + webp for terrain detail maps.
//   copy       verbatim.
//
// Budget: every model output must be under BUDGET_KB. Over budget fails the
// run, because a fat model on a phone connection is a bug, not a shame.
import { existsSync, mkdirSync, readFileSync, statSync, writeFileSync, copyFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';
import { JOBS } from './asset-jobs.mjs';
import modelsData from '../src/data/models.json' with { type: 'json' };

/** Clip names the game actually plays for a given output, from models.json. */
function clipsFor(outPath) {
  for (const section of [modelsData.pals, modelsData.characters]) {
    for (const entry of Object.values(section ?? {})) {
      if (entry.url === outPath) {
        return Object.values(entry.clips ?? {}).filter(Boolean);
      }
    }
  }
  return null;
}
import {
  bakeToVertexColors,
  getIO,
  mergeSeated,
  normalizeArmatureScale,
  slim,
  stats
} from './lib/glbtool.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const RAW = join(ROOT, 'assets_raw');
const PUB = join(ROOT, 'public');
/**
 * Editing a job, or the code that executes a job, must invalidate what that
 * job produced. Watching only the job list was the same mistake one level up:
 * a change to the transform library reported every asset `fresh`.
 */
const RECIPE_PATHS = [
  join(ROOT, 'scripts', 'asset-jobs.mjs'),
  join(ROOT, 'scripts', 'lib', 'glbtool.mjs'),
  join(ROOT, 'scripts', 'optimize-assets.mjs')
];
const RECIPE_MTIME = Math.max(...RECIPE_PATHS.map((p) => statSync(p).mtimeMs));
const BUDGET_KB = 420;

const args = process.argv.slice(2);
const force = args.includes('--force');
const only = args.find((a) => !a.startsWith('--')) ?? null;

/** A composite positions several sources before the merge. */
async function readComposite(io, sources) {
  const { Document } = await import('@gltf-transform/core');
  const { mergeDocuments, unpartition } = await import('@gltf-transform/functions');
  const { fromRotationTranslationScale } = await import('gl-matrix/esm/mat4.js');
  const { fromEuler } = await import('gl-matrix/esm/quat.js');

  const target = new Document();
  target.createBuffer();
  const scene = target.createScene('composite');
  target.getRoot().setDefaultScene(scene);

  for (const part of sources) {
    const doc = await io.read(join(RAW, part.file));
    const map = mergeDocuments(target, doc);
    for (const s of doc.getRoot().listScenes()) {
      const merged = map.get(s);
      if (!merged) continue;
      const holder = target
        .createNode('part')
        .setTranslation(part.pos ?? [0, 0, 0])
        .setRotation(fromEuler([], 0, ((part.rotY ?? 0) * 180) / Math.PI, 0))
        .setScale([part.scale ?? 1, part.scale ?? 1, part.scale ?? 1]);
      for (const child of [...merged.listChildren()]) holder.addChild(child);
      scene.addChild(holder);
      merged.dispose();
    }
  }
  // mergeDocuments imports one buffer per source document; GLB allows one.
  await target.transform(unpartition());
  return target;
}

async function runJob(io, job) {
  const out = join(PUB, job.out);
  mkdirSync(dirname(out), { recursive: true });

  if (job.transform === 'texture') {
    await sharp(join(RAW, job.sources[0].file))
      .resize(job.size ?? 512, job.size ?? 512, { fit: 'cover' })
      .modulate({ saturation: job.desaturate ? 0.35 : 1 })
      .webp({ quality: 82 })
      .toFile(out);
    return { note: 'texture' };
  }
  if (job.transform === 'copy') {
    copyFileSync(join(RAW, job.sources[0].file), out);
    return { note: 'copy' };
  }

  const doc =
    job.transform === 'composite'
      ? await readComposite(io, job.sources)
      : await io.read(join(RAW, job.sources[0].file));

  // No draco/meshopt anywhere: the runtime loader facade registers a minimal
  // extension set on purpose (see src/core/babylonLoaders.ts), and a decoder
  // wasm would cost more than these files weigh. Props are a few KB plain.
  if (job.transform === 'prop' || job.transform === 'composite') {
    await bakeToVertexColors(doc);
    await mergeSeated(doc, {
      scale: job.scale ?? 1,
      simplifyRatio: job.simplify ?? null,
      quantizeOut: job.quantize ?? false
    });
  } else if (job.transform === 'rigged') {
    // Babylon double-applies a scaled armature's scale to secondary root
    // joints (the Animated Animals IK bones), so the FBX 100x convention is
    // baked out before anything else sees the file.
    normalizeArmatureScale(doc);
    await slim(doc, {
      textureSize: job.textureSize ?? 512,
      keepAnimations: true,
      keepClips: clipsFor(job.out)
    });
  } else if (job.transform === 'model') {
    await slim(doc, { textureSize: job.textureSize ?? 512, keepAnimations: false });
  } else {
    throw new Error(`unknown transform "${job.transform}"`);
  }

  await io.write(out, doc);
  return { note: JSON.stringify(stats(doc)) };
}

/** Provenance rows. License is recorded as found; the CC0 gate is waived (D42). */
function manifestRow(job, sizeKB) {
  const src = job.provenance ?? {};
  return `| public/${job.out} | ${src.source ?? 'assets_raw/' + job.sources[0].file} | ${src.author ?? 'Kenney'} | ${src.license ?? 'CC0'} | ${new Date().toISOString().slice(0, 10)} | ${job.transform} (${sizeKB} KB) |`;
}

const io = await getIO();
const rows = [];
let failed = 0;
let ran = 0;

for (const job of JOBS) {
  if (only && job.group !== only) continue;
  const out = join(PUB, job.out);
  // "The output exists" is not freshness: retargeting a job at a different
  // source model, or changing its simplify ratio, left the old file in place
  // and the change silently did nothing. Rebuild whenever the output is older
  // than any of its sources or than the job list that describes it.
  const fresh =
    existsSync(out) &&
    !force &&
    statSync(out).mtimeMs >= RECIPE_MTIME &&
    (job.sources ?? []).every((s) => {
      const src = join(RAW, s.file);
      return !existsSync(src) || statSync(out).mtimeMs >= statSync(src).mtimeMs;
    });
  try {
    if (!fresh) {
      await runJob(io, job);
      ran++;
    }
    const sizeKB = Math.round(statSync(out).size / 1024);
    const budget = job.budgetKB ?? BUDGET_KB;
    if (job.out.endsWith('.glb') && sizeKB > budget) {
      throw new Error(`over budget: ${sizeKB} KB > ${budget} KB`);
    }
    rows.push(manifestRow(job, sizeKB));
    console.log(`  ${fresh ? 'fresh' : 'built'}  ${job.out}`);
  } catch (err) {
    failed++;
    console.error(`  FAIL   ${job.out}: ${err.message ?? err}`);
  }
}

if (!only && failed === 0) {
  const manifest = [
    '# ASSET_MANIFEST',
    '',
    'Provenance for every shipped asset. Generated by `npm run assets`; do not edit by hand.',
    'The CC0-only rule from ASSETS.md is waived by the owner for this non-commercial build (D42);',
    'licenses are recorded as found at the source so attribution stays a lookup, not an excavation.',
    '',
    '| File | Source | Author | License | Date pulled | Modified |',
    '|---|---|---|---|---|---|',
    ...rows
  ].join('\n');
  writeFileSync(join(ROOT, 'ASSET_MANIFEST.md'), manifest + '\n');
}

console.log(`\n${rows.length} assets (${ran} rebuilt), ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
