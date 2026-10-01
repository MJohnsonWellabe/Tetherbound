#!/usr/bin/env python3
"""Bounded source/package refusal checks; no engine, native runner or network."""
import importlib.util
import json
import re
import struct
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("f49_verify_release", ROOT / "tools/f49_verify_release.py")
verify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify)


def function(path, name):
    text = path.read_text(encoding="utf-8")
    start = text.index("func " + name + "(")
    end = re.search(r"\n(?:static )?func ", text[start + 1:])
    return text[start:start + 1 + end.start() if end else len(text)].strip()


def refuses(call, reason):
    try:
        call()
    except ValueError:
        return
    raise AssertionError("unsafe evidence was accepted: " + reason)


def source_contracts():
    for path in [ROOT / "tests/smoke_four_biome_continuous.gd", *sorted((ROOT / "tests/helpers").glob("f49_*.gd"))]:
        text = path.read_text(encoding="utf-8")
        for resource in re.findall(r'"res://([^"\n]+)"', text):
            assert (ROOT / resource).exists(), f"missing resource: {path}: {resource}"
    binder = function(ROOT / "tests/helpers/meadows_earned_warden_segment.gd", "_bind_ending")
    adapted = function(ROOT / "tests/helpers/f49_warden_finale.gd", "_bind_ending")
    assert adapted == binder.replace(" or _rift == null", ""), "Warden adapter changed guards beyond retired Rift presence"
    cloud = function(ROOT / "tests/helpers/cloudreach_live_segment.gd", "run")
    adapted = function(ROOT / "tests/helpers/f49_cloudreach_chapter.gd", "run")
    expected = cloud.replace('if not _has("legendary_freed") or not _has("realm_key_cloudreach"):',
                            'if not _has("water_currents_restored") or game.call("portal_view", "cloudreach").get("character_open") != true:')
    expected = expected.replace("Cloudreach continuation lacks the earned Meadows finale and key",
                                "F49 Cloudreach requires earned Tidewake restoration and the actual personal Cloudreach portal unlock")
    expected = expected.replace("earned live Meadows crossing", "earned live Tidewake portal")
    assert adapted == expected, "Cloudreach adapter changed flight/combat/contact/party guards"
    session = json.loads((ROOT / "data/config/multiplayer.json").read_text(encoding="utf-8"))["session"]
    print("Shared gates (report only; never enable):", {key: value for key, value in session.items() if key.startswith("redesign_")})
    print("PASS resource references and inherited guard equivalence")


def package_refusals():
    commit = "a" * 40
    run = {"id": 7, "head_sha": commit, "status": "completed", "conclusion": "success",
           "repository": {"full_name": "MJohnsonWellabe/Tetherbound"}}
    jobs = {"total_count": 2, "jobs": [
        {"name": "export", "run_id": 7, "conclusion": "success", "steps": [
            {"name": name, "conclusion": "success"} for name in
            ("Export Windows build", "Verify the export is a real Windows binary",
             "Verify the exported build runs and has ground under the player")]},
        {"name": "ci-gate", "run_id": 7, "conclusion": "success"}]}
    artifact = {"id": 9, "name": "Tetherbound-windows-debug", "expired": False,
                "workflow_run": {"id": 7, "head_sha": commit}}
    with tempfile.TemporaryDirectory(prefix="f49_source_contract_") as directory:
        path = Path(directory) / "isolated_fixture.zip"
        pe = bytearray(10_000_001)
        pe[:2] = b"MZ"
        struct.pack_into("<I", pe, 0x3C, 0x80)
        pe[0x80:0x84] = b"PE\0\0"
        struct.pack_into("<H", pe, 0x84, 0x8664)
        with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("Tetherbound.exe", pe)
            archive.writestr("Tetherbound.pck", b"GDPCfixture; never a played build")
        package_digest = verify.digest(path)
        artifact["digest"] = "sha256:" + package_digest
        verify.package_check(path, commit, package_digest, run, jobs, artifact, "MJohnsonWellabe/Tetherbound")
        refuses(lambda: verify.package_check(path, "b" * 40, package_digest, run, jobs, artifact,
                                            "MJohnsonWellabe/Tetherbound"), "wrong commit")
        refuses(lambda: verify.package_check(path, commit, "b" * 64, run, jobs, artifact,
                                            "MJohnsonWellabe/Tetherbound"), "wrong download digest")
        jobs["jobs"][0]["steps"][2]["conclusion"] = "skipped"
        refuses(lambda: verify.package_check(path, commit, package_digest, run, jobs, artifact,
                                            "MJohnsonWellabe/Tetherbound"), "skipped exported runtime proof")
        jobs["jobs"][0]["steps"][2]["conclusion"] = "success"
        with zipfile.ZipFile(path, "a") as archive:
            archive.writestr("../unsafe.txt", "isolated adversarial setup")
        package_digest = verify.digest(path)
        artifact["digest"] = "sha256:" + package_digest
        refuses(lambda: verify.package_check(path, commit, package_digest, run, jobs, artifact,
                                            "MJohnsonWellabe/Tetherbound"), "unsafe ZIP traversal")
    print("PASS isolated package refusal cases; no executable launched and no runtime credit")


def evidence_refusals():
    with tempfile.TemporaryDirectory(prefix="f49_log_contract_") as directory:
        path = Path(directory) / "isolated.log"
        result = {"campaign_complete": True, "counts_as_proof": True, "failures": [],
                  "reached": "completed_world_continuation", "dry_run": False, "resumed_from": ""}
        journey = {"order": verify.ORDER, "shortcuts": ["isolated verifier setup; never real campaign evidence"],
                   "legacy_cards": {key: "queued" for key in ("M2", "M3", "S2", "T2")}}
        handoffs = "\n".join("F49 DISK HANDOFF " + json.dumps({"boundary": label, "commit": "a" * 40,
                              "files_sha256": {"isolated.fixture": "b" * 64}}) for label in
                              ("meadows_settled", "tidewake_settled", "cloudreach_settled", "stormwood_settled", "completed_world"))
        path.write_text("FRESH CAMPAIGN RESULT " + json.dumps(result) + "\nF49 JOURNEY " + json.dumps(journey) + "\n" + handoffs)
        verify.journey_check(path, "a" * 40)
        refuses(lambda: verify.journey_check(path, "c" * 40), "wrong campaign/handoff source identity")
        result["resumed_from"] = "fixture"
        path.write_text("FRESH CAMPAIGN RESULT " + json.dumps(result) + "\nF49 JOURNEY " + json.dumps(journey))
        refuses(lambda: verify.journey_check(path, "a" * 40), "resumed piece falsely marked completion")
    refuses(lambda: verify.device_check({"commit": "a" * 40}, "a" * 40), "absent hardware samples")
    refuses(lambda: verify.owner_check({"commit": "a" * 40, "package_sha256": "b" * 64}, "a" * 40, "b" * 64),
            "absent human attestation")
    assert verify.percentile([33, 33, 33, 100], 95) == 100, "hitch percentile was discarded"
    print("PASS evidence refusal cases; isolated setup is never owner/device/campaign proof")


if __name__ == "__main__":
    source_contracts()
    package_refusals()
    evidence_refusals()
