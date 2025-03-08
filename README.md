# LLVM Basic Block Instrumentation

This project provides an LLVM pass for basic block instrumentation that enables mapping between source code basic blocks and their addresses in compiled binaries.

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
   - Creates a unique identifier string in the format `bbid#function_name#basic_block_name`
   - Creates a global string variable containing this identifier
   - Inserts a marker instruction at the beginning of the basic block that references this global string
   - The marker is designed to be preserved through optimization passes

2. When analyzing the binary:
   - The analysis script extracts the addresses and identifiers of all basic blocks
   - This creates a mapping between binary addresses and source-level basic blocks
   - The mapping is saved to a CSV file for further analysis

## Usage

### All-in-One Approach

The easiest way to use this tool is with the combined `bb_map.sh` script, which handles the entire process from compilation to analysis:

```bash
./bb_map.sh your_source_file.cpp
```

This will:
1. Compile your source file to LLVM IR
2. Apply the basic block instrumentation pass
3. Compile the instrumented IR to an executable
4. Analyze the executable to extract basic block mappings
5. Save the mappings to a CSV file

For more options:

```bash
./bb_map.sh --help
```

Available options include:
- `-c, --cflags <flags>`: Additional compiler flags for clang
- `-o, --opt-flags <flags>`: Additional flags for opt
- `-s, --skip-compile`: Skip initial compilation (if input is already LLVM IR)
- `-m, --output-map <file>`: Custom output file for the basic block mapping
- `-d, --objdump <path>`: Custom path to objdump executable
- `-k, --keep-temps`: Keep temporary files (IR, assembly, etc.)
- `-n, --no-run`: Don't run the executable after compilation

### Step-by-Step Approach

Alternatively, you can use the individual scripts for more control:

#### 1. Instrumenting Code

Use the provided `run_test.sh` script in the `tests` directory:

```bash
cd tests
./run_test.sh your_source_file.cpp
```

Or manually:

```bash
# Compile source to LLVM IR
clang++ -S -emit-llvm source.cpp -o source.ll

# Apply the instrumentation pass
opt -load-pass-plugin=./build/lib/libbb_instrument.so -passes=bb_instrument source.ll -o instrumented.ll

# Compile to executable
clang++ instrumented.ll -o executable
```

#### 2. Analyzing the Binary

After compiling the instrumented code, use the `analyze_binary.sh` script:

```bash
./analyze_binary.sh executable
```

This will create a `bb_mapping.csv` file with the format:
```
Address,Basic Block ID
1234,function_name#entry
5678,function_name#if.then
...
```

## Technical Details

- The instrumentation uses a store instruction to a global string variable, which creates a reference that is preserved through optimization
- The format of the identifier is `bbid#function_name#block_name` to make it easy to extract from assembly
- The pass works with standard LLVM optimization passes and doesn't significantly impact performance
- The analysis script uses `objdump` to extract the markers from the compiled binary

## Requirements

- LLVM 14.0 or newer
- CMake 3.16 or newer
- A C++20 compatible compiler 