STATUS: land (CI-blocking bug fix)
BRANCH: tb/item-feed-race-2
HEAD: (this commit)

CI failure: PR #875 run 42662569382, verify-multiplayer-shard (1), f48_coop_loop:
"feast: peer 1 fed its own Pup ()", the cap stayed 10, and no feast_feed receipt.

Root cause, from that log:
- Peer 1's f28_cook first answered owner_passive_checkpoint_pending, then
  completed.
- Peer 1's f28_feed labels were the Kitchen list ("Retry original transaction",
  "Ascension Feast 1 (ground)" ...), not the feed list.
- The "Feed creatures" button (breakthrough_panel.gd _open_feed_from_kitchen)
  went back through BreakthroughService.open_feed() into panel.open(). That
  function returns early when the input owner is not the panel
  (`INPUT.current != self`). Right after the pending checkpoint the Session held
  input, so open() returned silently and the panel stayed on the Kitchen list.
  No feed button meant nothing was fed.
- The #870 fix (rebuild on view arrival) addressed a different stale-list
  race and could not reach this one.
- A player could hit the same thing: pressing Feed in that window did nothing.

Fix: scripts/masters/breakthrough_panel.gd `_open_feed_from_kitchen` switches
the already open, visible panel from cook to feed in place (_mode, _source,
_master, then _rebuild()). It does not re-enter open() through the service. It
waits while a cook is still pending. service.open_feed() itself is unchanged and
is still used by smoke_evolution.

Tests:
- tests/test_breakthrough_panel_view_refresh.gd adds two tests: the feed switch
  happens in place without reopening, and it waits for a pending cook.
- Breakthrough panel and service tests (labels, view refresh, f28 training
  boundaries, guest master admission): 34 tests, 0 failed.

Smokes:
- f48_coop_loop x5: all ALL CHECKS PASSED. Runs 1-4 each hit the exact CI
  precondition (f28_cook answered owner_passive_checkpoint_pending twice) and
  fed correctly; run 5 did not hit it.
- f28_feast and f48_feast_feed: ALL CHECKS PASSED.
- smoke_evolution: 213 checks, 0 failures.
