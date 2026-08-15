#!/usr/bin/env python3
"""One-off crop tool for EV9's still-owed handheld-scale icon legibility
judge (BACKLOG.md EV9 remainder: HP/Stamina/Pals glyphs wired 2026-08-14,
"not yet run through a blind-judge round on sizing/legibility at handheld
scale... self-verified by render only").

Crops the three HUD icon glyphs at their true native-render pixel size
(the frames are captured at 1920x1080, the Ally's own native resolution,
so a pixel in the render IS a pixel on the physical device -- no scaling
assumption needed) from tools/capture_exploration_hud.gd's output, plus a
4x nearest-neighbour blowup of each crop so the icon's actual shape is
inspectable without smoothing inventing detail that is not there.

Icon screen positions/sizes read directly from scripts/ui/playground_hud.gd:
  hp_heart      (30, 978)  size 18x18  (VITALS_POS + hp_icon.position)
  stamina_bolt  (1023, 436) size 18x18 (STAMINA_ARC_POS + stamina_icon.position)
  creatures_paw (50, 816)  size 20x20 (CREATURE_BLOCK_POS + creature_icon.position)

Not part of the shipped game -- a throwaway analysis script for this pass.
"""
from PIL import Image
import os

SRC = "shots/_diag"
OUT = "shots/_diag/icon_crops"
os.makedirs(OUT, exist_ok=True)

ICONS = {
    "hp_heart": (30, 978, 18, 18),
    "stamina_bolt": (1023, 436, 18, 18),
    "creatures_paw": (50, 816, 20, 20),
}

# frame -> which icons are actually visible/active in that state
FRAMES = {
    "hud_full": ["hp_heart", "creatures_paw"],
    "hud_sprint": ["hp_heart", "stamina_bolt", "creatures_paw"],
    "hud_lowstam": ["hp_heart", "stamina_bolt", "creatures_paw"],
    "hud_hungry": ["hp_heart", "creatures_paw"],
    "hud_lowhp": ["hp_heart", "creatures_paw"],
}

PAD = 40  # context margin around the icon's exact bounds, in native px
UPSCALE = 4

for frame, icons in FRAMES.items():
    path = os.path.join(SRC, f"{frame}.png")
    if not os.path.exists(path):
        print(f"MISSING {path}")
        continue
    img = Image.open(path).convert("RGB")
    for icon in icons:
        x, y, w, h = ICONS[icon]
        # tight crop: exact icon bounds only, native pixels, no context
        tight = img.crop((x, y, x + w, y + h))
        tight_path = os.path.join(OUT, f"{frame}__{icon}__tight_{w}x{h}native.png")
        tight.save(tight_path)

        # upscaled (nearest, no smoothing) so the shape is inspectable
        up = tight.resize((w * UPSCALE, h * UPSCALE), Image.NEAREST)
        up_path = os.path.join(OUT, f"{frame}__{icon}__{w}x{h}native_at_{UPSCALE}x.png")
        up.save(up_path)

        # context crop: icon plus surrounding HUD, native scale, for placement/contrast judgment
        cx0, cy0 = max(0, x - PAD), max(0, y - PAD)
        cx1, cy1 = min(img.width, x + w + PAD), min(img.height, y + h + PAD)
        ctx = img.crop((cx0, cy0, cx1, cy1))
        ctx_path = os.path.join(OUT, f"{frame}__{icon}__context_native.png")
        ctx.save(ctx_path)

        print(f"{frame:12s} {icon:14s} -> tight {tight_path}, x{UPSCALE} {up_path}, context {ctx_path}")

print("done")
