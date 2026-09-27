# No-hold Fly (tap pulse) — held, reverted on tb/cloudreach

The owner ruling on #356 (issuecomment-5853566761, 2026-09-27 06:58) makes
held climb and descend lawful Fly input and makes the tap pulse optional. It
tells Cloudreach to stop the tap-pulse work. The two commits (4d99bb7c, the
no-hold flight; 28a3976c, typed harness locals) are therefore reverted on
`tb/cloudreach`. Behaviour is main's again: hold A in a marked updraft to
climb, hold LT/C to descend. The `input_owner.gd` traversal owner (X03,
f80cd473) stays.

What the patches did, in case the pulse is wanted later (`git am` both):
- A tap gave a 0.5 s pulse at 8 m/s (climb stamina 1.6/s). A fresh tap
  refreshed it and never stacked, and holding did not repeat it.
- A tap inside an updraft rode that current to its roof.
- LT toggled descent.
- `climb_pulse_seconds` / `climb_pulse_mps` were in fly_traversal.json.
- It shipped with test_cloudreach_fly_no_hold.gd (unit) and
  smoke_cloudreach_fly_no_hold.gd (16/16 on real input), and the route
  harnesses tapped via `_fly_intent`.

Note for Question B (the Voss overfly): the pulse climbs outside updrafts, so
re-measure the pre-Voss overfly if it returns.
