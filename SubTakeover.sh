#!/bin/bash
# Subdomain Takeover Automation (100% your original tools)
# Created by Varun Sulakhe
# Usage: ./takeover.sh target.com

domain="$1"

if [ -z "$domain" ]; then
    echo -e "\e[31m[!] Usage: $0 domain.com\e[0m"
    exit 1
fi

# Display banner
echo -e "\e[36m"
figlet -f slant "SubTakeover" 2>/dev/null || echo -e "╔══════════════════════════════════════════════╗\n║           SUBDOMAIN TAKEOVER SCANNER          ║\n╚══════════════════════════════════════════════╝"
echo -e "\e[0m"
echo -e "\e[33mCreated by: Varun Sulakhe\e[0m"
echo -e "\e[90m═══════════════════════════════════════════════\e[0m"
echo ""

echo -e "\e[34m[+] Starting full subdomain takeover scan on $domain\e[0m"
echo -e "\e[34m[+] Results will be saved in ./takeover_$domain/\e[0m\n"
mkdir -p "takeover_$domain"

echo -e "\e[90m═══════════════════════════════════════════════\e[0m"

# 1. Subfinder
echo -e "\e[33m[1] Running subfinder (all + recursive)...\e[0m"
subfinder -d $domain -all -recursive -silent | tee "takeover_$domain/subs.txt"

sub_count=$(wc -l < "takeover_$domain/subs.txt" 2>/dev/null || echo 0)
sub_count=$(echo "$sub_count" | tr -d '[:space:]')
if [ "$sub_count" -eq 0 ]; then
    echo -e "\e[31m[!] No subdomains found! Exiting...\e[0m"
    exit 1
fi
echo -e "\e[36m    Found $sub_count subdomains\e[0m"

echo -e "\e[90m───────────────────────────────────────────────\e[0m"

# 2. dnsx
echo -e "\e[33m[2] Resolving with dnsx (A + CNAME + resp)...\e[0m"
cat "takeover_$domain/subs.txt" | dnsx -a -cname -resp -silent | tee "takeover_$domain/dnsx.txt"
echo -e "\e[36m    DNS resolution completed\e[0m"

echo -e "\e[90m───────────────────────────────────────────────\e[0m"

# 3. httpx
echo -e "\e[33m[3] Probing with httpx (404,403,301,302 + title + tech)...\e[0m"
cat "takeover_$domain/subs.txt" | httpx -mc 404,403,302,301 -title -server -tech-detect -cl -status-code -silent | tee "takeover_$domain/httpx.txt"
echo -e "\e[36m    HTTP probing completed\e[0m"

echo -e "\e[90m───────────────────────────────────────────────\e[0m"

# 4. subzy
echo -e "\e[33m[4] Running subzy takeover check...\e[0m"
subzy run --targets "takeover_$domain/subs.txt" --vuln --hide_fails | tee "takeover_$domain/subzy.txt"

# Check subzy results
subzy_raw_count=$(grep -c "VULNERABLE" "takeover_$domain/subzy.txt" 2>/dev/null || echo 0)
subzy_count=$(echo "$subzy_raw_count" | tr -d '[:space:]')
if [ "$subzy_count" -gt 0 ]; then
    echo -e "\e[36m    Found $subzy_count potential takeover(s)\e[0m"
else
    echo -e "\e[32m    ✓ No takeover vulnerabilities found by subzy\e[0m"
fi

echo -e "\e[90m───────────────────────────────────────────────\e[0m"

# 5. nuclei
echo -e "\e[33m[5] Running nuclei takeover templates...\e[0m"
echo -n "    Scanning..."
nuclei_output=$(nuclei -list "takeover_$domain/subs.txt" \
        -t /root/nuclei-templates/http/takeovers/ \
        -silent -duc -c 20 2>&1)

echo "$nuclei_output" > "takeover_$domain/nuclei_takeovers.txt"

if [ -z "$nuclei_output" ] || echo "$nuclei_output" | grep -qi "no results\|no matches\|0 results\|WRN\|ERR"; then
    echo -e "\r    \e[32m✓ No takeover vulnerabilities found by nuclei\e[0m"
elif echo "$nuclei_output" | grep -qi "\[takeover\]"; then
    nuclei_raw_count=$(echo "$nuclei_output" | grep -c "\[takeover\]" 2>/dev/null || echo 0)
    nuclei_count=$(echo "$nuclei_raw_count" | tr -d '[:space:]')
    echo -e "\r    \e[31m⚠ Found $nuclei_count potential takeover(s)!\e[0m"
else
    echo -e "\r    \e[32m✓ No takeover vulnerabilities found by nuclei\e[0m"
fi

echo -e "\e[90m═══════════════════════════════════════════════\e[0m"

# Final summary
echo -e "\n\e[32m[+] Scan complete for $domain\e[0m"
echo -e "\e[36m[+] Subdomains found: $sub_count\e[0m"

# Get clean counts (removing all whitespace)
subzy_count=$(grep -c "VULNERABLE" "takeover_$domain/subzy.txt" 2>/dev/null || echo 0)
subzy_count=$(echo "$subzy_count" | tr -d '[:space:]')
subzy_count=$((subzy_count + 0)) 2>/dev/null || subzy_count=0

nuclei_count=$(grep -c "\[takeover\]" "takeover_$domain/nuclei_takeovers.txt" 2>/dev/null || echo 0)
nuclei_count=$(echo "$nuclei_count" | tr -d '[:space:]')
nuclei_count=$((nuclei_count + 0)) 2>/dev/null || nuclei_count=0

# Display results
echo -e "\e[36m[+] Potential takeovers (subzy): $subzy_count\e[0m"
if [ "$subzy_count" -gt 0 ]; then
    grep "VULNERABLE" "takeover_$domain/subzy.txt" | while read line; do
        echo -e "  \e[31m⚠  $(echo "$line" | cut -d']' -f2-)\e[0m"
    done
fi

echo ""  # Add space between sections

echo -e "\e[36m[+] Potential takeovers (nuclei): $nuclei_count\e[0m"
if [ "$nuclei_count" -gt 0 ]; then
    grep "\[takeover\]" "takeover_$domain/nuclei_takeovers.txt" | head -5 | while read line; do
        echo -e "  \e[31m⚠  $line\e[0m"
    done
    if [ "$nuclei_count" -gt 5 ]; then
        echo -e "  \e[33m... and $((nuclei_count - 5)) more\e[0m"
    fi
elif [ "$nuclei_count" -eq 0 ]; then
    echo -e "  \e[32m✓ No vulnerabilities found\e[0m"
fi

echo -e "\n\e[32m[+] All results saved in: takeover_$domain/\e[0m"
echo -e "\e[36mFiles created:\e[0m"
ls -lh "takeover_$domain/" | grep -E "\.(txt)$" | awk '{print "  • " $9 " (" $5 ")"}'
echo -e "\e[32m────────────────────────────────────────────────\e[0m"