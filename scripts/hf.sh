#!/bin/bash

mpirun -H a0,a1,a2,a3 -mca btl ^openib -mca pml ucx \
  /home/n1/junyeol/taccl-exp/taccl-exp-script-git/hf0.sh