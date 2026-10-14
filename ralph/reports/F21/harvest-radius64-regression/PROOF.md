Radius-64 focused r4 evidence audit

Scope: focused-run receipts and logs only; this does not establish parity, GPU acceptance, or release readiness.
Candidate source: 3987e8af5ce93bcc7fa088c8515c16547e8c6bf0; engine SHA-256 b2ca888d5115a6cedee564764a2ee494a625f2ec2edbabd010fe33c9a88a6bf8.
Runner SHA-256 1f6eaee84c2fc2fca92b19cd2e6f06f9d9ea4beb5c27d6a00bb8a340c981d099; job SHA-256 c9613fd0817d19b34d33816d8d77280484d65610994a549767d0490558dc4200.
Raw run: C:\CodexTemp\codex-service-carryovers\harvest-stream-radius64-r4\focused-r4.
Receipt status EXITED_ZERO_AWAITING_REVIEW; all three root processes exited 0; receipt records no rejected CIM observations and 27,772 combined output/home bytes.
Harvest permanence: 22 tests, 218,747 assertions, 0 failed; 132.043 s; stderr 3,122 bytes.
Clear-area gather: 3 tests, 13 assertions, 0 failed; 11.026 s; stderr empty.
World-ledger races: 27 tests, 163 assertions, 0 failed; 13.582 s; stderr empty.
Five scatter-placement warnings remain visible in harvest-permanence stderr; no error/failure diagnostics were found there.
Warning: anchor (80.0, -64.0), placed 0/2 in 24 attempts.
Warning: anchor (2.0, 47.0), placed 0/1 in 12 attempts.
Warning: anchor (2.0, 47.0), placed 0/4 in 48 attempts.
Warning: anchor (-10.0, 1318.0), placed 6/8 in 96 attempts.
Warning: anchor (-248.74, 6462.9), placed 0/2 in 24 attempts.
Combined focused observations including vegetation-streaming: 55 tests, 218,951 assertions, 0 test failures.
Vegetation-streaming evidence is 3 tests/28 assertions/0 failures/engine exit 0, but its r1 wrapper failed summary parsing on CRLF; it is preserved as an engine result, not a successful r1 supervisor receipt.
Preserved r1 failed receipt SHA-256: 8b3d23d58ae4c4c98fc20cd022a7f7d79a17f433ddf16cbf6cde43df544d16f6.
Preserved r3 failed receipt SHA-256: 1273c91b9d7a5d32aeaa13c4ea440e35e3708f500e854853abc80a022b9c1747; failure was child identity rejection before suite completion.
Focused r4 receipt SHA-256: bd76399577e2026887bfd82ff235f5b784c03068c66bff6169dd5bd2f4aed73e.
Harvest stdout/stderr SHA-256: 28c530b3ee48801d4dc435d05ac113c3921d9c12327afd42b492bb03ab0a0ad9 / a495ff95ecb635ea82e754d3fc49b151dbda8bf1c915f09bfa04132578631019.
Clear-area stdout/stderr SHA-256: f09a23bfdf1f650f1862b48618bce17e330d1d1089c38d1cd0885b95fc24fc4f / e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.
World-ledger stdout/stderr SHA-256: 972c82dd4201cd87ccb53505fada122e2941cf79293ea948555ba80515e8dc42 / e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.
