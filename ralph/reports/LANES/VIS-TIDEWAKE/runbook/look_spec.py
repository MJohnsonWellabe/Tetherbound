#!/usr/bin/env python3
"""look_spec.py <base_arm> <cand_arm> <out_dir>: 2x2 sheets (640x360 tiles) per row from /dev/shm/cap/look_<arm>/,
and a spec.json for anchor_tiles.py. Rows: F39#31 Veilfall, F39#30/#32 matrix subsets, F13#5 currents."""
import json, sys
from pathlib import Path
from PIL import Image
base, cand, out = sys.argv[1], sys.argv[2], Path(sys.argv[3]); out.mkdir(parents=True, exist_ok=True)
ROWS = [
 ("F39#31", ["F39-look/veilfall-near", "F39-look/veilfall-vista", "F39-look/veilfall-rain", "F39-look/veilfall-vista-rain"],
  "4 in-game frames (Tidewake) for one catalogue subject: the hero landmark (Veilfall) at distance and up close. Judge that subject as the game's real look - identity and read at a glance, silhouette, palette, lighting and fit with the key art and its chapter board.",
  ["The hero landmark (Veilfall) does not read as the board's towering waterfall mountain at distance and up close"]),
 ("F39#30a", ["F39-look/shore-day", "F39-look/shore-golden", "F39-look/lesson-dune", "F39-look/shore-rain"],
  "4 in-game frames (Tidewake): shore views across day, golden hour and rain. Judge the frames as the game's real look - read at a glance, palette, lighting, depth and fit with the key art and its chapter board.",
  ["Flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the frames"]),
 ("F39#30b", ["F39-look/shore-night", "F39-look/lesson-dawn", "F39-look/lesson-rain", "F39-look/veilfall-near"],
  "4 in-game frames (Tidewake): night, dawn, rain and the landmark approach. Judge the frames as the game's real look - read at a glance, palette, lighting, depth and fit with the key art and its chapter board.",
  ["Flat magenta rings or slabs, placeholder materials, floating bodies or clipping remain in the frames"]),
 ("F13#5", ["T2-current/swim-away-day", "T2-current/swim-across-day", "T2-current/swim-away-night", "F39-look/veilfall-vista"],
  "4 in-game frames (Tidewake): currents at the normal camera and the Veilfall at distance. Judge whether currents read as moving water and the landmark reads at distance, as the game's real look, against the chapter board.",
  ["Live currents use long bright evenly spaced parallel white streaks that read like guide lanes on the water surface"]),
]
def sheet(arm, frames, dst):
    im = Image.new("RGB", (1280, 720), (30, 30, 30))
    for i, f in enumerate(frames):
        p = Path(f"/dev/shm/cap/look_{arm}/{f}.jpg")
        if p.exists():
            im.paste(Image.open(p).convert("RGB").resize((640, 360)), ((i % 2) * 640, (i // 2) * 360))
    im.save(dst, quality=88); return dst
spec = []
for label, frames, brief, defects in ROWS:
    spec.append({"label": label, "a": str(sheet(base, frames, out / f"{label.replace('#','_')}_base.jpg")),
                 "b": str(sheet(cand, frames, out / f"{label.replace('#','_')}_cand.jpg")), "brief": brief, "defects": defects})
(out / "spec.json").write_text(json.dumps(spec, indent=1)); print(out / "spec.json")
