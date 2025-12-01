# Habitat 2.0 Testing Guide

## Overview

This guide provides step-by-step instructions for Testing of Habitat 2.0 RC builds with on-prem-builder. It covers the complete testing workflow from infrastructure setup to custom package development.


## Prerequisites

Before starting the testing, ensure you have:

- [ ] Linux x86_64 system (minimum: 2 CPUs, 4GB RAM, 100GB disk)
- [ ] Valid Progress Chef license key for Habitat 2.0
- [ ] Public builder authentication token
- [ ] OAuth provider configured (GitHub, Azure AD, etc.)
- [ ] Network connectivity to bldr.habitat.sh

## Supported Architectures & Channels

**Architectures:**
- `x86_64-linux` (Intel/AMD 64-bit Linux)
- `aarch64-linux` (ARM64 Linux)
- `x86_64-windows` (Intel/AMD 64-bit Windows)

**Channels:**
- `base` - Core packages for Habitat 2.0
- `hab-2-rc1` - Chef-specific Habitat 2.0 RC packages
- `stable` - Habitat 1.x packages (for upgrade testing)

---

## Scenario 1: Setup Standard On-Prem Builder Instance

**Objective:** Setup a standard Habitat on-prem instance on linux-x86_64

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPUs | 2 | 4+ |
| RAM | 4GB | 8GB+ |
| Disk | 50GB | 100GB+ |
| OS | Linux x86_64 with systemd | Ubuntu 20.04+ or RHEL 8+ |

**Reference:** [Detailed system requirements](./docs-chef-io/content/habitat/on_prem_builder/install/system_requirements.md)

### Step 1: Clone Repository

```bash
git clone https://github.com/habitat-sh/on-prem-builder.git
cd on-prem-builder
```

### Step 2: Configure OAuth Provider

Before installation, setup a 3rd-party OAuth provider for authentication:

**Reference:** [OAuth setup guide](./docs-chef-io/content/habitat/on_prem_builder/install/builder_oauth.md#before-you-begin)

**Supported providers:** GitHub, Azure AD, GitLab, Okta, Bitbucket

### Step 3: Configure Environment

```bash
cp bldr.env.sample bldr.env
# Edit bldr.env with your OAuth and system configuration
# Also add your HAB_AUTH_TOKEN for public builder
```

📖 **Reference:** [Configuration guide](./docs-chef-io/content/habitat/on_prem_builder/install/builder_oauth.md#configure-chef-habitat-on-prem-builder)

### Step 4: Install

```bash
./install.sh
```

### Verification

Check that all services are running:

```bash
sudo hab svc status
```

**Expected output:** 5 services should be `UP`:
- `habitat/builder-api`
- `habitat/builder-datastore` 
- `habitat/builder-memcached`
- `habitat/builder-api-proxy`
- `habitat/builder-minio`

---

## Scenario 2: Sync Packages from Public Builder

**Objective:** Use sync tool to sync `base` core packages and `hab-2-rc1` chef packages from SaaS to the on-prem instance

### Step 1: Generate Private Builder Token

Create a personal access token for your on-prem builder:

📖 **Reference:** [Create personal access token](https://docs.chef.io/habitat/builder_profile/#create-a-personal-access-token)

### Step 2: Install pkg-sync Tool

```bash
sudo hab pkg install habitat/pkg-sync
```

### Step 3: Enable native package support
The habitat packages are now built with updated dependencies from the `base` channel instead of the `stable` channel. 
Some of these package dependencies include `native` packages. 
In order for an on-prem builder instance to host the latest released habitat packages including these native package dependencies, 
that builder instance must be configured to allow native package support. 
This is done by enabling the `nativepackages` feature and specifying `core` as an allowed native package origin. 
To do this, an on-prem builder's `/hab/user/builder-api/config/user.toml` file should be edited so that the `[api]` section looks as follows:

```toml
[api]
features_enabled = "nativepackages"
targets = ["x86_64-linux", "aarch64-linux", "x86_64-windows"]
allowed_native_package_origins = ["core"]
```

### Step 4: Sync Base Core Packages

```bash
hab pkg exec habitat/pkg-sync pkg-sync \
  --bldr-url <ON_PREM_BUILDER_URL> \
  --channel base \
  --origin core \
  --public-builder-token <PUBLIC_TOKEN> \
  --private-builder-token <PRIVATE_TOKEN>
```

### Step 5: Sync hab-2-rc1 Chef Packages

```bash
hab pkg exec habitat/pkg-sync pkg-sync \
  --bldr-url <ON_PREM_BUILDER_URL> \
  --origin chef \
  --channel hab-2-rc1 \
  --public-builder-token <PUBLIC_TOKEN> \
  --private-builder-token <PRIVATE_TOKEN>
```

### ✅ Verification

Check packages in your on-prem builder web UI or via API:

---

## Scenario 3: Setup Hab 2.0 as New User

**Objective:** Setup Hab 2.0 as a new user pointing to the on-prem instance

> **Current Status:** Habitat 2.0 is not yet available in the stable channel. Use the temporary installation method below.

### Prerequisites

- [ ] On-prem builder instance running (from Scenario 1)
- [ ] Public builder authentication token with valid license
- [ ] Network access to public builder for initial download

### Method 1: Current Installation (Habitat 2.0 RC)

Since Habitat 2.0 is not in stable channel yet, install via hab-2-rc1 channel:

#### Step 1: Install Habitat 1.6.x (Base Installation)

**Linux:**
```bash
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | sudo bash
```

**Windows:**
📖 **Reference:** [Windows Installation Guide](https://docs.chef.io/habitat/install_habitat/#chef-habitat-for-windows)

#### Step 2: Upgrade to Habitat 2.0 RC

```bash
sudo hab pkg install chef/hab -bf -c hab-2-rc1 -z <YOUR_PUBLIC_BLDR_AUTH_TOKEN>
```

### Method 2: Future Installation (When Habitat 2.0 is Stable)

Once Habitat 2.0 is available in stable channel:

```bash
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | sudo bash
hab --version
# Expected: habitat 2.x.x
```

### Verification

```bash
hab --version
# Expected: habitat 2.x.x
```
---

## Scenario 4: Workstation Setup

**Objective:** Install habitat on a workstation (Linux ARM, x86_64, or Windows) and run Habitat applications

### Prerequisites

- [ ] Workstation system (ARM64, x86_64 Linux, or Windows)
- [ ] Network access to on-prem builder
- [ ] Authentication token for on-prem builder

### Step 1: Install Habitat on Workstation

Follow the installation steps from **Scenario 3** based on your workstation architecture.

### Step 2: Configure Workstation

📖 **Reference:** [Workstation setup guide](./docs-chef-io/content/habitat/on_prem_builder/install/workstation.md)

```bash
# Point to your on-prem builder
export HAB_BLDR_URL=https://your-builder.example.com

# Set authentication token
export HAB_AUTH_TOKEN=<ON_PREM_BUILDER_TOKEN>

# For self-signed certificates (if applicable)
export SSL_CERT_FILE=/path/to/ssl-certificate.crt
```

### Step 3: Test Package Installation

```bash
# Test installing a package from your on-prem builder
sudo -E hab pkg install core/curl

# Verify installation
hab pkg path core/curl
```

---

## Scenario 5: Custom Package Development

**Requirement**: "download, install, build a custom hab package/service using base channel deps"

This scenario tests building custom packages with Habitat 2.0 dependencies:

### On the Workstation

Run the following command on the Workstation

#### 1. Create a test plan 

```bash
# 1. Create a test plan that uses base dependencies
mkdir test-package
cd test-package

# 2. Create plan.sh with base deps
cat > plan.sh << 'EOF'
pkg_name=test-service
pkg_origin=test
pkg_version="1.0.0"
pkg_maintainer="Test User <test@company.com>"
pkg_license=('Apache-2.0')
pkg_description="Test service for Habitat 2.0 - Cross Platform"

# Cross-platform dependency
pkg_deps=(
  core/python
)

# Platform-agnostic service using Python HTTP server
pkg_svc_run="python -m http.server 8080"

do_build() {
  return 0
}

do_install() {
  return 0
}
EOF
```

#### 2. Set env

```bash
export HAB_ORIGIN=test

# Point to your on-prem builder
export HAB_BLDR_URL=https://your-builder.example.com

# Set authentication token
export HAB_AUTH_TOKEN=<ON_PREM_BUILDER_TOKEN>
```

#### 3. Build package

```bash
# One time command to generate the public key at ~/.hab/cache/keys
sudo hab origin key generate test


# Build using Habitat 2.0 with base channel
sudo -E  hab pkg build .
# Make a note of the hart file generated at the end of the successful build.
```

#### 4. Create Origin at the On Prem Builder (If not already done)

Custom Builder instances don't auto-create origins. 
If the origin doesn't already exist, you need to manually create the origin.

```bash
sudo -E hab origin create test
```

#### 5. Upload to on prem bldr

```bash
sudo -E hab pkg upload <HART_FILE>
# Make a note of the CUSTOM_PKG_IDENT that gets uploaded.
# By default, the package gets uploaded onto the unstable channel.
```

### On a environment with supervisor running (Production Supervisor Environment with Habitat 2.0)

#### Update the systemd service to connect to on prem builder

Create the hab user:

```bash
sudo groupadd hab
sudo useradd -g hab hab
```

Create the systemd service file:

```bash
sudo tee /etc/systemd/system/hab-sup.service > /dev/null <<EOF
[Unit]
Description=The Habitat Supervisor
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$(which hab) sup run
Restart=on-failure
RestartSec=10
KillMode=mixed
KillSignal=SIGINT
TimeoutStartSec=120
TimeoutStopSec=60
Environment=HAB_BLDR_URL=https://your-builder.example.com

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start the service:

```bash
# Reload systemd configuration
sudo systemctl daemon-reload

# Enable the service
sudo systemctl enable hab-sup

# Start the service
sudo systemctl start hab-sup
sleep 10

# Verify service is running
sudo systemctl status hab-sup

# Check supervisor is accessible
sudo hab svc status
```

#### Verification

- **Linux**: `sudo systemctl status hab-sup` shows active/running
- **Windows**: `Get-Service habitat` shows running services

#### Load the package

```bash
# Load the service
sudo -E hab svc load test/test-service --channel unstable --url https://your-builder.example.com
```

#### Verification
`sudo hab svc status` shows the custom service up and running.

---

## Troubleshooting 

### Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|-----------|
| **Channel Not Found** | `Error: Channel 'base' not found` | • Verify channel exists on public builder<br>• Check license permissions<br>• Ensure token is valid |
| **ARM64 Package Missing** | `Package not available for aarch64-linux` | • Check if package is built for ARM64<br>• Use alternative package<br>• Report missing package to engineering |
| **Authentication Failed** | `401 Unauthorized` | • Verify token has correct permissions<br>• Check license key is valid<br>• Regenerate token if needed |

### Debug Commands

```bash
# Check service logs
sudo journalctl -u hab-sup -f
```