# PR684 correction review

Reviewed 14 Oct 2026, 1:08 AM CT. Independent reviewer: `systems_resume_packet`. Result: pass for source scope; native/runtime confirmation is unrun.

Failing CI: run38516167455, headfd653c6e3fc6dcb2b522696191c1ddd0a0b30de1, merge751b54c366ba83ee349172c0d49893060cd29fc4.

- Water job115695836370: fight2 trainer drift4.183m, resume0.007m; stamina/HP pause assertions held. Tidewake513f494926, integratedcb8e142279, clears paused velocity and omits collision movement while preserving resource-state updates and unchanged normal swimming. The exact colliding body is unproven. Original smoke limits, resource assertions and watchdogs remain; only successful drift reporting changed.
- F28 job115695836765, artifact11871729342:97 submitted swings, enemy61.17/169.4HP, two retained placement samples during recovery, no retained refusal. Fights2b89da837e, integrated600a0d7bbc, enables the existing stage_when_ready guard for both win calls. place_on_ground clears motion; readiness and pending-host/vitals guards now prevent that interference during committed actions. The outer loop still waits and charges its frame budget. Original6000/6400 budgets, assertions, authority and guest no-HP-topup remain. This does not establish that every failed strike was interrupted. Separate injection-frame accounting discrepancy remains unresolved.

Original integrated smokes/full CI must confirm both corrections. No unchanged rerun, increased budget, assertion removal or weakened gate is claimed as a fix. No acceptance criterion closes from this review.

Related independently reviewed source-only changes: HUD lifecycle fixturea149ee18cf (integrated2b0af331c1) binds production Player before HUDready; original assertions remain. Homestead ac9974bf5f requires7eb4b11ec8 (integratedcf9e0766a2+776faf136f): reserve Evolve stock before optional Stay reuse, return actions in party order, both-order scarcity regression; runtime unrun.

Terrain integration44dc602529 includes exact accepted Windows-debug DLL5cf87b3a5dea907b788f187e7ede6347f3aaba25396610269120a3cf2a903306 and e2ac/d6e1 patch/profile dependencies. Independent reviewer `state_consistency`: source/provenance/notice/hash scope pass. Other three binaries and four selectors unchanged; Bash notice-copy execution and shipping/earned acceptance remain open. Prior component/Guardian runtime evidence is scoped in the adjacent proof directories.
