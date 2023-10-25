#!/bin/bash

# Ask for the name of the new peer
read -p "Enter the name of the new peer: " name

# Generate the private and public keys for the new peer
cd /etc/wireguard
umask 077
wg genkey | tee "$name"-privatekey | wg pubkey > "$name"-publickey

# Get the last AllowedIPs from wg0.conf and increment the last octet by 1
last_ip=$(awk '/AllowedIPs/{last=$NF} END{sub(/\/32$/, "", last); split(last, octets, "."); octets[4]+=1; printf("%d.%d.%d.%d\n", octets[1], octets[2], octets[3], octets[4])}' /etc/wireguard/wg0.conf)

# Create a new configuration file for the new peer
cat > "/etc/wireguard/$name.conf" <<EOF
[Interface]
PrivateKey = $(cat "$name"-privatekey)
Address = $last_ip/24
DNS = 1.1.1.1
[Peer]
PublicKey = $(cat server-publickey)
AllowedIPs = 0.0.0.0/0
Endpoint = rif.3cx.ae:51820
EOF

# Add the new peer to wg0.conf
cat >> /etc/wireguard/wg0.conf <<EOF

#$name
[Peer]
PublicKey = $(cat "$name"-publickey)
AllowedIPs = $last_ip/32
PersistentKeepalive = 25
EOF

# Restart the WireGuard service to apply the changes
systemctl restart wg-quick@wg0.service

echo "Added peer '$name' with AllowedIPs '$last_ip/32' to /etc/wireguard/wg0.conf."

# Clean up temporary files
rm "$name"-privatekey
rm "$name"-publickey

#display QR Code
qrencode -t ansiutf8 < /etc/wireguard/"$name".conf