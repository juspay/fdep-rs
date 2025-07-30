#!/bin/bash
set -e

echo "Setting up fdep-rs..."

# Install and setup the specific nightly version
rustup install nightly-2024-10-01
rustup component add --toolchain nightly-2024-10-01 rustc-dev
rustup override set nightly-2024-10-01

# Get the sysroot for the specific toolchain
SYSROOT=$(rustc +nightly-2024-10-01 --print sysroot)
LIB_PATH="$SYSROOT/lib"

echo "Using toolchain: $(rustc --version)"

# Check if the required libraries exist
if [ ! -d "$LIB_PATH" ]; then
    echo "Error: Library directory $LIB_PATH does not exist!"
    exit 1
fi

# Set environment variables
export RUSTFLAGS="-L $LIB_PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$LIB_PATH"
export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:$LIB_PATH"  # macOS specific

# Clean and build
cargo clean
cargo install --path . --force

# Create a wrapper script that works on macOS
cat > ~/.cargo/bin/fdep-wrapper << 'EOF'
#!/bin/bash
SYSROOT=$(rustc --print sysroot)
export RUSTFLAGS="-L $SYSROOT/lib"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SYSROOT/lib"
export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:$SYSROOT/lib"
fdep "$@"
EOF

chmod +x ~/.cargo/bin/fdep-wrapper

# Helper scripts setup complete

echo ""
echo "Setup complete!"
echo ""
echo "Usage:"
echo "  cargo fdep                              # Smart analysis with suggestions"
echo "  cargo fdep --all-features --all-targets # Maximum coverage"