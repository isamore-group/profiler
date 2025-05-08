#!/usr/bin/env python3

# Copyright (c) 2024 The Regents of The University of Michigan
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met: redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer;
# redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution;
# neither the name of the copyright holders nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
This script demonstrates how to use the BBTracer to track basic block
execution in a program.

The BBTracer attaches to a CPU and monitors all executed instructions.
When it detects a basic block marker instruction (lea instruction that points
to a string with the format "bbid#functionname#bbname"), it records the
execution count and time for that basic block. At the end of the simulation,
it writes the results to a CSV file.

Usage:
------

scons build/X86/gem5.opt
./build/X86/gem5.opt --debug-flags=BBTracer \
    x86-bb-tracer-example.py <path_to_instrumented_binary>

Note: The binary must be instrumented with basic block markers using the
BBInstrument LLVM pass.
"""

import argparse
import os
from pathlib import Path
import sys

import m5
from m5.objects import BBTracer

from gem5.components.boards.simple_board import SimpleBoard
from gem5.components.cachehierarchies.classic.no_cache import NoCache
from gem5.components.memory.single_channel import SingleChannelDDR4_2400
from gem5.components.processors.cpu_types import CPUTypes
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.isas import ISA
from gem5.resources.resource import CustomResource
from gem5.simulate.exit_event import ExitEvent
from gem5.simulate.simulator import Simulator

parser = argparse.ArgumentParser(
    description="Run a binary with BBTracer to track basic block execution."
)
parser.add_argument(
    "binary", 
    type=str, 
    help="Path to the instrumented binary to run"
)
parser.add_argument(
    "--temp-path",
    type=str,
    default="temp",
    help="Path to store temporary files"
)
parser.add_argument(
    "--output", 
    type=str, 
    default="__bb_tracer.csv",
    help="Output file for the basic block profile"
)
parser.add_argument(
    "--args", 
    type=str, 
    default="",
    help="Arguments to pass to the binary"
)
parser.add_argument(
    "--opcount-file",
    type=str,
    default="__bb_opcounts.csv",
    help="Input file for basic block operation counts"
)
parser.add_argument(
    "--debug",
    action="store_true",
    help="Enable debug mode"
)

args = parser.parse_args()

print("args.binary: ", args.binary)

from m5 import options
from _m5.core import setOutputDir

new_outdir = Path(args.temp_path)
new_outdir.mkdir(parents=True, exist_ok=True)

if not new_outdir.exists():
    raise Exception(f"Directory '{new_outdir}' does not exist")

if not new_outdir.is_dir():
    raise Exception(f"'{new_outdir}' is not a directory")

options.outdir = str(new_outdir)
setOutputDir(options.outdir)


# Check if the binary exists
if not os.path.exists(args.binary):
    print(f"Error: Binary file '{args.binary}' not found.")
    sys.exit(1)

# Use a simple cache hierarchy (no cache for simplicity)
cache_hierarchy = NoCache()

# Set up the memory system
memory = SingleChannelDDR4_2400("1GB")

# Set up the processor with a single core
processor = SimpleProcessor(
    cpu_type=CPUTypes.TIMING, 
    num_cores=1, 
    isa=ISA.X86
)

# Create a BBTracer for the core
bb_tracer = BBTracer(
    output_file=args.output,
    opcount_file=args.opcount_file
)

# print(processor.get_cores())
# exit(0)

# Set the tracer for the CPU
processor.get_cores()[0].core.tracer = bb_tracer

# Set up the board
board = SimpleBoard(
    clk_freq="1GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy,
)

# Set up the binary workload
binary_args = []
if args.args:
    binary_args = args.args.split()

# Create a CustomResource object for the binary
binary_resource = CustomResource(
    local_path=os.path.abspath(args.binary)
)

# Set the binary workload
board.set_se_binary_workload(
    binary=binary_resource,
    arguments=binary_args,
)

# Enable the BBTracer debug flag
if args.debug:
    m5.debug.flags["BBTracer"].enable()

# Print simulation information
print(f"Starting simulation with BBTracer...")
print(f"Binary: {args.binary}")
print(f"Output file: {args.output}")
print(f"Output directory: {args.temp_path}")
if args.args:
    print(f"Arguments: {args.args}")

# Create and run the simulator
simulator = Simulator(
    board=board,
    on_exit_event={
        ExitEvent.EXIT: lambda: (print("Program completed normally."), True)
    },
    
)

# simulator.override_outdir(Path(args.temp_path))

# Run the simulation
simulator.run()

print(f"Simulation completed. BBTracer results written to {args.output}") 