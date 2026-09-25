"""Install the pinned optional Steam runtime; no account setup or launch.

Usage:
  python tools/setup_steam_runtime.py [--destination PATH]
      Windows development editor (GodotSteam 4.20 / Godot 4.7 / SDK 1.64).
  python tools/setup_steam_runtime.py --templates [--platform win64|linux64]
      [--destination PATH]
      Matching export templates plus the Steam API library that must ship
      beside the exported executable. Point the export preset's
      custom_template/debug and custom_template/release at the printed paths,
      or add --configure-preset "Windows Desktop" to write them into
      export_presets.cfg (the release workflow does this only for a run that
      opted into the Steam runtime; do not commit machine paths).

The downloaded archive is checked against a pinned SHA-256 before it is
opened. Each extracted file is written as a `.download` temporary beside its
destination and checked against its own pin; only when every file has passed
are they renamed into place, and any failure removes the temporaries. If a
rename fails (for example a locked file on Windows), the error says which
files were already replaced. The ordinary Godot
installation and its stock templates are untouched. No AppID is configured
here: it comes from TETHERBOUND_STEAM_APP_ID, SteamAppId or the local project
setting (scripts/net/steam_lobby.gd). The pins were recorded from the upstream
Codeberg release on the owner's machine and re-derived independently in the X05
lane (ralph/reports/INVITE-COOP); the publisher does not provide checksums.
"""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import tarfile
import tempfile
import urllib.request

RELEASE = "https://codeberg.org/godotsteam/godotsteam/releases/download/v4.20/"
CACHE = Path.home() / ".cache" / "tetherbound-tools"

EDITOR = {
    "url": RELEASE + "win64-g47-s164-gs420-editor.tar.xz",
    "sha256": "b5bd13a3c1d6c2087b54607aad43865fa29d070d8992ef114ce17d955413149a",
    "destination": CACHE / "godotsteam-4.20-godot-4.7",
    # The editor archive holds exactly these files at its root; their hashes
    # are covered by the archive hash.
    "files": {
        "godotsteam.47.editor.win64.console.exe": None,
        "godotsteam.47.editor.win64.exe": None,
        "steam_api64.dll": None,
    },
}

TEMPLATES_URL = RELEASE + "godotsteam-g47-s164-gs420-templates.tar.xz"
TEMPLATES_SHA256 = "06216a20f39d64dfe6aa29ce7add91f5eb2f36b38ce13ca0dcac36c869ffa0f1"
# The template archive holds every platform; only the listed members are
# extracted, each checked against its own pin.
TEMPLATE_PLATFORMS = {
    "win64": {
        "win64/godotsteam.47.debug.template.win64.exe":
            "19f7b2621becaccc8c0984127e2989d016ddd5c73a54447c71d2f1f363bf5996",
        "win64/godotsteam.47.template.win64.exe":
            "a648caa7e30047827ed6b675b64d005aa7785aceb8400c0e116af4e439be6fc9",
        "win64/steam_api64.dll":
            "eb17909a76668cf9ae0b92a618a34a50f6c73d3a6787cb4dd8ce36a8b10bfb75",
    },
    "linux64": {
        "linux64/godotsteam.47.debug.template.x86_64":
            "ef38218ac130298ff399dbb1e852778b162ab62cf34f3af99359ea0d6493431d",
        "linux64/godotsteam.47.template.x86_64":
            "37b36120b1116fec1620b692867ba84453e87b8b09a28ce41c45cf41cd76f0f3",
        "linux64/libsteam_api.so":
            "ec4797f76a206eb0af627af0f0788eb5a2eabf5dee38ee0a6affbaa44a645f4e",
    },
}


def _sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def _download(url, expected, staging):
    archive = Path(staging) / "archive.tar.xz"
    urllib.request.urlretrieve(url, archive)
    actual = _sha256(archive)
    if actual != expected:
        raise SystemExit(f"Archive checksum mismatch for {url}: {actual}; nothing installed")
    return archive


def _extract_verified(archive, wanted, destination, exact_contents):
    """Extract `wanted` (member -> sha256 or None) as `.download` files in
    `destination`, verify every one, and only then rename them into place."""
    temporaries = []
    committed = False
    try:
        with tarfile.open(archive, "r:xz") as package:
            members = {member.name: member for member in package.getmembers()}
            if exact_contents and set(members) != set(wanted):
                raise SystemExit("Unexpected archive contents; nothing installed")
            for name, expected in wanted.items():
                member = members.get(name)
                if member is None or not member.isfile():
                    raise SystemExit(f"Archive is missing {name}; nothing installed")
                source = package.extractfile(member)
                assert source is not None
                temporary = destination / (Path(name).name + ".download")
                temporaries.append(temporary)
                with open(temporary, "wb") as target:
                    shutil.copyfileobj(source, target, 1 << 20)
                if expected is not None and _sha256(temporary) != expected:
                    raise SystemExit(f"Checksum mismatch for {name}; nothing installed")
        committed = True
    finally:
        if not committed:
            for path in temporaries:
                path.unlink(missing_ok=True)
    installed = []
    for temporary in temporaries:
        final = destination / temporary.name.removesuffix(".download")
        try:
            os.replace(temporary, final)
        except OSError as error:
            for path in temporaries:
                path.unlink(missing_ok=True)
            done = ", ".join(path.name for path in installed) or "none"
            raise SystemExit(f"Could not replace {final} ({error}); already replaced: {done}. "
                             "Close any running copy and run this again.")
        if final.suffix in ("", ".x86_64"):
            final.chmod(final.stat().st_mode | 0o111)
        installed.append(final)
    return installed


def install_editor(destination):
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="tetherbound-steam-") as staging:
        archive = _download(EDITOR["url"], EDITOR["sha256"], staging)
        _extract_verified(archive, EDITOR["files"], destination, exact_contents=True)
    print(destination / "godotsteam.47.editor.win64.console.exe")
    print("GodotSteam 4.20 / Godot 4.7 / Steamworks 1.64. No AppID configured; no game launched.")


def install_templates(platform, destination):
    destination.mkdir(parents=True, exist_ok=True)
    wanted = TEMPLATE_PLATFORMS[platform]
    with tempfile.TemporaryDirectory(prefix="tetherbound-steam-templates-") as staging:
        archive = _download(TEMPLATES_URL, TEMPLATES_SHA256, staging)
        installed = _extract_verified(archive, wanted, destination, exact_contents=False)
    for path in installed:
        print(path)
    print(f"GodotSteam 4.20 {platform} export templates for Godot 4.7 / Steamworks 1.64.")
    print("Ship the Steam API library beside the exported executable. No AppID configured.")


def template_files(platform):
    """(debug, release) template file names, from the pinned member list."""
    names = [Path(member).name for member in TEMPLATE_PLATFORMS[platform]]
    debug = next(name for name in names if ".debug.template." in name)
    release = next(name for name in names if ".template." in name and ".debug." not in name)
    return debug, release


def configure_preset(presets_path, preset_name, debug_template, release_template):
    """Set custom_template/debug and /release in the named preset's options
    section of export_presets.cfg. Other presets and keys are untouched."""
    lines = Path(presets_path).read_text(encoding="utf-8").splitlines(keepends=True)
    matches = []
    for i, line in enumerate(lines):
        if line.strip() == f'name="{preset_name}"':
            for j in range(i, -1, -1):
                header = lines[j].strip()
                if header.startswith("[preset.") and header.endswith("]") and ".options" not in header:
                    matches.append(header[len("[preset."):-1])
                    break
    if not matches:
        raise SystemExit(f"No export preset named {preset_name!r} in {presets_path}")
    if len(matches) > 1:
        raise SystemExit(f"More than one export preset is named {preset_name!r} in {presets_path}")
    index = matches[0]
    section = f"[preset.{index}.options]"
    wanted = {"custom_template/debug": debug_template.as_posix(),
              "custom_template/release": release_template.as_posix()}
    inside = False
    seen = set()
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("["):
            inside = stripped == section
            continue
        if inside:
            key = stripped.split("=", 1)[0]
            if key in wanted:
                lines[i] = f'{key}="{wanted[key]}"\n'
                seen.add(key)
    if seen != set(wanted):
        raise SystemExit(f"Preset {preset_name!r} has no custom_template keys to set")
    Path(presets_path).write_text("".join(lines), encoding="utf-8")
    print(f"Configured {preset_name!r} in {presets_path} to use the GodotSteam templates.")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--templates", action="store_true",
                        help="install export templates instead of the development editor")
    parser.add_argument("--platform", choices=sorted(TEMPLATE_PLATFORMS), default="win64")
    parser.add_argument("--destination", type=Path, default=None)
    parser.add_argument("--configure-preset", metavar="NAME", default=None,
                        help="with --templates: point this export preset at the installed templates")
    parser.add_argument("--presets-file", type=Path, default=Path("export_presets.cfg"))
    args = parser.parse_args()
    if args.configure_preset and not args.templates:
        parser.error("--configure-preset needs --templates")
    if args.templates:
        default = CACHE / f"godotsteam-4.20-godot-4.7-templates-{args.platform}"
        destination = (args.destination or default).resolve()
        install_templates(args.platform, destination)
        if args.configure_preset:
            debug_name, release_name = template_files(args.platform)
            configure_preset(args.presets_file, args.configure_preset,
                             destination / debug_name, destination / release_name)
    else:
        install_editor((args.destination or EDITOR["destination"]).resolve())


if __name__ == "__main__":
    main()
