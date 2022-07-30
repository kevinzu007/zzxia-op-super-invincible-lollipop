#!/bin/bash

echo "
[Unit]
Description=Docker Socket for the API
PartOf=docker.service

[Socket]
ListenStream=0.0.0.0:2375
BindIPv6Only=both
Service=docker.service

[Install]
WantedBy=sockets.target
" > /etc/systemd/system/docker-tcp.socket

systemctl enable docker-tcp.socket
systemctl stop docker
systemctl start docker-tcp.socket
systemctl start docker


