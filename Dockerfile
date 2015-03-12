FROM ubuntu:14.04
 
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8

#Runit
RUN apt-get install -y runit 
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

#Utilities
RUN apt-get install -y vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common

#Proxy needs iptables
RUN apt-get install -y iptables

#jq
RUN wget -P /usr/bin http://stedolan.github.io/jq/download/linux64/jq && \
    chmod +x /usr/bin/jq

#Docker client only
RUN wget -O /usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-latest && \
    chmod +x /usr/local/bin/docker

#Kubernetes
RUN wget -O - https://github.com/GoogleCloudPlatform/kubernetes/releases/download/v0.12.1/kubernetes.tar.gz| tar zx
RUN tar -xvf /kubernetes/server/kubernetes-server-linux-amd64.tar.gz --strip-components 3 -C /usr/local/bin 

ADD register.sh /register.sh

#Aliases
ADD aliases /root/.aliases
RUN echo "source ~/.aliases" >> /root/.bashrc

#Add runit services
ADD sv /etc/service 

