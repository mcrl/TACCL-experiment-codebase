#!/bin/bash

XML_ROOT="/home/n1/junyeol/taccl/output"

CHUNKSIZE_1MB="Allreduce.n16-Custom-AKMU_P2P_ENABLE_1MB-.n4-steps30.chunks16-gurobisol-1687414211-allreduce-1687414226_i1_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_2="Allreduce.n16-Custom-AKMU_P2P_ENABLE_1MB-.n4-steps40.chunks16-gurobisol-1687422442-allreduce-1687422480_i2_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_4=""
CHUNKSIZE_1MB_INSTANCE_8=""
CHUNKSIZE_1MB_INSTANCE_10="Allreduce.n16-Custom-AKMU_P2P_ENABLE_1MB-.n4-steps40.chunks16-gurobisol-1687422442-allreduce-1687422480_i10_scRemote1_IBContig.sccl.xml"

CHUNKSIZE_1KB=""
CHUNKSIZE_32KB=""

XML="${XML_ROOT}/${CHUNKSIZE_1MB_INSTANCE_2}"

echo $XML

source /home/n1/junyeol/HPCX-Thunder/scripts/start-hpcx.sh
mpirun -H a0:4,a1:4,a2:4,a3:4 -x LD_LIBRARY_PATH=/home/n1/junyeol/msccl/build/lib/:$LD_LIBRARY_PATH \
 -x NCCL_DEBUG=INFO \
 -x NCCL_DEBUG_SUBSYS=INIT,ENV \
 -x MSCCL_XML_FILES=$XML \
 -x NCCL_ALGO=MSCCL,RING,TREE \
 /home/n1/junyeol/msccl/nccl-tests/build/all_reduce_perf -b 128 -e 64MB -f 2 -g 1 -c 1 -n 10 -w 10 -G 10 -z 0\