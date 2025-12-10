#!/bin/bash
# Installation script for SubTakeover
# Created by Varun Sulakhe

echo -e "\e[36m"
echo '╔═══════════════════════════════════════════════╗'
echo '║           SubTakeover Installation            ║'
echo '╚═══════════════════════════════════════════════╝'
echo -e "\e[0m"
echo -e "\e[33mCreated by: Varun Sulakhe\e[0m"
echo -e "\e[90m═══════════════════════════════════════════════\e[0m"
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "\e[31m[!] Go is not installed!\e[0m"
    echo -e "Please install Go 1.17+ from: https://golang.org/dl/"
    exit 1
fi

echo -e "\e[32m[+] Go is installed: $(go version)\e[0m"

# Check if GOPATH/bin is in PATH
if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    echo -e "\e[33m[!] Adding ~/go/bin to PATH\e[0m"
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc
    export PATH=$PATH:$HOME/go/bin
    echo -e "\e[32m[✓] PATH updated. Please restart your terminal or run:\e[0m"
    echo -e "    source ~/.bashrc  # or source ~/.zshrc"
fi

# Install tools
echo -e "\n\e[33m[1] Installing subfinder...\e[0m"
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

echo -e "\e[33m[2] Installing dnsx...\e[0m"
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest

echo -e "\e[33m[3] Installing httpx...\e[0m"
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

echo -e "\e[33m[4] Installing subzy...\e[0m"
go install -v github.com/LukaSikic/subzy@latest

echo -e "\e[33m[5] Installing nuclei...\e[0m"
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

# Update nuclei templates
echo -e "\e[33m[6] Updating nuclei templates...\e[0m"
nuclei -update-templates

# Optional: Install figlet for banner
if command -v apt &> /dev/null; then
    echo -e "\e[33m[7] Installing figlet (optional for banner)...\e[0m"
    sudo apt install -y figlet 2>/dev/null || echo "Figlet installation skipped"
elif command -v yum &> /dev/null; then
    echo -e "\e[33m[7] Installing figlet (optional for banner)...\e[0m"
    sudo yum install -y figlet 2>/dev/null || echo "Figlet installation skipped"
fi

# Make main script executable
echo -e "\e[33m[8] Setting up main script...\e[0m"
chmod +x takeover.sh

# Verify installations
echo -e "\n\e[36m[+] Verification:\e[0m"
tools=("subfinder" "dnsx" "httpx" "subzy" "nuclei")
all_installed=true

for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        echo -e "  \e[32m✓ $tool installed\e[0m"
    else
        echo -e "  \e[31m✗ $tool not found in PATH\e[0m"
        all_installed=false
    fi
done

if [ "$all_installed" = true ]; then
    echo -e "\n\e[32m═══════════════════════════════════════════════\e[0m"
    echo -e "\e[32m[+] Installation Complete!\e[0m"
    echo -e "\e[32m[+] Run: ./takeover.sh example.com\e[0m"
    echo -e "\e[32m═══════════════════════════════════════════════\e[0m"
else
    echo -e "\n\e[31m[!] Some tools failed to install\e[0m"
    echo -e "\e[33m[!] Try adding ~/go/bin to your PATH:\e[0m"
    echo -e "    export PATH=\$PATH:\$HOME/go/bin"
    echo -e "    Then restart your terminal"
fi