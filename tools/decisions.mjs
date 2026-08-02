// Print the decisions index.
//
//   npm run decisions          list every decision, oldest first
//   npm run decisions -- --next   print the next free number and exit
//
// The index is generated rather than stored. A checked-in list would be edited
// by every session that adds a decision, which is the exact conflict that
// splitting DECISIONS.md into one file per entry was meant to remove.
//
// Exits non-zero if two files claim the same number. That is the failure mode
// when two sessions run concurrently, and it is silent otherwise: both entries
// exist, both look fine, and every cross-reference to "D31" is now ambiguous.
import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const DIR = join(dirname(fileURLToPath(import.meta.url)), '..', 'docs', 'decisions');

const entries = [];
for (const file of readdirSync(DIR).sort()) {
  if (!file.endsWith('.md')) continue;
  const text = readFileSync(join(DIR, file), 'utf8');
  const heading = /^# D(\d+)\. (.+)$/m.exec(text);
  if (!heading) {
    console.error(`  ${file}: no "# DNN. Title" heading`);
    process.exitCode = 1;
    continue;
  }
  const kind = /^Kind: (.+)$/m.exec(text);
  entries.push({
    n: Number(heading[1]),
    title: heading[2],
    kind: kind ? kind[1].trim() : 'implementation',
    file,
  });
}

entries.sort((a, b) => a.n - b.n);

const next = entries.length ? Math.max(...entries.map((e) => e.n)) + 1 : 1;

if (process.argv.includes('--next')) {
  console.log(`D${next}`);
  process.exit(process.exitCode ?? 0);
}

const width = Math.max(...entries.map((e) => e.kind.length));
let previous = null;
for (const e of entries) {
  if (e.n === previous) {
    console.error(`  !! D${e.n} claimed twice, second is ${e.file}`);
    process.exitCode = 1;
  }
  previous = e.n;
  console.log(`  D${String(e.n).padStart(2, '0')}  ${e.kind.padEnd(width)}  ${e.title}`);
}

console.log(`\n  ${entries.length} decisions in docs/decisions/. Next free number: D${next}.`);
