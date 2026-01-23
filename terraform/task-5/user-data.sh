#!/bin/bash
set -e

# NAT Instance Configuration Script for Amazon Linux 2023
# This script enables IP forwarding and configures iptables for NAT functionality

# Log all output for debugging
exec > >(tee -a /var/log/user-data.log)
exec 2>&1

echo "Starting NAT Instance configuration at $(date)"

# Enable IP forwarding persistently
echo "Enabling IP forwarding..."
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-nat.conf
sysctl -p /etc/sysctl.d/99-nat.conf

# Get the primary network interface
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}')
echo "Primary network interface: $PRIMARY_INTERFACE"

# Configure iptables for NAT/masquerading
echo "Configuring iptables for NAT..."
iptables -t nat -A POSTROUTING -o "$PRIMARY_INTERFACE" -j MASQUERADE

# Make iptables rules persistent across reboots
echo "Making iptables rules persistent..."
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

# Create systemd service to restore iptables rules on boot
cat > /etc/systemd/system/iptables-restore.service <<EOF
[Unit]
Description=Restore iptables rules
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/iptables-restore /etc/iptables/rules.v4
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the iptables-restore service
systemctl daemon-reload
systemctl enable iptables-restore.service

# Verify configuration
echo "Verifying NAT configuration..."
echo "IP forwarding status: $(sysctl net.ipv4.ip_forward)"
echo "iptables NAT rules:"
iptables -t nat -L -n -v

echo "NAT Instance configuration completed successfully at $(date)"
