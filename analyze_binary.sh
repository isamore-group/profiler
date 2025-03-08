#!/bin/bash

# This script analyzes a binary to find basic block markers and their addresses

if [ $# -lt 1 ]; then
    echo "Usage: $0 <executable>"
    exit 1
fi

EXECUTABLE=$1
OBJDUMP="objdump"

# Check if the executable exists
if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Executable '$EXECUTABLE' not found."
    exit 1
fi

# Find all global strings with the bb_id_ prefix
echo "Finding basic block identifiers in the binary..."
$OBJDUMP -s -j .rodata "$EXECUTABLE" | grep -A 1 "bb_id_" > bb_ids.txt

# Find all marker instructions (lea instructions with bb_marker label)
echo "Finding marker instructions in the binary..."
$OBJDUMP -d "$EXECUTABLE" | grep -B 1 -A 1 "bb_marker" > bb_markers.txt

# Extract addresses and identifiers
echo "Extracting addresses and identifiers..."
echo "Address,Basic Block ID" > bb_mapping.csv

# Process the marker instructions
while read -r line; do
    if [[ $line == *"lea"* && $line == *"bb_id_"* ]]; then
        # Extract the address of the instruction
        addr=$(echo "$line" | awk '{print $1}' | sed 's/://g')
        
        # Extract the reference to the global string
        ref=$(echo "$line" | grep -o "bb_id_[^ ,]*")
        
        if [ -n "$ref" ]; then
            # Find the actual string content in the rodata section
            bb_id=$(grep -A 1 "$ref" bb_ids.txt | grep -v "$ref" | tr -d ' ' | xxd -r -p | tr -d '\0')
            echo "$addr,$bb_id" >> bb_mapping.csv
        fi
    fi
done < bb_markers.txt

echo "Analysis complete. Results saved to bb_mapping.csv"
echo "Found $(($(wc -l < bb_mapping.csv) - 1)) basic blocks." 