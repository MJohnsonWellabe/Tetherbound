import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw

tag = sys.argv[1] if len(sys.argv) > 1 else 'paired'
root = Path(f'D:/tetherbound/visual-acceptance/shots/grass-normals-{tag}/region')
out = Path('D:/tetherbound/visual-acceptance-local/grass-normals-review' if tag == 'paired' else f'D:/tetherbound/visual-acceptance-local/grass-normals-{tag}-review')
out.mkdir(exist_ok=True)
for region in root.iterdir():
    manifest = region / 'manifest.jsonl'
    if not manifest.exists():
        continue
    rows = [json.loads(line) for line in manifest.read_text().splitlines()]
    frames = [r for r in rows if r.get('kind') == 'frame']
    for phase in dict.fromkeys(r['time'] for r in frames):
        pairs = {}
        for r in frames:
            if r['time'] == phase:
                pairs.setdefault(r['subject'], {})[r['variant']] = r
        complete = [p for p in pairs.values() if 'baseline' in p and 'candidate' in p]
        if not complete:
            continue
        sheet = Image.new('RGB', (1920, 578 * len(complete)), '#15191b')
        draw = ImageDraw.Draw(sheet)
        for n, p in enumerate(complete):
            for col, variant in enumerate(['baseline', 'candidate']):
                r = p[variant]
                with Image.open(region / r['file']) as im:
                    sheet.paste(im.resize((960, 540), Image.Resampling.LANCZOS), (col * 960, n * 578 + 38))
                draw.text((col * 960 + 12, n * 578 + 10), f"{region.name} / {r['label']} / {phase} / {variant}", fill='white')
        dest = out / f'{region.name}-{phase}.jpg'
        sheet.save(dest, quality=93)
        print(dest.name, len(complete), 'pairs')
