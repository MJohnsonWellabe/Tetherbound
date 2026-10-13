# F38#0 Meadows recapture and survey audit

- Lane `tb/codex-visual-meadows`, from merged main `122682adbc2b6b37b03c1c0d13287beece3fa23e`; audit checkout HEAD `021b32eef270640c6b3176dfc6c770dc887f9d5d`.
- Existing production fixture planned 22 sites × three times × two weather states × four views = 528 frames per preset, using fixed support stands, production camera/population, no candidate toggles or creature-scale changes.
- Medium and separately admitted High each saved 354/528 (174 missing), terminated exit 1, and had no resource abort. Terminal receipts and hashes remain under `C:/CodexTemp/codex-service-catalog/`.
- Capture definition was materialized byte-for-byte from source commit, SHA256 `e18a7a004277e5b5866c241a17ad0021f9614f31abf178f67eb2a02bc04b1e14`; source tree was clean before launch.
- Prior 24-pair neutral survey sampled 353 shared IDs and remained WEAK/WEAK; Bar A/B NO. Raw High/Medium manifests have 354 frames each, 353 shared IDs, 174 missing per preset.
- Survey frame IDs match 0 of 23 nonclosed Codex-owned catalog sighting IDs. Coverage, gaps, prior review overlap, blind mapping, source hashes, and exact next requests are in `survey-id-audit.json`.
- Scope is 23 rows: 9 top-20 and 14 impact>12. Survey has no exact sighting-ID matches; direct packets and the six baseline follow-ups remain scope-limited, with all row dispositions unchanged.
- Older broad review findings are retained below in REVIEW.md; its 24-pair review was not replaced by the follow-up samples.
- Two fresh independent blind baseline reviews covered P2-005, P2-006 (mill only), P2-012, P2-013 and P2-014. Neutral sheets, full-resolution pairs, mapping and scoped observations are in this folder and REVIEW.md.
- Two further blind readers reviewed the existing real-fight sheet: both saw overlay/HUD readability issues but did not confirm P2-062 ally occlusion or mesh clipping in the selected sample; see FIGHT-REVIEW.md. Row remains blocked.
- Crosswalk qualitative dispositions and next-evidence requests now reflect these six scoped reviews; numeric impacts and catalog/board statuses are unchanged.
- These High/Medium pairs are not before/after variants. No row score, status or acceptance criterion changed; no closure. Exact row-specific captures and candidate comparisons remain required.
- The landscape matrix excludes real fights and catch sequences; native fight/catch fixtures remain future targeted evidence. P2-087's packet stays root-owned.
- No native engine work, real-fight capture, import/render/export, CI or PR was run or dispatched in this audit.
