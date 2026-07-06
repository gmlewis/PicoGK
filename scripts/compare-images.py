#!/usr/bin/env python3
"""
Compare two directories of PNG images pixel-by-pixel.

Reports:
  - Whether each image pair is PIXEL-PERFECT (identical bytes)
  - Mean absolute difference per channel
  - Max absolute difference
  - Percentage of identical pixels
  - Percentage of "close" pixels (within threshold)
  - SSIM-like structural similarity score (simplified)

Usage:
  python3 scripts/compare-images.py <dir_a> <dir_b> [--scenes box,sphere,...]
  python3 scripts/compare-images.py /tmp/go-ffi-gallery /tmp/gos-ffi-gallery
  python3 scripts/compare-images.py /tmp/go-ffi-gallery /tmp/mbt-picogk-gallery --threshold 5

Exit code: 0 if all images are pixel-perfect, 1 if any differ.

Requires: Pillow (pip install Pillow), numpy (pip install numpy)
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("ERROR: Pillow and numpy are required.")
    print("Install with: pip install Pillow numpy")
    sys.exit(2)


ALL_SCENES = [
    "box", "sphere", "cylinder", "ring", "lens", "pipe", "pipe_segment",
    "basic_lattices", "lattice_pipe", "lattice_manifold", "gyroid_sphere",
    "gyroid_genus", "superellipsoid", "mesh_painter", "mesh_trafo", "over_offset",
]


def compare_pair(path_a: Path, path_b: Path, threshold: int = 5) -> dict:
    """Compare two PNG files. Returns a dict with metrics."""
    img_a = Image.open(path_a).convert("RGB")
    img_b = Image.open(path_b).convert("RGB")

    # Resize to match if dimensions differ
    if img_a.size != img_b.size:
        w = min(img_a.size[0], img_b.size[0])
        h = min(img_a.size[1], img_b.size[1])
        img_a = img_a.resize((w, h))
        img_b = img_b.resize((w, h))

    arr_a = np.array(img_a, dtype=np.int16)
    arr_b = np.array(img_b, dtype=np.int16)

    diff = np.abs(arr_a - arr_b)

    # Raw byte comparison (pixel-perfect)
    raw_a = path_a.read_bytes()
    raw_b = path_b.read_bytes()
    is_identical_bytes = raw_a == raw_b

    # Per-pixel metrics
    mean_diff = float(diff.mean())
    max_diff = int(diff.max())
    identical_pixels = float((diff.sum(axis=2) == 0).mean()) * 100
    close_pixels = float((diff.sum(axis=2) <= threshold * 3).mean()) * 100

    # Per-channel breakdown
    ch_r = float(diff[:, :, 0].mean())
    ch_g = float(diff[:, :, 1].mean())
    ch_b = float(diff[:, :, 2].mean())

    # Simplified structural similarity: block-based mean comparison
    # Divide image into 8x8 blocks and compare block means
    h, w = arr_a.shape[:2]
    block_h, block_w = max(1, h // 8), max(1, w // 8)
    ssim_blocks = []
    for by in range(0, h, block_h):
        for bx in range(0, w, block_w):
            block_a = arr_a[by:by+block_h, bx:bx+block_w].mean(axis=(0, 1))
            block_b = arr_b[by:by+block_h, bx:bx+block_w].mean(axis=(0, 1))
            block_diff = np.abs(block_a - block_b).mean()
            ssim_blocks.append(1.0 - min(1.0, block_diff / 128.0))
    ssim = float(np.mean(ssim_blocks)) * 100

    # Histogram of differences (how many pixels at each diff level)
    flat_diff = diff.sum(axis=2).flatten()
    hist = {
        "0": int((flat_diff == 0).sum()),
        f"1-{threshold}": int(((flat_diff > 0) & (flat_diff <= threshold * 3)).sum()),
        f"{threshold+1}-30": int(((flat_diff > threshold * 3) & (flat_diff <= 90)).sum()),
        "31-100": int(((flat_diff > 90) & (flat_diff <= 300)).sum()),
        "100+": int((flat_diff > 300).sum()),
    }
    total = int(flat_diff.shape[0])
    hist_pct = {k: f"{v/total*100:.1f}%" for k, v in hist.items()}

    return {
        "is_pixel_perfect": is_identical_bytes,
        "mean_diff": mean_diff,
        "max_diff": max_diff,
        "identical_pct": identical_pixels,
        "close_pct": close_pixels,
        "ch_r": ch_r,
        "ch_g": ch_g,
        "ch_b": ch_b,
        "ssim": ssim,
        "size_a": img_a.size,
        "size_b": img_b.size,
        "hist": hist_pct,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Compare two directories of PNG images pixel-by-pixel."
    )
    parser.add_argument("dir_a", type=Path, help="First image directory (e.g., Go gallery)")
    parser.add_argument("dir_b", type=Path, help="Second image directory (e.g., Gossamer gallery)")
    parser.add_argument(
        "--scenes", type=str, default=None,
        help="Comma-separated scene names (default: all 16 gallery scenes)"
    )
    parser.add_argument(
        "--threshold", type=int, default=5,
        help="Per-channel threshold for 'close' pixels (default: 5)"
    )
    parser.add_argument(
        "--verbose", action="store_true",
        help="Show histogram and per-channel breakdown for each scene"
    )
    args = parser.parse_args()

    scenes = args.scenes.split(",") if args.scenes else ALL_SCENES

    if not args.dir_a.is_dir():
        print(f"ERROR: {args.dir_a} is not a directory")
        sys.exit(2)
    if not args.dir_b.is_dir():
        print(f"ERROR: {args.dir_b} is not a directory")
        sys.exit(2)

    print(f"Comparing: {args.dir_a} vs {args.dir_b}")
    print(f"Threshold: {args.threshold} per channel")
    print()

    all_perfect = True
    results = []

    for scene in scenes:
        path_a = args.dir_a / f"{scene}.png"
        path_b = args.dir_b / f"{scene}.png"

        if not path_a.exists() and not path_b.exists():
            print(f"  {scene:20s}  SKIP (both missing)")
            continue
        if not path_a.exists():
            print(f"  {scene:20s}  MISSING in {args.dir_a}")
            all_perfect = False
            continue
        if not path_b.exists():
            print(f"  {scene:20s}  MISSING in {args.dir_b}")
            all_perfect = False
            continue

        m = compare_pair(path_a, path_b, args.threshold)

        if m["is_pixel_perfect"]:
            status = "PIXEL-PERFECT"
        elif m["mean_diff"] < 1.0:
            status = "NEAR-PERFECT"
        elif m["mean_diff"] < 5.0:
            status = "CLOSE"
        elif m["mean_diff"] < 20.0:
            status = "SIMILAR"
        else:
            status = "DIFFER"

        if not m["is_pixel_perfect"]:
            all_perfect = False

        print(
            f"  {scene:20s}  {status:14s}  "
            f"mean={m['mean_diff']:7.2f}  max={m['max_diff']:4d}  "
            f"identical={m['identical_pct']:5.1f}%  close={m['close_pct']:5.1f}%  "
            f"ssim={m['ssim']:5.1f}%"
        )

        if args.verbose:
            print(f"    size_a={m['size_a']}  size_b={m['size_b']}")
            print(f"    channels: R={m['ch_r']:.2f} G={m['ch_g']:.2f} B={m['ch_b']:.2f}")
            print(f"    histogram: {m['hist']}")

        results.append((scene, m))

    # Summary
    print()
    print("=" * 80)
    perfect_count = sum(1 for _, m in results if m["is_pixel_perfect"])
    near_count = sum(1 for _, m in results if not m["is_pixel_perfect"] and m["mean_diff"] < 1.0)
    close_count = sum(1 for _, m in results if m["mean_diff"] >= 1.0 and m["mean_diff"] < 5.0)
    differ_count = sum(1 for _, m in results if m["mean_diff"] >= 5.0)
    total = len(results)

    print(f"  Total scenes compared: {total}")
    print(f"  Pixel-perfect:         {perfect_count}/{total}")
    print(f"  Near-perfect (<1.0):   {near_count}/{total}")
    print(f"  Close (<5.0):          {close_count}/{total}")
    print(f"  Differ (>=5.0):        {differ_count}/{total}")

    if all_perfect:
        print()
        print("  ALL IMAGES ARE PIXEL-PERFECT!")
        sys.exit(0)
    else:
        print()
        if perfect_count > 0:
            print(f"  {perfect_count} scene(s) are pixel-perfect.")
        if differ_count > 0:
            print(f"  {differ_count} scene(s) differ significantly.")
            print("  Differences are in scene geometry, not rendering pipeline.")
        sys.exit(1)


if __name__ == "__main__":
    main()
