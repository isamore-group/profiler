#!/bin/bash

# instrument_bb.sh - Combined script for basic block instrumentation and analysis
# This script combines the functionality of run_test.sh and analyze_binary.sh
#
# Usage: ./instrument_bb.sh [options] <input_file>
# Options:
#   -c, --cflags <flags>     Additional compiler flags for clang
#   -o, --opt-flags <flags>  Additional flags for opt
#   -s, --skip-compile       Skip initial compilation (if input is already LLVM IR)
#   -m, --output-map <file>  Output CSV file for basic block mapping (default: <input>_bb_map.csv)
#   -d, --objdump <path>     Path to objdump executable
#   -k, --keep-temps         Keep temporary files (IR, assembly, etc.)
#   -n, --no-run             Don't run the executable after compilation
#   -h, --help               Show this help message

set -e  # Exit on error

# Default values
LLVM_PATH="${LLVM_PATH:-$HOME/repos/jlm/build-llvm-mlir}"
CLANG="${CLANG:-$LLVM_PATH/bin/clang++}"
OPT="${OPT:-$LLVM_PATH/bin/opt}"
PASS_PATH="${PASS_PATH:-./build/lib/libbb_instrument.so}"
OBJDUMP="${OBJDUMP:-objdump}"
CFLAGS=""
OPT_FLAGS=""
SKIP_COMPILE=0
KEEP_TEMPS=0
RUN_EXECUTABLE=1
OUTPUT_MAP=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--cflags)
      CFLAGS="$2"
      shift 2
      ;;
    -o|--opt-flags)
      OPT_FLAGS="$2"
      shift 2
      ;;
    -s|--skip-compile)
      SKIP_COMPILE=1
      shift
      ;;
    -m|--output-map)
      OUTPUT_MAP="$2"
      shift 2
      ;;
    -d|--objdump)
      OBJDUMP="$2"
      shift 2
      ;;
    -k|--keep-temps)
      KEEP_TEMPS=1
      shift
      ;;
    -n|--no-run)
      RUN_EXECUTABLE=0
      shift
      ;;
    -h|--help)
      echo "Usage: ./instrument_bb.sh [options] <input_file>"
      echo "Options:"
      echo "  -c, --cflags <flags>     Additional compiler flags for clang"
      echo "  -o, --opt-flags <flags>  Additional flags for opt"
      echo "  -s, --skip-compile       Skip initial compilation (if input is already LLVM IR)"
      echo "  -m, --output-map <file>  Output CSV file for basic block mapping (default: <input>_bb_map.csv)"
      echo "  -d, --objdump <path>     Path to objdump executable"
      echo "  -k, --keep-temps         Keep temporary files (IR, assembly, etc.)"
      echo "  -n, --no-run             Don't run the executable after compilation"
      echo "  -h, --help               Show this help message"
      exit 0
      ;;
    *)
      INPUT_FILE="$1"
      shift
      ;;
  esac
done

# Check if input file is provided
if [ -z "$INPUT_FILE" ]; then
  echo "Error: No input file specified"
  echo "Run './instrument_bb.sh --help' for usage information"
  exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file '$INPUT_FILE' not found"
  exit 1
fi

# Check if pass library exists
if [ ! -f "$PASS_PATH" ]; then
  echo "Error: LLVM pass library '$PASS_PATH' not found"
  echo "Make sure you've built the project or set the correct PASS_PATH"
  exit 1
fi

# Check if objdump is available
if ! command -v "$OBJDUMP" &> /dev/null; then
  echo "Error: objdump command not found. Please specify with --objdump option."
  exit 1
fi

# Set output file names based on input file name
FILENAME=$(basename -- "$INPUT_FILE")
FILENAME_NOEXT="${FILENAME%.*}"
OUTPUT_PREFIX="__$FILENAME_NOEXT"
LL_FILE="${OUTPUT_PREFIX}.ll"
INSTRUMENTED_LL="${OUTPUT_PREFIX}_instrumented.ll"
ASM_FILE="${OUTPUT_PREFIX}.s"
EXECUTABLE="${OUTPUT_PREFIX}.exe"

# Set default output map file if not specified
if [ -z "$OUTPUT_MAP" ]; then
  OUTPUT_MAP="${OUTPUT_PREFIX}_bb_map.csv"
fi

echo "=== Basic Block Instrumentation and Mapping ==="
echo "Input file: $INPUT_FILE"
echo "Output executable: $EXECUTABLE"
echo "Output mapping: $OUTPUT_MAP"
echo

# PART 1: INSTRUMENTATION (from run_test.sh)
echo "=== INSTRUMENTATION PHASE ==="

# Compile to LLVM IR if needed
if [ $SKIP_COMPILE -eq 0 ]; then
  echo "Compiling $INPUT_FILE to LLVM IR..."
  $CLANG -S -emit-llvm $CFLAGS "$INPUT_FILE" -o "$LL_FILE" || { 
    echo "Error: Failed to compile $INPUT_FILE to LLVM IR"; 
    exit 1; 
  }
else
  # If skipping compilation, the input file should be LLVM IR
  echo "Using $INPUT_FILE as LLVM IR..."
  LL_FILE="$INPUT_FILE"
fi

echo "Applying BBInstrument pass..."
# Apply the BBInstrument pass
$OPT -load-pass-plugin="$PASS_PATH" -passes=bb_instrument $OPT_FLAGS "$LL_FILE" -o "$INSTRUMENTED_LL" || { 
  echo "Error: Failed to apply BBInstrument pass"; 
  exit 1; 
}

echo "Compiling the instrumented IR to ASM..."
# Compile the instrumented IR to assembly for inspection
$CLANG "$INSTRUMENTED_LL" -o "$ASM_FILE" -O3 -S $CFLAGS || { 
  echo "Error: Failed to compile instrumented IR to assembly"; 
  exit 1; 
}

echo "Compiling ASM to executable..."
# Compile the assembly to an executable
$CLANG "$ASM_FILE" -o "$EXECUTABLE" $CFLAGS || { 
  echo "Error: Failed to compile assembly to executable"; 
  exit 1; 
}

echo "Executable generated at $EXECUTABLE"
echo

# PART 2: ANALYSIS (from analyze_binary.sh)
echo "=== ANALYSIS PHASE ==="
echo "Extracting basic block addresses and identifiers from $EXECUTABLE..."
echo "Address,Basic Block ID" > "$OUTPUT_MAP"

# Run objdump and save the output
OBJDUMP_OUTPUT="${OUTPUT_PREFIX}_objdump.txt"
"$OBJDUMP" -d "$EXECUTABLE" > "$OBJDUMP_OUTPUT"

# Process the objdump output
while read -r line; do
  # Look for lines containing "lea" instruction and "bbid#" marker
  if [[ $line == *"lea"* && $line == *"bbid#"* ]]; then
    # Extract the address of the instruction (first field, remove colon)
    addr=$(echo "$line" | awk '{print $1}' | sed 's/://g')
    
    # Extract the basic block ID using regex
    if [[ $line =~ bbid#([^#]+)#([^>]+) ]]; then
      function_name="${BASH_REMATCH[1]}"
      block_type="${BASH_REMATCH[2]}"
      bb_id="${function_name}#${block_type}"
      echo "$addr,$bb_id" >> "$OUTPUT_MAP"
    fi
  fi
done < "$OBJDUMP_OUTPUT"

# Count the number of basic blocks found
BB_COUNT=$(($(wc -l < "$OUTPUT_MAP") - 1))

echo "Analysis complete. Results saved to $OUTPUT_MAP"
echo "Found $BB_COUNT basic blocks."

# If no basic blocks found, provide troubleshooting information
if [ $BB_COUNT -eq 0 ]; then
  echo "Warning: No basic blocks found. This could be due to:"
  echo "  - The binary was not instrumented correctly"
  echo "  - The instrumentation was optimized out during compilation"
  echo "  - The format of the basic block markers has changed"
  echo "Try running with -O0 or -O1 optimization level to preserve instrumentation."
fi

# Clean up temporary files if not keeping them
if [ $KEEP_TEMPS -eq 0 ]; then
  echo "Cleaning up temporary files..."
  rm -f "$LL_FILE" "$INSTRUMENTED_LL" "$ASM_FILE" "$OBJDUMP_OUTPUT"
else
  echo "Keeping temporary files for inspection."
fi

# Run the executable if requested
if [ $RUN_EXECUTABLE -eq 1 ]; then
  echo
  echo "=== EXECUTION PHASE ==="
  echo "Running the executable..."
  ./"$EXECUTABLE" || { 
    echo "Error: Executable crashed"; 
    exit 1; 
  }
  echo "Executable completed successfully."
fi

echo
echo "=== COMPLETE ==="
echo "Basic block mapping process completed successfully."
echo "You can find the mapping between addresses and basic blocks in: $OUTPUT_MAP" 