# Docker build environment for static `ipmitool`

A 32-bit staticly built `ipmitool` can be [run on VMWare ESXi
5.x](https://coderwall.com/p/5cqj0g/esxi-ipmitool-works-on-any-linux-system-as-well)
(and [maybe
4.x](http://blog.rchapman.org/post/17480234232/configuring-bmc-drac-from-esxi-or-linux)).
This one is built on a 32-bit (i386) CentOS 4.9 base image, as that has
libraries of approximately the same age as VMWare ESXi 5.0.

Conveniently it turns out that [the Dell iDRAC cards also support
(parts of) the IPMI
interface](http://web.mit.edu/cron/documentation/dell-server-admin/en/idrac1/chap02.htm),
which means that Dell servers with iDRAC cards running VMWare ESXi
can have their IP addresses checked/configured via this static tool.

Our basic testing shows that this statically linked `ipmitool` will 
allow checking and setting the Dell iDRAC cards LAN (local network)
parameters on ESXi 5.0.  Other IPMI and iDRAC features have *not* 
been tested.  

We would recommend testing this on a lab machine or machine in
VMWare Maintenance mode before trying it on any of your production
machines.  Tool usage is at our own risk; see the [LICENSE](LICENSE) for 
disclaimer of warranty and liability.


## Building static ipmitool

### centos4\_i386

The build requires a 32-bit CentOS 4.9 base
image, called `centos4_i386`.  

Unfortunately the [Official CentOS Docker
Images](https://registry.hub.docker.com/_/centos/) are (a)
only 64-bit and (b) only go back to CentOS 5.  Fortunately
[Brian Lalor](https://github.com/blalor/) has created
[a script and `Dockerfile` that can build a CentOS 4 base
image](https://github.com/blalor/docker-centos4-base), but it is
designed for `x86_64` (ie, 64-bit).  However it is possible to 
adapt to building an image that will work as a 32-bit image:

    git clone https://github.com/blalor/docker-centos4-base.git
    cd docker-centos4-base
    vi build.sh       # Change arch from x86_64 to i386, comment out EPEL
    docker run --privileged -i -t -v $PWD:/srv centos:centos6 /srv/build.sh i386
    docker build -t centos4_i386 .

It appears for some reason that the EPEL setup does not work with the i386
install, possibly due to not having changed enough yum repositories at that
point, but since EPEL is not required for the `ipmitool` build it can just
be commented out.


### Building `ipmitool.static`

To build the Docker image:

    docker build -t ipmitool_build --rm .

And then run it, with an output directory mounted over `/mnt` to get 
a copy of the static binary:

    docker run -i -t -v $PWD:/mnt ipmitool_build


## Using the static ipmitool

Once built, you can enable the SSH server on your ESXi host, then use 
`scp` to copy the static binary onto the ESXi host.  Eg,

    scp -p ipmitool.static root@${ESXHOST}:/scratch

And then log into the ESXi host as root:

    ssh root@${ESXHOST}

and run the binary, eg:

    ~ # /scratch/ipmitool.static lan print 1
    Set in Progress         : Set Complete
    Auth Type Support       : NONE MD2 MD5 PASSWORD
    Auth Type Enable        : Callback : MD2 MD5
                            : User     : MD2 MD5
                            : Operator : MD2 MD5
                            : Admin    : MD2 MD5
                            : OEM      :
    IP Address Source       : Static Address
    IP Address              : 10.0.9.17
    Subnet Mask             : 255.255.255.0
    MAC Address             : 14:fe:b5:d5:52:b4
    SNMP Community String   : public
    IP Header               : TTL=0x40 Flags=0x40 Precedence=0x00 TOS=0x10
    BMC ARP Control         : ARP Responses Enabled, Gratuitous ARP Disabled
    Default Gateway IP      : 10.0.9.1
    Default Gateway MAC     : 00:00:00:00:00:00
    Backup Gateway IP       : 0.0.0.0
    Backup Gateway MAC      : 00:00:00:00:00:00
    802.1q VLAN ID          : Disabled
    802.1q VLAN Priority    : 0
    RMCP+ Cipher Suites     : 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
    Cipher Suite Priv Max   : aaaaaaaaaaaaaaa
                            :     X=Cipher Suite Unused
                            :     c=CALLBACK
                            :     u=USER
                            :     o=OPERATOR
                            :     a=ADMIN
                            :     O=OEM
    ~ #

If for some reason you need to set the LAN interface, the usual `ipmitool`
commands for setting will work, eg:

    /scratch/ipmitool.static lan set 1 ipaddr 10.0.9.17
    /scratch/ipmitool.static lan set 1 defgw ipaddr 10.0.9.1

and you can do `ipmitool lan print 1` to verify that the settings were
updated.
