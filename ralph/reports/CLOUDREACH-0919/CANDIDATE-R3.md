# Cloudreach R3 — role-specific proportional widths

Status: implementation/validation underway within the approved grass plan.
No acceptance or named-location promotion.

R2 improves Beacon and Summit and modestly helps Observatory and Shrine, but its
new medium/tall masses regress Three Bells. The plan explicitly called for
role-specific bounded width ratios; R1/R2 instead share the same 2.5–2.9 range.
This unfinished part of the mechanism has a concrete geometric consequence.

The retained seven-blade tuft spans approximately 0.532m X, 0.515m Z and 0.98m
height. With the existing proportional multiplier, medium tufts span roughly
0.86–1.31m and tall tufts 1.20–1.70m before shader lean, despite tall grass standing
only about 0.88–1.08m high. Introducing those roles into Three Bells' formerly low
field makes the accents broader as well as taller. The blind verdict describes
that larger mass and broad-blade regression. This is a width-by-role issue, not
evidence for more height, density, count, tip, arc, clearance or location overrides.

R3 preserves R2's field and every height endpoint. It preserves the low-role width
range so quieter ground cover is not changed again. Medium and tall roles get
bounded ratios chosen before implementation:

| Effective role | X/Z scale divided by height scale | Approximate unbent footprint |
|---|---:|---:|
| Low | 2.5–2.9, unchanged | 0.53–0.93m |
| Medium | 1.9–2.3 | 0.66–1.04m |
| Sparse tall | 1.5–1.9 | 0.72–1.11m |

These bounds are relative to the retained mesh at patch height multiplier 1.
Wind/lean can extend tips; this table is not an animated envelope or visual pass.
Tall demotion must happen before selecting both height and width bounds, so route
demotion produces exactly the medium role. All RNG draws, accepted positions,
counts, non-grass transforms, exclusions, callers and shared assets stay fixed.

Validation: preserve field/generation tests and add effective-role width and
demotion checks, then sliced construction, matched full eight-site day/night
capture, independent code-blind comparison including Three Bells and Summit
regression checks. Repeat the corrected supported movement probe on the selected
candidate. Packaged parity and CI remain required. Keep R1/R2 negative evidence.
Do not turn bounded grass gains into a claim that architecture, night atmosphere,
ground overlays or the entire reference bar are fixed.
