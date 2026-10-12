# F11#3 Long Storm aftermath and Spark/shrine persist: PASS (re-proved; guest Home Key intermittent root-caused)

**Latest:** `f0df968bc0` (`run_f0df968bc0/`, 2:09–2:29 PM CT, the portal NOT_READY fix; exit 0, no `[portal]` NOT_READY or drop line fired), `71f9702e4` (`run_71f9702e4/`, 1:21–1:41 PM CT, after the realm-load speed-ups), `8a05758ba` (`run_8a05758ba/`, started 10:18 AM CT) and `c965b210c` (9:14–9:40 AM CT); times from the run ids (UTC) converted to CDT, Godot 4.7 headless, two real processes. Exit 0, 0 FAIL (`run_c965b210c/PROOF.md`). First pass: `c1bb62ff0`, Sun 11 Oct, 99/0 (`aftermath_shrine_two_peer_reload_rejoin/`). Command: `tools/net/run_two_peer_proof.sh <scratch>/stormwood_f11_aftermath_shrine_two_peer_reload_rejoin.json`.

**Proven:**
- The Long Storm ends through the real path; both peers show the aftermath; one Stormheart answer per character.
- RD-17 crossings: Home Key home and the Hall arch back.
- The guest places the Spark and the host wears it.
- After a host process restart (title Load hosts again) and a guest rejoin: world hashes agree and equal the pre-restart hash (the clock-free hash exact; day ±1; harvested plants only regrow), and aftermath, Spark and answers reconstruct.
- The same holds after a mid-session drop and rejoin; replays grant nothing. Saved files hold it against a non-vacuous baseline.

**Game fixes found by this proof (each with unit tests):**
- e2fc28e6b / 4394e1c11: owner-fence travel baseline.
- e3ae38346 / b5433c3ed: host crossing record for damage_revision rollback.
- c1bb62ff0: travel permit ids carry a per-process nonce.
- e490594e6: a guest back at the title in the same process rejoins as its portable character. Its solo fallback autosave had put it in Meadows instead of its Stormwood spot (#56).
- f0df968bc0: a well-formed portal request reaching a transiently unready host (no world mid-swap, character not yet bound mid-rejoin) gets NOT_READY so the arch/Home Key resend it, instead of no reply (the #43 no-reply in `REALM-LOAD/`); invalid ones still drop. Test `test_portal_request_not_ready`.

**Helper changes (no assertion loosened):** 95ead78f6 (#54 clock-free hash exact; day and harvested plants with tolerance); 0fc4fb4ad / fae2bb6ed / c965b210c (the Home Key helper names a stalled press's block or refusal).

**Root-caused (8a05758ba):** the guest's intermittent Home Key failure.
- The host failed a crossing 120 s after the receiver began loading. This guest's Meadows build takes 106–112 s here, plus settle time.
- In `fail_35_transition_timeout/` the guest built Meadows, was failed mid-load and rolled back ("The destination could not load.").
- Fix: a loading receiver pings every 5 s; the host extends that deadline (cap 10 min; a silent receiver still times out at 120 s). Unit test in `test_realm_transition.gd`.
- `run_8a05758ba/` passes in full (exit 0). Its build was 106 s, so it shows no regression rather than reproducing the slow case.

**Disclosed:**
- Fixtures: the named host save, the initial Hall portal fixture with one Home Key, and the Dynamo fixture.
- Scratch copy with scaled budgets only: step frames max(4x, 12000), build allowance 600 s, `budget_s` 4x, portal frames x3.
