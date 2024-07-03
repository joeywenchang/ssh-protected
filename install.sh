#!/bin/bash

# Elevate privileges to root
sudo su << EOF

# Update package list and install Fail2Ban
apt-get update
apt-get install -y fail2ban

# Backup the original Fail2Ban jail.conf
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Create a new Fail2Ban SSH jail configuration
cat << EOL > /etc/fail2ban/jail.d/ssh.conf
[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 600
findtime = 600
EOL

# Restart Fail2Ban to apply the new configuration
systemctl restart fail2ban

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

# Allow SSH on port 2222
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

EOF

echo "Configuration complete. Ensure you can connect to the server on port 2222."
Explanation:
Elevate Privileges: The sudo su <<EOF block ensures all commands run as root.
Update and Install Fail2Ban: Installs Fail2Ban and updates the package list.
Backup and Configure Fail2Ban: Backs up the original Fail2Ban configuration and creates a new one for SSH.
Restart Fail2Ban: Applies the new Fail2Ban configuration.
Configure SSH: Changes SSH configuration to use port 2222, disables password authentication, and sets the maximum number of authentication attempts.
Restart SSH: 
