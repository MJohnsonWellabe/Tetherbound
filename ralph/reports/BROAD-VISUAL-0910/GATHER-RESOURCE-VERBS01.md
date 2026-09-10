# Resource-specific harvest verbs

Retained correction: standing wood offers `Chop`, stone offers `Mine`, and fiber offers `Gather`. Unknown resources retain their caller-supplied label. `vegetation_harvest_point.gd::setup` binds the verb from the actual item identity, so the scatter producer's legacy blanket `Chop` label cannot misdescribe stone or fiber. No yield, tool requirement, ledger, collision or quantity changes.

Root's `retained-material-provider-diagnostic` (06:48:43–06:51:39 UTC) exposed the defect while diagnosing a failed wood-gathering route: all five nearby rejected `Chop` providers reported `resource_item=stone`. The wood filter was correctly rejecting them. This corrects the misleading production prompt; it does not by itself prove the obstructed wood route or full continuous prefix now passes.

The regression test calls actual `setup` with legacy `label=Chop` for each of wood, stone and fiber, and checks each bound Interactable label. It passed six assertions in the clean combined `geology-label-unit-fifth` run, 07:10:38–07:10:43 (five tests / 119 assertions total). Earlier combined attempts failed or were non-clean for the separate new geology fixture; the complete `gather_point_props` group also exposed its pre-existing off-tree felled-resource fixture errors. Those attempts are preserved rather than presented as clean.

The corrected prompt will also be observed by subsequent production gathering diagnostics. See `MATERIAL-ARBITER01.md` for the failed compatibility experiment, actual provider identities and the separately pending refused-stand route correction.
