# F04#3 strict re-check: Warden Aldis at 3b6f965a (independent read-only subagent)

**VERDICT: MET.**

| Item | Result | Evidence | Reason |
|---|---|---|---|
| Named tactical question visible at the normal fight camera | MET | warden_3b6f965a/ t01–t04 start/mid, 08, 12, 16; fight_log `tell N: 1.10s` x5 | "!! HEAVY — get clear" is up for every tell, stronger than the ordinary "! incoming — move". Tuskroot is in frame with its ring. The tell is 1.10 s (BOSSES §4.5). Stand vs dodge outcomes differ: impact and HP drop, a stagger banner, and an unchanged-HP miss. |
| Boss kept in view at key moments (r2's failure) | MET, with a residual | 20, 24, t04-dodge-strike, r01, r02 | Tuskroot stays at the right edge. Holding framing at every body size is F04#7. |
| Victory dialogue frames the Warden without crowding | MET | a01–a06 | Aldis is centred head to foot, with no ally, paw or fallen ace in front of him. His lines are shown. He is small and dimly lit; that is Bars A/B, for the Phase 2 catalog. |
| Combat HUD gone in the victory dialogue | MET | a01–a06 against the t-frames | The foe plate, creature panel, moves grid and party strip are absent. The objective changes. |

**Disclosed shortcuts:**
- **Harness:** `tools/art_pipeline/capture_named_fight.gd`, an evidence-only CI render (run 36427399935).
- **Teleport:** the player is placed in front of the Warden. The challenge itself goes through the real prompt and dialogue.
- **Earlier members:** `--live-member` resolves the first four members as won, so the frames show the ace.
- **Resolution:** `--resolve=won` ends the fight by the resolve call.
- **Party and input:** a level-3 fixture creature, AI-driven, with a scripted dodge on every other tell. `--keep-alive` is available (no top-up is logged).

**Outside F04#3** (recorded for their own rows):
- The player's creature hides the Warden after the dialogue (F04#6/F04#7).
- The ring hugs Tuskroot's feet; the Earth Fist cone is not drawn (tell clause).
- The t04 miss text is ambiguous.
- One dodge was still hit.
- An `aftermath_standard` meta error was logged; it is fixed at d541cb04 (has_meta guard).
