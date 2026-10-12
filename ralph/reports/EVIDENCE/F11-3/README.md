# F11#3 Long Storm aftermath and Spark/shrine persist: PASS (re-proved), one open intermittent

**Latest:** `tb/ev-coop-chapters` @ `c965b210c`, Mon 12 Oct 9:14–9:40 AM CT, Godot 4.7 headless, two real processes. Exit 0, 0 FAIL (`run_c965b210c/PROOF.md`). First pass: `c1bb62ff0`, Sun 11 Oct, 99/0 (`aftermath_shrine_two_peer_reload_rejoin/`). Command: `tools/net/run_two_peer_proof.sh <scratch>/stormwood_f11_aftermath_shrine_two_peer_reload_rejoin.json`.

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

**Helper changes (no assertion loosened):**
- 95ead78f6: #54 compares a clock-free hash exactly; day and harvested plants with tolerance.
- 0fc4fb4ad / fae2bb6ed / c965b210c: the Home Key helper names the block or refusal when a press stalls.

**Open:** in two of the last three runs the guest's Home Key failed once, at a different step each time.
- #70 (e490594e6): the rejoined guest's input stayed held for the whole budget.
- #35 (0fc4fb4ad): the press was refused locally with no host request.

This run passed both; the cause is not yet found. Reruns with the new diagnostics continue.

**Disclosed:**
- Fixtures: the named host save, the initial Hall portal fixture with one Home Key, and the Dynamo fixture.
- Scratch copy with scaled budgets only: step frames max(4x, 12000), build allowance 600 s, `budget_s` 4x, portal frames x3.
