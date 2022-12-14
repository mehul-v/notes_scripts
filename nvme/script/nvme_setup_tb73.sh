set -x #echo on

/nic/tools/start-sec-agent.sh
sleep 2
/nic/tools/start-vpp.sh &
sleep 2
/nic/tools/start-nvme-agent.sh
sleep 2

vppctl set ip arp cpu_mnic3 1.1.0.2 00:ae:cd:00:2f:70
vppctl set ip arp cpu_mnic3 1.1.0.3 00:ae:cd:00:09:60

vppctl set interface ip address cpu_mnic3 1.1.0.1/24

/nic/bin/pdsctl debug update port -p Eth1/1 --auto-neg disable --fec-type none
/nic/bin/pdsctl debug update port -p Eth1/2 --auto-neg disable --fec-type none

sleep 1

vppctl ping 1.1.0.2
vppctl ping 1.1.0.3

dhclient oob_mnic0
ifconfig oob_mnic0

#/nic/bin/vppctl set tcp-plugin global ooq 1

#nsv_scale_cfg.py --no-auto-connect -n 8 -g 115 -p 1 -t 1.1.0.2 -t 1.1.0.3
#nsv_scale_cfg.py --no-auto-connect -n 8 -g 50 -p 1 -t 1.1.0.2 -t 1.1.0.3
#nsv_scale_cfg.py --no-auto-connect -n 1 -p1 -g1 -t 1.1.0.2 -t 1.1.0.3

#nsv_scale_cfg.py --no-auto-connect -n 8 -g 115 -p 1 -t 1.1.0.2


#stress 
#nsv_scale_cfg.py --no-auto-connect -b 4096 -b 512 -b 4096 -b 512 -m SHIFTED -m SHIFTED -m NORMAL -m NORMAL -n 8 -g 115 -p 1 -d 0 -d 0 -d 0 -d 0 -v 1 -t 1.1.0.2 -t 1.1.0.3
nsv_scale_cfg.py --no-auto-connect -n 4 -g 115 -p 1 --nsobj obj_key=10002 ivmode=shifted blksz=512 --nsobj obj_key=10003 ivmode=NORMAL blksz=4096 --nsobj obj_key=10004 ivmode=NORMAL blksz=512 --nsobj obj_key=10006 ivmode=shifted blksz=512 --nsobj obj_key=10007 ivmode=NORMAL blksz=4096 --nsobj obj_key=10008 ivmode=NORMAL blksz=512 --nsobj obj_key=10010 ivmode=shifted blksz=512 --nsobj obj_key=10011 ivmode=NORMAL blksz=4096 --nsobj obj_key=10012 ivmode=NORMAL blksz=512 --nsobj obj_key=10013 persistent=True ivmode=shifted blksz=4096 --nsobj obj_key=10014 persistent=True ivmode=shifted blksz=512 --nsobj obj_key=10015 persistent=True ivmode=NORMAL blksz=4096 --nsobj obj_key=10016 persistent=True ivmode=NORMAL blksz=512 nsPathTag=true -t 1.1.0.2 -t 1.1.0.3

# 1PF,15VF, 8NS per each pf/vf, 32path group with 2path per group
#nsv_scale_cfg.py --no-auto-connect -b 4096 -n 8 -g 32 -p 2 -d 15 -t 1.1.0.2 -t 1.1.0.3

#crash recovery + upgrade
#/nic/tools/nsv_scale_cfg.py -d 2 -n 8 -g 1 -p 1 -t 1.1.0.2
#/nic/tools/nsv_scale_cfg.py -d 2 -n 8 -g 24 -p 1 -t 1.1.0.2


#/nic/bin/vppctl show tcp-plugin global ooq
