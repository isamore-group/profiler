#!/bin/bash

# Parse command line arguments
function show_usage {
    echo "Usage: source env.sh [options]"
    echo "Options:"
    echo "  --llvm-install-path PATH   Set LLVM installation path"
    echo "  --llvm-build-path PATH     Set LLVM build path"
    echo "  --gem5-path PATH           Set gem5 path"
    echo "  -h, --help                 Show this help message"
}

# Default values
LLVM_INSTALL_PATH="$HOME/repos/jlm/usr/"
LLVM_BUILD_PATH="$HOME/repos/jlm/build-llvm-mlir"
CURRENT_DIR=$(pwd)
GEM5_PATH="$CURRENT_DIR/gem5"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --llvm-install-path)
            LLVM_INSTALL_PATH="$2"
            shift 2
            ;;
        --llvm-build-path)
            LLVM_BUILD_PATH="$2"
            shift 2
            ;;
        --gem5-path)
            GEM5_PATH="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            return 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            return 1
            ;;
    esac
done

# Set up environment variables
export LLVM_BUILD_DIR="$LLVM_BUILD_PATH"

# Set up aliases
alias clang-18="$LLVM_INSTALL_PATH/bin/clang-18"
alias opt-18="$LLVM_INSTALL_PATH/bin/opt"

# Set up gem5 alias if path is provided
if [ -n "$GEM5_PATH" ]; then
    alias gem5="$GEM5_PATH/build/X86/gem5.opt"
    alias gem5-debug="$GEM5_PATH/build/X86/gem5.debug"
fi
