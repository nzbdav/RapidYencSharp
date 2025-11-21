using System;
using System.Runtime.InteropServices;

namespace RapidYencSharp;

public enum RapidYencDecoderState
{
    RYDEC_STATE_CRLF = 0,
    RYDEC_STATE_EQ = 1,
    RYDEC_STATE_CR = 2,
    RYDEC_STATE_NONE = 3,
    RYDEC_STATE_CRLFDT = 4,
    RYDEC_STATE_CRLFDTCR = 5,
    RYDEC_STATE_CRLFEQ = 6
}

public enum RapidYencDecoderEnd
{
    RYDEC_END_NONE = 0,
    RYDEC_END_CONTROL = 1,
    RYDEC_END_ARTICLE = 2
}

/// <summary>
/// P/Invoke declarations for the rapidyenc native library
/// </summary>
internal static class NativeMethods
{
    private const string LibraryName = "rapidyenc";

    static NativeMethods()
    {
        // Try to load the native library
        NativeLibrary.SetDllImportResolver(typeof(NativeMethods).Assembly, (libraryName, assembly, searchPath) =>
        {
            if (libraryName == LibraryName)
            {
                // Try common library names
                if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                {
                    if (NativeLibrary.TryLoad("librapidyenc.so", assembly, searchPath, out var handle))
                        return handle;
                    if (NativeLibrary.TryLoad("rapidyenc", assembly, searchPath, out handle))
                        return handle;
                }
                else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                {
                    if (NativeLibrary.TryLoad("rapidyenc.dll", assembly, searchPath, out var handle))
                        return handle;
                    if (NativeLibrary.TryLoad("rapidyenc", assembly, searchPath, out handle))
                        return handle;
                }
                else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
                {
                    if (NativeLibrary.TryLoad("librapidyenc.dylib", assembly, searchPath, out var handle))
                        return handle;
                    if (NativeLibrary.TryLoad("rapidyenc", assembly, searchPath, out handle))
                        return handle;
                }
            }
            return IntPtr.Zero;
        });
    }

    // Version
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int rapidyenc_version();

    // Kernel constants
    public const int RYKERN_GENERIC = 0;
    public const int RYKERN_SSE2 = 0x100;
    public const int RYKERN_SSSE3 = 0x200;
    public const int RYKERN_AVX = 0x381;
    public const int RYKERN_AVX2 = 0x403;
    public const int RYKERN_VBMI2 = 0x603;
    public const int RYKERN_NEON = 0x1000;
    public const int RYKERN_RVV = 0x10000;
    public const int RYKERN_PCLMUL = 0x340;
    public const int RYKERN_VPCLMUL = 0x440;
    public const int RYKERN_ARMCRC = 8;
    public const int RYKERN_ARMPMULL = 0x48;
    public const int RYKERN_ZBC = 16;

    // Encode functions
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void rapidyenc_encode_init();

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern nuint rapidyenc_encode(
        [In] IntPtr src,
        [Out] IntPtr dest,
        nuint src_length);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern nuint rapidyenc_encode_ex(
        int line_size,
        ref int column,
        [In] IntPtr src,
        [Out] IntPtr dest,
        nuint src_length,
        int is_end);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern nuint rapidyenc_encode_ex(
        int line_size,
        IntPtr column,
        [In] IntPtr src,
        [Out] IntPtr dest,
        nuint src_length,
        int is_end);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int rapidyenc_encode_kernel();

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern nuint rapidyenc_encode_max_length(nuint length, int line_size);

    // Decode functions
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void rapidyenc_decode_init();

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern nuint rapidyenc_decode(
        [In] IntPtr src,
        [Out] IntPtr dest,
        nuint src_length);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern nuint rapidyenc_decode_ex(
        int is_raw,
        [In] IntPtr src,
        [Out] IntPtr dest,
        nuint src_length,
        ref RapidYencDecoderState state);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern nuint rapidyenc_decode_ex(
        int is_raw,
        [In] IntPtr src,
        [Out] IntPtr dest,
        nuint src_length,
        IntPtr state);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern RapidYencDecoderEnd rapidyenc_decode_incremental(
        ref IntPtr src,
        ref IntPtr dest,
        nuint src_length,
        ref RapidYencDecoderState state);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int rapidyenc_decode_kernel();

    // CRC32 functions
    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern void rapidyenc_crc_init();

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint rapidyenc_crc(
        [In] IntPtr src,
        nuint src_length,
        uint init_crc);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint rapidyenc_crc_combine(uint crc1, uint crc2, ulong length2);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint rapidyenc_crc_zeros(uint init_crc, ulong length);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint rapidyenc_crc_unzero(uint init_crc, ulong length);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint rapidyenc_crc_multiply(uint a, uint b);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint rapidyenc_crc_2pow(long n);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern uint rapidyenc_crc_256pow(ulong n);

    [DllImport(LibraryName, CallingConvention = CallingConvention.Cdecl)]
    public static extern int rapidyenc_crc_kernel();
}
