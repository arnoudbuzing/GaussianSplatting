#!/usr/bin/env zsh
# build.sh - Build the Rust library and install it into the paclet's LibraryResources

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUST_DIR="$SCRIPT_DIR/rust"
PACLET_DIR="$SCRIPT_DIR/GaussianSplatting"
SYSTEM_ID="MacOSX-ARM64"

echo "==> Building Rust library..."
cd "$RUST_DIR"
cargo build --release

echo "==> Installing dylib to paclet..."
LIB_DEST="$PACLET_DIR/LibraryResources/$SYSTEM_ID"
mkdir -p "$LIB_DEST"
cp "$RUST_DIR/target/release/libgaussian_splatting.dylib" "$LIB_DEST/"
codesign -f -s - "$LIB_DEST/libgaussian_splatting.dylib"

echo "==> Done. Library installed at:"
ls -lh "$LIB_DEST/"
