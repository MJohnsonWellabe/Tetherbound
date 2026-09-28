# P2-042 first recovery candidate

`stormwood_surge.json` contains a default-off
`presentation.phase_readability_candidate` block. It concentrates and lifts
the existing Fading steam, slows its fade to zero, and makes the existing
violet afterglow/cloud breakup more visible. Calm, Building and Break are
unchanged. Rain/wind ramps, aftermath, phase timing, strikes, flash cadence,
movement and camera behavior are unchanged.

Independent read-only code reviewer `stormwood_dialogue_review` found no
concrete bugs. The disabled path preserves the baseline; config copies do not
mutate the original rows; aftermath bypasses the phase candidate and retains
zero steam/afterglow. This is not a visual verdict.

Existing `test_stormwood_surge.gd` and
`test_stormwood_surge_presentation.gd` passed with the flag disabled (55 tests,
762 assertions) and temporarily enabled (55 tests, 760 assertions), zero
failures in both runs. The flag was restored to false after the enabled run.

Native matched replay and independent before/after review remain pending.
No fixed status or regional bar is claimed.
