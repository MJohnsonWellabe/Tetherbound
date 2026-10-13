# F38 fight-camera baseline — capture pending

- 13 Oct 2026 04:31 CT; main122682ad plus capture-only shell-readiness wait, private source629206643c29b5a7659d8ff7a18ea7f8734cee2c.
- Existing named-fight fixture previously waited300frames before looking up trainers despite asynchronous production shell construction.
- Added bounded600s wait for shell_build_complete, then existing settle; no gameplay/asset/config changes.
- Native High Forward+1920x1080, Warden Aldis versus Galewisp;48requested fight snapshots at0.5s intervals, attack/dodge input taps and lens probe.
- Fixture party/debug travel disclosed; no forced outcome, live-member skip, keepalive, or earned-progression claim.
- Supervisor session31799, 20-minute/512MiB/C reserve bounds; one native writer. Native restores main after terminal exit.
- Output C:/CodexTemp/codex-service-catalog/f38-fight-galewisp-high/; launch receipts .artifacts/codex-service-catalog/fight-preflight/.
- A terminal exit and actual live_fight records must be inspected before any combat-presentation claim. This is not F21/F25 four-peer or GPU performance evidence.
- Medium/Compatibility, size matrix and code-blind defect scan still pending. No READY or criterion closure.
