import logging
import datetime
import time
import sys
import re
import json
from pprint import pformat
from netmiko import ConnectHandler

_SEP_RE = re.compile(r"^\s*(?P<key>.*?)\s*:\s*(?P<value>\w.*?)$")

now = datetime.datetime.now()
now_str = now.strftime("%Y%m%d_%H%M")

log_file_name = "switch_port_flap_{}.log".format(now_str)
format_string = "%(asctime)s [%(levelname)s] - %(filename)s : %(message)s"
logger = logging.getLogger()
formatter = logging.Formatter(format_string)
file_handler = logging.FileHandler(filename=log_file_name, mode="w")
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)
logger.setLevel(logging.INFO)

def connect_to_switch(ip_address, username, password):
    try:
        handle = ConnectHandler(
            host=ip_address, username=username, password=password, device_type="cisco_nxos")
    except:
        logger.critical("Unable to connect to %s" % ip_address)
        return 0

    logger.info("Connected to %s" % ip_address)
    return handle

def dsc_traffic_check(dsc_hdl):
    print('Verifying traffic after port flap')
    print('elbmon -s')
    logger.info('Verifying traffic after port flap')
    logger.info('elbmon -s')
    traffic_output = dsc_hdl.send_command("elbmon -s")
    print(traffic_output)
    logger.info(traffic_output)
    match = re.search('TXDMA=([0-9]+)', traffic_output)
    txdma = match.group(1)
    if int(txdma) < 1000:
        print('traffic validation failed after Port Flap, retrying in 60sec')
        logger.info('traffic validation failed after Port Flap, retrying in 60sec')
        time.sleep(60)
        traffic_output = dsc_hdl.send_command("elbmon -s")
        print(traffic_output)
        logger.info(traffic_output)
        match = re.search('TXDMA=([0-9]+)', traffic_output)
        txdma = match.group(1)
        if int(txdma) < 1000:
            print('traffic validation failed after Port Flap')
            logger.info('traffic validation failed after Port Flap')
            dsc_nvme_techsupport(hdl, "port_flap")
            sys.exit(1)
    else:
        print('Traffic Validation PASSED after Port Flap')
        logger.info('Traffic Validation PASSED after Port Flap')

def verify_naples_core(hdl, core_dir="/data/core/"):
    """
    function to check if core files are seen after a test run
    :param log: log handle passed from test script
    :param hdl: naples handle passed from test script (telnet or ssh)
    :param core_dir: default core directory on naples (pass core_dir if it changes in the future)
    :return: pass/fail the test case
    """
    CORE_FOUND = False
    FILE_NAME_PREFIX = "ROTATED_CORE_"
    ls_attributes = [
        "permission",
        "links",
        "user",
        "group",
        "size",
        "ymd",
        "hms",
        "offset",
        "filename",
    ]
    hdl.send_command("ls -lh {core_dir} --full-time | grep -v out.sh > /tmp/core_list".format(core_dir=core_dir))
    core_files = hdl.send_command("cat /tmp/core_list")
    core_files = core_files.split("\n")
    core_file_list = list()

    for core in core_files:
        if "total " in core:
            continue
        core_dict = dict()
        core = core.split()
        if len(core) != 9:
            print("ls output is truncated or didnt not conform to standard")
            logger.info("ls output is truncated or didnt not conform to standard")
            continue
        core_dict = dict(zip(ls_attributes, core))
        core_file_list.append(core_dict)
    if len(core_file_list) > 0:
        print("core_found")
        logger.info("core_found")
        return True
    return False

def config_interface(hdl, DSC_UPLINK0_INTF_LIST, command):
    for interface in DSC_UPLINK0_INTF_LIST:
        config_set = ["interface {}".format(interface), command]
        logger.info('-'*40)
        logger.info("Current Set of commands")
        logger.info(config_set)
        logger.info('-'*40)

        print('-'*40)
        print("Current Set of commands")
        print(config_set)
        print('-'*40)

        try:
            hdl.send_config_set(config_set)
        except:
            print("config error")
            logger.error("config error")
            pass

def get_interface_status(hdl, DSC_UPLINK0_INTF_LIST):
    base_status = list()
    if_status = dict()

    for interface in DSC_UPLINK0_INTF_LIST:
        logger.info("running show inteface on %s" % interface)
        print("running show inteface on %s" % interface)
        state = hdl.send_command("show interface {} brief".format(interface))
        state = [curr_state for curr_state in state.split(
            '\n') if curr_state.startswith("Eth1/")]
        base_status.extend(state)

    for status in base_status:
        ifstate = status.split()
        if_status[ifstate[0]] = ifstate[4]

    return if_status

def dsc_nvme_techsupport(hdl, log_dir):
    log_dir_d = f"/data/{log_dir}"
    hdl.send_command(f"mkdir {log_dir_d}")
    logger.info(f"Copying Log Files to {log_dir_d}")
    print(f"Copying Log Files to {log_dir_d}")
    hdl.send_command(f"cp /obfl/* {log_dir_d}")
    logger.info("Starting Tech support Collection..")
    print("Starting Tech support Collection..")
    hdl.send_command(f"export LD_LIBRARY_PATH=/platform/lib:/nic/lib && /nic/tools/nsvcfg debug stats > {log_dir_d}/nsvdebugstats")
    hdl.send_command(f"/nic/tools/pen_oci_techsupport.sh --nic-path /nic/ --tmp-path /tmp/ --out-path {log_dir_d} &")

SWITCH_IP = "10.2.36.38" #"IP_ADDRESS"
SWITCH_USERNAME = "admin"
SWITCH_PASSWORD = "Pen1nfra$"
DSC_UPLINK0_INTF_LIST = "Eth1/25-26"
SHUT_CMD = "shut"
NO_SHUT_CMD = "no shut"
ITERATIONS = 100
TEST_FAIL = False
FAIL_DSC_LIST = []
DSC_IP= "10.8.100.60"
DELAY_IN_SEC=70
HOST_USER="root"
HOST_PASSWORD="docker"

for i in range(ITERATIONS):
    print("===========================")
    print("Starting Iteration #", str(i+1))
    print("===========================")
    hdl = connect_to_switch(SWITCH_IP, SWITCH_USERNAME, SWITCH_PASSWORD)
    assert hdl, logger.error("Connection To Switch Failed")
    logger.info('='*50)
    logger.info(f"STARTING PORT FLAP ITERATION# {i+1}")
    logger.info('='*50)
    dschdl = ConnectHandler(device_type='linux', ip=DSC_IP, username='root', password='pen123', blocking_timeout=500)
    cores = verify_naples_core(dschdl)
    if cores:
        logger.error("Core found during port flap test")
        print("Core found during port flap test")
        dsc_nvme_techsupport(dschdl, "port_flap")
        sys.exit(1)
    else:
        logger.info("No core seen during this port flap iteration!")
        print("No core seen during this port flap iteration!")

    config_interface(hdl, [DSC_UPLINK0_INTF_LIST], SHUT_CMD)
    print("Performing Shut On Interface")
    logger.info("Performing Shut On Interface")
    interface_state = get_interface_status(hdl, [DSC_UPLINK0_INTF_LIST])
    time.sleep(0.2)
    logger.info(interface_state)
    print(interface_state)
    time.sleep(DELAY_IN_SEC)
    #time.sleep(2)
    print("Performing No-Shut On Interface")
    logger.info("Performing No-Shut on Interface")
    config_interface(hdl, [DSC_UPLINK0_INTF_LIST], NO_SHUT_CMD)
    time.sleep(5)
    interface_state = get_interface_status(hdl, [DSC_UPLINK0_INTF_LIST])
    logger.info(interface_state)
    print(interface_state)
    time.sleep(DELAY_IN_SEC*4)
    dsc_traffic_check(dschdl)
    hdl.disconnect()
    time.sleep(2)
