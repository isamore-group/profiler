#!/bin/bash

# run_novia.sh - Run NOVIA fusion analysis with BBInstrument and profiler results

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
NOVIA_DIR="$(dirname "$0")/NOVIA"
# Use the full path to opt from the LLVM build
OPT_CMD="${HOME}/repos/jlm/build-llvm-mlir/bin/opt"
OPTIMIZATION="-O2"
VERBOSE=0

# Usage function
usage() {
    echo "Usage: $0 [options] <input.bc>"
    echo "Options:"
    echo "  -b <file>    BBInstrument operation count CSV file"
    echo "  -p <file>    Profiler execution results CSV file"
    echo "  -l <file>    List of basic blocks to merge"
    echo "  -o <file>    Output bitcode file (default: input_fused.bc)"
    echo "  -O <level>   Optimization level (default: -O2)"
    echo "  -g <dir>     Generate visualization graphs in directory"
    echo "  -v           Verbose output"
    echo "  -h           Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -b bb_counts.csv -p profiler_results.csv -l bb_list.txt input.bc"
    exit 1
}

# Parse command line arguments
BB_INSTRUMENT_FILE=""
PROFILER_RESULTS=""
BB_LIST=""
OUTPUT_FILE=""
GRAPH_DIR=""

while getopts "b:p:l:o:O:g:vh" opt; do
    case $opt in
        b) BB_INSTRUMENT_FILE="$OPTARG" ;;
        p) PROFILER_RESULTS="$OPTARG" ;;
        l) BB_LIST="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        O) OPTIMIZATION="$OPTARG" ;;
        g) GRAPH_DIR="$OPTARG" ;;
        v) VERBOSE=1 ;;
        h) usage ;;
        *) usage ;;
    esac
done

shift $((OPTIND-1))

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No input bitcode file specified${NC}"
    usage
fi

INPUT_BC="$1"

# Validate input file
if [ ! -f "$INPUT_BC" ]; then
    echo -e "${RED}Error: Input file '$INPUT_BC' not found${NC}"
    exit 1
fi

# Set default output file if not specified
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${INPUT_BC%.bc}_fused.bc"
fi

# Source NOVIA environment
if [ -f "$NOVIA_DIR/env.sh" ]; then
    source "$NOVIA_DIR/env.sh"
else
    echo -e "${YELLOW}Warning: NOVIA env.sh not found, using system environment${NC}"
fi

# Check if fusion library exists
FUSION_LIB="$NOVIA_DIR/fusion/build/lib/libfusionlib.so"
if [ ! -f "$FUSION_LIB" ]; then
    echo -e "${RED}Error: Fusion library not found at $FUSION_LIB${NC}"
    echo "Please build NOVIA first:"
    echo "  cd $NOVIA_DIR/fusion && mkdir -p build && cd build && cmake .. && make"
    exit 1
fi

echo -e "${GREEN}Running NOVIA fusion analysis...${NC}"

# Build opt command - use legacy pass manager for NOVIA passes
OPT_ARGS="-bugpoint-enable-legacy-pm -load $FUSION_LIB"

# Step 1: Skip renaming (BBInstrument already provides unique names)
echo "Step 1: Using BBInstrument's basic block naming..."
# We no longer rename BBs since BBInstrument format (function#bbname) is already unique
cp $INPUT_BC ${INPUT_BC%.bc}_renamed.bc

# Step 2: List all basic blocks (optional)
if [ $VERBOSE -eq 1 ]; then
    echo "Step 2: Listing basic blocks..."
    $OPT_CMD $OPT_ARGS -listBBs ${INPUT_BC%.bc}_renamed.bc -disable-output
fi

# Step 3: Run fusion pass
echo "Step 3: Running fusion analysis..."
MERGE_ARGS=""

# Add BBInstrument and profiler files if provided
if [ -n "$BB_INSTRUMENT_FILE" ]; then
    if [ ! -f "$BB_INSTRUMENT_FILE" ]; then
        echo -e "${RED}Error: BBInstrument file '$BB_INSTRUMENT_FILE' not found${NC}"
        exit 1
    fi
    MERGE_ARGS="$MERGE_ARGS -bb-instrument=$BB_INSTRUMENT_FILE"
fi

if [ -n "$PROFILER_RESULTS" ]; then
    if [ ! -f "$PROFILER_RESULTS" ]; then
        echo -e "${RED}Error: Profiler results file '$PROFILER_RESULTS' not found${NC}"
        exit 1
    fi
    MERGE_ARGS="$MERGE_ARGS -profiler-results=$PROFILER_RESULTS"
fi

# Add BB list if provided
if [ -n "$BB_LIST" ]; then
    if [ ! -f "$BB_LIST" ]; then
        echo -e "${RED}Error: BB list file '$BB_LIST' not found${NC}"
        exit 1
    fi
    MERGE_ARGS="$MERGE_ARGS -bbs=$BB_LIST"
else
    echo -e "${YELLOW}Warning: No BB list provided, will analyze all basic blocks${NC}"
fi

# Add visualization options
if [ -n "$GRAPH_DIR" ]; then
    MERGE_ARGS="$MERGE_ARGS -graph_dir=$GRAPH_DIR -visualLevel=3"
    mkdir -p "$GRAPH_DIR"
fi

# Run the merge pass
if [ $VERBOSE -eq 1 ]; then
    echo "Command: $OPT_CMD $OPT_ARGS -mergeBBList $MERGE_ARGS ${INPUT_BC%.bc}_renamed.bc -o $OUTPUT_FILE"
fi
# Ensure data directory exists
mkdir -p data
$OPT_CMD $OPT_ARGS -mergeBBList $MERGE_ARGS ${INPUT_BC%.bc}_renamed.bc -o $OUTPUT_FILE

# Step 4: Apply optimizations
echo "Step 4: Applying optimizations..."
if [ $VERBOSE -eq 1 ]; then
    echo "Command: $OPT_CMD $OPTIMIZATION $OUTPUT_FILE -o ${OUTPUT_FILE%.bc}_opt.bc"
fi
$OPT_CMD $OPTIMIZATION $OUTPUT_FILE -o ${OUTPUT_FILE%.bc}_opt.bc

echo -e "${GREEN}NOVIA fusion analysis complete!${NC}"
echo "Output files:"
echo "  - Fused bitcode: $OUTPUT_FILE"
echo "  - Optimized bitcode: ${OUTPUT_FILE%.bc}_opt.bc"

# Check for output CSV files
if [ -f "orig.csv" ]; then
    echo "  - Original BB metrics: orig.csv"
fi
if [ -f "fused.csv" ]; then
    echo "  - Fused BB metrics: fused.csv"
fi

# Clean up intermediate files
if [ $VERBOSE -eq 0 ]; then
    rm -f ${INPUT_BC%.bc}_renamed.bc
fi