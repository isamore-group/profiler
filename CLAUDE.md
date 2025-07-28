# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a basic block profiling system that combines LLVM-based static instrumentation with gem5 simulation-based dynamic tracing. The system is designed to analyze program performance at the basic block level with detailed timing and execution count information.

## Key Commands

### Building the LLVM Pass
```bash
mkdir -p build
cd build
cmake ..
make
```

### Instrumenting and Analyzing Programs
```bash
# Basic usage
./instrument_bb.sh <source_file>

# With options
./instrument_bb.sh -c "<compiler_flags>" -o "<opt_flags>" -m <output_map.csv> <source_file>
```

### Running gem5 Simulation with BBTracer
```bash
# Basic execution
./gem5/build/X86/gem5.opt --debug-flags=BBTracer x86-bb-tracer-example.py <instrumented_binary>

# With custom options (modify x86-bb-tracer-example.py)
# CPU types: SimpleTimingCPU, MinorCPU, O3CPU
# Cache configurations available
```

### Running Tests
```bash
cd tests
./run_test.sh
```

## Architecture

The system operates in two phases:

1. **Static Instrumentation (BBInstrument.cpp)**
   - LLVM pass that inserts marker instructions at basic block entries
   - Markers format: `____bbid#function_name#block_name`
   - Generates CSV mapping of addresses to basic block IDs
   - Supports operation counting within basic blocks

2. **Dynamic Tracing (gem5 BBTracer)**
   - gem5 CPU model extension that monitors marker instructions
   - Records execution counts and timing for each basic block
   - Outputs profiling results to CSV files
   - Supports multiple CPU models and cache configurations

## Important Files

- `BBInstrument.cpp` - Main LLVM instrumentation pass
- `instrument_bb.sh` - Master script for instrumentation workflow
- `x86-bb-tracer-example.py` - gem5 configuration script with BBTracer
- `gem5/` - Submodule containing modified gem5 with BBTracer support

## Output Files

The system generates several output files in `__temp/`:
- `*.ll` - LLVM IR files
- `*.s` - Assembly files with markers
- `*_instrumented` - Final instrumented binary
- `*.csv` - Basic block mapping and profiling results

## Notes

- Requires LLVM 14.0+ and gem5 with BBTracer patches
- The NOVIA/ directory contains a separate inline accelerator discovery framework
- Environment setup may be needed (see env.sh)
- gem5 simulations can be slow for large programs