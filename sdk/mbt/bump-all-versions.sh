#!/bin/bash
#
# bump-all-versions.sh — bump the patch version of every moon.mod file.
#
# Every moon.mod below ROOT_DIR is rewritten:
#
#   version = "0.2.1"               ->  version = "0.2.2"
#   "gmlewis/picogkffi@0.2.2",      ->  "gmlewis/picogkffi@0.2.3",
#
# Only gmlewis/ dependency references are bumped; third-party imports such
# as "moonbitlang/async@0.22.9" are left untouched.  Directories holding
# downloaded or generated files (.git, .mooncakes, _build, target,
# node_modules) are skipped.
#
# Usage:
#   ./bump-all-versions.sh [-n|--dry-run] [-h|--help] [ROOT_DIR]
#
# ROOT_DIR defaults to the directory containing this script.

set -euo pipefail

prog=$(basename "$0")
dry_run=false
root=""

usage() {
    echo "Usage: $prog [-n|--dry-run] [-h|--help] [ROOT_DIR]"
    echo
    echo "Bump the patch version of every moon.mod found under ROOT_DIR"
    echo "(default: the directory containing this script)."
    echo
    echo "  -n, --dry-run   show what would change without writing anything"
    echo "  -h, --help      show this help and exit"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) dry_run=true ;;
        -h|--help) usage; exit 0 ;;
        --) shift; [ $# -gt 0 ] && root=$1; break ;;
        -*) echo "$prog: unknown option: $1" >&2; usage >&2; exit 2 ;;
        *) root=$1 ;;
    esac
    shift
done

script_dir=$(cd "$(dirname "$0")" && pwd)
root=${root:-$script_dir}
[ -d "$root" ] || { echo "$prog: not a directory: $root" >&2; exit 2; }
root=$(cd "$root" && pwd)

files=()
while IFS= read -r f; do
    files+=("$f")
done < <(find "$root" \
    \( -name .git -o -name .mooncakes -o -name _build -o -name target \
       -o -name node_modules \) -prune -o \
    -type f -name moon.mod -print | LC_ALL=C sort)

if [ ${#files[@]} -eq 0 ]; then
    echo "$prog: no moon.mod files found under $root" >&2
    exit 1
fi

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/bump-all-versions.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

# Bump the patch component of `version = "x.y.z"` and of every
# `"gmlewis/<pkg>@x.y.z"` import reference.
bump_expr='s/^(\s*version\s*=\s*"\d+\.\d+\.)(\d+)(")/$1 . ($2 + 1) . $3/e;
s/("gmlewis\/[^"@]+@\d+\.\d+\.)(\d+)(")/$1 . ($2 + 1) . $3/ge;'

changed=0
unchanged=0

for file in "${files[@]}"; do
    rel=${file#"$root"/}
    before="$tmpdir/before.moon.mod"
    after="$tmpdir/after.moon.mod"
    cp "$file" "$before"
    cp "$file" "$after"
    perl -pi -e "$bump_expr" "$after"

    if cmp -s "$before" "$after"; then
        echo "unchanged: $rel"
        unchanged=$((unchanged + 1))
        continue
    fi

    changed=$((changed + 1))
    if $dry_run; then
        echo "would update: $rel"
    else
        cp "$after" "$file"
        echo "updated: $rel"
    fi
    diff -u -L "$rel (before)" -L "$rel (after)" "$before" "$after" \
        | sed -e '1,2d' -e 's/^/    /' || true
done

echo
if $dry_run; then
    echo "Dry run: $changed of ${#files[@]} moon.mod file(s) would change; $unchanged unchanged."
else
    echo "Bumped $changed of ${#files[@]} moon.mod file(s); $unchanged unchanged."
fi
