#!/bin/bash

# Enhanced analyze_binary.sh script for extracting basic block information
# Usage: ./analyze_binary.sh [options] <executable>
# Options:
#   -o, --output <file>      Output CSV file (default: bb_mapping.csv)
#   -d, --objdump <path>     Path to objdump executable
#   -h, --help               Show this help message

# Default values
OBJDUMP="${OBJDUMP:-objdump}"
OUTPUT_FILE="__bb_mapping.csv"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -d|--objdump)
      OBJDUMP="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./analyze_binary.sh [options] <executable>"
      echo "Options:"
      echo "  -o, --output <file>      Output CSV file (default: bb_mapping.csv)"
      echo "  -d, --objdump <path>     Path to objdump executable"
      echo "  -h, --help               Show this help message"
      exit 0
      ;;
    *)
      EXECUTABLE="$1"
      shift
      ;;
  esac
done

# Check if executable is provided
if [ -z "$EXECUTABLE" ]; then
  echo "Error: No executable specified"
  echo "Run './analyze_binary.sh --help' for usage information"
  exit 1
fi

# Check if the executable exists
if [ ! -f "$EXECUTABLE" ]; then
  echo "Error: Executable '$EXECUTABLE' not found."
  exit 1
fi

# Check if objdump is available
if ! command -v "$OBJDUMP" &> /dev/null; then
  echo "Error: objdump command not found. Please specify with --objdump option."
  exit 1
fi

# Extract addresses and identifiers
echo "Extracting basic block addresses and identifiers from $EXECUTABLE..."
echo "Address,Basic Block ID" > "$OUTPUT_FILE"

# Run objdump and save the output
"$OBJDUMP" -d "$EXECUTABLE" > objdump_output.txt

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
      echo "$addr,$bb_id" >> "$OUTPUT_FILE"
    fi
  fi
done < objdump_output.txt

# Clean up
rm objdump_output.txt

# Count the number of basic blocks found
BB_COUNT=$(($(wc -l < "$OUTPUT_FILE") - 1))

echo "Analysis complete. Results saved to $OUTPUT_FILE"
echo "Found $BB_COUNT basic blocks."

# If no basic blocks found, provide troubleshooting information
if [ $BB_COUNT -eq 0 ]; then
  echo "Warning: No basic blocks found. This could be due to:"
  echo "  - The binary was not instrumented with the bb_instrument pass"
  echo "  - The instrumentation was optimized out during compilation"
  echo "  - The format of the basic block markers has changed"
  echo "Try running with -O0 or -O1 optimization level to preserve instrumentation."
fi 