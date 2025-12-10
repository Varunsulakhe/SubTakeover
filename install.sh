#!/bin/bash
# Simple installation script for SubTakeover
# Created by Varun Sulakhe

echo "=============================================="
echo "      SubTakeover Installation Script"
echo "      Created by: Varun Sulakhe"
echo "=============================================="
echo ""

# Check Go
if ! command -v go &> /dev/null; then
    echo "[ERROR] Go is not installed!"
    echo "Install Go first: https://golang.org/dl/"
    echo "For Kali: sudo apt install golang"
    exit 1
fi

echo "[+] Go installed: $(go version)"

# Ensure Go bin is in PATH
if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    echo "[+] Adding Go binaries to PATH"
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# Install tools
echo ""
echo "[+] Installing security tools..."

echo "[1] Installing subfinder..."
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

echo "[2] Installing dnsx..."
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest

echo "[3] Installing httpx..."
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

echo "[4] Installing subzy..."
go install -v github.com/LukaSikic/subzy@latest

echo "[5] Installing nuclei..."
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

echo "[6] Updating nuclei templates..."
nuclei -update-templates

# Make script executable
chmod +x takeover.sh

echo ""
echo "=============================================="
echo "[+] Installation Complete!"
echo "[+] Run: ./takeover.sh example.com"
echo "=============================================="
