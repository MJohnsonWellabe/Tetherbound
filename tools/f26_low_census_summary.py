"""Condense F26 material-census manifests into one compact per-scene receipt.

The census manifest (tools/capture_renderer_material_census.gd) repeats the
whole mounted binding graph per frame (tens of MB each). This keeps the
receipt format's identity fields and reduces each scene to counts plus every
binding that could be a missing/placeholder material:
  - unbound surfaces (no active material -> engine default/placeholder),
  - resources whose res:// source no longer exists,
  - shaders with empty code,
  - ShaderMaterials whose object (texture) uniforms read null with no live
    GPU RID binding.
These are review prompts; pixel scan and the code-blind judge decide visuals.

  python3 tools/f26_low_census_summary.py --manifest <m.json[.gz]> ... \
      --scene-tag meadows=<label> --out receipt.json
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
from collections import Counter
from pathlib import Path

SCENE_PROBES = {
    "village": ("Village",),
    "crossing_hall": ("crossing_hall", "Arch_", "MeadowsCatalogPresentation"),
}


def load(path: Path) -> tuple[dict, str]:
    raw = gzip.decompress(path.read_bytes()) if path.suffix == ".gz" else path.read_bytes()
    return json.loads(raw), hashlib.sha256(raw).hexdigest()


def summarize(manifest: dict) -> dict:
    frames = manifest.get("material_census", [])
    unbound, missing_source, empty_shader, null_textures = {}, {}, {}, {}
    classes = Counter()
    nodes_seen: set[str] = set()
    per_frame = []
    for frame in frames:
        resources = frame.get("resources", {})
        for key, row in resources.items():
            if row.get("source_exists") is False:
                missing_source[row.get("path", key)] = row.get("class")
            if row.get("code_empty") is True:
                empty_shader[row.get("path") or key] = row.get("resource_name", "")
            gpu = row.get("null_getter_gpu_bindings", {})
            for name in row.get("null_object_properties", []):
                if not name.startswith("shader_parameter/"):
                    continue
                uniform = name.split("/", 1)[1]
                live = gpu.get(uniform, {})
                if live.get("binding_rid_valid") is True:
                    continue
                ident = f"{row.get('path') or row.get('resource_name') or row.get('class')}::{uniform}"
                null_textures[ident] = live.get("value_type", "unobserved")
        frame_unbound = 0
        for binding in frame.get("bindings", []):
            nodes_seen.add(binding.get("node", "") + " " + str(binding.get("owner_script", "")))
            kind = binding.get("kind", "")
            if "classification" in binding:
                classes[binding["classification"]] += 1
                if binding["classification"].startswith("unbound_"):
                    frame_unbound += 1
                    ident = f"{binding['node']}#{binding.get('surface')}"
                    unbound[ident] = {"mesh_class": binding.get("mesh_class"),
                                      "visible_in_tree": binding.get("visible_in_tree"),
                                      "owner_script": binding.get("owner_script"),
                                      "classification": binding["classification"]}
            elif kind in ("environment",) and not binding.get("resource"):
                unbound[binding.get("node", "") + "#environment"] = {"classification": "environment_without_resource"}
        per_frame.append({"frame_id": frame.get("frame_id"), "binding_count": frame.get("binding_count"),
                          "unbound_surfaces": frame_unbound})
    probes = {}
    for name, tokens in SCENE_PROBES.items():
        hits = sorted(n for n in nodes_seen if any(t in n for t in tokens))
        probes[name] = {"binding_nodes": len(hits), "examples": hits[:4]}
    visible_unbound = {k: v for k, v in unbound.items() if v.get("visible_in_tree")}
    return {"frames_with_census": len(frames), "per_frame": per_frame,
            "classification_counts": dict(classes),
            "unbound_surface_count": len(unbound), "visible_unbound_surfaces": visible_unbound,
            "hidden_unbound_surface_count": len(unbound) - len(visible_unbound),
            "missing_source_resources": missing_source, "empty_shaders": empty_shader,
            "null_texture_uniforms_without_live_binding": null_textures,
            "scene_node_probes": probes}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, action="append", required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    scenes = []
    for path in args.manifest:
        manifest, digest = load(path)
        failures = manifest.get("failures", [])
        scenes.append({"biome_id": manifest.get("biome_id"), "scene": manifest.get("scene"),
                       "manifest": path.name, "manifest_sha256": digest,
                       "complete": manifest.get("complete"), "failures": failures,
                       "graphics_capture": manifest.get("graphics_capture"),
                       "rendering_method": manifest.get("rendering_method"),
                       "adapter": manifest.get("adapter"),
                       "captured_frame_count": manifest.get("captured_frame_count"),
                       "planned_frame_count": manifest.get("planned_frame_count"),
                       "capture_started_utc": manifest.get("capture_started_utc"),
                       "capture_finished_utc": manifest.get("capture_finished_utc"),
                       "frames": [{"frame_id": f.get("frame_id"), "destination": f.get("destination_display_name"),
                                   "player_position": f.get("player_position")} for f in manifest.get("frames", [])],
                       "census": summarize(manifest)})
        print(f"{path.name}: complete={manifest.get('complete')} frames={manifest.get('captured_frame_count')}")
    args.out.write_text(json.dumps({"scenes": scenes}, indent=1) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
