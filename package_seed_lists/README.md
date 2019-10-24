# Habitat seed lists

Historically we bootstrapped on-prem Builders by downloading all the packages in 'core'
for all targets. That amounted to about 15GB, and was both too much and too little, in that many of
the packages weren't needed, and for many patterns (Effortless) other origins were needed.

With the creation of the `hab pkg download` command, a different approach is possible; you can start
with a list of seed packages, and download them along with their transitive dependencies. Of course,
the question now becomes 'what do I use for the seed'.

This directory contains sample 'seed lists' of packages for bootstrapping and syncing on-prem Builder, for
a number of different scenarios.

The basic file naming pattern is TASK\_ARCH\_CHANNEL. The files are newline separated list of
package identifiers. The contents are specific to a particular architecture and channel and the
correct architecture and channel must be provided on the command line when running the `hab pkg
download` command. The simple file format used doesn't allow for specification of channel or target
architecture inline, so we're using a file naming convention to represent that information. We plan
to improve on that experience, but for now keep it mind when building your own lists.

# Scenarios

The current scenarios are:
* builder (setting up an on-prem Builder)
* core_deps (a reduced starter set from core with common build time deps)
* core_full (everything for a particular architecture)
* effortless (starter set for the effortless pattern)

Each is broken out by the architecture and channel required; to complete some two downloads, once
from stable and once from unstable will be required.

For example, to get the complete Effortless infrastructure for Linux,
```
hab pkg download --download-directory download_pkgs --channel=unstable --target x86\_64-linux  --file  package_seed_lists/effortless_x86_64-linux_unstable
hab pkg download --download-directory download_pkgs --channel=stable --target x86\_64-linux  --file package_seed_lists/effortless_x86_64-linux_stable
```

Current scenarios include:

## Effortless (effortless_ARCH_CHANNEL)

These should provide all required packages for the various Effortless patterns. They're broken out
by architecture, and both stable and unstable are required for a complete Effortless infrastructure.

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

## Builder (builder_x86_64-linux_stable)

This should be just enough packages to get Builder installed on your system. Currently Builder only
supports the x86_64-linux platform.
