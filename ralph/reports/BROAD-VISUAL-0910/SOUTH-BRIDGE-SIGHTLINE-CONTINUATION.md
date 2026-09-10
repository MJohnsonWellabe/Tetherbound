# South Bridge sightline continuation — 2026-09-10

Status: retained candidate after matched production-camera inspection, canonical
scatter bake, focused tests, and the real bridge interaction smoke.

## Visible result

The current gameplay-camera audit reproduced the handoff's South Bridge gap. The
held checkpoint was present, but one dark foreground canopy filled the lower-right
quarter of the frame and obscured the road, sentry, and gate as one mass.

The retained source investigation in `FOLIAGE-BACKLIGHT01-CANDIDATE.md` had already
identified that mass as three baked `CommonTree_5` saplings at approximately
`(6.309, 1294.878)`, `(6.127, 1298.240)`, and `(1.675, 1294.252)`. Their nearest
leaf-card geometry lay 0.619–4.408 m from the fixed camera. The attempted shared
foliage fade did not earn a visual preference and remains withdrawn.

This continuation adds a five-metre clearing centred at `(6, 1296)`. It removes
only those measured near-camera saplings. The matched after frame has an open
sightline from the road to the occupied crossing: the gate, banners, sentry,
barricades, landing, and continuing road read together, while the surrounding
hill and authored treeline remain intact.

The same audit found that the bridge's original grass/flower footprint was still
at its pre-OW5D coordinate, `z=80`, after the crossing moved to `z=1330`. The
historical entry is retained for the split-baseline identity contract, and a new
14.5 m footprint at the live crossing clears dynamic cover from the deck and
occupied landing shoulders without clearing the wider field.

Matched local evidence:

- before: `.artifacts/visual-audit-0910/meadows-southbridge-current/meadows__band1_lower_meadows__02__the_south_bridge__day.png`
- after: `.artifacts/visual-audit-0910/meadows-southbridge-measured-after/meadows__band1_lower_meadows__02__the_south_bridge__day.png`
- both runs used `tools/catalogue_survey.ps1`, the production Meadows scene,
  production CameraRig, ordinary HUD, the same named catalogue stand, and day.

This is a concrete sightline improvement, not commercial Meadows acceptance. The
frame still shows the broader open items: the checkpoint is small in the overall
composition, distant terrain remains sparse, ground chroma is high, and the HUD
occupies substantial right-side area.

## Integration evidence

- `test_band_vegetation.gd`, `test_scatter_fingerprint_covers_bands.gd`, and
  `test_scatter_perf_budget.gd`: 14 tests / 204 assertions / 0 failed.
- Canonical `bake_playground_scatter.gd`: 256 regions, 824,018 kept placements,
  3,585 drained placements, 29,756,871 bytes; the freshness and load-budget tests
  pass against the resulting manifest.
- `smoke_south_bridge_challenge.gd` physically brought the guardian to the player,
  opened the correct dialogue, granted the unlock, and opened the gate; it printed
  its `smoke: OK` receipt. The wrapper correctly rejected the run as globally clean
  because the harness also emitted the existing unrelated
  `the player already has a creature; adopt_starter is not a swap` engine error.

No new Meadows mesh, creature, route, collision, reward, or progression mechanism
is introduced.
