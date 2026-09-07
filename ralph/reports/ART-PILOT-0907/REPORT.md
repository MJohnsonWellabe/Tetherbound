# ART-PILOT-0907 — Galecrest

## Subject choice (recorded before generation)

**Subject:** Galecrest.

This choice follows the repository's blind verdicts rather than author preference.
`ralph/reports/JUDGE-OWNER-RUN-20260907/VERDICT.md` identifies the blue raptor as a
recoloured photoreal eagle and says the creature set needs coherent authored forms.
Galecrest is repeatedly visible from the early Meadows road onward, remains present
in later encounters, and is a single mesh rather than a family. It therefore tests
the art loop on an early, recurring, player-facing offender without conflating the
result with Burrowback's base/alpha family problem or the multi-character trainer
and villager split.

The replacement must preserve the authored identity in
`data/creatures/species.json` and `tools/art_pipeline/meshy.py`: a 2.10 m Air
creature; large powerful hawk and aerial striker; enormous broad wings with long
layered flight feathers; hooked dark beak; heavy gripping talons; slate-blue and tan
plumage over a cream chest and face; fierce focused eyes; upright commanding raptor
posture; serious predator, never a cute fox-eared glider. The target language is the
installed stylised end of the cast, especially Mosshell: clean readable forms, large
clear colour regions, restrained surface detail and appealing stylised proportions.

## Credit ledger

- Goal-wide ceiling authorised by the owner: **1,000 credits**.
- Pilot ceiling: **55 credits** (one 20-credit preview, at most one 30-credit refine,
  and one 5-credit rig).
- Balance before spend: **1,190 credits**, returned by
  `tools/art_pipeline/meshy.py balance` after the candidate verdict passed.
- Preview task: `01a07d7d-0714-704f-a434-c3801bab75da`, submitted from
  `candidates/b.png` at the one-candidate preview tier.
- Balance after preview: **1,170 credits**.
- Credits spent so far: **20**, exactly matching the preview estimate.

## Candidate and mesh verdicts

The independent code-blind candidate judge passed candidate **b** and ranked the
set `b > a > c`; see `CANDIDATE-VERDICT.md`. This accepts only the reference image.
The reconstructed mesh and its in-world fit remain unproven.

`tools/art_pipeline/meshy.py generate --image <local.png>` now provides the explicit
single-image path this authorised loop requires without overwriting the subject's
installed reference views. Its three resolver tests pass under the bundled Python.

The first generated preview was rejected by an independent code-blind judge; see
`PREVIEW-VERDICT.md`. Its wings and separate legs survived, but the one available
thumbnail did not make the defining hooked beak or broad head-to-chest transition
legible. No refine or rig request has been submitted. The next attempt is a
zero-credit multi-angle inspection of the already-downloaded GLB before deciding
whether the visible defect is real or only the supplied thumbnail angle.

That inspection is now complete and independently rejected; see
`WORLD-PREVIEW-VERDICT.md` and `world-preview/`. The four views preserve the broad
raptor silhouette but do not recover the face, feather hierarchy or authored
palette. No further paid request was submitted. The pilot remains at **20 credits**
spent and does not proceed to refine or rig.
