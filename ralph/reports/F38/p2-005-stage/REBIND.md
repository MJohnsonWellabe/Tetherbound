# Rebind the P2-005 packet after native checkout

Use this only after the root owner has completed D5 validation and switched the native checkout to the pinned `5bb435c2ded96ecbec6a4a762e231ef7d7fabac0` commit. This helper does not launch Godot, edit native source, or replace the input packet.

From the meadows checkout, invoke it with the native checkout and the packet to rebind:

```powershell
./ralph/reports/F38/p2-005-stage/rebind_p2_005_packet.ps1 `
  -NativeCheckout 'C:\CodexTemp\tetherbound-native-service' `
  -PacketPath 'D:\tetherbound\.artifacts\codex-service-meadows\p2-005-capture\capture-packet.json' `
  -OutputPath 'D:\tetherbound\.artifacts\codex-service-meadows\p2-005-capture\capture-packet.rebound.json'
```

Before writing output, it requires the exact commit, a clean Git worktree, and matching canonical object IDs for every path in the packet's `source_blobs`, `assets`, and `project_godot_blob` pins. For every path, it compares both `git rev-parse HEAD:<path>` and `git hash-object --path=<path> -- <path>` to the pinned blob. Every `source_files` entry must also have a canonical blob pin. Any mismatch aborts before output is written. The original input is copied byte-for-byte to `capture-packet.pre-rebind.json`; an existing snapshot must match the input, and existing output is never overwritten.

Only raw-byte SHA-256 fields are refreshed in the new packet: `source_files`, `assets`, both `props_sha256_by_arm` values, and `run_matrix.candidate_flag_off_sha256`. All other packet content stays byte-for-byte the same. The helper prints the OFF and ON props hashes after writing the separate rebound packet.

The ON hash is deterministic and does not depend on PowerShell JSON serialization. Starting from the exact raw `data/config/props.json` bytes at the clean OFF checkout, locate the unique ASCII member key `"p2_005_groundcover_candidate_enabled"`, skip JSON whitespace and its colon, then require the value token to be exactly lowercase ASCII `false`. Replace only those five bytes with the four ASCII bytes `true`; preserve every byte before and after the token, including a BOM or line endings. SHA-256 of the original byte sequence is the OFF hash, and SHA-256 of this one-token byte substitution is the ON hash. The source file itself is never changed.

The root owner can inspect the rebound output and then copy it into the capture artifact directory as `capture-packet.json` if the native checkout has CRLF working bytes. Keep the `.pre-rebind.json` snapshot with the receipts.
