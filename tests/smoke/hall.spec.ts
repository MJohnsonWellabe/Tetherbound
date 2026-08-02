import { expect, test, type Page } from '@playwright/test';

/**
 * The M4 walkthrough: can a player actually get from a cold start to a win?
 *
 * Everything else in the suite tests a part. This tests the SPINE, driven the
 * way a player drives it: tapping the dialogue panel, tapping the interact
 * button, tapping Attack. If the chain from Orin to the Meadow Sigil is broken
 * anywhere, this is what says so.
 *
 * The one concession is that enemy pals are dropped to 1 HP before the killing
 * tap. This is a flow test, not a balance test: making a level-5 starter
 * legitimately beat Bracken's level-17 Loamking would mean grinding a real
 * party inside a smoke spec, and balance is M5's job. Every other step is real.
 */

async function boot(page: Page): Promise<string[]> {
  const errors: string[] = [];
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push(m.text());
  });
  page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
  await page.goto('/');
  await page.waitForFunction(() => document.getElementById('boot') === null, null, {
    timeout: 60_000
  });
  return errors;
}

/** Tap through dialogue until it closes or a choice is waiting. */
async function advanceDialogue(page: Page, max = 30): Promise<void> {
  for (let i = 0; i < max; i++) {
    const panel = page.locator('.dlg');
    if (!(await panel.isVisible())) return;
    if ((await page.locator('.dlg__choice').count()) > 0) return;
    await panel.dispatchEvent('pointerdown');
    await page.waitForTimeout(60);
  }
}

/** Put the player next to an NPC and open its conversation. */
async function talkTo(page: Page, npcId: string): Promise<void> {
  await page.evaluate((id) => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    const game = g.game as unknown as {
      world: { npcs: { byId: (i: string) => { position: { x: number; y: number; z: number } } | undefined } };
    };
    const player = g.player as unknown as { state: { position: { x: number; y: number; z: number } } };
    const npc = game.world.npcs.byId(id);
    if (!npc) throw new Error(`no npc ${id}`);
    player.state.position.x = npc.position.x + 1.5;
    player.state.position.y = npc.position.y;
    player.state.position.z = npc.position.z + 1.5;
  }, npcId);
  // The interact prompt refreshes on the HUD's 10Hz tick.
  await page.waitForTimeout(250);
  await page.locator('.hud__interact').dispatchEvent('pointerdown');
  await page.waitForTimeout(120);
}

async function mode(page: Page): Promise<string> {
  return page.evaluate(() => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    return (g.game as unknown as { mode: string }).mode;
  });
}

/** Win the fight in progress: soften each enemy, then land the real hit. */
async function winFight(page: Page): Promise<void> {
  for (let round = 0; round < 12; round++) {
    if ((await mode(page)) !== 'combat') return;
    await page.evaluate(() => {
      const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
      const battle = (g.game as unknown as { battle: { enemies: { hp: number }[] } | null }).battle;
      for (const e of battle?.enemies ?? []) if (e.hp > 1) e.hp = 1;
    });
    const attack = page.locator('.cb__btn--attack');
    await attack.dispatchEvent('pointerdown');
    await attack.dispatchEvent('pointerup');
    await page.waitForTimeout(700);
  }
}

test('a cold start reaches the Meadow Sigil', async ({ page }) => {
  const errors = await boot(page);

  // --- the beginning: Orin hands over a starter -------------------------
  await expect(page.locator('.dlg')).toBeVisible();
  await advanceDialogue(page);
  await expect(page.locator('.dlg__choice')).toHaveCount(3);
  await page.locator('.dlg__choice').nth(1).dispatchEvent('pointerdown');
  await advanceDialogue(page);

  const partySize = await page.evaluate(() => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    return (g.game as unknown as { party: { size: number } }).party.size;
  });
  expect(partySize, 'the starter should have joined').toBe(1);
  expect(await mode(page), 'the opening should hand control back').toBe('explore');

  // --- the middle: two grunts, then the Warden --------------------------
  for (const grunt of ['grunt_a', 'grunt_b']) {
    await talkTo(page, grunt);
    await advanceDialogue(page);
    // The fight is queued by a dialogue effect and starts once the panel closes.
    await page.waitForTimeout(300);
    expect(await mode(page), `${grunt} should have started a fight`).toBe('combat');
    await winFight(page);
    await advanceDialogue(page);
    await page.waitForTimeout(200);
  }

  const flags = await page.evaluate(() => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    const game = g.game as unknown as { hasFlag: (f: string) => boolean };
    return { a: game.hasFlag('grunt_a_down'), b: game.hasFlag('grunt_b_down') };
  });
  expect(flags.a && flags.b, 'both grunts should be recorded as beaten').toBe(true);

  // --- Bracken Holt -----------------------------------------------------
  await talkTo(page, 'bracken');
  await advanceDialogue(page);
  await page.waitForTimeout(300);
  expect(await mode(page), 'Bracken should have started a fight').toBe('combat');

  // The collared team cannot be caught, and the Hall cannot be walked out of.
  const hallRules = await page.evaluate(() => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    const battle = (g.game as unknown as {
      battle: { enemies: { collared: boolean }[]; flee: () => boolean } | null;
    }).battle;
    return {
      allCollared: (battle?.enemies ?? []).every((e) => e.collared),
      teamSize: battle?.enemies.length ?? 0,
      canFlee: battle?.flee() ?? true
    };
  });
  expect(hallRules.teamSize, 'Bracken fields three pals').toBe(3);
  expect(hallRules.allCollared, 'every Tether pal wears a collar').toBe(true);
  expect(hallRules.canFlee, 'a Hall fight cannot be fled').toBe(false);

  await winFight(page);
  // Defeat dialogue, then the cut-tether sequence.
  await advanceDialogue(page);
  await page.waitForTimeout(400);

  // --- the win state ----------------------------------------------------
  await expect(page.locator('.victory')).toBeVisible();
  await expect(page.locator('.victory__badgeName')).toHaveText('Meadow Sigil');

  await page.locator('.victory__go').dispatchEvent('pointerdown');
  await page.waitForTimeout(300);

  const won = await page.evaluate(() => {
    const g = (window as unknown as { __tetherbound: Record<string, never> }).__tetherbound;
    const game = g.game as unknown as {
      hasFlag: (f: string) => boolean;
      earnedBadges: readonly string[];
    };
    return { badge: game.hasFlag('badge_meadow'), badges: [...game.earnedBadges] };
  });
  expect(won.badge, 'the Truestone Orb gate should be open').toBe(true);
  expect(won.badges).toContain('meadow_sigil');

  const real = errors.filter((e) => !/swiftshader|WebGL|GPU stall|Fallback/i.test(e));
  expect(real, `unexpected console errors:\n${real.join('\n')}`).toEqual([]);
});
