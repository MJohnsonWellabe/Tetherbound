"""Synthetic temporary packaging controls only; these files are never native evidence."""
from pathlib import Path
import base64
import copy
import json
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/net"))
sys.path.insert(0, str(ROOT / "tests"))
import f48_package_actual as package
import f48_profile_fixture as fixture
import f48_ci_ready as gate
import f48_configuration as configuration
import f48_evidence_closure as evidence
import save_document
import test_f48_ci_ready as readiness_fixture


class ActualPackageTests(unittest.TestCase):
    def descendant(self, prepared=True):
        """Synthetic shape controls only; never a claimed native writer call."""
        root = Path(self.spec["producers"]["behind"]["root"])
        source = fixture.source_input(root / "proof/peer-1/f48-behind-input", False)
        encode = lambda value: json.dumps(save_document.encode(value), separators=(",", ":"))
        before = fixture.read(source["character_path"])
        scope = {"character_id": source["id"], "world_id": "synthetic-world",
                 "world_namespace": "synthetic-namespace", "session_epoch": "synthetic-epoch"}
        before.update(display_name="SYNTHETIC ONLY", created_at="synthetic-created", last_played="before",
                      last_world_id=scope["world_id"], last_world_instance_id=scope["world_namespace"], migrated_from="")
        before["party"][0]["hp"] = 123.4567890123456
        payload = dict(before, last_played="after")
        raw = encode(payload).encode()
        source["character_path"].write_bytes(raw)
        personal = {k: v for k, v in payload.items() if k not in evidence.CHARACTER_ENVELOPE}
        row = dict(scope, status="pending", kind="creature_training", receipt="synthetic-receipt",
                   delivery_id="synthetic-identity", after={"party": personal["party"]})
        accepted = dict(row, status="accepted")
        trace = root / "proof/f48-passive/actual-synthetic.jsonl"
        header = {"character_id": source["id"], "world_namespace": scope["world_namespace"],
                  "session_epoch": scope["session_epoch"],
                  "condition_configuration_document":encode(fixture.read(fixture.ROOT / "data/config/creature_condition.json")),
                  "configuration_sha256": fixture.digest(fixture.ROOT / "data/config/creature_condition.json")}
        trace.parent.mkdir(parents=True, exist_ok=True)
        trace.write_text(json.dumps(header) + "\n", encoding="utf-8")
        passive = dict(header, path=str(trace), error="", events=0, sequence=-1, chain_sha256="",
                       anchor={"error": "", "sequence": -1, "chain_sha256": "",
                               "initial": personal["party"], "expected": personal["party"]})
        edge_path = root / "proof/f48-owner-saves/synthetic-owner.json"
        edge = {"session_epoch": scope["session_epoch"], "row_document": encode(row),
                "disk_document": encode(before), "passive_document": encode(passive),
                "packet": {"delivery_id": row["delivery_id"],
                                                            "phase": "after_owner_write_before_ack"}}
        fixture.write(edge_path, edge)
        request = {"character_id": source["id"], "world_id": scope["world_id"],
                   "world_instance_id": scope["world_namespace"], "character_only": True,
                   "write_split": False, "host": False, "display_name": payload["display_name"],
                   "character_data": personal, "data": {"reward_deliveries": {row["delivery_id"]: accepted}}}
        native_path = "user://characters/synthetic/character.json"
        file = {"path": native_path, "bytes_base64": base64.b64encode(raw).decode(),
                "sha256": evidence.digest_bytes(raw), "payload": payload}
        receipt = {"version": 1, "source": "SaveGame_locked_prepared_character_write_TRUE_BOOL" if prepared
                   else "SaveGame_locked_fallback_write_TRUE_BOOL", "writer_instance_id": -(2**63) + 501,
                   "writer_script": "res://scripts/save/save_game.gd",
                   "request_sha256": evidence.digest_bytes(encode(request).encode()), "files": {"character": file}}
        cert = {"source": "actual_request_bound_prepared_owner_passive_TRUE_BOOL_descendant" if prepared
                else "actual_request_bound_natural_fallback_TRUE_BOOL_descendant", "actual_writer_success": True,
                "request_document": encode(request), "receipt_document": encode(receipt),
                "accepted_parent_document": encode(accepted), "submission_passive_document": encode(passive),
                "original_edge_path": str(edge_path), "original_edge_sha256": fixture.digest(edge_path)}
        if prepared:
            cert.update(call_id=str(receipt["writer_instance_id"]) + "-3", scope_document=encode(scope),
                        prepared_document=encode(dict(scope, kind="owner_action_passive_preparation",
                                                       after={"character_id": source["id"], "party": personal["party"]})))
        else:
            cert.update(job_id="synthetic-job", session_epoch=scope["session_epoch"])
        cert_path = root / "proof" / ("f48-prepared-character-saves" if prepared else "f48-fallback-requests") / "synthetic.json"
        fixture.write(cert_path, cert)
        key, suffix = evidence.SUFFIXES[1 if prepared else 0]
        link = {"path": str(cert_path), "sha256": fixture.digest(cert_path), "request_bound": True}
        if not prepared:
            link["job_id"] = cert["job_id"]
        observation_path = root / "proof/f48-observations/f48_assert_snapshot-behind-1.json"
        observation = fixture.read(observation_path)
        observation["result"]["data"].update(character_path=native_path, character_sha256=file["sha256"],
            snapshot_source=evidence.OWNER + suffix, owns_world=False, passive_evidence=passive,
            passive_evidence_document=encode(passive),
            selected_edge={"path": str(edge_path), "sha256": fixture.digest(edge_path), "identity": row["delivery_id"]},
            **{key: link})
        fixture.write(observation_path, observation)
        return root, source, observation_path, cert_path, edge_path, trace

    def test_prepared_descendant_retains_exact_certificate_parent_and_passive_closure(self):
        root, source, observation, cert, edge, trace = self.descendant()
        originals = {p: p.read_bytes() for p in (source["character_path"], observation, cert, edge, trace)}
        result = package.package(self.input, self.output)
        self.assertFalse(result["acceptance_credit"])
        for path in (observation, cert, edge, trace):
            target = self.output / "producer-evidence/behind" / path.relative_to(root)
            self.assertEqual(target.read_bytes(), originals[path])
        for path, raw in originals.items():
            self.assertEqual(path.read_bytes(), raw)

    def test_fallback_descendant_retains_original_request_and_locked_bytes(self):
        root, source, observation, cert, edge, trace = self.descendant(False)
        package.package(self.input, self.output)
        self.assertEqual((self.output / "producer-evidence/behind" / cert.relative_to(root)).read_bytes(), cert.read_bytes())

    def test_missing_descendant_parent_refused_before_output(self):
        _, _, _, _, edge, _ = self.descendant()
        edge.unlink()  # Test-owned temporary scratch only.
        with self.assertRaises(OSError):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_altered_certificate_and_passive_prefix_are_refused(self):
        _, _, observation_path, cert, _, trace = self.descendant()
        cert.write_bytes(cert.read_bytes() + b" ")
        with self.assertRaisesRegex(ValueError, "source hash mismatch"):
            package.package(self.input, self.output)
        observation = fixture.read(observation_path)
        observation["result"]["data"]["prepared_descendant"]["sha256"] = fixture.digest(cert)
        fixture.write(observation_path, observation)
        value = fixture.read(cert)
        passive = save_document.decode(json.loads(value["submission_passive_document"]))
        passive.update(events=1, sequence=1, chain_sha256="0" * 64)
        value["submission_passive_document"] = json.dumps(save_document.encode(passive))
        fixture.write(cert, value)
        observation["result"]["data"]["prepared_descendant"]["sha256"] = fixture.digest(cert)
        fixture.write(observation_path, observation)
        with self.assertRaisesRegex(ValueError, "passive prefix truncated or changed"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_forged_bool_and_rounded_request_documents_are_refused(self):
        _, _, observation_path, cert, _, _ = self.descendant()
        value = fixture.read(cert)
        for changes, message in (({"actual_writer_success": 1}, "TRUE BOOL"),
                                 ({"request_document": json.dumps({"character_id": "unit-1"})}, "plain/rounded")):
            altered = dict(value, **changes)
            fixture.write(cert, altered)
            observation = fixture.read(observation_path)
            observation["result"]["data"]["prepared_descendant"]["sha256"] = fixture.digest(cert)
            fixture.write(observation_path, observation)
            with self.assertRaisesRegex(ValueError, message):
                package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_exact_parent_ack_and_request_float_changes_are_refused(self):
        _, _, observation_path, cert, _, _ = self.descendant()
        original = fixture.read(cert)
        mutations = []
        missing = copy.deepcopy(original)
        del missing["receipt_document"]
        mutations.append((missing, "missing lossless receipt_document"))
        ack = copy.deepcopy(original)
        accepted = save_document.decode(json.loads(ack["accepted_parent_document"]))
        accepted["after"]["party"][0]["hp"] += 0.0000000001
        ack["accepted_parent_document"] = json.dumps(save_document.encode(accepted))
        mutations.append((ack, "accepted parent changed complete original row"))
        changed = copy.deepcopy(original)
        request = save_document.decode(json.loads(changed["request_document"]))
        request["character_data"]["party"][0]["hp"] += 0.0000000001
        changed["request_document"] = json.dumps(save_document.encode(request))
        mutations.append((changed, "locked writer/request identity mismatch"))
        for value, message in mutations:
            fixture.write(cert, value)
            observation = fixture.read(observation_path)
            observation["result"]["data"]["prepared_descendant"]["sha256"] = fixture.digest(cert)
            fixture.write(observation_path, observation)
            with self.assertRaisesRegex(ValueError, message):
                package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_passive_condition_source_mismatch_is_refused_before_output(self):
        _, _, _, _, _, trace = self.descendant()
        header = json.loads(trace.read_text())
        header["configuration_sha256"] = "0" * 64
        trace.write_text(json.dumps(header) + "\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "passive header changed owner/epoch/configuration"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_complete_party_mismatch_cannot_hide_behind_the_same_uid(self):
        _, _, observation_path, cert, _, _ = self.descendant()
        value = fixture.read(cert)
        request = save_document.decode(json.loads(value["request_document"]))
        request["character_data"]["party"][0]["hp"] += 0.0000000001
        plan = save_document.decode(json.loads(value["prepared_document"]))
        plan["after"]["party"] = request["character_data"]["party"]
        value["request_document"] = json.dumps(save_document.encode(request))
        value["prepared_document"] = json.dumps(save_document.encode(plan))
        receipt = save_document.decode(json.loads(value["receipt_document"]))
        receipt["request_sha256"] = evidence.digest_bytes(value["request_document"].encode())
        value["receipt_document"] = json.dumps(save_document.encode(receipt))
        fixture.write(cert, value)
        observation = fixture.read(observation_path)
        observation["result"]["data"]["prepared_descendant"]["sha256"] = fixture.digest(cert)
        fixture.write(observation_path, observation)
        with self.assertRaisesRegex(ValueError, "request party differs from sealed passive checkpoint"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_recovery_plan_retains_actual_original_and_baseline_relationships(self):
        _, _, observation_path, cert, _, _ = self.descendant()
        value = fixture.read(cert)
        plan = save_document.decode(json.loads(value["prepared_document"]))
        original = {k: plan[k] for k in ("character_id", "world_id", "world_namespace", "session_epoch")}
        original.update(source_kind="portal_arrival", request={"origin": "SYNTHETIC ONLY"}, host_context={})
        original.update(before=copy.deepcopy(plan["after"]), after=copy.deepcopy(plan["after"]))
        baseline = copy.deepcopy(original)
        baseline["after"] = plan["after"]
        recovery = {"kind": "owner_portal_recovery", "original": original, "baseline": baseline,
                    "before": baseline["after"], "after": plan["after"]}
        value["prepared_document"] = json.dumps(save_document.encode(recovery))
        fixture.write(cert, value)
        observation = fixture.read(observation_path)
        observation["result"]["data"]["prepared_descendant"]["sha256"] = fixture.digest(cert)
        fixture.write(observation_path, observation)
        result = package.package(self.input, self.output)
        self.assertFalse(result["acceptance_credit"])
        self.assertEqual(result["transaction_cases"], 24)

    def test_missing_or_null_sealed_link_digests_are_refused(self):
        _, _, observation_path, cert, _, _ = self.descendant()
        original = fixture.read(observation_path)
        original_cert = fixture.read(cert)
        for target in ("prepared_descendant", "selected_edge"):
            for missing in (True, False):
                observation = copy.deepcopy(original)
                if missing:
                    del observation["result"]["data"][target]["sha256"]
                else:
                    observation["result"]["data"][target]["sha256"] = None
                # The review's explicit-null parent counterexample must also fail.
                value = dict(original_cert, original_edge_sha256=None) if target == "selected_edge" else original_cert
                fixture.write(cert, value)
                if target == "selected_edge":
                    observation["result"]["data"]["prepared_descendant"]["sha256"] = fixture.digest(cert)
                fixture.write(observation_path, observation)
                with self.assertRaisesRegex(ValueError, "missing link digest"):
                    package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_foreign_recovery_epoch_world_or_baseline_are_refused(self):
        _, _, observation_path, cert, _, _ = self.descendant()
        original_cert = fixture.read(cert)
        plan = save_document.decode(json.loads(original_cert["prepared_document"]))
        original = {k: plan[k] for k in ("character_id", "world_id", "world_namespace", "session_epoch")}
        original.update(source_kind="portal_arrival", request={"origin": "SYNTHETIC ONLY"}, host_context={},
                        before=copy.deepcopy(plan["after"]), after=copy.deepcopy(plan["after"]))
        baseline = dict(copy.deepcopy(original), after=copy.deepcopy(plan["after"]))
        recovery = {"kind": "owner_portal_recovery", "original": original, "baseline": baseline,
                    "before": copy.deepcopy(baseline["after"]), "after": plan["after"]}
        for section, field, value in (("original", "session_epoch", "foreign-epoch"),
                                      ("baseline", "world_id", "foreign-world"),
                                      ("baseline", "before", {"character_id": "foreign-before"})):
            invalid = copy.deepcopy(recovery)
            invalid[section][field] = value
            altered = dict(original_cert, prepared_document=json.dumps(save_document.encode(invalid)))
            fixture.write(cert, altered)
            observation = fixture.read(observation_path)
            observation["result"]["data"]["prepared_descendant"]["sha256"] = fixture.digest(cert)
            fixture.write(observation_path, observation)
            with self.assertRaisesRegex(ValueError, "recovery original/baseline changed"):
                package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def shipping_producers(self):
        pins = [{"file": "res://data/config/" + name,
                 "sha256": fixture.digest(fixture.ROOT / "data/config" / name)}
                for name in sorted(configuration.FILES)]
        for row in self.spec["producers"].values():
            root = Path(row["root"])
            profile_path = root / row["profile"]
            profile = fixture.read(profile_path)
            profile["production_configuration_pins"] = pins
            profile["test_configuration"] = [pin for pin in pins if not pin["file"].endswith("/combat.json")]
            fixture.write(profile_path, profile)
            row["profile_sha256"] = fixture.digest(profile_path)
            invocation = fixture.read(root / "invocation.json")
            invocation.update(profile_sha256=row["profile_sha256"],
                              effective_configuration=pins, shipping_configuration=True)
            fixture.write(root / "invocation.json", invocation)
        fixture.write(self.input, self.spec)
        return pins

    def test_shipping_package_preserves_all_seven_pins_and_every_original_start(self):
        pins = self.shipping_producers()
        result = package.package(self.input, self.output)
        profile = fixture.read(self.output / "profile.json")
        self.assertEqual(profile["production_configuration_pins"], pins)
        self.assertEqual(result["transaction_cases"], 24)
        self.assertFalse(result["acceptance_credit"])
        self.assertEqual(set(profile["suite_profiles"]) | set(profile["transaction_profiles"]), set(package.CAPTURES))
        for row in profile["test_configuration"]:
            source = fixture.ROOT / row["file"].removeprefix("res://")
            self.assertEqual(Path(row["overlay_file"]).read_bytes(), source.read_bytes())
            self.assertEqual(row["sha256"], row["source_sha256"])

    def test_shipping_cannot_mix_with_overlay_or_drop_actual_combat_pin(self):
        self.shipping_producers()
        row = self.spec["producers"]["boss_four"]
        root = Path(row["root"])
        profile_path = root / row["profile"]
        profile = fixture.read(profile_path)
        profile["production_configuration_pins"] = [pin for pin in profile["production_configuration_pins"]
                                                    if not pin["file"].endswith("/combat.json")]
        fixture.write(profile_path, profile)
        row["profile_sha256"] = fixture.digest(profile_path)
        invocation = fixture.read(root / "invocation.json")
        invocation["profile_sha256"] = row["profile_sha256"]
        fixture.write(root / "invocation.json", invocation)
        fixture.write(self.input, self.spec)
        with self.assertRaisesRegex(ValueError, "Complete seven"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_shipping_and_overlay_producers_cannot_be_combined(self):
        original = fixture.read(Path(self.spec["producers"]["boss_four"]["root"]) / "producer-profile/profile.json")
        self.shipping_producers()
        row = self.spec["producers"]["boss_four"]
        root = Path(row["root"])
        fixture.write(root / row["profile"], original)
        row["profile_sha256"] = fixture.digest(root / row["profile"])
        invocation = fixture.read(root / "invocation.json")
        invocation.update(profile_sha256=row["profile_sha256"], shipping_configuration=False,
                          effective_configuration=[{"file": pin["file"], "sha256": pin["sha256"]}
                                                   for pin in original["test_configuration"]])
        fixture.write(root / "invocation.json", invocation)
        fixture.write(self.input, self.spec)
        with self.assertRaisesRegex(ValueError, "effective configurations disagree"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def setUp(self):
        self.seed = readiness_fixture.ReadinessTests("test_missing_cut_route_refused")
        self.seed.setUp()
        self.addCleanup(self.seed.doCleanups)
        self.root = self.seed.root
        self.output = self.root / "packaged"
        self.spec = {"provenance": "SYNTHETIC UNIT TEST ONLY, NO NATIVE OR GAMEPLAY CLAIM",
                     "producers": {}, "starts": {}}
        for producer, script in package.SCRIPTS.items():
            root = self.root / ("synthetic-" + producer)
            start = self.seed.profile["suite_profiles"][producer]
            profile = {"provenance": self.spec["provenance"], "saves": start["saves"],
                       "routes": start["routes"], "outcomes": start["outcomes"],
                       "configuration_scope": "full", "test_configuration": []}
            for row in self.seed.profile["test_configuration"]:
                target = root / "mechanics-start/test-configuration/data/config" / Path(row["file"]).name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(row["overlay_file"], target)
                profile["test_configuration"].append(dict(row, overlay_file=str(target)))
            profile_path = root / "producer-profile/profile.json"
            fixture.write(profile_path, profile)
            self.spec["producers"][producer] = {"root": str(root), "profile": "producer-profile/profile.json",
                                                "profile_sha256": fixture.digest(profile_path)}
            fixture.write(root / "invocation.json", {"profile_sha256": fixture.digest(profile_path),
                "command": ["SYNTHETIC-NOT-AN-ENGINE", "--script", script],
                "effective_configuration": [{"file": row["file"], "sha256": row["sha256"]}
                                            for row in profile["test_configuration"]]})
            fixture.write(root / "net-run/NET_RUN.json", {"failures": [], "fatal": "",
                "peers": [{"index": peer, "exited": True, "unexpected_exit": False}
                          for peer in range(len(start["saves"]))]})
            (root / "coordinator.log").write_text("SYNTHETIC UNIT TEST ONLY\nALL CHECKS PASSED\n", encoding="utf-8")
            report = ["SYNTHETIC UNIT TEST ONLY", "**Verdict: PASS**"]
            for name, (expected_producer, capture) in package.CAPTURES.items():
                if expected_producer != producer: continue
                source_start = self.seed.profile["suite_profiles" if name in gate.SUITES else "transaction_profiles"][name]
                for peer, source in enumerate(source_start["saves"]):
                    destination = root / "proof" / f"peer-{peer}" / capture
                    shutil.copytree(source, destination)
                    inputs = fixture.source_input(destination, peer == 0)
                    observation = {"action": "f48_assert_snapshot", "result": {"verdict": "PASS", "data": {
                        "character_id": inputs["id"], "character_sha256": fixture.digest(inputs["character_path"]),
                        "world_sha256": fixture.digest(inputs["world_path"]) if peer == 0 else "",
                        "snapshot_source": "actual_owner_BOOL_edge_full_canonical_after_and_accepted_ACK"}}}
                    fixture.write(root / "proof/f48-observations" / f"f48_assert_snapshot-{name}-{peer}.json", observation)
                    for path in destination.rglob("*"):
                        if path.is_file(): report.append(f"- `{path.relative_to(root / 'proof').as_posix()}`")
                route_path = self.root / "synthetic-routes" / (name + ".json")
                fixture.write(route_path, {key: source_start[key] for key in ("provenance", "routes", "outcomes")})
                self.spec["starts"][name] = {"producer": producer, "capture": capture, "route_pack": str(route_path),
                                             "route_pack_sha256": fixture.digest(route_path)}
            (root / "proof/PROOF.md").write_text("\n".join(report) + "\n", encoding="utf-8")
        self.input = self.root / "synthetic-package.json"
        self.save()

    def save(self):
        fixture.write(self.input, self.spec)

    def test_complete_package_delegates_original_gate_and_preserves_source_bytes(self):
        originals = {path: fixture.digest(path) for path in self.root.rglob("*") if path.is_file()}
        result = package.package(self.input, self.output)
        self.assertTrue(result["ok"])
        self.assertFalse(result["acceptance_credit"])
        self.assertFalse(result["earned_checkpoint"])
        self.assertTrue(result["native_oracles_required"])
        self.assertEqual(result["transaction_cases"], 24)
        self.assertEqual(gate.validate(self.output / "profile.json")["saved_documents"], 38)
        for path, digest in originals.items(): self.assertEqual(fixture.digest(path), digest)
        self.assertTrue((self.output / "producer-evidence/behind/proof/PROOF.md").is_file())

    def test_missing_behind_refused_before_any_output(self):
        del self.spec["producers"]["behind"]
        self.save()
        with self.assertRaisesRegex(ValueError, "behind"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_failed_terminal_and_wrong_producer_cannot_be_packaged(self):
        root = Path(self.spec["producers"]["loop"]["root"])
        run = fixture.read(root / "net-run/NET_RUN.json")
        run["fatal"] = "SYNTHETIC FAILURE"
        fixture.write(root / "net-run/NET_RUN.json", run)
        with self.assertRaisesRegex(ValueError, "producer failed"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())
        run["fatal"] = ""
        fixture.write(root / "net-run/NET_RUN.json", run)
        invocation = fixture.read(root / "invocation.json")
        invocation["command"] = ["SYNTHETIC WRONG SCRIPT"]
        fixture.write(root / "invocation.json", invocation)
        with self.assertRaisesRegex(ValueError, "different producer"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_changed_saved_bytes_need_sealed_native_hash_not_just_a_directory(self):
        root = Path(self.spec["producers"]["behind"]["root"])
        path = fixture.source_input(root / "proof/peer-1/f48-behind-input", False)["character_path"]
        path.write_bytes(path.read_bytes() + b" ")
        with self.assertRaisesRegex(ValueError, "sealed native snapshot hashes"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_route_hash_and_named_capture_are_not_replaceable(self):
        row = self.spec["starts"]["release"]
        row["route_pack_sha256"] = "0" * 64
        self.save()
        with self.assertRaisesRegex(ValueError, "Reviewed source hash mismatch"):
            package.package(self.input, self.output)
        row["route_pack_sha256"] = fixture.digest(Path(row["route_pack"]))
        row["capture"] = "f48-loop-input"
        self.save()
        with self.assertRaisesRegex(ValueError, "Wrong original capture"):
            package.package(self.input, self.output)
        self.assertFalse(self.output.exists())

    def test_missing_original_route_and_parent_path_refused(self):
        row = self.spec["starts"]["behind"]
        routes = fixture.read(Path(row["route_pack"]))
        del routes["routes"]["behind_enter_tidewake"]
        fixture.write(Path(row["route_pack"]), routes)
        row["route_pack_sha256"] = fixture.digest(Path(row["route_pack"]))
        self.save()
        with self.assertRaisesRegex(ValueError, "Missing original routes"):
            package.package(self.input, self.output)
        with self.assertRaisesRegex(ValueError, "Unsafe producer-relative"):
            package.checked(self.root, "../outside")
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
