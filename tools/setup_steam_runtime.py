"""Install the pinned optional Windows Steam runtime; no account setup or launch.

Usage: python tools/setup_steam_runtime.py [--destination PATH]
The ordinary Godot installation is untouched. Export templates are a separate,
still-unverified packaging dependency; this installs the development executable.
"""
import argparse
import hashlib
import os
from pathlib import Path
import tarfile
import tempfile
import urllib.request

URL = "https://codeberg.org/godotsteam/godotsteam/releases/download/v4.20/win64-g47-s164-gs420-editor.tar.xz"
SHA256 = "b5bd13a3c1d6c2087b54607aad43865fa29d070d8992ef114ce17d955413149a"
FILES = {
    "godotsteam.47.editor.win64.console.exe",
    "godotsteam.47.editor.win64.exe",
    "steam_api64.dll",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, default=Path.home() / ".cache" / "tetherbound-tools" / "godotsteam-4.20-godot-4.7")
    args = parser.parse_args()
    destination = args.destination.resolve()
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="tetherbound-steam-") as staging:
        archive = Path(staging) / "runtime.tar.xz"
        urllib.request.urlretrieve(URL, archive)
        actual = hashlib.sha256(archive.read_bytes()).hexdigest()
        if actual != SHA256:
            raise SystemExit(f"Runtime checksum mismatch: {actual}; nothing installed")
        with tarfile.open(archive, "r:xz") as package:
            members = package.getmembers()
            if {member.name for member in members} != FILES or any(not member.isfile() for member in members):
                raise SystemExit("Unexpected runtime archive contents; nothing installed")
            for member in members:
                source = package.extractfile(member)
                assert source is not None
                temporary = destination / (member.name + ".download")
                temporary.write_bytes(source.read())
                os.replace(temporary, destination / member.name)
    print(destination / "godotsteam.47.editor.win64.console.exe")
    print("GodotSteam 4.20 / Godot 4.7 / Steamworks 1.64. No AppID configured; no game launched.")


if __name__ == "__main__":
    main()
