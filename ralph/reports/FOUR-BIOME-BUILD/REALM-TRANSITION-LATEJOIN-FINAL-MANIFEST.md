# Final scoped latejoin integration manifest

2026-09-09. Exactly six changed source/test/runner files after the retained cancellation snapshot. No lane commit, push or branch change. Final focused tests29/154 pass; native82 precedes the final revision-ACK correction and is not relabeled as exact-final-source acceptance.

| Path | Final SHA256 |
|---|---|
| `scripts/net/realm_spawn_origins.gd` | `12009505CDA468AD9A13C23C73D220F0FC511B42E0D70B0B8A505CA047665838` |
| `scripts/net/realm_transition.gd` | `B4159D3BE17E69E0EF479C5EC2D62BA798A482FFD8667AE8CA60DC501FA60A9F` |
| `tests/test_realm_spawn_origins.gd` | `0A85776451CA136C4F033841DDAE5FAC16D231E64B7A172DB2121D3FC3AE1A45` |
| `tests/test_realm_transition.gd` | `1F9D1A3B055253EA531BEDEF42016E9A6D47D7C2D0E23F4895A2AC629DC58AF1` |
| `tools/probe_realm_transition_adapter_peer.gd` | `86994808E5EE1A410A430E854089B5DA8FDEBE67F0EBC868FA88E6143D90E582` |
| `tools/run_realm_transition_adapter.ps1` | `B4E7FE7D05017D0475CDD4C4198BF2A067A65EC90610AAE1E3AA8F474E0300CA` |

Reports: REALM-TRANSITION-LATEJOIN-PROOF-BRIEF.md; REALM-TRANSITION-ORIGIN-RECEIVER-REPAIR-BRIEF.md; REALM-TRANSITION-LATEJOIN-IMPLEMENTATION.md; REALM-TRANSITION-LATEJOIN-NATIVE-FIRST-ATTEMPT.md; this manifest. Image-only reviews VISUAL-WAVE4/5 are separate evidence, not gameplay implementation.

Native first-candidate and focused logs remain under .artifacts. Root-authored CI wrapper is outside lane ownership. No new Godot run after final ACK-focused verification. Exact-head CI and shipping review remain open.
