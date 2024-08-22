#!/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Create symlink for nvidia-smi
sudo ln -s /usr/lib/wsl/lib/nvidia-smi /usr/local/bin/nvidia-smi

# Install Bacalhau
cd /tmp
wget https://github.com/bacalhau-project/bacalhau/releases/download/v1.3.2/bacalhau_v1.3.2_linux_amd64.tar.gz
tar xfv bacalhau_v1.3.2_linux_amd64.tar.gz
sudo mv bacalhau /usr/bin/bacalhau
sudo mkdir -p /app/data/ipfs
sudo chown -R $USER /app/data

# Install Kubo (IPFS)
cd ~
wget https://dist.ipfs.tech/kubo/v0.29.0/kubo_v0.29.0_linux-amd64.tar.gz
tar -xvzf kubo_v0.29.0_linux-amd64.tar.gz
cd kubo/
sudo ./install.sh

# Initialize IPFS
export IPFS_PATH=/app/data/ipfs
ipfs init

# Install Lilypad
cd ~
OSARCH=$(uname -m | awk '{if ($0 ~ /arm64|aarch64/) print "arm64"; else if ($0 ~ /x86_64|amd64/) print "amd64"; else print "unsupported_arch"}') && export OSARCH
OSNAME=$(uname -s | awk '{if ($1 == "Darwin") print "darwin"; else if ($1 == "Linux") print "linux"; else print "unsupported_os"}') && export OSNAME
curl https://api.github.com/repos/lilypad-tech/lilypad/releases/latest | grep "browser_download_url.*lilypad-$OSNAME-$OSARCH-gpu" | cut -d : -f 2,3 | tr -d \" | wget -qi - -O lilypad
chmod +x lilypad
sudo mv lilypad /usr/local/bin/lilypad

# Securely prompt for the WEB3 private key
read -sp "Enter your WEB3 Private Key: " WEB3_PRIVATE_KEY
echo

# Create environment file for Lilypad with the private key
sudo mkdir -p /app/lilypad
sudo bash -c "echo 'WEB3_PRIVATE_KEY=$WEB3_PRIVATE_KEY' > /app/lilypad/resource-provider-gpu.env"

# Setup systemd for Bacalhau
sudo tee /etc/systemd/system/bacalhau.service > /dev/null <<EOF
[Unit]
Description=Lilypad V2 Bacalhau
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Environment="LOG_TYPE=json"
Environment="LOG_LEVEL=debug"
Environment="HOME=/app/lilypad"
Environment="BACALHAU_SERVE_IPFS_PATH=/app/data/ipfs"
Restart=always
RestartSec=5s
ExecStart=/usr/bin/bacalhau serve --node-type compute,requester --peer none --private-internal-ipfs=false

[Install]
WantedBy=multi-user.target
EOF

# Setup systemd for Lilypad Resource Provider
sudo tee /etc/systemd/system/lilypad-resource-provider.service > /dev/null <<EOF
[Unit]
Description=Lilypad V2 Resource Provider GPU
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Environment="LOG_TYPE=json"
Environment="LOG_LEVEL=debug"
Environment="HOME=/app/lilypad"
Environment="OFFER_GPU=1"
EnvironmentFile=/app/lilypad/resource-provider-gpu.env
Restart=always
RestartSec=5s
ExecStart=/usr/local/bin/lilypad resource-provider 

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start services
sudo systemctl daemon-reload
sudo systemctl enable bacalhau
sudo systemctl enable lilypad-resource-provider
sudo systemctl start bacalhau
sudo systemctl start lilypad-resource-provider

echo "Installation complete. Lilypad node is up and running!"
