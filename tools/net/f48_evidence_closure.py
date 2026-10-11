"""Preserve and verify sealed descendant evidence; never infer native success.

The native observer binds the actual live writer and independently replays
passive operations. This module verifies the published byte/link closure only.
Older descendant certificates without lossless documents remain refused.
"""
import base64
import copy
import hashlib
import json
import re

import save_document
import f48_profile_fixture as fixture
from f48_relocate_profile import tail

OWNER = "actual_owner_BOOL_edge_full_canonical_after_and_accepted_ACK"
ORIGINAL = "unchanged_original_admitted_disk_no_initial_memory_disk_convergence_or_saved_live_care_bond_claim"
SUFFIXES = (("fallback_descendant", "_and_separate_request_bound_natural_fallback_descendant"),
            ("prepared_descendant", "_and_separate_request_bound_prepared_checkpoint_descendant"))
CHARACTER_ENVELOPE = {"version", "character_id", "display_name", "created_at", "last_played",
                      "last_world_id", "last_world_instance_id", "migrated_from"}
WORLD_ENVELOPE = {"version", "world_id", "display_name", "created_at", "last_played", "migrated_from"}


def require(ok, message):
    if not ok:
        raise ValueError("Descendant evidence: " + message)


def digest_bytes(data):
    return hashlib.sha256(data).hexdigest()


def exact(left, right):
    # Match native authority equality for safe integral numbers; float bits
    # never receive a tolerance and bool never aliases an integer.
    if isinstance(left, dict) and isinstance(right, dict):
        return left.keys() == right.keys() and all(exact(left[k], right[k]) for k in left)
    if isinstance(left, list) and isinstance(right, list):
        return len(left) == len(right) and all(exact(a, b) for a, b in zip(left, right))
    if type(left) in (int, float) and type(right) in (int, float):
        if type(left) != type(right) and (abs(left) > save_document.SAFE or abs(right) > save_document.SAFE):
            return False
        return left == right
    return type(left) is type(right) and left == right


def document(value, key):
    raw = value.get(key)
    require(isinstance(raw, str) and raw, "missing lossless " + key)
    envelope = json.loads(raw)
    require(envelope.get("format") == save_document.FORMAT, "plain/rounded " + key)
    return save_document.decode(envelope)


def closure(data, source, root, checked, pin):
    """Return original producer-relative files to copy after all gates pass."""
    retained = set()

    def linked(path, expected=None, folder=None, authoritative=False):
        relative = tail(path, "proof")
        require(len(relative.parts) >= 3 and (folder is None or relative.parts[1] == folder),
                "wrong linked evidence directory")
        actual = checked(root, relative)
        if authoritative or expected is not None:
            require(isinstance(expected, str) and re.fullmatch(r"[0-9a-f]{64}", expected), "missing link digest")
        pin(actual, expected)
        retained.add(relative.as_posix())
        return actual

    label = data.get("snapshot_source")
    selected = [(key, suffix) for key, suffix in SUFFIXES if data.get(key)]
    require(label in {OWNER, ORIGINAL} if not selected else
            label == OWNER + "".join(suffix for _, suffix in selected), "unsupported snapshot source")
    if not selected:
        # Preserve the authentic parent/trace even for an unsuffixed snapshot.
        if data.get("selected_edge", {}).get("path"):
            linked(data["selected_edge"]["path"], data["selected_edge"].get("sha256"), authoritative=True)
        if data.get("passive_evidence", {}).get("path"):
            linked(data["passive_evidence"]["path"], folder="f48-passive")
        return retained

    selected_edge = data.get("selected_edge", {})
    edge_path = linked(selected_edge.get("path", ""), selected_edge.get("sha256"), "f48-owner-saves", True)
    edge = json.loads(edge_path.read_bytes())
    row = document(edge, "row_document")
    original_disk = document(edge, "disk_document")
    identity = selected_edge.get("identity")
    require(isinstance(identity, str) and identity and edge.get("packet", {}).get("delivery_id") == identity
            and edge.get("packet", {}).get("phase") == "after_owner_write_before_ack",
            "original owner BOOL boundary missing")
    scope = {"character_id": source["id"], "world_id": original_disk.get("last_world_id"),
             "world_namespace": original_disk.get("last_world_instance_id"),
             "session_epoch": edge.get("session_epoch")}
    require(all(isinstance(v, str) and v for v in scope.values())
            and row.get("delivery_id") == identity
            and row.get("character_id") == source["id"]
            and row.get("world_id") == scope["world_id"]
            and row.get("world_namespace") == scope["world_namespace"], "original owner scope mismatch")
    captured = source["character_path"].read_bytes()

    condition = fixture.ROOT / "data/config/creature_condition.json"
    condition_hash = pin(condition)
    edge_passive = document(edge, "passive_document")

    def passive(evidence):
        require(isinstance(evidence, dict) and evidence.get("error") == "", "passive source error")
        trace = linked(evidence.get("path", ""), folder="f48-passive")
        events = evidence.get("events")
        require(type(events) is int and 0 <= events <= 1200000, "invalid passive prefix length")
        chain, sequence, count = "", -1, 0
        anchor = evidence.get("anchor", {})
        anchor_sequence = anchor.get("sequence")
        require(type(anchor_sequence) is int, "missing original passive anchor sequence")
        anchor_matched = anchor_sequence == -1 and anchor.get("chain_sha256") == ""
        with trace.open(encoding="utf-8") as stream:
            header_line = stream.readline()
            require(header_line, "missing passive header")
            header = json.loads(header_line)
            require(header.get("character_id") == scope["character_id"]
                    and header.get("world_namespace") == scope["world_namespace"]
                    and header.get("session_epoch") == scope["session_epoch"]
                    and header.get("configuration_sha256") == evidence.get("configuration_sha256") == condition_hash,
                    "passive header changed owner/epoch/configuration")
            require(exact(document(header, "condition_configuration_document"), fixture.read(condition)),
                    "actual condition configuration changed")
            for line in stream:
                if count == events:
                    break
                raw = line.removesuffix("\n").removesuffix("\r")
                event = json.loads(raw)
                require(type(event.get("s")) is int and event["s"] > 0
                        and (count == 0 or event["s"] == sequence + 1), "passive sequence discontinuity")
                chain = digest_bytes((chain + raw).encode())
                sequence = event["s"]
                count += 1
                if sequence == anchor_sequence:
                    anchor_matched = chain == anchor.get("chain_sha256")
        require(count == events and chain == evidence.get("chain_sha256")
                and sequence == evidence.get("sequence"), "passive prefix truncated or changed")
        require(anchor_matched, "original passive anchor prefix missing or changed")
        require(evidence.get("character_id") == scope["character_id"]
                and evidence.get("world_namespace") == scope["world_namespace"]
                and evidence.get("session_epoch") == scope["session_epoch"]
                and evidence.get("anchor", {}).get("error") == "", "passive anchor scope/error")

    snapshot_passive = document(data, "passive_evidence_document")
    passive(edge_passive)
    passive(snapshot_passive)
    for field in ("initial", "sequence", "chain_sha256"):
        require(exact(snapshot_passive.get("anchor", {}).get(field), edge_passive.get("anchor", {}).get(field)),
                "snapshot replaced original passive anchor")
    for key, _ in selected:
        link = data[key]
        require(link.get("request_bound") is True, "unbound descendant")
        prepared = key == "prepared_descendant"
        cert_path = linked(link.get("path", ""), link.get("sha256"),
                           "f48-prepared-character-saves" if prepared else "f48-fallback-requests", True)
        cert = json.loads(cert_path.read_bytes())
        require(cert.get("source") == ("actual_request_bound_prepared_owner_passive_TRUE_BOOL_descendant" if prepared
                                       else "actual_request_bound_natural_fallback_TRUE_BOOL_descendant")
                and cert.get("actual_writer_success") is True, "authentic TRUE BOOL certificate missing")
        require(isinstance(cert.get("original_edge_sha256"), str)
                and re.fullmatch(r"[0-9a-f]{64}", cert["original_edge_sha256"])
                and cert.get("original_edge_path") == selected_edge["path"]
                and cert.get("original_edge_sha256") == selected_edge["sha256"], "different original owner edge")
        request = document(cert, "request_document")
        receipt = document(cert, "receipt_document")
        accepted = document(cert, "accepted_parent_document")
        require(accepted.get("status") == "accepted", "original parent has no accepted ACK")
        original_status = row.get("status")
        compared = copy.deepcopy(accepted)
        compared["status"] = original_status
        require(exact(row, compared), "accepted parent changed complete original row")
        require(request.get("character_id") == scope["character_id"]
                and request.get("world_id") == scope["world_id"]
                and request.get("world_instance_id") == scope["world_namespace"]
                and request.get("host") is data.get("owns_world") is ("world_path" in source)
                and all(type(request.get(k)) is bool for k in ("host", "character_only", "write_split"))
                and exact(request.get("data", {}).get("reward_deliveries", {}).get(identity), accepted),
                "request owner/world/parent mismatch")
        require(set(receipt) == {"version", "source", "writer_instance_id", "writer_script", "request_sha256", "files"}
                and type(receipt["version"]) is int and receipt["version"] == 1 and receipt["source"] == ("SaveGame_locked_prepared_character_write_TRUE_BOOL"
                    if prepared else "SaveGame_locked_fallback_write_TRUE_BOOL")
                and receipt["writer_script"] == "res://scripts/save/save_game.gd"
                and type(receipt["writer_instance_id"]) is int and receipt["writer_instance_id"] != 0
                and receipt["request_sha256"] == digest_bytes(cert["request_document"].encode()),
                "locked writer/request identity mismatch")
        if prepared:
            require(str(receipt["writer_instance_id"]) == cert.get("call_id", "").rsplit("-", 1)[0]
                    and request.get("character_only") is True and request.get("write_split") is False,
                    "prepared actual call/writer mismatch")
            plan = document(cert, "prepared_document")
            require(exact(document(cert, "scope_document"), scope)
                    and plan.get("kind") in {"owner_passive_preparation", "owner_action_passive_preparation", "owner_portal_recovery"}
                    and plan.get("after", {}).get("character_id") == scope["character_id"],
                    "prepared checkpoint scope mismatch")
            if plan["kind"] == "owner_portal_recovery":
                require(plan.get("original", {}).get("source_kind") == "portal_arrival"
                        and plan.get("baseline", {}).get("source_kind") == "portal_arrival"
                        and all(plan["original"].get(k) == v for k, v in scope.items())
                        and plan["baseline"].get("world_id") == plan["original"].get("world_id")
                        and isinstance(plan["baseline"].get("before"), dict)
                        and isinstance(plan["original"].get("before"), dict)
                        and isinstance(plan["original"].get("after"), dict)
                        and (exact(plan["baseline"]["before"], plan["original"]["before"])
                             or exact(plan["baseline"]["before"], plan["original"]["after"]))
                        and exact(plan["original"].get("request"), plan["baseline"].get("request"))
                        and exact(plan["original"].get("host_context"), plan["baseline"].get("host_context"))
                        and exact(plan.get("before"), plan["baseline"].get("after")), "recovery original/baseline changed")
            else:
                require(all(plan.get(k) == v for k, v in scope.items()), "prepared original scope mismatch")
            personal = request["character_data"]
            require(exact(plan["after"].get("party"), [{k: v for k, v in card.items() if k != "energy"}
                         for card in personal.get("party", [])]), "prepared complete portable party mismatch")
        else:
            require(cert.get("session_epoch") == scope["session_epoch"]
                    and isinstance(cert.get("job_id"), str) and cert["job_id"] == link.get("job_id"),
                    "fallback job/epoch mismatch")
        submitted = document(cert, "submission_passive_document")
        passive(submitted)
        require(submitted["events"] <= snapshot_passive["events"]
                and submitted["path"] == snapshot_passive["path"]
                and exact(submitted.get("anchor", {}).get("initial"), edge_passive.get("anchor", {}).get("initial"))
                and exact(submitted.get("anchor", {}).get("expected"), request["character_data"].get("party")),
                "request party differs from sealed passive checkpoint")
        for field in ("sequence", "chain_sha256"):
            require(exact(submitted.get("anchor", {}).get(field), edge_passive.get("anchor", {}).get(field)),
                    "submission replaced original passive anchor prefix")
        expected_kinds = {"character"}
        require(request["character_only"] or request["write_split"], "unsupported non-split fallback shape")
        if request.get("character_only") is False:
            expected_kinds.add("slot")
            if request.get("host") is True:
                expected_kinds.add("world")
        require(isinstance(receipt["files"], dict) and set(receipt["files"]) == expected_kinds,
                "missing/extra locked save files")
        for kind, file in receipt["files"].items():
            require(isinstance(file, dict) and set(file) == {"path", "bytes_base64", "sha256", "payload"},
                    "malformed locked file")
            raw = base64.b64decode(file["bytes_base64"], validate=True)
            require(raw and base64.b64encode(raw).decode() == file["bytes_base64"]
                    and digest_bytes(raw) == file["sha256"], "locked file bytes/hash mismatch")
            payload = save_document.decode(json.loads(raw))
            require(exact(payload, file["payload"]), "locked full payload mismatch")
            expected = copy.deepcopy(request["data"] if kind == "slot" else request[kind + "_data"])
            if kind == "slot":
                if request.get("write_split") is True and request.get("host") is True:
                    expected["split_locator"] = {"world_id": request["world_id"], "character_id": request["character_id"]}
                require(exact(payload, expected), "locked slot payload mismatch")
            else:
                envelope = CHARACTER_ENVELOPE if kind == "character" else WORLD_ENVELOPE
                require(set(payload) == set(expected) | envelope and not (set(expected) & envelope)
                        and exact({k: payload[k] for k in expected}, expected)
                        and type(payload["version"]) is int and payload["version"] == 28 and payload["display_name"] == request["display_name"]
                        and all(isinstance(payload[k], str) for k in envelope - {"version"})
                        and payload["created_at"] and payload["last_played"], "locked request/envelope mismatch")
            if kind == "character":
                require(raw == captured and file["path"] == data.get("character_path")
                        and file["sha256"] == data.get("character_sha256")
                        and payload["character_id"] == scope["character_id"]
                        and payload["last_world_id"] == scope["world_id"]
                        and payload["last_world_instance_id"] == scope["world_namespace"], "selected captured bytes differ")
                protected = ("inventory", "redesign_character", "satchel_escrow", "equipment", "realm_hearts")
                if prepared:
                    protected += ("flags",)
                for field in protected:
                    require(exact(payload.get(field), original_disk.get(field)), "protected original carrier changed: " + field)
                original_uids = [card.get("uid") for card in original_disk.get("party", [])]
                require(original_uids and original_uids == [card.get("uid") for card in payload.get("party", [])],
                        "original ordered party changed")
            elif kind == "world":
                require(payload["world_id"] == scope["world_id"], "locked host world changed")
    return retained
