// Loads every rigged model (creatures + characters) into a live scene, exactly
// as the game does via loadContainerOwned, and checks its skinned bounding box
// for the screen-filling-shard failure mode documented in D56: a model whose
// skin explodes renders fine as raw vertex data (small) but blows up once
// Babylon poses it through the skeleton (hundreds of metres).
//
// Run after any change to the rigged asset pipeline, a poly.pizza source swap,
// or an upgrade to @babylonjs/core, since this bug class is a Babylon/glTF
// interaction that has no reliable static check.
import { launch } from './lib/game.mjs';
import species from '../src/data/species.json' with { type: 'json' };
import characters from '../src/data/models.json' with { type: 'json' };

const EXPLODED_THRESHOLD_M = 20;

const { browser, page } = await launch({ width: 800, height: 600 });

const files = [
  ...Object.keys(species.species ?? species).map((id) => `models/creatures/${id}.glb`),
  ...Object.keys(characters.characters).map((id) => `models/characters/${id}.glb`)
];

const results = await page.evaluate(
  async ({ files, threshold }) => {
    const g = window.__tetherbound;
    const out = [];
    for (const f of files) {
      try {
        const container = await g.loadContainerOwned('/' + f);
        container.addAllToScene();
        for (const group of container.animationGroups) group.stop();
        container.animationGroups.find((a) => /idle/i.test(a.name))?.start(true, 1);
        await new Promise((resolve) => setTimeout(resolve, 120));

        let worst = 0;
        for (const mesh of container.meshes) {
          if (!mesh.getTotalVertices()) continue;
          mesh.computeWorldMatrix(true);
          try {
            mesh.refreshBoundingInfo({ applySkeleton: true, applyMorph: false });
          } catch {
            // Some meshes have no skeleton; the plain bounding box is fine.
          }
          const bb = mesh.getBoundingInfo().boundingBox;
          const extent = Math.max(...bb.maximumWorld.subtract(bb.minimumWorld).asArray());
          worst = Math.max(worst, extent);
        }
        out.push({ file: f, worstExtentM: +worst.toFixed(1), exploded: worst > threshold });
        container.dispose();
      } catch (e) {
        out.push({ file: f, error: String(e).slice(0, 120), exploded: true });
      }
    }
    return out;
  },
  { files, threshold: EXPLODED_THRESHOLD_M }
);

await browser.close();

const broken = results.filter((r) => r.exploded);
for (const r of results) {
  const tag = r.exploded ? 'BROKEN' : '  ok  ';
  console.log(`  ${tag}  ${r.file.padEnd(34)} ${r.error ?? `${r.worstExtentM}m`}`);
}
console.log('');
if (broken.length > 0) {
  console.error(`${broken.length} of ${results.length} rigged models fail the bounds check.`);
  process.exit(1);
}
console.log(`All ${results.length} rigged models pass (D56).`);
