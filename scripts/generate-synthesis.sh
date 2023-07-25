#!/bin/bash

# activate taccl conda env
source ~/anaconda3/etc/profile.d/conda.sh
conda activate taccl

# algos: allreduce allgather broadcast reducescatter reduce 
# checkout TACCL for all supported collectives
# taccl/taccl/cli/known_collectives.py

INSTANCE=3 # We set this to 3 because < 3 gives suboptimal results

# all reduce routine
for machine in A B D
do
  for nnodes in n1 n2 n4
  do
    for gpu_per_node in gpu1 gpu2 gpu4
    do
      
      if [[ "$nnodes" == "n1" && "$gpu_per_node" == "gpu1" ]]; then
        continue
      fi

      TOPO=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/topo/topo-akmu-${machine}-${gpu_per_node}-p2p-enable-1MB.json
      SK=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/sketch/sk-akmu-${nnodes}-${gpu_per_node}.json
      XML_NAME=allreduce.${machine}.${nnodes}.${gpu_per_node}.i${INSTANCE}.xml

      echo $XML_NAME

      # all reduce routine
      ts=$(taccl solve custom Allgather --topology-file ${TOPO} --sketch-file ${SK} --directory ~/taccl/output --force \
        | grep "Wrote to" | grep -o '[0-9]\+' | tail -1)
      # echo $ts
      json=$(taccl combine custom Allgather --topology-file ${TOPO} --sketch-file ${SK} --ts ${ts} --directory ~/taccl/output --force \
        | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
      # echo $json
      xml=$(taccl ncclize ${json} --instances $INSTANCE \
        | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
      # echo $xml
      mv $xml ${XML_NAME}
      mv ${XML_NAME} /home/n1/junyeol/taccl-exp/taccl-exp-synthesis-plans/${machine}
    done
  done
done

# other symmetric routine
for other_algo in allgather reducescatter
do
  for machine in A B D
  do
    for nnodes in n1 n2 n4
    do
      for gpu_per_node in gpu1 gpu2 gpu4
      do
        
        if [[ "$nnodes" == "n1" && "$gpu_per_node" == "gpu1" ]]; then
          continue
        fi

        TOPO=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/topo/topo-akmu-${machine}-${gpu_per_node}-p2p-enable-1MB.json
        SK=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/sketch/sk-akmu-${nnodes}-${gpu_per_node}.json
        XML_NAME=${other_algo}.${machine}.${nnodes}.${gpu_per_node}.i${INSTANCE}.xml

        echo $XML_NAME

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

        json=$(taccl solve custom ${CamelCaseAlgo} --topology-file ${TOPO} --sketch-file ${SK} --directory ~/taccl/output --force \
          | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
        xml=$(taccl ncclize ${json} --instances $INSTANCE \
          | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
        mv $xml ${XML_NAME}
        mv ${XML_NAME} /home/n1/junyeol/taccl-exp/taccl-exp-synthesis-plans/${machine}
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
    for nnodes in n1 n2 n4
    do
      for gpu_per_node in gpu1 gpu2 gpu4
      do
        
        if [[ "$nnodes" == "n1" && "$gpu_per_node" == "gpu1" ]]; then
          continue
        fi

        TOPO=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/topo/topo-akmu-${machine}-${gpu_per_node}-p2p-enable-1MB.json
        SK=/home/n1/junyeol/taccl-exp/taccl/taccl/examples/sketch/sk-akmu-${nnodes}-${gpu_per_node}-nonsymmetric.json
        XML_NAME=${other_algo}.${machine}.${nnodes}.${gpu_per_node}.i${INSTANCE}.xml

        echo $XML_NAME

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

        json=$(taccl solve custom ${CamelCaseAlgo} --topology-file ${TOPO} --sketch-file ${SK} --directory ~/taccl/output --force \
          | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
        xml=$(taccl ncclize ${json} --instances $INSTANCE \
          | grep "Wrote to " | awk -F"Wrote to " '{print (NF>1)? $NF : ""}')
        mv $xml ${XML_NAME}
        mv ${XML_NAME} /home/n1/junyeol/taccl-exp/taccl-exp-synthesis-plans/${machine}
      done
    done
  done
done