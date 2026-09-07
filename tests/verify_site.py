#!/usr/bin/env python3
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote
import hashlib, re, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "docs"
TOOLBOX = ROOT / "toolbox"
MIRROR = SITE / "files" / "toolbox"

class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links=[]
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if tag in ("a","link","script","img"):
            for key in ("href","src"):
                if key in a:
                    self.links.append(a[key])

errors=[]

# Toolbox mirror must contain every toolbox file and preserve bytes.
for src in TOOLBOX.rglob("*"):
    if not src.is_file():
        continue
    rel=src.relative_to(TOOLBOX)
    dst=MIRROR/rel
    if not dst.is_file():
        errors.append(f"Missing toolbox mirror: {rel}")
        continue
    if hashlib.sha256(src.read_bytes()).digest() != hashlib.sha256(dst.read_bytes()).digest():
        errors.append(f"Toolbox mirror differs: {rel}")

# Local HTML references must resolve.
for page in SITE.glob("*.html"):
    parser=LinkParser()
    parser.feed(page.read_text(encoding="utf-8"))
    for link in parser.links:
        parsed=urlparse(link)
        if parsed.scheme or parsed.netloc or link.startswith(("#","mailto:","javascript:")):
            continue
        path=unquote(parsed.path)
        if not path:
            continue
        if path.startswith("files/bundles/"):
            continue
        target=(page.parent/path).resolve()
        try:
            target.relative_to(SITE.resolve())
        except ValueError:
            errors.append(f"{page.name}: link escapes site root: {link}")
            continue
        if not target.exists():
            errors.append(f"{page.name}: broken local reference: {link}")

if (SITE/"CNAME").read_text(encoding="utf-8").strip() != "project.bf3speedhacks.com":
    errors.append("CNAME is not project.bf3speedhacks.com")

# Operational dependencies and explicit apply/restore pairs must be declared for grouped download.
# The browser builds ZIP files on demand from these mirrored source files, which avoids stale static bundles.
expected_bundle_members = {
    "Windows-Cleanup-GUI.zip": {
        "files/toolbox/cleanup/Start-Windows-Cleanup-GUI.cmd",
        "files/toolbox/cleanup/Windows-Orphan-Cleanup-Audit.ps1",
    },
    "Universal-Network-Reset-MTU1492.zip": {
        "files/toolbox/network/reset/Run-Universal-Network-Reset-MTU1492.cmd",
        "files/toolbox/network/reset/Universal-Network-Reset-MTU1492.ps1",
    },
    "NVIDIA-Inspector-Toolkit.zip": {
        "files/toolbox/nvidia/inspector/Apply_NVIDIA_Inspector_Settings.cmd",
        "files/toolbox/nvidia/inspector/Revert_NVIDIA_Inspector_Settings_Only.cmd",
        "files/toolbox/nvidia/inspector/NVIDIA_Inspector_Settings.nip",
        "files/toolbox/nvidia/inspector/NVIDIA_Inspector_Default.nip",
        "files/toolbox/nvidia/inspector/inspector.exe",
    },
    "Chocolatey-Package-Installer.zip": {
        "files/scripts/Install-ChocolateyPackages.ps1",
        "files/packages/chocolatey-packages.txt",
    },
    "Windows11-EnergyMode-Workaround.zip": {
        "files/experimental/power/Apply-EnergyModeWorkaround.reg",
        "files/experimental/power/Set-HighPerformance.cmd",
        "files/experimental/power/Restore-EnergyModeDefaults.reg",
        "files/experimental/power/README.md",
    },
    "Legacy-NvApi64-Workaround.zip": {
        "files/archive/legacy-workarounds/nvidia/Move-NvApi64.ps1",
        "files/archive/legacy-workarounds/nvidia/Restore-NvApi64.ps1",
    },
    "Legacy-Services-Disable-Restore.zip": {
        "files/archive/wfiles-original/Files [OLD]/Services Disable.reg",
        "files/archive/wfiles-original/Files [OLD]/Services Restore.reg",
    },
}
site_js = (SITE / "assets" / "site.js").read_text(encoding="utf-8")
for bundle_name, members in expected_bundle_members.items():
    if bundle_name not in site_js:
        errors.append(f"Missing bundle declaration in site.js: {bundle_name}")
    for member in members:
        if member not in site_js:
            errors.append(f"{bundle_name}: member is not declared in site.js: {member}")
        target = SITE / unquote(member.removeprefix("files/")) if False else SITE / unquote(member)
        if not target.is_file():
            errors.append(f"{bundle_name}: mirrored member is missing: {member}")

# The private source label must not reappear in the current tree, website, or archive metadata.
forbidden = bytes((97, 109, 105, 110))
forbidden_word = re.compile(rb"\b" + re.escape(forbidden) + rb"\b", re.IGNORECASE)
for path in ROOT.rglob("*"):
    if not path.is_file():
        continue
    rel = path.relative_to(ROOT).as_posix()
    if forbidden_word.search(rel.encode("utf-8", errors="ignore")):
        errors.append(f"Forbidden private-source reference in path: {rel}")
        continue
    if forbidden_word.search(path.read_bytes()):
        errors.append(f"Forbidden private-source reference in file: {rel}")

if errors:
    print("\n".join("ERROR: "+x for x in errors))
    sys.exit(1)

print("Site integrity OK")
