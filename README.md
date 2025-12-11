 🔥 SubTakeover - Ultimate Subdomain Takeover Scanner

One-liner to find takeover vulnerabilities | *Created by Varun Sulakhe*

subtakeover -d target.com -c 50   Finds vulnerable subdomains in minutes


 🚀 Quick Start

 Clone & Install (30 seconds)
git clone https://github.com/varunsulakhe/SubTakeover.git
cd SubTakeover && chmod +x *.sh && sudo ./install.sh

 Basic Scan
subtakeover -d target.com

 Fast Scan
subtakeover -d bugcrowd.com -c 75

 With Custom Templates
subtakeover -d hackerone.com -t ~/nuclei-templates/

 ⚡ Features

✅ 5-in-1 Toolchain - subfinder → dnsx → httpx → subzy → nuclei  
✅ Real-time Results - See vulnerabilities as they're found  
✅ Smart Filtering - Focuses on 404/403 pages (common takeover vectors)  
✅ Color-coded Output - Instant visual risk assessment  
✅ Portable - Works anywhere with Go installed  
✅ Professional Reports - Clean, organized output directories  

 🎯 Usage

 Required
subtakeover -d target.com

 Advanced
subtakeover -d target.com -c 100 -t /custom/templates/

 Help
subtakeover -h

| Flag | Description | Default |
|------|-------------|---------|
| `-d` | Target domain (required) | - |
| `-c` | Concurrency (speed) | 20 |
| `-t` | Nuclei templates path | `/root/nuclei-templates/` |
| `-h` | Show help | - |

 📊 Sample Output

![SubTakeover Demo](https://img.shields.io/badge/DEMO-Interactive_Scan-blue)

╔══════════════════════════════════════════════╗
║           SUBDOMAIN TAKEOVER SCANNER         ║
╚══════════════════════════════════════════════╝
Target: github.com | Concurrency: 50 | Time: 00:45

[1] 🔍 subfinder       → 342 subdomains found
[2] 📡 dnsx            → 298 resolved (87% live)
[3] 🌐 httpx           → 45 potential 404/403 pages
[4] ⚡ subzy           → 0 takeovers found
[5] 💣 nuclei          → 2 critical takeovers!

🚨 CRITICAL FINDINGS:
  • azure.github.io [Azure Storage]
  • s3-assets.github.com [AWS S3 Bucket]

📁 Results: takeover_github.com/ (5 files)
⏱️  Scan time: 45 seconds

 🛠️ Installation

 Automatic (Recommended)

curl -sL https://raw.githubusercontent.com/varunsulakhe/SubTakeover/main/install.sh | sudo bash

 Manual

 1. Install Go tools
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/PentestPad/subzy@latest
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

 2. Download script
wget https://raw.githubusercontent.com/varunsulakhe/SubTakeover/main/subtakeover.sh
chmod +x subtakeover.sh && sudo mv subtakeover.sh /usr/local/bin/subtakeover

 📁 Output Structure

takeover_target.com/
├── subs.txt               All subdomains
├── httpx.txt              Live hosts + status codes  
├── subzy.txt              Subzy findings
├── nuclei_takeovers.txt   Nuclei takeover matches
└── scan_report.md         Summary report

 🎨 Color Guide

| Color | Meaning | Example |
|-------|---------|---------|
| 🔴 RED | Critical vulnerability | `[TAKEOVER] AWS S3 bucket` |
| 🟡 YELLOW | Warning/Info | `[WARN] High concurrency` |
| 🟢 GREEN | Success/Safe | `✓ No vulnerabilities` |
| 🔵 BLUE | Information | `Found 250 subdomains` |
| 🌈 CYAN | Statistics | `Scan time: 2m 15s` |

 ⚡ Performance Tips

 For bug bounty (fast)
subtakeover -d target.com -c 100

 For thorough audit (slow)
subtakeover -d target.com -c 20

 Batch scanning
for domain in $(cat targets.txt); do
    subtakeover -d $domain -c 30 &
done

 🔧 Customization

 Add Custom Templates

git clone https://github.com/projectdiscovery/nuclei-templates
subtakeover -d target.com -t ~/nuclei-templates/http/takeovers/


 Modify Defaults
Edit `subtakeover.sh`:

CONCURRENCY=50   Change default speed
NUCLEI_TEMPLATES="$HOME/templates/"   Change template path


 🐛 Troubleshooting


 "Command not found"
export PATH=$PATH:$HOME/go/bin

 "Permission denied"
sudo chmod +x /usr/local/bin/subtakeover

 Nuclei warnings
nuclei -update-templates

 Slow scanning
subtakeover -d target.com -c 10   Reduce concurrency


 📋 Requirements

- Go 1.19+ (`go version`)
- Internet connection (for API-based enumeration)
- 2GB+ RAM (for large scopes)

 ⚠️ Legal & Ethics

USE RESPONSIBLY! Only scan:
- Your own assets
- Authorized bug bounty programs
- Systems with written permission

 🤝 Contributing

Found a bug? Want a feature?

 1. Fork repo
 2. Create branch: feature/awesome
 3. Commit changes
 4. Push & PR

 📞 Support

- Issues: [GitHub](https://github.com/varunsulakhe/SubTakeover/issues)
- Twitter: [@varunsulakhe](https://twitter.com/varunsulakhe)

🔥 Pro Tip: Combine with other tools for maximum coverage:

 Chain with other recon tools
assetfinder target.com | subtakeover -d

Star ⭐ the repo if this tool helps you find critical vulnerabilities!

