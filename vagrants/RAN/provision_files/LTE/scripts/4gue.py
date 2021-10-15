#!/usr/bin/python3

from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

import pexpect
import struct
import fcntl
import termios
import signal
import re
import os
import sys
import pprint
import subprocess
import argparse

class Terminate(Exception):
    pass

CMDLINE_ENB='ip netns exec ue-4gue%s /opt/LTE/srsRAN/bin/srsenb /opt/LTE/srsRAN/etc/enb-4gue%s.conf'
CMDLINE_UE='ip netns exec ue-4gue%s /opt/LTE/srsRAN/bin/srsue /opt/LTE/srsRAN/etc/ue-4gue%s.conf'
CMDLINE_SHELL='ip netns exec ue-4gue%s /bin/bash'

TRIGGERS_ENB = [
    r'==== eNodeB started ===',
    pexpect.EOF,
    pexpect.TIMEOUT
]

TRIGGERS_UE = [
    r'Network attach successful. IP: ([0-9.]+)\r\n',
    r'Network attach successful. IPv6 interface Id:',
    r'nTp\) .+/.+/.+ .+:.+:.+ TZ:.+',
    pexpect.EOF,
    pexpect.TIMEOUT
]

pshell=None

def winch_handler(sig, data):
    s = struct.pack("HHHH", 0, 0, 0, 0)
    a = struct.unpack('hhhh', fcntl.ioctl(sys.stdout.fileno(),
        termios.TIOCGWINSZ , s))
    if pshell and not pshell.closed:
        pshell.setwinsize(a[0],a[1])
        
signal.signal(signal.SIGWINCH, winch_handler)

def ip_setup(interface, namespace, is_ipv6):
    if (is_ipv6):
        subprocess.run(['ip', 'netns', 'exec', namespace, 'ip', '-6', 'route', 'add', 'fd01:230:cafe::1', 'dev', interface])
        subprocess.run(['ip', 'netns', 'exec', namespace, 'ip', '-6', 'route', 'add', '::/0', 'via', 'fd01:230:cafe::1'])
    else:
        subprocess.run(['ip', 'netns', 'exec', namespace, 'route', 'add', '-host', '10.45.0.1', 'dev', interface])
        subprocess.run(['ip', 'netns', 'exec', namespace, 'route', 'add', '-net', 'default', 'gw', '10.45.0.1'])

def run_ue(ue):
    str_ue = str(ue)
    namespace='ue-4gue' + str_ue
    CMD_ENB=CMDLINE_ENB % (str_ue, str_ue)
    CMD_UE=CMDLINE_UE % (str_ue, str_ue) 
    CMD_SHELL=CMDLINE_SHELL % (str_ue)
    
    penb = None
    pue = None
    pshell = None
    
    try:
        enb_up = False
        ue_up = False
    
        penb = pexpect.spawnu(CMD_ENB)
        penb.logfile = sys.stdout
        while (not enb_up):
            m = penb.expect(TRIGGERS_ENB)
            if (m == 0):
                print("Matched ENB trigger string")
                enb_up = True
        
        print("Spawning UE")
        
        pue = pexpect.spawnu(CMD_UE)
        pue.logfile = sys.stdout        
        while (not ue_up):
            m = pue.expect(TRIGGERS_UE)
            if (m == 0):
                interface = 'tun_srsue' + str_ue
                print('Connection established, IPv4, interface=%s' % (interface));
                ip_setup(interface, namespace, False)
            if (m == 1):
                interface = 'tun_srsue' + str_ue
                print('Connection established, IPv6, interface=%s' % (interface));
                ip_setup(interface, namespace, True)
            if (m == 2):
                ue_up = True
                print('UE active')
                subprocess.run(['ip', 'netns', 'exec', namespace, 'ifconfig'])
                subprocess.run(['ip', 'netns', 'exec', namespace, 'netstat', '-rn'])
                subprocess.run(['ip', 'netns', 'exec', namespace, 'netstat', '-rn6'])
                
        print('Exit this shell to kill UE/ENB')
        pshell = pexpect.spawnu(CMD_SHELL)
        signal.signal(signal.SIGWINCH, winch_handler)
        pshell.interact()
        raise Terminate

    except KeyboardInterrupt:
        print("Keyboard interrupt, exiting")
    except Terminate:
        print("Shell exited")
    finally:
        if (pue):
            print("Terminating UE")
            pue.terminate()
            pue.close()
        if (penb):
            print("Terminating eNB")
            penb.terminate()
            penb.close()
        if (pshell):
            print("Terminate shell");
            pshell.terminate()
            pshell.close()



if __name__ == '__main__':
    if sys.version_info.major < 3 or sys.version_info.minor < 6:
        raise Exception("Python 3.6 required")
        
    parser = argparse.ArgumentParser()
    parser.add_argument("ue", help="UE number [1 - 4]")
    args = parser.parse_args()
    ue = int(args.ue)
    
    if (ue < 0 or ue > 4):
        raise Exception("UE must be between 1 and 4")
        
    run_ue(ue)
