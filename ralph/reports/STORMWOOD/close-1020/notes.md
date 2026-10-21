# Stormwood lane, close plan from 20 Oct 2026 (F41, F26#3)

Renderer for every capture here: Godot 4.7 Compatibility (opengl3), Mesa llvmpipe, CPU, 1920x1080, Xvfb. Owner rule (17 Oct): a CPU three-judge Bar A mean of 6.7 or above counts as met, "CPU-provisional", until a GPU pass confirms 7.5.

Capture: `tools/capture_stormwood_f10_matrix.gd` (same five stands as `camera_sets/F41-look.json`, the only Stormwood matrix script that runs without a Forward+ preset) plus three fixed custom stands, used unchanged every round:
`--phases=calm,break --custom="reverse@-300,4420@-350,4,4330@-2;heart_near@-100,5330@-100,80,5470@18;hollows@-500,1550@-460,3,1640@0"`, aftermath pass on. 24 frames per run; about 33 min.

Judging: three code-blind general-purpose subagents. Each gets two shuffled sheets (X/Y, 8 stands x Calm/Break/aftermath), the Stormwood boards, the key art, the Palworld references and the written §4.1/§4 look bar. No code, diffs or labels.

## F26#3 — unrun
Needs matched High and Medium (Forward+) captures on a GPU. Forward+ does not run in this container. Recorded as unrun; not attempted.

## Round 1 (21 Oct, about 03:45 CT)
- Baseline: main 2124b1f6c, all candidates OFF.
- Candidate: shared look ON, Voltcap finish ON, Glass scar relief ON, fallen giant ON. Moss grass cover denser and cooler (density 0.16->0.55); bark retint lighter (#8f9580->#b3bfa6); slate roofs on the four Stormwood ranger stations. They were raw terracotta and read as oxblood beside the Stormheart.
- Bar A: baseline 4.2 / 4.6 / 4.3 = **4.37**; candidate 4.6 / 5.0 / 4.6 = **4.73** (+0.37). Bar B: 3.9 / 4.2 / 3.8 = 3.97 vs 4.3 / 4.5 / 4.1 = 4.30. All three judges preferred the candidate.
- Common defects (all three judges): the Stormheart reads as a plain pale trunk with a ladder and a rust strip, and needs new art; Break crushes the forest stands to near-black; pools are matte lilac slabs with hard edges; bare brown ground with sparse blades; generic meadow broadleaf trees; the rod cable reads red; a hot-pink bush on the Hollows horizon; the Glass Field stand shows no readable scar; the fallen giant doesn't read.
- Bug found and fixed: `stormwood_look.gd` `_process` typed a freed streamed node ("previously freed instance" script error). Now checked before typing.
