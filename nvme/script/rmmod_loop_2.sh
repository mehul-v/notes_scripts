#!/bin/bash
#!

oob='10.8.121.226'
pass='pen123'

check_failure () {
   command=(sshpass -p $pass ssh root@$oob 'LD_LIBRARY_PATH=/platform/lib:/nic/lib /nic/bin/eth_dbgtool nvme_debug' \> temp.log)
   eval "${command[@]}"
   cat temp.log

   command=(sshpass -p $pass ssh root@$oob 'LD_LIBRARY_PATH=/platform/lib:/nic/lib /nic/bin/eth_dbgtool nvme_cb resource tx | egrep "free|range"' \> temp1.log)
   eval "${command[@]}"
   cat temp1.log

   grepcmd=(grep \'global cbs\' temp.log \| cut -d \' \' -f 1)
   res=$(eval "${grepcmd[@]}")
   if [[ $res != '0' ]]; then
       return 1
   fi
}


seq=0
for i in {1..100}
do
   echo "iter $i"
   echo "rmmod nvme"
   rmmod nvme
   sleep 20

   echo "Check failure"
   check_failure
   if [[ $? != '0' ]]; then
       echo "check_failure failed"
       exit
   fi

   echo "modprobe nvme"
   modprobe nvme
   sleep 5
   ls /dev/nvme*
   sleep 2
   echo "fio template.fio"
   fio template.fio
   sleep 20

   check_failure
   if [[ $? != '0' ]]; then
       echo "check_failure failed"
       exit
   fi
done
