#!/bin/bash

files=("/dev/nvme0n1:/dev/nvme0n2:/dev/nvme0n3:/dev/nvme0n4:/dev/nvme0n5:/dev/nvme0n6:/dev/nvme0n7:/dev/nvme0n8" "/dev/nvme1n1:/dev/nvme1n2:/dev/nvme1n3:/dev/nvme1n4:/dev/nvme1n5:/dev/nvme1n6:/dev/nvme1n7:/dev/nvme1n8" "/dev/nvme2n1:/dev/nvme2n2:/dev/nvme2n3:/dev/nvme2n4:/dev/nvme2n5:/dev/nvme2n6:/dev/nvme2n7:/dev/nvme2n8" "/dev/nvme3n1:/dev/nvme3n2:/dev/nvme3n3:/dev/nvme3n4:/dev/nvme3n5:/dev/nvme3n6:/dev/nvme3n7:/dev/nvme3n8" "/dev/nvme0n1:/dev/nvme0n2:/dev/nvme0n3:/dev/nvme0n4:/dev/nvme0n5:/dev/nvme0n6:/dev/nvme0n7:/dev/nvme0n8:/dev/nvme1n1:/dev/nvme1n2:/dev/nvme1n3:/dev/nvme1n4:/dev/nvme1n5:/dev/nvme1n6:/dev/nvme1n7:/dev/nvme1n8:/dev/nvme2n1:/dev/nvme2n2:/dev/nvme2n3:/dev/nvme2n4:/dev/nvme2n5:/dev/nvme2n6:/dev/nvme2n7:/dev/nvme2n8:/dev/nvme3n1:/dev/nvme3n2:/dev/nvme3n3:/dev/nvme3n4:/dev/nvme3n5:/dev/nvme3n6:/dev/nvme3n7:/dev/nvme3n8")

rws=("randread" "readwrite" "randrw")
blk_sz='2048k'
iodepth=512
njobs=64
rt=20

for file in "${files[@]}"
do
    for rw in "${rws[@]}"
    do
        fio_cmd=(fio --filename=${file} --direct=1 --rw=${rw} --bs=${blk_sz} --group_reporting --randrepeat=1 --ioengine=libaio --name nvmeperf --iodepth=${iodepth} --numjobs=${njobs} --eta-newline=1 --time_based --runtime=${rt})
        echo ${fio_cmd[@]}
        res=eval "${fio_cmd[@]}"
        if [[ $res != '0' ]]; then
            return 1
        fi
    done
done
