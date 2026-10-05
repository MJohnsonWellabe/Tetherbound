# Oskar refusal: frame-bounded cooperative-deadline retry

Coordinator ruling (2026-10-04): "Change the harness to yield and retry the query on the next
frame, bounded by a frame count (not wall time), and log every deferral count. Keep the failure
if the walker still can't reach Oskar within the existing step budget. The identity and
contact-saturation guards stay hard refusals."

## Change (`tests/helpers/opening_geometry_navigator.gd`)

- Every wall-clock cooperative deadline now defers instead of refusing. These are the native
  query budget, the post-query frame deadline, the starting-overlap deadline, the deadline before
  stick input, input dispatch, the pre callback and the observation callback. A deferral releases
  the stick (a zero-stick flush in production) and retries on the next physics frame.
- The bound is `MAX_DEFERRAL_FRAMES = 30` *consecutive* deferred frames, a frame count. Frame 31
  refuses: `cooperative deadline exceeded on N consecutive frames (<where>; T deferred frames total)`.
  An on-time frame resets the consecutive run, not the total.
- Every deferral prints `OPENING_NAV_DEFERRAL {where,total,consecutive,cap_frames}`, and
  `deferral_count()` exposes the total.
- Deferred frames still spend the caller's unchanged `walk_to` budget, so a walker that can't reach
  Oskar in budget still fails. They don't count toward the 90-frame stall cap, because the stick
  was released.
- Hard refusals are unchanged: body identity, contact saturation, starting-overlap
  saturation/registration, and the deterministic per-frame/lifetime query *count* caps. The count
  caps were split out of the old combined "count/lifetime/cooperative deadline cap" message.
- Refusals later in a deferred callback are artifacts of its blocked queries. They release the
  stick but don't refuse (`_halted()`). The observation that follows a deferred pre callback still
  validates the controller's actual movement in full, on its own 10 ms allowance.

## Proof

- `tests/test_opening_geometry_navigator_deferral.gd`: 3 tests, 9 assertions, 0 failed. Covers one
  deferral per frame, an on-time frame resetting the run but not the total, and exactly 30
  consecutive deferred frames being retried before frame 31 refuses.
- `tests/test_opening_geometry_navigator_low_prop.gd`: still 2/8 passing.
- Real production-steering walk, `tests/smoke_f17_legacy_circle.gd` (farmhouse door → Main Street
  → Hall nave → four relic slots):
  - `circle.keylines.txt`, shipped 10 ms cap: PASS, 0 deferrals.
  - `circle_1600.keylines.txt`, cap edited locally to 1.6 ms (not committed): PASS with 24
    deferrals, at most 4 consecutive. The old guard would have refused on the first one.
  - `circle_900.keylines.txt` (0.9 ms) and `circle_forced.keylines.txt` (0.4 ms), also local only:
    105 and 31 deferrals, then the bounded refusal after 31 consecutive frames. This shows the
    bound holds and the refusal is logged with its total.
- F02#1 (Oskar), on the earned harness, runs in the earned session against this SHA.

## Independent review M1 fix (post-merge head)

The final independent review (`../final-independent-review.md`) found that a deferral in the post-physics observation's
live query also skipped that frame's grounded-floor, slide/contact-cap and movement-bound checks. Those read cached
controller state and make no native query. Fix: only the live query defers. Those checks now run and refuse hard after a
deferral (`live_deferred`), and `_checked_start` stays false for that frame. `_motion` now checks contact saturation before
the deadline, so a late saturated query still refuses.

Re-proof:
- Unit deferral 3/9 and low-prop 2/8 pass. `smoke_home_creature_bed` OK.
- `circle_after_m1.keylines.txt`, shipped 10 ms cap: PASS with 1 deferral.
- `circle_1600_after_m1.keylines.txt`, forced 1.6 ms cap (local only): refuses after 40 deferrals with
  `actual production walk lost grounded floor` at the raised Cloudreach relic plinth (body y 2.96, stick driven, on an
  on-time frame). This is the hard guard working: the frequent stick releases forced by the artificial cap change the
  approach path. **The earlier 1.6 ms PASS above was partly M1 masking this guard, so treat it as superseded.**
