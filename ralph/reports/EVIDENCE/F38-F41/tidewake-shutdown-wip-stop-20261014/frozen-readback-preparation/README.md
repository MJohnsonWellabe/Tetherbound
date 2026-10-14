# Tidewake shutdown readback preparation

Frozen source: `bf45595b3a06392a4633858642a63160e047e17b`. Independent source observation review passed; native typecheck and full-world shutdown remain unproven.

**NOT NATIVE READY. No native launcher is included.** Exact one-parser/one-capture commands and prior floors are in `diagnostic-packet.json`, with launch disabled. A verified collector and a reviewed successor supervisor are still required. The old full-world supervisor contains unbounded pipe waits and must not be executed unchanged. Do not treat the isolated supervisor as a drop-in full-scene runner.

The executable tools here are read-only evidence analysis and CPU fixtures. Run with the bundled Python and `-B`:

```powershell
& 'C:/Users/mattj/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' -B 'D:/tetherbound/.artifacts/codex-look-tidewake/shutdown-readback-preparation-bf45595b3a/verify_cpu.py'
```

For a future admitted receipt, invoke `analyze_shutdown.py <receipt-path> --receipt-sha256 <verified-sha256> --require-readback`. This validates typed readbacks and recorded boundaries; it never certifies natural exit, process ownership, lease release, warning cleanliness or visual acceptance. A separate root review still verifies those. Original e006 analysis explicitly preserves FAILED and no resource readback. Synthetic fixture counts are not native observations.

Preserve this directory and all prior failures/successes. Changes to source, collector or supervisor require a newly frozen successor and review; no automatic retry or cap increase follows from this packet.
