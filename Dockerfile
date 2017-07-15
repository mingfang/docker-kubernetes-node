FROM ubuntu:16.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD export > /etc/envvars && /usr/sbin/runsvdir-start

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync gettext-base

#Proxy needs iptables
RUN apt-get install -y --no-install-recommends iptables

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

#Ceph client
RUN apt-get install -y ceph-common

#For Hairpin-veth mode
RUN apt-get install -y ethtool

#Kubernetes
RUN wget -P /usr/local/bin https://storage.googleapis.com/kubernetes-release/release/v1.7.1/bin/linux/amd64/kubelet
RUN wget -P /usr/local/bin https://storage.googleapis.com/kubernetes-release/release/v1.7.1/bin/linux/amd64/kube-proxy
RUN chmod +x /usr/local/bin/kube*

#Calico
RUN wget -N -P /opt/cni/bin https://github.com/projectcalico/cni-plugin/releases/download/v1.9.1/calico && \
    wget -N -P /opt/cni/bin https://github.com/projectcalico/cni-plugin/releases/download/v1.9.1/calico-ipam && \
    wget -N -P /opt/cni/bin https://github.com/projectcalico/cni-plugin/releases/download/v1.9.1/portmap && \
    chmod +x /opt/cni/bin/*
RUN wget -O - https://github.com/containernetworking/cni/releases/download/v0.3.0/cni-v0.3.0.tgz | tar zx && \
    mv loopback /opt/cni/bin/
RUN wget -N -P /usr/local/bin https://github.com/projectcalico/calicoctl/releases/download/v1.3.0/calicoctl && \
    chmod +x /usr/local/bin/calicoctl
COPY calico /calico
 
#Manifests
COPY manifests /etc/kubernetes/manifests

#Configs
ADD etc /etc/

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
