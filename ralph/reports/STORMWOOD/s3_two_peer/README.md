# Card S3: shared state and the Water gate, in one two-process session (PASS)

```
tools/net/run_two_peer_proof.sh tools/net/proof_scenarios/stormwood_s3_integrated_two_peer.json --out=<dir>
```

`PROOF.md` shows **Verdict: PASS**, exit 0, 131 rows. That is run 4 of 4, and every negative control FAILed as intended.
- There are two real Godot processes over loopback ENet, headless.
- Saves are gzipped under `peer-*/<label>/`. The net summary and both peer logs are in `net-summary/`.

## S3 clause → rows

| Clause | Rows |
|---|---|
| Two peers build and use Arches | Rows 11–29 (grants 11–12, relights 15–19, open pair 22, closed pair 25, gated pair 27). Still lit after the restart and both rejoins: rows 88–89. Each peer relights one end of pair A with its own Stormglass: the host path, then the client path. The host steps through the lit Ashfoot arch and arrives at the Lantern Pools twin. The guest cannot pass dark pair B. The host cannot use pair C, which is behind the closed Rootgate. The lit pair is saved (`lit`), survives the host restart and both rejoins, and is in the final saved world. |
| Resolve the Dynamo | Rows 31–32, 38. The host's ending sees Marrow's defeat with both peers recorded as contributors. It frees the Stormheart through `dynamo:release`, and `long_storm_ended` and the Spark are granted on both peers. |
| Independently accept or refuse Stormheart, with stable-character receipts | Rows 35–36. The host says Yes and the guest says No through the real dialogue. Each character file carries its own `legendary_answer` receipt. Rows 102–103 check the saved characters: one Stormheart for the host, a refusal for the guest. |
| Through disconnect and reload | The host saves, then its **process restarts** and it Loads from the title. The guest rejoins as the same character, and the hashes **equal the pre-restart world** (row 71). Later the guest's link is dropped mid-session and it rejoins; the hashes are equal again (row 86). Replays are refused by the host from its own record (rows 76 and 87). Nothing is granted twice. |
| Long Storm aftermath, Spark shrine and Water key persist | Rows 50, 57–58, 72–73 and 83–84, plus the saved-world checks 98–101. These rows check the aftermath presentation on both peers after each reconnect: the Spark placed by the guest and worn by the host, the key consumed and the gate open. |
| The physical gate enters Tidewake | The guest reads the Stormheart's aftermath conversation, then unlocks the Waterward gate with one press (a negative control first shows it still sealed). After the final rejoin, the guest presses the opened gate. Row 94 shows `realm: water`, with the Stormwood outcome intact. |

## Disclosed shortcuts

- **Start:** a named host save (Meadows, Stormwood route open). The guest is a fresh trainer.
- **Setup:** satchel grants of Stormglass (host 9, guest 3).
- **Placements:** `explore_at` and `teleport` beside the Arches, the view, the gate and the Spark socket. Every press after a placement is an ordinary `interact`.
- **Dynamo fight fixture:** Marrow's defeat is committed through the ledger with both contributors. The live fight and Break are proven solo in `../full_run` (step 5) and in F11#0.
- **Host crossings:** the host makes no realm crossing after a guest reconnect. This is the known `realm_transition` epoch finding.

## Scenario fixes across runs 1–4 (harness only; no game code changed)

1. **Run 1:** FAIL at row 85. The hash changed after the guest's mid-session rejoin.
   - Diagnostic captures showed a new death satchel: the host's 6 Stormglass, at y 111 below the 262 m view platform.
   - The replay `stormheart_answer` steps (expected FAIL) teleport the trainer beside the Stormheart offer prompt. After the aftermath, that stand point lies over the tree's open interior, so the trainer fell about 150 m.
   - Fix: those replays became host-judged `stormheart_claim_again`, which needs no teleport.
   - Not claimed as a product defect: the trainer was teleported into the air, not walked.
2. **Run 2:** the guest's three reading presses arrived before the aftermath conversation had opened, so they reached the gate. Fix: `wait_context narrative_modal` before pressing.
3. **Run 3:** reproduced run 1's hash change, which gave the diagnosis above.
4. **Run 4:** PASS.
