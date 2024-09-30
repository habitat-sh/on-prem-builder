# Habitat seed lists

With the `hab pkg download` command, you can download a list of seed packages along with their transitive dependencies. Of course, the question now becomes 'what do I use for the seed'.

This directory contains sample 'seed lists' of packages for bootstrapping and syncing on-prem Builder for
a number of different scenarios.

> Note: We are moving away from seed lists. See [Bootstrap Core Origin](../on-prem-docs/bootstrap-core.md) for instructions on using the `pkg-sync` tool to sync packages from public builder to an on-prem instance.

The basic file naming pattern is TASK\_ARCH\_CHANNEL. The files are a newline separated list of
package identifiers. The contents are specific to a particular architecture and channel and the
correct architecture and channel must be provided on the command line when running the `hab pkg
download` command. The simple file format used doesn't allow for specification of channel or target
architecture inline, so we're using a file naming convention to represent that information.
# Scenarios

The current scenarios are:
* builder (setting up an on-prem Builder)
* core_deps (a reduced starter set from core with common build time deps)
* core_full (everything for a particular architecture)
* effortless (starter set for the effortless pattern)

Each is broken out by the architecture and channel required.

For example, to get the complete Builder infrastructure for Linux,
```
hab pkg download --download-directory download_pkgs --channel=LTS-2024 --target x86\_64-linux  --file package_seed_lists/builder_x86_64-linux_lts_2024
hab pkg download --download-directory download_pkgs --channel=stable --target x86\_64-linux  --file package_seed_lists/builder_x86_64-linux_stable
```

Current scenarios include:

## Effortless (effortless_ARCH_CHANNEL)

These should provide all required packages for the various Effortless patterns, broken down by architecture.

See https://github.com/chef/effortless for more details on the Effortless infrastructure pattern.

## Core full (core_full_ARCH_CHANNEL)

These machine generated lists provide nearly all of the packages in core, broken down by
architecture. Downloading these lists replicates the old process of downloading all of core, and is
expensive in both download time and space. However if you just want one of the architectures these
do save substantial amounts of space. The Linux set expands to about 12 GB, while the Windows and
Linux kernel2 are about 3.5GB and 1GB respectively.

## Core deps (core_deps_ARCH_CHANNEL)

These are the packages listed as a transitive dep or build dep of another package in core. It is
intended as good starting point for building packages.

## Builder (builder_x86_64-linux_CHANNEL)

This should be just enough packages to get Builder installed on your system. Currently Builder only supports the x86_64-linux platform. You will need both the LTS-2024 channel list and also the stable channel list.
