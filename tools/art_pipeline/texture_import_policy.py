#!/usr/bin/env python3
"""Keep shipped 3D textures on Godot's VRAM-compressed import path.

Godot writes texture policy into each source image's ``.import`` sidecar. The
headless art pipeline does not open the editor scene that normally triggers
``detect_3d/compress_to``, so new creature and character textures used to stay
Lossless (``compress/mode=0``) indefinitely.

Usage from the repository root::

    python tools/art_pipeline/texture_import_policy.py --check
    python tools/art_pipeline/texture_import_policy.py --apply
    godot --headless --path . --import

``--apply`` changes only the two policy parameters. Godot must then reimport so
the generated ``path.s3tc``, destination and metadata fields match mode 2. UI
art stays Lossless, and generator inputs under ``reference/`` are excluded
because they are not runtime 3D textures and are protected by ``.gdignore``.
The unsuffixed extracted generator inputs are excluded for the same reason.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
from collections.abc import Iterable


ROOT = pathlib.Path(__file__).resolve().parents[2]
# Match horizontal whitespace only. ``\s`` also consumes the following newline
# and made an idempotent policy pass remove the final newline from sidecars.
MODE_RE = re.compile(r"(?m)^compress/mode=(\d+)[ \t]*$")
DETECT_3D_RE = re.compile(r"(?m)^detect_3d/compress_to=(\d+)[ \t]*$")
VRAM_PATH_RE = re.compile(
    r'(?m)^path\.(?:s3tc|bptc)="[^"]+\.(?:s3tc|bptc)\.ctex"[ \t]*$'
)
GENERATOR_INPUT_RE = re.compile(
    r"/models/[^/]+_extracted_(?:base_color|emissive)\.png\.import$"
)


def is_runtime_3d_sidecar(path: pathlib.Path, root: pathlib.Path = ROOT) -> bool:
    """Return whether *path* controls a shipped 3D texture.

    Runtime images live below ``assets/``. Deliberately Lossless groups do not:
    UI art (including portraits and controller glyphs), generator reference
    crops, and unsuffixed extracted generator inputs. Keeping the
    classification path-based makes it stable in the same headless environment
    that caused the regression.
    """

    try:
        relative = path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return False
    if not relative.startswith("assets/") or not relative.endswith(".import"):
        return False
    if (
        relative.startswith("assets/ui/")
        or "/reference/" in relative
        or GENERATOR_INPUT_RE.search(relative) is not None
    ):
        return False
    try:
        return 'importer="texture"' in path.read_text(encoding="utf-8")
    except (FileNotFoundError, UnicodeDecodeError):
        return False


def sidecars(paths: Iterable[pathlib.Path], root: pathlib.Path = ROOT) -> list[pathlib.Path]:
    found: set[pathlib.Path] = set()
    for candidate in paths:
        candidate = candidate.resolve()
        if candidate.is_dir():
            found.update(candidate.rglob("*.import"))
        elif candidate.name.endswith(".import"):
            found.add(candidate)
    return sorted(path for path in found if is_runtime_3d_sidecar(path, root))


def mode(path: pathlib.Path) -> int | None:
    match = MODE_RE.search(path.read_text(encoding="utf-8"))
    return int(match.group(1)) if match else None


def is_reimported_for_vram(path: pathlib.Path) -> bool:
    """Require mode 2 and the generated fields proving reimport completed."""

    text = path.read_text(encoding="utf-8")
    detect_3d = DETECT_3D_RE.search(text)
    return (
        mode(path) == 2
        and '"vram_texture": true' in text
        and '"imported_formats": ["s3tc_bptc"]' in text
        and VRAM_PATH_RE.search(text) is not None
        and detect_3d is not None
        and int(detect_3d.group(1)) == 0
    )


def apply_policy(paths: Iterable[pathlib.Path], root: pathlib.Path = ROOT) -> list[pathlib.Path]:
    """Set explicit mode-2 policy on eligible sidecars and return changes.

    ``detect_3d/compress_to`` is reset to disabled because the importer only
    uses that field while waiting for an editor scene scan to choose a mode.
    Headless installs do not get that scan; leaving the pending value in place
    would make mode 2 depend on the very detection path this tool replaces.
    """

    changed: list[pathlib.Path] = []
    for path in sidecars(paths, root):
        text = path.read_text(encoding="utf-8")
        if len(MODE_RE.findall(text)) != 1:
            raise ValueError(f"texture sidecar has no single compress/mode: {path}")
        if len(DETECT_3D_RE.findall(text)) != 1:
            raise ValueError(f"texture sidecar has no single detect_3d/compress_to: {path}")
        updated = MODE_RE.sub("compress/mode=2", text, count=1)
        updated = DETECT_3D_RE.sub("detect_3d/compress_to=0", updated, count=1)
        if updated == text:
            continue
        path.write_text(updated, encoding="utf-8", newline="\n")
        changed.append(path)
    return changed


def violations(paths: Iterable[pathlib.Path], root: pathlib.Path = ROOT) -> list[pathlib.Path]:
    return [path for path in sidecars(paths, root) if not is_reimported_for_vram(path)]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument(
        "--check",
        action="store_true",
        help="fail unless every runtime 3D texture is fully reimported for mode 2",
    )
    action.add_argument(
        "--apply",
        action="store_true",
        help="rewrite runtime 3D texture sidecars to mode 2",
    )
    parser.add_argument("paths", nargs="*", type=pathlib.Path, default=[ROOT / "assets"])
    args = parser.parse_args()

    targets = args.paths or [ROOT / "assets"]
    if args.apply:
        changed = apply_policy(targets)
        print(f"updated {len(changed)} runtime 3D texture import sidecar(s)")
        if changed:
            print("run Godot --headless --path . --import to rebuild imported payloads")
        return 0

    broken = violations(targets)
    if broken:
        for path in broken:
            print(path.relative_to(ROOT).as_posix())
        print(
            f"FAIL: {len(broken)} runtime 3D texture import sidecar(s) are not fully "
            "reimported for mode 2"
        )
        return 1
    print(f"PASS: {len(sidecars(targets))} runtime 3D texture import sidecar(s) use mode 2")
    return 0


if __name__ == "__main__":
    sys.exit(main())
