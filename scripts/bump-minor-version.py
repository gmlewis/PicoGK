#!/usr/bin/env python3
"""
Bump the minor version of all PicoGK packages.

This script reads the master version from sdk/go/picogk/version.go,
bumps the minor version, and updates all version constants across
the entire repository.

Usage:
    ./scripts/bump-minor-version.py           # Bump minor version (0.1.0 -> 0.2.0)
    ./scripts/bump-minor-version.py 0.5.3     # Set to specific version
"""

import re
import sys
from pathlib import Path

# Repository root (parent of scripts/)
REPO_ROOT = Path(__file__).parent.parent

# Master version file
MASTER_VERSION_FILE = REPO_ROOT / "sdk" / "go" / "picogk" / "version.go"

# All files that contain version constants
VERSION_FILES = [
    # Go SDKs
    REPO_ROOT / "sdk" / "go" / "picogk" / "version.go",
    REPO_ROOT / "sdk" / "go" / "picogkffi" / "version.go",
    REPO_ROOT / "sdk" / "go" / "blender" / "version.go",
    REPO_ROOT / "sdk" / "go" / "picogkshapes" / "version.go",
    REPO_ROOT / "sdk" / "go" / "picogk" / "go.mod",
    REPO_ROOT / "sdk" / "go" / "blender" / "go.mod",
    
    # Gossamer SDKs
    REPO_ROOT / "sdk" / "gos" / "picogk" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "picogk" / "src" / "lib.gos",
    REPO_ROOT / "sdk" / "gos" / "picogkffi" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "picogkffi" / "picogkffi" / "Cargo.toml",
    REPO_ROOT / "sdk" / "gos" / "picogkshapes" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "blender" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "blender" / "src" / "lib.gos",
    
    # Gossamer examples
    REPO_ROOT / "sdk" / "gos" / "examples" / "full-api" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "examples" / "ffi-web-demo" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "examples" / "ffi-viewer-demo" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "examples" / "ffi-gallery" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "examples" / "ffi-hello-picogk" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "examples" / "ffi-fields-and-io" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "examples" / "ffi-visualize" / "project.toml",
    REPO_ROOT / "sdk" / "gos" / "examples" / "blender-scene" / "project.toml",
    
    # MoonBit SDKs - moon.mod files
    REPO_ROOT / "sdk" / "mbt" / "picogk" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "picogkffi" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "picogkshapes" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "blender" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "picogkffi" / "test" / "moon.mod",
    
    # MoonBit SDKs - client.mbt files
    REPO_ROOT / "sdk" / "mbt" / "picogk" / "client.mbt",
    REPO_ROOT / "sdk" / "mbt" / "blender" / "client.mbt",
    
    # MoonBit examples - moon.mod files
    REPO_ROOT / "sdk" / "mbt" / "examples" / "hello-picogk" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "examples" / "fields-and-io" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "examples" / "viewer-demo" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "examples" / "visualize" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "examples" / "web-demo" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "examples" / "shapekernel-gallery" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "examples" / "full-api" / "moon.mod",
    REPO_ROOT / "sdk" / "mbt" / "examples" / "blender-scene" / "moon.mod",
    
    # MCP Server
    REPO_ROOT / "PicoGK.Mcp" / "Tools" / "SessionTools.cs",
]

# Patterns to match version strings (with capturing group)
# Each pattern is (regex, description)
VERSION_PATTERNS = [
    # Go: const VERSION = "0.1.0"
    (r'(const VERSION = ")([\d]+\.[\d]+\.[\d]+)(")', 'go_const'),
    # Gossamer: const VERSION: String = "0.1.0"
    (r'(const VERSION: String = ")([\d]+\.[\d]+\.[\d]+)(")', 'gos_const'),
    # Gossamer/MoonBit project.toml/moon.mod: version = "0.1.0"
    (r'(version = ")([\d]+\.[\d]+\.[\d]+)(")', 'toml_version'),
    # MoonBit: const VERSION : String = "0.1.0"
    (r'(const VERSION : String = ")([\d]+\.[\d]+\.[\d]+)(")', 'mbt_const'),
    # C#: return "0.1.0";
    (r'(return ")([\d]+\.[\d]+\.[\d]+)(";)', 'cs_return'),
    # Go mod comment: // Version: 1.0.0
    (r'(// Version: )([\d]+\.[\d]+\.[\d]+)', 'go_mod_comment'),
    # MoonBit import with version: "gmlewis/picogkffi@0.1.0"
    # Only update gmlewis/ imports, not third-party like moonbitlang/
    (r'("gmlewis/picogkffi@)([\d]+\.[\d]+\.[\d]+)(")', 'mbt_import_picogkffi'),
    (r'("gmlewis/picogkshapes@)([\d]+\.[\d]+\.[\d]+)(")', 'mbt_import_picogkshapes'),
    (r'("gmlewis/blender@)([\d]+\.[\d]+\.[\d]+)(")', 'mbt_import_blender'),
    (r'("gmlewis/picogk@)([\d]+\.[\d]+\.[\d]+)(")', 'mbt_import_picogk'),
]


def read_version_from_master() -> str:
    """Read the version from the master version file."""
    content = MASTER_VERSION_FILE.read_text()
    match = re.search(r'const VERSION = "([\d]+\.[\d]+\.[\d]+)"', content)
    if not match:
        print(f"Error: Could not find version in {MASTER_VERSION_FILE}")
        sys.exit(1)
    return match.group(1)


def bump_minor(version: str) -> str:
    """Bump the minor version of a semver string."""
    parts = version.split('.')
    if len(parts) != 3:
        print(f"Error: Invalid version format: {version}")
        sys.exit(1)
    
    major, minor, patch = int(parts[0]), int(parts[1]), int(parts[2])
    minor += 1
    patch = 0  # Reset patch on minor bump
    
    return f"{major}.{minor}.{patch}"


def update_file(filepath: Path, old_version: str, new_version: str) -> bool:
    """Update version in a file. Returns True if file was modified."""
    if not filepath.exists():
        print(f"Warning: File not found: {filepath}")
        return False
    
    content = filepath.read_text()
    original_content = content
    
    # Try each pattern
    for pattern, pattern_type in VERSION_PATTERNS:
        def replace_version(match):
            if match.lastindex == 3:
                return f"{match.group(1)}{new_version}{match.group(3)}"
            else:
                return f"{match.group(1)}{new_version}"
        
        content = re.sub(pattern, replace_version, content)
    
    if content != original_content:
        filepath.write_text(content)
        return True
    return False


def parse_version(version_str: str) -> str:
    """Parse and validate a semver version string."""
    parts = version_str.split('.')
    if len(parts) != 3:
        print(f"Error: Invalid version format: {version_str} (expected MAJOR.MINOR.PATCH)")
        sys.exit(1)
    for part in parts:
        if not part.isdigit():
            print(f"Error: Invalid version format: {version_str} (all parts must be numbers)")
            sys.exit(1)
    return version_str


def main():
    # Read current version from master file
    old_version = read_version_from_master()
    print(f"Current version: {old_version}")
    
    # Determine target version
    if len(sys.argv) > 1:
        # Use explicitly provided version
        new_version = parse_version(sys.argv[1])
    else:
        # Bump minor version
        new_version = bump_minor(old_version)
    
    print(f"New version: {new_version}")
    
    # Update all files
    updated_count = 0
    for filepath in VERSION_FILES:
        if update_file(filepath, old_version, new_version):
            print(f"Updated: {filepath.relative_to(REPO_ROOT)}")
            updated_count += 1
    
    print(f"\nDone! Updated {updated_count} files.")
    print(f"Version changed from {old_version} to {new_version}")


if __name__ == "__main__":
    main()
