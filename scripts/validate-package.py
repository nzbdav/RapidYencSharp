#!/usr/bin/env python3
"""Validate RapidYencSharp NuGet package contents."""

from __future__ import annotations

import argparse
from pathlib import Path
import zipfile


EXPECTED_PACKAGE_FILES = {
    "lib/net10.0/RapidYencSharp.dll",
    "lib/net10.0/RapidYencSharp.xml",
    "runtimes/linux-x64/native/librapidyenc.so",
    "runtimes/linux-arm64/native/librapidyenc.so",
    "runtimes/linux-musl-x64/native/librapidyenc.so",
    "runtimes/linux-musl-arm64/native/librapidyenc.so",
    "runtimes/win-x64/native/rapidyenc.dll",
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
}


def single_package(directory: Path, pattern: str) -> Path:
    packages = sorted(directory.glob(pattern))
    if len(packages) != 1:
        raise ValueError(
            f"Expected exactly one {pattern} in {directory}, found {packages}"
        )
    return packages[0]


def validate(directory: Path) -> None:
    package = single_package(directory, "*.nupkg")
    symbols = single_package(directory, "*.snupkg")

    with zipfile.ZipFile(package) as archive:
        names = set(archive.namelist())
        missing = EXPECTED_PACKAGE_FILES.difference(names)
        if missing:
            raise ValueError(f"{package} is missing: {sorted(missing)}")
        stale = sorted(name for name in names if name.startswith("lib/net9.0/"))
        if stale:
            raise ValueError(f"{package} contains stale .NET 9 assets: {stale}")

    with zipfile.ZipFile(symbols) as archive:
        names = set(archive.namelist())
        expected_pdb = "lib/net10.0/RapidYencSharp.pdb"
        if expected_pdb not in names:
            raise ValueError(f"{symbols} is missing: {expected_pdb}")
        stale = sorted(name for name in names if name.startswith("lib/net9.0/"))
        if stale:
            raise ValueError(f"{symbols} contains stale .NET 9 assets: {stale}")

    print(f"Validated {package} and {symbols}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "directory",
        nargs="?",
        type=Path,
        default=Path("artifacts/packages"),
        help="Directory containing the .nupkg and .snupkg files",
    )
    args = parser.parse_args()
    validate(args.directory)


if __name__ == "__main__":
    main()
