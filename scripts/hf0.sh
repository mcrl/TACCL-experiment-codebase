#!/bin/bash -l

# activate taccl conda env
source ~/anaconda3/etc/profile.d/conda.sh
conda activate taccl

# vars used in this script
MASTER_ADDR=a0
MASTER_PORT=23456
NUM_GPU=4

# env vars passed to pytorch script
export LD_LIBRARY_PATH=/home/n1/junyeol/taccl-exp/msccl/build/lib:$LD_LIBRARY_PATH
export CUDA_VISIBLE_DEVICES=0,1,2,3
# export CUDA_DEVICE_ORDER=PCI_BUS_ID
TRAIN_SCRIPT=/home/n1/junyeol/taccl-exp/transformers/examples/pytorch/language-modeling/run_clm.py
TMP_SCRIPT=/tmp/pyscript.py # train script with msccl.init prefix

export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,ENV
export NCCL_ALGO=MSCCL,RING,TREE
export NCCL_NET_GDR_LEVEL=SYS
export NCCL_NET_GDR_READ=1

# taccl related vars
TARGET_MACHINE="A" # A or B or D
export XML_DIR=/home/n1/junyeol/taccl-exp/taccl-exp-synthesis-plans/${TARGET_MACHINE}

# msccl prefix
MSCCL_PREFIX='import os
import msccl
from msccl.autosynth.registry import register_ef_file

for xml in os.scandir(os.environ["XML_DIR"]):
  print(f"registering {xml.name} from {xml.path}")

  if xml.name.endswith(".xml"):
    algo = xml.name.split(".")[0]
    machine = xml.name.split(".")[1]
    nnodes = int(xml.name.split(".")[2].lstrip("n"))

    # MSCCL register routine
    register_ef_file(xml.path, algo, machine, nnodes, ("1MB", None))
    msccl.init(machine, nnodes, (algo, ("1MB", None)))
    
from msccl.autosynth import print_plans
print_plans()
'

# make msccl-prefixed train script on TMP_SCRIPT
echo "$MSCCL_PREFIX" > $TMP_SCRIPT
cat $TRAIN_SCRIPT >> $TMP_SCRIPT

# run torch
torchrun \
  --nproc_per_node $NUM_GPU \
  --nnodes $OMPI_COMM_WORLD_SIZE \
  --node_rank $OMPI_COMM_WORLD_RANK \
  --master_addr $MASTER_ADDR \
  --master_port $MASTER_PORT \
  $TMP_SCRIPT \
  --model_type gpt2 \
  --tokenizer_name gpt2 \
  --config_overrides n_layer=12,n_embd=768,n_head=12,n_positions=2048 \
  --dataset_name wikitext \
  --dataset_config_name wikitext-2-raw-v1 \
  --per_device_train_batch_size 1 \
  --gradient_accumulation_steps 1 \
  --do_train \
  --max_steps 20 \
  --overwrite_output_dir \
  --output_dir ws/test-clm

# cleanup
rm $TMP_SCRIPT