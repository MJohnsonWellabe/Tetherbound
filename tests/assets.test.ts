import { describe, expect, it } from 'vitest';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import models from '../src/data/models.json';
import { planProps, propUrls, PROP_FAMILIES } from '../src/world/propPlan';

/**
 * The asset pipeline's contracts.
 *
 * The manifest is a PROVENANCE log, not a license gate: the owner waived the
 * CC0-only rule for this non-commercial build (D42). What still matters is
 * that every shipped file is accounted for (where it came from, what touched
 * it) and that everything models.json points at actually shipped.
 */

const ROOT = join(__dirname, '..');
const PUB = join(ROOT, 'public');

function walk(dir: string): string[] {
  if (!existsSync(dir)) return [];
  let out: string[] = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) out = out.concat(walk(full));
    else out.push(full.slice(ROOT.length + 1).replaceAll('\\', '/'));
  }
  return out;
}

function manifestFiles(): Set<string> {
  const text = readFileSync(join(ROOT, 'ASSET_MANIFEST.md'), 'utf8');
  const files = new Set<string>();
  for (const line of text.split('\n')) {
    const match = /^\|\s*(public\/\S+)\s*\|/.exec(line);
    if (match?.[1]) files.add(match[1]);
  }
  return files;
}

describe('asset manifest', () => {
  const shipped = [
    ...walk(join(PUB, 'models')),
    ...walk(join(PUB, 'textures')),
    ...walk(join(PUB, 'icons'))
  ];
  const manifest = manifestFiles();

  it('ships at least the prop families', () => {
    expect(shipped.length).toBeGreaterThan(0);
  });

  it('every shipped asset has a manifest row', () => {
    const missing = shipped.filter((f) => !manifest.has(f));
    expect(missing, 'run `npm run assets` to regenerate the manifest').toEqual([]);
  });

  it('every manifest row points at a real file', () => {
    const stale = [...manifest].filter((f) => !existsSync(join(ROOT, f)));
    expect(stale, 'manifest names files that no longer ship').toEqual([]);
  });

  it('keeps models inside the payload budget', () => {
    // Rigged models are lazy-loaded per spawn, never on the boot path, so
    // they get a looser ceiling than world props (which download in bulk).
    for (const file of shipped.filter((f) => f.endsWith('.glb'))) {
      const kb = statSync(join(ROOT, file)).size / 1024;
      const rigged = file.includes('/creatures/') || file.includes('/characters/');
      expect(kb, `${file} is ${Math.round(kb)} KB`).toBeLessThan(rigged ? 1600 : 420);
    }
  });
});

describe('models.json', () => {
  it('covers every prop family with an existing first variant', () => {
    for (const family of PROP_FAMILIES) {
      const entry = (models.props as Record<string, { variants: { url: string; scale: number }[] }>)[
        family
      ];
      expect(entry, `family "${family}" missing from models.json`).toBeDefined();
      const first = entry?.variants[0];
      expect(first, `family "${family}" has no variants`).toBeDefined();
      expect(existsSync(join(PUB, first?.url ?? '')), `${first?.url} not shipped`).toBe(true);
      expect(first?.scale).toBeGreaterThan(0);
      expect(Number.isFinite(first?.scale)).toBe(true);
    }
  });

  it('every variant of every family exists and is sanely scaled', () => {
    for (const [family, entry] of Object.entries(
      models.props as Record<string, { variants: { url: string; scale: number }[] }>
    )) {
      for (const variant of entry.variants) {
        expect(existsSync(join(PUB, variant.url)), `${family}: ${variant.url}`).toBe(true);
        expect(variant.scale, `${family} scale`).toBeGreaterThan(0);
        expect(variant.scale, `${family} scale`).toBeLessThan(20);
      }
    }
  });
});

describe('planProps', () => {
  it('uses the model when its url loaded', () => {
    const loaded = new Map(propUrls().map((u) => [u, true] as const));
    for (const plan of planProps(loaded)) {
      expect(plan.source, plan.family).toBe('model');
      expect(plan.variant?.url).toBeTruthy();
    }
  });

  it('falls back per family, not all-or-nothing', () => {
    const urls = propUrls();
    const loaded = new Map(urls.map((u, i) => [u, i !== 0] as const));
    const plans = planProps(loaded);
    const primitive = plans.filter((p) => p.source === 'primitive');
    const model = plans.filter((p) => p.source === 'model');
    expect(primitive.length).toBe(1);
    expect(model.length).toBe(PROP_FAMILIES.length - 1);
  });

  it('treats a total failure as an all-primitive world', () => {
    for (const plan of planProps(new Map())) {
      expect(plan.source).toBe('primitive');
    }
  });
});
