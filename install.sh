#!/bin/bash
# Fixed installation script for SubTakeover
# Created by Varun Sulakhe

echo "=============================================="
echo "      SubTakeover Installation"
echo "      Created by: Varun Sulakhe"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] Running as non-root user${NC}"
    echo -e "${YELLOW}[!] Some features may require sudo privileges${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Function to check if tool is installed
check_tool() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}[✓] $1 is already installed${NC}"
        return 0
    else
        echo -e "${RED}[ ] $1 is not installed${NC}"
        return 1
    fi
}

# Check Go
if ! check_tool "go"; then
    echo -e "${RED}[ERROR] Go is not installed!${NC}"
    echo "Install Go first: https://golang.org/dl/"
    echo "For Kali/Debian: sudo apt install golang"
    echo "For macOS: brew install go"
    exit 1
fi

echo -e "${GREEN}[+] Go installed: $(go version)${NC}"

# Ensure Go bin is in PATH
if [[ ":$PATH:" != *":$HOME/go/bin:"* ]] && [[ ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
    echo -e "${BLUE}[+] Adding Go binaries to PATH${NC}"
    echo 'export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# Install required tools
echo ""
echo -e "${BLUE}[+] Installing/Checking required tools...${NC}"

TOOLS=(
    "subfinder:github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "dnsx:github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "httpx:github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "subzy:github.com/PentestPad/subzy@latest"
    "nuclei:github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
    "figlet:figlet"
)

for tool_info in "${TOOLS[@]}"; do
    tool_name=$(echo "$tool_info" | cut -d':' -f1)
    tool_path=$(echo "$tool_info" | cut -d':' -f2)

    if ! check_tool "$tool_name"; then
        if [[ "$tool_path" == "figlet" ]]; then
            echo -e "${BLUE}[+] Installing figlet...${NC}"
            if command -v apt &> /dev/null; then
                sudo apt install -y figlet 2>/dev/null || echo -e "${YELLOW}[!] Failed to install figlet${NC}"
            elif command -v yum &> /dev/null; then
                sudo yum install -y figlet 2>/dev/null || echo -e "${YELLOW}[!] Failed to install figlet${NC}"
            elif command -v brew &> /dev/null; then
                brew install figlet 2>/dev/null || echo -e "${YELLOW}[!] Failed to install figlet${NC}"
            else
                echo -e "${YELLOW}[!] Could not install figlet (package manager not found)${NC}"
            fi
        else
            echo -e "${BLUE}[+] Installing $tool_name...${NC}"
            go install -v "$tool_path" 2>&1 | grep -v "go: downloading" || echo -e "${YELLOW}[!] Failed to install $tool_name${NC}"
        fi
    fi
done

# Update nuclei templates
echo ""
echo -e "${BLUE}[+] Updating nuclei templates...${NC}"
if command -v nuclei &> /dev/null; then
    nuclei -update-templates
else
    echo -e "${YELLOW}[!] nuclei not found, skipping template update${NC}"
fi

# Check if main script exists
if [ ! -f "subtakeover.sh" ]; then
    echo -e "${RED}[!] Error: subtakeover.sh not found in current directory${NC}"
    echo -e "${YELLOW}[!] Please create subtakeover.sh first or download it${NC}"
    exit 1
fi

# Make main script executable
chmod +x subtakeover.sh
echo -e "${GREEN}[+] Made subtakeover.sh executable${NC}"

# Copy tools to /usr/local/bin for system-wide access (with sudo if available)
echo ""
echo -e "${BLUE}[+] Setting up system-wide access...${NC}"
for tool in subfinder dnsx httpx subzy nuclei; do
    if command -v "$tool" &> /dev/null; then
        tool_path=$(which "$tool")
        if [ -f "$tool_path" ]; then
            echo -e "${BLUE}[+] Found $tool at $tool_path${NC}"
            # Try with sudo, if fails try without
            sudo cp "$tool_path" /usr/local/bin/ 2>/dev/null && \
                echo -e "${GREEN}[+] Copied $tool to /usr/local/bin/${NC}" || \
                echo -e "${YELLOW}[!] Could not copy $tool to /usr/local/bin/ (permission denied)${NC}"
        fi
    fi
done

# Create system-wide symlink
echo ""
echo -e "${BLUE}[+] Creating system-wide symlink...${NC}"
if [ -f "$(pwd)/subtakeover.sh" ]; then
    # Try with sudo first
    sudo ln -sf "$(pwd)/subtakeover.sh" /usr/local/bin/subtakeover 2>/dev/null && \
        echo -e "${GREEN}[+] Created symlink: /usr/local/bin/subtakeover${NC}" || \
        ln -sf "$(pwd)/subtakeover.sh" ~/.local/bin/subtakeover 2>/dev/null && \
        echo -e "${GREEN}[+] Created symlink: ~/.local/bin/subtakeover${NC}" || \
        echo -e "${YELLOW}[!] Could not create system symlink${NC}"
fi

# Add ~/.local/bin to PATH if not already
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
    source ~/.bashrc
    echo -e "${BLUE}[+] Added ~/.local/bin to PATH${NC}"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}[+] Installation Complete!${NC}"
echo ""
echo -e "${BLUE}[+] Usage examples:${NC}"
echo "    System-wide: subtakeover -d example.com"
echo "    Local: ./subtakeover.sh -d example.com"
echo ""
echo -e "${BLUE}[+] Quick test:${NC}"
echo "    subtakeover -h  (to see help)"
echo ""
echo -e "${BLUE}[+] Available tools:${NC}"
for tool in subfinder dnsx httpx subzy nuclei; do
    if command -v "$tool" &> /dev/null; then
        echo -e "    ${GREEN}✓${NC} $tool"
    else
        echo -e "    ${RED}✗${NC} $tool"
    fi
done
echo "=============================================="
