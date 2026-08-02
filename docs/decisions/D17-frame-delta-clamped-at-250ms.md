# D17. Frame delta is clamped at 250 ms

Kind: implementation

A tab restored after five minutes in the background reports a 300 second delta.
Unclamped, the accumulator owes 18,000 fixed steps in one frame, the page
locks, the next delta is larger still, and the loop never recovers.

Clamping means a backgrounded tab resumes with a small time skip rather than a
hang. Covered by `tests/loop.test.ts`.
