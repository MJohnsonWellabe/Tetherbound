# Cloudreach synthetic storage diagnostic: scoped paired result

Source under audit `fd2acbeff8a4dea39ae53b69dcfc9cdebb6c5e08`; two exact isolated probe files, no game autoloads or world. Locked Godot 4.7, Vulkan 1.3.280 Forward+, NVIDIA GTX 1060 3GB. Array and packed cases naturally exited zero in 6.1194726s and 6.1779688s, respectively, with empty stderr and clean diagnostics. Both read back 135,000 transforms / 6,480,000 bytes with first_mismatch=-1 and identical SHA256 `755c6d60862dcef06337c93f085e8477645a3be9bba4b1a5b048ccc5e8b8c514`.

Independent reviewer `state_consistency` returned `PASS_PAIRED_SYNTHETIC_STORAGE_ONLY`, verified exact files/engine/logs, resource floors and cleanup. Partial engine static counters showed packed approximately 4 MiB lower after generation and about 10.16 MiB lower after submission. Probe times were 844ms and 790ms; a single pair does not establish a speed improvement.

All six external phase windows were unobserved in both cases. Sampled process maxima are asynchronous observations, not phase peaks or controlled benefit estimates. Do not extrapolate these counters to the full biome or claim the diagnostic resolves the prior approximately 4.2 GB full-world failure. The result supports considering a narrowly scoped production storage/upload candidate followed by exact equivalence checks; it does not authorize another full-world capture by itself.

No world, rendered vegetation or acceptance images were tested; no production performance benefit, visual acceptance or criterion closure is demonstrated. Original failed capture and F10 receipts remain preserved separately.

[raw-bundle.json](raw-bundle.json) preserves 16 byte-exact base64 payloads; all decoded bytes matched originals. [hash-manifest.json](hash-manifest.json) records lengths and SHA256. Canonical UTF-8/LF bundle SHA256 `e08ca1b6dfe806b8fe687e36d58b63211e2412ea1d410c67471e947539cce4e0`. Homes, caches and generated `.godot` data are excluded.
