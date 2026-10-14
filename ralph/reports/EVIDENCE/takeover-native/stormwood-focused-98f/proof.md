# Stormwood partial focused-run proof

- Source `98f911cd8dff5e22ad0b60e53d56d23227a16524`.
- Run October 13, 2026, 10:39:45–10:39:56 PM US Central.
- Look step: eight exact methods, zero failures, natural exit 0; stderr empty; 11.274 seconds.
- Independent audit verified log hashes, exact executable/argv, admitted job/runner, 539 exact-source blobs and recorded resource floors.
- Original overall receipt remains **FAILED**. Surge was **UNRUN**: underscore in `surge_presentation` failed the supervisor step-id guard before process creation.
- Failed Surge receipt has null PID/time/argv and exit -1. Its log fields incorrectly reuse the prior look logs; they are not Surge evidence.
- No Surge process or dedicated Surge logs exist in this run. That first-run result is preserved; the separately reviewed continuation below supplies Surge evidence.
- `raw-evidence.json` preserves eight files byte-exactly, including failed receipt and logs; UTF-8/BOM/newline/hash round trips verified.
- The original failed run alone proves eight look methods, not all 60; the continuation below completes the focused set.

## Surge continuation

- October 13, 2026, 10:44:20–10:44:36 PM US Central; same exact source.
- 52 exact Surge methods, zero failures, natural exit 0, empty stderr; 16.077 seconds below the 120-second cap.
- Independently verified exact argv/executable, job/runner/log hashes, 539 source blobs and resource floors.
- Total distinct methods now 60: reused eight look methods plus newly executed 52 Surge methods. Eight were not rerun; original FAILED receipt remains unchanged.
- Raw evidence extends the original eight files with eight continuation files, all byte-exact UTF-8/hash round trips verified.
- Focused logic passes only; GPU judging and visual acceptance remain separate.
