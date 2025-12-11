#!/bin/bash
# Enhanced Subdomain Takeover Automation
# Created by Varun Sulakhe
# Usage: subtakeover -d target.com [-t templates_path] [-c concurrency]

# Default values
DOMAIN=""
NUCLEI_TEMPLATES="/root/nuclei-templates/http/takeovers/"
CONCURRENCY=20
OUTPUT_DIR=""
TOOLS_DIR="/usr/local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to display help
show_help() {
    echo -e "${BOLD}${CYAN}SubTakeover - Subdomain Takeover Scanner${NC}"
    echo -e "${CYAN}Created by: Varun Sulakhe${NC}"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  subtakeover -d domain.com [options]"
    echo "  ./subtakeover.sh -d domain.com [options]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  -d DOMAIN     Target domain (required)"
    echo "  -t PATH       Custom nuclei templates path"
    echo "               (default: /root/nuclei-templates/http/takeovers/)"
    echo "  -c NUMBER     Concurrency level (default: 20)"
    echo "  -h            Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  subtakeover -d example.com"
    echo "  subtakeover -d example.com -c 50"
    echo "  subtakeover -d example.com -t ~/custom-templates/"
    exit 0
}

# Function to check if a command was successful
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "\r    ${GREEN}✓ Completed${NC}"
        return 0
    else
        echo -e "\r    ${RED}✗ Failed${NC}"
        return 1
    fi
}

# Function to clean up temporary files
cleanup() {
    if [ -f "$OUTPUT_DIR/temp_nuclei.txt" ]; then
        rm -f "$OUTPUT_DIR/temp_nuclei.txt"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Parse command line arguments
while getopts "d:t:c:h" opt; do
    case $opt in
        d) DOMAIN="$OPTARG" ;;
        t) NUCLEI_TEMPLATES="$OPTARG" ;;
        c) CONCURRENCY="$OPTARG" ;;
        h) show_help ;;
        \?)
            echo -e "${RED}[!] Invalid option: -$OPTARG${NC}" >&2
            show_help
            ;;
    esac
done

# Validate required arguments
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}[!] Error: Domain is required${NC}"
    echo ""
    show_help
fi

# Validate concurrency (limit to reasonable value)
if [ "$CONCURRENCY" -gt 100 ]; then
    echo -e "${YELLOW}[!] Concurrency reduced to max 100${NC}"
    CONCURRENCY=100
fi

# Set output directory
OUTPUT_DIR="takeover_$DOMAIN"
mkdir -p "$OUTPUT_DIR"

# Display banner
echo -e "${CYAN}"
figlet -f slant "SubTakeover" 2>/dev/null || echo -e "╔══════════════════════════════════════════════╗\n║           SUBDOMAIN TAKEOVER SCANNER          ║\n╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${YELLOW}Created by: Varun Sulakhe${NC}"
echo -e "${BLUE}Target: ${BOLD}$DOMAIN${NC}"
echo -e "${BLUE}Concurrency: $CONCURRENCY${NC}"
echo -e "${BLUE}Output: $OUTPUT_DIR/${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Start scanning
START_TIME=$(date +%s)
echo -e "${GREEN}[+] Starting full subdomain takeover scan on $DOMAIN${NC}"
echo ""

# 1. Subfinder
echo -e "${YELLOW}[1] Running subfinder (all + recursive)...${NC}"
echo -n "    Scanning..."
subfinder -d "$DOMAIN" -all -recursive -silent | tee "$OUTPUT_DIR/subs.txt" 2>/dev/null
check_success

sub_count=$(wc -l < "$OUTPUT_DIR/subs.txt" 2>/dev/null || echo 0)
sub_count=$(echo "$sub_count" | tr -d '[:space:]')
if [ "$sub_count" -eq 0 ]; then
    echo -e "${RED}[!] No subdomains found! Exiting...${NC}"
    exit 1
fi
echo -e "${CYAN}    Found $sub_count subdomains${NC}"
echo -e "${BLUE}───────────────────────────────────────────────${NC}"

# 2. dnsx
echo -e "${YELLOW}[2] Resolving with dnsx (A + CNAME + resp)...${NC}"
echo -n "    Resolving..."
cat "$OUTPUT_DIR/subs.txt" 2>/dev/null | dnsx -a -cname -resp -silent | tee "$OUTPUT_DIR/dnsx.txt" 2>/dev/null
check_success
echo -e "${CYAN}    DNS resolution completed${NC}"
echo -e "${BLUE}───────────────────────────────────────────────${NC}"

# 3. httpx
echo -e "${YELLOW}[3] Probing with httpx (404,403,301,302 + title + tech)...${NC}"
echo -n "    Probing..."
cat "$OUTPUT_DIR/subs.txt" 2>/dev/null | httpx -mc 404,403,302,301 -title -server -tech-detect -cl -status-code -silent | tee "$OUTPUT_DIR/httpx.txt" 2>/dev/null
check_success
echo -e "${CYAN}    HTTP probing completed${NC}"
echo -e "${BLUE}───────────────────────────────────────────────${NC}"

# 4. subzy
echo -e "${YELLOW}[4] Running subzy takeover check...${NC}"
echo -n "    Checking..."
subzy run --targets "$OUTPUT_DIR/subs.txt" --vuln --hide_fails | tee "$OUTPUT_DIR/subzy.txt" 2>&1
check_success

subzy_raw_count=$(grep -c "VULNERABLE" "$OUTPUT_DIR/subzy.txt" 2>/dev/null || echo 0)
subzy_count=$(echo "$subzy_raw_count" | tr -d '[:space:]')
if [ "$subzy_count" -gt 0 ]; then
    echo -e "${CYAN}    Found $subzy_count potential takeover(s)${NC}"
else
    echo -e "${GREEN}    ✓ No takeover vulnerabilities found by subzy${NC}"
fi
echo -e "${BLUE}───────────────────────────────────────────────${NC}"

# 5. nuclei
echo -e "${YELLOW}[5] Running nuclei takeover templates...${NC}"
echo -n "    Scanning..."

# Check if templates directory exists
if [ ! -d "$NUCLEI_TEMPLATES" ]; then
    echo -e "\r    ${YELLOW}[!] Templates directory not found: $NUCLEI_TEMPLATES${NC}"
    echo -e "    ${YELLOW}Using default nuclei takeover tags...${NC}"
    TEMPLATE_OPTION="-tags takeover"
else
    TEMPLATE_OPTION="-t $NUCLEI_TEMPLATES"
fi

# Run nuclei with proper error handling
if [ -s "$OUTPUT_DIR/subs.txt" ]; then
    # Run nuclei and capture both stdout and stderr separately
    nuclei -list "$OUTPUT_DIR/subs.txt" \
        $TEMPLATE_OPTION \
        -silent -duc -c "$CONCURRENCY" \
        -rate-limit 100 \
        -timeout 10 \
        -retries 2 \
        1|tee "$OUTPUT_DIR/nuclei_takeovers.txt" \
        2|tee "$OUTPUT_DIR/nuclei_errors.txt"

    # Check if there were any warnings/errors
    if [ -s "$OUTPUT_DIR/nuclei_errors.txt" ]; then
        # Filter out just warnings about concurrency
        if grep -q "concurrency value is higher than max-host-error" "$OUTPUT_DIR/nuclei_errors.txt"; then
            echo -e "\r    ${YELLOW}⚠ Concurrency adjusted by nuclei${NC}"
        else
            echo -e "\r    ${YELLOW}⚠ Nuclei reported warnings (see nuclei_errors.txt)${NC}"
        fi
    else
        echo -e "\r    ${GREEN}✓ Completed${NC}"
    fi

    # Remove error file if empty
    [ ! -s "$OUTPUT_DIR/nuclei_errors.txt" ] && rm -f "$OUTPUT_DIR/nuclei_errors.txt"
else
    echo -e "\r    ${YELLOW}⚠ No subdomains to scan with nuclei${NC}"
    touch "$OUTPUT_DIR/nuclei_takeovers.txt"
fi

# Check nuclei results
if [ -s "$OUTPUT_DIR/nuclei_takeovers.txt" ]; then
    nuclei_raw_count=$(grep -c "\[takeover\]" "$OUTPUT_DIR/nuclei_takeovers.txt" 2>/dev/null || echo 0)
    nuclei_count=$(echo "$nuclei_raw_count" | tr -d '[:space:]')
    if [ "$nuclei_count" -gt 0 ]; then
        echo -e "${RED}    ⚠ Found $nuclei_count potential takeover(s)!${NC}"
    else
        echo -e "${GREEN}    ✓ No takeover vulnerabilities found by nuclei${NC}"
    fi
else
    echo -e "${GREEN}    ✓ No takeover vulnerabilities found by nuclei${NC}"
fi

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"

# Calculate scan duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Final summary
echo -e "\n${GREEN}[+] Scan complete for $DOMAIN${NC}"
echo -e "${CYAN}[+] Scan duration: ${MINUTES}m ${SECONDS}s${NC}"
echo -e "${CYAN}[+] Subdomains found: $sub_count${NC}"

# Get clean counts
subzy_count=$(grep -c "VULNERABLE" "$OUTPUT_DIR/subzy.txt" 2>/dev/null || echo 0)
subzy_count=$(echo "$subzy_count" | tr -d '[:space:]')
subzy_count=$((subzy_count + 0)) 2>/dev/null || subzy_count=0

nuclei_count=$(grep -c "\[takeover\]" "$OUTPUT_DIR/nuclei_takeovers.txt" 2>/dev/null || echo 0)
nuclei_count=$(echo "$nuclei_count" | tr -d '[:space:]')
nuclei_count=$((nuclei_count + 0)) 2>/dev/null || nuclei_count=0

total_vulns=$((subzy_count + nuclei_count))

# Display results
echo -e "${CYAN}[+] Potential takeovers found: $total_vulns${NC}"

if [ "$total_vulns" -eq 0 ]; then
    echo -e "${GREEN}[✓] No takeover vulnerabilities detected${NC}"
else
    if [ "$subzy_count" -gt 0 ]; then
        echo -e "${YELLOW}[+] Subzy findings ($subzy_count):${NC}"
        grep "VULNERABLE" "$OUTPUT_DIR/subzy.txt" 2>/dev/null | head -3 | while read -r line; do
            vuln_domain=$(echo "$line" | grep -oE 'https?://[^ ]+' || echo "$line")
            echo -e "  ${RED}⚠  ${vuln_domain}${NC}"
        done
        if [ "$subzy_count" -gt 3 ]; then
            echo -e "  ${YELLOW}... and $((subzy_count - 3)) more${NC}"
        fi
    fi

    if [ "$nuclei_count" -gt 0 ]; then
        echo -e "${YELLOW}[+] Nuclei findings ($nuclei_count):${NC}"
        grep "\[takeover\]" "$OUTPUT_DIR/nuclei_takeovers.txt" 2>/dev/null | head -3 | while read -r line; do
            # Extract just the URL/target part
            target=$(echo "$line" | grep -oE 'https?://[^ ]+' || echo "$line" | cut -d' ' -f1)
            echo -e "  ${RED}⚠  ${target}${NC}"
        done
        if [ "$nuclei_count" -gt 3 ]; then
            echo -e "  ${YELLOW}... and $((nuclei_count - 3)) more${NC}"
        fi
    fi
fi

echo -e "\n${GREEN}[+] All results saved in: $OUTPUT_DIR/${NC}"
echo -e "${CYAN}Files created:${NC}"
ls -lh "$OUTPUT_DIR/" 2>/dev/null | grep -E "\.(txt)$" | awk '{print "  • " $9 " (" $5 ")"}' || echo -e "  ${YELLOW}No output files found${NC}"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}[+] Quick analysis:${NC}"
echo -e "  ${CYAN}• Subdomains:${NC} $sub_count"
echo -e "  ${CYAN}• HTTP Live:${NC} $(grep -c "^http" "$OUTPUT_DIR/httpx.txt" 2>/dev/null || echo 0)"
echo -e "  ${CYAN}• 404/403 Responses:${NC} $(grep -c "404\|403" "$OUTPUT_DIR/httpx.txt" 2>/dev/null || echo 0)"
echo -e "  ${CYAN}• Takeover Vulnerabilities:${NC} $total_vulns"
echo -e "${GREEN}────────────────────────────────────────────────${NC}"
