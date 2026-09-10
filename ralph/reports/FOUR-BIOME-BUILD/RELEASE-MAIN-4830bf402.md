# Rolling release identity repair — verified on main

PR93 landed as `4830bf402a94d7d945119027a454d07dfee1dccc`, with reviewed head
`0a8934106` an ancestor and identical tree `6b043bf79290c0af3df56b645f8a795f65b51945`.

Release run [34313176648](https://github.com/MJohnsonWellabe/Tetherbound/actions/runs/34313176648)
completed successfully on attempt 1, 2026-09-09 05:00:46–05:14:35 UTC.
Both executed jobs and all steps were reviewed: build `102343857733`, pages
`102345918288`. Complete decoded logs were inspected (1,609,646 and 28,470
characters). No engine ERROR, SCRIPT ERROR or failed step appeared. OBJ/PBR
ambient-material import warnings and Actions Node-runtime deprecation warnings
remain; no warning-free claim is made.

The Windows export passed the PE32+ and minimum-size checks; executable size was
109,052,928 bytes. The exported-runtime ground check reported terrain present,
ground 0.90, player 2.90 and 383,004 props. That runtime check uses the Linux test
export; it does not establish Windows executable or Ally runtime acceptance.

The workflow uploaded `Tetherbound-windows.zip` at 05:11:19 UTC, then the new
helper logged `rolling latest ref updated and verified at
4830bf402a94d7d945119027a454d07dfee1dccc` at 05:11:20 UTC. Independent live
`git ls-remote origin refs/tags/latest` read-back after reconnection returned that
same SHA. Public release metadata independently names the same target and body.

Asset `552043230`, updated 05:11:18 UTC, is 692,407,211 bytes with GitHub digest
`sha256:71ebb070f3ef2ae93094973acbee44e389b982785b73acd9b1d934bc116c9627`.
The rolling release object's original published_at date is historical; the asset
update and exact build/tag identities establish this publication. Pages also
deployed the exact SHA successfully. Main regression CI is reviewed separately
in `CI-MAIN-4830bf402.md`.

The diagnosed rolling-tag mismatch is closed for this actual publication. No
gameplay, visual, campaign, hardware-performance or Beta acceptance follows from
release identity alignment.
