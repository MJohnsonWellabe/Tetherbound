#!/bin/bash
# Re-queue after the OOM: F39#3 d3, F39#15 s15, F39#3 dr, F39#9 tests + base.
R=/home/user/Tetherbound/ralph/reports/LANES/VIS-TIDEWAKE/runbook
$R/qj3run.sh > /dev/shm/run/qj3run.out 2>&1
$R/qj15run.sh > /dev/shm/run/qj15run.out 2>&1
$R/qj3dr.sh > /dev/shm/run/qj3dr.out 2>&1
$R/qj9base.sh > /dev/shm/run/qj9base.out 2>&1
