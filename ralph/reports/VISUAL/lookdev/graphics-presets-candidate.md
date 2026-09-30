# F26 candidate graphics settings — source c6c39e6bdd44ed833ffba20a4f262cc1208e47cd

Actual source is pushed on `tb/lookdev`, against the pushed F16 dependency candidate. Main landing waits for F16. F26#0/#1/#3/#4/#5 are not claimed MET here. F26#2's authored documentation has an independent docs-only pass; main pin/board closure remains separate.

## Implemented behavior and scope

Low keeps Compatibility as the authored default. Medium/High request Forward+ through one checked `user://graphics_override.cfg` document read at engine startup. All choices, custom toggles and the overlay are device-local; no character/world fields or peer RPCs are added. Preferences commit in memory only after staged bytes, flush, re-open and document validation pass. A valid previous generation is retained; a contradictory preset/base pair is refused. This does not claim power-loss atomicity. If promotion rollback cannot restore the canonical file, the previous copy remains available to the runtime reader; preboot conservatively uses the authored default before an explicit recovery restart.

The existing Settings shell embeds Graphics and retains input ownership. Physical controller focus enters and leaves the existing audio lane. Every graphics button receives scroll-follow, including initially disabled Forward+ controls. Choosing a toggle selects Custom. Renderer changes offer Restart now/Later and never arm a restart silently. Restart preparation checks the existing host save result or the guest's own portable-character admission/save result before leaving a session. Session goodbye flush and Steam lobby exit precede the requested desktop restart. The new proof checks routing with declared fake host/guest objects; an actual process quit/restart and four-peer restart remain unproved.

WorldLook applies quality after its authored weather/time grade, handles changing cameras even when capture time is frozen, and keeps shader depth conversion renderer-specific. Shadow Off removes visible sun shadows but retains a minimum map to avoid the existing Terrain3D black-ground issue; it is not a zero shadow-pass-cost claim. GPU biome rendering, supported-feature changes, materials and route timing remain open.

## Minimum validation batch (RD-36/RD-37)

- Full-checkout warm import: Godot 4.7 native exit 0; no `ERROR:`/`SCRIPT ERROR` markers. This is import/parse evidence, not visual proof.
- First `tests/smoke_graphics_settings.gd` run: native exit 1, two failing expectations and an actual typed-ternary Array assignment error in the shadow selector. Raw red log is retained. Fixed the option list to its actual untyped runtime Array, then ran the affected batch once.
- Corrected batch: native exit 0, all 19 checks PASS in the production Settings shell with injected physical A/D-pad events. Includes persistent Medium/Custom request, unavailable-feature focus skipping, shadow/overlay toggles, Later, audio boundary focus, reload, contradictory-document rejection, and checked host/guest save routing.
- Separate fresh process with the same isolated APPDATA: native exit 0, custom shadow/overlay choices retained and actual startup renderer reported `forward_plus`. The headless renderer is not a GPU/material/performance proof.
- The final source adds only scroll-follow wiring for buttons initially disabled on Low after the corrected batch. This bounded addition was reviewed statically; no repeat of the unrelated unit suite is justified. It will be exercised by the actual Forward+ controller/capture path.

Runtime logs were produced before the source commit; production files match the tested content except the disclosed scroll-follow addition and documentation. No unit suite/full CI was run for this bounded candidate. No test was skipped, disabled or quarantined. Generated import timestamps/line-ending metadata were refreshed only after normalized blob identity checks; no asset changes were staged.

## Independent read-only re-check — /root/vfx

Source review PASS: no concrete persistence, scope or checked-restart blocker. The contradictory preset/base recovery defect was fixed. Minor concern about later-enabled controls lacking scroll-follow was fixed by wiring all graphics buttons once.

F26#2 docs-only PASS/MET: ART_DIRECTION §4.1 supplies sky, fog/haze, sun shafts, time/phase grade and weather mood for every biome plus Village/Hall, config anchors, a preset contract and ordinary-camera frame matrix. Reviewer independently inspected the restored Meadows key art, Veilfall, Aviary and Stormheart A+B boards. It preserves the owner's dune, purple-sky and no Stormwood day/night decisions. Separate Valheim/Animo images are absent and disclosed; the exact criterion requires biome look bars with reference boards, not separate external frames. This proves the written target only; visual/performance/hardware acceptance remains open.
