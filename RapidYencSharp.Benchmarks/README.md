# RapidYencSharp benchmarks

Run the benchmarks in Release mode with a locally built native library:

```bash
RAPIDYENC_LIBRARY_PATH=/absolute/path/to/librapidyenc \
  dotnet run --project RapidYencSharp.Benchmarks -c Release
```

The .NET 10 migration baseline was captured on an Apple M4 Pro with the same
native library for both runs. Moving from .NET 9.0.16 with `DllImport` to .NET
10.0.9 with source-generated `LibraryImport` changed the representative 8 KiB
span decode from 470.5 ns to 466.9 ns and span encode from 863.7 ns to 836.3 ns.
Span operations remained allocation-free. Large-buffer results varied within
the short-run noise expected when native SIMD dominates, so these benchmarks
are intended for local comparisons rather than CI pass/fail thresholds.
