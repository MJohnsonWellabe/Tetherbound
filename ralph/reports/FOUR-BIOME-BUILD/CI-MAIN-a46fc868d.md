# Main a46fc868d CI audit — passed on attempt 1

CI34384656606 targets `a46fc868d6d93d491a8a17c8931576148ed0dfb7` and completed successfully on attempt 1 (2026-09-09 17:43:29–18:35:26 UTC). All 27 executed jobs and their steps succeeded; the two explicitly known-red full-route jobs were skipped. Complete raw logs, run/job metadata, and baseline comparison are retained under `.artifacts/main-a46fc868-ci/`.

The four unit shards report 3,137 tests, 487,946 assertions, zero failures. All 38 network smokes passed on their first invocation. Full-log comparison retains existing native diagnostic classes and shutdown resource-count variations; no new non-shutdown diagnostic class appeared. This is not an error-free-log claim. The export job also completed successfully; its complete log contains no native or script errors.

Independently verified tree `80a1505fb0083bb5213f107f440474827a3535c7` differs from reviewed PR101bba only by the 107-line owner directive introduced by PR10236ef19265; no source or CI delta. This closes this main regression audit, without closing a continuous campaign, visual, or Beta gate. Later main commits have separate CI and release runs.
