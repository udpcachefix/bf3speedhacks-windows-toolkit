#!/usr/bin/env python3
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote
import hashlib, sys, zipfile

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

# Multi-file launchers must be distributed as complete bundles.
bundles = {
    "Windows-Cleanup-GUI.zip": {"Start-Windows-Cleanup-GUI.cmd", "Windows-Orphan-Cleanup-Audit.ps1"},
    "Universal-Network-Reset-MTU1492.zip": {"Run-Universal-Network-Reset-MTU1492.cmd", "Universal-Network-Reset-MTU1492.ps1"},
    "NVIDIA-Inspector-Toolkit.zip": {"Apply_NVIDIA_Inspector_Settings.cmd", "Revert_NVIDIA_Inspector_Settings_Only.cmd", "NVIDIA_Inspector_Settings.nip", "NVIDIA_Inspector_Default.nip"},
}
for bundle_name, required in bundles.items():
    bundle_path = SITE / "files" / "bundles" / bundle_name
    if not bundle_path.is_file():
        errors.append(f"Missing download bundle: {bundle_name}")
        continue
    try:
        with zipfile.ZipFile(bundle_path) as zf:
            names = set(zf.namelist())
    except zipfile.BadZipFile:
        errors.append(f"Invalid ZIP bundle: {bundle_name}")
        continue
    missing = required - names
    if missing:
        errors.append(f"{bundle_name}: missing bundle members: {', '.join(sorted(missing))}")

if errors:
    print("\n".join("ERROR: "+x for x in errors))
    sys.exit(1)

print("Site integrity OK")
