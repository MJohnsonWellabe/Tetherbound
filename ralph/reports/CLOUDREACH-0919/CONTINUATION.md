# Persistent Cloudreach grass production — resumed

Owner explicitly requested continuation until acceptance on September 19. The
persistent goal is active. The earlier R1 negative result remains evidence, not
completion of the approved plan. Keep R1 isolated from main and continue within
the grass mechanism. No gameplay or other-biome implementation.

Current main's new lane directives were read and merged as 760c4f50; those are
documentation-only changes. Cloudreach scope and plan approval remain unchanged.
Render priority now explicitly reads Meadows, Cloudreach, Combat, then survey.

## New evidence, not another arbitrary endpoint round

The R1 broad-grid role check concealed a local distribution defect. Running the
actual helper over a 15m-radius, 1m-spaced disk around each recorded player pose
produced these theoretical roles (709 samples per disk; this is the role field,
not a count of planted/visible instances):

| Stand | Low | Medium | Tall |
|---|---:|---:|---:|
| Gate | 709 | 0 | 0 |
| Three Bells | 709 | 0 | 0 |
| Beacon | 166 | 387 | 156 |
| Shrine | 414 | 295 | 0 |
| Perches | 208 | 431 | 70 |
| Cliffhold | 0 | 415 | 294 |
| Observatory | 282 | 427 | 0 |
| Summit | 709 | 0 | 0 |

Receipt: `.artifacts/cloudreach-0919/role-neighborhoods-r1.log`; exit 0.
An 83m dominant wavelength makes a nearby scene one role or a broad band. The
global 7% tall statistic does not ensure sparse tall accents around the player.
This is consistent with R1's crop-strip and absent-hierarchy verdicts.

Next experiment: small irregular coherent accent masses within a majority-low
field, checked both globally and in fixed player neighborhoods. Keep accepted
placements, RNG progression, exclusions and counts unchanged; do not introduce
location-specific exceptions. A diagnostic-only pass-ablation capture at Beacon,
Shrine and Observatory will identify layer contribution. Missing-layer images
will be labelled diagnostic and never presented for visual acceptance.

The diagnostic completed at `shots/catalogue/cloudreach-grass-ablation-r1-02/`:
three full frames plus six explicitly labelled missing-pass frames, exit 0.
The primary pass drives Shrine's crossed-blade carpet and Observatory's crowded
paving. The finishing pass drives Beacon's isolated foreground blades; primary
grass supplies its dense left fringe. These different contributions justify
retaining both passes and testing their common role distribution. No diagnostic
frame is acceptance evidence. The first diagnostic launch failed its preboot
subset-count guard; the corrected exact-site filter and fresh root are retained.

R2 code is committed as `846324f4f`. Cached, non-fractal cellular fields create
smaller irregular accent masses; existing height/width ranges, placements, RNG,
counts, route clearance and callers are unchanged. Strengthened tracked tests
inspect all 12 live catalogue neighborhoods and meaningful config switch-back.
Against R1: 5 tests / 574 assertions / 1 failing test (local roles), preserved in
`roles-local-coverage-r1-red.log`. Against R2: 5 / 574 / 0, exit 0,
`roles-local-coverage-r2.log`. Sliced construction remains 2600/20/10 with matching
CPU transforms and three budget yields, exit 0, `roles-sliced-r2.log`.
Matched full production capture is pending; structural success is not acceptance.

## CI fixture repair

Commit `a2d2f9d12` materializes exactly eight existing committed Meadows ledger
receipts in the sparse unit-test checkout. All eight are real HEAD blobs, verified
locally by Git hashes; no receipt or assertion was changed. The existing focused
ledger test passes 1 test / 16 assertions / 0 failures, exit 0,
`ci-fixtures-focused-r1.log`. Prior run 35458097381 also failed Warrens and combat
HUD smoke jobs; their logs are being investigated separately. No full-CI claim.

## Packaged verification correction

The previous UI attempt used `Start-Process -WindowStyle Hidden`, which prevented
the desktop tool from finding the window. That was a launch-method limitation,
not proof of a package defect. The unchanged 89c176fd EXE/PCK now passes
`--headless --quit --verbose`, exit 0, using packed resources; log:
`.artifacts/cloudreach-0919/package-headless-title-r1.log`. This proves only title
startup. Cloudreach geometry, actual movement and render parity remain to verify.
An isolated real save is ready; explicit visible-window permission was requested
because the host launch instruction requires it. No existing user saves changed.

## Acceptance remains open

Required: improve the targeted grass hierarchy without regression, matched full
production captures, independent code-blind review, packaged geometry sanity
check, ordinary movement observation, structural tests and required world smoke,
actual CI job review, and evidence-backed PR delivery. No grade can move from
tests or a theoretical role distribution. Other visual gaps remain outside this
grass fix and must not be silently counted as resolved.
