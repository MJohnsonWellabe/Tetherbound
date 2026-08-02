import { expect, test } from '@playwright/test';
import type { Page } from '@playwright/test';

/**
 * The M3 and M4 spine, driven in a real browser: start cold with nothing, take
 * a starter from Orin, walk into the Hall, beat both grunts and Bracken, and
 * come out with the Meadow Sigil.
 *
 * Unit tests cover the formulas. What they cannot see is whether the pieces are
 * wired to each other: whether the prompt appears, whether a conversation
 * reaches its effects, whether a scripted fight actually hands the next pal in,
 * whether an orb really bounces off a collar. Every one of those was broken at
 * some point and every one of them compiled.
 *
 * The party is over-levelled deliberately. This asserts that the SPINE
 * connects, not that the numbers are balanced; balance is M5b's job, and a
 * smoke test that needs twenty minutes of levelling is a smoke test nobody
 * runs.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */
type Win = any;

const BOOT_TIMEOUT = 120_000;

async function bootGame(page: Page): Promise<void> {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => document.getElementById('boot') === null, null, {
    timeout: BOOT_TIMEOUT
  });
  await page.waitForTimeout(1200);
}

/** Advance the dialogue until it closes or a choice is waiting. */
async function runDialogue(page: Page, choice: number | null = null): Promise<void> {
  for (let i = 0; i < 20; i++) {
    const choices = await page.$$('.dlg__choices button, .dlg__choice');
    if (choices.length > 0) {
      const pick = choices[choice ?? 0];
      if (pick) await pick.click();
      await page.waitForTimeout(300);
      continue;
    }
    const open = await page.evaluate(() => !document.querySelector('.dlg')?.hidden);
    if (!open) return;
    await page.keyboard.press('KeyE');
    await page.waitForTimeout(260);
  }
}

/** Stand next to an NPC and talk to them. */
async function talkTo(page: Page, npcId: string, choice: number | null = null): Promise<void> {
  const at = await page.evaluate((id) => {
    const g = (window as Win).__tetherbound;
    const npc = g.built.npcs.byId(id);
    const p = npc.position;
    return { x: p.x as number, z: p.z as number };
  }, npcId);

  await page.evaluate(
    ({ x, z }) => {
      const g = (window as Win).__tetherbound;
      g.player.state.position.x = x + 2;
      g.player.state.position.z = z + 2;
      g.player.state.position.y = g.terrain.heightAt(x + 2, z + 2) + 1;
      g.chunks.update(x, z);
    },
    at
  );
  // The Hall is ~1km out, so the streamed world has to catch up before the
  // controller settles and the talk range check means anything.
  await page.waitForTimeout(2500);

  await page.keyboard.press('KeyE');
  await page.waitForTimeout(500);
  await runDialogue(page, choice);
}

/** Swing until the scripted fight resolves. */
async function winScriptedFight(page: Page): Promise<void> {
  for (let i = 0; i < 600; i++) {
    const running = await page.evaluate(
      () => (window as Win).__tetherbound.story.inScriptedFight as boolean
    );
    if (!running) return;
    await page.evaluate(() => (window as Win).__tetherbound.combat.attack('quick', 1));
    await page.waitForTimeout(50);
  }
  throw new Error('scripted fight never resolved');
}

async function overlevel(page: Page): Promise<void> {
  await page.evaluate(() => {
    const g = (window as Win).__tetherbound;
    for (const pal of g.party.members) {
      pal.level = 40;
      pal.currentHp = 99_999;
      pal.fainted = false;
    }
  });
}

test('a cold start reaches the Meadow Sigil', async ({ page }) => {
  const errors: string[] = [];
  page.on('pageerror', (e) => errors.push(String(e.message)));

  await bootGame(page);

  // Nothing to begin with. The starter is a decision, not a gift.
  expect(await page.evaluate(() => (window as Win).__tetherbound.party.size)).toBe(0);

  // Orin, and the choice of three.
  await talkTo(page, 'orin', 0);
  const afterOrin = await page.evaluate(() => {
    const g = (window as Win).__tetherbound;
    return { size: g.party.size as number, flags: [...g.story.flags] as string[] };
  });
  expect(afterOrin.size, 'Orin should hand over a starter').toBe(1);
  expect(afterOrin.flags).toContain('took_starter');

  await overlevel(page);

  // The Hall: two grunts, then the Warden.
  for (const grunt of ['grunt_a', 'grunt_b']) {
    await talkTo(page, grunt);
    expect(
      await page.evaluate(() => (window as Win).__tetherbound.story.inScriptedFight as boolean),
      `${grunt} should start a fight`
    ).toBe(true);
    await winScriptedFight(page);
  }

  const beaten = await page.evaluate(() => [...(window as Win).__tetherbound.story.flags]);
  expect(beaten).toContain('grunt_a_down');
  expect(beaten).toContain('grunt_b_down');

  await talkTo(page, 'bracken');

  // Tether's pals are not catchable, and that is a lesson rather than a bug.
  // This bounced silently for the whole of M2 because the collar was checked
  // against a species name no species has.
  const thrown = await page.evaluate(() => (window as Win).__tetherbound.encounter.throwOrb(1));
  expect(thrown, 'an orb must bounce off a collared pal').toBe('bounced');

  await winScriptedFight(page);

  const won = await page.evaluate(() => {
    const g = (window as Win).__tetherbound;
    return { flags: [...g.story.flags] as string[], badges: [...g.story.badges] as string[] };
  });
  expect(won.flags, 'beating Bracken sets the badge flag').toContain('badge_meadow');
  expect(won.badges, 'the Meadow Sigil is awarded').toContain('meadow_sigil');

  expect(errors, 'no page errors across the whole spine').toEqual([]);
});

test('the party and the story survive a reload', async ({ page }) => {
  await bootGame(page);
  await talkTo(page, 'orin', 1);

  const before = await page.evaluate(() => {
    const g = (window as Win).__tetherbound;
    g.saves.save(g.snapshotSave());
    return {
      size: g.party.size as number,
      species: g.party.members.map((p: Win) => p.species) as string[],
      flags: [...g.story.flags] as string[]
    };
  });
  expect(before.size).toBe(1);

  await bootGame(page);

  const after = await page.evaluate(() => {
    const g = (window as Win).__tetherbound;
    return {
      size: g.party.size as number,
      species: g.party.members.map((p: Win) => p.species) as string[],
      flags: [...g.story.flags] as string[]
    };
  });

  // Both of these were written to the save and never read back, so a reload
  // dropped the party and re-offered a starter the player already had.
  expect(after.species, 'the party comes back').toEqual(before.species);
  expect(after.flags, 'progress comes back').toEqual(expect.arrayContaining(before.flags));
});
