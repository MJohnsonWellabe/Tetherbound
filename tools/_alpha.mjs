import { readFileSync } from 'node:fs';
import { NodeIO } from '@gltf-transform/core';
const io = new NodeIO();
const D='/tmp/claude-0/-home-user-Tetherbound/544bb7ab-eb1e-5ae4-b422-1f77f6792e53/scratchpad/cand';
for (const n of ['grass_a','grass_b','grass_c','grass_d','grass_e','grass_f','tallgrass','bush_a','bush_b','bush_c','bush_d','flower_b','fern']) {
  try {
    const doc = await io.readBinary(new Uint8Array(readFileSync(`${D}/${n}.glb`)));
    const modes = doc.getRoot().listMaterials().map(m => `${m.getAlphaMode()}${m.getBaseColorTexture()?'/tex':''}`);
    console.log(`${n.padEnd(11)} ${modes.join(' ')}`);
  } catch(e) { console.log(`${n.padEnd(11)} ERR`); }
}
