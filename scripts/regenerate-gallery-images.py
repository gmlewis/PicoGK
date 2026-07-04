#!/usr/bin/env python3
"""
Regenerate all gallery images for the Go, MoonBit, and Gossamer PicoGK SDKs.

This script:
  1. Runs the Go FFI shapekernel-gallery example to produce 16 gallery PNGs
  2. Runs the Go FFI viewer-demo example to produce the viewer PNG
  3. Runs the Go FFI visualize example to produce slice + preview PNGs
  4. Runs the MoonBit shapekernel-gallery example to produce 16 gallery PNGs
  5. Runs the MoonBit viewer-demo example
  6. Runs the MoonBit visualize example
  7. Runs the Gossamer ffi-gallery example to produce 16 gallery PNGs
  8. Compares Go vs MoonBit and Go vs Gossamer gallery images for similarity
  9. Copies generated images into the docs/images/ directories

All three SDKs use the in-process FFI bindings (picogkffi), which bind
directly to the native PicoGK C++ runtime and render via the OpenGL Viewer.

Requires:
  - The PicoGK native runtime (built under native/)
  - Go 1.22+ (go command on PATH)
  - MoonBit (moon command on PATH)
  - Gossamer (gos command on PATH) for Gossamer gallery
  - Python 3 with Pillow (pip install Pillow) for image comparison

Usage:
  python3 scripts/regenerate-gallery-images.py [--verbose]
  python3 scripts/regenerate-gallery-images.py --gos-only
"""

import argparse
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GO_SDK = REPO_ROOT / "sdk" / "go"
MBT_SDK = REPO_ROOT / "sdk" / "mbt"
GOS_SDK = REPO_ROOT / "sdk" / "gos"
GO_GALLERY_DIR = GO_SDK / "examples" / "ffi-gallery"
MBT_GALLERY_DIR = MBT_SDK / "examples" / "shapekernel-gallery"
GOS_GALLERY_DIR = GOS_SDK / "examples" / "ffi-gallery"
GO_VIEWER_DIR = GO_SDK / "examples" / "ffi-viewer-demo"
GO_VISUALIZE_DIR = GO_SDK / "examples" / "ffi-visualize"
MBT_VIEWER_DIR = MBT_SDK / "examples" / "viewer-demo"
MBT_VISUALIZE_DIR = MBT_SDK / "examples" / "visualize"

GO_DOCS_IMAGES = GO_SDK / "docs" / "images"
MBT_DOCS_IMAGES = MBT_SDK / "docs" / "images"
GOS_DOCS_IMAGES = GOS_SDK / "docs" / "images"

# All 16 gallery scene names
GALLERY_SCENES = [
    "box", "sphere", "cylinder", "ring", "lens", "pipe", "pipe_segment",
    "basic_lattices", "lattice_pipe", "lattice_manifold", "gyroid_sphere",
    "gyroid_genus", "superellipsoid", "mesh_painter", "mesh_trafo", "over_offset",
]


def run(cmd: list[str], cwd: Path, label: str, timeout: int = 300, verbose: bool = False, env: dict | None = None) -> bool:
    """Run a command and return True on success."""
    print(f"\n{'='*60}")
    print(f"  {label}")
    print(f"{'='*60}")
    print(f"  cmd: {' '.join(cmd)}")
    print(f"  cwd: {cwd}")
    print()
    start = time.time()
    try:
        result = subprocess.run(
            cmd, cwd=str(cwd), capture_output=True, text=True,
            timeout=timeout, env=env,
        )
    except subprocess.TimeoutExpired:
        print(f"  TIMEOUT after {timeout}s")
        return False
    elapsed = time.time() - start
    if verbose:
        print(result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout)
        if result.stderr:
            print("STDERR:", result.stderr[-1000:])
    if result.returncode != 0:
        print(f"  FAILED (exit {result.returncode}) in {elapsed:.1f}s")
        print("STDOUT (last 500 chars):", result.stdout[-500:])
        if result.stderr:
            print("STDERR (last 500 chars):", result.stderr[-500:])
        return False
    print(f"  OK in {elapsed:.1f}s")
    return True


def check_files(directory: Path, expected: list[str], label: str) -> list[Path]:
    """Check that expected files exist in directory and return their paths."""
    found = []
    missing = []
    for name in expected:
        path = directory / name
        if path.exists() and path.stat().st_size > 0:
            found.append(path)
        else:
            missing.append(name)
    print(f"\n  {label}: {len(found)}/{len(expected)} files found")
    if missing:
        print(f"  MISSING: {missing}")
    else:
        print(f"  All files present!")
    return found


def compare_images(go_dir: Path, mbt_dir: Path, scenes: list[str], label: str = "Image Comparison") -> None:
    """Compare two gallery image directories using Pillow if available."""
    try:
        from PIL import Image
        import struct
    except ImportError:
        print("\n  (Pillow not installed — skipping image comparison)")
        print("  Install with: pip install Pillow")
        return

    print(f"\n{'='*60}")
    print(f"  Image Comparison: {label}")
    print(f"{'='*60}")

    for scene in scenes:
        go_img_path = go_dir / f"{scene}.png"
        mbt_img_path = mbt_dir / f"{scene}.png"

        if not go_img_path.exists() or not mbt_img_path.exists():
            print(f"  {scene}: SKIP (one or both images missing)")
            continue

        try:
            go_img = Image.open(go_img_path).convert("RGB")
            mbt_img = Image.open(mbt_img_path).convert("RGB")
        except Exception as e:
            print(f"  {scene}: ERROR loading images: {e}")
            continue

        # Resize to same dimensions if different
        if go_img.size != mbt_img.size:
            w = min(go_img.size[0], mbt_img.size[0])
            h = min(go_img.size[1], mbt_img.size[1])
            go_img = go_img.resize((w, h))
            mbt_img = mbt_img.resize((w, h))

        # Compute mean absolute difference per pixel
        import numpy as np
        try:
            go_arr = np.array(go_img, dtype=np.float32)
            mbt_arr = np.array(mbt_img, dtype=np.float32)
            diff = np.abs(go_arr - mbt_arr)
            mean_diff = diff.mean()
            max_diff = diff.max()
            pct_similar = (diff < 10).mean() * 100  # % of pixels within 10 of each other

            status = "MATCH" if mean_diff < 5 else ("CLOSE" if mean_diff < 20 else "DIFFER")
            print(f"  {scene:20s}: mean_diff={mean_diff:6.2f}  max_diff={max_diff:5.0f}  similar={pct_similar:5.1f}%  [{status}]")
        except ImportError:
            # No numpy — do a simple pixel-by-pixel comparison
            go_pixels = list(go_img.getdata())
            mbt_pixels = list(mbt_img.getdata())
            total_diff = 0
            for p1, p2 in zip(go_pixels[:1000], mbt_pixels[:1000]):
                total_diff += abs(p1[0]-p2[0]) + abs(p1[1]-p2[1]) + abs(p1[2]-p2[2])
            mean_diff = total_diff / (min(len(go_pixels), 1000) * 3)
            print(f"  {scene:20s}: mean_diff={mean_diff:6.2f} (sampled)")


def copy_images(src_dir: Path, dest_dir: Path, scenes: list[str], label: str) -> None:
    """Copy generated gallery images to the docs directory."""
    print(f"\n  Copying {label} images to {dest_dir}")
    copied = 0
    for scene in scenes:
        src = src_dir / f"{scene}.png"
        if src.exists():
            dest = dest_dir / f"{scene}.png"
            shutil.copy2(src, dest)
            copied += 1
    print(f"  Copied {copied}/{len(scenes)} images")


def main():
    parser = argparse.ArgumentParser(description="Regenerate all PicoGK SDK gallery images.")
    parser.add_argument("--verbose", action="store_true", help="Show full command output")
    parser.add_argument("--go-only", action="store_true", help="Only run Go examples")
    parser.add_argument("--mbt-only", action="store_true", help="Only run MoonBit examples")
    parser.add_argument("--gos-only", action="store_true", help="Only run Gossamer examples")
    parser.add_argument("--no-copy", action="store_true", help="Don't copy images to docs dirs")
    parser.add_argument("--no-compare", action="store_true", help="Don't compare Go vs MoonBit images")
    args = parser.parse_args()

    run_go = not args.mbt_only and not args.gos_only
    run_mbt = not args.go_only and not args.gos_only
    run_gos = not args.go_only and not args.mbt_only

    all_success = True

    # Output directories
    go_output = Path("/tmp/go-ffi-gallery")
    mbt_output = Path("/tmp/mbt-picogk-gallery")
    gos_output = Path("/tmp/gos-ffi-gallery")
    go_viewer_output = Path("/tmp/go-picogkffi-viewer")
    go_visualize_output = Path("/tmp/go-picogkffi-visualize")
    mbt_viewer_output = Path("/tmp/mbt-picogk-viewer")
    mbt_visualize_output = Path("/tmp/mbt-picogk-visualize")

    # --- Go examples ---
    if run_go:
        print("\n" + "=" * 60)
        print("  GO SDK (FFI): Regenerating gallery images")
        print("=" * 60)

        # Run the Go shapekernel-gallery (FFI)
        ok = run(
            ["go", "run", "main.go", "-out", str(go_output)],
            cwd=GO_GALLERY_DIR,
            label="Go: ffi-gallery (16 scenes)",
            timeout=600,
            verbose=args.verbose,
        )
        all_success = all_success and ok
        go_files = check_files(go_output, [f"{s}.png" for s in GALLERY_SCENES], "Go gallery PNGs")

        # Run the Go viewer-demo (FFI)
        ok = run(
            ["go", "run", "main.go", str(go_viewer_output / "viewer_demo.png")],
            cwd=GO_VIEWER_DIR,
            label="Go: ffi-viewer-demo",
            timeout=120,
            verbose=args.verbose,
        )
        all_success = all_success and ok
        check_files(go_viewer_output, ["viewer_demo.png"], "Go viewer PNG")

        # Run the Go visualize (FFI)
        ok = run(
            ["go", "run", "main.go"],
            cwd=GO_VISUALIZE_DIR,
            label="Go: ffi-visualize",
            timeout=120,
            verbose=args.verbose,
        )
        all_success = all_success and ok
        check_files(go_visualize_output, ["slice_z0.png", "mesh_preview.png"], "Go visualize PNGs")

    # --- MoonBit examples ---
    if run_mbt:
        print("\n" + "=" * 60)
        print("  MoonBit SDK: Regenerating gallery images")
        print("=" * 60)

        # Run the MoonBit shapekernel-gallery
        ok = run(
            ["moon", "run", "."],
            cwd=MBT_GALLERY_DIR,
            label="MoonBit: shapekernel-gallery (16 scenes)",
            timeout=600,
            verbose=args.verbose,
        )
        all_success = all_success and ok
        mbt_files = check_files(mbt_output, [f"{s}.png" for s in GALLERY_SCENES], "MoonBit gallery PNGs")

        # Run the MoonBit viewer-demo
        ok = run(
            ["moon", "run", "."],
            cwd=MBT_VIEWER_DIR,
            label="MoonBit: viewer-demo",
            timeout=120,
            verbose=args.verbose,
        )
        all_success = all_success and ok
        check_files(mbt_viewer_output, ["viewer_demo.png"], "MoonBit viewer PNG")

        # Run the MoonBit visualize
        ok = run(
            ["moon", "run", "."],
            cwd=MBT_VISUALIZE_DIR,
            label="MoonBit: visualize",
            timeout=120,
            verbose=args.verbose,
        )
        all_success = all_success and ok
        check_files(mbt_visualize_output, ["slice_z0.png", "mesh_preview.png"], "MoonBit visualize PNGs")

    # --- Gossamer examples ---
    if run_gos:
        print("\n" + "=" * 60)
        print("  Gossamer SDK (FFI): Regenerating gallery images")
        print("=" * 60)

        gos_env = os.environ.copy()
        gos_env["RUSTFLAGS"] = "-Awarnings"
        ok = run(
            ["gos", "run", "--no-jit", "."],
            cwd=GOS_GALLERY_DIR,
            label="Gossamer: ffi-gallery (16 scenes)",
            timeout=900,
            verbose=args.verbose,
            env=gos_env,
        )
        all_success = all_success and ok
        gos_files = check_files(gos_output, [f"{s}.png" for s in GALLERY_SCENES], "Gossamer gallery PNGs")

    # --- Compare Go vs MoonBit ---
    if run_go and run_mbt and not args.no_compare:
        compare_images(go_output, mbt_output, GALLERY_SCENES, "Go vs MoonBit Gallery")

    # --- Compare Go vs Gossamer ---
    if run_go and run_gos and not args.no_compare:
        compare_images(go_output, gos_output, GALLERY_SCENES, "Go vs Gossamer Gallery")

    # --- Copy images to docs directories ---
    if not args.no_copy:
        print("\n" + "=" * 60)
        print("  Copying images to docs directories")
        print("=" * 60)

        if run_go:
            # Copy gallery images to Go docs
            copy_images(go_output, GO_DOCS_IMAGES / "gallery", GALLERY_SCENES, "Go gallery")
            # Copy viewer image
            viewer_src = go_viewer_output / "viewer_demo.png"
            if viewer_src.exists():
                shutil.copy2(viewer_src, GO_DOCS_IMAGES / "viewer_example.png")
                print(f"  Copied viewer_demo.png -> docs/images/viewer_example.png")

        if run_mbt:
            # Copy gallery images to MoonBit docs
            copy_images(mbt_output, MBT_DOCS_IMAGES / "gallery", GALLERY_SCENES, "MoonBit gallery")
            # Copy viewer image
            viewer_src = mbt_viewer_output / "viewer_demo.png"
            if viewer_src.exists():
                shutil.copy2(viewer_src, MBT_DOCS_IMAGES / "viewer_example.png")
                print(f"  Copied viewer_demo.png -> docs/images/viewer_example.png")

        if run_gos:
            # Copy gallery images to Gossamer docs
            copy_images(gos_output, GOS_DOCS_IMAGES / "gallery", GALLERY_SCENES, "Gossamer gallery")

    # --- Summary ---
    print("\n" + "=" * 60)
    print("  SUMMARY")
    print("=" * 60)
    if all_success:
        print("  All examples ran successfully!")
    else:
        print("  Some examples FAILED — check output above.")
    print()
    print("Generated images:")
    if run_go:
        print(f"  Go gallery:       {go_output}/")
        print(f"  Go viewer:        {go_viewer_output}/")
        print(f"  Go visualize:     {go_visualize_output}/")
    if run_mbt:
        print(f"  MoonBit gallery:  {mbt_output}/")
        print(f"  MoonBit viewer:   {mbt_viewer_output}/")
        print(f"  MoonBit visualize:{mbt_visualize_output}/")
    if run_gos:
        print(f"  Gossamer gallery: {gos_output}/")

    if not all_success:
        sys.exit(1)


if __name__ == "__main__":
    main()
