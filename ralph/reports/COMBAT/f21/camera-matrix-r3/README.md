# F21#4 size matrix r3 (in-container, pre inset-fade)

Source: see SOURCE.txt (fade on whole envelopes, foreground_fade 0.75). Tool:
`tools/capture_f21_size_matrix.gd` under xvfb + llvmpipe, gl_compatibility,
Low preset, 1920x1080, `--fixed-fps 60`. 9 pairs x 4 stills; `matrix.json`
holds each camera solution: all 36 framed, overlap 0, HUD clear, lens
9.5-23.9 m (none at the 39.5 m cap). Frame times are software rendering and
are not quoted.

Code-blind judge (fresh sub-agent, pixels only, all 36 viewed): **PASS**, all
nine pairings. Report: `judge.txt`. Its one actionable defect (a trainer
dithered while beside, not in front of, the ally in 03-060/071) is fixed in
the following commit (inset fade envelopes) and re-captured as r4.
