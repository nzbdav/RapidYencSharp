# RapidYencSharp

[![CI](https://github.com/nzbdav/RapidYencSharp/actions/workflows/ci.yml/badge.svg)](https://github.com/nzbdav/RapidYencSharp/actions/workflows/ci.yml)
[![NuGet](https://img.shields.io/nuget/v/NzbDav.RapidYencSharp.svg)](https://www.nuget.org/packages/NzbDav.RapidYencSharp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

.NET bindings for [rapidyenc](https://github.com/nzbdav/rapidyenc) - a high-performance yEnc encoding/decoding library.

Maintained by the [nzbdav organization](https://github.com/nzbdav).

## Features

- High-performance yEnc encoding and decoding
- CRC32 computation with combine operations
- Zero-allocation API using `Span<T>` and `ArrayPool<T>`
- Incremental encoding/decoding with state tracking
- NNTP dot unstuffing support
- Automatic SIMD optimization (SSE2, SSSE3, AVX, AVX2, VBMI2, NEON, RVV)
- Cross-platform support (Windows x64, Linux x64/ARM64)

## Installation

```bash
dotnet add package NzbDav.RapidYencSharp
```

## Requirements

- .NET 10.0 or later
- Native rapidyenc library (included in the package for supported platforms)

## Supported Platforms

| Runtime identifier | Architecture | Native library |
| --- | --- | --- |
| `linux-x64` | Linux x64 | `librapidyenc.so` |
| `linux-arm64` | Linux ARM64 | `librapidyenc.so` |
| `win-x64` | Windows x64 | `rapidyenc.dll` |

## Quick Start

### Basic Encoding and Decoding

```csharp
using RapidYencSharp;

// Encode data
byte[] original = Encoding.UTF8.GetBytes("Hello, World!");
byte[] encoded = YencEncoder.Encode(original);

// Decode data
byte[] decoded = YencDecoder.Decode(encoded);
```

### Zero-Allocation Encoding with Span

```csharp
ReadOnlySpan<byte> data = "Hello, World!"u8;

// Calculate maximum encoded size
nuint maxSize = YencEncoder.GetMaxEncodedLength((nuint)data.Length);

// Use stackalloc for small data
Span<byte> encodedBuffer = stackalloc byte[(int)maxSize];
int bytesWritten = YencEncoder.Encode(data, encodedBuffer);

// Decode back
Span<byte> decodedBuffer = stackalloc byte[data.Length];
int decodedBytes = YencDecoder.Decode(encodedBuffer[..bytesWritten], decodedBuffer);
```

### High-Performance Encoding with ArrayPool

```csharp
using System.Buffers;

byte[] largeData = new byte[10_000];
nuint maxSize = YencEncoder.GetMaxEncodedLength((nuint)largeData.Length);

byte[] encodedBuffer = ArrayPool<byte>.Shared.Rent((int)maxSize);
try
{
    int bytesWritten = YencEncoder.Encode(largeData, encodedBuffer);
    // Use encoded data...
}
finally
{
    ArrayPool<byte>.Shared.Return(encodedBuffer);
}
```

### Incremental Encoding

```csharp
int? column = 0;
byte[] chunk1 = Encoding.UTF8.GetBytes("First chunk");
byte[] chunk2 = Encoding.UTF8.GetBytes("Second chunk");

// Encode first chunk
byte[] encoded1 = YencEncoder.EncodeEx(chunk1, ref column, lineSize: 128, isEnd: false);

// Encode final chunk
byte[] encoded2 = YencEncoder.EncodeEx(chunk2, ref column, lineSize: 128, isEnd: true);
```

### CRC32 Computation

```csharp
byte[] data = Encoding.UTF8.GetBytes("Hello, World!");
uint crc = Crc32.Compute(data);
Console.WriteLine($"CRC32: 0x{crc:X8}");

// Combine CRC32 values
byte[] part1 = Encoding.UTF8.GetBytes("Hello, ");
byte[] part2 = Encoding.UTF8.GetBytes("World!");
uint crc1 = Crc32.Compute(part1);
uint crc2 = Crc32.Compute(part2);
uint combined = Crc32.Combine(crc1, crc2, (ulong)part2.Length);
```

## API Reference

### YencEncoder

#### Methods

- `byte[] Encode(ReadOnlySpan<byte> input)` - Encodes data and returns a new array
- `int Encode(ReadOnlySpan<byte> input, Span<byte> output, int lineSize = 128)` - Encodes data into provided buffer
- `byte[] EncodeEx(ReadOnlySpan<byte> input, ref int? column, int lineSize = 128, bool isEnd = true)` - Incremental encoding with column tracking
- `int EncodeEx(ReadOnlySpan<byte> input, Span<byte> output, ref int? column, int lineSize = 128, bool isEnd = true)` - Incremental encoding into buffer
- `nuint GetMaxEncodedLength(nuint inputLength, int lineSize = 128)` - Calculates maximum encoded output size

#### Properties

- `int Kernel` - Gets the SIMD instruction set used for encoding

### YencDecoder

#### Methods

- `byte[] Decode(ReadOnlySpan<byte> input)` - Decodes data and returns a new array
- `int Decode(ReadOnlySpan<byte> input, Span<byte> output)` - Decodes data into provided buffer
- `byte[] DecodeEx(ReadOnlySpan<byte> input, ref RapidYencDecoderState? state, bool isRaw = true)` - Decodes with NNTP dot unstuffing
- `int DecodeEx(ReadOnlySpan<byte> input, Span<byte> output, ref RapidYencDecoderState? state, bool isRaw = true)` - Decodes into buffer with state tracking
- `(byte[] DecodedData, RapidYencDecoderEnd EndState) DecodeIncremental(ReadOnlySpan<byte> input, ref RapidYencDecoderState state)` - Incremental decoding
- `int DecodeIncremental(ReadOnlySpan<byte> input, Span<byte> output, ref RapidYencDecoderState state, out RapidYencDecoderEnd endState)` - Incremental decoding into buffer

#### Properties

- `int Kernel` - Gets the SIMD instruction set used for decoding

### Crc32

#### Methods

- `uint Compute(ReadOnlySpan<byte> data, uint initCrc = 0)` - Computes CRC32 checksum
- `uint Combine(uint crc1, uint crc2, ulong length2)` - Combines two CRC32 values
- `uint Zeros(uint initCrc, ulong length)` - CRC32 of zero bytes
- `uint Unzero(uint initCrc, ulong length)` - Reverse operation of Zeros
- `uint Multiply(uint a, uint b)` - Multiplies two CRC32 polynomials
- `uint Pow2(long n)` - Computes 2^n in CRC32 polynomial field
- `uint Pow256(ulong n)` - Computes 256^n in CRC32 polynomial field

#### Properties

- `int Kernel` - Gets the SIMD instruction set used for CRC32

### Version

`Version` reports the version of the bundled native rapidyenc library. It is
independent from the RapidYencSharp NuGet package version shown by NuGet and
managed by Release Please.

#### Properties

- `int Major` - Major version number
- `int Minor` - Minor version number
- `int Patch` - Patch version number

#### Methods

- `int GetVersion()` - Returns version as integer (0xMMNNPP format)

## Performance

RapidYencSharp leverages the native rapidyenc library which automatically selects the best SIMD instruction set available on your CPU:

- **x86/x64**: Generic, SSE2, SSSE3, AVX, AVX2, VBMI2
- **ARM**: NEON, ARM CRC32, ARM PMULL
- **RISC-V**: RVV

The managed boundary uses source-generated interop and span-based APIs. C# 14's
first-class span conversions let arrays flow into these APIs without duplicate
array overloads, while the native library remains responsible for SIMD-heavy
encoding, decoding, and CRC work.

Check which instruction set is being used:

```csharp
Console.WriteLine($"Encode kernel: 0x{YencEncoder.Kernel:X}");
Console.WriteLine($"Decode kernel: 0x{YencDecoder.Kernel:X}");
Console.WriteLine($"CRC32 kernel: 0x{Crc32.Kernel:X}");
```

## Examples

The `Examples.cs` file contains comprehensive examples including:

- Basic encoding/decoding
- Incremental encoding with column tracking
- CRC32 computation and combining
- Zero-allocation encoding using stackalloc
- High-performance encoding with ArrayPool
- Streaming data processing

## Native Library

The package includes the native libraries listed under
[Supported Platforms](#supported-platforms). For other platforms, build
rapidyenc from source and place the resulting shared library in the application
directory. Custom deployments and local native builds can set
`RAPIDYENC_LIBRARY_PATH` to an absolute shared-library path.

## Building from Source

Clone the repository with its rapidyenc submodule:

```bash
git clone --recurse-submodules https://github.com/nzbdav/RapidYencSharp.git
cd RapidYencSharp
```

For an existing clone, initialize the submodule with
`git submodule update --init`.

The reproducible build uses the repository `Dockerfile` to compile every
supported native runtime and pack the NuGet package. With Podman installed:

```bash
./build-artifacts.sh
python3 scripts/validate-package.py artifacts/packages
```

Artifacts are written under `artifacts/`. To build directly on Linux, install
the CMake, Ninja, ARM64 Linux, and MinGW cross-compilers listed in the
`Dockerfile`, then run:

```bash
dotnet restore --locked-mode
./build-native.sh
dotnet build RapidYencSharp.sln --configuration Release --no-restore
dotnet test RapidYencSharp.Tests/RapidYencSharp.Tests.csproj \
  --configuration Release --no-build
dotnet pack RapidYencSharp/RapidYencSharp.csproj \
  --configuration Release --no-build --output artifacts/packages
```

Managed microbenchmarks are available in `RapidYencSharp.Benchmarks` and are
intended for local before/after comparisons rather than as a noisy CI gate.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The underlying rapidyenc library is licensed under its own terms. See the [rapidyenc repository](https://github.com/nzbdav/rapidyenc) for details.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) for the
development and release workflow. Report vulnerabilities according to
[SECURITY.md](SECURITY.md), not through public issues.

## Acknowledgments

- The original [rapidyenc project](https://github.com/animetosho/rapidyenc) by Anime Tosho
- All contributors to this project
