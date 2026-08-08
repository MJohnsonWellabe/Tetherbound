#!/usr/bin/env python3
"""Lay the whole-game capture out as contact sheets that can be looked at.

    python3 tools/compose_sheet.py

Reads every frame `tools/capture_all.gd` wrote into `shots/review/`, plus the
manifest beside them, and writes:

  * `shots/review/_sheet_N.png`  — the whole run, in order, captioned with the
    frame number, its name and what the manifest says it was meant to show. One
    page per twelve frames, because a seventy-frame sheet is either unreadably
    small or too large to open.
  * `shots/review/_sheet_scale.png` — the frames that answer "how big is
    anything": the roster at true scale, the roster on the real ground, and the
    trainer beside Team Tether.

WHY THIS EXISTS, and it is not decoration. The blind visual review this project
runs (`docs/decisions/D06`, `.claude/skills/visual-judge`) hands a reviewer the
FRAMES and nothing else — no code, no conversation, no note about what changed.
A sheet is how a set of frames becomes one artefact that can be handed over and
compared against the last one. The captions carry the frame's own number so a
finding can be pinned to a file, and they carry the manifest's stated intent so
that "this shot failed to show what it was for" is a judgement anybody can make.

A FRAME THAT IS MISSING GETS A TILE ANYWAY, with its name and the word MISSING
across it. A contact sheet that quietly omits what did not render looks exactly
like a contact sheet of a run in which everything worked, which is the failure
`tools/preview_ceremony.gd` was rewritten to make impossible.
"""

import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(HERE, "shots", "review")
MANIFEST = os.path.join(SHOTS, "MANIFEST.txt")

COLS = 4
ROWS = 3
THUMB_W = 560
CAPTION_H = 62
PAD = 8
BACKDROP = (18, 20, 23)
INK = (236, 238, 240)
DIM = (150, 156, 162)
ALARM = (232, 108, 92)

SCALE_FRAMES = [
    "31-creature-roster-line",
    "32-creature-roster-field",
    "29-character-team-tether",
]


def font(size, bold=False):
    names = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in names:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def read_manifest():
    """frame filename -> (intent, problem or '')."""
    out = {}
    if not os.path.exists(MANIFEST):
        return out
    current = None
    with open(MANIFEST, encoding="utf-8") as handle:
        for line in handle:
            match = re.match(r"^(\S+\.png)\s+(\S+)\s{2,}(\S.*?)\s{2,}(.*)$", line.rstrip())
            if match:
                current = match.group(1)
                out[current] = [match.group(4).strip(), ""]
                continue
            hit = re.search(r"->\s+(PROBLEM: .*?)\s+\d+ bytes", line)
            if hit and current:
                out[current][1] = hit.group(1)
    return out


def wrap(draw, text, face, width):
    words, lines, line = text.split(), [], ""
    for word in words:
        trial = (line + " " + word).strip()
        if draw.textlength(trial, font=face) <= width:
            line = trial
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def tile(name, path, intent, problem, size):
    """One captioned cell. Draws a placeholder when the frame is not there."""
    width, height = size
    cell = Image.new("RGB", (width, height + CAPTION_H), BACKDROP)
    draw = ImageDraw.Draw(cell)

    if path and os.path.exists(path):
        shot = Image.open(path).convert("RGB")
        shot.thumbnail((width, height), Image.LANCZOS)
        cell.paste(shot, ((width - shot.width) // 2, (height - shot.height) // 2))
    else:
        draw.rectangle([2, 2, width - 3, height - 3], outline=ALARM, width=2)
        big = font(26, bold=True)
        label = "MISSING"
        draw.text(
            ((width - draw.textlength(label, font=big)) / 2, height / 2 - 16),
            label, font=big, fill=ALARM)

    head = font(15, bold=True)
    body = font(13)
    draw.text((4, height + 4), name, font=head, fill=INK)
    text = problem if problem else intent
    colour = ALARM if problem else DIM
    y = height + 23
    for line in wrap(draw, text, body, width - 8)[:2]:
        draw.text((4, y), line, font=body, fill=colour)
        y += 16
    return cell


def frames():
    if not os.path.isdir(SHOTS):
        return []
    names = [f for f in os.listdir(SHOTS) if f.endswith(".png") and not f.startswith("_")]

    def order(name):
        head = name.split("-")[0]
        return (int(head) if head.isdigit() else 9999, name)

    return sorted(names, key=order)


def sheet(names, manifest, path, cols=COLS, rows=None, thumb_w=THUMB_W, title=""):
    thumb_h = int(thumb_w * 9 / 16)
    rows = rows or ((len(names) + cols - 1) // cols)
    head_h = 40 if title else 0
    width = cols * (thumb_w + PAD) + PAD
    height = rows * (thumb_h + CAPTION_H + PAD) + PAD + head_h
    page = Image.new("RGB", (width, height), BACKDROP)
    draw = ImageDraw.Draw(page)
    if title:
        draw.text((PAD, 12), title, font=font(21, bold=True), fill=INK)

    for index, name in enumerate(names):
        entry = manifest.get(name, ["", ""])
        cell = tile(
            name[:-4], os.path.join(SHOTS, name), entry[0], entry[1], (thumb_w, thumb_h))
        x = PAD + (index % cols) * (thumb_w + PAD)
        y = PAD + head_h + (index // cols) * (thumb_h + CAPTION_H + PAD)
        page.paste(cell, (x, y))
    page.save(path)
    print("wrote %s  (%d frames, %dx%d)" % (path, len(names), page.width, page.height))


def main():
    names = frames()
    if not names:
        print("no frames in %s; run tools/capture_all.gd first" % SHOTS, file=sys.stderr)
        return 1
    manifest = read_manifest()

    per_page = COLS * ROWS
    pages = (len(names) + per_page - 1) // per_page
    for page in range(pages):
        chunk = names[page * per_page:(page + 1) * per_page]
        sheet(
            chunk, manifest,
            os.path.join(SHOTS, "_sheet_%d.png" % (page + 1)),
            title="Tetherbound — whole-game capture, sheet %d of %d" % (page + 1, pages))

    # The scale sheet, wide and tall, because a 3.4m creature beside a 1.8m
    # trainer is the one comparison a thumbnail destroys.
    wanted = []
    for stem in SCALE_FRAMES:
        match = [n for n in names if n.startswith(stem)]
        wanted.append(match[0] if match else stem + ".png")
    sheet(
        wanted, manifest, os.path.join(SHOTS, "_sheet_scale.png"),
        cols=1, rows=len(wanted), thumb_w=1400,
        title="Scale: everything measured against the 1.80m trainer")
    return 0


if __name__ == "__main__":
    sys.exit(main())
