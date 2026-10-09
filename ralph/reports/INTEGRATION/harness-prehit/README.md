# Live pre-hit harness witness

The guest can receive a normal host-resolved enemy hit before the smoke emits its explicit test strike. The old assertion required the guest to remain unhit throughout live asynchronous setup. The revised test polls at most 120 physics frames and accepts only coherent evidence of either unchanged bare HP with no incoming hits, or an actual positive incoming counter with exact authored host-scale damage, displayed HP fraction and serialized base maximum. Live attacks remain active. Every later explicit-hit and flee guard is retained.

Source `97a4d7bad060b6fb2e1e54eb7795e65ad78663b2` is current main `6add9d5f9b9f490bf8a77783d3afa21474cdb50d` plus only three test/helper files. Config and default changes: none; feature flips: zero.

Actual affected units: [38001887195](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/38001887195), 6 tests / 20 assertions / 0 failed, exit 0, 8 seconds, three original logs without errors. Actual two-peer proof: [38002597870](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/38002597870), both original peer SHA handshakes and normal exits, all checks passed, exit 0, 116 seconds, six original logs without errors. Original artifact IDs and SHA256 values are retained in receipt.json.

The native sample exercised bare-before-first-hit, then a real connected explicit host strike with scale 1.264. Positive-prior-hit arithmetic has causal unit coverage but was not observed in this sample. The canonical serialized party row is not an independent disk-durability witness. Independent root source/runtime review approves this isolated infrastructure correction. No Relay/Hall or other whole criterion closes from this change. Required full CI remains the integration gate.
