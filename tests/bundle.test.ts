import { describe, expect, it } from 'vitest';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

/**
 * Bundle and layering discipline. Two rules, both of which are cheap to state
 * and expensive to rediscover:
 *
 * 1. Only src/core/babylon.ts may import from '@babylonjs'. Everything else
 *    goes through the facade. A single barrel import anywhere restores the
 *    whole engine to the vendor chunk.
 *
 * 2. Pure game logic imports no renderer at all. combat/, party/, survival/,
 *    and the world generation math must run under vitest with no canvas, and
 *    must stay portable if the renderer is ever replaced.
 *
 * The HTML sweep in rule 1 is not paranoia. The sibling GolfModel project lost
 * ~800 KB to two authoring tools that imported the barrel from an inline
 * <script type="module"> block, which no scan of src/ could ever have seen.
 */

const ROOT = join(__dirname, '..');

/**
 * The two files allowed to import @babylonjs.
 *
 * They are split rather than merged because the glTF parser costs 207 KB
 * gzipped and nothing before milestone M5 loads a model. babylonLoaders.ts is
 * reached only through a dynamic import in AssetLoader.ts, which keeps it in
 * its own chunk and off the boot path.
 */
const FACADES = [join('src', 'core', 'babylon.ts'), join('src', 'core', 'babylonLoaders.ts')];
const FACADE = FACADES[0] as string;

/** Directories whose contents must never touch the renderer. */
const ENGINE_FREE_DIRS = [
  join('src', 'combat'),
  join('src', 'party'),
  join('src', 'survival'),
  join('src', 'save'),
  join('src', 'data')
];

function walk(dir: string, match: (f: string) => boolean): string[] {
  let out: string[] = [];
  let entries: string[];
  try {
    entries = readdirSync(dir);
  } catch {
    return out; // directory not created yet, nothing to police
  }
  for (const entry of entries) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      out = out.concat(walk(full, match));
    } else if (match(full)) {
      out.push(full);
    }
  }
  return out;
}

const isTs = (f: string): boolean => f.endsWith('.ts') && !f.endsWith('.d.ts');

/**
 * Strip comments before scanning for imports.
 *
 * The facade's own doc comment quotes `from '@babylonjs/core'` as the mistake
 * it exists to prevent, and this test flagged it. A rule that cannot be
 * explained in prose next to the code it governs is a bad rule, so the scanner
 * learns to read code rather than the docs learning to avoid words.
 *
 * The `//` case guards against `:` immediately before, so a `https://` inside
 * a string is not mistaken for the start of a line comment.
 */
function stripComments(src: string): string {
  return src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/.*$/gm, '$1');
}

describe('engine import discipline', () => {
  it('only the engine facades import from @babylonjs', () => {
    const offenders = walk(join(ROOT, 'src'), isTs)
      .filter((f) => !FACADES.includes(relative(ROOT, f)))
      .filter((f) =>
        /from\s+['"]@babylonjs|import\s+['"]@babylonjs/.test(stripComments(readFileSync(f, 'utf8')))
      )
      .map((f) => relative(ROOT, f));

    expect(
      offenders,
      `These files import @babylonjs directly. Route them through ${FACADE} instead, ` +
        `and add any missing symbol there as a deep import.`
    ).toEqual([]);
  });

  it('no facade imports a @babylonjs barrel', () => {
    // A barrel import is one whose path is exactly the package root. The
    // loaders barrel is the expensive one: it drags in OBJ, STL, Draco and
    // every KHR extension alongside the glTF parser we actually want.
    const offenders = FACADES.filter((f) =>
      /['"]@babylonjs\/(core|loaders)['"]/.test(stripComments(readFileSync(join(ROOT, f), 'utf8')))
    );
    expect(
      offenders,
      'Facades must deep-import specific modules, never the package root.'
    ).toEqual([]);
  });

  it('only AssetLoader reaches the glTF facade, and only dynamically', () => {
    // A static import anywhere would pull the parser back into the boot chunk
    // and undo the split.
    const offenders = walk(join(ROOT, 'src'), isTs)
      .filter((f) => !FACADES.includes(relative(ROOT, f)))
      .filter((f) => /^\s*import\s.*from\s+['"].*babylonLoaders['"]/m.test(stripComments(readFileSync(f, 'utf8'))))
      .map((f) => relative(ROOT, f));

    expect(
      offenders,
      'Import babylonLoaders with a dynamic import() so the glTF parser stays out of the boot chunk.'
    ).toEqual([]);
  });

  it('no HTML entry point imports @babylonjs inline', () => {
    const offenders = walk(ROOT, (f) => f.endsWith('.html') && !f.includes(`${sep}node_modules${sep}`))
      .filter((f) => !f.includes(`${sep}dist${sep}`))
      .filter((f) => /@babylonjs/.test(readFileSync(f, 'utf8')))
      .map((f) => relative(ROOT, f));

    expect(
      offenders,
      'An inline <script> importing the engine bypasses the facade and re-inflates the vendor chunk.'
    ).toEqual([]);
  });
});

describe('layering', () => {
  it('pure game logic does not import the renderer', () => {
    const offenders: string[] = [];
    for (const dir of ENGINE_FREE_DIRS) {
      for (const file of walk(join(ROOT, dir), isTs)) {
        const src = stripComments(readFileSync(file, 'utf8'));
        if (/from\s+['"].*core\/babylon['"]|from\s+['"]@babylonjs/.test(src)) {
          offenders.push(relative(ROOT, file));
        }
      }
    }
    expect(
      offenders,
      'These modules are meant to be pure and renderer-free so they run headless under vitest. ' +
        'Move the rendering half into the system that owns it.'
    ).toEqual([]);
  });
});
