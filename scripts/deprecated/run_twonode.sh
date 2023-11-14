#!/bin/bash

XML_ROOT="/home/n1/junyeol/taccl/output"

CHUNKSIZE_1MB_INSTANCE_1="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i1_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_2="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i2_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_3="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i3_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_4="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i4_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_5="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i5_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_6="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i6_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_7="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i7_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_8="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i8_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_9="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i9_scRemote1_IBContig.sccl.xml"
CHUNKSIZE_1MB_INSTANCE_10="Allreduce.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps4.chunks4-gurobisol-1690175880-allreduce-1690175934_i10_scRemote1_IBContig.sccl.xml"

TMP="ReduceScatter.n4-Custom-AKMU_A_GPU2_P2P_ENABLE_1MB-.n2-steps1-tacclsol-improve-1690259978_i3_scRemote1_IBContig.sccl.xml"
# XML="${XML_ROOT}/${CHUNKSIZE_1MB_INSTANCE_10}"
XML="${XML_ROOT}/${TMP}"
echo $XML

source /home/n1/junyeol/HPCX-Thunder/scripts/start-hpcx.sh
mpirun -H a0:2,a1:2 -x LD_LIBRARY_PATH=/home/n1/junyeol/msccl/build/lib/:$LD_LIBRARY_PATH \
 -x NCCL_DEBUG=INFO \
 -x NCCL_DEBUG_SUBSYS=INIT,ENV \
 -x MSCCL_XML_FILES=$XML \
 -x NCCL_ALGO=MSCCL,RING,TREE \
 /home/n1/junyeol/msccl/nccl-tests/build/reduce_scatter_perf -b 128 -e 16MB -f 2 -g 1 -c 1 -n 10 -w 10 -G 10 -z 0\