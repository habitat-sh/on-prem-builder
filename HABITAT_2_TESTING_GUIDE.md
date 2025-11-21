# Habitat 2.0 Testing Guide

## Overview

This guide provides step-by-step instructions for Testing of Habitat 2.0 RC builds with on-prem-builder. It covers the complete testing workflow from infrastructure setup to custom package development.


## Prerequisites

Before starting CFT testing, ensure you have:

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

**Objective:** Setup a standard hab on-prem instance on linux-x86_64

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
```

📖 **Reference:** [Configuration guide](./docs-chef-io/content/habitat/on_prem_builder/install/builder_oauth.md#configure-chef-habitat-on-prem-builder)

### Step 4: Install Dependencies

```bash
# Set authentication token for public builder
export HAB_AUTH_TOKEN=<PUBLIC_AUTH_TOKEN>

# Install required dependencies
sudo -E hab pkg install core/sqlite/3130000/20180608141313
sudo -E hab pkg install core/coreutils/8.32/20240110072150
```

### Step 5: Run Installation

```bash
sudo -E ./install.sh
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

**Objective:** Use sync tool to sync `base` core packages and `hab-2-rc1` chef packages from SAAS to the on-prem instance

### Step 1: Generate Private Builder Token

Create a personal access token for your on-prem builder:

📖 **Reference:** [Create personal access token](https://docs.chef.io/habitat/builder_profile/#create-a-personal-access-token)

### Step 2: Install pkg-sync Tool

```bash
sudo hab pkg install habitat/pkg-sync
```

### Step 3: Enable native package support
The habitat packages are now built with updated dependencies from the `base-2025` channel instead of the `stable` channel. 
Some of these package dependencies include `native` packages. 
In order for an on-prem builder instance to host the latest released habitat packages including these native package dependencies, 
that builder instance must be configured to allow native package support. 
This is done by enabling the `nativepackages` feature and specifying `core` as an allowed native package origin. 
To do this, an on-prem builder's `/hab/user/builder-api/config/user.toml` file should be edited so that the `[api]` section looks as follows:

```toml
[api]
features_enabled = "nativepackages"
targets = ["x86_64-linux", "x86_64-linux-kernel2", "x86_64-windows"]
allowed_native_package_origins = ["core"]
EOF

# Restart builder-api service to apply changes
sudo hab svc reload habitat/builder-api
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

```bash
curl -H "Authorization: Bearer <PRIVATE_TOKEN>" \
  "<ON_PREM_BUILDER_URL>/v1/depot/channels/core/base/pkgs"
```

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

#### Step 3: Verify Installation

```bash
hab --version
# Expected: habitat 2.x.x
```

### Method 2: Future Installation (When Habitat 2.0 is Stable)

Once Habitat 2.0 is available in stable channel:

```bash
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | sudo bash
hab --version
# Expected: habitat 2.x.x
```

### Step 4: Configure for On-Prem Builder

Point your Habitat installation to use the on-prem builder:

```bash
export HAB_BLDR_URL=<ON_PREM_BUILDER_URL>/bldr/v1/
export HAB_AUTH_TOKEN=<ON_PREM_BUILDER_TOKEN>
```

---

## Scenario 4: Upgrade from Habitat 1.x to 2.0

**Objective:** Upgrade existing Habitat 1.x installation to Habitat 2.0

### Prerequisites

- [ ] Existing Habitat 1.x installation
- [ ] Valid Progress Chef license key for Habitat 2.0
- [ ] Authentication token associated with the license

### Step 1: Obtain License Key and Token

1. Generate a free/trial license key: [Chef License Portal](https://www.chef.io/license-generation-free-trial)
2. Add license to your profile: [Instructions](https://docs.chef.io/habitat/builder_profile/#add-a-progress-chef-license-key)

### Step 2: Run Migration Script

**Warning:** Running services will be restarted during migration.

**Linux:**
```bash
curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/migrate.sh | \
  sudo -E bash -s -- --channel hab-2-rc1
```

**Windows:**
```powershell
iex "& { $(irm https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/migrate.ps1) } -Channel hab-2-rc1"
```

### Verification

```bash
hab --version
# Expected: habitat 2.x.x

sudo hab svc status
# Verify all services are running with Habitat 2.0
```

---

**Note:** The doc has not been tested from this point onwards.

## Scenario 5: Workstation Setup (Including ARM64)

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
export HAB_BLDR_URL=https://your-builder.example.com/bldr/v1/

# Set authentication token
export HAB_AUTH_TOKEN=<ON_PREM_BUILDER_TOKEN>

# For self-signed certificates (if applicable)
export SSL_CERT_FILE=/path/to/ssl-certificate.crt
```

### Step 3: Test Package Installation

```bash
# Test installing a package from your on-prem builder
hab pkg install core/curl

# Verify installation
hab pkg path core/curl
```

--

## Scenario 6: Custom Package Development

**Requirement**: "download, install, build a custom hab package/service using base channel deps"

This scenario tests building custom packages with Habitat 2.0 dependencies:

### On the On Prem Builder Instance

Run the following command on the system with On Prem Builder Setup:

```bash
# 1. Create a test plan that uses base-2025 dependencies
mkdir test-package
cd test-package

# 2. Create plan.sh with base-2025 deps
cat > plan.sh << 'EOF'
pkg_name=test-package
pkg_origin=test
pkg_version="1.0.0"
pkg_deps=(core/glibc)
pkg_build_deps=(core/gcc)

do_build() {
  echo "Building with Habitat 2.0 base deps"
}

do_install() {
  echo "Installing test package"
}
EOF

# 4. One time command to generate the public key at ~/.hab/cache/keys
sudo hab origin key generate test

# 5. Set env
export HAB_ORIGIN=test

#Required for private packages
export HAB_AUTH_TOKEN=<your private bldr token> 


# 3. Build using Habitat 2.0 with base-2025 channel
sudo-E  hab pkg build . --refresh-channel base-2025

#4 Upload to on prem bldr
sudo -E hab pkg upload <PKG_IDENT>
```

### On the workstation

Run the followong command on the Workstation:

```bash
# Download the package inside the workstation
sudo hab pkg download <PKG_IDENT>

# Install the package on workstation
sudo hab pkg install <hart file>
```

---

## Troubleshooting

### Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|-----------|
| **Channel Not Found** | `Error: Channel 'base' not found` | • Verify channel exists on public builder<br>• Check license permissions<br>• Ensure token is valid |
| **ARM64 Package Missing** | `Package not available for aarch64-linux` | • Check if package is built for ARM64<br>• Use alternative package<br>• Report missing package to engineering |
| **Authentication Failed** | `401 Unauthorized` | • Verify token has correct permissions<br>• Check license key is valid<br>• Regenerate token if needed |
| **Native Package Error** | `Native packages not allowed` | • Enable `nativepackages` feature<br>• Add `core` to allowed origins<br>• Restart builder-api service |
| **Service Not Starting** | `hab svc status` shows DOWN | • Check logs: `sudo journalctl -u hab-sup`<br>• Verify system resources<br>• Check port conflicts |

### Debug Commands

```bash
# Check service logs
sudo journalctl -u hab-sup -f

# Verify package availability
curl -H "Authorization: Bearer <TOKEN>" \
  "https://bldr.habitat.sh/v1/depot/channels/core/base/pkgs"

# Test on-prem builder connectivity
curl -H "Authorization: Bearer <TOKEN>" \
  "<ON_PREM_BUILDER_URL>/v1/depot/origins"

# Check ARM64 package availability
curl -H "Authorization: Bearer <TOKEN>" \
  "https://bldr.habitat.sh/v1/depot/channels/core/base/pkgs/_latest?target=aarch64-linux"

