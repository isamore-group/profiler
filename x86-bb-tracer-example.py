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
from typing import Optional


from gem5.utils.override import overrides
import m5
from m5.objects import *

from gem5.components.boards.simple_board import SimpleBoard
from gem5.components.boards.abstract_board import AbstractBoard
from gem5.components.cachehierarchies.classic.no_cache import NoCache
from gem5.components.cachehierarchies.classic.private_l1_cache_hierarchy import PrivateL1CacheHierarchy
from gem5.components.cachehierarchies.classic.private_l1_private_l2_cache_hierarchy import PrivateL1PrivateL2CacheHierarchy
from gem5.components.cachehierarchies.classic.abstract_classic_cache_hierarchy import AbstractClassicCacheHierarchy
from gem5.components.cachehierarchies.abstract_cache_hierarchy import AbstractCacheHierarchy
from gem5.components.memory.single_channel import SingleChannelDDR4_2400
from gem5.components.processors.cpu_types import CPUTypes   
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.components.processors.base_cpu_processor import BaseCPUProcessor
from gem5.components.processors.base_cpu_core import BaseCPUCore
from gem5.isas import ISA
from gem5.resources.resource import CustomResource
from gem5.simulate.exit_event import ExitEvent
from gem5.simulate.simulator import Simulator


# Simple ALU Instructions have a latency of 1
class O3_X86_v7a_Simple_Int(FUDesc):
    opList = [OpDesc(opClass="IntAlu", opLat=1)]
    count = 2


# Complex ALU instructions have a variable latencies
class O3_X86_v7a_Complex_Int(FUDesc):
    opList = [
        OpDesc(opClass="IntMult", opLat=3, pipelined=True),
        OpDesc(opClass="IntDiv", opLat=12, pipelined=False),
        OpDesc(opClass="IprAccess", opLat=3, pipelined=True),
    ]
    count = 1


# Floating point and SIMD instructions
class O3_X86_v7a_FP(FUDesc):
    opList = [
        OpDesc(opClass="SimdAdd", opLat=4),
        OpDesc(opClass="SimdAddAcc", opLat=4),
        OpDesc(opClass="SimdAlu", opLat=4),
        OpDesc(opClass="SimdCmp", opLat=4),
        OpDesc(opClass="SimdCvt", opLat=3),
        OpDesc(opClass="SimdMisc", opLat=3),
        OpDesc(opClass="SimdMult", opLat=5),
        OpDesc(opClass="SimdMultAcc", opLat=5),
        OpDesc(opClass="SimdMatMultAcc", opLat=5),
        OpDesc(opClass="SimdShift", opLat=3),
        OpDesc(opClass="SimdShiftAcc", opLat=3),
        OpDesc(opClass="SimdSqrt", opLat=9),
        OpDesc(opClass="SimdFloatAdd", opLat=5),
        OpDesc(opClass="SimdFloatAlu", opLat=5),
        OpDesc(opClass="SimdFloatCmp", opLat=3),
        OpDesc(opClass="SimdFloatCvt", opLat=3),
        OpDesc(opClass="SimdFloatDiv", opLat=3),
        OpDesc(opClass="SimdFloatMisc", opLat=3),
        OpDesc(opClass="SimdFloatMult", opLat=3),
        OpDesc(opClass="SimdFloatMultAcc", opLat=5),
        OpDesc(opClass="SimdFloatMatMultAcc", opLat=5),
        OpDesc(opClass="SimdFloatSqrt", opLat=9),
        OpDesc(opClass="FloatAdd", opLat=5),
        OpDesc(opClass="FloatCmp", opLat=5),
        OpDesc(opClass="FloatCvt", opLat=5),
        OpDesc(opClass="FloatDiv", opLat=9, pipelined=False),
        OpDesc(opClass="FloatSqrt", opLat=33, pipelined=False),
        OpDesc(opClass="FloatMult", opLat=4),
        OpDesc(opClass="FloatMultAcc", opLat=5),
        OpDesc(opClass="FloatMisc", opLat=3),
    ]
    count = 2


# Load/Store Units
class O3_X86_v7a_Load(FUDesc):
    opList = [
        OpDesc(opClass="MemRead", opLat=2),
        OpDesc(opClass="FloatMemRead", opLat=2),
    ]
    count = 1


class O3_X86_v7a_Store(FUDesc):
    opList = [
        OpDesc(opClass="MemWrite", opLat=2),
        OpDesc(opClass="FloatMemWrite", opLat=2),
    ]
    count = 1


# Functional Units for this CPU
class O3_X86_v7a_FUP(FUPool):
    FUList = [
        O3_X86_v7a_Simple_Int(),
        O3_X86_v7a_Complex_Int(),
        O3_X86_v7a_Load(),
        O3_X86_v7a_Store(),
        O3_X86_v7a_FP(),
    ]


class O3_X86_v7a_BTB(SimpleBTB):
    numEntries = 2048
    tagBits = 18
    associativity = 1
    instShiftAmt = 2
    btbReplPolicy = LRURP()
    btbIndexingPolicy = BTBSetAssociative(
        num_entries=Parent.numEntries,
        set_shift=Parent.instShiftAmt,
        assoc=Parent.associativity,
        tag_bits=Parent.tagBits,
    )


# Bi-Mode Branch Predictor
class O3_X86_v7a_BP(BiModeBP):
    btb = O3_X86_v7a_BTB()
    ras = ReturnAddrStack(numEntries=16)
    globalPredictorSize = 8192
    globalCtrBits = 2
    choicePredictorSize = 8192
    choiceCtrBits = 2
    instShiftAmt = 2


class O3_X86_v7a_3(X86O3CPU):
    LQEntries = 16
    SQEntries = 16
    LSQDepCheckShift = 0
    LFSTSize = 1024
    SSITSize = 1024
    decodeToFetchDelay = 1
    renameToFetchDelay = 1
    iewToFetchDelay = 1
    commitToFetchDelay = 1
    renameToDecodeDelay = 1
    iewToDecodeDelay = 1
    commitToDecodeDelay = 1
    iewToRenameDelay = 1
    commitToRenameDelay = 1
    commitToIEWDelay = 1
    fetchWidth = 3
    fetchBufferSize = 16
    fetchToDecodeDelay = 3
    decodeWidth = 3
    decodeToRenameDelay = 2
    renameWidth = 3
    renameToIEWDelay = 1
    issueToExecuteDelay = 1
    dispatchWidth = 6
    issueWidth = 8
    wbWidth = 8
    fuPool = O3_X86_v7a_FUP()
    iewToCommitDelay = 1
    renameToROBDelay = 1
    commitWidth = 8
    squashWidth = 8
    trapLatency = 13
    backComSize = 5
    forwardComSize = 5
    numPhysIntRegs = 128
    numPhysFloatRegs = 192
    numPhysVecRegs = 48
    numIQEntries = 32
    numROBEntries = 40

    switched_out = False
    branchPred = O3_X86_v7a_BP()

# Instruction Cache
class O3_X86_v7a_ICache(Cache):
    tag_latency = 1
    data_latency = 1
    response_latency = 1
    mshrs = 2
    tgts_per_mshr = 8
    size = "32KiB"
    assoc = 2
    is_read_only = True
    # Writeback clean lines as well
    writeback_clean = True


# Data Cache
class O3_X86_v7a_DCache(Cache):
    tag_latency = 2
    data_latency = 2
    response_latency = 2
    mshrs = 6
    tgts_per_mshr = 8
    size = "32KiB"
    assoc = 2
    write_buffers = 16
    # Consider the L2 a victim cache also for clean lines
    writeback_clean = True


# L2 Cache
class O3_X86_v7aL2(Cache):
    tag_latency = 12
    data_latency = 12
    response_latency = 12
    mshrs = 16
    tgts_per_mshr = 8
    size = "1MiB"
    assoc = 16
    write_buffers = 8
    clusivity = "mostly_excl"
    # Simple stride prefetcher
    prefetcher = StridePrefetcher(degree=8, latency=1, prefetch_on_access=True)
    tags = BaseSetAssoc()
    replacement_policy = RandomRP()


class O3_X86_v7a_CacheHierarchy(
    AbstractClassicCacheHierarchy
):
    """
    A cache setup where each core has a private L1 Data and Instruction Cache,
    and a private L2 cache.
    """

    def _get_default_membus(self) -> SystemXBar:
        """
        A method used to obtain the default memory bus of 64 bit in width for
        the PrivateL1PrivateL2 CacheHierarchy.

        :returns: The default memory bus for the PrivateL1PrivateL2
                  CacheHierarchy.

        """
        membus = SystemXBar(width=64)
        membus.badaddr_responder = BadAddr()
        membus.default = membus.badaddr_responder.pio
        return membus

    def __init__(
        self,
        membus: Optional[BaseXBar] = None,
    ) -> None:
        """
        :param l1d_size: The size of the L1 Data Cache (e.g., "32KiB").

        :param  l1i_size: The size of the L1 Instruction Cache (e.g., "32KiB").

        :param l2_size: The size of the L2 Cache (e.g., "256KiB").

        :param membus: The memory bus. This parameter is optional parameter and
                       will default to a 64 bit width SystemXBar is not
                       specified.
        """

        AbstractClassicCacheHierarchy.__init__(self=self)

        self.membus = membus if membus else self._get_default_membus()

    @overrides(AbstractClassicCacheHierarchy)
    def get_mem_side_port(self) -> Port:
        return self.membus.mem_side_ports

    @overrides(AbstractClassicCacheHierarchy)
    def get_cpu_side_port(self) -> Port:
        return self.membus.cpu_side_ports

    @overrides(AbstractCacheHierarchy)
    def incorporate_cache(self, board: AbstractBoard) -> None:
        # Set up the system port for functional access from the simulator.
        board.connect_system_port(self.membus.cpu_side_ports)

        for _, port in board.get_mem_ports():
            self.membus.mem_side_ports = port

        self.l2buses = [
            L2XBar() for i in range(board.get_processor().get_num_cores())
        ]

        for i, cpu in enumerate(board.get_processor().get_cores()):
            l2_node = self.add_root_child(
                f"l2-cache-{i}", O3_X86_v7aL2()
            )
            l1i_node = l2_node.add_child(
                f"l1i-cache-{i}", O3_X86_v7a_ICache()
            )
            l1d_node = l2_node.add_child(
                f"l1d-cache-{i}", O3_X86_v7a_DCache()
            )

            self.l2buses[i].mem_side_ports = l2_node.cache.cpu_side
            self.membus.cpu_side_ports = l2_node.cache.mem_side

            l1i_node.cache.mem_side = self.l2buses[i].cpu_side_ports
            l1d_node.cache.mem_side = self.l2buses[i].cpu_side_ports

            cpu.connect_icache(l1i_node.cache.cpu_side)
            cpu.connect_dcache(l1d_node.cache.cpu_side)

            self._connect_table_walker(i, cpu)

            if board.get_processor().get_isa() == ISA.X86:
                int_req_port = self.membus.mem_side_ports
                int_resp_port = self.membus.cpu_side_ports
                cpu.connect_interrupt(int_req_port, int_resp_port)
            else:
                cpu.connect_interrupt()

        if board.has_coherent_io():
            self._setup_io_cache(board)

    def _connect_table_walker(self, cpu_id: int, cpu: BaseCPU) -> None:
        cpu.connect_walker_ports(
            self.membus.cpu_side_ports, self.membus.cpu_side_ports
        )

    def _setup_io_cache(self, board: AbstractBoard) -> None:
        """Create a cache for coherent I/O connections"""
        self.iocache = Cache(
            assoc=8,
            tag_latency=50,
            data_latency=50,
            response_latency=50,
            mshrs=20,
            size="1KiB",
            tgts_per_mshr=12,
            addr_ranges=board.mem_ranges,
        )
        self.iocache.mem_side = self.membus.cpu_side_ports
        self.iocache.cpu_side = board.get_mem_side_coherent_io_port()


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

parser.add_argument(
    "--cpu-type",
    type=str,
    default="minor",
    help="CPU type to use"
)

parser.add_argument(
    "--cache-hierarchy",
    type=str,
    default="no_cache",
    help="Cache hierarchy to use"
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
if args.cache_hierarchy == "no_cache":
    cache_hierarchy = NoCache()
elif args.cache_hierarchy == "private_l1":
    cache_hierarchy = PrivateL1CacheHierarchy(l1d_size="32KiB", l1i_size="32KiB")
elif args.cache_hierarchy == "private_l1_private_l2":
    cache_hierarchy = PrivateL1PrivateL2CacheHierarchy(l1d_size="32KiB", l1i_size="32KiB", l2_size="256KiB")
elif args.cache_hierarchy == "arm_v7a":
    cache_hierarchy = O3_X86_v7a_CacheHierarchy()
else:
    raise Exception(f"Invalid cache hierarchy: {args.cache_hierarchy}")

# Set up the memory system
memory = SingleChannelDDR4_2400("1GB")


if args.cpu_type == "simple":
    # Set up the processor with a single core
    processor = SimpleProcessor(
        cpu_type=CPUTypes.TIMING, 
        num_cores=1, 
        isa=ISA.X86
    )
elif args.cpu_type == "minor":
    # Set up the processor with a single core
    processor = SimpleProcessor(
        cpu_type=CPUTypes.MINOR, 
        num_cores=1, 
        isa=ISA.X86
    )
elif args.cpu_type == "O3":
    # Set up the processor with a single core
    processor = SimpleProcessor(
        cpu_type=CPUTypes.O3, 
        num_cores=1, 
        isa=ISA.X86
    )
elif args.cpu_type == "O3_ARM_v7a":
    # Set up the processor with a single core
    processor = BaseCPUProcessor(
        cores=[BaseCPUCore(O3_X86_v7a_3(), ISA.X86)],
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