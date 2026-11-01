# Code-fix lane: Fix 1, dialogue push-in (GPU DLG-1)

Branch `tb/world-fix-dialogue`, from main 9996fa4a.

## Verdict

**The 14 failing DLG-1 frames are a capture problem, not a game bug.** The capture camera framing is unchanged.

**Separately, the investigation found one real in-game bug and fixed it.** Cloudreach topic prompts never pushed in. The fix is in game code, with a unit test that fails before the fix and passes after it.

## Why the 14 frames do not push in

`phase2_capture_dialogue.gd` calls `DialoguePanel.start()` directly at a catalogue post. It does not activate an interaction first.

When a conversation opens, `conversation_camera.begin()` can only frame someone if:
- the arbiter's live winning prompt is on a character, or
- an earlier activation left a character behind.

At every failing post, no enabled speaker prompt was offering. The probe (`tools/_probe_dialogue_speaker.gd`, CPU, seed 2042) lists every interaction provider within 8 m of the player after the post settles:

| Frame | Speaker prompts within 8 m | Why |
|---|---|---|
| Meadows Kell | none | Kell's Greet prompt only exists once he has something to say (`village_npcs.gd` `has_anything_to_say`). Kell stands at the storm road only after `legendary_freed`. The capture state is fresh. |
| Tidewake Daro (Bex and Irva use the same path) | `WaterChallenge` plus two others, all `enabled=false` | The challenge prompt is enabled only while `can_challenge(spec)` holds (`cloudreach_encounter_director.gd` `_process`). The capture opens the trainer's `intro_conversation`, which no game code ever opens: `spec["intro"]` is set in `water_encounter_runtime_data.gd` and never read. In play, Challenge starts the battle directly, and the victory lines pass the trainer explicitly (`_present_trainer_victory`, `begin(speaker, "aftermath")`). |
| Tidewake Nalia, Nerissa | none | The post stands on an empty dune with no Nalia in frame. The catalogue post is not at the NPC's body. In play, `water_scene_npcs.start_conversation` refuses beyond 5 m of the speaker, and the Greet prompt is on the body. |
| Cloudreach Kelm, Veyra | none | Neither body or prompt is within 8 m of the post in the fresh capture state. |
| Stormwood Captain Marrow | none | No body or prompt within 8 m of the post in the fresh capture state. |
| Meadows stronghold courtyard/elite | not probed | The trainer posts found no CPU stand in the Meadows probe. In play, stronghold trainers open their `challenge` conversation from their own challenge prompt. |

**Controls engage the same way in the same run:**
- Tidewake Adair: enabled, offering Greet prompt on the body. `pushed_in=true`.
- Cloudreach Sora: same, `pushed_in=true`.
- Stormwood Elder Maud: same, `pushed_in=true`.
- Meadows Corin: has an offering prompt. It engages on GPU DLG-1. On CPU it missed, because the arbiter had not yet picked its winner on the frame the capture opened the panel.

**What this means for capture:**
- The capture opens conversations at posts where the game would not open them.
- In play, each of these conversations opens through the speaker's own enabled prompt, which makes it the live winner and pushes in, or never opens at all (the water trainer intros).
- Making these frames push in is a capture fixture change: stand at the speaker's body and activate its prompt, or pass the speaker to `begin()`. That is not a game change, and it is not a framing change.

## Real bug fixed: Cloudreach topic prompts

**The bug:**
- `cloudreach_physical_runtime.gd` hangs each `topic_interactions` prompt (e.g. "Ask Kelm about cliff materials", offset 1.8 m) under a shared `ConversationTopics` Node3D, not under the person.
- `resolve_speaker()` walks provider → parent looking for a character, so it found nothing.
- In play, that topic opened Kelm's lines with no push-in. If an earlier conversation had happened, it framed the previous speaker instead.

**The fix:**
- `conversation_camera.gd`: a provider may name its speaker through the `conversation_speaker` meta (`SPEAKER_META`). It is honoured only when the named node is a live character.
- `cloudreach_physical_runtime.gd`: `_show_topic` sets that meta on the topic prompt to the person body standing now, just before the panel opens.

**Test:** `test_conversation_camera.gd::test_a_prompt_beside_its_speaker_resolves_through_the_speaker_meta`.
- Before the fix: `28 tests, 119 assertions, 1 failed`.
- After the fix: `28 tests, 119 assertions, 0 failed`.
