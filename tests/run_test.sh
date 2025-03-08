#!/bin/bash

# Set paths
LLVM_PATH="$HOME/repos/jlm/build-llvm-mlir"
CLANG="$LLVM_PATH/bin/clang++"
OPT="$LLVM_PATH/bin/opt"
PASS_PATH="../build/lib/libaddress_mapper.so"

# Compile the test to LLVM IR
echo "Compiling test.cpp to LLVM IR..."
$CLANG -S -emit-llvm test.cpp -o test.ll || { echo "Error: Failed to compile test.cpp to LLVM IR"; exit 1; }

echo "Applying AddressMapper pass..."
# Apply the AddressMapper pass
$OPT -load-pass-plugin=$PASS_PATH -passes=address-mapper test.ll -o test_instrumented.ll || { echo "Error: Failed to apply AddressMapper pass"; exit 1; }

echo "Compiling the instrumented IR to ASM..."
# Compile the instrumented IR to assembly for inspection
$CLANG test_instrumented.ll -o test_executable.s -O3 -S || { echo "Error: Failed to compile instrumented IR to assembly"; exit 1; }

echo "Assembly generated at test_executable.s"
echo "You can inspect the lea instructions with:"
echo "grep -A 1 bb_marker test_executable.s"

echo "Compiling ASM to executable..."
# Compile the assembly to an executable
$CLANG test_executable.s -o test_executable || { echo "Error: Failed to compile assembly to executable"; exit 1; }

echo "Running the executable..."
# Run the executable
./test_executable || { echo "Error: Executable crashed"; exit 1; }

echo "Executable completed successfully."
echo "To analyze the binary and find basic block markers, you can use:"
echo "objdump -d test_executable | grep -A 1 bb_marker" 