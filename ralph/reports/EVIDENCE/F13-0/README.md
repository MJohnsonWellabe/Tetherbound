# F13#0 - Tidewake segments by controller input, same five, no mount, Load after each

**Verdict: PASS** (routes-west, 2026-10-12 CT). Every piece is a fresh process with a production title Load, a handoff check (same five UIDs, flags, items, realm) and unchanged helpers. Runner: `tools/earned_saves/tidewake_piece_runner.gd`; checkpoints are in `tests/fixtures/earned_saves/tidewake_NN_*`.

| Piece | Result | Input / commit |
|---|---|---|
| 01–05 | PASS | generated arrival, then earned (tb/ev-tidewake-route, b9975478) |
| 07 human late (no mount) | **PASS** | from `tidewake_05_tidal` at L44 (disclosed `--raise-levels`); `44bbda40`, hosted |
| 08 ending | **PASS** | from the earned 07 checkpoint; `59d2963b` |
| 09 Cloudreach handoff | **PASS** | from the earned 08 checkpoint; `45a1dd6a` |

**Fight lengths in 07 (sim seconds):** Bex 183.6, Calder 252.5, Venn 205.4, Nerissa 151.6. All are hosted victories with complete opponents.

**07 results**
- Salt Crown, both Sluice controls, the Veilfall crossing and the interior controls pass.
- Nerissa's defeat releases the Guardian.
- 12 flags gained; same five UIDs throughout; no mount.

**What changed since the earlier FAIL at Venn**
- **Route pilot** (tb/ev-systems-a): `17f33eec9`, `1032b96d3`, `d83f2d3b7`. It reads F22 shapes and never charges into protected heavy attacks.
- **Veilfall walk-back** (`4470fe4e`): starts from the waypoint nearest Venn's fight; Venn stands by the landing camp.
- **Hosting** (`44bbda40`): Session.host falls back to nearby ports when 27015 is taken. Earlier concurrent runs were offline-solo, which skips host-authored durable paths.

**08:** Guardian farewell saved, currents restored, Water relic earned, same five.

**09**
- Home Key home, Tidewake relic hung, Cloudreach arch used and entered with the same five.
- It needed the permit-id nonce fix: coordinator `c1bb62ff0`, merged at `45a1dd6a`.
- Without it, the first trip after a Load re-minted a used permit id. The trip never finished: 11 of 11 grounded-arrival commits were refused as `reconcile_original_decision`.

**Disclosures**
- L44 is generated input (Rules v2 #1), the level smoke_tidewake_dry_run declares for the fixture.
- Pieces ran on the commits listed; 07 and 08 predate the 45a1dd6a merge.
- Fixtures and PROVENANCE: `tidewake_07_human_late`, `tidewake_08_ending_earned`, `tidewake_09_cloudreach_handoff`.

EV F13#0 PASS 45a1dd6a Tidewake 01–09 by controller input with the same five, no mount, Load per piece; 07 at L44 (disclosed) beats Venn and Nerissa.
