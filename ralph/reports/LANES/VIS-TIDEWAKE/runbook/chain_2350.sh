#!/bin/bash
# After d3 shipped: F39#15 s15, F39#3 dr, F39#9 tests + base.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
$R/qj15run.sh > /dev/shm/run/qj15run.out 2>&1
$R/qj3dr.sh > /dev/shm/run/qj3dr.out 2>&1
$R/qj9base.sh > /dev/shm/run/qj9base.out 2>&1
