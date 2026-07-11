ARG DOTNET_SDK_VERSION=10.0

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

RUN chmod +x build-native.sh \
    && ./build-native.sh

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
