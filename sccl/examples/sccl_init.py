# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import os
import msccl

def show():
    if 'MSCCL_CONFIG' in os.environ:
        print()
        print(f"MSCCL_CONFIG = {os.environ['MSCCL_CONFIG']}")
        print(f"Contents of {os.environ['MSCCL_CONFIG']}:")
        with open(os.environ['MSCCL_CONFIG']) as f:
            print(f.read())
        print()


print('=== Trigger a builtin synthesis plan ===')

"""
# TCCL: e.g., msccl.init('ndv4', 9, (msccl.Collective.alltoall, '1GB'), (msccl.Collective.alltoall, ('1GB','2GB')))
msccl.init('ndv4', 9, (msccl.Collective.alltoall, '1GB'))

show()
"""

# print('=== Register additional plans from a library ===')

# import msccl_presynth
# msccl.init('ndv2', 3,
#     (msccl.Collective.alltoall, '1GB'),
#     (msccl.Collective.allgather, (128, '1KB')))

# show()


print('=== Register custom plans ===')

from msccl.autosynth.registry import register_synthesis_plan
from msccl.autosynth.registry import register_ef_file # TCCL

# @register_synthesis_plan(msccl.Collective.alltoall, 'ndv9000', lambda m: m == 1, ('1MB', None))
# def alltoall_9000(machines):
#     return """<algo name="a2andv9000" nchunksperloop="2" nchannels="1" inplace="0" ngpus="2" proto="Simple">
#     ...
#     </algo>"""

# msccl.init('ndv9000', 1, (msccl.Collective.alltoall, '2MB'))

# TCCL

NUM_AKMU_A_MACHINES=4
AKMU_A_MACHINE_NAME="a"

## Register all reduce

### register <1MB all_reduce for akmu a nodes
path = "/home/n1/junyeol/taccl-exp/taccl/output/Allreduce.n16-Custom-AKMU_P2P_ENABLE_1MB-.n4-steps27.chunks16-gurobisol-1687418999-allreduce-1687419034_i10_scRemote1_IBContig.sccl.xml"
register_ef_file(path, "allreduce", AKMU_A_MACHINE_NAME, NUM_AKMU_A_MACHINES, ("0MB","1MB"))

## Load registered EF file plan to runtime
msccl.init(AKMU_A_MACHINE_NAME, NUM_AKMU_A_MACHINES, (msccl.Collective.allreduce, ("0MB","1MB")))

show()


print('=== Overlapping size ranges ===')

# register_synthesis_plan(msccl.Collective.alltoall, 'ndv9000', lambda m: m == 1, (0, '1KB'), protocol='LL')(alltoall_9000)
# register_synthesis_plan(msccl.Collective.alltoall, 'ndv9000', lambda m: m == 1, ('1KB', '1MB'), protocol='LL128')(alltoall_9000)

# msccl.init('ndv9000', 1, (msccl.Collective.alltoall, ('2KB', None)))

# show()


# TODO: Update the following programs to use the new syntax
# print('=== MSCCLang program ===')

# from msccl.autosynth.registry import register_msccl_program
# from msccl.topologies import line
# from msccl.language import *

# @register_msccl_program(line(2), 'allgather', 'two_gpus', machines= lambda m: m == 1)
# def trivial_allgather(prog, nodes):
#     chunk(Buffer.input, 0, 0).send(0, Buffer.output, 0).send(1)
#     chunk(Buffer.input, 1, 0).send(1, Buffer.output, 1).send(0)

# msccl.init('two_gpus', 1, (msccl.Collective.allgather, (0, None)))

# show()


# print('=== MSCCLang program example ====')

# from msccl.topologies import fully_connected
# from msccl.programs.allreduce_a100_ring import allreduce_ring

# @register_msccl_program(fully_connected(8), 'allreduce', 'ndv4', chunk_factor=8, inplace=True,
#     instances=4, protocol='LL128', threadblock_policy=ThreadblockPolicy.manual, machines=lambda x: x == 1)
# def ndv4_ring_allreduce(prog, nodes):
#     allreduce_ring(size=8, channels=8)

# msccl.init('ndv4', 1, (msccl.Collective.allreduce, (0, None)))

# show()