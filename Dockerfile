FROM ubuntu:18.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales tzdata && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/bin/runsvdir /etc/service'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute2 python ssh rsync gettext-base

#Proxy needs iptables
RUN apt-get install -y --no-install-recommends iptables conntrack

#ZFS
RUN apt-get install -y --no-install-recommends zfsutils-linux

#NFS client
RUN apt-get install -y nfs-common

#XFS
RUN apt-get install -y libguestfs-xfs

#Ceph client
RUN apt-get install -y ceph-common

#For Hairpin-veth mode
RUN apt-get install -y ethtool

#IPVS
RUN apt-get install -y ipvsadm ipset

#Consul Template
RUN wget -O - https://releases.hashicorp.com/consul-template/0.20.0/consul-template_0.20.0_linux_amd64.tgz | tar zx -C /usr/local/bin

#Docker client only
RUN wget -O - https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz | tar zx -C /usr/local/bin --strip-components=1 docker/docker

#Kubernetes
RUN wget -P /usr/local/bin https://storage.googleapis.com/kubernetes-release/release/v1.18.2/bin/linux/amd64/kubelet
RUN wget -P /usr/local/bin https://storage.googleapis.com/kubernetes-release/release/v1.18.2/bin/linux/amd64/kube-proxy
RUN wget -P /usr/local/bin https://storage.googleapis.com/kubernetes-release/release/v1.18.2/bin/linux/amd64/kubectl
RUN chmod +x /usr/local/bin/kube*

#Configs
RUN mkdir -p /srv/kubernetes
COPY consul-template.sh /

COPY manifests /etc/kubernetes/manifests

# Add runit services
COPY sv /etc/service
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
