# F21 service Medium live capture

- Status: FAILED; no performance claim, no PASS/READY. The candidate remains OFF.
- Source pin: `1f6d7e210888244d544ea4290770cb844ca21a66`.
- Fixture: `capture_f21_medium_timing.gd`, SHA-256 `601d1878e0672bf204df8625fd37054300613b2a30f4ebe1dd775c32a8ee10a6`.
- Supervisor: `run_private_f21f25_calibration.ps1`, SHA-256 `fd5ac55f00021e65235041a0e4ff805e565e77207354a6778f2e7990f97fb30d`.
- First raw run: `C:\CodexTemp\codex-service-gpu\f21-medium-live\run-20261013`; natural exit 1. Receipt confirms Medium / Forward+ but windowed output was 1920x1061, so the fixture rejected it; no shots or timing samples were produced.
- Second raw run: `C:\CodexTemp\codex-service-gpu\f21-medium-live\run-20261013-fullscreen`; supervisor stopped its owned engine during world build when the combined physical-or-commit-memory guard crossed the 2 GiB floor. No fight or frame samples were produced.
- The retained supervisor receipt does not identify which memory measure crossed the combined guard; do not infer physical versus commit exhaustion.
- Raw receipts, stdout/stderr, supervisor logs, and isolated homes remain at `C:\CodexTemp\codex-service-gpu\f21-medium-live`.
- Compatibility four-creature diagnostic also blocked before timing at 12:02:47 CT, 13 Oct: one rendered production Meadows host plus two lightweight headless clients. Both client hellos bind `1f6d7e210888`; host boot reached the world but no fight/readiness or timing receipt completed.
- Exact stop sample: available physical RAM 2,146,435,072 bytes (<2 GiB); commit headroom 2,862,604,288 bytes. C/D free bytes 13,330,812,928 / 25,157,087,232 were above floors. Supervisor stopped only the verified run family; lease returned idle.
- Evidence: `D:/tetherbound/.artifacts/codex-service-gpu/four-creature-live/compatibility-runs/four-creature-compat-232f4af69634402789ffd261b90bf401/`; supervisor JSONL retains actual memory values, source, PID/image/argv/creation identity and failure. No GPU timestamp, VFX, visual or performance acceptance claim.
- Three earlier preparation starts are retained separately: a rejected private GDScript type inference, diagnostic Git-helper process rejection, and peer-registration snapshot race. These were fixed before this memory-limited attempt. Further work must reduce the admitted process footprint or use a suitable device; no unchanged retry is authorized by this evidence.
