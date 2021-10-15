# LTE_Vagrant
## Set of Vagrantfiles for a LTE testbed:

EPC (open5gs)
RAN + Soft-UE (ueransim + srsLTE)
IMS (work in progress)
3G (work in progress)

## Installation :

run "vagrant up" in each subdirectory (EPC and RAN for now). The
provisioning script inside Vagrantfile installs a base system,
then either:

1) untars a package of precompiled binaries located in provision_files/precompiled/

or

2) compiles all sources from scratch and generates the package

Provisioning the EPC VM will ask for an interface in the host-side to bridge
with. Use an interface with internet access.

If the precompiled files don't work, just remove
provision_files/precompiled/*.tar.bz2 and re-provision the vagrant VM.
The provisioning script will compile all sources from scratch then
generate new precompiled .tar.bz2 files in /opt/ which you can copy backl
into provision_files/precompiled/ in the host environment

## Networking :

Each VM is configured with two network interfaces, one NATed to the inside
world and one private network connecting the VMs (IP range:
192.168.33.0/24). EPC has a third interface for traffic capture

Inside the Vagrant VMs, each component runs in its own networking namespace,
with veth interfaces that are bridged together in the default namespace

The default IP allocations are located in /opt/LTE/env :

RAN :

> LTE_IP_brran=10.99.90.128\
> LTE_IP_ran_gnb0=10.99.90.129\
> LTE_IP_ran_5gue1=10.99.90.130\
> LTE_IP_ran_5gue2=10.99.90.131\
> LTE_IP_ran_5gue3=10.99.90.132\
> LTE_IP_ran_5gue4=10.99.90.133\
> LTE_IP_ran_4gue1=10.99.90.140\
> LTE_IP_ran_4gue2=10.99.90.141\
> LTE_IP_ran_4gue3=10.99.90.142\
> LTE_IP_ran_4gue4=10.99.90.143\
> LTE_VM_BRIDGE_INTERFACE="eth1"\
> LTE_MCC=901\
> LTE_MNC=70

EPC :

> LTE_IP_brepc=10.99.90.1\
> LTE_IP_mongo=10.99.90.1\
> LTE_IP_epc_mme0=10.99.90.2\
> LTE_IP_epc_sgwc0=10.99.90.3\
> LTE_IP_epc_smf0=10.99.90.4\
> LTE_IP_epc_amf0=10.99.90.5\
> LTE_IP_epc_sgwu0=10.99.90.6\
> LTE_IP_epc_upf0=10.99.90.7\
> LTE_IP_epc_hss0=10.99.90.8\
> LTE_IP_epc_pcrf0=10.99.90.9\
> LTE_IP_epc_nrf0=10.99.90.10\
> LTE_IP_epc_ausf0=10.99.90.11\
> LTE_IP_epc_udm0=10.99.90.12\
> LTE_IP_epc_pcf0=10.99.90.13\
> LTE_IP_epc_nssf0=10.99.90.14\
> LTE_IP_epc_bsf0=10.99.90.15\
> LTE_IP_epc_udr0=10.99.90.20\
> LTE_TAP_ENABLE=0\
> LTE_LOCAL_IP="192.168.222.1"\
> LTE_TAP_TARGET_MAC="36:c6:44:91:1a:65"\
> LTE_TAP_TARGET_IP="192.168.111.44"\
> LTE_TAP_DUMMY_GRE_IP1="10.99.99.1"\
> LTE_TAP_DUMMY_GRE_IP2="10.99.99.2"\
> LTE_TAP_DUMMY_GRE_MAC="fe:6a:0e:b0:87:e5"\
> LTE_VM_BRIDGE_INTERFACE="eth1"\
> LTE_PUBLIC_ROUTE_ENABLE=1

## Tooling description:

Configuration template files are in /opt/LTE/config_templates/

Several helper scripts in /opt/LTE/scripts:

* for EPC:

> /opt/LTE/scripts/01-generate_config.sh

Populate the HSS database, then generate configuration files from templates
in /opt/LTE/config_templates/ and values in /opt/LTE/env

> /opt/LTE/scripts/02-setup_network.sh

Sets up networking namespaces, routing and filtering rules

> /opt/LTE/scripts/03-start_core.sh

Start Open5GS EPC elements

> /opt/LTE/scripts/open5gs-dbctl

Used by 01-generate_config.sh

> /opt/LTE/scripts/subst.sh

Simple templating script, used by 01-generate_config.sh


* for RAN:

> ./LTE/scripts/01-generate_config.sh

generate configuration files from templates
in /opt/LTE/config_templates/ and values in /opt/LTE/env

> /opt/LTE/scripts/02-setup_network.sh

Sets up networking namespaces, routing and filtering rules

> /opt/LTE/scripts/03-start_ran.sh

Starts RAN elements

> /opt/LTE/scripts/5gue.py

Start one of the four 5G preconfigured UEs, takes the number of the UE (1 - 4)
as an argument

> /opt/LTE/scripts/4gue.py

Start one of the four 4G preconfigured UEs, takes the number of the UE (1 - 4)
as an argument

> /opt/LTE/scripts/subst.sh

Simple templating script, used by 01-generate_config.sh


## How to run:

### First start EPC:

> [username@host LTE_Vagrant]$ cd EPC\
> [username@host EPC]$ vagrant up

.... (VM is provisioned) ....

> [username@host EPC]$ vagrant ssh\
> vagrant@ubuntu2004:~$ sudo -s\
> root@ubuntu2004:/home/vagrant# /opt/LTE/scripts/01-generate_config.sh\
> root@ubuntu2004:/home/vagrant# /opt/LTE/scripts/02-setup_network.sh\
> root@ubuntu2004:/home/vagrant# /opt/LTE/scripts/03-start_core.sh

### Then start RAN:

> [username@host RAN]$ vagrant ssh\
> vagrant@ubuntu2004:~$ sudo -s\
> root@ubuntu2004:/home/vagrant# /opt/LTE/scripts/01-generate_config.sh\
> root@ubuntu2004:/home/vagrant# /opt/LTE/scripts/02-setup_network.sh\
> root@ubuntu2004:/home/vagrant# /opt/LTE/scripts/03-start_ran.sh

RAN vm has four 4G UEs and four 5G UEs you can run. If you want to run more
than two 4G UEs concurrently you might have to adjust the VM RAM allocation in
vagrant, as the srsLTE UE softmodem is pretty resource-hungry.

### How to start a 5G UE:

> root@ubuntu2004:/home/vagrant# /opt/LTE/scripts/5gue.py 1
>
> .... (UE is attaching and a shell is created inside the UE namespace) ....
>
> [2021-10-15 11:54:33.013] [app] [info] Connection setup for PDU session[1] is successful, TUN interface[uesimtun0, 10.45.0.2] is up.\
> Connection established, interface=uesimtun0 IP=10.45.0.2\
> Exit this shell to kill UE\
> root@ubuntu2004:/home/vagrant#

From this point on any network application you run will go through UE <> RAN <> EPC:

> root@ubuntu2004:/home/vagrant# ping 10.45.0.1\
> PING 10.45.0.1 (10.45.0.1) 56(84) bytes of data.\
> 64 bytes from 10.45.0.1: icmp_seq=1 ttl=64 time=4.37 ms\
> 64 bytes from 10.45.0.1: icmp_seq=2 ttl=64 time=2.65 ms\
> ^C\
> 2 packets transmitted, 2 received, 0% packet loss, time 1014ms\
> rtt min/avg/max/mdev = 2.650/3.508/4.367/0.858 ms\
> root@ubuntu2004:/home/vagrant#

### How to start a 4G UE:

> root@ubuntu2004:/home/vagrant# /opt/LTE/scripts/4gue.py 1

.... (ENB is starting, UE is attaching and a shell is created inside the ENB/UE namespace) ....

In the default configuration, 4G UEs 1 and 2 request IPv4 PDN, UE 3 requests
IPv4v6 PDN and UE 4 requests IPv6 PDN
