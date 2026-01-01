# Recon Docker Framework

A **Dockerized automated reconnaissance framework** for web security testing.  
This project consolidates industry‑standard recon tools into a single, repeatable workflow driven by `recon.sh`.

Designed for **bug bounty hunting**, **penetration testing**, and **attack surface mapping**.

---

## Overview

Recon Docker automates the following phases:

1. Subdomain enumeration  
2. DNS resolution  
3. Live host discovery  
4. URL collection & crawling  
5. Parameter discovery  
6. Vulnerability pattern matching  
7. Deep crawling

All results are stored in a structured output directory per target.

---

## Toolchain

| Category | Tools |
|--------|------|
| Subdomain Enumeration | `subfinder`, `amass (passive)` |
| DNS Resolution | `puredns` + `massdns` |
| Live Host Detection | `httpx` |
| URL Collection | `gau`, `katana` |
| Parameter Discovery | `ParamSpider` |
| Pattern Matching | `gf` (xss, sqli, lfi, rce, ssrf, redirect, idor) |
| Crawling | `hakrawler` |

---

## Requirements

- Docker 20.10+
- Linux / macOS / Windows (WSL2 recommended)
- Internet access

---

## Installation

### Clone Repository
```bash
git clone https://github.com/<your-username>/recon-docker.git
cd recon-docker
```

**Build Docker Image**
```bash
docker build -t recon-docker .
```

**Usage**
```bash
docker run -it --rm recon-docker ./recon.sh example.com
```

**URL Input Examples**
```bash
./recon.sh example.com
./recon.sh https://example.com
```

**Output Structure**
```bash
/recon/output/example.com/
│
├── subfinder.txt
├── amass.txt
├── all-subs.txt
├── resolved.txt
├── live.txt
├── live-urls.txt
├── gau.txt
├── katana.txt
├── all-urls.txt
├── paramspider.txt
├── hakrawler.txt
└── gf/
    ├── xss.txt
    ├── sqli.txt
    ├── lfi.txt
    ├── rce.txt
    ├── ssrf.txt
    ├── redirect.txt
    └── idor.txt
```
**Script Logic (recon.sh)**
```bash
1. Validate input
2. Enumerate subdomains
3. Resolve DNS using puredns
4. Identify live hosts via httpx
5. Collect URLs (gau + katana)
6. Discover parameters with ParamSpider
7. Run GF vulnerability patterns
8. Crawl endpoints using Hakrawler
```
**Each stage fails gracefully and continues execution.**

**Important Notes**

>puredns requires massdns in $PATH
>Katana only runs if live hosts are found
>ParamSpider runs per resolved domain to avoid invalid input
>Hakrawler flags are updated to match current official releases
>GF patterns must exist in:
```bash
~/.gf/
```
**Customization**
Modify crawl depth or threads inside recon.sh:
```bash
katana -list live-urls.txt -silent
hakrawler -depth 2
```
**Add or remove GF patterns as needed:**
```bash
for pattern in xss sqli lfi rce ssrf redirect idor; do
```
**Legal Disclaimer**

This project is intended for **authorized security testing and educational purposes only.**
The author is **not responsible** for misuse or illegal activities.

Author

Nahid
Security Researcher | Recon | Pentester
GitHub: https://github.com/fumioryoto
