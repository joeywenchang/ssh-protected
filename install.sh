#!/bin/bash

# Elevate privileges to root
sudo bash << EOF

# Install iptables-persistent if not already installed
apt-get update
apt-get install -y iptables-persistent

# Configure SSH settings
sed -i -e '/^#Port 22/c\Port 2222' \
       -e '/^#PermitRootLogin prohibit-password/c\PermitRootLogin prohibit-password' \
       -e '/^#PasswordAuthentication yes/c\PasswordAuthentication no' \
       -e '/^#PubkeyAuthentication yes/c\PubkeyAuthentication yes' \
       -e '/^#MaxAuthTries 6/c\MaxAuthTries 3' /etc/ssh/sshd_config

# Restart SSH service to apply the new configuration
systemctl restart sshd

# Flush all iptables rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t raw -F
iptables -t raw -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow necessary traffic
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Rate limiting
iptables -A INPUT -p tcp --dport 2222 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 2222 -m state --state NEW -m recent --update --seconds 600 --hitcount 3 -j DROP

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

EOF

echo "Configuration complete."
