import { readdirSync, readFileSync } from 'node:fs';
import { NodeIO } from '@gltf-transform/core';
const io = new NodeIO();
const dir = 'public/models/props';
for (const f of readdirSync(dir).sort()) {
  if (!f.endsWith('.glb')) continue;
  const doc = await io.readBinary(new Uint8Array(readFileSync(`${dir}/${f}`)));
  let tris = 0, lo = [1e9,1e9,1e9], hi = [-1e9,-1e9,-1e9];
  for (const m of doc.getRoot().listMeshes()) for (const p of m.listPrimitives()) {
    const idx = p.getIndices(), pos = p.getAttribute('POSITION');
    tris += idx ? idx.getCount()/3 : pos.getCount()/3;
    const mn = pos.getMin([]), mx = pos.getMax([]);
    for (let k=0;k<3;k++){ lo[k]=Math.min(lo[k],mn[k]); hi[k]=Math.max(hi[k],mx[k]); }
  }
  const h = hi[1]-lo[1], w = Math.max(hi[0]-lo[0], hi[2]-lo[2]);
  console.log(`${f.replace('.glb','').padEnd(14)} ${String(Math.round(tris)).padStart(5)} tris   h=${h.toFixed(2)}  w=${w.toFixed(2)}`);
}
