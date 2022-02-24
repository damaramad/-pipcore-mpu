#!/usr/bin/env python3

# Script to build all benchmarks

# Copyright (C) 2017, 2019 Embecosm Limited
#
# Contributor: Graham Markall <graham.markall@embecosm.com>
# Contributor: Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# This file is part of Embench.

# SPDX-License-Identifier: GPL-3.0-or-later

"""
Build all Embench programs.
"""


import argparse
import os
import shutil
import subprocess
import sys
import telnetlib
import queue
import re
import threading
import time
import datetime
from pathlib import Path
import shutil
import json
from statistics import mean
import multiprocessing

sys.path.append(
    os.path.join(os.path.abspath(os.path.dirname(__file__)), '../../embench-iot')
)
sys.path.append(
    os.path.join(os.path.abspath(os.path.dirname(__file__)), '../../embench-iot/pylib')
)


from embench_core import check_python_version
from embench_core import log
from embench_core import gp
from embench_core import setup_logging
from embench_core import log_args
from embench_core import find_benchmarks
from embench_core import log_benchmarks
from embench_core import arglist_to_str
from benchmark_size import benchmark_size
from benchmark_size import ALL_METRICS

import benchiot_measure_static_flash_and_ram

def static_metrics(bench_dir, benchmarks, sequence):
    print("\nCollecting static data:\n")

    successful = True
    raw_section_data = {}
    raw_totals = {}
    rel_data = {}
    static_results = {}

    # invoke BenchIoT ROP gadgets and indirect calls
    #exec(open("benchmarks/benchiot_measure_static_flash_and_ram.py").read())
    benchiot_measure_static_flash_and_ram.measure_static(benchmarks)

    # Collect data
    for bench in benchmarks:
        raw_section_data[bench] = benchmark_size(bench, ALL_METRICS)
        raw_totals[bench] = sum(raw_section_data[bench].values())
        bench_path = os.path.join(bench_dir, bench)
        size_out = raw_section_data[bench]
        static_results[bench] = {}
        for f in os.listdir(bench_path):
            file_path = os.path.join(bench_path, f)
            if os.path.isfile(file_path):
                filename, file_extension = os.path.splitext(file_path)
                if file_extension == ".json":
                    with open(file_path) as fdata:
                        data = json.load(fdata)
                        static_out = size_out | {"ROP_gadgets" : int(data["ROP_gadgets"]), "Indirect_calls" : int(data["Indirect_calls"])}
                        static_results[bench] |= static_out
                if file_extension == ".bin":
                    static_results[bench] |= {"binsize" : (os.path.getsize(file_path))}
    res_rec_filename = 'results_static_' + str(sequence) + '.json'
    static_metrics_file = os.path.join(bench_dir, 'results', res_rec_filename)
    with open(static_metrics_file, "w") as outfile:
        json.dump(static_results, outfile, indent=4, sort_keys=True)

    if successful:
        return raw_totals, rel_data

    # Otherwise failure return
    return [], []

""" Retrieve the dynamic analysis results is in the output string """
def decode_results(file_str):
    results = {}
    cycles = re.search('Ticks:(\d+)', file_str, re.S)
    if cycles:
        results["Cycles"] = cycles.group(1)
    main_stack_usage = re.search('Main stack usage:(\d+)', file_str, re.S)
    if main_stack_usage:
        results["Main_stack_usage"] = main_stack_usage.group(1)
    app_stack_usage = re.search('App stack usage:(\d+)', file_str, re.S)
    if app_stack_usage:
        results["App_stack_usage"] = app_stack_usage.group(1)
    systick_stack_usage = re.search('Systick stack usage:(\d+)', file_str, re.S)
    if systick_stack_usage:
        results["Systick_stack_usage"] = systick_stack_usage.group(1)
    return results

""" Join the static and the dynamic results """
def produce_recap(results_dir, benchmarks, sequence, runs):
    # Compute the baseline data we need
    baseline = {}

    recap_tot = {}
    for f in os.listdir(results_dir):
        file_path = os.path.join(results_dir, f)
        if os.path.isfile(file_path):
            filename, file_extension = os.path.splitext(file_path)
            # read static
            res_static_filename = "results_static_" + str(sequence)
            if file_extension == ".json" and os.path.basename(filename) == res_static_filename:
                with open(file_path) as fstatics:
                    static_data = json.load(fstatics)

            res_dyn_filename = "results_dynamic_" + str(sequence)
            if file_extension == ".json" and os.path.basename(filename) == res_dyn_filename:
                with open(file_path) as fdynamics:
                    dynamic_data_all = json.load(fdynamics)
                    dynamic_data = {}
                    # Average, min, max
                    for bench in dynamic_data_all:
                        recap_tot[bench] = {}
                        systick_data = {"average" : 0, "min" : sys.maxsize, "max" : 0 , "var" : 0}
                        cycles_average = 0
                        cycles_min = sys.maxsize
                        cycles_max = 0
                        cycles_var = 0
                        main_stack_average = 0
                        main_stack_min = sys.maxsize
                        main_stack_max = 0
                        main_stack_var = 0
                        app_stack_average = 0
                        app_stack_min = sys.maxsize
                        app_stack_max = 0
                        app_stack_var = 0
                        for run in dynamic_data_all[bench]:
                            run_cycles = run["Cycles"]
                            cycles_average += run_cycles
                            if cycles_max < run_cycles:
                                cycles_max = run_cycles
                            if cycles_min > run_cycles:
                                cycles_min = run_cycles
                            run_main_stack = run["Main_stack_usage"]
                            main_stack_average += run_main_stack
                            if main_stack_max < run_main_stack:
                                main_stack_max = run_main_stack
                            if main_stack_min > run_main_stack:
                                main_stack_min = run_main_stack
                            run_app_stack = run["App_stack_usage"]
                            app_stack_average += run_app_stack
                            if app_stack_max < run_app_stack:
                                app_stack_max = run_app_stack
                            if app_stack_min > run_app_stack:
                                app_stack_min = run_app_stack
                            if "pip" in sequence:
                                run_systick_stack = run["Systick_stack_usage"]
                                systick_data["average"] += run_systick_stack
                                if systick_data["max"] < run_systick_stack:
                                    systick_data["max"] = run_systick_stack
                                if systick_data["min"] > run_systick_stack:
                                    systick_data["min"] = run_systick_stack
                        cycles_average /= runs
                        main_stack_average /= runs
                        app_stack_average /= runs
                        systick_data["average"] /= runs
                        # Variance
                        for run in dynamic_data_all[bench]:
                            cycles_var += (run["Cycles"]-cycles_average)**2
                            main_stack_var += (run["Main_stack_usage"]-main_stack_average)**2
                            app_stack_var += (run["App_stack_usage"]-app_stack_average)**2
                            if "pip" in sequence:
                                systick_data["var"] += (run["Systick_stack_usage"]-systick_data["average"])**2
                        cycles_var /= runs
                        main_stack_var /= runs
                        app_stack_var /= runs
                        systick_data["var"] /= runs
                        # Full results
                        dynamic_data[bench] = { 'Cycles_average': cycles_average,
                                                'Cycles_min': cycles_min,
                                                'Cycles_max': cycles_max,
                                                'Cycles_var': cycles_var,
                                                'Time_ms_average': float(int(cycles_average)) / float(64000000), # TODO: set real cpu frequency
                                                'Main_stack_average': main_stack_average,
                                                'Main_stack_min': main_stack_min,
                                                'Main_stack_max': main_stack_max,
                                                'Main_stack_var': main_stack_var,
                                                'App_stack_average': app_stack_average,
                                                'App_stack_min': app_stack_min,
                                                'App_stack_max': app_stack_max,
                                                'App_stack_var': app_stack_var
                                             }
                        if "pip" in sequence:
                            dynamic_data[bench] |= {'Systick_stack_average': systick_data["average"],
                                                    'Systick_stack_min': systick_data["min"],
                                                    'Systick_stack_max': systick_data["max"],
                                                    'Systick_stack_var': systick_data["var"]}
    for bench in benchmarks:
        recap_tot[bench]["Static"] = static_data[bench]
        recap_tot[bench]["Dynamic"] = dynamic_data[bench]
    res_rec_filename = 'results_recap_' + str(sequence) + '.json'
    recap_file = os.path.join(results_dir, res_rec_filename)
    with open(recap_file, "w") as outfile:
        json.dump(recap_tot, outfile, indent=4, sort_keys=True)


""" Generic function to start a process"""
def start_process(func, name=None, args = []):
    proc = multiprocessing.Process(target=func, name=name, args=args)
    proc.start()
    return proc

""" Start a JLinkGDBServer """
def init_gdbserver(bench_name):
    try:
        process = subprocess.Popen(
                    ["/opt/SEGGER/JLink/JLinkGDBServer", "-if", "swd", "-device", "nRF52832_xxAA",
                    "-endian", "little", "-speed", "1000", "-port", "2331", "-swoport", "2332",
                    "-telnetport", "2333", "-vd", "-ir", "-localhostonly", "1", "-singlerun", "-strict",
                    "-timeout", "0", "-nogui"],
                    #capture_output=True, # doesn't work
                    stdin=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    stdout=subprocess.DEVNULL
                    #timeout=gp['timeout'],
                )
    except BaseException:
        print("Error in init_gdbserver")

""" Start a telnet to retrive the semihosting output"""
def init_telnet(bench_name, run, sequence):
    succeeded = True
    output = ""
    try:
        tn = telnetlib.Telnet("localhost", 2333, timeout=20)
        output = tn.read_all()
        tn.close()
    except ConnectionRefusedError:
        print(f'Telnet error: Run of {bench_name} timed out.')
        succeeded = False
    except BaseException:
        print(f'Telnet error: {bench_name} failed')
        succeeded = False
    # Dump the data if successful
    outfile = os.path.join("generated/benchmarks", bench_name, f'{sequence}_{bench_name}_{run}.txt')
    if succeeded:
        with open(outfile, "w") as fileh:
            linecount = 0
            for line in output.decode('utf-8').splitlines(keepends=True):
               # if not 'All benchmarks ' + desc + ' successfully' in line:
                fileh.writelines(line)
                linecount=linecount+1
            fileh.close()
            if linecount == 1:
                print("***ERROR: " + bench_name + " failed, check gdbserver connection (is the device up and running? or try to augment sleep delay?)")
    else:
        print("***ERROR: " + bench_name + " failed, check gdbserver connection (is the device up and running? or try to augment sleep delay)")
        with open(outfile, 'w') as fileh:
            fileh.write("NOK")
            fileh.close()

def run_dynamic_metrics(benchmarks, sequence, runs):
    print("\nCollecting dynamic data:")

    for bench in benchmarks:
        print(f'\n***Launching {sequence} benchmark for {bench}***')
        for run in range(1, runs+1):
            start_run = time.time()
            print("***RUN "+ str(run) + "/" + str(runs) + "***")
            print("Starting GDBServer", end='...')
            gdbs = start_process(init_gdbserver, args=[bench])
            print("OK")
            print("Starting Telnet", end='...')
            time.sleep(0.5) # wait GDBServer is up
            tn = start_process(init_telnet, args=[bench, run, sequence])
            print("OK")
            print("Flashing and running %s..." % bench)
            try:
                res = subprocess.run(
                    ["arm-none-eabi-gdb", "--batch", "-ex", f'py arg0 = "{bench}"', "-x", "benchmarks/gdb_connect_flash_run.py"],
                    capture_output=True,
                )
            except subprocess.TimeoutExpired:
                    print(f'Warning: Run of {bench} timed out.')
                    print("NOK***")

            tn.join()
            #time.sleep(5)
            gdbs.join()
            end_run = time.time()
            print("Run %s ended in %s (HH:MM:SS)" % (run, str(datetime.timedelta(seconds=(end_run-start_run)))))
            # All threads have returned

def analyse_dynamic_metrics(results_dir, bench_dir, benchmarks, sequence):
    dynamic_results = {}
    # Analyse all dynamic outputs
    for bench in benchmarks:
        dir_path = os.path.join(bench_dir, bench)
        for f in os.listdir(dir_path):
            file_path = os.path.join(dir_path, f)
            if os.path.isfile(file_path):
                filename, file_extension = os.path.splitext(file_path)
                if file_extension == ".txt" and sequence in filename:
                    with open(file_path) as fdata:
                        read_data = fdata.read()
                        data = decode_results(read_data)
                        cycles = int(data["Cycles"])
                        file_name = re.search('.*_(\D+\d*)_(\d+).*$', f, re.S)
                        if file_name:
                            run_res_out = { 'Run': int(file_name.group(2)),
                                            'Cycles': cycles,
                                            'Time_ms': float(int(cycles)) / float(64000000), # TODO: set real cpu frequency
                                            'Main_stack_usage': int(data["Main_stack_usage"]),
                                            'App_stack_usage': int(data["App_stack_usage"])
                                        }
                            if "pip" in sequence:
                                run_res_out |= {'Systick_stack_usage': int(data["Systick_stack_usage"])}
                            if file_name.group(1) not in dynamic_results:
                                dynamic_results[file_name.group(1)] = []
                            dynamic_results[file_name.group(1)].append(run_res_out)
                        else:
                            print("***Error: Didn't find any output for " + f)
                            sys.exit(1)
    res_dyn_filename = 'results_dynamic_' + str(sequence) + '.json'
    baseline_file = os.path.join(results_dir, res_dyn_filename)
    with open(baseline_file, "w") as outfile:
        json.dump(dynamic_results, outfile, indent=4, sort_keys=True)

def compare_baseline(results_dir, sequence):
    # TODO: check variance is small
    if "bench-baseline" in sequence: # reject "bench-baseline-w-systick" and "bench-baseline-wo-systick":
        return
    print("Producing comparison report for %s" % sequence, end="...")
    rel_baseline_data = {}
    rel_total_recap_mean = {}
    # Open baseline file
    res_recap_baseline_filename = 'results_recap_bench-baseline-w-systick.json'
    recap_file = os.path.join(results_dir, res_recap_baseline_filename)
    with open(recap_file) as frecapbase:
        b_data = json.load(frecapbase)
        # Open baseline file
        res_recap_baseline_wo_systick_filename = 'results_recap_bench-baseline-wo-systick.json'
        recap_file = os.path.join(results_dir, res_recap_baseline_wo_systick_filename)
        with open(recap_file) as frecapbase:
            b_wo_systick_data = json.load(frecapbase)
            # open sequence file
            res_recap_filename = 'results_recap_' + str(sequence) + '.json'
            recap_file = os.path.join(results_dir, res_recap_filename)
            with open(recap_file) as frecap:
                data = json.load(frecap)
                for bench in data:
                    base_cycles = b_data[bench]["Dynamic"]["Cycles_average"]
                    sequence_cycles = data[bench]["Dynamic"]["Cycles_average"]
                    base_time = b_data[bench]["Dynamic"]["Time_ms_average"]
                    sequence_time = data[bench]["Dynamic"]["Time_ms_average"]
                    base_main_stack = b_data[bench]["Dynamic"]["Main_stack_average"]
                    sequence_main_stack = data[bench]["Dynamic"]["Main_stack_average"]
                    base_app_stack = b_data[bench]["Dynamic"]["App_stack_average"]
                    sequence_app_stack = data[bench]["Dynamic"]["App_stack_average"]
                    base_systick_stack = b_data[bench]["Dynamic"]["Main_stack_average"] - b_wo_systick_data[bench]["Dynamic"]["Main_stack_average"]
                    sequence_systick_stack = data[bench]["Dynamic"]["Systick_stack_average"]
                    base_indirect_calls = b_data[bench]["Static"]["Indirect_calls"]
                    sequence_indirect_calls = data[bench]["Static"]["Indirect_calls"]
                    base_gadgets = b_data[bench]["Static"]["ROP_gadgets"]
                    sequence_gadgets = data[bench]["Static"]["ROP_gadgets"]
                    base_bss = b_data[bench]["Static"]["bss"]
                    sequence_bss = data[bench]["Static"]["bss"]
                    base_data = b_data[bench]["Static"]["data"]
                    sequence_data = data[bench]["Static"]["data"]
                    base_rodata = b_data[bench]["Static"]["rodata"]
                    sequence_rodata = data[bench]["Static"]["rodata"]
                    base_text = b_data[bench]["Static"]["text"]
                    sequence_text = data[bench]["Static"]["text"]
                    base_binsize = b_data[bench]["Static"]["binsize"]
                    sequence_binsize = data[bench]["Static"]["binsize"]
                    rel_baseline_data[bench] = {"Dynamic" : {
                                                                "Cycles_rel_average" : sequence_cycles*100/base_cycles if base_cycles != 0 else sequence_cycles,
                                                                "Cycles_base_var" : b_data[bench]["Dynamic"]["Cycles_var"],
                                                                f'Cycles_{sequence}_var' : int(data[bench]["Dynamic"]["Cycles_var"]),
                                                                "Time_ms_rel_average" : sequence_time*100/base_time if base_time != 0 else sequence_time,
                                                                #"Time_ms_base_var" : b_data[bench]["Dynamic"]["Time_ms_var"],
                                                                #f'Time_ms_{sequence}_var' : data[bench]["Dynamic"]["Time_ms_var"],
                                                                "Main_stack_rel_average": sequence_main_stack*100/base_main_stack if base_main_stack != 0 else sequence_main_stack,
                                                                "Main_stack_base_var": b_data[bench]["Dynamic"]["Main_stack_var"],
                                                                f'Main_stack_{sequence}_var' : data[bench]["Dynamic"]["Main_stack_var"],
                                                                "App_stack_rel_average": sequence_app_stack*100/base_app_stack if base_app_stack != 0 else sequence_app_stack,
                                                                "App_stack_base_var": b_data[bench]["Dynamic"]["App_stack_var"],
                                                                f'App_stack_{sequence}_var' : data[bench]["Dynamic"]["App_stack_var"],
                                                                "Systick_stack_rel_average":  sequence_systick_stack*100/base_systick_stack if base_systick_stack != 0 else sequence_systick_stack,
                                                                "Systick_stack_base_var": b_data[bench]["Dynamic"]["Main_stack_var"],
                                                                f'Systick_stack_{sequence}_var' : data[bench]["Dynamic"]["Systick_stack_var"],
                                                            },
                                                "Static" : {
                                                                "Indirect_calls_rel" : sequence_indirect_calls*100/base_indirect_calls if base_indirect_calls != 0 else sequence_indirect_calls,
                                                                "ROP_gadgets_rel": sequence_gadgets*100/base_gadgets if base_gadgets != 0 else sequence_gadgets,
                                                                "bss_rel": sequence_bss*100/base_bss if base_bss != 0 else sequence_bss,
                                                                "data_rel": sequence_data*100/base_data if base_data != 0 else sequence_data,
                                                                "rodata_rel": sequence_rodata*100/base_rodata if base_rodata != 0 else sequence_rodata,
                                                                "text_rel": sequence_text*100/base_text if base_text != 0 else sequence_text,
                                                                "binsize_rel" : sequence_binsize*100/base_binsize if base_binsize != 0 else sequence_binsize
                                                            }
                                                }
                    if "Cycles_rel_total_mean" not in rel_total_recap_mean \
                        or "Main_stack_rel_average" not in rel_total_recap_mean \
                        or "App_stack_rel_average" not in rel_total_recap_mean \
                        or "Systick_stack_rel_average" not in rel_total_recap_mean \
                        or "Indirect_calls_rel" not in rel_total_recap_mean \
                        or "ROP_gadgets_rel" not in rel_total_recap_mean \
                        or "bss_rel" not in rel_total_recap_mean \
                        or "data_rel" not in rel_total_recap_mean \
                        or "rodata_rel" not in rel_total_recap_mean \
                        or "text_rel" not in rel_total_recap_mean \
                        or "binsize_rel" not in rel_total_recap_mean:
                        rel_total_recap_mean["Cycles_rel_total_mean"] = []
                        rel_total_recap_mean["Main_stack_rel_total_mean"] = []
                        rel_total_recap_mean["App_stack_rel_total_mean"] = []
                        rel_total_recap_mean["Systick_stack_rel_total_mean"] = []
                        rel_total_recap_mean["Indirect_calls_rel_total_mean"] = []
                        rel_total_recap_mean["ROP_gadgets_rel_total_mean"] = []
                        rel_total_recap_mean["bss_rel_total_mean"] = []
                        rel_total_recap_mean["data_rel_total_mean"] = []
                        rel_total_recap_mean["rodata_rel_total_mean"] = []
                        rel_total_recap_mean["text_rel_total_mean"] = []
                        rel_total_recap_mean["binsize_rel_total_mean"] = []
                    rel_total_recap_mean["Cycles_rel_total_mean"].append(rel_baseline_data[bench]["Dynamic"]["Cycles_rel_average"])
                    rel_total_recap_mean["Main_stack_rel_total_mean"].append(rel_baseline_data[bench]["Dynamic"]["Main_stack_rel_average"])
                    rel_total_recap_mean["App_stack_rel_total_mean"].append(rel_baseline_data[bench]["Dynamic"]["App_stack_rel_average"])
                    rel_total_recap_mean["Systick_stack_rel_total_mean"].append(rel_baseline_data[bench]["Dynamic"]["Systick_stack_rel_average"])
                    rel_total_recap_mean["Indirect_calls_rel_total_mean"].append(rel_baseline_data[bench]["Static"]["Indirect_calls_rel"])
                    rel_total_recap_mean["ROP_gadgets_rel_total_mean"].append(rel_baseline_data[bench]["Static"]["ROP_gadgets_rel"])
                    rel_total_recap_mean["bss_rel_total_mean"].append(rel_baseline_data[bench]["Static"]["bss_rel"])
                    rel_total_recap_mean["data_rel_total_mean"].append(rel_baseline_data[bench]["Static"]["data_rel"])
                    rel_total_recap_mean["rodata_rel_total_mean"].append(rel_baseline_data[bench]["Static"]["rodata_rel"])
                    rel_total_recap_mean["text_rel_total_mean"].append(rel_baseline_data[bench]["Static"]["text_rel"])
                    rel_total_recap_mean["binsize_rel_total_mean"].append(rel_baseline_data[bench]["Static"]["binsize_rel"])
    # relative mean for each metric
    rel_baseline_data["Total"] = { "Cycles_rel_average_tot" :  mean(rel_total_recap_mean["Cycles_rel_total_mean"]),
                                    "Main_stack_rel_average_tot" :  mean(rel_total_recap_mean["Main_stack_rel_total_mean"]),
                                    "App_stack_rel_average_tot" :  mean(rel_total_recap_mean["App_stack_rel_total_mean"]),
                                    "Systick_stack_rel_average_tot" :  mean(rel_total_recap_mean["Systick_stack_rel_total_mean"]),
                                    "Indirect_calls_rel_average_tot" :  mean(rel_total_recap_mean["Indirect_calls_rel_total_mean"]),
                                    "ROP_gadgets_rel_average_tot" :  mean(rel_total_recap_mean["ROP_gadgets_rel_total_mean"]),
                                    "bss_rel_average_tot" :  mean(rel_total_recap_mean["bss_rel_total_mean"]),
                                    "data_rel_average_tot" :  mean(rel_total_recap_mean["data_rel_total_mean"]),
                                    "rodata_rel_average_tot" :  mean(rel_total_recap_mean["rodata_rel_total_mean"]),
                                    "text_rel_average_tot" :  mean(rel_total_recap_mean["text_rel_total_mean"]),
                                    "binsize_rel_average_tot" :  mean(rel_total_recap_mean["binsize_rel_total_mean"]),
                                    }
    res_compare_filename = 'results_baseline_compare_' + str(sequence) + '.json'
    compare_file = os.path.join(results_dir, res_compare_filename)
    with open(compare_file, "w") as outfile:
        json.dump(rel_baseline_data, outfile, indent=4, sort_keys=True)
    print("OK -> written in %s" % compare_file)


""" Build and run the benchmarks, then analyse the results"""
def main():
    # Start benchmark time measurement
    start = time.time()
    # Establish the root directory of the repository, since we know this file is
    # in that directory.
    gp['rootdir'] = os.path.abspath(os.path.dirname(__file__))

    results_dir = "generated/benchmarks/results"

    bench_dir = "generated/benchmarks"

    runs = 5

    do_all = False
    build_only= False
    dynamic_analysis_only = False
    dynamic_analysis_only_no_run = False
    static_analysis_only = False
    recap_only = False
    baseline_compare_only = False

    args = sys.argv[1:]

    if(len(sys.argv)==1):
        do_all = True
    else:
        for arg in args:
            if "build" in arg:
                build_only= True
            if "dynamic" in arg:
                if "no-run" in arg:
                    dynamic_analysis_only_no_run = True
                else:
                    dynamic_analysis_only = True
            if "static" in arg:
                static_analysis_only = True
            if "recap" in arg:
                recap_only = True
            if "compare" in arg:
                baseline_compare_only = True

    if do_all:
        if(os.path.isdir(results_dir)):
            shutil.rmtree(results_dir) # erase dir
        Path(results_dir).mkdir(parents=True, exist_ok=True) # create dir

    # Find the benchmarks
    benchmarks = find_benchmarks()
    benchmarks.remove('matmult-int')

    benchmarks.remove('md5sum')
    benchmarks.remove('nettle-aes')
    benchmarks.remove('picojpeg')
    benchmarks.remove('ud')
    benchmarks.remove('tarfind')
    benchmarks.remove('st')
    benchmarks.remove('huffbench')

    # Not working with bench-pip-child
    benchmarks.remove('wikisort')

    # not working with bench-pip-child

    '''
    # working
    benchmarks.remove('aha-mont64')
    benchmarks.remove('crc32')
    benchmarks.remove('cubic')
    benchmarks.remove('edn')
    benchmarks.remove('minver')
    benchmarks.remove('nbody')
    benchmarks.remove('nettle-sha256')
    benchmarks.remove('nsichneu')
    benchmarks.remove('primecount')
    benchmarks.remove('qrduino')
    benchmarks.remove('statemate')


    benchmarks.remove('slre')
    benchmarks.remove('sglib-combined')
    '''

    #not working




    #benchmarks = ['aha-mont64', 'crc32', 'cubic', 'edn', 'huffbench']
    print("benchmarks.py: Considered benchmarks: %s " % benchmarks)
    log_benchmarks(benchmarks)

    # Launch the benchmark batch in different scenarios (baseline, without the systick interrupt, with Pip...)
    # Always keep the baseline scenarios at first
    boot_sequence =  ["bench-baseline-wo-systick", "bench-baseline-w-systick", "bench-pip-root", "bench-pip-child"] # ["bench-pip-child"] #
    for sequence in boot_sequence:
        print("\n\n-----> Configuring sequence %s" % sequence, end="...")
        try:
            res_clean = subprocess.run(
                ["make", "cleanbench-soft"],
                capture_output=True,
            )
            res = subprocess.run(
                ["./configure.sh", "--architecture=dwm1001", "--debugging-mode=semihosting",
                    f'--boot-sequence={sequence}'],
                capture_output=True,
            )
            if res_clean.returncode != 0 or res.returncode != 0:
                print("***NOK***")
                print("Investigate with commands: 1) make cleanbench-soft 2) ./configure.sh --architecture=dwm1001 --debugging-mode=semihosting --boot-sequence=%s" % sequence)
                succeeded = False

            else:
                log.debug('Configuration of sequence "{sequence}" successful'.format(sequence=sequence))
                print("OK")

        except subprocess.TimeoutExpired:
            log.warning('Warning: link of benchmark "{sequence}" timed out'.format(sequence=sequence))
            succeeded = False

        if do_all or build_only:
            # Track success
            successful = True
            for bench in benchmarks:
                print("Building " + bench, end='...')
                try:
                    res = subprocess.run(
                        ["make", "-s", "bench", "BENCH_NAME=" + bench],
                        capture_output=True,
                    )
                    if res.returncode != 0:
                        print("***NOK***")
                        print("--> Investigate with shell command: make bench BENCH_NAME=" + bench)
                        log.warning('Warning: Compilation of benchmark "{bench}" failed'.format(bench=bench))
                        succeeded = False

                    else:
                        log.debug('Compilation of benchmark "{bench}" successful'.format(bench=bench))
                        log.info(bench)
                        print("OK")

                except subprocess.TimeoutExpired:
                    log.warning('Warning: link of benchmark "{bench}" timed out'.format(bench=bench))
                    succeeded = False

            if successful:
                log.info('All benchmarks built successfully')
            else:
                print('ERROR: Not all benchmarks built successfully')
                sys.exit(1)

        if do_all or dynamic_analysis_only:
            run_dynamic_metrics(benchmarks, sequence, runs)

        if do_all or dynamic_analysis_only or dynamic_analysis_only_no_run:
            analyse_dynamic_metrics(results_dir, bench_dir, benchmarks, sequence)

        if do_all or static_analysis_only:
            static_metrics(bench_dir, benchmarks, sequence)

        if do_all or recap_only:
            produce_recap(results_dir, benchmarks, sequence, runs)

        if do_all or baseline_compare_only:
            compare_baseline(results_dir, sequence)
    end = time.time()
    print("\n\nDONE in %s (HH:MM:SS): Nothing to do left" % str(datetime.timedelta(seconds=(end-start))))

# Make sure we have new enough Python and only run if this is the main package

check_python_version(3, 10)
if __name__ == '__main__':
    sys.exit(main())
