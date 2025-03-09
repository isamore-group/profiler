# Basic Block Tracer for gem5

This repository contains a Basic Block Tracer (BBTracer) for the gem5 simulator. The BBTracer is designed to track the execution of basic blocks in a program and record execution counts and timing information for each basic block.

## Overview

The BBTracer is an instruction tracer that attaches to a CPU in gem5 and monitors all executed instructions. When it detects a basic block marker instruction (a `lea` instruction that points to a string with the format "bbid#functionname#bbname"), it records the execution count and time for that basic block. At the end of the simulation, it writes the results to a CSV file.

## How It Works

1. The BBTracer is an InstTracer that attaches to the CPU's instruction execution pipeline.
2. For each instruction executed, it checks if the instruction is a `lea` instruction.
3. If it is a `lea` instruction, it extracts the target address from the instruction.
4. It then reads the memory at the target address to check if it contains a string with the format "bbid#functionname#bbname".
5. If it finds such a string, it records the basic block ID and updates the execution count and timing information.
6. At the end of the simulation, it writes the results to a CSV file.

## Building gem5 with BBTracer

To build gem5 with the BBTracer, follow these steps:

1. Clone the gem5 repository:
   ```
   git clone https://github.com/gem5/gem5.git
   ```

2. Copy the BBTracer files to the gem5 repository:
   - `src/cpu/bbtracer.hh` -> `gem5/src/cpu/bbtracer.hh`
   - `src/cpu/bbtracer.cc` -> `gem5/src/cpu/bbtracer.cc`
   - `src/debug/BBTracer.hh` -> `gem5/src/debug/BBTracer.hh`

3. Update the gem5 build files:
   - Add `Source('bbtracer.cc')` to `gem5/src/cpu/SConscript`
   - Add `DebugFlag('BBTracer', 'Basic Block Tracer')` to `gem5/src/cpu/SConscript`
   - Add the BBTracer class to `gem5/src/cpu/CPUTracers.py`

4. Build gem5:
   ```
   cd gem5
   scons build/X86/gem5.opt -j$(nproc)
   ```

## Using the BBTracer

To use the BBTracer, you need to:

1. Instrument your program with basic block markers using the BBInstrument LLVM pass.
2. Run the instrumented program with gem5 using the BBTracer.

### Example

```python
# Create a BBTracer for the core
bb_tracer = BBTracer(
    output_file="bb_tracer.csv"
)

# Set the tracer for the CPU
processor.get_cores()[0].core.tracer = bb_tracer

# Enable the BBTracer debug flag
m5.debug.flags["BBTracer"].enable()
```

### Running the Example Script

We provide an example script `x86-bb-tracer-example.py` that demonstrates how to use the BBTracer:

```
./build/X86/gem5.opt --debug-flags=BBTracer x86-bb-tracer-example.py __test.exe
```

You can specify the output file for the profiling results:

```
./build/X86/gem5.opt --debug-flags=BBTracer x86-bb-tracer-example.py __test.exe --output=my_profile.csv
```

You can also pass arguments to the binary:

```
./build/X86/gem5.opt --debug-flags=BBTracer x86-bb-tracer-example.py __test.exe --args="arg1 arg2"
```

## Output Format

The BBTracer writes the profiling results to a CSV file with the following columns:

- Basic Block ID: The ID of the basic block (functionname#bbname)
- Execution Count: The number of times the basic block was executed
- Total Time (ticks): The total time spent in the basic block (in ticks)
- Average Time (ticks): The average time spent in the basic block (in ticks)

## Debugging

You can enable debug output by adding the `--debug-flags=BBTracer` option to your gem5 command line. This will show detailed information about each basic block marker found during execution.

## License

This project is licensed under the BSD 3-Clause License - see the LICENSE file for details.

## Acknowledgments

- The gem5 team for providing the gem5 simulator
- The LLVM team for providing the LLVM compiler infrastructure 