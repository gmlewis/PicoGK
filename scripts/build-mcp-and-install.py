#!/usr/bin/env python3
"""Build, install, and test the PicoGK MCP server.

Detects the current platform, publishes a self-contained .NET binary,
co-locates the native geometry libraries, and runs the end-to-end test suite.

The script is shebang-startable on Linux/macOS:
    ./scripts/build-mcp-and-install.py

On Windows, run with:
    python scripts/build-mcp-and-install.py

Supported platforms (those shipped with native libraries in this repo):
    - macOS Apple Silicon  -> osx-arm64   (native/osx-arm64/*.dylib)
    - Windows x64          -> win-x64     (native/win-x64/*.dll)

Usage:
    build-mcp-and-install.py [--install-dir DIR] [--skip-test] [--verbose]

Options:
    --install-dir DIR   Destination directory (default: ~/.local/bin/picogk-mcp)
    --skip-test         Skip the smoke + end-to-end tests after building
    --verbose           Show full output of underlying commands
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import NoReturn


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
MCP_CSPROJ = REPO_ROOT / "PicoGK.Mcp" / "PicoGK.Mcp.csproj"
NATIVE_ROOT = REPO_ROOT / "native"
E2E_TEST = REPO_ROOT / "PicoGK.Mcp" / "Tests" / "e2e_test.py"
DEFAULT_INSTALL_DIR = Path.home() / ".local" / "bin" / "picogk-mcp"

# Map (system, machine) -> .NET Runtime Identifier (RID)
# Only RIDs that have a matching native/ subdirectory are truly supported here.
SUPPORTED_RIDS = {
    "osx-arm64",
    "win-x64",
}


# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------

class Style:
    HEADER = "\033[1;36m"
    OK = "\033[1;32m"
    WARN = "\033[1;33m"
    ERR = "\033[1;31m"
    DIM = "\033[2m"
    RESET = "\033[0m"
    _enabled = sys.stdout.isatty()


def _s(code: str) -> str:
    return code if Style._enabled else ""


def header(msg: str) -> None:
    print(f"\n{_s(Style.HEADER)}{'=' * 70}{_s(Style.RESET)}")
    print(f"{_s(Style.HEADER)}{msg}{_s(Style.RESET)}")
    print(f"{_s(Style.HEADER)}{'=' * 70}{_s(Style.RESET)}")


def ok(msg: str) -> None:
    print(f"  {_s(Style.OK)}[OK]{_s(Style.RESET)} {msg}")


def warn(msg: str) -> None:
    print(f"  {_s(Style.WARN)}[WARN]{_s(Style.RESET)} {msg}")


def err(msg: str) -> None:
    print(f"  {_s(Style.ERR)}[FAIL]{_s(Style.RESET)} {msg}")


def step(msg: str) -> None:
    print(f"  {msg}...")


def die(msg: str, code: int = 1) -> NoReturn:
    err(msg)
    sys.exit(code)


# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

def detect_platform() -> tuple[str, str, str, bool]:
    """Return (rid, native_subdir, exe_name, is_windows)."""
    system = platform.system().lower()  # darwin | windows | linux
    machine = platform.machine().lower()  # arm64 | aarch64 | x86_64 | amd64

    is_windows = system == "windows"

    # Normalize machine names
    arch = machine
    if arch in ("x86_64", "amd64"):
        arch = "x64"
    elif arch in ("aarch64", "arm64"):
        arch = "arm64"

    if system == "darwin":
        rid = f"osx-{arch}"
    elif system == "windows":
        rid = f"win-{arch}"
    elif system == "linux":
        rid = f"linux-{arch}"
    else:
        die(f"Unsupported operating system: {system!r}")

    exe_name = "PicoGK.Mcp.exe" if is_windows else "PicoGK.Mcp"
    return rid, rid, exe_name, is_windows


# ---------------------------------------------------------------------------
# Command execution
# ---------------------------------------------------------------------------

def run_cmd(
    cmd: list[str],
    *,
    capture: bool = False,
    check: bool = True,
    verbose: bool = False,
    cwd: Path | None = None,
    timeout: int | None = None,
) -> subprocess.CompletedProcess:
    """Run a command, optionally streaming or capturing output."""
    if verbose and not capture:
        print(f"    $ {' '.join(cmd)}")
        result = subprocess.run(cmd, cwd=cwd, timeout=timeout)
        if check and result.returncode != 0:
            raise subprocess.CalledProcessError(result.returncode, cmd)
        return result

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=cwd,
        timeout=timeout,
    )
    if check and result.returncode != 0:
        if verbose:
            print(f"    $ {' '.join(cmd)}")
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        raise subprocess.CalledProcessError(result.returncode, cmd)
    return result


# ---------------------------------------------------------------------------
# Prerequisite checks
# ---------------------------------------------------------------------------

def check_dotnet() -> str:
    """Ensure .NET 9.0+ SDK is available; return the version string."""
    try:
        result = run_cmd(["dotnet", "--version"], capture=True, check=False)
    except FileNotFoundError:
        die("The 'dotnet' command was not found. Install the .NET 9.0 SDK:\n"
            "    https://dotnet.microsoft.com/download/dotnet/9.0")

    version = result.stdout.strip()
    if result.returncode != 0 or not version:
        die(f"Could not determine the dotnet version:\n{result.stderr}")

    try:
        major = int(version.split(".")[0])
    except (ValueError, IndexError):
        die(f"Cannot parse dotnet version: {version!r}")

    if major < 9:
        die(f".NET {version} is installed, but .NET 9.0+ SDK is required.\n"
            "    https://dotnet.microsoft.com/download/dotnet/9.0")

    # Confirm the 9.0 SDK is actually installed (not just a runtime).
    sdks = run_cmd(["dotnet", "--list-sdks"], capture=True).stdout
    if "9." not in sdks:
        die(f".NET {version} runtime found, but the 9.0 SDK is not installed.\n"
            "    Install the .NET 9.0 SDK: https://dotnet.microsoft.com/download/dotnet/9.0")

    return version


def check_repo_layout(rid: str) -> Path:
    """Verify the script is run from a valid PicoGK repo checkout."""
    if not MCP_CSPROJ.is_file():
        die(f"PicoGK.Mcp project not found at:\n    {MCP_CSPROJ}\n"
            f"Run this script from the PicoGK repository (it lives in scripts/).")

    native_dir = NATIVE_ROOT / rid
    if not native_dir.is_dir():
        die(f"No native libraries for platform '{rid}' in:\n    {native_dir}\n"
            f"This repo ships native libraries for: {sorted(SUPPORTED_RIDS)}.\n"
            f"To add support for '{rid}', place the compiled native libraries\n"
            f"    (picogk.26.2 and its dependencies) into native/{rid}/.")

    native_files = [p for p in native_dir.iterdir() if p.is_file()]
    if not native_files:
        die(f"The native library directory is empty:\n    {native_dir}")

    return native_dir


# ---------------------------------------------------------------------------
# Build & install
# ---------------------------------------------------------------------------

def build_and_install(
    rid: str,
    native_dir: Path,
    install_dir: Path,
    verbose: bool,
) -> Path:
    """Publish the self-contained MCP server and copy native libraries."""
    if not MCP_CSPROJ.is_file():
        die(f"MCP project not found: {MCP_CSPROJ}")

    # Clean the install directory to avoid stale native libs / old binaries.
    if install_dir.exists():
        step(f"Cleaning existing install dir {install_dir}")
        shutil.rmtree(install_dir)
    install_dir.mkdir(parents=True, exist_ok=True)

    # 1. dotnet publish (self-contained)
    step(f"Publishing self-contained build for {rid}")
    publish_cmd = [
        "dotnet", "publish", str(MCP_CSPROJ),
        "-c", "Release",
        "-r", rid,
        "--self-contained",
        "-o", str(install_dir),
        "--nologo",
    ]
    run_cmd(publish_cmd, capture=not verbose, verbose=verbose, timeout=600)
    ok(f"Published self-contained binary for {rid}")

    # 2. Copy native geometry libraries next to the executable.
    step(f"Copying native libraries from {native_dir}")
    copied = 0
    for src in native_dir.iterdir():
        if src.is_file():
            shutil.copy2(src, install_dir / src.name)
            copied += 1
    if copied == 0:
        die("No native library files were copied.")
    ok(f"Copied {copied} native library file(s) into {install_dir}")

    return install_dir


def verify_install(install_dir: Path, exe_name: str) -> Path:
    """Verify the executable and key native libraries are present."""
    exe = install_dir / exe_name
    if not exe.is_file():
        die(f"Built executable not found: {exe}")

    if os.name == "posix":
        st = os.stat(exe)
        os.chmod(exe, st.st_mode | 0o755)

    # Look for the core picogk native library.
    found_core = any(
        p.name.startswith("picogk.26.2") for p in install_dir.iterdir()
        if p.is_file()
    )
    if not found_core:
        die(f"Core native library 'picogk.26.2' not found in {install_dir}")

    ok(f"Executable: {exe}")
    ok(f"Native libs present in install dir")
    return exe


# ---------------------------------------------------------------------------
# Smoke test: launch the server and verify it answers an MCP initialize
# ---------------------------------------------------------------------------

def smoke_test(exe: Path) -> bool:
    """Spawn the server, send a JSON-RPC initialize, check for a response."""
    step("Smoke test: MCP initialize handshake")

    init_request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "build-script", "version": "1.0"},
        },
    }
    initialized_notification = {
        "jsonrpc": "2.0",
        "method": "notifications/initialized",
    }
    payload = (
        json.dumps(init_request) + "\n" +
        json.dumps(initialized_notification) + "\n"
    ).encode()

    try:
        proc = subprocess.Popen(
            [str(exe)],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except Exception as e:
        err(f"Could not launch {exe}: {e}")
        return False

    stdin = proc.stdin
    stdout = proc.stdout
    if stdin is None or stdout is None:
        err("Could not get server stdin/stdout pipes")
        proc.terminate()
        return False

    try:
        stdin.write(payload)
        stdin.flush()
    except Exception as e:
        err(f"Could not write to server stdin: {e}")
        proc.terminate()
        return False

    # The MCP stdio server emits the initialize result to stdout, then keeps
    # running (it's a long-lived server). Read a line with a short timeout,
    # then close stdin so the server shuts down cleanly.
    import select

    response_line = b""
    try:
        # Wait up to 15s for the server to write the response on stdout.
        ready, _, _ = select.select([stdout], [], [], 15)
        if ready:
            response_line = stdout.readline()
    except Exception:
        pass

    # Signal the server to exit by closing its stdin.
    try:
        stdin.close()
    except Exception:
        pass
    try:
        proc.wait(timeout=5)
    except Exception:
        proc.kill()
        proc.wait(timeout=5)

    text = response_line.decode(errors="replace").strip()

    if not text:
        err("Server produced no stdout response to initialize")
        return False

    if '"serverInfo"' in text and '"result"' in text:
        try:
            msg = json.loads(text)
            if msg.get("id") == 1 and "result" in msg:
                info = msg["result"].get("serverInfo", {})
                name = info.get("name", "?")
                ver = info.get("version", "?")
                ok(f"Server responded to initialize: {name} v{ver}")
                return True
        except Exception:
            pass
        ok("Server responded to initialize")
        return True

    err("Server response did not contain a valid initialize result")
    print(f"  {_s(Style.DIM)}stdout:{_s(Style.RESET)}\n{text[:800]}")
    return False


# ---------------------------------------------------------------------------
# End-to-end test
# ---------------------------------------------------------------------------

def ensure_mcp_python_package() -> None:
    """Ensure the 'mcp' Python package is available for the e2e test."""
    try:
        import mcp  # noqa: F401
        ok("'mcp' Python package available")
        return
    except ImportError:
        pass

    step("Installing 'mcp' Python package (required by the e2e test)")
    run_cmd([sys.executable, "-m", "pip", "install", "--quiet", "mcp"],
            capture=True, verbose=False)
    ok("Installed 'mcp' Python package")


def run_e2e_test(exe: Path) -> bool:
    """Run the comprehensive Python e2e test suite."""
    if not E2E_TEST.is_file():
        warn(f"E2E test script not found: {E2E_TEST}")
        return False

    ensure_mcp_python_package()

    outdir = Path(tempfile.mkdtemp(prefix="picogk_e2e_"))
    step(f"Running end-to-end test suite (output: {outdir})")
    result = subprocess.run(
        [sys.executable, str(E2E_TEST), str(exe), str(outdir)],
    )
    if result.returncode == 0:
        ok("End-to-end test suite PASSED")
        return True
    else:
        err("End-to-end test suite FAILED")
        return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build, install, and test the PicoGK MCP server.",
    )
    parser.add_argument(
        "--install-dir",
        type=Path,
        default=DEFAULT_INSTALL_DIR,
        help=f"Destination directory (default: {DEFAULT_INSTALL_DIR})",
    )
    parser.add_argument(
        "--skip-test",
        action="store_true",
        help="Skip the smoke and end-to-end tests after building",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show full output of underlying commands",
    )
    args = parser.parse_args()

    rid, native_subdir, exe_name, is_windows = detect_platform()
    header(f"PicoGK MCP Server — Build, Install & Test")
    print(f"  Platform:      {platform.system()} {platform.machine()}")
    print(f"  .NET RID:      {rid}")
    print(f"  Repo root:     {REPO_ROOT}")
    print(f"  Install dir:   {args.install_dir}")

    if rid not in SUPPORTED_RIDS:
        warn(f"Platform RID '{rid}' is not in the shipped set "
             f"({sorted(SUPPORTED_RIDS)}).")

    # 1. Prerequisites
    header("Step 1 — Checking prerequisites")
    dotnet_ver = check_dotnet()
    ok(f".NET SDK {dotnet_ver} found")
    native_dir = check_repo_layout(rid)
    ok(f"Native libraries for '{rid}' found at {native_dir}")

    # 2. Build & install
    header("Step 2 — Building & installing (self-contained)")
    install_dir = build_and_install(
        rid, native_dir, args.install_dir, args.verbose
    )
    exe = verify_install(install_dir, exe_name)

    print()
    print(f"  {_s(Style.OK)}Installation complete{_s(Style.RESET)}")
    print(f"  {_s(Style.DIM)}Executable:{_s(Style.RESET)} {exe}")
    print(f"  {_s(Style.DIM)}Native libs:{_s(Style.RESET)} "
          f"{sum(1 for _ in install_dir.iterdir())} files in {install_dir}")

    # 3. Test
    if args.skip_test:
        header("Step 3 — Tests skipped (--skip-test)")
        print(f"  To test manually:  {sys.executable} {E2E_TEST} {exe}")
        return 0

    header("Step 3 — Testing")
    if not smoke_test(exe):
        err("Smoke test failed — aborting before e2e suite")
        return 1
    ok("Smoke test passed")

    if not run_e2e_test(exe):
        err("End-to-end tests failed")
        return 1

    header("All done")
    print(f"  {_s(Style.OK)}PicoGK MCP server is built, installed, and tested.{_s(Style.RESET)}")
    print(f"  {_s(Style.DIM)}Binary:{_s(Style.RESET)} {exe}")
    print()
    print(f"  Configure your MCP client to launch:")
    print(f"    {_s(Style.DIM)}command:{_s(Style.RESET)} {exe}")
    print(f"    {_s(Style.DIM)}args:{_s(Style.RESET)} []")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(130)