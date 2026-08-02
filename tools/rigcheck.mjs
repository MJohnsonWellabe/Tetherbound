// Verifies Phase 5 in a real browser: rigged player mounts, wild pals mount
// rigged bodies with playing animations, the companion follows an added pal.
import { chromium } from 'playwright';

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH,
  args: ['--use-gl=angle', '--use-angle=swiftshader', '--no-sandbox']
});
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
page.on('console', (m) => {
  if (m.type() === 'error' || m.type() === 'warning') console.log('[console]', m.type(), m.text());
});
page.on('pageerror', (e) => console.log('[pageerror]', e.message));

await page.goto('http://127.0.0.1:4173/?seed=hollowbrook');
await page.waitForFunction(() => window.__tetherbound, { timeout: 30000 });
// Let rigs download and mount.
await page.waitForTimeout(6000);

const report = await page.evaluate(async () => {
  const g = window.__tetherbound;
  const scene = g.scene;
  const out = {};

  // 1. Player rig: root should carry rig children, capsule disabled.
  const playerRoot = g.player.root;
  const playerMeshes = playerRoot.getChildMeshes();
  out.player = {
    childMeshes: playerMeshes.length,
    skinned: playerMeshes.filter((m) => m.skeleton).length,
    capsuleEnabled: playerMeshes.some((m) => m.name === 'player_body' && m.isEnabled())
  };

  // 2. Force a wild spawn near the player and give it time to mount.
  for (let i = 0; i < 200 && g.spawner.activeCount === 0; i++) {
    g.spawner.update(g.player.state.position.x, g.player.state.position.z, 0.5, 0.5, 1);
  }
  await new Promise((r) => setTimeout(r, 5000));
  const wild = g.spawner.active[0];
  out.wild = wild
    ? {
        species: wild.state.species,
        hasBody: !!wild.body,
        rigMeshes: wild.body ? wild.body.root.getChildMeshes().filter((m) => m.skeleton).length : 0,
        driverHasRig: wild.body ? wild.body.driver.hasRig : false
      }
    : null;

  // 3. Animation groups actually playing.
  out.playingGroups = scene.animationGroups.filter((gr) => gr.isPlaying).map((gr) => gr.name).slice(0, 8);
  out.playingCount = scene.animationGroups.filter((gr) => gr.isPlaying).length;

  // 4. Companion: add a starter to the party, run updates, check a body appears.
  const starter = { ...wild.state, uid: 'test_starter' };
  g.party.add(starter);
  for (let i = 0; i < 60; i++) {
    g.companion.update(g.party, g.player.state.position.x, g.player.state.position.z, 0, 1 / 60, false);
  }
  await new Promise((r) => setTimeout(r, 4000));
  g.companion.update(g.party, g.player.state.position.x, g.player.state.position.z, 0, 1 / 60, false);
  const compNode = scene.transformNodes.find((n) => n.name.startsWith('pal_') && n.name !== wild?.body?.root?.name);
  out.companion = {
    partySize: g.party.size,
    nodeFound: !!compNode,
    skinnedMeshes: compNode ? compNode.getChildMeshes().filter((m) => m.skeleton).length : 0
  };

  // 5. NPC rigs.
  const npcRoots = scene.transformNodes.filter((n) => n.name.startsWith('npc_'));
  out.npcs = {
    total: npcRoots.length,
    withSkinned: npcRoots.filter((n) => n.getChildMeshes().some((m) => m.skeleton)).length
  };

  out.drawCalls = g.renderer?.handles?.engine?._drawCalls?.current ?? null;
  return out;
});

console.log(JSON.stringify(report, null, 2));
await page.screenshot({ path: process.env.SHOT ?? 'shots-feel/rigcheck.png' });
await browser.close();
