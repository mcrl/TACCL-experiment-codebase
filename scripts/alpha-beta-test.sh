#!/bin/bash

# Perform alpha-beta test for machines and save the results

MPI_OPTIONS="-mca btl ^openib -mca pml ucx"

OSU_LATENCY_RELATIVE=c/xccl/pt2pt/osu_xccl_latency
OSU_BW_RELATIVE=c/xccl/pt2pt/osu_xccl_bw

OUTDIR=/home/n1/junyeol/taccl-exp-log/alpha-beta

for machine in A B D
do

    NCCL_LIB_PATH="/home/n1/junyeol/taccl-exp/nccl-branches/nccl-$(echo $machine | tr '[:upper:]' '[:lower:]')/build/lib/"
    OSU_DIR="/home/n1/junyeol/taccl-exp/osu-branches/osu-$(echo $machine | tr '[:upper:]' '[:lower:]')"
    for NCCL_P2P_DISABLE in 0 1
    do
        for NCCL_NET_GDR_LEVEL in SYS LOC
        do
            for NCCL_NET_GDR_READ in 0 1
            do
                intra_node_host=
                inter_node_hosts=

                if [ "$machine" == "A" ]; then
                    intra_node_host="a0"
                    inter_node_hosts="a0,a1"
                elif [ "$machine" == "B" ]; then
                    intra_node_host="b2"
                    inter_node_hosts="b2,b4"
                elif [ "$machine" == "D" ]; then
                    intra_node_host="d0"
                    inter_node_hosts="d0,d2"
                else
                    echo "Unknown algo"
                    exit 1
                fi

                LD_LIBRARY_PATH=${NCCL_LIB_PATH} mpirun -H ${intra_node_host}:2 ${MPI_OPTIONS} ${OSU_DIR}/${OSU_LATENCY_RELATIVE} -m 134217728 -x 10 2>&1 | tee ${OUTDIR}/${machine}_${NCCL_P2P_DISABLE}_${NCCL_NET_GDR_LEVEL}_${NCCL_NET_GDR_READ}_intranode_latency.txt
                LD_LIBRARY_PATH=${NCCL_LIB_PATH} mpirun -H ${intra_node_host}:2 ${MPI_OPTIONS} ${OSU_DIR}/${OSU_BW_RELATIVE} -m 134217728 -x 10 2>&1 | tee ${OUTDIR}/${machine}_${NCCL_P2P_DISABLE}_${NCCL_NET_GDR_LEVEL}_${NCCL_NET_GDR_READ}_intranode_bw.txt
                LD_LIBRARY_PATH=${NCCL_LIB_PATH} mpirun -np 2 -H ${inter_node_hosts} ${MPI_OPTIONS} ${OSU_DIR}/${OSU_LATENCY_RELATIVE} -m 134217728 -x 10 2>&1 | tee ${OUTDIR}/${machine}_${NCCL_P2P_DISABLE}_${NCCL_NET_GDR_LEVEL}_${NCCL_NET_GDR_READ}_internode_latency.txt
                LD_LIBRARY_PATH=${NCCL_LIB_PATH} mpirun -np 2 -H ${inter_node_hosts} ${MPI_OPTIONS} ${OSU_DIR}/${OSU_BW_RELATIVE} -m 134217728 -x 10 2>&1 | tee ${OUTDIR}/${machine}_${NCCL_P2P_DISABLE}_${NCCL_NET_GDR_LEVEL}_${NCCL_NET_GDR_READ}_internode_bw.txt
            done
        done
    done
done