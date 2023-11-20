#!/bin/bash

# activate taccl conda env
source /home/n1/junyeol/anaconda3/etc/profile.d/conda.sh
conda activate taccl

# Modify gurobi license path
export GRB_LICENSE_FILE=/home/n1/junyeol/gurobi.lic

# algos: allreduce allgather broadcast reducescatter reduce 
# checkout TACCL for all supported collectives
# taccl/taccl/cli/known_collectives.py

INSTANCE=3 # We set this to 3 because < 3 gives suboptimal results
CHUNKSIZE=1MB

function cleanup {
  rm *.pkl *.lp *.npy
}

# mkdir
for machine in A B D 
do
  for p2p in 0 1
  do
    for gdrlevel in SYS LOC
    do
      for gdrread in 0 1
      do
        mkdir -p /home/n1/junyeol/taccl-exp/taccl-exp-synthesis-plans/${machine}.${p2p}.${gdrlevel}.${gdrread}
      done
    done
  done
done

# all reduce routine
for machine in A B D
do
  for nnodes in 1 2 3 4 5 6 7 8
  do
    for gpu_per_node in 1 2 4
    do
      
      if [[ $nnodes -eq 1 && $gpu_per_node -eq 1 ]]; then
        continue
      fi
      
      for p2p in 0 1
      do
        for gdrlevel in SYS LOC
        do
          for gdrread in 0 1
          do
            TOPO=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/topo/akmu-${machine}-GPU${gpu_per_node}-P2P-${p2p}-GDRLEVEL-${gdrlevel}-GDRREAD-${gdrread}-${CHUNKSIZE}.json
            SK=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/sketch/sk-akmu-n${nnodes}-gpu${gpu_per_node}.json
            XML_NAME=allreduce.${machine}.${nnodes}.${gpu_per_node}.i${INSTANCE}.xml
            SAVE_DIR=/home/n1/junyeol/taccl-exp/taccl-exp-synthesis-plans/${machine}.${p2p}.${gdrlevel}.${gdrread}

            # all reduce routine
            ts=$(taccl solve custom Allgather --topology-file ${TOPO} --sketch-file ${SK} --directory /home/n1/junyeol/taccl-exp/taccl/output --force \
              | grep "Wrote to" | grep -o '[0-9]\+' | tail -1)
            # echo $ts
            json=$(taccl combine custom Allgather --topology-file ${TOPO} --sketch-file ${SK} --ts ${ts} --directory /home/n1/junyeol/taccl-exp/taccl/output --force \
              | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
            # echo $json
            xml=$(taccl ncclize ${json} --instances $INSTANCE \
              | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')

            mv $xml ${XML_NAME}
            mv ${XML_NAME} ${SAVE_DIR}

            cleanup

            echo ${SAVE_DIR} ${XML_NAME}
          done
        done
      done
    done
  done
done

# other symmetric routine
for other_algo in allgather reducescatter
do
  for machine in A B D
  do
    for nnodes in 1 2 3 4 5 6 7 8
    do
      for gpu_per_node in 1 2 4
      do
        
        if [[ "$nnodes" == 1 && "$gpu_per_node" == 1 ]]; then
          continue
        fi

        for p2p in 0 1
        do
          for gdrlevel in SYS LOC
          do
            for gdrread in 0 1
            do
              TOPO=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/topo/akmu-${machine}-GPU${gpu_per_node}-P2P-${p2p}-GDRLEVEL-${gdrlevel}-GDRREAD-${gdrread}-${CHUNKSIZE}.json
              SK=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/sketch/sk-akmu-n${nnodes}-gpu${gpu_per_node}.json
              XML_NAME=${other_algo}.${machine}.${nnodes}.${gpu_per_node}.i${INSTANCE}.xml
              SAVE_DIR=/home/n1/junyeol/taccl-exp/taccl-exp-synthesis-plans/${machine}.${p2p}.${gdrlevel}.${gdrread}

              CamelCaseAlgo=""
              if [ "$other_algo" == "allgather" ]; then
                CamelCaseAlgo="Allgather"
              elif [ "$other_algo" == "broadcast" ]; then
                CamelCaseAlgo="Broadcast"
              elif [ "$other_algo" == "reducescatter" ]; then
                CamelCaseAlgo="ReduceScatter"
              elif [ "$other_algo" == "reduce" ]; then
                CamelCaseAlgo="Reduce"
              else
                echo "Unknown algo"
                exit 1
              fi

              json=$(taccl solve custom ${CamelCaseAlgo} --topology-file ${TOPO} --sketch-file ${SK} --directory /home/n1/junyeol/taccl-exp/taccl/output --force \
                | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
              xml=$(taccl ncclize ${json} --instances $INSTANCE \
                | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
              mv $xml ${XML_NAME}
              mv ${XML_NAME} ${SAVE_DIR}

              cleanup

              echo ${SAVE_DIR} ${XML_NAME}
            done
          done
        done
      done
    done
  done
done

# other nonsymmetric routine
# Bug: There is currently a bug in XML output of reduce. Inside the parenthesis of the first row,
#      coll="reduce" and inplace="1" is missing. This is a bug in TACCL. For now, you should manually
#      add these two attributes to the first row of the XML file.
for other_algo in broadcast reduce
do
  for machine in A B D
  do
    for nnodes in 1 2 3 4 5 6 7 8
    do
      for gpu_per_node in 1 2 4
      do
        
        if [[ $nnodes -eq 1 && $gpu_per_node -eq 1 ]]; then
          continue
        fi

        for p2p in 0 1
        do
          for gdrlevel in SYS LOC
          do
            for gdrread in 0 1
            do
              TOPO=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/topo/akmu-${machine}-GPU${gpu_per_node}-P2P-${p2p}-GDRLEVEL-${gdrlevel}-GDRREAD-${gdrread}-${CHUNKSIZE}.json
              SK=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/sketch/sk-akmu-n${nnodes}-gpu${gpu_per_node}-nonsymmetric.json
              XML_NAME=${other_algo}.${machine}.${nnodes}.${gpu_per_node}.i${INSTANCE}.xml
              SAVE_DIR=/home/n1/junyeol/taccl-exp/taccl-exp-synthesis-plans/${machine}.${p2p}.${gdrlevel}.${gdrread}

              CamelCaseAlgo=""
              if [ "$other_algo" == "allgather" ]; then
                CamelCaseAlgo="Allgather"
              elif [ "$other_algo" == "broadcast" ]; then
                CamelCaseAlgo="Broadcast"
              elif [ "$other_algo" == "reducescatter" ]; then
                CamelCaseAlgo="ReduceScatter"
              elif [ "$other_algo" == "reduce" ]; then
                CamelCaseAlgo="Reduce"
              else
                echo "Unknown algo"
                exit 1
              fi

              json=$(taccl solve custom ${CamelCaseAlgo} --topology-file ${TOPO} --sketch-file ${SK} --directory /home/n1/junyeol/taccl-exp/taccl/output --force \
                | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
              xml=$(taccl ncclize ${json} --instances $INSTANCE \
                | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
              mv $xml ${XML_NAME}
              mv ${XML_NAME} ${SAVE_DIR}

              cleanup

              echo ${SAVE_DIR} ${XML_NAME}
            done
          done
        done
      done
    done
  done
done