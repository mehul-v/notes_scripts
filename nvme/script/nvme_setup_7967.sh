set -x #echo on

/nic/tools/start-sec-agent.sh
sleep 2
/nic/tools/start-vpp.sh &
sleep 2
/nic/tools/start-nvme-agent.sh
sleep 2

vppctl set ip arp cpu_mnic3 1.1.0.2 00:ae:cd:03:7b:48

vppctl set interface ip address cpu_mnic3 1.1.0.1/24

/nic/bin/pdsctl debug update port -p Eth1/1 --auto-neg disable --fec-type rs
/nic/bin/pdsctl debug update port -p Eth1/2 --auto-neg disable --fec-type rs

sleep 1

vppctl ping 1.1.0.2

dhclient oob_mnic0
ifconfig oob_mnic0

# nvme_precheckin
# /nic/tools/nsvcfg load --json /data/nvme_testsuite_nsvcfg_cfg.json

# nvme_upgrade
# /nic/tools/nsv_scale_cfg.py --no-auto-connect -b 4096 -b 512 -b 4096 -b 512 -m SHIFTED -m SHIFTED -m NORMAL -m NORMAL -n 2 -g 14 -p 2 -d 0 -d 0 -d 0 -d 0 -v 1

# nvme_stress
# /nic/tools/nsv_scale_cfg.py --no-auto-connect -b 4096 -b 512 -b 4096 -b 512 -b 4096 -b 512 -b 4096 -b 512 -m SHIFTED -m SHIFTED -m NORMAL -m NORMAL -m SHIFTED -m SHIFTED -m NORMAL -m NORMAL -n 8 -g 115 -p 2 -t 1.1.0.1 -t 1.1.0.2

#/nic/tools/nsv_scale_cfg.py -d 2 -n 8 -g 1 -p 1 --no-auto-connect --use-ns-path-tag
#/nic/tools/nsv_scale_cfg.py -d 2 -n 8 -g 24 -p 1 --no-auto-connect --use-ns-path-tag
/nic/tools/nsv_scale_cfg.py -d 2 -n 8 -g 1 -p 1 
