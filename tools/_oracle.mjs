import { launch } from './lib/game.mjs';
const { browser, page } = await launch({ width: 800, height: 600 });
const r = await page.evaluate(async () => {
  const g = window.__tetherbound;
  const models = await fetch('/models.list').then(r => r.ok ? r.json() : null).catch(() => null);
  const files = [
    ...['bramblit','cindercub','dewdrake','tuftmoth','pebblit','sparrowick','grazehorn','rillnewt',
       'emberhop','thistleback','cragpup','voltvole','mirefin','ashmane','loamking'].map(s => `models/creatures/${s}.glb`),
    ...['player','villager_m','villager_f','tether','warden'].map(s => `models/characters/${s}.glb`)
  ];
  const out = [];
  for (const f of files) {
    try {
      const c = await g.loadContainerOwned('/' + f);
      c.addAllToScene();
      for (const gr of c.animationGroups) gr.stop();
      c.animationGroups.find(a => /idle/i.test(a.name))?.start(true, 1);
      await new Promise(res => setTimeout(res, 120));
      let worst = 0;
      for (const m of c.meshes) {
        if (!m.getTotalVertices()) continue;
        m.computeWorldMatrix(true);
        try { m.refreshBoundingInfo({ applySkeleton: true, applyMorph: false }); } catch (e) {}
        const bb = m.getBoundingInfo().boundingBox;
        worst = Math.max(worst, Math.max(...bb.maximumWorld.subtract(bb.minimumWorld).asArray()));
      }
      out.push({ f: f.split('/').pop(), worst: +worst.toFixed(1), broken: worst > 20 });
      c.dispose();
    } catch (e) { out.push({ f: f.split('/').pop(), err: String(e).slice(0, 60) }); }
  }
  return out;
});
console.log(JSON.stringify(r.filter(x => x.broken || x.err)));
console.log('ok:', r.filter(x => !x.broken && !x.err).map(x => x.f).join(' '));
await browser.close();
