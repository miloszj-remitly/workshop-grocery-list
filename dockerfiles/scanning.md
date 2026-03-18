# Docker Image Security Scanning Guide

This guide demonstrates how to scan the Docker images we created using **Docker Scout** and **Grype** to identify vulnerabilities and security issues.

---

## 🔍 Why Scan Images?

- **Identify vulnerabilities** in base images and dependencies
- **Detect outdated packages** with known CVEs
- **Compare security** across different Dockerfile approaches
- **Meet compliance** requirements for production deployments
- **Shift-left security** - catch issues before production

---

## 🛡️ Tool 1: Docker Scout

Docker Scout is Docker's official vulnerability scanning tool, integrated into Docker Desktop and CLI.

### Installation

Docker Scout is included with Docker Desktop 4.17+. For CLI:

```bash
# Check if Docker Scout is available
docker scout version

# If not installed, install the plugin
curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh -s --
```

### Basic Usage

#### 1. Quick Vulnerability Scan

```bash
# Scan the simple fat image
docker scout cves grocery-app:fat

# Scan the multi-stage image
docker scout cves grocery-app:multi-stage

# Scan the production-ready image
docker scout cves grocery-app:production

# Scan the distroless image
docker scout cves grocery-app:distroless

# Scan the scratch image
docker scout cves grocery-app:scratch
```

#### 2. Compare Images

```bash
# Compare fat vs multi-stage
docker scout compare grocery-app:fat --to grocery-app:multi-stage

# Compare multi-stage vs distroless
docker scout compare grocery-app:multi-stage --to grocery-app:distroless

# Compare all against production-ready
docker scout compare grocery-app:fat --to grocery-app:production
```

#### 3. Detailed CVE Report

```bash
# Get detailed CVE information
docker scout cves --format sarif --output scout-report.json grocery-app:production

# Only show critical and high severity
docker scout cves --only-severity critical,high grocery-app:production

# Show only fixable vulnerabilities
docker scout cves --only-fixed grocery-app:production
```

#### 4. Recommendations

```bash
# Get recommendations for base image updates
docker scout recommendations grocery-app:multi-stage

# Quick health score
docker scout quickview grocery-app:production
```

#### 5. Policy Evaluation

```bash
# Evaluate against Docker Scout policies
docker scout policy grocery-app:production

# Check if image meets policy requirements
docker scout policy --exit-code grocery-app:production
```

### Example: Scan All Our Images

```bash
#!/bin/bash
# scan-all-scout.sh

echo "Building all images..."
docker build -f dockerfiles/01-simple-fat.Dockerfile -t grocery-app:fat .
docker build -f dockerfiles/02-layer-caching.Dockerfile -t grocery-app:cached .
docker build -f dockerfiles/03-multi-stage.Dockerfile -t grocery-app:multi-stage .
docker build -f dockerfiles/04-distroless.Dockerfile -t grocery-app:distroless .
docker build -f dockerfiles/05-scratch.Dockerfile -t grocery-app:scratch .
docker build -f dockerfiles/06-production-ready.Dockerfile -t grocery-app:production .

echo -e "\n=== Scanning with Docker Scout ===\n"

for tag in fat cached multi-stage distroless scratch production; do
    echo "--- Scanning grocery-app:$tag ---"
    docker scout cves --only-severity critical,high grocery-app:$tag
    echo ""
done

echo -e "\n=== Comparison Report ===\n"
docker scout compare grocery-app:fat --to grocery-app:production
```

---

## 🔎 Tool 2: Grype

Grype is an open-source vulnerability scanner by Anchore, known for comprehensive CVE detection.

### Installation

```bash
# macOS
brew install grype

# Linux
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Or using Docker
docker run --rm anchore/grype version
```

### Basic Usage

#### 1. Scan Docker Images

```bash
# Scan the simple fat image
grype grocery-app:fat

# Scan the multi-stage image
grype grocery-app:multi-stage

# Scan the production-ready image
grype grocery-app:production

# Scan the distroless image
grype grocery-app:distroless

# Scan the scratch image
grype grocery-app:scratch
```

#### 2. Filter by Severity

```bash
# Only critical vulnerabilities
grype grocery-app:production --fail-on critical

# Critical and high only
grype grocery-app:production --only-fixed --severity critical,high

# Exclude low severity
grype grocery-app:production --severity medium,high,critical
```

#### 3. Output Formats

```bash
# JSON output
grype grocery-app:production -o json > grype-report.json

# Table format (default)
grype grocery-app:production -o table

# SARIF format (for GitHub/GitLab integration)
grype grocery-app:production -o sarif > grype-sarif.json

# CycloneDX SBOM
grype grocery-app:production -o cyclonedx-json > sbom.json

# Template output
grype grocery-app:production -o template -t custom-template.tmpl
```

#### 4. Scan with SBOM

```bash
# Generate SBOM first with Syft
syft grocery-app:production -o json > sbom.json

# Scan the SBOM
grype sbom:sbom.json
```

#### 5. Advanced Filtering

```bash
# Only show fixed vulnerabilities
grype grocery-app:production --only-fixed

# Exclude specific vulnerabilities
grype grocery-app:production --exclude CVE-2023-1234

# Use ignore file
grype grocery-app:production --exclude-file .grype-ignore.yaml
```

### Example: Scan All Our Images

```bash
#!/bin/bash
# scan-all-grype.sh

echo "Building all images..."
docker build -f dockerfiles/01-simple-fat.Dockerfile -t grocery-app:fat .
docker build -f dockerfiles/02-layer-caching.Dockerfile -t grocery-app:cached .
docker build -f dockerfiles/03-multi-stage.Dockerfile -t grocery-app:multi-stage .
docker build -f dockerfiles/04-distroless.Dockerfile -t grocery-app:distroless .
docker build -f dockerfiles/05-scratch.Dockerfile -t grocery-app:scratch .
docker build -f dockerfiles/06-production-ready.Dockerfile -t grocery-app:production .

echo -e "\n=== Scanning with Grype ===\n"

for tag in fat cached multi-stage distroless scratch production; do
    echo "--- Scanning grocery-app:$tag ---"
    grype grocery-app:$tag --only-fixed --severity critical,high
    echo ""
done
```

---

## 📊 Comparison Script

Compare vulnerability counts across all images:

```bash
#!/bin/bash
# compare-vulnerabilities.sh

echo "Image Vulnerability Comparison"
echo "==============================="
echo ""

for tag in fat cached multi-stage distroless scratch production; do
    echo "grocery-app:$tag"
    
    # Docker Scout count
    scout_count=$(docker scout cves grocery-app:$tag 2>/dev/null | grep -c "CVE-" || echo "N/A")
    
    # Grype count
    grype_count=$(grype grocery-app:$tag -q 2>/dev/null | wc -l || echo "N/A")
    
    echo "  Docker Scout: $scout_count CVEs"
    echo "  Grype: $grype_count vulnerabilities"
    echo ""
done
```

---

## 🎯 Expected Results

Based on our Dockerfile examples, you should see:

| Image | Expected Vulnerabilities | Reason |
|-------|-------------------------|---------|
| `fat` | **HIGH** (100+) | Contains full Go toolchain, build tools |
| `cached` | **HIGH** (100+) | Same as fat, just better caching |
| `multi-stage` | **LOW** (5-20) | Only runtime dependencies |
| `distroless` | **VERY LOW** (0-5) | Minimal Google-maintained base |
| `scratch` | **MINIMAL** (0-2) | Only your binary + CA certs |
| `production` | **LOW** (5-20) | Alpine runtime with minimal packages |

---

## 🔧 Integration Examples

### CI/CD Pipeline (GitHub Actions)

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build image
        run: docker build -f dockerfiles/06-production-ready.Dockerfile -t grocery-app:production .
      
      - name: Scan with Docker Scout
        uses: docker/scout-action@v1
        with:
          command: cves
          image: grocery-app:production
          only-severities: critical,high
          exit-code: true
      
      - name: Scan with Grype
        uses: anchore/scan-action@v3
        with:
          image: grocery-app:production
          fail-build: true
          severity-cutoff: high
```

### GitLab CI

```yaml
security_scan:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -f dockerfiles/06-production-ready.Dockerfile -t grocery-app:production .
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/grype:latest grocery-app:production --fail-on critical
```

---

## 📝 Best Practices

1. **Scan regularly** - Vulnerabilities are discovered daily
2. **Scan in CI/CD** - Catch issues before production
3. **Use multiple tools** - Different tools find different vulnerabilities
4. **Prioritize fixes** - Focus on critical/high severity first
5. **Update base images** - Keep base images current
6. **Monitor production** - Continuously scan running images
7. **Use minimal bases** - Fewer packages = fewer vulnerabilities

---

## 🚀 Quick Start

```bash
# 1. Build an image
docker build -f dockerfiles/06-production-ready.Dockerfile -t grocery-app:production .

# 2. Scan with Docker Scout
docker scout cves grocery-app:production

# 3. Scan with Grype
grype grocery-app:production

# 4. Compare with a less secure version
docker build -f dockerfiles/01-simple-fat.Dockerfile -t grocery-app:fat .
docker scout compare grocery-app:fat --to grocery-app:production
```

---

## 📚 Additional Resources

- [Docker Scout Documentation](https://docs.docker.com/scout/)
- [Grype GitHub](https://github.com/anchore/grype)
- [CVE Database](https://cve.mitre.org/)
- [Snyk Vulnerability Database](https://security.snyk.io/)

