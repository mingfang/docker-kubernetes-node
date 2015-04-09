FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq

#Proxy needs iptables
RUN apt-get install -y iptables

#Need this for ovs-ovsctl
RUN apt-get install -y openvswitch-switch

#Docker client only
RUN wget -O /usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-latest && \
    chmod +x /usr/local/bin/docker

#Kubernetes
RUN wget -O - https://github.com/GoogleCloudPlatform/kubernetes/releases/download/v0.14.2/kubernetes.tar.gz| tar zx
RUN tar -xvf /kubernetes/server/kubernetes-server-linux-amd64.tar.gz --strip-components 3 -C /usr/local/bin 

#Manifests
ADD manifests /etc/kubernetes/manifests

#OVS Scripts
ADD register.sh /register.sh
ADD ovs-sync.sh /ovs-sync.sh
ADD ovs-remote.sh /ovs-remote.sh
ADD ovs-show.sh /ovs-show.sh

#Aliases
ADD aliases /root/.aliases
RUN echo "source ~/.aliases" >> /root/.bashrc

#Add runit services
ADD sv /etc/service 

