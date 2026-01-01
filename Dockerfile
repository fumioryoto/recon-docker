# ================================
# Recon Automation Docker Image
# ================================
FROM golang:1.24-alpine

# ================================
# Environment
# ================================
ENV VENV_PATH=/opt/venv
ENV PATH="/go/bin:/opt/venv/bin:/root/.gf:$PATH"

# ================================
# System Dependencies
# ================================
RUN apk add --no-cache \
    bash \
    git \
    python3 \
    py3-virtualenv \
    build-base \
    curl \
    ca-certificates \
    bind-tools \
    jq

# ================================
# Python Virtual Environment (PEP 668 SAFE)
# ================================
RUN python3 -m venv $VENV_PATH

# ================================
# ParamSpider (Python)
# ================================
RUN git clone https://github.com/devanshbatham/ParamSpider /opt/paramspider && \
    cd /opt/paramspider && \
    $VENV_PATH/bin/pip install --no-cache-dir .

# ================================
# Go Recon Tools
# ================================
RUN go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install github.com/projectdiscovery/katana/cmd/katana@latest && \
    go install github.com/lc/gau/v2/cmd/gau@latest && \
    go install github.com/tomnomnom/httprobe@latest && \
    go install github.com/tomnomnom/waybackurls@latest && \
    go install github.com/hakluke/hakrawler@latest && \
    go install github.com/tomnomnom/gf@latest && \
    go install github.com/owasp-amass/amass/v4/...@latest

# ================================
# MassDNS (REQUIRED for puredns)
# ================================
RUN git clone https://github.com/blechschmidt/massdns.git /opt/massdns && \
    cd /opt/massdns && \
    make && \
    mv bin/massdns /usr/local/bin/massdns


# ================================
# ================================
# GF Patterns (using 1ndianl33t/Gf-Patterns)
# ================================
RUN mkdir -p /root/.gf && \
    git clone https://github.com/1ndianl33t/Gf-Patterns.git /root/.gf


# ================================
# PureDNS
# ================================
RUN git clone https://github.com/d3mondev/puredns.git /opt/puredns && \
    cd /opt/puredns && \
    go build && \
    mv puredns /usr/local/bin

# ================================
# PureDNS Resolvers
# ================================
RUN mkdir -p /root/.config/puredns
COPY resolvers.txt /root/.config/puredns/resolvers.txt


# ================================
# Cleanup
# ================================
RUN rm -rf /var/cache/apk/* /tmp/* /opt/puredns /opt/paramspider


# ================================
# ================================
# Workspace
# ================================
WORKDIR /recon

# Copy recon.sh into the container and make it executable
COPY recon.sh /recon/recon.sh
RUN chmod +x /recon/recon.sh

CMD ["/bin/bash"]

# ================================
