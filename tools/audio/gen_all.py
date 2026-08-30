#!/usr/bin/env python3
"""Regenerate every audio asset in the game.

    python3 tools/audio/gen_all.py

Runs in a few seconds and is deterministic: with no source change, the .wav
files it writes are byte-identical to the committed ones. That property is the
point -- it means `git status` after a run is the honest answer to "has anyone
hand-edited an asset", and it keeps the committed binary diff proportional to
the source change that caused it.

The .wav files ARE committed, so nothing in CI or in a build runs this. numpy is
a tool-time dependency only, the same as it is for `tools/repaint_creature_textures.py`
and the other nine scripts in `tools/` that use it.

`gen_ui_cues.py` is deliberately NOT called from here. It predates this lane,
writes to `assets/ui/audio/` rather than `assets/audio/`, and uses the standard
library alone; rerunning it from here would create a second owner of files this
lane did not author. Run it directly if the UI cue set changes.
"""

from __future__ import annotations

import time

import gen_ambience
import gen_creatures
import gen_music
import gen_sfx


def main() -> None:
    for label, module in (
        ("ambience layers", gen_ambience),
        ("world and combat sfx", gen_sfx),
        ("creature voices", gen_creatures),
        ("music cues", gen_music),
    ):
        started = time.time()
        print(f"{label}:")
        module.main()
        print(f"  ({time.time() - started:.1f}s)")


if __name__ == "__main__":
    main()
