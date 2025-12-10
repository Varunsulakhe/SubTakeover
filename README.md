# SubTakeover 🔍
### Automated Subdomain Takeover Detection Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/yourusername/SubTakeover.svg)](https://github.com/yourusername/SubTakeover/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/yourusername/SubTakeover.svg)](https://github.com/yourusername/SubTakeover/issues)

**Created by Varun Sulakhe**

A powerful automation script that combines multiple security tools to detect subdomain takeover vulnerabilities efficiently.

## 🚀 Features

- **Complete Automation**: Single command to run entire takeover detection pipeline
- **Multiple Tool Integration**: Uses 5 specialized security tools
- **Smart Filtering**: Focuses on relevant HTTP status codes (404, 403, 301, 302)
- **Comprehensive Output**: Saves all results in organized directories
- **Color-coded Results**: Easy-to-read terminal output
- **Error Handling**: Graceful handling of edge cases

## 🛠️ Tools Used

This automation integrates the following security tools:

1. **Subfinder** - Subdomain enumeration
2. **dnsx** - DNS resolution and CNAME extraction
3. **httpx** - HTTP probing with technology detection
4. **subzy** - Subdomain takeover detection
5. **nuclei** - Vulnerability scanning with takeover templates

## 📦 Installation

### Prerequisites
- Go 1.17+ installed
- Basic terminal knowledge

### Quick Install
```bash
# Clone the repository
git clone https://github.com/Varunsulakhe/SubTakeover.git
cd SubTakeover

# Install dependencies
chmod +x install.sh

./install.sh
