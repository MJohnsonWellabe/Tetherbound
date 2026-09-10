# Shared creature repaint feathering — held

This bounded candidate replaces abrupt colour-rule boundaries with smooth
saturation/value/hue matching at softness 0.07. Earlier rules consume their
weighted share first; later rules and the source receive the remainder. RGB
composition avoids scalar hue-wrap interpolation. Existing target colours,
despeckling, value posterization, dark-feature masks and overlays are retained.
No production code, configuration, texture, alpha or shiny variant was changed.

The off-tree experiment under `.artifacts/broad-visual-0910/creature-softmatch01`
produced hard controls and candidates for Skyrill, Pebblik (`pebbik`), Cloudfang
and Torrentoad. Every hard control is byte-for-byte and pixel-for-pixel identical
to the shipped vivid PNG. Current source JPGs were verified against their GLB
images. Numeric checks cover bounded weights, sum-to-one ownership, rule
priority recurrence, circular hue wrapping, preserved alpha and unchanged
watched source files. These checks establish a controlled experiment, not an
art improvement.

The native `creature-softmatch-first` run rendered 16 frames at 1280x800 from
2026-09-10 11:15:57 to 11:16:08 UTC, exit 0 and no engine errors. Both treatments
use raw PNG ImageTextures to avoid an asymmetric importer/compression change.
They use the same actual creature body, frozen pose, material scalars, lighting
and close/distant camera. This is an isolated fixture, not habitat evidence or
a test of the eventual compressed production texture.

Fresh independent judges preferred Cloudfang's hard-control baseline (neutral
Y) narrowly and tied Skyrill. Neither found substantial genre-reference progress
or a commercial-bar pass. These findings do not support a universal rollout.
Pebblik and Torrentoad were rendered but not independently judged in this round;
their result is not inferred from the other species. The candidate is held and
no second parameter ladder is scheduled during this pass.

The final optional numeric recheck overlapped a full-world capture and consumed
about 1.1 GB of private memory. That world run reached the 90% system-commit
guard and was terminated at 11:14:43. This scheduling/resource failure is
preserved separately; it is not a creature-rendering verdict. Heavy processing
and Godot runs were serialized afterward.
