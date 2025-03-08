#!/bin/bash

# Enhanced run_test.sh script for BB instrumentation
# Usage: ./run_test.sh [options] <input_file>
# Options:
#   -c, --cflags <flags>     Additional compiler flags for clang
#   -o, --opt-flags <flags>  Additional flags for opt
#   -s, --skip-compile       Skip initial compilation (if input is already LLVM IR)
#   -h, --help               Show this help message

# Default values
LLVM_PATH="${LLVM_PATH:-$HOME/repos/jlm/build-llvm-mlir}"
CLANG="${CLANG:-$LLVM_PATH/bin/clang++}"
OPT="${OPT:-$LLVM_PATH/bin/opt}"
PASS_PATH="${PASS_PATH:-../build/lib/libbb_instrument.so}"
CFLAGS=""
OPT_FLAGS=""
SKIP_COMPILE=0
OUTPUT_PREFIX="output"

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
    -h|--help)
      echo "Usage: ./run_test.sh [options] <input_file>"
      echo "Options:"
      echo "  -c, --cflags <flags>     Additional compiler flags for clang"
      echo "  -o, --opt-flags <flags>  Additional flags for opt"
      echo "  -s, --skip-compile       Skip initial compilation (if input is already LLVM IR)"
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
  echo "Run './run_test.sh --help' for usage information"
  exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file '$INPUT_FILE' not found"
  exit 1
fi

# Set output file names based on input file name
FILENAME=$(basename -- "$INPUT_FILE")
FILENAME_NOEXT="${FILENAME%.*}"
OUTPUT_PREFIX="$FILENAME_NOEXT"
LL_FILE="${OUTPUT_PREFIX}.ll"
INSTRUMENTED_LL="${OUTPUT_PREFIX}_instrumented.ll"
ASM_FILE="${OUTPUT_PREFIX}.s"
EXECUTABLE="${OUTPUT_PREFIX}.exe"

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

echo "Assembly generated at $ASM_FILE"

echo "Compiling ASM to executable..."
# Compile the assembly to an executable
$CLANG "$ASM_FILE" -o "$EXECUTABLE" $CFLAGS || { 
  echo "Error: Failed to compile assembly to executable"; 
  exit 1; 
}

echo "Executable generated at $EXECUTABLE"

echo "To analyze the binary and find basic block markers, you can use:"
echo "../analyze_binary.sh $EXECUTABLE"

# Ask if user wants to run the executable
read -p "Do you want to run the executable? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Running the executable..."
  ./"$EXECUTABLE" || { 
    echo "Error: Executable crashed"; 
    exit 1; 
  }
  echo "Executable completed successfully."
fi 