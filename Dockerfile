ARG DOTNET_SDK_VERSION=10.0
ARG ALPINE_VERSION=3.21

# -------- musl natives (Alpine) --------
# Built as separate stages so linux-musl-* RID consumers (e.g. Alpine .NET
# images) do not fall back to the glibc linux-x64 binary via the RID graph.

FROM --platform=linux/amd64 alpine:${ALPINE_VERSION} AS rapidyenc-musl-x64
RUN apk add --no-cache build-base cmake ninja
WORKDIR /src
COPY rapidyenc/ ./
RUN cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release --target rapidyenc_shared \
    && mkdir -p /out \
    && lib_path="$(find build -name 'librapidyenc.so' -type f | head -n 1)" \
    && test -n "$lib_path" \
    && cp "$lib_path" /out/librapidyenc.so

FROM --platform=linux/arm64 alpine:${ALPINE_VERSION} AS rapidyenc-musl-arm64
RUN apk add --no-cache build-base cmake ninja
WORKDIR /src
COPY rapidyenc/ ./
RUN cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release --target rapidyenc_shared \
    && mkdir -p /out \
    && lib_path="$(find build -name 'librapidyenc.so' -type f | head -n 1)" \
    && test -n "$lib_path" \
    && cp "$lib_path" /out/librapidyenc.so

FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_SDK_VERSION}-noble AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        binutils-aarch64-linux-gnu \
        gcc-mingw-w64-x86-64 \
        g++-mingw-w64-x86-64 \
        binutils-mingw-w64-x86-64 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY RapidYencSharp.sln ./
COPY Directory.Build.props global.json ./
COPY RapidYencSharp/RapidYencSharp.csproj RapidYencSharp/
COPY RapidYencSharp/packages.lock.json RapidYencSharp/
COPY RapidYencSharp.Tests/RapidYencSharp.Tests.csproj RapidYencSharp.Tests/
COPY RapidYencSharp.Tests/packages.lock.json RapidYencSharp.Tests/
COPY RapidYencSharp.Benchmarks/RapidYencSharp.Benchmarks.csproj RapidYencSharp.Benchmarks/
COPY RapidYencSharp.Benchmarks/packages.lock.json RapidYencSharp.Benchmarks/

RUN dotnet restore RapidYencSharp.sln --locked-mode

COPY . .

RUN dotnet restore RapidYencSharp.sln --locked-mode \
    && chmod +x build-native.sh \
    && ./build-native.sh

# Overlay musl-built natives after the glibc/win cross-compile pass.
RUN mkdir -p \
        RapidYencSharp/runtimes/linux-musl-x64/native \
        RapidYencSharp/runtimes/linux-musl-arm64/native
COPY --from=rapidyenc-musl-x64 /out/librapidyenc.so RapidYencSharp/runtimes/linux-musl-x64/native/librapidyenc.so
COPY --from=rapidyenc-musl-arm64 /out/librapidyenc.so RapidYencSharp/runtimes/linux-musl-arm64/native/librapidyenc.so

RUN dotnet build RapidYencSharp.sln -c Release --no-restore

RUN LD_LIBRARY_PATH=/src/RapidYencSharp/runtimes/linux-x64/native \
    dotnet test RapidYencSharp.Tests/RapidYencSharp.Tests.csproj \
    -c Release \
    --no-build

RUN dotnet pack RapidYencSharp/RapidYencSharp.csproj \
    -c Release \
    --no-build \
    -o /dist/packages

RUN mkdir -p /dist/lib \
    && cp RapidYencSharp/bin/Release/net10.0/RapidYencSharp.dll /dist/lib/ \
    && cp RapidYencSharp/bin/Release/net10.0/RapidYencSharp.xml /dist/lib/ \
    && if [ -f RapidYencSharp/bin/Release/net10.0/RapidYencSharp.pdb ]; then cp RapidYencSharp/bin/Release/net10.0/RapidYencSharp.pdb /dist/lib/; fi \
    && cp -r RapidYencSharp/runtimes /dist/

FROM scratch AS export

COPY --from=build /dist /artifacts
