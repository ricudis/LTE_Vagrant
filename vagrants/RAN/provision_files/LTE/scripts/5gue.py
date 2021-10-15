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

CMDLINE='ip netns exec %s /opt/LTE/ueransim/bin/nr-ue -c /opt/LTE/ueransim/etc/open5gs-5gue%s.yaml'

TRIGGERS = [
    r'Connection setup for PDU session.+ is successful, TUN interface\[(.+), (.+)\] is up.',
    pexpect.EOF,
    pexpect.TIMEOUT
]

psh=None

def winch_handler(sig, data):
    s = struct.pack("HHHH", 0, 0, 0, 0)
    a = struct.unpack('hhhh', fcntl.ioctl(sys.stdout.fileno(),
        termios.TIOCGWINSZ , s))
    if psh and not psh.closed:
        psh.setwinsize(a[0],a[1])
        
signal.signal(signal.SIGWINCH, winch_handler)

def ip_setup(interface, ip, namespace):
    subprocess.run(['ip', 'netns', 'exec', namespace, 'route', 'add', '-host', '10.45.0.1', 'dev', interface])
    subprocess.run(['ip', 'netns', 'exec', namespace, 'route', 'add', '-net', 'default', 'gw', '10.45.0.1'])
    subprocess.run(['ip', 'netns', 'exec', namespace, 'ifconfig'])
    subprocess.run(['ip', 'netns', 'exec', namespace, 'netstat', '-rn'])

def run_ue(ue):
    namespace='ue-5gue' + str(ue)
    CMD=CMDLINE % (namespace, str(ue))
    SHELL='ip netns exec %s /bin/bash' % (namespace)
    p = None
    psh = None
    
    try:
        p = pexpect.spawnu(CMD)
        p.logfile = sys.stdout

        while True:
            m = p.expect(TRIGGERS);
            if (m == 0):
                interface = p.match.groups()[0]
                ip = p.match.groups()[1]
                print('Connection established, interface=%s IP=%s' % (interface, ip));
                ip_setup(interface, ip, namespace)
                print('Exit this shell to kill UE')
                psh = pexpect.spawnu(SHELL)
                signal.signal(signal.SIGWINCH, winch_handler)
                psh.interact()
                raise Terminate
                
    except KeyboardInterrupt:
        print("Keyboard interrupt, exiting")
    except Terminate:
        print("Shell exited")
    finally:
        if (p):
            print("Terminating UE")
            p.terminate()
            p.close()
        if (psh):
            print("Terminating shell")
            psh.terminate()
            psh.close()

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
