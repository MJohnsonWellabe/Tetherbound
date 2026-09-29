# Terrain-only caster bias comparison

Six of six native Compatibility 1920×1080 frames completed with seed 2042,
matching camera/stand and read-back shadow settings. Shader compilation logged
no errors. The base game commit is `becb28dfd`; retained `working.patch` records
the grove candidate present throughout this run, later committed as `ff843ac84`.
The diagnostic extends the two previously retained local ablations. Both dune
gates were restored false and the GPU lock released on exit.

Root full-resolution comparison:

- Raising Sun normal bias to 3.4 or 6.8 clears fine bands but visibly detaches
  the trainer shadow. Neither global adjustment is selected.
- Moving only terrain caster depth 0.02 m reduces bands but leaves fine traces.
- At 0.05 m the sand bands clear while the trainer's contact shadow remains.
  The 0.10 m case offers no necessary additional improvement in this view.
- The steep bluff still shows angular shading at its crest and foot. This is
  not a complete terrain-art pass or an independent item/chapter acceptance.

The next candidate uses 0.05 m only in the terrain shadow pass, under the dune
gate and outside Veilfall's exclusion. Visible vertices, collision, Sun settings
and other objects' caster shaders remain unchanged. Cross-island, route,
day/night and moving-camera evidence must verify its practical limits. The
mechanism and official Godot 4.7 source citations are in `source-notes.md`.
