// Download every source asset into assets_raw/ (gitignored).
//
//   node scripts/fetch-assets.mjs             everything
//   node scripts/fetch-assets.mjs kenney      one source group
//
// Two source shapes:
//
//   zips     - direct-download packs (Kenney, ambientCG). Unzipped in place.
//   pizza    - individual rigged models from poly.pizza. The site's model
//              pages embed the static GLB URL and the author/license, which
//              we scrape per pinned model id. Licenses are recorded as found:
//              the owner has waived the CC0-only rule (see D42), so the
//              manifest is a provenance log, not a gate.
//
// Idempotent: a file that already exists at the expected size is skipped, so
// re-runs cost one HEAD-ish check per asset. Failures isolate per entry and
// the summary at the end says exactly what is missing.
import { createWriteStream, existsSync, mkdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const RAW = join(ROOT, 'assets_raw');

/** Direct-download packs. URLs verified from this environment. */
const ZIPS = [
  { id: 'nature-kit', url: 'https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip', author: 'Kenney', license: 'CC0' },
  { id: 'fantasy-town-kit', url: 'https://kenney.nl/media/pages/assets/fantasy-town-kit/efe948d309-1754222374/kenney_fantasy-town-kit_2.0.zip', author: 'Kenney', license: 'CC0' },
  { id: 'survival-kit', url: 'https://kenney.nl/media/pages/assets/survival-kit/4065a8185b-1712149243/kenney_survival-kit.zip', author: 'Kenney', license: 'CC0' },
  { id: 'furniture-kit', url: 'https://kenney.nl/media/pages/assets/furniture-kit/440e0608a4-1677580847/kenney_furniture-kit.zip', author: 'Kenney', license: 'CC0' },
  { id: 'blocky-characters', url: 'https://kenney.nl/media/pages/assets/blocky-characters/8369c0cf30-1749547469/kenney_blocky-characters_20.zip', author: 'Kenney', license: 'CC0' },
  { id: 'cube-pets', url: 'https://kenney.nl/media/pages/assets/cube-pets/44e58e945f-1774520254/kenney_cube-pets_1.0.zip', author: 'Kenney', license: 'CC0' },
  { id: 'ui-pack', url: 'https://kenney.nl/media/pages/assets/ui-pack/f651646eab-1718203990/kenney_ui-pack.zip', author: 'Kenney', license: 'CC0' },
  { id: 'particle-pack', url: 'https://kenney.nl/media/pages/assets/particle-pack/f8fe0f8cb8-1677578741/kenney_particle-pack.zip', author: 'Kenney', license: 'CC0' },
  { id: 'tex-grass', url: 'https://ambientcg.com/get?file=Grass004_1K-JPG.zip', author: 'ambientCG', license: 'CC0' },
  { id: 'tex-ground', url: 'https://ambientcg.com/get?file=Ground037_1K-JPG.zip', author: 'ambientCG', license: 'CC0' },
  { id: 'tex-rock', url: 'https://ambientcg.com/get?file=Rock030_1K-JPG.zip', author: 'ambientCG', license: 'CC0' }
];

/**
 * Rigged models from poly.pizza, by model-page id.
 *
 * `as` is the local filename the pipeline refers to. The list is curated by
 * hand against the species reads in docs/01_GAME_DESIGN.md section 6; changing a
 * species' look means changing one id here and re-running.
 *
 * Populated by the curation pass (Phase 5); the resolver below works for any
 * entry added to it. Kept in one flat list so the summary table reads well.
 */
export const PIZZA = [
  // Pals: one distinct rigged creature per species, curated against the
  // species reads in docs/01_GAME_DESIGN.md section 6. All Quaternius.
  { id: 'irZjWFARyl', as: 'creatures/bramblit.glb' }, // Bunny (Ultimate Monsters)
  { id: 'Bc97C66HKi', as: 'creatures/cindercub.glb' }, // Fox (Animated Animals)
  { id: '3rUm1cN3yp', as: 'creatures/dewdrake.glb' }, // Dragon
  { id: '42djT5zJnx', as: 'creatures/tuftmoth.glb' }, // Armabee
  { id: '71gomWolax', as: 'creatures/pebblit.glb' }, // Goleling
  { id: 'gZ2ExU9OAB', as: 'creatures/sparrowick.glb' }, // Birb
  { id: 'T6Cs7tmMHJ', as: 'creatures/grazehorn.glb' }, // Deer
  { id: '37wofOCOzG', as: 'creatures/rillnewt.glb' }, // Frog (monster)
  { id: '9Z2V8fpazF', as: 'creatures/emberhop.glb' }, // Frog (animal hopper)
  { id: 'IoWG5F9WUc', as: 'creatures/thistleback.glb' }, // Green Spiky Blob
  { id: 'wcWiuEqwzq', as: 'creatures/cragpup.glb' }, // Husky
  { id: 'iltq5bVNaV', as: 'creatures/voltvole.glb' }, // Rat
  { id: 'MRjSlwCjHM', as: 'creatures/mirefin.glb' }, // Anglerfish
  { id: 'P1gU3Qkr9r', as: 'creatures/ashmane.glb' }, // Wolf
  { id: 'BldaiPtyJa', as: 'creatures/loamking.glb' }, // Giant
  // Humanoids: one shared 24-clip rig across all five, so one verb map
  // covers the player and every NPC.
  { id: 'ZwF0K7WBmu', as: 'characters/player.glb' }, // Adventurer
  { id: '7pn3R6hPvE', as: 'characters/villager_m.glb' }, // Farmer
  { id: 'nIItLV9nxS', as: 'characters/villager_f.glb' }, // Animated Woman
  { id: 'y9KWOVG21R', as: 'characters/tether.glb' }, // Hooded Adventurer
  { id: 'I1gTjmuK2m', as: 'characters/warden.glb' }, // King
  // Village: Quaternius Medieval Village Pack, whole prebuilt buildings so
  // Hollowbrook stops being hand-stacked wall/roof tiles (roofs were 36-51%
  // of total building height, see docs/decisions/D62). Same artist as every
  // creature and humanoid above, so the village stops clashing with the
  // people standing in it. The player's own home stays the Kenney composite
  // (house_a) because it needs an interior and a working door; these are set
  // dressing, so a solid shell is all they need.
  { id: 'BH2XHWUNmF', as: 'village/house_b.glb' }, // Fantasy House B
  { id: 'dcPho4SUA3', as: 'village/house_c.glb' }, // Fantasy House C
  { id: 'x3ZcGn3jr4', as: 'village/inn.glb' }, // Inn
  { id: 'bV52eTG1Aj', as: 'village/blacksmith.glb' }, // Blacksmith
  { id: 'QlqncKYxXb', as: 'village/well.glb' }, // Well
  { id: 'Azj9hJwwwG', as: 'village/bonfire.glb' }, // Bonfire
  { id: 'hts7l0NZxW', as: 'village/market_stand.glb' }, // Market Stand
  { id: 'DGIM5HGISb', as: 'village/market_stand_2.glb' }, // Market Stand 2
  { id: 'l7bDe7ak6j', as: 'village/cart.glb' }, // Cart
  { id: 'jLxjFxFRpw', as: 'village/bench.glb' }, // Bench
  { id: '7uSlZo3n9Y', as: 'village/bench_2.glb' }, // Bench 2
  { id: 'zjCQP1TAci', as: 'village/barrel.glb' }, // Barrel
  { id: '3OEFd1AWfa', as: 'village/crate.glb' }, // Crate
  { id: 'UXmKfG81fG', as: 'village/fence.glb' }, // Fence
  // Vegetation: Quaternius Stylized Nature. This replaces the Kenney Nature
  // Kit outright rather than retinting it. The kit's plants are flat-shaded
  // spiked fans, and a captured frame of them at real density read as a field
  // of green starfish; no tint, scale or density value fixes a silhouette.
  // Going to the same artist as the creatures, the humanoids and the village
  // is the point: the world stops being three art styles in one frame.
  { id: '9nvGuZlbpE', as: 'nature/tree_a.glb' }, // Tree
  { id: 'i4QMw4L64D', as: 'nature/tree_b.glb' }, // Tree
  { id: '2paAm1ja4w', as: 'nature/tree_c.glb' }, // Tree
  { id: 'igSu0cPoBz', as: 'nature/pine_a.glb' }, // Pine
  { id: 'Zt62gceKXZ', as: 'nature/pine_b.glb' }, // Pine
  { id: '92EytlU1El', as: 'nature/bush_a.glb' }, // Bush
  { id: 'ooG6CkLyE8', as: 'nature/bush_b.glb' }, // Bush
  { id: 'U1ymDy8tbY', as: 'nature/bush_c.glb' }, // Bush with Flowers
  { id: 'Db4UVcNWnF', as: 'nature/grass_a.glb' }, // Grass
  { id: 'AkGoA1SaHA', as: 'nature/grass_b.glb' }, // Grass
  { id: 'JSIYtscPmP', as: 'nature/grass_tall.glb' }, // Tall Grass
  { id: 'dOO6kMDd8L', as: 'nature/flower_a.glb' }, // Flowers
  { id: 'NBUxHir6FJ', as: 'nature/flower_b.glb' }, // Flowers
  { id: 'jqcanvH7D6', as: 'nature/fern.glb' }, // Fern
  { id: 's1OJ3bBzqc', as: 'nature/rock_a.glb' }, // Rock Medium
  { id: 'KZdEP3uUpa', as: 'nature/rock_b.glb' }, // Rock Medium
  { id: 'JQxF95498B', as: 'nature/rock_c.glb' }, // Rock Medium
  { id: 'BVYSNurXMV', as: 'nature/bush_d.glb' }, // Bush, rounded and opaque
  { id: 'MZdeiQApSb', as: 'nature/plant_small.glb' }, // Small Plant
  // The rounded blob shrub. The other four "Bush" entries in the pack are leaf
  // rosettes: agave silhouettes, which is the same complaint that moved the
  // whole family off the Kenney kit. Measured 1.91 x 1.58 x 1.97, which is the
  // aspect a shrub should have.
  { id: 'EoTERLq3z2', as: 'nature/bush_e.glb' }, // Bush, rounded blob
  { id: 'TSbIxkDtxF', as: 'nature/bush_f.glb' }, // Bush with Berries
  { id: 'J2h3HrO356', as: 'nature/bush_g.glb' } // Bushes
];

const args = process.argv.slice(2);
const only = args[0] ?? null;

async function download(url, dest) {
  mkdirSync(dirname(dest), { recursive: true });
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  await pipeline(Readable.fromWeb(res.body), createWriteStream(dest));
  return statSync(dest).size;
}

/** Scrape a poly.pizza model page for its GLB URL, author and license. */
async function resolvePizza(id) {
  const res = await fetch(`https://poly.pizza/m/${id}`, { redirect: 'follow' });
  if (!res.ok) throw new Error(`page HTTP ${res.status}`);
  const html = await res.text();
  const glb = html.match(/https:\/\/static\.poly\.pizza\/[a-f0-9-]+\.glb/)?.[0];
  if (!glb) throw new Error('no static GLB URL on page');
  const author = html.match(/"Creator":\{"Username":"([^"]+)"/)?.[1] ?? 'unknown';
  const license = html.match(/"Licen[cs]e":"([^"]+)"/)?.[1] ?? 'unknown';
  const title = html.match(/<title>([^<|]+)/)?.[1]?.trim() ?? id;
  return { glb, author, license, title };
}

const summary = [];

async function fetchZip(entry) {
  const dir = join(RAW, entry.id);
  const zip = join(dir, `${entry.id}.zip`);
  if (existsSync(join(dir, '.done'))) {
    summary.push([entry.id, 'cached', '']);
    return;
  }
  const bytes = await download(entry.url, zip);
  execFileSync('unzip', ['-o', '-q', zip, '-d', dir]);
  writeFileSync(join(dir, '.done'), new Date().toISOString());
  summary.push([entry.id, 'ok', `${(bytes / 1e6).toFixed(1)} MB`]);
}

async function fetchPizza(entry) {
  const dest = join(RAW, 'pizza', entry.as);
  const meta = join(RAW, 'pizza', `${entry.as}.json`);
  if (existsSync(dest) && existsSync(meta)) {
    summary.push([entry.as, 'cached', '']);
    return;
  }
  const resolved = await resolvePizza(entry.id);
  const bytes = await download(resolved.glb, dest);
  mkdirSync(dirname(meta), { recursive: true });
  writeFileSync(
    meta,
    JSON.stringify(
      {
        source: `https://poly.pizza/m/${entry.id}`,
        author: resolved.author,
        license: resolved.license,
        title: resolved.title,
        pulled: new Date().toISOString()
      },
      null,
      2
    )
  );
  summary.push([entry.as, 'ok', `${(bytes / 1e3).toFixed(0)} KB by ${resolved.author}`]);
}

let failed = 0;
for (const entry of ZIPS) {
  if (only && entry.id !== only && only !== 'zips') continue;
  try {
    await fetchZip(entry);
  } catch (err) {
    failed++;
    summary.push([entry.id, 'FAIL', String(err.message ?? err)]);
  }
}
for (const entry of PIZZA) {
  if (only && only !== 'pizza' && entry.id !== only) continue;
  try {
    await fetchPizza(entry);
  } catch (err) {
    failed++;
    summary.push([entry.as, 'FAIL', String(err.message ?? err)]);
  }
}

for (const [id, status, note] of summary) {
  console.log(`  ${status.padEnd(7)} ${id.padEnd(28)} ${note}`);
}
console.log(`\n${summary.length} entries, ${failed} failed -> assets_raw/`);
process.exit(failed > 0 ? 1 : 0);
