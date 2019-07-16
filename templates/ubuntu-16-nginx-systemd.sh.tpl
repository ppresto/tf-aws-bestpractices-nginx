#!/bin/bash

echo "[---Begin nginx-systemd.sh---]"

NODE_NAME=$(hostname)
LOCAL_IPV4=$(curl -s ${local_ip_url})
CONSUL_TLS_DIR=/opt/consul/tls
CONSUL_CONFIG_DIR=/etc/consul.d

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Install nginx"
sudo apt-get update
sudo apt-get -y install nginx ${packages}

echo "Configure New Default Port"
sudo sed -i "s/listen 80/listen ${port}/" /etc/nginx/sites-enabled/default
sudo sed -i "s/listen \[::\]:80/listen \[::\]:${port}/" /etc/nginx/sites-enabled/default

sudo systemctl reload nginx
sudo systemctl enable nginx

echo "[---best-practices-consul-systemd.sh Complete---]"
