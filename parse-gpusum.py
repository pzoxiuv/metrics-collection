import os
import json
import argparse

def get_metrics(metrics_list):
    if metrics_list:
        with open(metrics_list) as f:
            m = json.load(f)
        return list(m[0].keys()) + list(m[1].keys())
    else:
        return [
        "smsp__average_warp_latency_issue_stalled_no_instruction.ratio",
        "dram__bytes.sum",
        "l1tex__t_bytes_lookup_hit.sum",
        "smsp__sass_l1tex_tags_mem_global.max",
        "smsp__average_warp_latency_issue_stalled_dispatch_stall.pct",
        "l1tex__data_pipe_lsu_wavefronts_mem_shared_cmd_write.max",
        "dram__bytes.max",
        "smsp__average_warp_latency_issue_stalled_not_selected.pct",
        "smsp__sass_thread_inst_executed_op_fp32_pred_on.max",
        "sm__average_threads_launched_per_warp.pct",
        "l1tex__t_bytes.avg",
        "sm__average_threads_launched_per_warp_shader_cs.pct",
        "smsp__average_threads_launched_per_warp.pct",
        "sm__sass_inst_executed_op_memory_32b.max",
        "l1tex__data_bank_conflicts_pipe_lsu_mem_shared.max",
        "l1tex__data_bank_conflicts_pipe_lsu_mem_shared.sum",
        "l1tex__t_bytes_lookup_hit.max",
        "sm__average_thread_inst_executed_pred_on_per_inst_executed_realtime.pct",
        "lts__t_request_hit_rate.pct",
        "smsp__sass_average_data_bytes_per_wavefront_mem_shared.max_rate",
        "smsp__average_warp_latency_issue_stalled_selected.ratio",
        "l1tex__data_pipe_lsu_wavefronts_mem_shared_cmd_read.max",
        "smsp__average_inst_executed_per_warp.ratio",
        "sm__sass_thread_inst_executed_op_fp32_pred_on.max",
        "sm__sass_data_bytes_mem_shared.avg",
        "smsp__average_warp_latency_issue_stalled_drain.pct",
        "sm__sass_data_bytes_mem_global.avg",
        "smsp__average_warp_latency_issue_stalled_no_instruction.pct",
        "smsp__average_warp_latency_issue_stalled_lg_throttle.pct",
    ]

def get_time_cmd(outfile):
    return f'/usr/bin/time -f %e -a -o {outfile}'

def get_ncu_cmd(cudadir, outdir, output_prefix, kernel_names, metrics):
    timecmd = get_time_cmd(os.path.join(outdir, f'{output_prefix}.time'))
    ncu_outfile = os.path.join(outdir, f'{output_prefix}.kernel_metrics')

    if kernel_names == None:
        kernel_regex = f':::3'
    else:
        assert all([' ' not in k for k in kernel_names])
        kernel_regex = f'::regex:"{"|".join(kernel_names)}":3'

    return f'{timecmd} ' \
           f'{cudadir}/bin/ncu ' \
           f'--target-processes all '\
           f'-f ' \
           f'-o {ncu_outfile} ' \
           f'-s 0 ' \
           f'--kernel-id {kernel_regex} ' \
           f'--metrics {",".join(metrics)}'

def parse_func_signature(s):
    k = s
    okr = s

    a = k.find("<")
    b = k.find(">")
    nk = k[a + 1 : b]
    if b == -1:
        pass
    elif (
        " " in nk
        or nk == "unnamed"
        or nk
        in (
            "float",
            "unnamed",
            "<unnamed",
        )
    ):
        a = k.find(" ")
        b = k.find("<")
        if "unnamed" in k[b + 1 : b + len("unnamed") + 1]:
            c = k[b + 1 :].find("<")
            k = k[b + 1 + len("unnamed") + 1 : c + b + 1]
        else:
            k = k[a + 1 : b]
    else:
        k = nk
    if "::" in k:
        k = k.split("::")[-1]
    if '(' in k:
        k = k.split('(')[0]
    return k


def print_op(o):
    std_mean = o["StdDev (ns)"] / o["Avg (ns)"]

    print(f'{parse_func_signature(o["Operation"])}:')
    print(f'\tTime %: {o["Time (%)"]}')
    print(f'\tInstances: {o["Instances"]}')
    print(f"\tstdmean: {std_mean:.2f}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--in-file")
    parser.add_argument("--cuda-dir", default="/usr/local/cuda-12.2")
    parser.add_argument("--out-dir", default="/output")
    parser.add_argument("--output-prefix", default="testing")
    parser.add_argument("--app-cmdline")
    parser.add_argument("--metrics-file")
    parser.add_argument("--num-kernels", default=5, type=int)
    args = parser.parse_args()

    with open(args.in_file) as f:
        r = json.load(f)

    mem_ops = [o for o in r if o["Category"] == "MEMORY_OPER"]
    cuda_ops = [o for o in r if o["Category"] == "CUDA_KERNEL"]

    sorted_ops = sorted(cuda_ops, reverse=True, key=lambda x: x["Time (%)"])
    if args.num_kernels == -1:
        kernel_names = None
    else:
        kernel_names = [parse_func_signature(op['Operation']) for op in sorted_ops[:5]]
    ncu_cmd = get_ncu_cmd(args.cuda_dir, 
                          args.out_dir, 
                          args.output_prefix, 
                          kernel_names,
                          get_metrics(args.metrics_file))
    print(ncu_cmd + " " + args.app_cmdline)

    # print(mem_ops)

if __name__ == "__main__":
    main()
