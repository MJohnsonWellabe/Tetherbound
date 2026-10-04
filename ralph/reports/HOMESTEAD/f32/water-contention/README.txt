F32 criterion #5 evidence: "The ten Tidewake water_crafting proposals are
registered at runtime; four-character node contention follows MULTIPLAYER."
Run 2026-10-04, Linux headless, Godot v4.7.stable.official.5b4e0cb0f, shared
checkout working tree (uncommitted; no git SHA recorded by this lane).

VERDICT
  Part A, runtime registration:      PASS
  Part B, node contention (2 peers): FAIL. Two production blockers, listed below.
  Four-character contention:         NOT PROVEN. Out of reach for a peers:2 smoke; see LIMITATION.
  Criterion #5 overall:              OPEN

-------------------------------------------------------------------------------
PART A: tests/test_f32_water_registration.gd
  godot --headless --path . --script tests/run_tests.gd -- --only=test_f32_water_registration

  only test_f32_water_registration: 1 of 769 test files
    ok    test_f32_water_registration.gd :: test_production_item_db_registers_all_water_proposals
    ok    test_f32_water_registration.gd :: test_water_crafting_config_has_exactly_ten_recipes
  2 tests, 23 assertions, 0 failed

  Method: the production constructor autoload/item_db.gd ItemDB.new(), which Game
  also uses at game_state.gd:764. Its item book (ids()/definition()) and recipe
  book (recipe_ids()/recipe()) go to
  f32_catalogue_registration.gd::water_registration_errors(). The result is
  []: all nine item proposals and all ten recipes match exactly. Each id is
  also present individually, and water_crafting.json has exactly 10 recipes.
  The registration happens in item_db.gd:65-70, which runs only on the
  default-path constructor.
  Not covered: under the --script runner the Game autoload is not stood up, so
  Game.items was not read directly. It is the same constructor.

-------------------------------------------------------------------------------
PART B: tests/smoke_net_f32_node_contention.gd   (# peers: 2)
  GODOT_BIN=/usr/local/bin/godot tools/net/run_net_smoke.sh f32_node_contention --out=/tmp/claude-0/contention
  Exit 1. 62 PASS. Failures are below.

  Path (no stubs). Both peers mount canonical F32 sites through
  foundation_resources.gd and f32_world_mount.gd. Each press is the harvest
  node's own Interactable.activated, which runs SourceService ->
  Resources.submit -> Session._foundation_send -> host host_context -> ledger
  stock CAS -> owner save/ACK.

  Disclosed fixtures: the trainers are teleported (6 m start, then 1.3 m on
  opposite sides of the node). The mount retry timer is cleared. Both peers
  save_character_here before the race. The peer steps live in a scoped
  runner: source is a constant in the smoke, written to the run dir, extending
  tools/net/peer_runner.gd. No existing file was edited.

  Race 1 [simultaneous], essence_meadows_ground_01, one shared wall-clock press.
  Race 2 [guest-first], essence_meadows_psychic_01, guest presses 400 ms
  before the host.

  These invariants PASS in both races:
    - exactly one stock revision is consumed: {revision 1, generation 2,
      next_ready_day 4}. Host and guest stock are identical, and the node reads
      depleted on both peers.
    - exactly one peer gains the outputs (+3 essence, +1 attuned). The other
      gains 0. Nothing is duplicated.
    - the winner's verdict is ok/resolved/owner_saved/owner_acknowledged. The
      winner gains exactly one receipt, and its character file has the gain and
      that receipt.
    - the loser gains no receipt, and its character file gains nothing.
    - the host world journal has exactly one accepted resource row, owned by
      the winner. The host world save on disk has the consumed stock and one
      row.
    - the loser's re-press on the depleted node is refused locally with no
      item. Host stock and journal are unchanged.

  FAIL 1 (blocker): a guest can never win. The host always does.
    [guest-first] guest armed press 1791135033799. Guest refused at
    1791135033995 with code source_or_revision_changed. Host armed press
    1791135034199. The guest was refused 204 ms before the host pressed, with
    the node ready and nothing else in flight. So "first valid claim wins"
    fails, and race 1 is not real contention either: the guest's claim is
    never admitted.
    Root cause, from the in-smoke f32_diag probe:
      host portal_runtime_ready=false; host TravelLifecycle has no observation
      for the guest ("lifecycle":{"observation":false}). The guest's
      local_sample is valid and publish_now() returns true.
      - data/config/multiplayer.json:22 sets redesign_portal_runtime_enabled to false.
      - scripts/net/session.gd:5623, in _rpc_travel_lifecycle, returns early
        when portal_runtime_ready() is false. Every guest lifecycle sample is
        dropped.
      - scripts/net/foundation_resources.gd:153 host_context: safety comes from
        lifecycle.host_context(peer), which is {}, so it returns {}.
      - scripts/net/session.gd:525 then refuses with
        _foundation_refusal("source_or_revision_changed").
    Expected: a guest within 2.6 m of a ready node is admitted, and the
    first-arriving claim commits.
    Observed: with the shipped flags, every guest F32 node or farm gather is
    refused. The gate is generic to the foundation "resource" op, so this is
    not specific to F32.

  FAIL 2: the loser's refusal reaches the HUD as a raw machine code.
    The shown text is 'source_or_revision_changed' (production run) or
    'stale_stock' (diagnostic run, real contention). The causes:
      - scripts/net/session.gd:580 _foundation_refusal sets reason equal to
        code.
      - f32_source_actions.gd:102 _deny("stale_stock") carries no reason.
      - scripts/world/harvest_node.gd:812 pushes verdict.reason verbatim to
        push_world_message.
    The smoke asserts that the shown reason is a player sentence, the same bar
    as smoke_net_farm_race.gd. A player-readable reason is needed.

  DIAGNOSTIC run. NOT acceptance evidence.
    TB_F32_DIAG_PORTAL_FLAG=1 GODOT_BIN=/usr/local/bin/godot tools/net/run_net_smoke.sh f32_node_contention --out=/tmp/claude-0/contention
    This sets the host's in-memory session config redesign_portal_runtime_enabled=true.
    Result: 64 PASS. The only failure is FAIL 2 (shown 'stale_stock').
    [simultaneous]: host wins. The guest is refused stale_stock: real CAS
                    contention (shape A).
    [guest-first]:  the guest wins: "the first valid claim (peer 1) is the one
                    that won". The guest's owner save/ACK, receipt and disk gain
                    all PASS. The host's later press finds the node depleted
                    (shape B) and sends nothing.
    So once the lifecycle gate admits guests, the contention path itself is
    correct. The two blockers above are what remain. (This diagnostic ran
    before a cosmetic edit that removed a publish_now() call from the diag
    probe. No asserted path changed.)

LIMITATION: four characters
  MULTIPLAYER §9: two-peer PR coverage covers world-ledger races. Three- and
  four-peer runs belong to the owner kit and nightly. A "# peers: 4" smoke
  stays out of PR CI because four Meadows boots measured 12.85 GB
  (smoke_net_four_peer_session.gd). This smoke proves two characters on one
  node only. It does not show four simultaneous claimants producing one
  commit and three clean refusals. That needs a peers:4 variant on the
  nightly/owner kit, and it is blocked by FAIL 1 anyway.

== Re-run after a898ca39 (guest travel samples decoupled from the portal flag) ==
Command: GODOT_BIN=/usr/local/bin/godot tools/net/run_net_smoke.sh f32_node_contention --out=<dir>
Shipped config (redesign_portal_runtime_enabled=false), no diagnostic flag. Exit 0, 68 PASS, 0 FAIL.
- [simultaneous] host wins; guest refused stale_stock, HUD sentence "Someone else gathered this first."
- [guest-first] guest wins with its own save/receipt/disk gain; host's later press finds the node depleted.
- New check: on both peers portal_runtime_ready=false, home_key_refusal "The Home Key is not ready yet.",
  request_portal_action -> {ok:false, "Travel is not ready yet."}.
- The loser HUD check now asserts the text harvest_node.gd actually pushes (f32 refusal_reason(verdict)).
Verdict: F32#5 PASS for two characters. Four-claimant run remains owner-kit/nightly scope (MULTIPLAYER §9).
