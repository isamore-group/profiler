# LLVM Basic Block Address Mapper

This project provides LLVM passes for basic block profiling and address mapping.

## Building

```bash
mkdir -p build
cd build
cmake ..
make
```

## Instrument Pass

The `instrument` pass adds profiling instrumentation to count cycles and iterations for each basic block.

## AddressMapper Pass

The `address_mapper` pass inserts a marker at the beginning of each basic block that can be used to identify the basic block in the binary.

### How it works

1. For each basic block in the program, the pass:
   - Creates a unique identifier string (function_name:basic_block_name)
   - Creates a global string variable containing this identifier
   - Inserts a no-effect instruction at the beginning of the basic block that references this global string
   - The no-effect instruction is an add operation that adds 0 to the pointer value of the global string
   - To prevent optimization, the result is stored in a volatile global variable

2. When analyzing the binary:
   - A simulator or debugger can identify the beginning of each basic block by looking for these marker instructions
   - The global string referenced by the instruction contains the basic block's unique identifier
   - This allows mapping between basic blocks in the source code and their addresses in the binary

This approach is elegant because:
- It doesn't require any runtime support or external functions
- The marker instructions are simple and unlikely to be optimized away
- The global strings provide a clear mapping between basic blocks and their identifiers
- It works across different architectures and compilers

### Usage

To use the AddressMapper pass with `opt`:

```bash
opt -load-pass-plugin=./build/lib/libaddress_mapper.so -passes=address-mapper input.ll -o instrumented.ll
```

Then compile the instrumented IR:

```bash
clang++ instrumented.ll -o executable
```

When analyzing the binary, look for instructions that reference global strings with the prefix "bb_id_".

## Notes

- The marker instructions are inserted at the beginning of each basic block
- Each marker references a global string with the format "function_name:basic_block_name"
- The markers are designed to have no effect on program execution
- Make sure to compile with optimizations disabled (-O0) to prevent the markers from being optimized away 