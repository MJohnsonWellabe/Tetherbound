# tb/gpu-frames-1101 (temporary, 1 Nov 2026)

GPU-lane captures for the cloud judges. Never merged; deleted tonight. Owner approved this branch in the GPU session (1 Nov).
Layout: `<tree>/<set>/<stand>.jpg`, High preset, 1920 wide, JPEG q85. Trees: `main` (origin/main control), `batch0`, `batch1`,
`craft/{main,cand}` (CRAFT-ICONS: main 2f2901db0 + tb/world-craft-icons 8ed4a7ca, flags off vs readable_r3 + rendered_item_icons on).
Sets: `<biome>-<tool>` for a grouped launch, `<biome>-<tool>-<args hash>` for a single command (same name in every tree),
`pad/...` (UI-PAD + craft with --gamepad), `creatures-f36` (capture_f36_poses --all --whole-body --context), `hall-f17-6`.

Capture speed (coordinator 1 Nov, ~10:15 CST): from here on every imported tree is merged with tb/capture-speed (5fb5e7283: GameMenu
per-frame scene walk fixed, shell waits by the world's ready flag, --jobs, --ground-cover-cache; renders the same, identical
grass/flower/bush counts) and Cloudreach launches pass --ground-cover-cache. main/ Meadows was shot on main 2f2901db0 before the merge;
main/'s remaining biomes and extras are shot on local 9ba38c96b = 2f2901db0 + tb/capture-speed. Batch trees: <batch sha> + tb/capture-speed.

Dialogue fixture (coordinator 1 Nov): main/'s frames for batch-1's dialogue stands were shot with batch-1's tools/phase2_capture_dialogue.gd byte-copied from 73a5d9f65 (tool-only; game = main 2f2901db0), so main/ and batch1/ dialogue frames use the same fixture. Realm-flight stands (meadows c016/c017/c026) are skipped on main until the shell-wait fix lands.
