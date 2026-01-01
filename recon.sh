#!/bin/bash
set -eo pipefail

# =============================
# INPUT VALIDATION
# =============================
if [ $# -lt 1 ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

# Normalize target (remove scheme)
TARGET=$(echo "$1" | sed -E 's#https?://##g' | tr -d '/')
OUTDIR="/recon/output/$TARGET"

mkdir -p "$OUTDIR"

echo "[+] Target      : $TARGET"
echo "[+] Output Dir  : $OUTDIR"
echo "[+] Started at  : $(date)"
echo

# =============================
# 1. SUBDOMAIN ENUMERATION
# =============================
echo "[*] Running Subfinder..."
subfinder -d "$TARGET" -silent -o "$OUTDIR/subfinder.txt" || true

echo "[*] Running Amass (passive)..."
amass enum -passive -d "$TARGET" -o "$OUTDIR/amass.txt" || true

cat "$OUTDIR/"*.txt 2>/dev/null | sort -u > "$OUTDIR/all-subs.txt"
echo "[+] Total subdomains: $(wc -l < "$OUTDIR/all-subs.txt" 2>/dev/null || echo 0)"
echo

# =============================
# 2. DNS RESOLUTION (FIXED)
# =============================
echo "[*] Resolving subdomains (puredns)..."

if command -v massdns >/dev/null 2>&1 && [[ -s "$OUTDIR/all-subs.txt" ]]; then
  puredns resolve "$OUTDIR/all-subs.txt" \
    --quiet \
    -w "$OUTDIR/resolved.txt" || touch "$OUTDIR/resolved.txt"
else
  echo "[!] massdns not found or no subdomains — skipping resolution"
  touch "$OUTDIR/resolved.txt"
fi

# =============================
# 3. LIVE HOST CHECK
# =============================
echo "[*] Checking live hosts (httpx)..."

if [[ -s "$OUTDIR/resolved.txt" ]]; then
  httpx -l "$OUTDIR/resolved.txt" \
    -silent \
    -status-code \
    -title \
    -tech-detect \
    -o "$OUTDIR/live.txt" || touch "$OUTDIR/live.txt"
else
  echo "[!] No resolved hosts — skipping httpx"
  touch "$OUTDIR/live.txt"
fi

cut -d ' ' -f1 "$OUTDIR/live.txt" 2>/dev/null > "$OUTDIR/live-urls.txt" || true
echo "[+] Live hosts: $(wc -l < "$OUTDIR/live-urls.txt" 2>/dev/null || echo 0)"
echo

# =============================
# 4. URL COLLECTION
# =============================
echo "[*] Collecting URLs (gau)..."
gau --subs "$TARGET" 2>/dev/null | sort -u > "$OUTDIR/gau.txt" || touch "$OUTDIR/gau.txt"

echo "[*] Crawling (katana)..."
if [[ -s "$OUTDIR/live-urls.txt" ]]; then
  katana -list "$OUTDIR/live-urls.txt" -silent -o "$OUTDIR/katana.txt" || touch "$OUTDIR/katana.txt"
else
  echo "[!] No live hosts found — skipping katana"
  touch "$OUTDIR/katana.txt"
fi

cat "$OUTDIR/gau.txt" "$OUTDIR/katana.txt" 2>/dev/null | sort -u > "$OUTDIR/all-urls.txt"
echo "[+] Total URLs: $(wc -l < "$OUTDIR/all-urls.txt" 2>/dev/null || echo 0)"
echo

# =============================
# 5. PARAM DISCOVERY (FIXED)
# =============================
echo "[*] Running ParamSpider..."

if [[ -s "$OUTDIR/live-urls.txt" ]]; then
  sed 's~https\?://~~' "$OUTDIR/live-urls.txt" | \
  cut -d/ -f1 | \
  sort -u | \
  while read -r d; do
    paramspider -d "$d"
  done > "$OUTDIR/paramspider.txt" 2>/dev/null || true
else
  echo "[!] No live URLs — skipping ParamSpider"
  touch "$OUTDIR/paramspider.txt"
fi

# =============================
# 6. GF PATTERN MATCHING
# =============================
echo "[*] Running GF patterns..."
mkdir -p "$OUTDIR/gf"

if [[ -s "$OUTDIR/all-urls.txt" ]]; then
  for pattern in xss sqli lfi rce ssrf redirect idor; do
    gf "$pattern" "$OUTDIR/all-urls.txt" > "$OUTDIR/gf/$pattern.txt" || true
  done
else
  echo "[!] No URLs for GF matching"
fi

# =============================
# 7. HAKRAWLER (FIXED)
# =============================
echo "[*] Running Hakrawler..."

if [[ -s "$OUTDIR/live-urls.txt" ]]; then
  cat "$OUTDIR/live-urls.txt" | \
  hakrawler -d 2 -u > "$OUTDIR/hakrawler.txt" || true
else
  echo "[!] No live URLs for hakrawler"
  touch "$OUTDIR/hakrawler.txt"
fi


# =============================
# DONE
# =============================
echo
echo "[✔] Recon completed!"
echo "[✔] Results saved in $OUTDIR"
echo "[✔] Finished at $(date)"
