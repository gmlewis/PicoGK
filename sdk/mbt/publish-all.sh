#!/bin/bash -ex
#
# publish-all.sh — release the PicoGK MoonBit SDKs under one version.
#
# Every moon.mod below this directory is kept at the same version:
#
#   1. pick the release version: --version X.Y.Z, otherwise the highest version
#      currently found under sdk/mbt (usually after ./bump-all-versions.sh);
#   2. sync every moon.mod version and every intra-repo gmlewis dependency pin
#      to that version (examples and picogk-reinforce included);
#   3. refuse to continue if tag vX.Y.Z already exists, or if a published
#      module already has that version;
#   4. fail on any compiler warning (moon check --deny-warn);
#   5. commit sdk/mbt, push, tag vX.Y.Z, and push the tag;
#   6. publish blender, picogk, picogkffi, picogkshapes and picogk-reinforce.
#
# Usage:
#   ./publish-all.sh [-n|--dry-run] [--version X.Y.Z]
#
# Typical release:
#   ./bump-all-versions.sh
#   ./publish-all.sh

set -uo pipefail

prog=$(basename "$0")
dry_run=false
requested=""

usage() {
    echo "Usage: $prog [-n|--dry-run] [--version X.Y.Z]"
    echo
    echo "Sync all sdk/mbt moon.mod versions to one value, then commit, tag"
    echo "vX.Y.Z, push, and publish blender, picogk, picogkffi, picogkshapes"
    echo "and picogk-reinforce."
    echo
    echo "  -n, --dry-run      show what would change without changing anything"
    echo "  --version X.Y.Z    use this version (default: highest version found)"
    echo "  -h, --help         show this help and exit"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) dry_run=true ;;
        --version)
            shift
            requested=${1:-}
            [ -n "$requested" ] || { echo "$prog: --version needs X.Y.Z" >&2; exit 2; }
            ;;
        -h|--help) usage; exit 0 ;;
        *) echo "$prog: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"
REPO_ROOT=$(git rev-parse --show-toplevel)
MODULES="blender picogk picogkffi picogkshapes reinforce"

# --- Pick and validate the release version ---------------------------------

target=$(python3 - "$requested" <<'PY'
import os
import re
import sys

requested = sys.argv[1]
skip = {".git", ".mooncakes", "_build", "target", "node_modules"}
version_re = re.compile(r'(?m)^version[ \t]*=[ \t]*"([^"]+)"[ \t]*$')
semver_re = re.compile(r'^(\d+)\.(\d+)\.(\d+)$')

versions = []
for dirpath, dirnames, filenames in os.walk("."):
    dirnames[:] = [d for d in dirnames if d not in skip]
    if "moon.mod" not in filenames:
        continue
    with open(os.path.join(dirpath, "moon.mod")) as f:
        m = version_re.search(f.read())
    if not m:
        continue
    if not semver_re.match(m.group(1)):
        sys.exit("error: %s has non-numeric version %r" % (dirpath, m.group(1)))
    versions.append(tuple(int(x) for x in m.group(1).split(".")))

if not versions:
    sys.exit("error: no versioned moon.mod files found under sdk/mbt")

highest = max(versions)
if requested:
    if not semver_re.match(requested):
        sys.exit("error: --version %r is not MAJOR.MINOR.PATCH" % requested)
    wanted = tuple(int(x) for x in requested.split("."))
    if wanted < highest:
        sys.exit("error: --version %s is older than an existing moon.mod version %s"
                 % (requested, ".".join(str(x) for x in highest)))
    print(requested)
else:
    print(".".join(str(x) for x in highest))
PY
)

tag="v$target"
if git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    echo "$prog: error: tag $tag already exists; bump the version first" >&2
    exit 1
fi

# --- Refuse to republish a version that already exists ---------------------

for i in $MODULES; do
    name=$(sed -n 's/^name *= *"\([^"]*\)".*/\1/p' "$i/moon.mod")
    latest=$(moon view "$name" --json 2>/dev/null | python3 -c '
import json
import sys
try:
    print(json.load(sys.stdin)["result"]["latest_version"])
except Exception:
    pass' || true)
    if [ -n "$latest" ]; then
        if python3 - "$target" "$latest" <<'PY'
import sys
t = tuple(int(x) for x in sys.argv[1].split("."))
l = tuple(int(x) for x in sys.argv[2].split("."))
sys.exit(0 if t <= l else 1)
PY
        then
            echo "$prog: error: $name@$latest is already published; run ./bump-all-versions.sh first" >&2
            exit 1
        fi
    fi
done

# --- Sync every moon.mod version and intra-repo dependency pin -------------

python3 - "$target" "$dry_run" <<'PY'
import os
import re
import sys

target, dry = sys.argv[1], sys.argv[2] == "true"
skip = {".git", ".mooncakes", "_build", "target", "node_modules"}
name_re = re.compile(r'(?m)^name[ \t]*=[ \t]*"([^"]+)"[ \t]*$')
version_re = re.compile(r'(?m)^version[ \t]*=[ \t]*"[^"]*"[ \t]*$')
dep_re = re.compile(r'"([^"@]+)@([^"]+)"')

paths = []
for dirpath, dirnames, filenames in os.walk("."):
    dirnames[:] = [d for d in dirnames if d not in skip]
    if "moon.mod" in filenames:
        paths.append(os.path.join(dirpath, "moon.mod"))
paths.sort()

texts = {}
names = set()
for path in paths:
    with open(path) as f:
        text = f.read()
    texts[path] = text
    m = name_re.search(text)
    if m:
        names.add(m.group(1))

changed = 0
for path in paths:
    text = texts[path]
    new = text

    m = version_re.search(new)
    if m:
        old = re.search(r'"([^"]+)"', m.group(0)).group(1)
        if old != target:
            new = new[:m.start()] + 'version = "%s"' % target + new[m.end():]
            print("version %s -> %s: %s" % (old, target, path))

    def sync_dep(match):
        name, old = match.group(1), match.group(2)
        if name not in names or old == target:
            return match.group(0)
        print("dep     %s@%s -> %s@%s: %s" % (name, old, name, target, path))
        return '"%s@%s"' % (name, target)

    new = dep_re.sub(sync_dep, new)
    if new == text:
        continue
    changed += 1
    if not dry:
        with open(path, "w") as f:
            f.write(new)

if changed == 0:
    print("All moon.mod versions and intra-repo pins are already at %s" % target)
elif dry:
    print("Dry run: %d moon.mod file(s) would change" % changed)
else:
    print("Updated %d moon.mod file(s)" % changed)
PY

# --- Strict warning gate ----------------------------------------------------

if $dry_run; then
    echo "would run: moon check --deny-warn --no-mbti"
else
    moon check --deny-warn --no-mbti
fi

# --- Commit, tag, push ------------------------------------------------------

branch=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
[ "$branch" = "master" ] || echo "$prog: warning: tagging from '$branch', not master" >&2

if $dry_run; then
    echo "would commit sdk/mbt if changed, push origin HEAD, tag $tag, push the tag"
else
    if [ -n "$(git -C "$REPO_ROOT" status --porcelain -- sdk/mbt)" ]; then
        git -C "$REPO_ROOT" add -A sdk/mbt
        git -C "$REPO_ROOT" commit -m "Bump PicoGK MoonBit SDKs to $target" -- sdk/mbt
    fi
    git -C "$REPO_ROOT" push origin HEAD
    git -C "$REPO_ROOT" tag "$tag"
    git -C "$REPO_ROOT" push origin "refs/tags/$tag"
fi

# --- Publish ----------------------------------------------------------------

for i in $MODULES; do
    if $dry_run; then
        echo "would publish $i"
    else
        (cd "$i" && moon update && moon publish) || exit 1
    fi
done

if $dry_run; then
    echo "Dry run complete: would release $tag and publish: $MODULES"
else
    echo "Released $tag and published: $MODULES"
fi
