#!/bin/bash
# Builds the rapidyenc native library for multiple runtime identifiers (RIDs)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAPIDYENC_DIR="$SCRIPT_DIR/rapidyenc"
BUILD_ROOT="$RAPIDYENC_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/RapidYencSharp/runtimes"

IFS=' ' read -r -a TARGET_RIDS <<< "${TARGET_RIDS:-linux-x64 linux-arm64 win-x64}"

if [[ ${#TARGET_RIDS[@]} -eq 0 ]]; then
    echo "No runtime identifiers specified. Set TARGET_RIDS or use defaults." >&2
    exit 1
fi

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

build_target() {
    local rid="$1"
    local -a lib_names=()
    local -a cmake_args=(-G Ninja -DCMAKE_BUILD_TYPE=Release)

    case "$rid" in
        linux-x64)
            lib_names=("librapidyenc.so")
            ;;
        linux-arm64)
            lib_names=("librapidyenc.so")
            if ! command -v aarch64-linux-gnu-g++ >/dev/null 2>&1; then
                echo "Error: aarch64-linux-gnu-g++ is required to build for linux-arm64." >&2
                return 1
            fi
            cmake_args+=(
                -DCMAKE_SYSTEM_NAME=Linux
                -DCMAKE_SYSTEM_PROCESSOR=aarch64
                -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc
                -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++
                -DCMAKE_FIND_ROOT_PATH=/usr/aarch64-linux-gnu
                -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER
                -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
                -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
                -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY
            )
            ;;
        win-x64)
            lib_names=("rapidyenc.dll" "librapidyenc.dll")
            if ! command -v x86_64-w64-mingw32-g++ >/dev/null 2>&1; then
                echo "Error: x86_64-w64-mingw32-g++ is required to build for win-x64." >&2
                return 1
            fi
            cmake_args+=(
                -DCMAKE_SYSTEM_NAME=Windows
                -DCMAKE_SYSTEM_PROCESSOR=x86_64
                -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc
                -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++
                -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres
                "-DCMAKE_SHARED_LINKER_FLAGS=-static-libstdc++ -static-libgcc"
            )
            ;;
        *)
            echo "Unsupported runtime identifier: $rid" >&2
            return 1
            ;;
    esac

    if ! command -v ninja >/dev/null 2>&1; then
        echo "Error: ninja is required but not found in PATH." >&2
        exit 1
    fi

    local build_dir="$BUILD_ROOT/$rid"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"

    echo "Configuring rapidyenc for $rid..."
    cmake -S "$RAPIDYENC_DIR" -B "$build_dir" "${cmake_args[@]}"

    echo "Building rapidyenc for $rid..."
    cmake --build "$build_dir" --config Release --target rapidyenc_shared

    local lib_path=""
    for candidate in "${lib_names[@]}"; do
        lib_path="$(find "$build_dir" -name "$candidate" -type f | head -n 1 || true)"
        if [[ -n "$lib_path" ]]; then
            break
        fi
    done

    if [[ -z "$lib_path" ]]; then
        echo "Error: Failed to locate expected library (${lib_names[*]}) for $rid" >&2
        return 1
    fi

    local output_path="$OUTPUT_DIR/$rid/native"
    mkdir -p "$output_path"
    local dest_name
    dest_name="$(basename "$lib_path")"
    if [[ "$rid" == win-x64 && "$dest_name" == "librapidyenc.dll" ]]; then
        dest_name="rapidyenc.dll"
    fi
    cp "$lib_path" "$output_path/$dest_name"

    echo "Copied $dest_name to $output_path"
}

for rid in "${TARGET_RIDS[@]}"; do
    build_target "$rid"
done

echo "Native builds complete. Output available in $OUTPUT_DIR."
