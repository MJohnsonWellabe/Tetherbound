# selfcheck_context — Harness self-check (CD-1/CD-4): the context guard fails at the step that could not drive the game

### preflight — capture not required
- segment declares no captures and no continuous record
- predicted cost 2 s over 295 frames at 0.0060 s/frame

### SC-X-01 — boot the real Meadows
- expected: the real world scene stands up
- actual: booted world in 64723 ms (240 settle frames)
- events: t=64.84
- verdict: PASS

### SC-X-02 — the world owns input
- expected: input_context is 'world' before anything is opened
- actual: input_context is 'world', which satisfies "world" (owner=, focus='')
- events: t=64.84
- verdict: PASS

### SC-X-03 — open the pause shell the way a player does
- expected: the bound `game_menu` action opens the shell and input_context becomes a menu* one
- actual: game_menu opened the shell: context world -> menu_backpack, focus on '' (@Button@61804)
- events: t=65.00
- verdict: PASS

### SC-X-04 — the shell owns input
- expected: input_context begins 'menu'. The next step is the one this segment exists for.
- actual: input_context is 'menu_backpack', which satisfies "menu*" (owner=GameMenu, focus='')
- events: t=65.00
- verdict: PASS

### SC-X-05 — a world control at an open menu must NOT be pressed
- expected: FAIL naming the guard: the step declares it acts in 'world', input is owned by the menu, and the press does not happen. In the f082bdf6 run this press DID happen, into whatever was open, and whatever it did was recorded as a finding about the game.
- actual: BLOCKER step SC-X-05 (press) requires context "world" and input is owned by 'menu_backpack' (owner=GameMenu, focus=, tree_paused=true). The step did NOT run: acting here would have pressed a world control at whatever holds input, and recorded the result as a defect in the game.
- verdict: FAIL (context guard; the step did not run)

### SC-X-06 — the step after a derail is SKIPPED, not run
- expected: SKIP. A step with no require_context, after a derail, is skipped with the derail named -- absence, labelled. It is not a pass and not a finding.
- actual: SKIPPED: the segment derailed at step SC-X-05 (required context "world", input_context was 'menu_backpack') and this step declares no resync point. input_context is 'menu_backpack' now.
- verdict: SKIP

### SC-X-07 — and so is the assertion that would have been taken in the wrong state
- expected: SKIP. This is the shape that produced the run's loudest findings: forty assertions taken after the harness had already lost the thread, each reported as a defect in the game.
- actual: SKIPPED: the segment derailed at step SC-X-05 (required context "world", input_context was 'menu_backpack') and this step declares no resync point. input_context is 'menu_backpack' now.
- verdict: SKIP

- resync at SC-X-08: input_context is menu_backpack; the segment is back on rails (derailed at SC-X-05)
### SC-X-08 — a step whose own context holds resynchronises the segment
- expected: the shell is still open, this step's require_context holds, and the segment comes back on rails. A derail that could never be recovered would make one bad step void a whole segment.
- actual: input_context is 'menu_backpack', which satisfies "menu*" (owner=GameMenu, focus='')
- events: t=65.00
- verdict: PASS

### SC-X-09 — close the shell
- expected: menu_cancel closes it and input_context leaves the menu*
- actual: menu_cancel closed the shell: context menu_backpack -> world
- events: t=65.11
- verdict: PASS

### SC-X-10 — the mouse came back
- expected: §E.4's restoration checklist: the shell releases the mouse on open and must restore it on close. Under --capture this is a real verdict. In LOGIC mode it is a SKIP and says so: a process with no display server has no mouse to capture, so mouse mode says nothing about the game. An assertion that cannot be EVALUATED is not a verdict -- the first run of this segment reported `mouse_mode=visible (wanted captured)` as a FAIL against a build that restores it fine, which is the harness-artefact class this whole lane exists to remove.
- actual: SKIPPED mouse_captured: this process has no display server (DisplayServer reports 'headless'), so mouse mode says nothing about the game. Run this segment under tools/gate_f/run_segment.sh --capture for a verdict.
- events: t=65.11
- verdict: SKIP

### SC-X-11 — and the world owns input again
- expected: input_context is 'world': the segment is fully recovered and a later step would mean what it says
- actual: input_context is 'world', which satisfies "world" (owner=, focus='')
- events: t=65.11
- verdict: PASS

### SC-X-12 — close the segment
- expected: a note event closes the segment
- actual: SC-X-05 is an EXPECTED FAIL and SC-X-06/SC-X-07 are EXPECTED SKIPs; they are the point of the segment. SC-X-10 is a third SKIP in logic mode and a real verdict under --capture. INVENTORY.json's `derails` array records the derail at SC-X-05 and its resync at SC-X-08, so a segment that lost the thread and found it again cannot close looking clean.
- events: t=65.11
- verdict: PASS
