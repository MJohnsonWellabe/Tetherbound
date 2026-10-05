C3 / F45#2 readiness audit: PARTIAL; actual canonical-history UI witness OPEN.

Independent read-only reviewer /root/c3_journal_review. Reviewed main e2fa5e4e6bb0060e5f98f9129f2f2e949f8a37f3. No source defect in party filtering found.

scripts/creatures/research_log.gd:106-115 counts tasks independently of party;123-146 projects saved species progress/caught/seen/payouts;175-176 records accepted catch. scripts/ui/tab_quest_log.gd:44-51 supplies canonical personal view; research_log_panel.gd:31-48 displays tasks/progress without ownership filtering. scripts/creatures/essence.gd:1062-1067 removes released party/UID record while retaining research history. This is source evidence, not proof of rendered release behavior.

Existing test_research_log.gd:41-63 stages empty-party defeat/serialization,104-127 accepted catch with empty party. It does not perform actual release or inspect rendered labels. smoke_bounty_journal.gd:26-28 checks Research entry/bounty rows but does not open Research modal. phase2_capture_ui.gd captures quest shell only and requires1080p.

Existing capture_f42_layout_fixtures.gd opens Research modal114-118 and supports native1080p or --size=1280x800;800p content scale1920x1200. It invents two tasks for ownedTerrapup at158-164, bypassing canonical history. Suitable only for scoped layout/readability. Owner STATE secondUIcheck1280x720 differs from coordinator1280x800 request; current tool lacks720p mode.

Missing prerequisite: existing native journal fixture demonstrating actual released-after-catch and caught-never-kept canonical task labels. Requested new smoke conflicts with standing human GPU-lane no-equipment/tests instruction; coordinator comment alone supplies no human override. No new smoke/tool, native capture, UI defect fix or acceptance claim was made. Source/test coverage and synthetic layout cannot close this criterion.
