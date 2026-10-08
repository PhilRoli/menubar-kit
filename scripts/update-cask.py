#!/usr/bin/env python3
"""Usage: update-cask.py <cask.rb> <version> <sha256>. Fails unless exactly one version and one sha256 line were replaced."""
import re
import sys

path, version, sha256 = sys.argv[1:4]
text = open(path).read()
text, n_version = re.subn(r'version "[^"]*"', f'version "{version}"', text)
text, n_sha = re.subn(r'sha256 "[^"]*"', f'sha256 "{sha256}"', text)
if n_version != 1 or n_sha != 1:
    sys.exit(f"error: {path}: expected exactly one version and one sha256 line, replaced {n_version}/{n_sha}")
open(path, "w").write(text)
print(f"Updated {path} to v{version}")
