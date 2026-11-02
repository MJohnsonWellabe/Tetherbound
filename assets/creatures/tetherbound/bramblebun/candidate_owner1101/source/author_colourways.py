"""Shiny and alpha colourways for the Bramblebun owner-rule remake (1 Nov 2026).

PR #793 CI (tests/smoke_bramblebun_colourway_binding.gd): with the remake ON,
ordinary, alpha and shiny all bound the plain remake albedo and the resolver
named `bramblebun_owner1101`, a colourway source with no rules. Bramblebun's
colourways are authored in data/creatures/shiny_colourways.json `bramblebun`
(`rules` -> shiny; an alpha with no `alpha_rules` inherits `vivid_rules`, the
convention of tools/repaint_creature_textures.py). This repaints the remake's
own albedo with those rules and finish, so the textures share the
remake's UVs, and writes them where creature_body._texture_for() reads a
remake's colourways: `<albedo stem>_<suffix>.png` beside the extracted .jpg.

The remake ships an albedo-derived emission map (`_arc_emission.png`); the swap
reads the colourway's glow as that map's `_<suffix>` sibling, so the same rules
(no finish pass) recolour it too. Without it the swap would self-light the
whole albedo. No `_vivid` is written: the ordinary remake keeps its look.
The leaf_ears/leaf_ruff growth overlays are left out: placed by the old mesh's
anatomy they cover 17-22% of the remake, against the owner rule's "no
full-body overgrowth", and the remake already carries its own bark, veins and
leafy tail.

    python3 assets/creatures/tetherbound/bramblebun/candidate_owner1101/source/author_colourways.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from repaint_creature_textures import SPEC_PATHS, load_spec, repaint  # noqa: E402

MODELS = os.path.join(HERE, "..", "models")
ALBEDO = os.path.join(MODELS, "creature_bramblebun_owner1101_Image_0.jpg")
GLOW = os.path.join(MODELS, "creature_bramblebun_owner1101_arc_emission.png")
SOURCE = "bramblebun/candidate_owner1101"  # anatomy for overlays: the remake's own mesh


def main():
    spec = load_spec()["bramblebun"]
    finish = {}
    for path in SPEC_PATHS:
        finish.update(json.load(open(path)).get("_finish_default", {}))
    if "finish" in spec:
        finish = dict(finish, **spec["finish"]) if spec["finish"] else {}
    for suffix, key in (("shiny", "rules"), ("alpha", "alpha_rules")):
        rules = spec.get(key) or (spec.get("vivid_rules") if suffix == "alpha" else None)
        stem = os.path.splitext(ALBEDO)[0]
        dst, share, notes = repaint(ALBEDO, rules, "%s_%s.png" % (stem, suffix), dict(finish),
                                    species=SOURCE, overlays=[])
        print("%s: %s (%.0f%% terrain-hue) %s" % (suffix, os.path.relpath(dst, ROOT), share * 100, notes))
        glow_dst, _, _ = repaint(GLOW, rules, "%s_%s.png" % (os.path.splitext(GLOW)[0], suffix), {})
        print("%s glow: %s" % (suffix, os.path.relpath(glow_dst, ROOT)))


if __name__ == "__main__":
    main()
