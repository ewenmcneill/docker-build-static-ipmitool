## Build 32-bit ipmitool statically, for use on ESXi 5.x
#
# To produce ipmitool.static in the current directory:
#
# docker build -t ipmitool_build --rm .
# docker run -i -t -v $PWD:/mnt ipmitool_build
#
# This Dockerfile needs a centos4_i386 base image, which is built from:
#
# https://github.com/blalor/docker-centos4-base
# 
# modified to support building with i386 architecture:
#
# git clone https://github.com/blalor/docker-centos4-base.git
# cd docker-centos4-base
# vi build.sh   # <--- change arch from x86_64 to i386, comment out EPEL bits
# docker run --privileged -i -t -v $PWD:/srv centos:centos6 /srv/build.sh i386
# docker build -t centos4_i386 .
#
# Written by Ewen McNeill <ewen@naos.co.nz>, 2015-07-08
#---------------------------------------------------------------------------
# Copyright (c) 2015, Naos Ltd and LocalCloud Ltd
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived
# from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#---------------------------------------------------------------------------

FROM centos4_i386
MAINTAINER EWen McNeill <ewen@naos.co.nz>

# Fix up yum, so that it will install i386 versions, without GPG key warnings
# (for some reason base image does not seem to set up GPG key versions)
RUN sed 's/\$basearch/i386/; s/\]/-i386]/;'                              \
         </etc/yum.repos.d/CentOS-Base.repo                              \
         >/etc/yum.repos.d/CentOS-i386.repo                           && \
    sed -i '/protect=1/a enabled=0' /etc/yum.repos.d/CentOS-Base.repo && \
    curl -L -o /tmp/RPM-GPG-KEY-centos4                                  \
            http://mirror.centos.org/centos/RPM-GPG-KEY-centos4       && \
    echo "57821109aeb5f27805b80be03e31b1d978f3b7c7464c684169b1d341ff4d7021" \
         " /tmp/RPM-GPG-KEY-centos4" | sha256sum -c -                 && \
    rpm --import /tmp/RPM-GPG-KEY-centos4                             && \
    rm /tmp/RPM-GPG-KEY-centos4

# Install gcc4 and make, as build dependencies for ipmitool
RUN yum -y install gcc4 make

# Add download and compile script
ADD build-ipmitool /root/build-ipmitool

# And set it to run by default
CMD sh -x /root/build-ipmitool /mnt
