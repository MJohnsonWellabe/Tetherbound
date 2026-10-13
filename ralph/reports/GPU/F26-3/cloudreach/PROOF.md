# F26#3 Cloudreach matrix — Medium coordinate preview complete, High pending

- Source `122682ad`; native Godot 4.7, GTX 1060 3GB, Forward+ Medium.
- Existing `capture_lookdev_catalogue.gd`, all 12 catalogue stands, day/night.
- Result: 22/24 frames, complete=false, two failures, exit 1 (13 Oct 01:04 CT).
- Both failures: Broken Skyroad Arch; `Game.debug_teleport_to` refused destination.
- Production travel guards remain intact; precise grounding/slope cause is not established.
- Two wild sites were excluded by existing fail-closed walkability checks; no population-completeness claim.
- Receipt and per-frame hashes: `medium-manifest.json`; full originals under `D:/tetherbound/.artifacts/codex-service-gpu/cloudreach-Medium/`.
- Production world/camera with staged debug travel and clock pins; no earned-play, real-fight or performance claim.
- Private opt-in preview uses authored Broken Skyroad Arch center XZ (350,1940), versus catalogue (365,1925); default catalogue remains unchanged.
- Preview Medium: 24/24, complete=true, no failures, exit 0 (13 Oct 01:36 CT); both previously refused arch views passed production guards.
- Receipt `authored-arch-medium-manifest.json` records exact coordinate change and frame hashes; adapter `coordinate-preview.gd` requires --preview-authored-arch.
- Original failure evidence retained separately. This supports the coordinate correction, not a proven slope diagnosis.
- High preview currently running; complete-matrix judge pending, no READY or criterion closure.
- These 24-frame matrices do not replace the required >=200-frame F40 catalog recapture or real-fight matrix.
