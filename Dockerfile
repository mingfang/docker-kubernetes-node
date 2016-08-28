FROM ubuntu:16.04
  
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    TERM=xterm
RUN locale-gen en_US en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc
RUN apt-get update

# Runit
RUN apt-get install -y --no-install-recommends runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute

#Proxy needs iptables
RUN apt-get install -y --no-install-recommends iptables

#Need this for ovs-ovsctl
RUN apt-get install -y --no-install-recommends openvswitch-switch

#Dnsmasq and Confd used for DNS
RUN apt-get install -y --no-install-recommends dnsmasq 
RUN wget -O /usr/local/bin/confd  https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 && \
    chmod +x /usr/local/bin/confd

#ZFS
RUN apt-get install -y --no-install-recommends zfsutils-linux

#Docker client only
RUN wget -O - https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz | tar zx -C /usr/local/bin --strip-components=1 docker/docker

#NFS client
RUN apt-get install -y nfs-common

#Kubernetes
RUN wget -P /usr/local/bin https://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kubelet
RUN wget -P /usr/local/bin https://storage.googleapis.com/kubernetes-release/release/v1.3.6/bin/linux/amd64/kube-proxy
RUN chmod +x /usr/local/bin/kube*

#Manifests
RUN mkdir -p /etc/kubernetes/manifests

#OVS Scripts
ADD ovs-sync.sh /ovs-sync.sh
ADD ovs-remote.sh /ovs-remote.sh
ADD ovs-show.sh /ovs-show.sh

#Aliases
ADD aliases /root/.aliases
RUN echo "source ~/.aliases" >> /root/.bashrc

#Configs
ADD etc /etc/

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
