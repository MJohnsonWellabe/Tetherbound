# Cloudreach Medium OFF fd2: FAILED resource guard

Source `fd2acbeff8a4dea39ae53b69dcfc9cdebb6c5e08`; run `crfd-medium-off-r1`, 2026-10-14T05:50:28.0464642Z to 2026-10-14T05:57:57.2389117Z. Locked Godot 4.7, stock Terrain DLL, exact 50 source bindings and argv independently verified. The requested Medium Forward+ 1920x1080 Cliffhold capture produced **zero frames**. No visual assessment or completed resolution proof is available.

Owned PID 56296 was stopped after available physical memory reached 2,099,372,032 bytes, below the 2 GiB floor. Recorded exit -1; no natural shutdown. Peak sampled private memory was 4,221,042,688 bytes. Commit and disk stop floors remained above their limits. Stderr is empty; this does not override the failed resource gate.

The log reports 2,235,639 grass instances, 30,379 flowers and 1,249 bushes: ground-cover generation took 361.771 seconds, reaching total startup 416.773 seconds before mounting. This supports investigation of full-world startup costs, without proving per-object allocation causality. The later read-only inventory found no Godot process and an idle lease.

[raw-bundle.json](raw-bundle.json) preserves 9 original byte-exact base64 entries: terminal receipt, both logs, admitted job/runner/admission, packet manifest/slot and independent failed review. [hash-manifest.json](hash-manifest.json) records all lengths and hashes; every payload was decoded and compared to its original. UTF-8/LF container SHA256 `8c04404e65ba3d11afa8a427e2b80cdd93bdf978e5c6b706bb8833a8b8aaf677`. Isolated homes, saves, fonts and caches are excluded.

This failed OFF diagnostic provides no capture PASS, visual acceptance, criterion closure, or permission to retry unchanged. Prior focused validation remains separately scoped. Original run evidence remains untouched.
