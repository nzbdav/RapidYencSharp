# RapidYencSharp Agent Guide

## Purpose and stack

- RapidYencSharp is a .NET 10 binding for the rapidyenc native library.
- `RapidYencSharp/` contains the managed package; `rapidyenc/` is a submodule
  of `nzbdav/rapidyenc` used to produce runtime-specific binaries.
- Release Please versions the package; GitHub Actions builds and publishes
  releases.

## Architecture

- `NativeMethods.cs` defines the P/Invoke boundary. Keep entry points, calling
  conventions, integer widths, and state layouts synchronized with native code.
- `YencEncoder.cs` and `YencDecoder.cs` provide allocating and span-based APIs.
  Keep hot paths allocation-conscious and validate destination capacities.
- `Crc32.cs` wraps native CRC operations.
- `Version.cs` reports the native rapidyenc version, not the NuGet package
  version.
- `build-native.sh` cross-compiles `linux-x64`, `linux-arm64`, and `win-x64`
  assets into `RapidYencSharp/runtimes/`. The Dockerfile Alpine stages add
  `linux-musl-x64` and `linux-musl-arm64`.

## Required invariants

- Do not read beyond source spans or write beyond destination spans.
- Keep managed state structures layout-compatible with native rapidyenc.
- Preserve incremental encoder and decoder state across chunk boundaries.
- Treat all encoded input as untrusted; avoid unchecked narrowing and buffer
  size arithmetic.
- Do not commit generated native libraries or native build directories.

## Development workflow

```bash
dotnet restore --locked-mode
dotnet format RapidYencSharp.sln --verify-no-changes --no-restore
dotnet build RapidYencSharp.sln --configuration Release --no-restore
dotnet test RapidYencSharp.Tests/RapidYencSharp.Tests.csproj --configuration Release --no-build
./build-artifacts.sh
python3 scripts/validate-package.py artifacts/packages
```

- The container build is the authoritative multi-RID package build.
- Add regression tests for encoding, decoding, CRC, interop, bounds, and
 incremental-state changes. Use `RapidYencSharp.Benchmarks` for measured
 hot-path changes; do not make timed benchmarks a CI gate.
- Keep nullable analysis enabled and resolve warnings rather than suppressing
  them without justification.

## Public API and compatibility

- Avoid silent public API or native ABI breaks. Isolate compatibility changes,
  document them, and use semantic versioning.
- The NuGet package ID is `NzbDav.RapidYencSharp`.
- Supported packaged runtimes are `linux-x64`, `linux-arm64`,
  `linux-musl-x64`, `linux-musl-arm64`, and `win-x64`.

## Repository and release

- `README.md`, `LICENSE`, and `CHANGELOG.md` are packed into the NuGet package.
- `.github/workflows/ci.yml` is the required pull-request quality gate.
- `release-please-config.json` updates the version in
  `RapidYencSharp/RapidYencSharp.csproj`.
- Release artifacts must be built from the release tag only after locked
  restore, native compilation, managed build, and package validation succeed.

## Commit convention

- Use scoped Conventional Commits: `feat(scope):`, `fix(scope):`, or
  `chore(scope):`.
- Choose a concise scope such as `yenc`, `crc`, `interop`, `native`, `ci`,
  `deps`, or `docs`.
- Release Please uses commit types for release notes and versions: `feat`
  triggers a minor release, `fix` triggers a patch release, and `chore` does
  not trigger a release.
- Mark breaking changes with `!` (for example, `feat(interop)!:`) and include a
  `BREAKING CHANGE:` footer.
- Keep unrelated changes in separate commits so each release-note entry
  describes one coherent change.

## Start here

Read `README.md`, `RapidYencSharp/NativeMethods.cs`,
`RapidYencSharp/YencEncoder.cs`, `RapidYencSharp/YencDecoder.cs`,
`RapidYencSharp/Crc32.cs`, both build scripts, and the project file before
changing behavior.
