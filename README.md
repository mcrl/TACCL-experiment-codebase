# TACCL Experiment Codebase

## Repository Organization
```
.                                 
├── msccl                           # MSCCL runtime
├── sccl                            # MSCCL tools
├── taccl                           # TACCL
│   ├── taccl                       #
│       ├── examples                #
│           ├── topo                #   - TACCL input topologies for akmu
│           ├── sketch              #   - TACCL input sketches for akmu
├── scripts               # Scripts for experiment 
├── taccl-exp-synthesis-plans       # Synthesized plans for akmu using TACCL
│   ├── A                           #   - Synthesized plans for target A nodes (a0-3)
│   ├── B                           #   - Synthesized plans for target B nodes (b4-7)                           
│   ├── D                           #   - Synthesized plans for target D nodes (d0-3)
├── transformers                    # HuggingFace Transformers 
```

## Prerequisited
- Anaconda
- PyTorch @456ecef
- Python 3.8
- gurobipy

## Setup
0. Create conda env with Python 3.8. Naming it `taccl` is recommended to run all given scripts without error. We expect everything to be done inside this env, using `conda activate`.
```
conda create -n taccl python=3.8 
```
1. Build MSCCL. Add NVCC_GENCODE with respect to your GPU.
```
make -j src.build CUDA_HOME=/path/to/cuda/install NVCC_GENCODE="-gencode=arch=compute_70,code=sm_70"
```
2. Build PyTorch with MSCCL
```
export CUDA_NVCC_EXECUTABLE=/path/to/nvcc
export CUDA_HOME=/path/to/cuda/install
export CUDNN_INCLUDE_DIR=/path/to/cudnn
export CUDNN_LIB_DIR=/path/to/cudnn/lib
export USE_SYSTEM_NCCL=1
export NCCL_INCLUDE_DIRS=/path/to/msccl/include
export NCCL_LIBRARIES=/path/to/msccl/lib
cd pytorch && python setup.py install
```
3. Build SCCL
```
cd sccl/ && python setup.py install
```
4. Build HuggingFace
```
cd transformers && pip install -e . && pip install datasets evaluate accelerate
```
5. Build TACCL
```
conda config --add channels http://conda.anaconda.org/gurobi
conda install -c conda-forge gurobi -y
<command to add Gurobi license>
cd taccl && pip install .
```

## Getting started
(Optional) To write custom input topology and sketch files, measuring alpha-beta of your server is required. We used following libraries:
- [cuda-samples](https://github.com/NVIDIA/cuda-samples/blob/master/Samples/5_Domain_Specific/p2pBandwidthLatencyTest/p2pBandwidthLatencyTest.cu): For intra-node alpha-beta measurement. Specifically, we used `p2pBandwidthLatencyTest`.
- [OSU Micro-benchmarks](https://mvapich.cse.ohio-state.edu/benchmarks/): For inter-node alpha beta measurement. Specifically, we used `osu_nccl_latency` and `osu_nccl_bw`.

Our custom input files are provided under [topo/](taccl/taccl/examples/topo) and [sketch/](taccl/taccl/examples/sketch). 

To generate synthesis plans using custom input files, we used [generate-synthesis.sh](scripts/generate-synthesis.sh). Synthesized plans are in XML format and stored in [taccl-exp-synthesis-plans](taccl-exp-synthesis-plans/). You can test the synthesized plans using provided `run_single/two/multinode.sh`.

To run a benchmark using the synthesized plans, we need to load them before launching the actual benchmark script. We provide a sample script in [hf0.sh](scripts/hf0.sh). Simply, we add the MSCCL prefix at the beginning of the benchmark script. Benchmark script must be a Python script for our implementation. You can test the benchmark using provided [`hf.sh`](scripts/hf.sh).