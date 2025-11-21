ARG DOTNET_SDK_VERSION=9.0

FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_SDK_VERSION}-bookworm-slim AS build

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
COPY RapidYencSharp/RapidYencSharp.csproj RapidYencSharp/

RUN dotnet restore RapidYencSharp/RapidYencSharp.csproj

COPY . .

RUN chmod +x build-native.sh \
    && ./build-native.sh

RUN dotnet build RapidYencSharp/RapidYencSharp.csproj -c Release --no-restore

RUN dotnet pack RapidYencSharp/RapidYencSharp.csproj \
    -c Release \
    --no-build \
    -o /dist/packages

RUN mkdir -p /dist/lib \
    && cp RapidYencSharp/bin/Release/net9.0/RapidYencSharp.dll /dist/lib/ \
    && cp RapidYencSharp/bin/Release/net9.0/RapidYencSharp.xml /dist/lib/ \
    && if [ -f RapidYencSharp/bin/Release/net9.0/RapidYencSharp.pdb ]; then cp RapidYencSharp/bin/Release/net9.0/RapidYencSharp.pdb /dist/lib/; fi \
    && cp -r RapidYencSharp/runtimes /dist/

FROM scratch AS export

COPY --from=build /dist /artifacts
