# GPU pass: P2-095 craft recipe text / P2-096 craft hint contrast: both defects FIXED, Bar A REOPENED (Medium 6.63, High 6.60)

22 Oct 2026, ~02:45 CT. Remote GPU lane (owner's Windows desktop).

- **Renderer:** Forward+ on Vulkan, NVIDIA GeForce GTX 1060 3GB, 1920x1080. Medium and High were set through the tool's look-dev bootstrap.
- **Source:** origin/main 9db3d2146, unmodified (the readable recipe rows, action hints and glyph hints are ON, as shipped).
- **Command:** `godot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1920x1080 --script res://tools/phase2_capture_build_systems.gd -- --biome=stormwood --seed=2042 --preset=<Medium|High> --source-commit=9db3d2146d0587d189cf172567b17345f31a0abd --output=<dir>`. Judged frame: `stormwood__system__crafting.jpg`. Both runs exit 0 with 4 frames each.

## Judging

Three fresh code-blind judges scored this in one batch with P2-018 and P2-094 (`judge_prompt.md`, `p2_gpu_key.json`).

**Anchor:** the committed CPU sheet `UI/close-1020/craft/_sheet_craft.png`. A = after, shipping (CPU judges 7.35); B = before (CPU judges 4.83).

| Set | j1/j2/j3 | Mean | P2-095 | P2-096 |
|---|---|---|---|---|
| Anchor A, CPU shipping (CPU judges 7.35) | 5.9/6.4/6.4 | 6.23 | FIXED ×3 | FIXED ×3 |
| Anchor B, CPU before (CPU judges 4.83) | 3.6/3.8/3.6 | 3.67 | PRESENT ×3 | PRESENT ×3 |
| **GPU Medium** | 6.4/7.0/6.5 | **6.63** | **FIXED ×3** | **FIXED ×3** |
| **GPU High** | 6.4/6.9/6.5 | **6.60** | **FIXED ×3** | **FIXED ×3** |

**Both defects are FIXED on GPU** (all three judges). Bar A is 6.63 / 6.60, below 7.5, so **REOPENED** under the owner's rule.

On one scale the GPU frames sit +0.4 above the CPU shipping frames. This prompt scores the CPU anchor about 1.1 below the CPU judges.

## Judges' asks (all fixable in scene)

1. Shorten the recipe cards (about 110 px) so 5–6 recipes show. Today only Axe, Berry Seeds and Hoe fit; Knife and the Orbs are off-screen.
2. Show controller glyphs (A and B) for the active device. The hints show Enter and Esc keycaps only, and ART_DIRECTION asks for controller-first prompts.
3. Make Craft a primary button with a disabled state when ingredients are missing, and distinguish have from missing by colour or icon.

Two notes need new art: the Axe and Hoe icons are near-identical T shapes, and the centre preview is just a small icon.

Sheet: `_sheet_p2_095_gpu.png` (Medium | High).
