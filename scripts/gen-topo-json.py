import json
import os
import subprocess

LOG_DIR = "/home/n1/junyeol/taccl-exp-log/alpha-beta"
SAVE_DIR = "/home/n1/junyeol/taccl-exp/taccl/taccl/examples/topo"
CHUNKSIZE = "1MB"
CHUNKSIZE_IN_BYTES = 1048576

for machine in [ "A", "B", "D" ]:
    for num_gpu in [ 1, 2, 4 ]:
        for p2p_disable in [ 0, 1 ]:
            for nccl_net_gdr_level in [ "SYS", "LOC" ]:
                for nccl_net_gdr_read in [ 0, 1 ]:
                    dict = {}
                    dict["name"] = f"akmu-{machine}-GPU{num_gpu}-P2P-{p2p_disable}-GDRLEVEL-{nccl_net_gdr_level}-GDRREAD-{nccl_net_gdr_read}-{CHUNKSIZE}"
                    dict["gpus_per_node"] = num_gpu
                    dict["nics_per_node"] = 1

                    alpha = subprocess.check_output(
                        f"cat {LOG_DIR}/{machine}_{p2p_disable}_{nccl_net_gdr_level}_{nccl_net_gdr_read}_intranode_latency.txt"
                        f" | grep {CHUNKSIZE_IN_BYTES}",
                        shell=True,
                        text=True
                    ).strip("\n").split(" ")[-1]
                    dict["alpha"] = float(alpha)

                    bw = subprocess.check_output(
                        f"cat {LOG_DIR}/{machine}_{p2p_disable}_{nccl_net_gdr_level}_{nccl_net_gdr_read}_intranode_bw.txt"
                        f" | grep {CHUNKSIZE_IN_BYTES}",
                        shell=True,
                        text=True
                    ).strip("\n").split(" ")[-1]
                    beta = round(1e6 / float(bw), 2)
                    betas = [
                        [ 0 if i == j else beta for j in range(num_gpu)] for i in range(num_gpu)
                    ]
                    dict["betas"] = betas

                    invbws = [
                        [ betas[i][j] + float(alpha) for j in range(num_gpu)] for i in range(num_gpu)
                    ]
                    dict["invbws"] = invbws

                    links = [
                        [ 0 if i == j else 1 for j in range(num_gpu)] for i in range(num_gpu)
                    ]
                    dict["links"] = links

                    remote_alpha = subprocess.check_output(
                        f"cat {LOG_DIR}/{machine}_{p2p_disable}_{nccl_net_gdr_level}_{nccl_net_gdr_read}_internode_latency.txt"
                        f" | grep {CHUNKSIZE_IN_BYTES}",
                        shell=True,
                        text=True
                    ).strip("\n").split(" ")[-1]
                    dict["remote_alpha"] = float(remote_alpha)

                    remote_bw = subprocess.check_output(
                        f"cat {LOG_DIR}/{machine}_{p2p_disable}_{nccl_net_gdr_level}_{nccl_net_gdr_read}_internode_bw.txt"
                        f" | grep {CHUNKSIZE_IN_BYTES}",
                        shell=True,
                        text=True
                    ).strip("\n").split(" ")[-1]
                    remote_beta = round(1e6 / float(remote_bw), 2)
                    dict["remote_beta"] = remote_beta

                    remote_inbvw = float(remote_alpha) + float(remote_beta)
                    dict["remote_invbw"] = remote_inbvw
                
                    with open(os.path.join(SAVE_DIR, dict["name"] + ".json"), "w") as f:
                        json.dump(dict, f, indent=2)
