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

Native matched replay completed: eight stills and 160 temporal samples at
1920x1080. The independent review in `after-r1-verdict.md` accepts Fading's
new identity and preservation of readability, but still fails the full item:
Calm and Building remain too similar beneath Stormheart. The flag stays off.
No fixed status or regional bar is claimed.

Round 2 retains the accepted Fading values and changes only Building's
understory ambient color/energy, key-light energy, rain amount, wind slant and
fog contribution. The blue-green fill follows ART_DIRECTION 3.3; all sky
colors remain purple. Independent code review found no actionable defects.
Default-off surge tests passed 55 tests / 762 assertions. An ignored wrapper
subclass enabled the candidate in the existing presentation suite's returned
config, without changing the on-disk flag: 51 tests / 716 assertions passed.
Native matched round-2 review is pending.
