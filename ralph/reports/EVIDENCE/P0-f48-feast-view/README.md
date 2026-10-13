# P0 f48 feast feed (#681 blocker): smoke_net_f48_coop_loop "peer 1 fed its own Pup"

Systems lane, tb/ev-systems, Mon 12 Oct 2026, 11:45 PM CT.

## Symptom
CI run 38337179074 (net-smoke-runs-1), reproduced locally once in 3 runs (with the
boss-rewards fix in place): the guest's first cook returns owner_passive_checkpoint_pending,
the retry saves, then the feed list holds only "Back". The Pup stays at cap 10 and no
feast_feed receipt is written.

## Root cause
A guest's Kitchen lists are built from Session's cached personal view
(_foundation_personal_cache). view() returns that cache at once and asks the host for
a new one. The panel rebuilds on arrival only when it was built with no view. After a
cook settles, the cache still predates the cook (no feast_t1_ground). When the feed
list opens before the fresh view lands, it offers no Pup, and nothing rebuilds it.
A player sees the same dead list.

## Fix (product, session.gd)
A settled feast_cook or feast_feed answer drops the guest's cached view and requests
a fresh one (the camp_build precedent). The panel then shows "not ready" and rebuilds
when the fresh view arrives. The Kitchen open waits for that view, as a player would.
The smoke and its helpers are unchanged.

## Proof
- f48_coop_loop 3/3 PASS with the fix (runs 4-6). Every run hit the checkpoint-refused
  first attempt that preceded the failure, and the guest then fed its Pup.
- f28_feast 1/1 PASS (same Kitchen/feed path).
