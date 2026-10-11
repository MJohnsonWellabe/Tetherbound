"""Strict shipping config pins; verify original bytes without an overlay."""
from contextlib import contextmanager
import re
from pathlib import Path

import f48_profile_fixture as fixture

FILES = {"stations.json", "essence.json", "traits.json", "multiplayer.json",
         "hud.json", "alpha_respawns.json", "combat.json"}


def shipping_pins(profile):
    if "production_configuration_pins" not in profile:
        return None
    pins = profile["production_configuration_pins"]
    expected = {"res://data/config/" + name for name in FILES}
    fixture.require(isinstance(pins, list) and len(pins) == len(expected),
                    "Complete seven shipping configuration pins required")
    for row in pins:
        fixture.require(isinstance(row, dict) and set(row) == {"file", "sha256"}
                        and row["file"] in expected and isinstance(row["sha256"], str)
                        and re.fullmatch(r"[0-9a-f]{64}", row["sha256"]),
                        "Invalid or duplicate shipping configuration pin")
        expected.remove(row["file"])
    configurations = profile.get("test_configuration")
    effective = [{"file": row["file"], "sha256": row["sha256"]} for row in pins
                 if row["file"] != "res://data/config/combat.json"]
    fixture.require(isinstance(configurations, list) and len(configurations) == len(effective)
                    and all(isinstance(row, dict) for row in configurations)
                    and sorted((row.get("file", ""), row.get("sha256", "")) for row in configurations)
                    == sorted((row["file"], row["sha256"]) for row in effective),
                    "Shipping native guard pins differ from complete production pins")
    return pins


def shipping_files(project, profile):
    pins = shipping_pins(profile)
    fixture.require(pins is not None, "Explicit shipping pins required")
    files = []
    for row in pins:
        path = Path(project) / row["file"].removeprefix("res://")
        fixture.require(path.is_file() and fixture.digest(path) == row["sha256"],
                        "Shipping configuration differs from original producer pins")
        files.append((path, row["sha256"]))
    return files


@contextmanager
def shipping_configuration(project, profile):
    files = shipping_files(project, profile)
    try:
        yield shipping_pins(profile)
    finally:
        for path, sha256 in files:
            fixture.require(path.is_file() and fixture.digest(path) == sha256,
                            "Shipping configuration changed during native run")
