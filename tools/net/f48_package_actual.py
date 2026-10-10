"""Assemble all nine F48 starts from successful, reviewed native producers.

Input JSON has provenance, producers, and starts. Producers are loop, behind,
boss_four; each has root, profile (relative to root), and profile_sha256.
Each named start has producer, capture (the fixed label below), route_pack,
and route_pack_sha256. Route paths are relative to the input JSON's directory.
This wrapper validates terminal evidence, copies original bytes through the
existing packager, and runs the existing complete-input gate. It never runs
Godot, changes a save, or claims native smoke/24-cut acceptance.
"""
from __future__ import annotations

import argparse
import copy
import json
import re
import shutil
import tempfile
from pathlib import Path

import f48_ci_ready as gate
import f48_profile_fixture as fixture
import f48_profile_ready as ready
import f48_configuration as configuration
import f48_evidence_closure as evidence
from f48_relocate_profile import tail

CAPTURES = {"loop": ("loop", "f48-loop-input"),
            "behind": ("behind", "f48-behind-input"),
            "boss_four": ("boss_four", "f48-boss-four-input"),
            **{name: ("loop", "f48-before-" + name) for name in fixture.OPERATIONS}}
SCRIPTS = {"loop": "tools/net/f48_prepare.gd", "behind": "tools/net/f48_prepare_behind.gd",
           "boss_four": "tools/net/f48_prepare_boss_four.gd"}
require = fixture.require


def fields(value: object, expected: set[str], label: str) -> None:
    require(isinstance(value, dict) and set(value) == expected, f"Unknown/missing {label} fields")


def checked(root: Path, relative: str | Path) -> Path:
    suffix = Path(relative)
    require(not suffix.is_absolute() and suffix.parts and
            all(part not in {"..", ".", ""} for part in suffix.parts), "Unsafe producer-relative path")
    path = root / suffix
    require(path.resolve().is_relative_to(root), "Producer path escapes original root")
    for item in (path, *path.parents):
        if not item.is_relative_to(root): break
        require(not item.is_symlink() and not (hasattr(item, "is_junction") and item.is_junction()),
                "Original producer links/junctions refused")
    return path


def package(input_path: Path, output: Path) -> dict:
    input_path = input_path.resolve()
    output = output.resolve()
    require(not output.exists(), "Fresh package output required; preserve prior evidence")
    spec = fixture.read(input_path)
    fields(spec, {"provenance", "producers", "starts"}, "actual package")
    require(isinstance(spec["provenance"], str) and spec["provenance"].strip(), "Disclose producer shortcuts")
    require(isinstance(spec["producers"], dict) and set(spec["producers"]) == set(SCRIPTS),
            "Require successful loop, behind and four-peer boss producers")
    require(isinstance(spec["starts"], dict) and set(spec["starts"]) == set(CAPTURES),
            "Require all nine original starts; incomplete bundles are refused")
    pins: dict[Path, str] = {}

    def pin(path: Path, expected: str | None = None) -> str:
        actual = fixture.digest(path)
        require(expected is None or (isinstance(expected, str) and re.fullmatch(r"[0-9a-f]{64}", expected)
                                     and actual == expected), f"Reviewed source hash mismatch: {path}")
        require(path not in pins or pins[path] == actual, f"Source changed during assembly: {path}")
        pins[path] = actual
        return actual

    pin(input_path)
    producers = {}
    common_configs = None
    for name, row in spec["producers"].items():
        fields(row, {"root", "profile", "profile_sha256"}, "producer")
        source_root = Path(row["root"])
        if not source_root.is_absolute(): source_root = input_path.parent / source_root
        require(not source_root.is_symlink() and not (hasattr(source_root, "is_junction") and source_root.is_junction()),
                "Original producer root cannot be a link")
        root = source_root.resolve()
        require(root.is_dir() and not output.resolve().is_relative_to(root) and not root.is_relative_to(output.resolve()),
                "Package output must be disjoint from every producer")
        profile_path = checked(root, row["profile"])
        pin(profile_path, row["profile_sha256"])
        terminal = gate.terminal_producer(root, profile_path, row["profile_sha256"])
        for relative, digest in terminal.items(): pin(checked(root, relative), digest)
        invocation = fixture.read(root / "invocation.json")
        require(SCRIPTS[name] in invocation.get("command", []), "Terminal evidence belongs to a different producer")
        report = checked(root, "proof/PROOF.md")
        pin(report)
        report_text = report.read_text(encoding="utf-8")
        require("**Verdict: PASS**" in report_text and "**Verdict: FAIL**" not in report_text,
                "Actual producer proof report did not pass")
        profile = fixture.read(profile_path)
        require(len(profile["saves"]) == (4 if name == "boss_four" else 2), "Wrong original producer peer count")
        require(profile.get("configuration_scope") == "full", "Reviewed full producer configuration required")
        config_rows = profile.get("test_configuration", [])
        require(isinstance(config_rows, list) and len(config_rows) == len(ready.CONFIGURATION_FILES) and
                {r["file"] for r in config_rows} == {"res://data/config/" + n for n in ready.CONFIGURATION_FILES},
                "Require all original configuration pins")
        relocated = copy.deepcopy(profile)
        signature = []
        shipping = configuration.shipping_pins(relocated)
        if shipping is not None:
            for source, digest in configuration.shipping_files(fixture.ROOT, relocated):
                pin(source, digest)
            signature.append(("res://data/config/combat.json",
                              next(row["sha256"] for row in shipping if row["file"].endswith("/combat.json")),
                              "shipping"))
        for config in relocated["test_configuration"]:
            # Production producer paths are preserved in the reviewed profile;
            # artifact extraction changes only their parent directory here.
            if shipping is not None:
                source = fixture.ROOT / config["file"].removeprefix("res://")
                config["source_sha256"] = config["sha256"]
            else:
                suffix = tail(config["overlay_file"], "test-configuration")
                source = checked(root, Path("mechanics-start") / suffix)
            require(source.name == Path(config["file"]).name, "Configuration filename changed")
            pin(source, config["sha256"])
            pin(fixture.ROOT / "data/config" / source.name, config["source_sha256"])
            signature.append((config["file"], config["sha256"], config["source_sha256"]))
            config["overlay_file"] = str(source)
        signature.sort()
        require(common_configs is None or signature == common_configs, "Producer effective configurations disagree")
        common_configs = signature
        snapshots = []
        for observation in checked(root, "proof/f48-observations").glob("f48_assert_snapshot-*.json"):
            checked(root, observation.relative_to(root))
            pin(observation)
            value = fixture.read(observation)
            result = value.get("result", {})
            data = result.get("data", {})
            if value.get("action") == "f48_assert_snapshot" and result.get("verdict") == "PASS":
                snapshots.append((observation, data.get("character_id"), data.get("character_sha256"),
                                  data.get("world_sha256"), data))
        require(snapshots, "Actual sealed passing snapshot evidence missing")
        producers[name] = {"root": root, "profile": relocated, "profile_path": profile_path,
                           "terminal": terminal, "report": report_text, "snapshots": snapshots,
                           "used_snapshots": set(), "evidence_closure": set()}

    starts = {}
    for name, row in spec["starts"].items():
        fields(row, {"producer", "capture", "route_pack", "route_pack_sha256"}, "captured start")
        require((row["producer"], row["capture"]) == CAPTURES[name], "Wrong original capture/producer for named start")
        producer = producers[row["producer"]]
        roots = []
        for peer in range(4 if name == "boss_four" else 2):
            relative = Path("proof") / f"peer-{peer}" / row["capture"]
            root = checked(producer["root"], relative)
            source = fixture.source_input(root, peer == 0)
            for item in root.rglob("*"): checked(producer["root"], item.relative_to(producer["root"]))
            originals = [source["character_path"]]
            if peer == 0: originals += [source["world_path"], source["slot_path"]]
            matches = [item for item in producer["snapshots"] if item[1] == source["id"] and
                       item[2] == fixture.digest(source["character_path"]) and
                       (peer != 0 or item[3] == fixture.digest(source["world_path"]))]
            require(matches, "Captured document bytes lack matching sealed native snapshot hashes")
            for observation, _, _, _, data in matches:
                pin(observation)
                producer["used_snapshots"].add(observation.relative_to(producer["root"]).as_posix())
                producer["evidence_closure"].update(evidence.closure(data, source, producer["root"], checked, pin))
            for path in originals:
                pin(path)
                artifact = path.relative_to(producer["root"] / "proof").as_posix()
                require(f"`{artifact}`" in producer["report"], "Capture bytes are not listed in actual producer report")
            roots.append(root)
        require(len({fixture.source_input(root, peer == 0)["id"] for peer, root in enumerate(roots)}) == len(roots),
                "Distinct actual peer identities required")
        route_path = Path(row["route_pack"])
        if not route_path.is_absolute(): route_path = input_path.parent / route_path
        pin(route_path, row["route_pack_sha256"])
        routes = fixture.read(route_path)
        gate.validate_routes(name, routes)
        ready.prerequisite(name, [fixture.source_input(root, peer == 0) for peer, root in enumerate(roots)])
        starts[name] = {"sources": [str(root) for root in roots], "route_pack": str(route_path),
                        "origin": f"Actual terminal {row['producer']} producer {producer['root']}; "
                                  f"reviewed profile {spec['producers'][row['producer']]['profile_sha256']}; "
                                  f"original capture {row['capture']}. No campaign/CI acceptance credit."}

    # Nothing is written until all producers, captures, prerequisites and routes
    # pass. The existing packager remains the sole saved-document copy path.
    for path, digest in pins.items(): require(fixture.digest(path) == digest, f"Source changed before packaging: {path}")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="f48-package-spec-", dir=output.parent) as temporary:
        stage = Path(temporary)
        config_path = stage / "configuration-profile.json"
        fixture.write(config_path, producers["loop"]["profile"])
        pack_path = stage / "input-pack.json"
        fixture.write(pack_path, {"provenance": spec["provenance"], "configuration_profile": str(config_path), "starts": starts})
        ready.generate(pack_path, output, True)
        result = gate.validate(output / "profile.json", output.resolve())
        for path, digest in pins.items(): require(fixture.digest(path) == digest, f"Original source changed during copy: {path}")
        shutil.copyfile(input_path, output / "package-request.json")
        shutil.copyfile(pack_path, output / "actual-input-pack.json")
    for name, producer in producers.items():
        for relative in (*producer["terminal"], "proof/PROOF.md", str(Path(spec["producers"][name]["profile"])),
                         *sorted(producer["used_snapshots"] | producer["evidence_closure"])):
            source = checked(producer["root"], relative)
            target = output / "producer-evidence" / name / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            require(fixture.digest(target) == pins[source], "Copied terminal evidence changed")
        condition = fixture.ROOT / "data/config/creature_condition.json"
        if condition in pins:
            target = output / "producer-evidence" / name / "configuration/creature_condition.json"
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(condition, target)
            require(fixture.digest(target) == pins[condition], "Copied passive configuration changed")
    for path, digest in pins.items(): require(fixture.digest(path) == digest, f"Original evidence changed during copy: {path}")
    result.update({"earned_checkpoint": False, "native_oracles_required": True,
                   "source_pins": [{"path": str(path), "sha256": digest} for path, digest in pins.items()]})
    fixture.write(output / "actual-producer-evidence.json", result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        result = package(args.input, args.output)
        print(json.dumps({key: value for key, value in result.items() if key != "source_pins"}))
        return 0
    except (OSError, ValueError, KeyError, TypeError, IndexError, AttributeError) as error:
        print(json.dumps({"ok": False, "error": str(error), "acceptance_credit": False}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
