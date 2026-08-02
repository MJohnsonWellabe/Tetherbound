// Tile a survey into one labelled contact sheet.
//
//   node tools/sheet.mjs [--in shots] [--out shots/_sheet.png] [--cols 3]
//
// A whole survey judged in a single look. Reviewing nine PNGs one file at a
// time is how inconsistencies survive review: you cannot see that the dusk
// shot and the night shot disagree about fog when they are never on screen
// together.
//
// Built by rendering an HTML page and screenshotting it, rather than shelling
// out to ffmpeg. No ffmpeg here, no new dependency, and the tiles get real
// labels and per-shot stats baked in, which an ffmpeg tile filter cannot do
// without a freetype build.
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const args = process.argv.slice(2);
const opt = (k, d) => {
  const i = args.indexOf('--' + k);
  return i >= 0 ? args[i + 1] : d;
};

const IN = opt('in', 'shots');
const OUT = opt('out', 'shots/_sheet.png');
const COLS = +opt('cols', 3);
const TILE = +opt('tile', 520);

const manifestPath = path.join(IN, 'survey.json');
if (!fs.existsSync(manifestPath)) {
  console.error(`No ${manifestPath}. Run: node tools/survey.mjs`);
  process.exit(1);
}
const survey = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

// Read each PNG as a data URI. The page is loaded via setContent with no base
// URL, so relative file paths would not resolve.
const tiles = survey.shots
  .filter((s) => fs.existsSync(s.file))
  .map((s) => ({
    ...s,
    uri: `data:image/png;base64,${fs.readFileSync(s.file).toString('base64')}`
  }));

if (tiles.length === 0) {
  console.error('No shots found. Run: node tools/survey.mjs');
  process.exit(1);
}

const budget = { frameMs: 16, drawCalls: 150, triangles: 300_000 };
const over = (v, max) => (v != null && v > max ? 'over' : '');

const html = `<!doctype html><meta charset="utf-8"><style>
  :root { color-scheme: dark }
  body { margin:0; background:#0a0f0c; color:#e8f5ea;
         font:13px/1.4 ui-sans-serif,system-ui,sans-serif; padding:18px }
  h1 { font-size:15px; letter-spacing:.22em; color:#7cff9b; margin:0 0 14px; font-weight:600 }
  .grid { display:grid; grid-template-columns:repeat(${COLS}, ${TILE}px); gap:14px }
  figure { margin:0 }
  img { width:${TILE}px; display:block; border-radius:8px; border:1px solid #2c4033 }
  figcaption { margin-top:5px; display:flex; justify-content:space-between; gap:8px }
  .name { color:#e8f5ea; font-weight:600 }
  .stat { color:#63796b; font-family:ui-monospace,monospace; font-size:11px }
  .over { color:#ff6b4a }
</style>
<h1>TETHERBOUND SURVEY</h1>
<div class="grid">
${tiles
  .map(
    (t) => `<figure>
  <img src="${t.uri}">
  <figcaption>
    <span class="name">${t.name}</span>
    <span class="stat">
      <span class="${over(t.frameMs, budget.frameMs)}">${t.frameMs}ms</span> ·
      <span class="${over(t.drawCalls, budget.drawCalls)}">${t.drawCalls ?? '?'}d</span> ·
      <span class="${over(t.triangles, budget.triangles)}">${Math.round((t.triangles ?? 0) / 1000)}k</span>
    </span>
  </figcaption>
</figure>`
  )
  .join('\n')}
</div>`;

const browser = await chromium.launch({
  ...(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {})
});
const page = await browser.newPage({
  viewport: { width: COLS * (TILE + 14) + 40, height: 900 }
});
await page.setContent(html);
await page.screenshot({ path: OUT, fullPage: true });
await browser.close();

console.log(`${tiles.length} tiles -> ${OUT}`);
console.log('Frame times are software-rendered and are NOT a phone measurement.');
