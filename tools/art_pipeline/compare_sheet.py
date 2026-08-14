#!/usr/bin/env python3
"""Put a candidate's renders next to the concept art it is supposed to be.

    tools/art_pipeline/compare_sheet.py terrapup \
        --candidate a=shots/candidates/terrapup-a \
        --candidate b=shots/candidates/terrapup-b \
        --out shots/candidates/terrapup-compare.png

TETHERBOUND_3D_ART_PIPELINE.md section 9 asks for candidate renders saved to a
comparison folder and compared against the equivalent concept crops, then
scored. Section 10 sets the bar the comparison is for: a player seeing the GLB
and the concept sheet side by side should immediately identify them as the same
designed character.

Nobody can hold four renders of three candidates and four concept crops in
their head at once, which is how the candidate with the nicest render wins
instead of the candidate that most resembles the drawing. So: one image, the
reference row on top, every candidate below it, same four angles in the same
order, same size.

It also emits the section 9 scorecard as a Markdown table, pre-filled with the
rows and left blank for the scores, with a HARD FAIL column. Section 9 is
explicit that a catastrophic failure is a rejection even when the aggregate is
high, so a scorecard that can only produce a total would encode the wrong rule.
"""

import argparse
import pathlib
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.exit("needs Pillow:  pip install pillow")

ROOT = pathlib.Path(__file__).resolve().parents[2]
REFERENCE_ROOT = ROOT / "assets" / "creatures" / "tetherbound"
VIEWS = ["front", "side", "back", "three_quarter"]

CELL = 384
LABEL = 30
GUTTER = 8

## The section 9 scorecard. Ten points each, and the totals are deliberately not
## computed here — see the module docstring on why a total is not the verdict.
CRITERIA = [
    ("Silhouette similarity", "Does the outline read as this creature at 40px?"),
    ("Face appeal", "Starter personality preserved, or generic animal?"),
    ("Body proportion similarity", "Head/body ratio, leg thickness, shoulder height"),
    ("Species feature similarity", "The distinctive thing: mantle, fins, ear tufts"),
    ("Material/colour similarity", "Against the sheet's own swatch strip"),
    ("Topology usability", "From inspect_glb.py, not from looking"),
    ("Rigging suitability", "Deformation zones, symmetry, limb separation"),
    ("Gameplay readability", "Holds up at combat distance on a handheld"),
]


def load_cell(path: pathlib.Path) -> Image.Image:
    """One view, letterboxed into a fixed cell so nothing shifts between rows."""
    cell = Image.new("RGB", (CELL, CELL), (28, 28, 30))
    if not path.exists():
        draw = ImageDraw.Draw(cell)
        draw.text((10, CELL // 2), "missing", fill=(200, 90, 90))
        return cell
    image = Image.open(path).convert("RGB")
    image.thumbnail((CELL, CELL), Image.LANCZOS)
    cell.paste(image, ((CELL - image.width) // 2, (CELL - image.height) // 2))
    return cell


def build_sheet(species: str, rows: list[tuple[str, pathlib.Path]]) -> Image.Image:
    width = CELL * len(VIEWS) + GUTTER * (len(VIEWS) - 1)
    height = (CELL + LABEL) * len(rows) + GUTTER * (len(rows) - 1)
    sheet = Image.new("RGB", (width, height), (18, 18, 20))
    draw = ImageDraw.Draw(sheet)

    for row, (name, directory) in enumerate(rows):
        y = row * (CELL + LABEL + GUTTER)
        colour = (255, 220, 120) if row == 0 else (200, 210, 230)
        # ASCII only: PIL's built-in bitmap font has no em-dash and draws a
        # box glyph instead, which looks like a rendering fault in an image
        # whose job is to show rendering faults.
        draw.text((4, y + 9), f"{species} / {name}", fill=colour)
        for col, view in enumerate(VIEWS):
            x = col * (CELL + GUTTER)
            sheet.paste(load_cell(directory / f"{view}.png"), (x, y + LABEL))
            draw.text((x + 6, y + LABEL + 6), view, fill=(150, 150, 160))
    return sheet


def build_scorecard(species: str, candidates: list[str]) -> str:
    header = "| Criterion | What it asks | " + " | ".join(f"{c} /10" for c in candidates) + " |"
    rule = "|---|---|" + "---|" * len(candidates)
    lines = [
        f"# {species} — candidate scorecard",
        "",
        "Scored against `docs/art/reference/` and the crops in "
        f"`assets/creatures/tetherbound/{species}/reference/`.",
        "",
        "**A HARD FAIL is a rejection regardless of the total.** "
        "`TETHERBOUND_3D_ART_PIPELINE.md` §9: *do not hide failures behind a total "
        "score.* A candidate that scores 68/80 with a face that lost the starter "
        "personality loses to one that scores 61 and did not.",
        "",
        header,
        rule,
    ]
    for name, asks in CRITERIA:
        lines.append(f"| {name} | {asks} | " + " | ".join(" " for _ in candidates) + " |")
    lines += [
        "| **TOTAL** | /80 | " + " | ".join(" " for _ in candidates) + " |",
        "| **HARD FAIL?** | §10 list — silhouette, face, plastic materials, uncanny eyes, bad deformation | "
        + " | ".join(" " for _ in candidates) + " |",
        "",
        "## §10 rejection list, checked explicitly",
        "",
        "- [ ] silhouette substantially different from the sheet",
        "- [ ] face lost the friendly starter personality",
        "- [ ] reads as an ordinary real-world animal",
        "- [ ] species feature reads as bolted-on rather than grown",
        "- [ ] proportions drifted photoreal",
        "- [ ] materials look plastic",
        "- [ ] fur/feather treatment conflicts with the rest of Tetherbound",
        "- [ ] eyes uncanny",
        "- [ ] anatomy deforms badly",
        "- [ ] stops matching the reference at gameplay distance",
        "",
        "## Chosen",
        "",
        "_Which, and why — including what the runner-up did better._",
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("species", help="terrapup, ripplet, galewisp, trainer, ...")
    parser.add_argument("--candidate", action="append", default=[], metavar="NAME=DIR",
                        help="a candidate's turntable directory; repeatable")
    parser.add_argument("--out", default=None, help="output PNG (default: shots/candidates/<species>-compare.png)")
    parser.add_argument("--scorecard", default=None, help="output Markdown scorecard")
    args = parser.parse_args()

    reference = REFERENCE_ROOT / args.species / "reference"
    if not reference.exists():
        sys.exit(f"no reference crops for '{args.species}' — run crop_views.py first "
                 f"(looked in {reference})")

    rows = [("REFERENCE (concept)", reference)]
    names = []
    for entry in args.candidate:
        if "=" not in entry:
            sys.exit(f"--candidate wants NAME=DIR, got: {entry}")
        name, directory = entry.split("=", 1)
        rows.append((f"candidate {name}", pathlib.Path(directory).resolve()))
        names.append(name)

    if not names:
        sys.exit("no candidates given; nothing to compare the reference against")

    out = pathlib.Path(args.out) if args.out else ROOT / "shots" / "candidates" / f"{args.species}-compare.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    build_sheet(args.species, rows).save(out)
    print(f"comparison: {out}")

    card = pathlib.Path(args.scorecard) if args.scorecard else out.with_suffix(".md")
    card.write_text(build_scorecard(args.species, names))
    print(f"scorecard:  {card}")


if __name__ == "__main__":
    main()
