# THINGS-TELLDUST3: the wind-up dust as one continuous low band (F38#3, F38#28 close-out)

Rows: F38#3 High 7.51 / Medium 7.47 and F38#28 High 7.47 / Medium 7.55. Each misses one preset by 0.03.

TELLDUST2 (the band lowered to 0.5 m puffs) was dropped at the GPU's by-eye check: the band did move down to the boar's feet, but it broke into separate round puffs with gaps, at Medium and on Warden 03 as well.

## Cause, and how it was confirmed

Named by the coordinator from the code and checked here by number. In `scripts/combat/tell_style.gd` each puff's alpha is `alpha * sin(PI * phase)` with `phase = time * rate + a random seed per puff`, and its size and lift follow the same phase. So every puff goes from invisible to full on its own clock, whatever the spacing: at any instant some puffs are near zero beside full ones, which is a row of beads.

`tests/test_tell_dust_phase_coherence.gd` shows it on the shipped values: with the flag off, at four sample times the faintest puff on an 8 m line is under a quarter of the brightest.

## Arm

Overlay (`overlay.json`): `combat.json telegraph.soft_style.dust_phase_coherence` 1.0, on TELLDUST2's low-band values (size 0.5 m, spacing 0.2 m, rise 0.04 m, cap 400).

Flag-off code on `tb/scene` (`dust_puff`): at coherence 1 the puffs share one slow wave along the line (8 m wavelength) instead of a random phase each. The seed is kept as a small jitter only. Size breathes between 0.9 and 1.1 of the stated size and alpha between 0.72 and 1.0 of the band's alpha, so no puff fades out and neighbours differ by under 0.08 in alpha. Lane dust no longer drifts and snaps back along the lane. With the flag at 0 the maths is the shipped formula (pinned by a test).

The band's overall alpha, its build-up over the wind-up and its pulse are unchanged, so the tell still strengthens and quickens toward the hit.

## Not shown on CPU

The wind-up dust does not draw on the CPU renderer (LANE-THINGS' note), so there is no CPU sheet. The evidence here is the per-puff numbers in the test.

## By-eye line for the GPU lane

Meadows grunt frame 03 at High: one continuous soft band at the boar's feet, with no separate round puffs and no gaps along it. Same on Warden 03. If it still reads as beads, hold the arm. If it reads as a flat hard stripe instead, tell me: `dust_wave_per_m` and the size and alpha breathing are overlay values.

## Risks and no-loss frames

- F38#11 (fight tell and hit effects, 6.95): the tell must still read as a danger cue. The painted outlines stay off.
- A steadier band is less lively than rising puffs. If the judges miss the motion, coherence 0.6 to 0.8 is the middle setting.
- F38#38 control in the same batch, as before.
