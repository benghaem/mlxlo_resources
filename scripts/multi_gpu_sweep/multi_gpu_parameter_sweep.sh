#!/bin/bash

# replace with your python script
EXE="./echo_example.sh"
NUM_GPUS=4
LOG_DIR="./logs"

echo "Enter a run name: (no spaces or slashes)"
read RUN_NAME

# we create a new short name for each experiment run
EXPERIMENT_HASH=$(date +%s%N | sha256sum | head -c 6)
EXP_NAME=${RUN_NAME}_${EXPERIMENT_HASH}
OUTPUT_DIR="${LOG_DIR}/${EXP_NAME}"
mkdir -p $OUTPUT_DIR

echo "Running new experiments: $EXP_NAME"

# MODIFY THESE LINES WITH THE ARGUMENTS YOU NEED
# create your argument combinations here
arg_queue=()
for arg1 in 0 4 7 8 ; do
    for arg2 in 2 3 4 ; do
        arg_queue+=("${arg1} ${arg2}")
    done
done

# run the queue here
job_counter=0
device_counter=0
for args in "${arg_queue[@]}"; do

    # set the correct cuda device
    export CUDA_VISIBLE_DEVICES="$device_counter"

    # log the job start
    job_start=$(date +"%m-%d %H:%M:%S")
    echo $job_counter $job_start $EXE $args | sed "s/ /, /g" >> ${OUTPUT_DIR}/job_list.csv
    echo "Launched $job_counter @ $job_start on $device_counter"

    # launch the job
    $($EXE $args > ${OUTPUT_DIR}/${job_counter}.log) &

    # increment the counters
    ((device_counter++))
    ((job_counter++))

    # wait for the current batch of jobs to complete
    # not super efficient, but simple
    if [[ ${device_counter} -eq ${NUM_GPUS} ]]; then
        wait
        device_counter=0
    fi
done
