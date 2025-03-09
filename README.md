# LLVM/GEM5 Basic Block Instrumentation

This project provides an LLVM pass for basic block instrumentation that enables mapping between source code basic blocks and their addresses in compiled binaries. It also provides a GEM5 tracer for LLVM basic block profiling.

## Overview

The `bb_instrument` pass inserts marker instructions at the beginning of each basic block in LLVM IR. These markers reference unique identifiers that include the function name and basic block name. When the instrumented code is compiled to a binary, these markers can be identified in the assembly, allowing for precise mapping between source-level basic blocks and their machine code addresses.

## Building

```bash
mkdir -p build
cd build
cmake ..
make
```

## How It Works

1. For each basic block in the program, the pass:
   - Creates a unique identifier string in the format `____bbid#function_name#basic_block_name`
   - Creates a global string variable containing this identifier
   - Inserts a marker instruction at the beginning of the basic block that references this global string
   - The marker is designed to be preserved through optimization passes

2. When analyzing the binary:
   - The analysis script extracts the addresses and identifiers of all basic blocks
   - This creates a mapping between binary addresses and source-level basic blocks
   - The mapping is saved to a CSV file for further analysis

## Usage (LLVM Part)

### All-in-One Approach

The easiest way to use this tool is with the combined `instrument_bb.sh` script, which handles the entire process from compilation to analysis:

```bash
./instrument_bb.sh your_source_file.cpp
```

This will:
1. Compile your source file to LLVM IR
2. Apply the basic block instrumentation pass
3. Compile the instrumented IR to an executable
4. Analyze the executable to extract basic block mappings
5. Save the mappings to a CSV file

For more options:

```bash
./instrument_bb.sh --help
```

Available options include:
- `-c, --cflags <flags>`: Additional compiler flags for clang
- `-o, --opt-flags <flags>`: Additional flags for opt
- `-s, --skip-compile`: Skip initial compilation (if input is already LLVM IR)
- `-m, --output-map <file>`: Custom output file for the basic block mapping
- `-d, --objdump <path>`: Custom path to objdump executable
- `-k, --keep-temps`: Keep temporary files (IR, assembly, etc.)
- `-n, --no-run`: Don't run the executable after compilation

## Usage (GEM5 Part)

### Basic Block Profiling

To profile basic blocks in a GEM5 simulation, you can use the `x86-bb-tracer-example.py` script. This script sets up a basic GEM5 simulation with a single core and a simple memory system, and then uses the `BBTracer` to profile the basic blocks of the program.

See the [BB_TRACER_README.md](BB_TRACER_README.md) file for more details.



## Requirements

- LLVM 14.0 or newer
- CMake 3.16 or newer
- A C++20 compatible compiler 
