using BenchmarkDotNet.Attributes;

namespace RapidYencSharp.Benchmarks;

[MemoryDiagnoser]
[ShortRunJob]
public class YencBenchmarks
{
    private byte[] _source = null!;
    private byte[] _encoded = null!;
    private byte[] _encodeDestination = null!;
    private byte[] _decodeDestination = null!;
    private int _encodedLength;

    [Params(128, 8192, 1_048_576)]
    public int PayloadSize { get; set; }

    [GlobalSetup]
    public void Setup()
    {
        _source = new byte[PayloadSize];
        new Random(0x5EED + PayloadSize).NextBytes(_source);

        int maxEncodedLength = checked((int)YencEncoder.GetMaxEncodedLength((nuint)_source.Length));
        _encoded = new byte[maxEncodedLength];
        _encodeDestination = new byte[maxEncodedLength];
        _decodeDestination = new byte[maxEncodedLength];
        _encodedLength = YencEncoder.Encode(_source, _encoded);
    }

    [Benchmark(Baseline = true)]
    public int EncodeSpan()
    {
        return YencEncoder.Encode(_source, _encodeDestination);
    }

    [Benchmark]
    public byte[] EncodeAllocating()
    {
        return YencEncoder.Encode(_source);
    }

    [Benchmark]
    public int DecodeSpan()
    {
        RapidYencDecoderState? state = RapidYencDecoderState.RYDEC_STATE_CRLF;
        return YencDecoder.DecodeEx(
            _encoded.AsSpan(0, _encodedLength),
            _decodeDestination,
            ref state,
            isRaw: false);
    }

    [Benchmark]
    public byte[] DecodeAllocating()
    {
        return YencDecoder.Decode(_encoded.AsSpan(0, _encodedLength));
    }

    [Benchmark]
    public uint ComputeCrc32()
    {
        return Crc32.Compute(_source);
    }
}
